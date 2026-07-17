# 実装ロードマップ

> 最終更新: 2026-03-06（フェーズ0完了・フェーズ1 全ステップ完了・フェーズ2 全ステップ完了・フェーズ3 全ステップ完了・フェーズ4-A 完了・フェーズ4-B 完了）
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
フェーズ3: 月次レポート・バッジ拡充（設計書完成済み・フェーズ2完了後に実装着手）
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

## フェーズ0: 事前準備（完了）

> 設計書: [immediate-tasks-design.md](.claude/plans/immediate-tasks-design.md)
> **完了日: 2026-03-05**

- [x] **#13** `FIRESTORE.md` に `discoveredCount` / `rarityOverride` / `areaId` を追記（`nfcCheckin` 修正前）
- [x] **#10** `punchStamp` 内のウェルカムお知らせ文言を更新（コイン記述を削除）→ `firebase deploy --only functions:punchStamp`
- [x] **#9** `STORE_AGREEMENT.md` 新規作成（パイロット営業開始前・運用タスク）

---

## フェーズ1: 図鑑・3タブ化（完了）

> 設計書: `.claude/plans/` 配下に全て存在。**完了日: 2026-03-05**

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
- [x] `currentStamps >= 1` の既存ユーザーはスタンプ +1 加算継続（救済措置）
- [x] `currentStamps == 0` の新規ユーザーはスタンプ加算なし（来店記録のみ）
- [x] `isFirstVisit` フラグを追加（初回来店時のみ `stores/{storeId}.discoveredCount` を +1）
- [x] 来店ボーナスコイン付与を削除
- [x] スタンプ達成クーポン自動付与を削除
- [x] 自動フォローの `source` を `nfc_checkin` に変更
- [x] 戻り値を `{ storeName, stampsAfter, cardCompleted, isFirstVisit, awardedCoupons: [], usedCoupons, usageVerificationCode }` に変更

**`punchStamp` 関数の変更:**
- [x] `currentStamps >= 1` のユーザーのみスタンプ +1 加算（救済措置と整合）
- [x] スタンプ達成クーポン自動付与を削除
- [x] 自動フォローの `source` を `punch_checkin` に変更

**デプロイ:**
- [x] `firebase deploy --only functions:nfcCheckin,functions:punchStamp`

---

#### ② NFC結果画面 → 図鑑発見演出 + 図鑑View詳細実装

設計書:
- [nfc-zukan-flow-redesign.md](.claude/plans/nfc-zukan-flow-redesign.md)（フロー・画面分岐ロジック）
- [zukan-view-design.md](.claude/plans/zukan-view-design.md)（ZukanView・ZukanCardWidget・Provider の詳細実装定義）

**モデル変更:**
- [x] `NfcCheckinResult` モデルに `isFirstVisit` 追加、`coinsAdded` 削除（`stampsAfter`, `cardCompleted` は救済措置のため維持）

**新規ファイル作成（zukan-view-design.md に従う）:**
- [x] `lib/providers/zukan_provider.dart`（`zukanAllStoresProvider`, `userVisitedStoreIdsProvider`, `zukanStoresProvider`, `userDiscoveredStoreCountProvider`, `ZukanStoreItem` クラス）
- [x] `lib/widgets/zukan_card_widget.dart`（発見済み/未発見の2モードカード。カテゴリアイコン・カラーは `StampCardWidget` を static import で流用）
- [x] `lib/views/zukan/zukan_view.dart`（図鑑タブ。フィルター・ソート・グリッド・開拓サマリーバー）

**NFC結果画面の変更:**
- [x] `nfc_checkin_result_view.dart` に `stampsAfter >= 1` による分岐を追加
  - スタンプ保有者: スタンプ押印アニメーション → 「カードを見る」ボタン → 図鑑カード画面
  - 新規ユーザー: 直接図鑑カード画面へ
- [x] 図鑑カード画面を新規作成（`lib/views/zukan/zukan_card_view.dart`）（初発見: フリップアニメーション + 「発見！」演出 / 再訪: 「○回目の来店」静的表示）

**ホーム画面の変更:**
- [x] 統計カプセルバーの「スタンプ数」を「発見店舗数」に変更（`userDiscoveredStoreCountProvider` を使用）

---

#### ③ 3タブ化・ZukanView・ProfileView 強化（#11・#12 を同時実施）

設計書: [ui-navigation-redesign-3tabs.md](.claude/plans/ui-navigation-redesign-3tabs.md)

**ナビゲーション変更:**
- [x] `MainNavigationView` を3タブ化（マップ / 図鑑 / アカウント）・FAB削除
- [x] 初期タブを MapView（index 0）に固定
- [x] 図鑑タブに `ZukanView` を配置（②で作成済み）

**ProfileView 強化:**
- [x] 探検統計カード追加（発見店舗数・バッジ数・ランキング順位）
- [x] ヘッダー右上に通知ベルアイコン追加（未読バッジ付き）
- [x] QRコードフォールバックボタン追加（グレーの小テキストボタン・ログアウトの上）
- [x] 「バッジ一覧」「ランキング」「通知・お知らせ」を「ゲーム」セクションとして上部に移動

**ウォークスルー更新:**
- [x] ④「図鑑タブで発見済み店舗を確認」に変更

**#12 紹介UIの廃止（同時実施）:**
設計書: [immediate-tasks-design.md](.claude/plans/immediate-tasks-design.md)
- [x] `home_view.dart` から「友達を紹介する」ボタン・`FriendReferralView` への導線を削除
- [x] ルーティング定義から `FriendReferralView` への Route を削除（ファイル自体は残す）

**#11 廃止バッジ処理（同時実施）:**
設計書: [immediate-tasks-design.md](.claude/plans/immediate-tasks-design.md)
- [x] `BADGE_LIST.md` にコイン獲得バッジ5個・ミッション達成バッジ5個（計10個）に「廃止・獲得不可」の注記を追加
- [x] `missions_view.dart` から `incrementBadgeCounter('coinsEarned')` / `incrementBadgeCounter('missionCompleted')` を削除

---

#### ④ ビジネスモデル簡素化（コイン・クーポンUI削除）

設計書: [business-model-simplification.md](.claude/plans/business-model-simplification.md)（**UIの削除・非表示のみ参照。Cloud Functions の変更は①で実施済み**）

- [x] `home_view.dart` のコイン交換セクション・ミッションFAB・コイン残高表示を削除
- [x] `home_view.dart` のウォークスルーのステップ数を短縮（コイン関連ステップを削除）
- [x] 特別クーポンセクション・クーポンショートカットを非表示

---

#### ⑤ KPI再定義

設計書: [kpi-redefinition.md](.claude/plans/kpi-redefinition.md)

- [x] `store_stats/daily.visitorCount` の更新条件を確認・修正（NFCチェックインの `type='stamp'` でも +1 されるか検証）
- [x] `BUSINESS_MODEL.md` の KPI セクションを更新（スタンプベース → `firstVisitAt` ベース）

---

#### ⑥ ドキュメント更新

- [x] **#14** `USER_APP_SCREENS.md` を3タブ構成（マップ / 図鑑 / アカウント）に更新（フェーズ1完了後）
- [x] `FIRESTORE.md` に未追記の項目があれば補完（フェーズ0 #13 の残り分）（`discoveredCount` / `rarityOverride` / `areaId` はすでに追記済みを確認）

---

## フェーズ2: 地図塗り・エリア・ランキング刷新（完了）

> 設計書: `.claude/plans/` 配下に存在。**完了日: 2026-03-06**

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
- [x] `lib/models/area_model.dart` 新規作成
- [x] `lib/providers/area_provider.dart` 新規作成（`areasProvider`, `areaExplorationRateProvider`）
- [x] `map_view.dart` に `_loadAreas()` / `_buildAreaCircles()` 追加
- [x] `store_detail_view.dart` に「秘境スポット」バッジ追加（`areaId == null` の場合）
- [x] `lib/views/area/area_exploration_view.dart` 新規作成（エリア開拓率一覧）
- [x] `firestore.rules` に `areas` コレクションのルール追加 → `firebase deploy --only firestore:rules`（※Firebase再認証後にデプロイ要）
- [x] `FIRESTORE.md` に `areas` コレクション・`stores.areaId` を追記

---

#### ② マップ拡張

設計書: [map-extension-design.md](.claude/plans/map-extension-design.md)

**前提:** エリアシステム（①）の `_loadAreas()` / `_areaCircles` が実装済みであること

**実装タスク:**
- [x] `nfcCheckin` Cloud Function に `users/{uid}/stores/{storeId}.totalVisits` ミラー書き込みを追加 → `firebase deploy --only functions:nfcCheckin`（※Firebase再認証後にデプロイ要）
- [x] `map_view.dart` に `_personalMapMode` / `_communityMapMode` / `_communitySubMode` フィールド追加
- [x] `_setMapMode()` で既存フラグ管理を統一
- [x] `_resolveMarkerVisual()` に `storeId` 引数追加・個人マップロジック追加（5段階ステータス）
- [x] `_buildFilterChips()` に「個人マップ」「コミュニティ」チップ追加
- [x] `_buildActivityCircles()` 実装（賑わい度 Circle オーバーレイ）
- [x] `_buildCommunitySubModeToggle()` UI 実装（開拓率 / 賑わい度トグル）
- [x] `GoogleMap` ウィジェットに `circles: _getActiveCircles()` を追加

---

#### ③ ランキング刷新（+ #7・#8 を同時実施）

設計書: [ranking-redesign.md](.claude/plans/ranking-redesign.md)

**前提:** フェーズ1の `nfcCheckin`（`isFirstVisit` 追加）が完了していること

**実装タスク:**
- [x] `lib/models/ranking_model.dart` — `RankingType` enum に `discoveredStoreCount` 追加（先頭・デフォルト）、`RankingModel` にフィールド追加
- [x] `flutter pub run build_runner build`（freezed コード再生成）
- [x] `lib/providers/ranking_provider.dart` — `_getRankingFromScores()` / `_buildPeriodId()` 追加
- [x] `lib/views/ranking/leaderboard_view.dart` — デフォルト指標変更・ラベル追加・全ユーザーに開放
- [x] `firestore.rules` に `ranking_scores` コレクションのルール追加 → `firebase deploy --only firestore:rules`
- [x] `nfcCheckin` Cloud Function に `discoveredStoreCount` インクリメント + `ranking_scores` batch 更新を追加 → `firebase deploy --only functions:nfcCheckin`
- [x] `FIRESTORE.md` に `users.discoveredStoreCount` / `ranking_scores` コレクションを追記

**#7 ランキングオプトアウト設定（同時実施）:**
設計書: [immediate-tasks-design.md](.claude/plans/immediate-tasks-design.md)
- [x] `users/{uid}.rankingOptOut: bool` フィールド追加（デフォルト: false）
- [x] `notification_settings_view.dart` に「ランキング設定」セクション・トグル追加
- [x] ランキング取得時の匿名化ロジック追加（`rankingOptOut == true` → 「名無し探検家」表示）

**#8 プライバシーポリシー更新（ランキング公開前に必ず実施）:**
設計書: [immediate-tasks-design.md](.claude/plans/immediate-tasks-design.md)
- [x] `PRIVACY_POLICY.md` にランキング公開情報セクション追加（ランキングでユーザー名・アイコンが公開される旨・オプトアウト方法）

---

## フェーズ3: 月次レポート・バッジ拡充（完了）

> 設計書: `.claude/plans/` 配下に存在。**完了日: 2026-03-06**

### 設計書

| 設計書 | テーマ | ステータス |
|--------|--------|-----------|
| [monthly-report-design.md](.claude/plans/monthly-report-design.md) | 月次探検レポート | 設計完了 |
| [badge-expansion-design.md](.claude/plans/badge-expansion-design.md) | バッジ追加（秘境・コンプリート・週次ミッション） | 設計完了 |

---

### 推奨実装順序

```
フェーズ3-A: バッジ定義・画像（前提なし・先行着手可）
    ↓
フェーズ3-B: 秘境探検家バッジ + ジャンル別コンプリートバッジ
    （エリアシステム完了が前提）
    ↓
フェーズ3-C: 月次探検レポート（Scheduled Functions + 専用画面 + SNSシェア）
    （フェーズ2 全完了が前提）
    ↓
フェーズ3-D: 週次ミッション達成バッジ
    （週次ミッション機能の実装と同時）
```

---

### タスク一覧

#### フェーズ3-A: バッジ定義・画像

設計書: [badge-expansion-design.md](.claude/plans/badge-expansion-design.md)

- [x] `lib/data/badge_definitions.dart` に18種を追記（秘境4 + コンプリート10 + 週次4）
- [x] `BADGE_LIST.md` に新バッジ18種を追記
- [x] `badge-image-gen` スキルで18種の画像生成・`assets/images/badges/` に配置

---

#### フェーズ3-B: 秘境探検家バッジ + ジャンル別コンプリートバッジ

設計書: [badge-expansion-design.md](.claude/plans/badge-expansion-design.md)

**前提:** フェーズ2 エリアシステム完了（`stores.areaId` 設定済み）

**秘境探検家シリーズ（4段階）:**
- [x] Cloud Functions: `nfcCheckin` に `hiddenExplorer` カウンターインクリメント追加
  - `isFirstVisit == true && store.areaId == null` の場合にカウント
  - 全エリア外店舗制覇チェック（`hidden_explorer_4` 付与ロジック）
- [x] Flutter: `NfcCheckinResult` に `hiddenExplorerIncremented` フィールド追加（`nfc_checkin_service.dart`）
- [x] Flutter: `nfc_checkin_result_view.dart` に秘境バッジトリガー追加
- [x] `firebase deploy --only functions:nfcCheckin`

**ジャンル別コンプリートバッジ（10個）:**
- [x] Cloud Functions: `nfcCheckin` にジャンルコンプリートチェック追加
  - `isFirstVisit == true` 時に当該ジャンルの全店舗訪問済みを確認
  - 達成時に `genre_complete_{group}` バッジ付与
- [x] `firebase deploy --only functions:nfcCheckin`

---

#### フェーズ3-C: 月次探検レポート

設計書: [monthly-report-design.md](.claude/plans/monthly-report-design.md)

**前提:** フェーズ2（エリアシステム・マップ拡張・ランキング刷新）全完了

**Firestore スキーマ追加:**
- [x] `FIRESTORE.md` に `monthly_reports` / `monthly_reports_community` コレクションを追記

**Cloud Functions:**
- [x] `generateMonthlyReport` 関数新規作成（Scheduled: 毎月末 23:00 JST）
  - アクティブユーザー一覧取得
  - ユーザーごと個人レポートデータ集計（バッチ100件）
  - `monthly_reports/{userId}/reports/{yyyy-MM}` に書き込み
  - FCM プッシュ通知送信
- [x] `firebase deploy --only functions:generateMonthlyReport`

**Firestore ルール:**
- [x] `monthly_reports` / `monthly_reports_community` のルール追加
- [x] `firebase deploy --only firestore:rules`

**Flutter:**
- [x] `lib/models/monthly_report_model.dart` 新規作成
- [x] `lib/providers/monthly_report_provider.dart` 新規作成
- [x] `lib/views/report/monthly_report_view.dart` 新規作成
  - 個人データ・コミュニティデータ・来月おすすめ・SNSシェアエリア
- [x] `lib/utils/share_text_generator.dart` 新規作成（SNSシェア文生成）
- [x] DeepLink ルーティング追加（`/monthly_report/{yearMonth}`）
- [x] `ProfileView` に「過去のレポート」ボタン追加

**ドキュメント更新:**
- [x] `USER_APP_SCREENS.md` に月次レポート画面を追記

---

#### フェーズ3-D: 週次ミッション達成バッジ

設計書: [badge-expansion-design.md](.claude/plans/badge-expansion-design.md)

**前提:** 週次ミッション機能の実装（フェーズ3 内で並行設計）

- [x] Cloud Functions: `checkWeeklyMission` 新規作成
  - 週次ミッション達成判定（未訪問店舗1件 + 週3回来店）
  - 達成時に `weeklyMission` カウンターインクリメント
  - バッジ付与（`weekly_mission_{N}`）
  - 発見ヒント処理（近くのレジェンド店舗ピンを点滅通知）
- [x] `firebase deploy --only functions:checkWeeklyMission`
- [x] Flutter: `MissionsView` 更新（週次ミッション進捗表示）
- [x] Flutter: ミッション達成時のバッジ付与トリガー追加

---

### フェーズ3設計時に合わせて検討する未設計機能

以下の項目は BUSINESS_MODEL.md に記載があるが具体的な設計書が存在しない。

| 未設計機能 | BUSINESS_MODEL.md での状態 |
|-----------|--------------------------|
| エリア100%達成時の処理 | 「後日検討（未定）」 |
| 招待人数に応じた称号バッジ | 「ゲーム機能が整った段階で検討」 |
| 投稿ピン留め・パーソナライズフィード | 「将来方針」として記載のみ |

---

## フェーズ4: 管理者UI（エリア管理・店舗設定）

> 設計書: [area-admin-ui-design.md](.claude/plans/area-admin-ui-design.md)
> **フェーズ3完了後に着手。**

### 背景

フェーズ2でエリアシステムのコードは実装済みだが、以下がFirestoreコンソール手動作業のまま残っている。本フェーズでオーナー専用UIに移行する。

| 未設定項目 | 現状 |
|-----------|------|
| `areas` コレクションのデータ | Firestoreコンソールで手動作成が必要 |
| `stores.areaId` | Firestoreコンソールで手動設定が必要 |
| `stores.rarityOverride` | 実質未実装（UIなし） |

### タスク一覧

#### フェーズ4-A: エリア管理UI

設計書: [area-admin-ui-design.md](.claude/plans/area-admin-ui-design.md)

**実装先:** 店舗用アプリ（`/Users/kanekohiroki/Desktop/groumapapp_store`）

- [x] `lib/providers/area_admin_provider.dart` 新規作成（`areasAdminProvider` / CRUD メソッド）
- [x] `lib/views/settings/area_management_view.dart` 新規作成（エリア一覧・`isOwner` チェック）
- [x] `lib/views/settings/area_edit_view.dart` 新規作成（フォーム・flutter_mapプレビュー・現在地取得）
- [x] `owner_settings_view.dart` に「ゲーム設定」セクション追加
  - `_buildNavigationRow` ヘルパーを追加
  - `AreaManagementView` 遷移ボタン
  - `StoreAreaRarityView` 遷移ボタン（4-B で実装）

---

#### フェーズ4-B: 店舗エリア・レア度設定UI + Firestoreルール更新

設計書: [area-admin-ui-design.md](.claude/plans/area-admin-ui-design.md)

**前提:** フェーズ4-A（OwnerSettingsView への「ゲーム設定」セクション追加）が完了していること

**店舗用アプリ:**
- [x] `lib/views/settings/store_area_rarity_view.dart` 新規作成
  - 全承認済み店舗一覧（`isApproved=true` かつ `isOwner=false`）
  - 店舗名検索フィルター
  - 編集ボトムシート（エリア選択 + `rarityOverride` 選択 + `discoveredCount` 参考表示）
  - `areaId` / `rarityOverride` を Firestore に書き込み

**Firestoreルール（`/Users/kanekohiroki/Desktop/groumapapp/firestore.rules`）:**
- [x] `updatesRestrictedFields()` 関数を追加（`areaId` / `rarityOverride` / `isApproved` / `isOwner` / `founderMember` をオーナー専用フィールドとして保護）
- [x] `stores/{storeId}` の `update` ルールを修正
- [x] `firebase deploy --only firestore:rules,firestore:indexes`

**ドキュメント更新:**
- [x] `FIRESTORE.md` の `areas` コレクション・`stores.areaId` の管理方法を「管理者UIで設定」に更新

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
  ├─ 3-A: バッジ定義・画像（badge-expansion-design.md）← 先行着手可
  ├─ 3-B: 秘境バッジ + ジャンルコンプリート（badge-expansion-design.md）← エリアシステム後
  ├─ 3-C: 月次探検レポート（monthly-report-design.md）← フェーズ2全完了後
  └─ 3-D: 週次ミッション達成バッジ（badge-expansion-design.md）← ミッション機能実装と同時

フェーズ4（フェーズ3完了後）
  ├─ 4-A: エリア管理UI（area-admin-ui-design.md）← 先行着手可
  │       AreaManagementView + AreaEditView（店舗アプリ）
  │       OwnerSettingsView に「ゲーム設定」セクション追加
  └─ 4-B: 店舗エリア・レア度設定UI（area-admin-ui-design.md）
          StoreAreaRarityView（店舗アプリ）
          + Firestoreルール更新（updatesRestrictedFields 追加）← 同時実施
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
| [monthly-report-design.md](.claude/plans/monthly-report-design.md) | 3 | 設計完了 | Scheduled Functions・専用画面・SNSシェア |
| [badge-expansion-design.md](.claude/plans/badge-expansion-design.md) | 3 | 設計完了 | 秘境探検家・コンプリート・週次ミッション（計18種） |
| 週次ミッションプラン | 3 | 未作成 | badge-expansion-design.md と連動 |
| [area-admin-ui-design.md](.claude/plans/area-admin-ui-design.md) | 4 | 設計完了 | エリア管理UI・店舗エリア/レア度設定UI（店舗アプリ・オーナー専用） |
