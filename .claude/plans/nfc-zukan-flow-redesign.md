# プラン: NFC結果画面 → 図鑑発見演出への移行（スタンプ救済措置付き）

## Context

ゲーム性を主軸に方針転換し、スタンプカードを**完全廃止**する。
NFCタップ時の「主役」をスタンプカード押印から**図鑑カード発見演出**に変更する。

ただし、すでにスタンプを集め始めた既存ユーザーへの**救済措置**として、
`currentStamps >= 1` のユーザーには引き続きスタンプを加算し、
スタンプ押印画面を経由してから図鑑カード画面へ遷移する。
`currentStamps == 0` の新規ユーザーはスタンプカードを経由せず、直接図鑑カードシステムへ移行する。

図鑑機能は現時点で完全未実装。以下の順序で進める：

1. Firestore/Cloud Function のデータ拡張（スタンプ分岐ロジック追加）
2. 図鑑カードWidget + 図鑑タブ画面の新規作成
3. NFC結果画面を分岐対応に差し替え
4. スタンプカードUIを非表示化

---

## 設計方針: スタンプ救済措置

| ユーザー種別 | 判定条件 | NFC後の画面遷移 |
|------------|---------|--------------|
| 既存スタンプ保有者 | `currentStamps >= 1` | スタンプ押印アニメーション → 「カードを見る」ボタン → 図鑑カード画面 |
| 新規ユーザー | `currentStamps == 0` | 図鑑カード画面（直接遷移） |

### フルフロー図

```
ユーザーがNFCタッチ
  ↓
nfcCheckin Cloud Function
  ↓
  ├─ currentStamps >= 1（救済措置対象）
  │    → stamps +1 加算
  │    ↓
  │   【スタンプ押印アニメーション画面】（既存nfc_checkin_result_view流用）
  │    - StampCardWidget で押印演出
  │    - cardCompleted == true の場合: 完成エフェクト（輝き）表示
  │    - 「カードを見る」ボタンを下部に配置
  │    ↓（「カードを見る」ボタン押下）
  │   【図鑑カード画面】
  │    ├─ isFirstVisit == true  → フリップアニメーション + 「発見！」演出
  │    └─ isFirstVisit == false → 再訪表示（○回目の来店 / 発見者数）
  │
  └─ currentStamps == 0（新規ユーザー）
       → スタンプ加算なし（来店記録・firstVisitAt のみ）
       → stampsAfter = 0 を返す
       ↓
      【図鑑カード画面（直接遷移）】
       ├─ isFirstVisit == true  → フリップアニメーション + 「発見！」演出
       └─ isFirstVisit == false → 再訪表示（スタンプは常に 0 のまま）
```

---

## 現状の実装サマリー（調査結果）

| 項目 | ファイル | 状態 |
|------|---------|------|
| NFC結果画面 | `lib/views/checkin/nfc_checkin_result_view.dart` | 実装済み（スタンプ主役 → 分岐対応に変更） |
| クーポン選択画面 | `lib/views/checkin/nfc_coupon_select_view.dart` | 実装済み（変更不要） |
| Cloud Function: nfcCheckin | `backend/functions/src/index.ts` L4105~ | 実装済み（修正必要） |
| NfcCheckinResult モデル | `lib/services/nfc_checkin_service.dart` | 実装済み（修正必要） |
| StampCardWidget | `lib/widgets/stamp_card_widget.dart` | 実装済み（スタンプ保有者の押印画面で流用） |
| getCategoryIcon / getCategoryColor | `lib/widgets/stamp_card_widget.dart` L420-636 | 実装済み（図鑑カードでも流用） |
| 図鑑UI | なし | **完全未実装** |
| discoveredCount フィールド | なし | **未定義** |
| isFirstVisit 判定 | `index.ts` L4214-4223 | ロジックは存在するが戻り値に未含有 |

### 初発見判定の既存ロジック

`storeUserStatsSnap.exists` の否定値 = 初発見。
`store_users/{storeId}/users/{userId}` が存在しなければ初訪問。すでにサーバーサイドで判定済み。

---

## Phase 1: Firestore / Cloud Function の拡張

### 1-1. Firestoreスキーマ追加

**`stores/{storeId}` に追加するフィールド:**

| フィールド | 型 | 説明 |
|-----------|-----|------|
| `discoveredCount` | int | GrouMap経由で来店したユニークユーザー数。図鑑のレア度自動計算に使用 |
| `rarityOverride` | int（任意） | 管理者による手動レア度上書き（1=コモン / 2=レア / 3=エピック / 4=レジェンド） |

**更新ファイル:** `FIRESTORE.md`（stores コレクションのスキーマ欄に追記）

### 1-2. nfcCheckin Cloud Function の修正

**変更箇所:** `backend/functions/src/index.ts` L4159〜4234（トランザクション部分）

**スタンプ分岐ロジック（新規追加）:**

```typescript
const currentStamps = storeStampData?.stamps ?? 0;
const isFirstVisit = !storeUserStatsSnap.exists;

if (currentStamps >= 1) {
  // 救済措置: 既存スタンプ保有者はスタンプを +1 加算
  const nextStamps = currentStamps + 1;
  const cardCompleted = nextStamps % MAX_STAMPS === 0;
  txn.set(targetStoreRef, {
    stamps: nextStamps,
    lastStampDate: todayJst,   // 1日1回制限チェック用（フィールド名流用）
    lastVisited: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
} else {
  // 新規ユーザー: 来店記録のみ（スタンプ加算なし）
  txn.set(targetStoreRef, {
    lastStampDate: todayJst,   // 1日1回制限チェック用（フィールド名は変更しない）
    lastVisited: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
}

if (isFirstVisit) {
  txn.update(storeRef, {
    discoveredCount: FieldValue.increment(1),
    updatedAt: FieldValue.serverTimestamp(),
  });
}
```

**変更後の戻り値:**

```typescript
return {
  storeName,
  stampsAfter,        // 0 = 新規ユーザー / 1以上 = スタンプ保有者（Flutter側の分岐に使用）
  cardCompleted,      // スタンプ10個達成フラグ（新規ユーザーは常に false）
  isFirstVisit,       // 図鑑カードの初発見判定（新規追加）
  awardedCoupons: [], // クーポン廃止により常に空配列
  usedCoupons,
  usageVerificationCode,
};
```

**削除する処理:**
- 来店ボーナスコイン +1 付与（`coinLastEarnedAt`, `coinExpiresAt` の更新も削除）
- スタンプ達成クーポン自動付与（`if (result.cardCompleted) { ... }` ブロック全体）

### 1-3. NfcCheckinResult モデルの修正

**変更ファイル:** `lib/services/nfc_checkin_service.dart`

```dart
class NfcCheckinResult {
  final int stampsAfter;         // 0 = 新規 / 1以上 = スタンプ保有者
  final bool cardCompleted;      // スタンプカード完成フラグ
  final String storeName;
  final bool isFirstVisit;       // 図鑑カード初発見フラグ（新規追加）
  final List<Map<String, dynamic>> awardedCoupons;
  final List<Map<String, dynamic>> usedCoupons;
  final String? usageVerificationCode;
  // coinsAdded: 削除（コイン廃止）
}
```

---

## Phase 2: 図鑑カードWidget + 図鑑タブ画面

### 2-1. ZukanCardWidget（新規作成）

**新規ファイル:** `lib/widgets/zukan_card_widget.dart`

**設計:**
- `StampCardWidget.getCategoryIcon()` / `getCategoryColor()` をそのまま流用（新規アセット作成ゼロ）
- カード背景: 店舗写真あり → 店舗写真、なし → カテゴリアイコン（getCategoryIcon使用）
- レア度計算ロジック（クライアント側で計算）:

```
rarityOverride があれば優先
discoveredCount == 0 → ★★★★ レジェンド
discoveredCount 1〜5 → ★★★ エピック
discoveredCount 6〜20 → ★★ レア
discoveredCount 21以上 → ★ コモン
```

**表示モード2種:**

| モード | 内容 |
|--------|------|
| 発見済み | フルカラー + 店舗名 + レア度（★表示）+ 発見者数 |
| 未発見 | ColorFiltered(グレースケール + opacity 0.5) + 「？？？」+ カテゴリ/エリア/距離/description先頭40文字/発見者数は表示 |

### 2-2. ZukanView（図鑑タブ画面）（新規作成）

**新規ファイル:** `lib/views/zukan/zukan_view.dart`

**画面構成:**
- 上部: エリア開拓率サマリー（将来実装のためプレースホルダー表示）
- メイン: 店舗カード一覧
  - 発見済み: フルカラーカード
  - 未発見: グレースケールシルエット
  - 並び順: エリア別 or カテゴリ別（切り替えタブまたはフィルター）

**データ取得ロジック:**
- 全店舗一覧: `stores`（isActive=true / isApproved=true）
- 発見済み判定: `store_users/{storeId}/users/{userId}` の存在有無（firstVisitAt 存在）で判定
  ※ `stamps > 0` だけでなく `firstVisitAt` の存在で判定する（新規ユーザーはstamps=0のため）

### 2-3. ボトムナビゲーションへの図鑑タブ追加

**変更ファイル:** `lib/views/main_navigation_view.dart`（3タブ化）

```
現在: [ホーム] [マップ] [投稿] [通知] [アカウント]
変更後:         [マップ]  [図鑑]        [アカウント]
```

※ ホームタブ廃止・投稿タブ廃止は BUSINESS_MODEL.md で確定済み（2026-03-04）

---

## Phase 3: NFC結果画面の差し替え（分岐対応）

**変更ファイル:** `lib/views/checkin/nfc_checkin_result_view.dart`

### stampsAfter による画面分岐

```dart
if (result.stampsAfter >= 1) {
  // スタンプ保有者: スタンプ押印画面を表示
  _showStampScreen();
} else {
  // 新規ユーザー: 直接図鑑カード画面へ
  _navigateToZukanCard();
}
```

### スタンプ押印画面（stampsAfter >= 1 の場合）

既存の StampCardWidget を流用してスタンプ押印演出を表示する。

1. StampCardWidget で押印アニメーション表示
2. `cardCompleted == true` の場合: 完成エフェクト（輝きアニメーション）を追加表示
3. 下部に「カードを見る」ボタンを配置
4. ボタン押下 → 図鑑カード画面へ遷移

※ 自動遷移はしない（ユーザーが意図的にボタンを押す形式）

### 図鑑カード画面（ZukanCardView）

#### 初発見時（isFirstVisit == true）

1. カードがグレースケールで表示（未発見状態から開始）
2. フリップアニメーション（約 400ms）でフルカラーに切り替わる
3. 「発見！」テキストをフェードイン演出
4. レア度（★★★★など）を下部に表示
5. 「あなたが○人目の発見者です！」の表示
6. バッジ獲得があれば下部に表示

#### 再訪時（isFirstVisit == false）

1. 発見済み図鑑カードを静的表示（フリップなし）
2. 「○回目の来店」表示
3. 「発見者数: ○人」表示
4. バッジ獲得があれば下部に表示

#### 共通要素（変更なし）
- クーポン利用確認コード（6桁 + リアルタイム時計）
- 利用したクーポン一覧

### エッジケース

| ケース | 動作 |
|--------|------|
| スタンプ9→10（カード完成） | 押印アニメーション + 完成エフェクト → 「カードを見る」→ 図鑑カード（初発見 or 再訪） |
| 新規ユーザーの2回目以降来店 | stampsAfter=0 のまま、isFirstVisit=false → 図鑑カードの再訪表示 |
| 1日1回制限 | `lastStampDate` フィールドを流用（フィールド名変更なし。新規ユーザーも記録して制限に使用） |

---

## Phase 4: スタンプカードUIの非表示化

| ファイル | 変更内容 |
|---------|---------|
| `lib/views/home_view.dart` | スタンプショートカットボタンを削除。統計カプセルバーの「スタンプ数」を「発見店舗数」に変更 |
| `lib/widgets/user_stats_card.dart` | `userTotalStampsProvider` を発見店舗数Provider に差し替え |
| `lib/views/stamps/stamp_cards_view.dart` | ボトムナビから外す |
| `lib/providers/` | 発見店舗数を返す新規Provider追加（`userDiscoveredStoreCountProvider`） |

---

## 変更しないもの（重要）

- `StampCardWidget` 自体: 削除しない（スタンプ保有者の押印画面で引き続き使用）
- `store_users/{storeId}/users/{userId}` の firstVisitAt / totalVisits 記録: 維持（KPI・発見済み判定に使用）
- `stores/{storeId}/transactions` への type:'stamp' レコード作成: 維持（KPI集計のため）
- スタンプデータ（`users/{uid}/stores/{storeId}.stamps`）: データは削除しない
- `lastStampDate` フィールド名: 変更なし（1日1回制限チェックに流用）
- `punchStamp` 関数: 変更対象外（QRコード経由のチェックインは現状維持）

---

## 実装の依存関係

```
Phase 1（Cloud Function修正: スタンプ分岐 + isFirstVisit + discoveredCount）
    ↓
Phase 2-1（ZukanCardWidget）
    ↓
Phase 2-2（ZukanView）
    ↓
Phase 2-3（ナビゲーション変更 → 3タブ化）
    ↓
Phase 3（NFC結果画面: スタンプ保有者分岐 + 「カードを見る」ボタン + 図鑑カード画面）
    ↓
Phase 4（スタンプカードUI廃止）
```

---

## 検証方法

### スタンプ保有者（既存ユーザー）のフロー
1. スタンプ1〜9個保有ユーザーがNFCタッチ → スタンプ押印アニメーション確認
2. 「カードを見る」ボタンが表示されることを確認
3. ボタン押下 → 図鑑カード画面に遷移することを確認
4. 初発見なら: フリップアニメーション + 「発見！」確認
5. 再訪なら: 「○回目の来店」静的表示確認
6. スタンプ9個→10個（完成）: 完成エフェクト → 「カードを見る」確認

### 新規ユーザー（スタンプ0）のフロー
7. 初回NFC タッチ → スタンプ画面をスキップして図鑑カード画面に直行
8. フリップアニメーション + 「発見！」+ 「あなたが○人目」を確認
9. 同一店舗に2回目チェックイン → 再訪表示・スタンプは0のまま

### 共通
10. 図鑑タブで発見済み店舗がフルカラー表示されることを確認
11. 未発見店舗がグレースケールシルエット表示されることを確認
12. `stores/{storeId}.discoveredCount` が初発見時に +1 されることを確認
13. 1日1回制限が引き続き機能すること（2回目はエラー）
14. コインが付与されないこと
15. クーポン自動付与が行われないこと
