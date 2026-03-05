# ビジネスモデル簡素化プラン

## Context

ゲーム性（図鑑・マップ塗り）を主軸に据えた設計変更にあたり、心理学的観点から「外発的動機（コイン・クーポン）が内発的動機（探索欲求）を阻害する」と判断。コインシステム・クーポンシステムをUIから除去し、スタンプシステムは既存ユーザーのみ10個まで継続できる「サンセット設計」に移行する。

店舗側にはデジタル導入コストを掛けない方針（NFCスタンドのみ）のため、100円引き特典はアプリ外（口頭）で完結させ、「初回来店 = 100円引き使用」とみなしてデータ集計する設計とする。

---

## 変更スコープ

### Phase 1: スタンプサンセット（Cloud Functions + Firestore）

#### 1-1. `stampEnabled` フィールドを特定店舗に追加

- 対象: `stores/{storeId}` ドキュメント
- フィールド: `stampEnabled: false`
- 方法: Firestore コンソールで対象店舗のみ直接設定（初回は手動）
- 設計: `stampEnabled` が存在しない or `true` の場合は従来通り（後方互換性）

#### 1-2. `nfcCheckin` Cloud Function の変更

**ファイル**: `backend/functions/src/index.ts`（行 4105-4592）

変更箇所（行 4155-4234 のトランザクション内）：

```typescript
// [追加] stampEnabled チェック
const stampEnabled = storeDoc.data()?.stampEnabled !== false; // デフォルト true
const currentStamps = storeStampData?.stamps ?? 0;

if (!stampEnabled && currentStamps === 0) {
  // 新規ユーザー + スタンプ無効 = 来店記録のみ（スタンプ付与しない）
  // ※ visit/transaction記録は行う（データ収集のため）
} else {
  // 既存スタンプホルダー or stampEnabled=true = 通常通りスタンプ付与
}
```

#### 1-3. 10個達成時のクーポン自動付与を停止

**ファイル**: `backend/functions/src/index.ts`

- 行 4365-4411 の `requiredStampCount > 0` クーポン自動付与処理を削除
- 代替: スタンプカード達成バッジ（`stamp_card_completed_1`）を付与（既存バッジ定義を流用）
- `lib/data/badge_definitions.dart` の `stamp_card_completed_1` ID を使用（既存の実装）

#### 1-4. `punchStamp` 関数にも同様の変更を適用

**ファイル**: `backend/functions/src/index.ts`（行 2463-3014）

- 行 2527 のスタンプ加算前に `stampEnabled` チェックを追加
- 行 2846-2887 のクーポン自動付与処理を削除

---

### Phase 2: コインシステムのUI削除

**方針**: データベースのコインデータは削除しない（既存ユーザーへの影響なし）。UIから非表示にするのみ。

#### 2-1. ホーム画面のコイン関連UI削除

**ファイル**: `lib/views/home_view.dart`

| 削除対象 | 行番号（参考） | 内容 |
|---------|------------|------|
| コイン交換セクション | 1798-1879 | `_buildCoinExchangeSection` メソッドと呼び出し箇所 |
| ミッションFABボタン | `_missionFabKey` 関連 | FloatingActionButton 全体 |
| ステータスバーのコイン表示 | 1308-1371 | コイン残高・有効期限テキスト |

#### 2-2. ミッション画面の無効化

**ファイル**: `lib/views/main_navigation_view.dart`

- ナビゲーションバーからミッション導線を除去
- `missions_view.dart` は**削除せず残す**（将来の別ゲームミッション実装に備えて）

#### 2-3. インタラクティブウォークスルーの修正

**ファイル**: `lib/views/home_view.dart`（行 520-550 付近）

- ステップ5（ミッションFAB）とステップ7（コイン交換ボタン）を削除
- 7ステップ→最大5ステップに短縮（マップ関連ステップのみ残す）

---

### Phase 3: コイン付与の停止（Cloud Function）

**ファイル**: `backend/functions/src/index.ts`

- 行 4237-4250: `nfcCheckin` の来店ボーナスコイン+1付与処理を削除
- `coinLastEarnedAt`, `coinExpiresAt` の更新も合わせて削除

---

### Phase 4: クーポンシステムのUI非表示

**方針**: クーポン関連のデータ・コレクションは削除しない。UIから非表示にするのみ。

**ファイル**: `lib/views/home_view.dart`

- 特別クーポンセクション（コイン交換クーポン表示）を非表示
- クーポンショートカットメニューを非表示

**ファイル**: `lib/views/main_navigation_view.dart`

- クーポン画面への導線を非表示

---

## 変更対象ファイル一覧

| ファイル | 変更種別 | 内容 |
|--------|---------|------|
| `backend/functions/src/index.ts` | 修正 | `nfcCheckin`・`punchStamp` に `stampEnabled` チェック追加、クーポン自動付与削除、コイン付与削除 |
| `lib/views/home_view.dart` | 修正 | コイン交換セクション削除、ミッションFAB削除、コイン表示削除、ウォークスルー短縮 |
| `lib/views/main_navigation_view.dart` | 修正 | ミッション・クーポン導線の非表示 |
| `stores/{storeId}` (Firestore) | 手動設定 | 対象店舗に `stampEnabled: false` を追加 |

---

## 影響を受けないもの（変更しない）

- ホーム画面自体（削除しない、将来的に再利用可能）
- `missions_view.dart`（削除しない、将来のゲームミッション用）
- `user_coupons` コレクション（データ保持、新規作成のみ停止）
- バッジシステム（変更なし）
- スタンプデータ（`users/{uid}/stores/{storeId}.stamps`、変更なし）
- `store_users/{storeId}/users/{userId}.firstVisitAt`（100円引き集計のベースデータとして保持）

---

## デプロイ手順

1. Cloud Functions のビルド・デプロイ
   ```bash
   cd /Users/kanekohiroki/Desktop/groumapapp/backend/functions && npm run build
   firebase deploy --only functions:nfcCheckin,functions:punchStamp
   ```
2. Firestore コンソールにて対象店舗ドキュメントに `stampEnabled: false` を手動設定
3. Flutter アプリの UI 変更をビルド・テスト

---

## 検証項目

- [ ] 既存スタンプ保有ユーザー（1〜9個）がNFCタッチしてスタンプが加算されること
- [ ] 新規ユーザー（スタンプ0）がNFCタッチしても `stampEnabled: false` の店舗ではスタンプが付与されないこと
- [ ] 10個達成時にスタンプカード達成バッジが付与されること
- [ ] 10個達成時にクーポンが発行されないこと
- [ ] ホーム画面にコイン交換ボタンが表示されないこと
- [ ] ミッションFABが表示されないこと
