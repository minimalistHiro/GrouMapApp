# 実装ロードマップ

> 最終更新: 2026-03-05
> 目的: ゲーム性（図鑑・地図塗り）を主軸とした設計変更の実装計画

---

## 全体方針

スタンプ・コインシステムからの脱却を軸に、以下フェーズで段階的に移行する。

```
フェーズ0: 事前準備（実装着手前に完了）
    ↓
フェーズ1: 図鑑・3タブ化（設計書完成済み・実装着手可能）
    ↓
フェーズ2: 地図塗り・エリア・ランキング刷新（設計書完成済み・フェーズ1完了後に着手）
    ↓
フェーズ3: 月次レポート・バッジ拡充（設計プラン未作成・フェーズ2完了後に着手）
```

---

## ⚠️ 設計書間の重要な調整事項

### スタンプ救済措置の方針（正規仕様: nfc-zukan-flow-redesign.md を採用）

`block-a-cloud-functions.md`（スタンプ全停止）と `nfc-zukan-flow-redesign.md`（救済措置付き廃止）で方針が異なる。
BUSINESS_MODEL.md の記述（「既存スタンプ保有者は救済措置として継続」）と整合する **nfc-zukan-flow-redesign.md を採用**する。

| ユーザー種別 | 判定 | 動作 |
|------------|------|------|
| 既存スタンプ保有者（`currentStamps >= 1`） | 救済措置対象 | NFCチェックイン時にスタンプ +1 加算継続 |
| 新規ユーザー（`currentStamps == 0`） | 図鑑移行済み | スタンプ加算なし・来店記録のみ |

### `business-model-simplification.md` の扱い

`stampEnabled` フラグ方式は `nfc-zukan-flow-redesign.md` の `currentStamps` チェック方式と競合する。
Cloud Functions 側の変更は **nfc-zukan-flow-redesign.md の仕様を優先**し、
`business-model-simplification.md` は **UI削除・コイン停止の変更のみ参照**する。

---

## フェーズ0: 事前準備（実装着手前に完了）

> 設計書: [immediate-tasks-design.md](.claude/plans/immediate-tasks-design.md)
> **フェーズ1の Cloud Functions 修正前に完了しておくこと。**

- [ ] **#13** `FIRESTORE.md` に `discoveredCount` / `rarityOverride` / `areaId` を追記（`nfcCheckin` 修正前）
- [ ] **#10** `punchStamp` 内のウェルカムお知らせ文言を更新（コイン記述を削除）→ `firebase deploy --only functions:punchStamp`
- [ ] **#9** `STORE_AGREEMENT.md` 新規作成（パイロット営業開始前・運用タスク）

---

## フェーズ1: 図鑑・3タブ化

> 設計書: `.claude/plans/` 配下に全て存在。**今すぐ実装着手できる。**

### 推奨実装順序

```
① Cloud Functions 変更（バックエンド基盤）
    ↓
② NFC結果画面 → 図鑑発見演出 + 図鑑View詳細実装
    ↓
③ 3タブ化・ZukanView・ProfileView 強化
    + 紹介UI廃止（#12）・廃止バッジ処理（#11）を同時実施
    ↓
④ ビジネスモデル簡素化（コイン・クーポンUI削除）
    ↓
⑤ KPI再定義
    ↓
⑥ ドキュメント更新（#14）
```

---

### タスク一覧

#### ① バックエンド（Cloud Functions）

設計書:
- [nfc-zukan-flow-redesign.md](.claude/plans/nfc-zukan-flow-redesign.md) **← スタンプ救済措置の正規仕様。Cloud Functions の実装仕様はこちらを優先**
- [block-a-cloud-functions.md](.claude/plans/block-a-cloud-functions.md) **← コイン付与削除・フォロー source 変更の詳細はこちらを参照**

**`nfcCheckin` 関数の変更:**
- [ ] `currentStamps >= 1` の既存ユーザーはスタンプ +1 加算継続（救済措置）
- [ ] `currentStamps == 0` の新規ユーザーはスタンプ加算なし（来店記録のみ）
- [ ] `isFirstVisit` フラグを追加（初回来店時のみ `stores/{storeId}.discoveredCount` を +1）
- [ ] 来店ボーナスコイン付与を削除
- [ ] スタンプ達成クーポン自動付与を削除
- [ ] 自動フォローの `source` を `nfc_checkin` に変更
- [ ] 戻り値を `{ storeName, stampsAfter, cardCompleted, isFirstVisit, awardedCoupons: [], usedCoupons, usageVerificationCode }` に変更

**`punchStamp` 関数の変更:**
- [ ] `currentStamps >= 1` のユーザーのみスタンプ +1 加算（救済措置と整合）
- [ ] スタンプ達成クーポン自動付与を削除
- [ ] 自動フォローの `source` を `punch_checkin` に変更

**デプロイ:**
- [ ] `firebase deploy --only functions:nfcCheckin,functions:punchStamp`

---

#### ② NFC結果画面 → 図鑑発見演出 + 図鑑View詳細実装

設計書:
- [nfc-zukan-flow-redesign.md](.claude/plans/nfc-zukan-flow-redesign.md)（フロー・画面分岐ロジック）
- [zukan-view-design.md](.claude/plans/zukan-view-design.md)（ZukanView・ZukanCardWidget・Provider の詳細実装定義）

**モデル変更:**
- [ ] `NfcCheckinResult` モデルに `isFirstVisit` 追加、`coinsAdded` 削除（`stampsAfter`, `cardCompleted` は救済措置のため維持）

**新規ファイル作成（zukan-view-design.md に従う）:**
- [ ] `lib/providers/zukan_provider.dart`（`zukanAllStoresProvider`, `userVisitedStoreIdsProvider`, `zukanStoresProvider`, `userDiscoveredStoreCountProvider`, `ZukanStoreItem` クラス）
- [ ] `lib/widgets/zukan_card_widget.dart`（発見済み/未発見の2モードカード。カテゴリアイコン・カラーは `StampCardWidget` を static import で流用）
- [ ] `lib/views/zukan/zukan_view.dart`（図鑑タブ。フィルター・ソート・グリッド・開拓サマリーバー）

**NFC結果画面の変更:**
- [ ] `nfc_checkin_result_view.dart` に `stampsAfter >= 1` による分岐を追加
  - スタンプ保有者: スタンプ押印アニメーション → 「カードを見る」ボタン → 図鑑カード画面
  - 新規ユーザー: 直接図鑑カード画面へ
- [ ] 図鑑カード画面を新規作成（初発見: フリップアニメーション + 「発見！」演出 / 再訪: 「○回目の来店」静的表示）

**ホーム画面の変更:**
- [ ] 統計カプセルバーの「スタンプ数」を「発見店舗数」に変更（`userDiscoveredStoreCountProvider` を使用）

---

#### ③ 3タブ化・ZukanView・ProfileView 強化（#11・#12 を同時実施）

設計書: [ui-navigation-redesign-3tabs.md](.claude/plans/ui-navigation-redesign-3tabs.md)

**ナビゲーション変更:**
- [ ] `MainNavigationView` を3タブ化（マップ / 図鑑 / アカウント）・FAB削除
- [ ] 初期タブを MapView（index 0）に固定
- [ ] 図鑑タブに `ZukanView` を配置（②で作成済み）

**ProfileView 強化:**
- [ ] 探検統計カード追加（発見店舗数・バッジ数・ランキング順位）
- [ ] ヘッダー右上に通知ベルアイコン追加（未読バッジ付き）
- [ ] QRコードフォールバックボタン追加（グレーの小テキストボタン・ログアウトの上）
- [ ] 「バッジ一覧」「ランキング」「通知・お知らせ」を「ゲーム」セクションとして上部に移動

**ウォークスルー更新:**
- [ ] ④「図鑑タブで発見済み店舗を確認」に変更

**#12 紹介UIの廃止（同時実施）:**
設計書: [immediate-tasks-design.md](.claude/plans/immediate-tasks-design.md)
- [ ] `profile_view.dart` から「友達を紹介する」ボタン・`FriendReferralView` への導線を削除
- [ ] ルーティング定義から `FriendReferralView` への Route を削除（ファイル自体は残す）

**#11 廃止バッジ処理（同時実施）:**
設計書: [immediate-tasks-design.md](.claude/plans/immediate-tasks-design.md)
- [ ] `BADGE_LIST.md` にコイン獲得バッジ5個・ミッション達成バッジ5個（計10個）に「廃止・獲得不可」の注記を追加
- [ ] `missions_view.dart` から `incrementBadgeCounter('coinsEarned')` / `incrementBadgeCounter('missionCompleted')` を削除

---

#### ④ ビジネスモデル簡素化（コイン・クーポンUI削除）

設計書: [business-model-simplification.md](.claude/plans/business-model-simplification.md)（**UIの削除・非表示のみ参照。Cloud Functions の変更は①で実施済み**）

- [ ] `home_view.dart` のコイン交換セクション・ミッションFAB・コイン残高表示を削除
- [ ] `home_view.dart` のウォークスルーのステップ数を短縮（コイン関連ステップを削除）
- [ ] 特別クーポンセクション・クーポンショートカットを非表示

---

#### ⑤ KPI再定義

設計書: [kpi-redefinition.md](.claude/plans/kpi-redefinition.md)

- [ ] `store_stats/daily.visitorCount` の更新条件を確認・修正（NFCチェックインの `type='stamp'` でも +1 されるか検証）
- [ ] `BUSINESS_MODEL.md` の KPI セクションを更新（スタンプベース → `firstVisitAt` ベース）

---

#### ⑥ ドキュメント更新

- [ ] **#14** `USER_APP_SCREENS.md` を3タブ構成（マップ / 図鑑 / アカウント）に更新（フェーズ1完了後）
- [ ] `FIRESTORE.md` に未追記の項目があれば補完（フェーズ0 #13 の残り分）

---

## フェーズ2: 地図塗り・エリア・ランキング刷新

> 設計書: `.claude/plans/` 配下に存在。**フェーズ1完了後に着手。**

### 推奨実装順序

フェーズ2は以下の依存関係がある。

```
① エリアシステム（Firestoreスキーマ・Circle オーバーレイ）  ← 最初に実装
    ↓
② マップ拡張（個人マップ・コミュニティマップ）             ← エリアオーバーレイを流用

③ ランキング刷新（独立。①②と並行して進めても可）
   + #7 ランキングオプトアウト設定（同時実施）
   + #8 プライバシーポリシー更新（ランキング公開前）
```

---

### タスク一覧

#### ① エリアシステム

設計書: [area-system-design.md](.claude/plans/area-system-design.md)

**先に実施する理由:**
- `areas` コレクションが `AreaModel` / `area_provider.dart` の基盤になる
- マップ拡張（コミュニティマップの開拓率ビュー）がこのエリアオーバーレイを流用する

**実装タスク:**
- [ ] Firestore コンソールで `areas` コレクションにサンプルエリアを手動作成（蕨駅・川口駅・西川口駅）
- [ ] `stores/{storeId}` に `areaId` フィールドを手動設定（Firestore コンソール）
- [ ] `lib/models/area_model.dart` 新規作成
- [ ] `lib/providers/area_provider.dart` 新規作成（`areasProvider`, `areaExplorationRateProvider`）
- [ ] `map_view.dart` に `_loadAreas()` / `_buildAreaCircles()` 追加
- [ ] `store_detail_view.dart` に「秘境スポット」バッジ追加（`areaId == null` の場合）
- [ ] `lib/views/area/area_exploration_view.dart` 新規作成（エリア開拓率一覧）
- [ ] `firestore.rules` に `areas` コレクションのルール追加 → `firebase deploy --only firestore:rules`
- [ ] `FIRESTORE.md` に `areas` コレクション・`stores.areaId` を追記

---

#### ② マップ拡張

設計書: [map-extension-design.md](.claude/plans/map-extension-design.md)

**前提:** エリアシステム（①）の `_loadAreas()` / `_areaCircles` が実装済みであること

**実装タスク:**
- [ ] `nfcCheckin` Cloud Function に `users/{uid}/stores/{storeId}.totalVisits` ミラー書き込みを追加 → `firebase deploy --only functions:nfcCheckin`
- [ ] `map_view.dart` に `_personalMapMode` / `_communityMapMode` / `_communitySubMode` フィールド追加
- [ ] `_setMapMode()` で既存フラグ管理を統一
- [ ] `_resolveMarkerVisual()` に `storeId` 引数追加・個人マップロジック追加（5段階ステータス）
- [ ] `_buildFilterChips()` に「個人マップ」「コミュニティ」チップ追加
- [ ] `_buildActivityCircles()` 実装（賑わい度 Circle オーバーレイ）
- [ ] `_buildCommunitySubModeToggle()` UI 実装（開拓率 / 賑わい度トグル）
- [ ] `GoogleMap` ウィジェットに `circles: _getActiveCircles()` を追加

---

#### ③ ランキング刷新（+ #7・#8 を同時実施）

設計書: [ranking-redesign.md](.claude/plans/ranking-redesign.md)

**前提:** フェーズ1の `nfcCheckin`（`isFirstVisit` 追加）が完了していること

**実装タスク:**
- [ ] `lib/models/ranking_model.dart` — `RankingType` enum に `discoveredStoreCount` 追加（先頭・デフォルト）、`RankingModel` にフィールド追加
- [ ] `flutter pub run build_runner build`（freezed コード再生成）
- [ ] `lib/providers/ranking_provider.dart` — `_getRankingFromScores()` / `_buildPeriodId()` 追加
- [ ] `lib/views/ranking/leaderboard_view.dart` — デフォルト指標変更・ラベル追加・全ユーザーに開放
- [ ] `firestore.rules` に `ranking_scores` コレクションのルール追加 → `firebase deploy --only firestore:rules`
- [ ] `nfcCheckin` Cloud Function に `discoveredStoreCount` インクリメント + `ranking_scores` batch 更新を追加 → `firebase deploy --only functions:nfcCheckin`
- [ ] `FIRESTORE.md` に `users.discoveredStoreCount` / `ranking_scores` コレクションを追記

**#7 ランキングオプトアウト設定（同時実施）:**
設計書: [immediate-tasks-design.md](.claude/plans/immediate-tasks-design.md)
- [ ] `users/{uid}.rankingOptOut: bool` フィールド追加（デフォルト: false）
- [ ] `notification_settings_view.dart` に「ランキング設定」セクション・トグル追加
- [ ] ランキング取得時の匿名化ロジック追加（`rankingOptOut == true` → 「名無し探検家」表示）

**#8 プライバシーポリシー更新（ランキング公開前に必ず実施）:**
設計書: [immediate-tasks-design.md](.claude/plans/immediate-tasks-design.md)
- [ ] `PRIVACY_POLICY.md` にランキング公開情報セクション追加（ランキングでユーザー名・アイコンが公開される旨・オプトアウト方法）

---

## フェーズ3: 月次レポート・バッジ拡充

> **設計プラン未作成。フェーズ2完了後に設計から着手する。**

### 設計が必要なテーマ

| テーマ | 概要 |
|--------|------|
| 月次探検レポート | Scheduled Cloud Functions（月末配信）・レポート専用画面・SNSシェア文生成 |
| バッジ追加 | 秘境探検家シリーズ（4段階）・ジャンル別コンプリート・週次ミッション達成バッジ |

### フェーズ3設計時に合わせて検討する未設計機能

以下の項目は BUSINESS_MODEL.md に記載があるが具体的な設計書が存在しない。

| 未設計機能 | BUSINESS_MODEL.md での状態 |
|-----------|--------------------------|
| 週次ミッション（来店促進1週間ミッション） | 「ユーザー行動データを見て導入時期を判断」 |
| エリア100%達成時の処理 | 「後日検討（未定）」 |
| 秘境専用バッジシリーズの実装設計 | 概念・バッジ条件表のみ |
| 招待人数に応じた称号バッジ | 「ゲーム機能が整った段階で検討」 |
| SNSシェア機能（マイ探検マップ） | 月次探検レポートと連動 |
| 投稿ピン留め・パーソナライズフィード | 「将来方針」として記載のみ |

---

## 全体の依存関係マップ

```
フェーズ0（事前準備）
  ├─ immediate-tasks-design.md #13   FIRESTORE.md 更新（nfcCheckin修正前）
  ├─ immediate-tasks-design.md #10   ウェルカムお知らせ更新 → デプロイ
  └─ immediate-tasks-design.md #9    STORE_AGREEMENT.md 作成（運用タスク）

フェーズ1
  ├─ nfc-zukan-flow-redesign.md      ←── 最初（Cloud Functions + スタンプ救済措置 + モデル変更）
  │   ※ block-a-cloud-functions.md のコイン削除・フォロー source 変更の詳細も参照
  │       ↓
  ├─ zukan-view-design.md            ←── nfc-zukan と並行（ZukanView・ZukanCardWidget 詳細実装）
  │       ↓
  ├─ ui-navigation-redesign-3tabs.md ←── 3タブ化
  │   + immediate-tasks-design.md #11（廃止バッジ処理）同時実施
  │   + immediate-tasks-design.md #12（紹介UI廃止）同時実施
  │       ↓
  ├─ business-model-simplification.md ←── UIのみ（Cloud Functions は nfc-zukan で対応済み）
  ├─ kpi-redefinition.md              ←── 並行実装可
  └─ immediate-tasks-design.md #14   ←── フェーズ1完了後（USER_APP_SCREENS.md 更新）

フェーズ2（フェーズ1完了後）
  ├─ area-system-design.md           ←── フェーズ2の最初
  │       ↓
  ├─ map-extension-design.md         ←── area-system 完了後
  └─ ranking-redesign.md             ←── フェーズ1 nfc-zukan 完了後ならいつでも可
      + immediate-tasks-design.md #7  ランキングオプトアウト（同時実施）
      + immediate-tasks-design.md #8  プライバシーポリシー更新（ランキング公開前）

フェーズ3（フェーズ2完了後）
  ├─ 月次探検レポートプラン（未作成）
  ├─ バッジ追加プラン（未作成）
  └─ その他未設計機能のプラン作成
```

---

## 設計書一覧

| 設計書 | フェーズ | ステータス | 備考 |
|--------|---------|-----------|------|
| [nfc-zukan-flow-redesign.md](.claude/plans/nfc-zukan-flow-redesign.md) | 1 | 設計完了 | **Cloud Functions の正規仕様（スタンプ救済措置）** |
| [block-a-cloud-functions.md](.claude/plans/block-a-cloud-functions.md) | 1 | 設計完了 | コイン削除・フォロー source の詳細参照用 |
| [zukan-view-design.md](.claude/plans/zukan-view-design.md) | 1 | 設計完了 | ZukanView・ZukanCardWidget の詳細実装定義 |
| [ui-navigation-redesign-3tabs.md](.claude/plans/ui-navigation-redesign-3tabs.md) | 1 | 設計完了 | |
| [business-model-simplification.md](.claude/plans/business-model-simplification.md) | 1 | 設計完了 | **UIのみ参照**。Cloud Functions は nfc-zukan を優先 |
| [kpi-redefinition.md](.claude/plans/kpi-redefinition.md) | 1 | 設計完了 | |
| [immediate-tasks-design.md](.claude/plans/immediate-tasks-design.md) | 0〜2 | 設計完了 | #9〜#14: フェーズ0〜2で随時実施 |
| [area-system-design.md](.claude/plans/area-system-design.md) | 2 | 設計完了 | |
| [map-extension-design.md](.claude/plans/map-extension-design.md) | 2 | 設計完了 | |
| [ranking-redesign.md](.claude/plans/ranking-redesign.md) | 2 | 設計完了 | |
| 月次探検レポートプラン | 3 | 未作成 | |
| バッジ追加プラン | 3 | 未作成 | |
| 週次ミッションプラン | 未定 | 未作成 | |
| 秘境バッジ実装プラン | フェーズ3 | 未作成 | |
