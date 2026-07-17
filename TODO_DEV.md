# 開発 TODO（ぐるまっぷ）

> 最終更新: 2026-03-05（フェーズ1〜2前の小タスク群を設計・追加）
> ゲーム性（図鑑・地図塗り）を主軸とした設計変更に伴う、実装の残タスク一覧。

---

## フェーズ1: 図鑑・3タブ化（実装着手可能）

設計プランは全て `.claude/plans/` 配下に作成済み。

### Cloud Functions / バックエンド

- [ ] **`nfcCheckin` 修正**（スタンプ救済措置 + isFirstVisit + discoveredCount）
  - `currentStamps >= 1` のユーザーにのみスタンプ +1（救済措置）、`== 0` は来店記録のみ
  - `isFirstVisit` フラグを戻り値に追加
  - 初回来店時に `stores/{storeId}.discoveredCount` を +1（トランザクション内）
  - 来店ボーナスコイン付与を削除（友達紹介コインは維持）
  - スタンプ達成クーポン自動付与を削除
  - 自動フォローの source を `'nfc_checkin'` に変更
  - プラン: **`nfc-zukan-flow-redesign.md` Phase 1**（block-a の nfcCheckin 部分を上書き）

- [ ] **`punchStamp` 修正**
  - スタンプ計算削除（全ユーザー・全店舗）
  - スタンプ達成クーポン自動付与を削除
  - 自動フォローの source を `'punch_checkin'` に変更
  - プラン: **`block-a-cloud-functions.md`**

- [ ] **`store_stats/daily.visitorCount` のバグ確認・修正**
  - `updateStoreDailyStats` トリガー関数の有無を検索してから対応
  - プラン: **`kpi-redefinition.md`**

### Flutter / フロントエンド

- [ ] **`NfcCheckinResult` モデル更新** (`lib/services/nfc_checkin_service.dart`)
  - `isFirstVisit` フィールド追加、`coinsAdded` 削除
  - プラン: **`nfc-zukan-flow-redesign.md` Phase 1-3**

- [ ] **図鑑Provider新規作成** (`lib/providers/zukan_provider.dart`)
  - `zukanAllStoresProvider`, `userVisitedStoreIdsProvider`, `zukanStoresProvider`, `userDiscoveredStoreCountProvider`
  - `ZukanStoreItem` クラス（レア度計算ロジック含む）
  - プラン: **`zukan-view-design.md`**

- [ ] **ZukanCardWidget新規作成** (`lib/widgets/zukan_card_widget.dart`)
  - 発見済み/未発見の2モード表示
  - `StampCardWidget.getCategoryIcon()` / `getCategoryColor()` 流用（新規アセット不要）
  - プラン: **`zukan-view-design.md`**

- [ ] **ZukanView（図鑑タブ）新規作成** (`lib/views/zukan/zukan_view.dart`)
  - 発見済み/未発見フィルター、カテゴリ/エリア/レア度ソート、2列グリッド、開拓サマリーバー
  - プラン: **`zukan-view-design.md`**

- [ ] **3タブ化（MainNavigationView）**
  - `[ホーム, マップ, QR, 投稿, アカウント]` → `[マップ, 図鑑, アカウント]`
  - FAB（QRボタン）削除
  - プラン: **`ui-navigation-redesign-3tabs.md`**

- [ ] **NFC結果画面を分岐対応に差し替え** (`lib/views/checkin/nfc_checkin_result_view.dart`)
  - `stampsAfter >= 1`: スタンプ押印アニメーション → 「カードを見る」ボタン → 図鑑カード画面
  - `stampsAfter == 0`: 図鑑カード画面へ直接遷移（フリップアニメーション + 「発見！」）
  - プラン: **`nfc-zukan-flow-redesign.md` Phase 3**

- [ ] **アカウント画面（ProfileView）強化**
  - 探検統計カード（発見店舗数・バッジ数・ランキング順位）追加
  - ヘッダー右上に通知ベルアイコン移設
  - QRコードフォールバックボタン追加（目立たない場所に）
  - プラン: **`ui-navigation-redesign-3tabs.md`**

- [ ] **ホーム画面のコイン関連UI削除**
  - コイン交換セクション・ミッションFAB・ステータスバーのコイン表示を削除
  - プラン: **`business-model-simplification.md` Phase 2**

- [ ] **ウォークスルー更新（新タブ対応）**
  - ④「ホームタブに戻る」→「図鑑タブで発見済み店舗を確認」に変更
  - プラン: **`ui-navigation-redesign-3tabs.md`**

---

## フェーズ1: 小タスク（設計不要）

- [ ] **紹介UIの廃止**
  - `ProfileView` の「友達を紹介する」導線を削除
  - `FriendReferralView` へのルーティングを削除
  - バックエンド（`processFriendReferral` / `referral_uses`）は**維持**
  - 新規登録フロー（`UserInfoView`）の紹介コード入力欄は**維持**

- [ ] **ウェルカムお知らせ更新**（`backend/functions/src/index.ts`）
  - `punchStamp` 内の紹介通知タイトル・本文からコイン記述を削除
    - 被紹介者: `'友達紹介コイン獲得'` → `'ようこそぐるまっぷへ！'`
    - 紹介者: `'友達紹介コイン獲得'` → `'お友達が登録しました！'`
  - `processFriendReferral` にウェルカムお知らせ作成を追加（`users/{uid}/notifications`、`type:'social'`、`tags:['referral','welcome']`）
  - デプロイ: `firebase deploy --only functions:punchStamp,processFriendReferral`
  - プラン: **`immediate-tasks-design.md` #10**

- [ ] **廃止バッジの整理**
  - `BADGE_LIST.md` にコイン獲得（5個）・ミッション達成（5個）の「廃止・獲得不可」注記を追加
  - `lib/views/missions/missions_view.dart` から `incrementBadgeCounter('coinsEarned')` / `incrementBadgeCounter('missionCompleted')` を削除
  - スタンプカード達成バッジ（4個）はフェーズ1のスタンプ廃止実装と同時に対応
  - プラン: **`immediate-tasks-design.md` #11**

---

## フェーズ2: 地図塗り（実装着手可能）

> フェーズ1完了後に着手。設計書は全て作成済み。

- [ ] **ランキング刷新実装**（オプトアウト設定を含む）
  - `nfcCheckin` で初回来店時に `users/{uid}.discoveredStoreCount` を +1
  - `ranking_scores/{periodId}/users/{userId}` コレクション（alltime/weekly/monthly/daily）を実装
  - `RankingType` enum に `discoveredStoreCount` 追加 → `flutter pub run build_runner build`
  - `leaderboard_view.dart` のデフォルト指標・ラベル・表示値変更
  - Firestoreルールに `ranking_scores` を追加
  - **ランキングオプトアウト設定を同時実装**:
    - `users/{uid}.rankingOptOut: bool` フィールド追加
    - `notification_settings_view.dart` に「ランキング設定」トグル追加
    - `ranking_provider.dart` にオプトアウトユーザーの匿名化ロジック追加（「名無し探検家」）
  - プラン: **`ranking-redesign.md`** / **`immediate-tasks-design.md` #7**

- [ ] **エリアシステム実装**
  - `areas` コレクション作成（Firestoreコンソールで手動）
  - `lib/models/area_model.dart` 新規作成
  - `lib/providers/area_provider.dart` 新規作成
  - `map_view.dart` にエリアサークルオーバーレイ追加（`_loadAreas()`, `_buildAreaCircles()`）
  - `store_detail_view.dart` に「秘境スポット」バッジ追加
  - `lib/views/area/area_exploration_view.dart` 新規作成
  - Firestoreルールに `areas` を追加
  - プラン: **`area-system-design.md`**

- [ ] **マップ拡張実装**
  - 個人マップレイヤー（`totalVisits` 5段階ピン色変化）
  - コミュニティマップ（エリア開拓率 / 賑わい度 サブモードトグル）
  - `nfcCheckin` に `users/{uid}/stores/{storeId}.totalVisits` ミラー書き込み追加
  - プラン: **`map-extension-design.md`**

---

## フェーズ3: 月次レポート・バッジ拡充（設計プランが必要）

> フェーズ2完了後に着手。

- [ ] **【設計】月次探検レポートプラン作成**
  - Scheduled Cloud Functions（月末配信）の設計
  - レポート専用画面のUI設計
  - SNSシェア用テキスト自動生成ロジック

- [ ] **【設計】バッジ追加プラン作成**
  - 秘境探検家バッジシリーズ（エリア外店舗専用、4段階）
  - ジャンル別コンプリートバッジ
  - 週次ミッション達成バッジ（発見ヒント報酬）
  - `BADGE_LIST.md` への追記と実装トリガー設計

---

## ドキュメント更新

- [ ] `FIRESTORE.md` に `stores/{storeId}.discoveredCount` / `rarityOverride` / `areaId` を追記
- [ ] `USER_APP_SCREENS.md` を3タブ構成に更新（フェーズ1完了後）
- [ ] `PRIVACY_POLICY.md` にランキング公開情報の記述を追加（ランキング刷新実装前・フェーズ2前）
  - 第4条（利用目的）にランキング公開情報を追記
  - 「ランキング機能に関する公開情報」セクションを新規追加
  - プラン: **`immediate-tasks-design.md` #8**

## パイロット運用準備

- [ ] **`STORE_AGREEMENT.md` 新規作成**（パイロット営業開始前）
  - 店舗掲載・NFCスタンド設置・100円引き特典・精算方法・解約条件を記載したA4一枚の簡易合意書
  - プラン: **`immediate-tasks-design.md` #9**

---

## メモ（未決定事項）

- エリア100%達成時の演出・処理
- 将来の収益化方式（現フェーズはゼロ）
