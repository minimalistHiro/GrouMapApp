# エージェントチーム実行ガイド

> 最終更新: 2026-03-06（フェーズ0完了・フェーズ1 全ステップ完了・フェーズ2 全ステップ完了・フェーズ3 全ステップ完了・フェーズ4 未着手）
> 目的: Claude Code エージェントチームを使ってフェーズ1〜4を段階的に実装するための手順書

---

## 目次

- [事前準備](#事前準備)
- [エージェントチームとは](#エージェントチームとは)
- [フェーズ0: 事前準備](#フェーズ0-事前準備の実行)
- [フェーズ1: 図鑑・3タブ化](#フェーズ1-図鑑3タブ化)
- [フェーズ2: 地図塗り・エリア・ランキング](#フェーズ2-地図塗りエリアランキング)
- [フェーズ3: 月次レポート・バッジ拡充](#フェーズ3-月次レポートバッジ拡充)
- [フェーズ4: 管理者UI（エリア管理・店舗設定）](#フェーズ4-管理者uiエリア管理店舗設定)
- [フェーズ完了後の手順書更新ルール](#フェーズ完了後の手順書更新ルール)

---

## 事前準備

### 1. エージェントチームを有効化する

`.claude/settings.json` に以下を追加：

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

### 2. Claude Code CLI を起動する

```bash
cd /Users/kanekohiroki/Desktop/groumapapp
claude
```

### 3. 実行前に必ず確認するファイル

実行前に以下のドキュメントの最新状態を把握しておくこと：

| ファイル | 確認目的 |
|---------|---------|
| `IMPLEMENTATION_ROADMAP.md` | 各フェーズのタスク一覧・チェックボックス状態 |
| `.claude/plans/nfc-zukan-flow-redesign.md` | Cloud Functions の正規仕様（スタンプ救済措置） |
| `.claude/plans/immediate-tasks-design.md` | #9〜#14 の各タスク詳細 |
| `FIRESTORE.md` | Firestoreスキーマ・ルール |

---

## エージェントチームとは

Claude Code のエージェントチームは、複数の Claude インスタンスがそれぞれ独立したコンテキストで並列・逐次作業を行う仕組みです。

- **チームリード（自分）**: 全体調整・タスクアサイン・完了確認
- **チームメイト（エージェント）**: 割り当てられたタスクを自律的に実行

### チームが有効な場面

- フロントエンド/バックエンドを同時に進めたいとき
- 互いに依存しない複数ファイルを並列で変更するとき
- 1つのフェーズ内で役割が明確に分かれているとき

### 注意事項

- エージェントチームは実験的機能のため、予期しない動作が起きることがある
- 初めてのフェーズは**逐次方式**で試してから、次フェーズでチーム方式に切り替えると安全
- 各エージェントへの指示には**設計書のファイルパスを必ず含める**
- Cloud Functions 変更後は**必ずデプロイまで指示に含める**

---

## フェーズ0: 事前準備の実行

> ステータス: 完了 (2026-03-05)

> このフェーズは完了済みです。以下のプロンプトはアーカイブとして保持しています。

### 逐次方式プロンプト（アーカイブ）

```
フェーズ0を実装してください。

参照ファイル:
- IMPLEMENTATION_ROADMAP.md（フェーズ0 セクション）
- .claude/plans/immediate-tasks-design.md（#10・#13 の詳細）

タスク（順番通りに実行）:
1. FIRESTORE.md に discoveredCount / rarityOverride / areaId フィールドを追記（#13）
   - stores/{storeId}.discoveredCount: int（NFCチェックイン初回来店時に +1）
   - stores/{storeId}.rarityOverride: int?（運営による手動レア度設定 1〜4）
   - stores/{storeId}.areaId: String?（エリア帰属ID、フェーズ2で使用）

2. backend/functions の punchStamp 関数内にある「ウェルカムお知らせ」生成ロジックを確認し、
   コイン獲得・コイン枚数に関する文言を削除してスタンプ獲得手順のみに更新する（#10）
   更新後: firebase deploy --only functions:punchStamp を実行

3. IMPLEMENTATION_ROADMAP.md のフェーズ0 チェックボックス（#10・#13）を [x] に更新する

完了後、変更したファイルの一覧と変更概要を報告してください。
```

---

## フェーズ1: 図鑑・3タブ化

> ステータス: 完了 (2026-03-05)

> このフェーズは完了済みです。以下のプロンプトはアーカイブとして保持しています。

### 重要ルール（フェーズ1 全体）

- Cloud Functions の正規仕様は `nfc-zukan-flow-redesign.md` を優先
- `block-a-cloud-functions.md` はコイン削除・フォロー source の詳細参照のみ
- `business-model-simplification.md` は UI 削除のみ参照（Cloud Functions は触らない）
- 実装後は必ず `flutter analyze` でエラー確認

---

### Step 1-①: バックエンド（Cloud Functions）（完了済み）

> このフェーズは完了済みです。以下のプロンプトはアーカイブとして保持しています。

```
フェーズ1 ① バックエンドを実装してください。

参照ファイル（必ず最初に全て読むこと）:
- IMPLEMENTATION_ROADMAP.md（フェーズ1 ① タスク一覧）
- .claude/plans/nfc-zukan-flow-redesign.md（★正規仕様。スタンプ救済措置あり）
- .claude/plans/block-a-cloud-functions.md（コイン削除・フォロー source の詳細）
- FIRESTORE.md（スキーマ確認）

実装タスク:

【nfcCheckin 関数の変更】
- currentStamps >= 1 の既存ユーザーはスタンプ +1 加算継続（救済措置）
- currentStamps == 0 の新規ユーザーはスタンプ加算なし（来店記録のみ）
- isFirstVisit フラグを追加（初回来店時のみ stores/{storeId}.discoveredCount を +1）
- 来店ボーナスコイン付与を削除
- スタンプ達成クーポン自動付与を削除
- 自動フォローの source を 'nfc_checkin' に変更
- 戻り値を { storeName, stampsAfter, cardCompleted, isFirstVisit, awardedCoupons: [], usedCoupons, usageVerificationCode } に変更

【punchStamp 関数の変更】
- currentStamps >= 1 のユーザーのみスタンプ +1 加算（救済措置と整合）
- スタンプ達成クーポン自動付与を削除
- 自動フォローの source を 'punch_checkin' に変更

デプロイ:
firebase deploy --only functions:nfcCheckin,functions:punchStamp

完了後:
- IMPLEMENTATION_ROADMAP.md のフェーズ1 ① チェックボックスを [x] に更新
- 変更したファイルと変更概要を報告
```

---

### Step 1-②: 図鑑UI（ZukanView）（完了済み）

> このフェーズは完了済みです。以下のプロンプトはアーカイブとして保持しています。

```
フェーズ1 ② 図鑑UIを実装してください。

参照ファイル（必ず最初に全て読むこと）:
- IMPLEMENTATION_ROADMAP.md（フェーズ1 ② タスク一覧）
- .claude/plans/zukan-view-design.md（ZukanView・ZukanCardWidget の詳細実装定義）
- .claude/plans/nfc-zukan-flow-redesign.md（NFC結果画面の分岐ロジック）
- FIRESTORE.md（discoveredCount フィールド確認）

実装タスク:

【モデル変更】
- NfcCheckinResult モデルに isFirstVisit: bool を追加
- NfcCheckinResult から coinsAdded を削除（stampsAfter, cardCompleted は維持）

【新規ファイル作成（zukan-view-design.md の仕様に従う）】
- lib/providers/zukan_provider.dart
  （zukanAllStoresProvider, userVisitedStoreIdsProvider, zukanStoresProvider,
   userDiscoveredStoreCountProvider, ZukanStoreItem クラス）
- lib/widgets/zukan_card_widget.dart
  （発見済み/未発見の2モードカード。StampCardWidget の getCategoryIcon/getCategoryColor を流用）
- lib/views/zukan/zukan_view.dart
  （図鑑タブ。フィルター・ソート・グリッド・開拓サマリーバー）

【NFC結果画面の変更】
- nfc_checkin_result_view.dart に stampsAfter >= 1 による分岐を追加
  - スタンプ保有者: スタンプ押印アニメーション → 「カードを見る」ボタン → 図鑑カード画面
  - 新規ユーザー: 直接図鑑カード画面へ
- 図鑑カード画面を新規作成
  - 初発見: フリップアニメーション + 「発見！」演出
  - 再訪: 「○回目の来店」静的表示

【ホーム画面の変更】
- 統計カプセルバーの「スタンプ数」を「発見店舗数」に変更（userDiscoveredStoreCountProvider を使用）

実装後: flutter analyze を実行してエラーがないことを確認

完了後:
- IMPLEMENTATION_ROADMAP.md のフェーズ1 ② チェックボックスを [x] に更新
- 変更したファイルと変更概要を報告
```

---

### Step 1-③: 3タブ化・ProfileView 強化（#11・#12 を同時実施）（完了済み）

> このフェーズは完了済みです。以下のプロンプトはアーカイブとして保持しています。

```
フェーズ1 ③ を実装してください。

参照ファイル（必ず最初に全て読むこと）:
- IMPLEMENTATION_ROADMAP.md（フェーズ1 ③ タスク一覧）
- .claude/plans/ui-navigation-redesign-3tabs.md（3タブ化の詳細設計）
- .claude/plans/immediate-tasks-design.md（#11 廃止バッジ処理・#12 紹介UI廃止）

実装タスク:

【ナビゲーション変更】
- MainNavigationView を3タブ化（マップ / 図鑑 / アカウント）
- FAB（フローティングボタン）を削除
- 初期タブを MapView（index 0）に固定
- 図鑑タブに ZukanView を配置（Step ② で作成済み）

【ProfileView 強化】
- 探検統計カード追加（発見店舗数・バッジ数・ランキング順位）
- ヘッダー右上に通知ベルアイコン追加（未読バッジ付き）
- QRコードフォールバックボタン追加（グレーの小テキストボタン・ログアウトの上）
- 「バッジ一覧」「ランキング」「通知・お知らせ」を「ゲーム」セクションとして上部に移動

【ウォークスルー更新】
- ④ステップを「図鑑タブで発見済み店舗を確認」に変更

【#12 紹介UIの廃止（同時実施）】
- profile_view.dart から「友達を紹介する」ボタン・FriendReferralView への導線を削除
- ルーティング定義から FriendReferralView への Route を削除（ファイル自体は残す）

【#11 廃止バッジ処理（同時実施）】
- BADGE_LIST.md にコイン獲得バッジ5個・ミッション達成バッジ5個（計10個）に「廃止・獲得不可」の注記を追加
- missions_view.dart から incrementBadgeCounter('coinsEarned') / incrementBadgeCounter('missionCompleted') を削除

実装後: flutter analyze を実行してエラーがないことを確認

完了後:
- IMPLEMENTATION_ROADMAP.md のフェーズ1 ③ チェックボックスを [x] に更新
- 変更したファイルと変更概要を報告
```

---

### Step 1-④: ビジネスモデル簡素化（コイン・クーポンUI削除）（完了済み）

> このフェーズは完了済みです。以下のプロンプトはアーカイブとして保持しています。

```
フェーズ1 ④ を実装してください。

参照ファイル（必ず最初に全て読むこと）:
- IMPLEMENTATION_ROADMAP.md（フェーズ1 ④ タスク一覧）
- .claude/plans/business-model-simplification.md（UIの削除・非表示のみ参照）

重要: Cloud Functions の変更は Step ① で実施済みのため、ここでは UI のみ変更する。

実装タスク:
- home_view.dart のコイン交換セクションを削除（非表示ではなく完全削除）
- home_view.dart のミッションFABを削除
- home_view.dart のコイン残高表示を削除
- home_view.dart のウォークスルーのコイン関連ステップを削除・短縮
- 特別クーポンセクションを非表示
- クーポンショートカットを非表示

実装後: flutter analyze を実行してエラーがないことを確認

完了後:
- IMPLEMENTATION_ROADMAP.md のフェーズ1 ④ チェックボックスを [x] に更新
- 変更したファイルと変更概要を報告
```

---

### Step 1-⑤: KPI再定義（完了済み）

> このフェーズは完了済みです。以下のプロンプトはアーカイブとして保持しています。

```
フェーズ1 ⑤ KPI再定義を実装してください。

参照ファイル（必ず最初に全て読むこと）:
- IMPLEMENTATION_ROADMAP.md（フェーズ1 ⑤ タスク一覧）
- .claude/plans/kpi-redefinition.md

実装タスク:
- store_stats/daily.visitorCount の更新条件を確認・修正
  （NFCチェックインの type='stamp' でも +1 されるか検証）
- BUSINESS_MODEL.md の KPI セクションを更新
  （スタンプベース → firstVisitAt ベースに文言修正）

完了後:
- IMPLEMENTATION_ROADMAP.md のフェーズ1 ⑤ チェックボックスを [x] に更新
- 変更したファイルと変更概要を報告
```

---

### Step 1-⑥: ドキュメント更新（完了済み）

> このフェーズは完了済みです。以下のプロンプトはアーカイブとして保持しています。

```
フェーズ1 ⑥ ドキュメント更新を実行してください。

タスク:
1. USER_APP_SCREENS.md を3タブ構成（マップ / 図鑑 / アカウント）に更新（#14）
   - 旧ホームタブ・投稿タブを削除
   - 図鑑タブの画面フローを追加
   - アカウントタブの変更を反映

2. FIRESTORE.md に未追記の項目があれば補完（フェーズ0 #13 の残り分）

3. IMPLEMENTATION_ROADMAP.md のフェーズ1 ⑥ チェックボックスを [x] に更新

完了後、更新したファイルの一覧と変更概要を報告してください。
```

---

### フェーズ1 チーム方式プロンプト（並列実行・上級者向け）

Step ①〜② を並列で実行したい場合：

```
フェーズ1 の Step ① と Step ② を並列でエージェントチームを使って実装してください。

プロジェクト: /Users/kanekohiroki/Desktop/groumapapp

チーム構成:

1. agent-backend（バックエンド担当）
   担当: Step ① - Cloud Functions 変更
   参照設計書:
     - .claude/plans/nfc-zukan-flow-redesign.md（★正規仕様）
     - .claude/plans/block-a-cloud-functions.md（コイン削除・フォロー source の詳細）
   完了条件: firebase deploy まで実行し、デプロイ成功を確認

2. agent-zukan（Zukan UI担当）
   担当: Step ② - 図鑑UI実装
   参照設計書:
     - .claude/plans/zukan-view-design.md
     - .claude/plans/nfc-zukan-flow-redesign.md（NFC結果画面の分岐ロジック）
   開始条件: agent-backend から「NfcCheckinResult モデルの isFirstVisit 追加完了」の
             メッセージを受け取ってから Flutter 側の変更を開始する
             （それ以前は Zukan Provider・Widget のみ実装する）
   完了条件: flutter analyze でエラーなし

共通ルール:
- 各自、作業開始前に担当設計書を全て読むこと
- FIRESTORE.md を参照して新規フィールドの確認を行うこと
- 完了したら IMPLEMENTATION_ROADMAP.md のチェックボックスを更新すること
- 作業完了時にチームリードへメッセージで完了報告を送ること
```

---

## フェーズ2: 地図塗り・エリア・ランキング

> ステータス: 完了 (2026-03-06)
> 設計書は全て `.claude/plans/` 配下に存在。

> このフェーズは完了済みです。以下のプロンプトはアーカイブとして保持しています。

### 依存関係

```
① エリアシステム（area-system-design.md）
    ↓
② マップ拡張（map-extension-design.md）

③ ランキング刷新（ranking-redesign.md）← ① ② と並行可能
```

### Step 2-①: エリアシステム（完了済み）

> このフェーズは完了済みです。以下のプロンプトはアーカイブとして保持しています。

```
フェーズ2 ① エリアシステムを実装してください。

参照ファイル（必ず最初に全て読むこと）:
- IMPLEMENTATION_ROADMAP.md（フェーズ2 ① タスク一覧）
- .claude/plans/area-system-design.md
- FIRESTORE.md

実装タスク:
- lib/models/area_model.dart 新規作成
- lib/providers/area_provider.dart 新規作成（areasProvider, areaExplorationRateProvider）
- map_view.dart に _loadAreas() / _buildAreaCircles() を追加
- store_detail_view.dart に「秘境スポット」バッジを追加（areaId == null の場合）
- lib/views/area/area_exploration_view.dart 新規作成（エリア開拓率一覧）
- firestore.rules に areas コレクションのルールを追加
  → firebase deploy --only firestore:rules
- FIRESTORE.md に areas コレクション・stores.areaId を追記

Firestore コンソールでの手動設定（コードではなく手順として記載）:
- areas コレクションにサンプルエリアを手動作成（蕨駅・川口駅・西川口駅）
- stores/{storeId} に areaId フィールドを手動設定

実装後: flutter analyze を実行してエラーがないことを確認

完了後:
- IMPLEMENTATION_ROADMAP.md のフェーズ2 ① チェックボックスを [x] に更新
- 変更したファイルと変更概要を報告
```

### Step 2-②: マップ拡張（完了済み）

> このフェーズは完了済みです。以下のプロンプトはアーカイブとして保持しています。

```
フェーズ2 ② マップ拡張を実装してください。

前提: エリアシステム（フェーズ2 ①）の _loadAreas() / _areaCircles が実装済みであること。

参照ファイル（必ず最初に全て読むこと）:
- IMPLEMENTATION_ROADMAP.md（フェーズ2 ② タスク一覧）
- .claude/plans/map-extension-design.md

実装後: flutter analyze を実行してエラーがないことを確認

完了後:
- IMPLEMENTATION_ROADMAP.md のフェーズ2 ② チェックボックスを [x] に更新
- 変更したファイルと変更概要を報告
```

### Step 2-③: ランキング刷新（#7・#8 同時実施）（完了済み）

> このフェーズは完了済みです。以下のプロンプトはアーカイブとして保持しています。

```
フェーズ2 ③ ランキング刷新を実装してください。

前提: フェーズ1 の nfcCheckin（isFirstVisit 追加）が完了していること。

参照ファイル（必ず最初に全て読むこと）:
- IMPLEMENTATION_ROADMAP.md（フェーズ2 ③ タスク一覧）
- .claude/plans/ranking-redesign.md
- .claude/plans/immediate-tasks-design.md（#7 ランキングオプトアウト・#8 プライバシーポリシー）
- FIRESTORE.md

実装タスク:
（IMPLEMENTATION_ROADMAP.md フェーズ2 ③ の全タスクを実行）

重要: ランキング公開前に必ず #8 プライバシーポリシー更新を実施すること

実装後: flutter analyze / firebase deploy を実行

完了後:
- IMPLEMENTATION_ROADMAP.md のフェーズ2 ③ チェックボックスを [x] に更新
- 変更したファイルと変更概要を報告
```

---

## フェーズ3: 月次レポート・バッジ拡充

> ステータス: 完了 (2026-03-06)

> このフェーズは完了済みです。以下のプロンプトはアーカイブとして保持しています。

### フェーズ3-A: バッジ定義・画像（完了済み・2026-03-06）

> このフェーズは完了済みです。以下のプロンプトはアーカイブとして保持しています。

```
フェーズ3-A を実装してください。

参照ファイル（必ず最初に全て読むこと）:
- IMPLEMENTATION_ROADMAP.md（フェーズ3-A タスク一覧）
- .claude/plans/badge-expansion-design.md（バッジ追加の詳細設計）
- BADGE_LIST.md（既存バッジ一覧・重複確認）

実装タスク（前提なし・先行着手可）:
1. lib/data/badge_definitions.dart に18種を追記
   - 秘境探検家シリーズ: hidden_explorer_1〜4（rare/epic/legendary/legendary）
   - ジャンル別コンプリート: genre_complete_{group} × 10（epic）
   - 週次ミッション: weekly_mission_1/5/10/25（common/rare/epic/legendary）

2. BADGE_LIST.md に新バッジ18種を追記（badge-expansion-design.md の「BADGE_LIST.md への追記内容」セクションを参照）

3. badge-image-gen スキルで18種の画像生成・assets/images/badges/ に配置

完了後:
- IMPLEMENTATION_ROADMAP.md のフェーズ3-A チェックボックスを [x] に更新
- 変更したファイルと変更概要を報告
```

---

### フェーズ3-B: 秘境バッジ + ジャンルコンプリートバッジ（完了済み・2026-03-06）

> このフェーズは完了済みです。以下のプロンプトはアーカイブとして保持しています。

**前提:** フェーズ2 エリアシステムの `stores.areaId` が実際のデータに設定済みであること

```
フェーズ3-B を実装してください。

参照ファイル（必ず最初に全て読むこと）:
- IMPLEMENTATION_ROADMAP.md（フェーズ3-B タスク一覧）
- .claude/plans/badge-expansion-design.md（秘境バッジ・ジャンルコンプリートの実装ロジック）
- FIRESTORE.md（stores.areaId フィールド確認）

実装タスク:

【秘境探検家シリーズ】
- Cloud Functions: nfcCheckin に hiddenExplorer カウンターインクリメント追加
  （isFirstVisit == true && store.areaId == null の場合）
- Flutter: BadgeProvider に hiddenExplorer チェックロジック追加
- Flutter: nfc_checkin_result_view.dart に秘境バッジトリガー追加
- firebase deploy --only functions:nfcCheckin

【ジャンル別コンプリートバッジ】
- Cloud Functions: nfcCheckin にジャンルコンプリートチェック追加
  （isFirstVisit == true 時に当該ジャンルの全店舗訪問済みを確認）
- firebase deploy --only functions:nfcCheckin

実装後: flutter analyze を実行してエラーがないことを確認

完了後:
- IMPLEMENTATION_ROADMAP.md のフェーズ3-B チェックボックスを [x] に更新
- 変更したファイルと変更概要を報告
```

---

### フェーズ3-C: 月次探検レポート（完了済み・2026-03-06）

> このフェーズは完了済みです。以下のプロンプトはアーカイブとして保持しています。

**前提:** フェーズ2（エリア・マップ拡張・ランキング刷新）全完了

```
フェーズ3-C を実装してください。

参照ファイル（必ず最初に全て読むこと）:
- IMPLEMENTATION_ROADMAP.md（フェーズ3-C タスク一覧）
- .claude/plans/monthly-report-design.md（月次レポートの詳細設計）
- FIRESTORE.md

実装タスク（推奨順序）:

1. FIRESTORE.md に monthly_reports / monthly_reports_community コレクションを追記

2. Cloud Functions: generateMonthlyReport 関数新規作成
   （Scheduled: 毎月末 23:00 JST・バッチ100件・FCM通知送信）
   firebase deploy --only functions:generateMonthlyReport

3. Firestore ルール: monthly_reports / monthly_reports_community を追加
   firebase deploy --only firestore:rules

4. Flutter 実装:
   - lib/models/monthly_report_model.dart 新規作成
   - lib/providers/monthly_report_provider.dart 新規作成
   - lib/views/report/monthly_report_view.dart 新規作成
   - lib/utils/share_text_generator.dart 新規作成
   - DeepLink ルーティング追加（/monthly_report/{yearMonth}）
   - ProfileView に「過去のレポート」ボタン追加

5. USER_APP_SCREENS.md に月次レポート画面を追記

実装後: flutter analyze を実行してエラーがないことを確認

完了後:
- IMPLEMENTATION_ROADMAP.md のフェーズ3-C チェックボックスを [x] に更新
- 変更したファイルと変更概要を報告
```

---

### フェーズ3-D: 週次ミッション達成バッジ（完了済み・2026-03-06）

> このフェーズは完了済みです。以下のプロンプトはアーカイブとして保持しています。

```
フェーズ3-D を実装してください。

参照ファイル（必ず最初に全て読むこと）:
- IMPLEMENTATION_ROADMAP.md（フェーズ3-D タスク一覧）
- .claude/plans/badge-expansion-design.md（週次ミッション達成バッジのロジック）
- BUSINESS_MODEL.md（来店促進1週間ミッション の仕様セクション）

実装タスク:
- Cloud Functions: checkWeeklyMission 新規作成
  （週次達成判定: 未訪問1件 + 週3回来店、達成時にバッジ付与 + 発見ヒント通知）
  firebase deploy --only functions:checkWeeklyMission
- Flutter: MissionsView 更新（週次ミッション進捗表示）
- Flutter: ミッション達成時のバッジ付与トリガー追加

実装後: flutter analyze を実行してエラーがないことを確認

完了後:
- IMPLEMENTATION_ROADMAP.md のフェーズ3-D チェックボックスを [x] に更新
- 変更したファイルと変更概要を報告
```

---

### 設計プラン作成（完了済み）

> このフェーズは完了済みです。以下のプロンプトはアーカイブとして保持しています。

```
フェーズ3 の設計プランを作成してください。

対象テーマ:
1. 月次探検レポート
   - Scheduled Cloud Functions（月末配信）
   - レポート専用画面の設計
   - SNSシェア文生成ロジック

2. バッジ追加
   - 秘境探検家シリーズ（4段階）
   - ジャンル別コンプリートバッジ
   - 週次ミッション達成バッジ

参照ファイル（背景理解のために読むこと）:
- BUSINESS_MODEL.md（将来検討事項・ゲーム性強化計画セクション）
- BADGE_LIST.md（既存バッジ一覧）
- IMPLEMENTATION_ROADMAP.md（フェーズ3 セクション）

設計書を .claude/plans/ 配下に以下のファイル名で作成してください:
- monthly-report-design.md
- badge-expansion-design.md

その後、IMPLEMENTATION_ROADMAP.md のフェーズ3 セクションに設計書へのリンクと
タスク一覧を追記してください。
```

---

## フェーズ4: 管理者UI（エリア管理・店舗設定）

> ステータス: 完了 (2026-03-06)

**背景:** フェーズ2でエリアシステムのコードは実装済みだが、`areas` コレクションのデータ登録と `stores.areaId` / `stores.rarityOverride` の設定がFirestoreコンソール手動作業のまま残っている。本フェーズでこれらをオーナー専用UIで管理できるようにする。

### 依存関係

```
フェーズ4-A: エリア管理UI（AreaManagementView + AreaEditView）
    ↓
フェーズ4-B: 店舗エリア・レア度設定UI（StoreAreaRarityView）
    + Firestoreルール更新（同時実施）
```

### 重要ルール（フェーズ4 全体）

- 編集権限は `users.isOwner == true` のユーザーのみ（`userIsOwnerProvider` で判定）
- `isStoreOwner`（個別店舗アカウント）は閲覧のみ・編集不可
- 既存の `OwnerSettingsView` に「ゲーム設定」セクションを追加して各サブページへ遷移する設計
- Firestoreルールで `areaId` / `rarityOverride` をオーナー専用フィールドとして保護する

---

### フェーズ4-A: エリア管理UI（完了済み）

> このフェーズは完了済みです。以下のプロンプトはアーカイブとして保持しています。

```
フェーズ4-A を実装してください。

参照ファイル（必ず最初に全て読むこと）:
- IMPLEMENTATION_ROADMAP.md（フェーズ4-A タスク一覧）
- .claude/plans/area-admin-ui-design.md（★本フェーズの正規仕様・必ず最初に読むこと）
- FIRESTORE.md（areas スキーマ確認）
- /Users/kanekohiroki/Desktop/groumapapp_store/lib/views/settings/owner_settings_view.dart（既存UIとの統合）
- /Users/kanekohiroki/Desktop/groumapapp/lib/models/area_model.dart（モデル参照）

実装タスク（店舗用アプリ: /Users/kanekohiroki/Desktop/groumapapp_store）:

1. lib/providers/area_admin_provider.dart を新規作成
   - areasAdminProvider（StreamProvider<List<AreaModel>>）
   - createArea() / updateArea() / deactivateArea() メソッド

2. lib/views/settings/area_management_view.dart を新規作成
   - エリア一覧 ListView（エリア名・半径・isActive表示）
   - isOwner チェック（閲覧/編集の切り替え）
   - AppBar右上に追加ボタン（isOwnerのみ表示）

3. lib/views/settings/area_edit_view.dart を新規作成
   - フォーム: エリア名（10文字以内）・説明・緯度・経度・半径(m)・色・表示順・isActive
   - Googleマッププレビュー（高さ200px、中心ピン＋Circleをリアルタイム表示）
   - 「現在地を使用」ボタン（geolocatorで取得）
   - 作成・更新・無効化（isActive: false）の3操作対応

4. owner_settings_view.dart に「ゲーム設定」セクションを追加
   - _buildNavigationRow ヘルパーを追加（area-admin-ui-design.md 参照）
   - AreaManagementView への遷移ボタン
   - StoreAreaRarityView への遷移ボタン（フェーズ4-B で実装予定のため NavRow のみ追加）

実装後: flutter analyze を実行してエラーがないことを確認

完了後:
- IMPLEMENTATION_ROADMAP.md のフェーズ4-A チェックボックスを [x] に更新
- 変更したファイルと変更概要を報告
```

---

### フェーズ4-B: 店舗エリア・レア度設定UI + Firestoreルール更新（完了済み）

> このフェーズは完了済みです。以下のプロンプトはアーカイブとして保持しています。

```
フェーズ4-B を実装してください。

前提: フェーズ4-A（OwnerSettingsView への「ゲーム設定」セクション追加）が完了していること。

参照ファイル（必ず最初に全て読むこと）:
- IMPLEMENTATION_ROADMAP.md（フェーズ4-B タスク一覧）
- .claude/plans/area-admin-ui-design.md（★本フェーズの正規仕様・必ず最初に読むこと）
- FIRESTORE.md（stores スキーマ確認）
- /Users/kanekohiroki/Desktop/groumapapp/firestore.rules（ルール修正対象）

実装タスク（店舗用アプリ）:

1. lib/views/settings/store_area_rarity_view.dart を新規作成
   - 全承認済み店舗の一覧（isApproved=true かつ isOwner=false）
   - 店舗名での検索フィルター
   - 各タイルに現在のエリア名・rarityOverride を表示
   - タップで編集ボトムシートを表示
   - ボトムシート内容:
     - エリア選択（areasコレクション全エリア + 「未設定（秘境スポット）」）
     - rarityOverride 選択（自動 / ★コモン / ★★レア / ★★★エピック / ★★★★レジェンド）
     - 現在のdiscoveredCount参考表示（「来店者数: ○人（自動: ★○）」）
     - 保存ボタン

実装タスク（Firestoreルール: /Users/kanekohiroki/Desktop/groumapapp/firestore.rules）:

2. updatesRestrictedFields() 関数を追加
   （areaId / rarityOverride / isApproved / isOwner / founderMember をオーナー専用フィールドに）
3. stores/{storeId} の update ルールを修正（area-admin-ui-design.md セクション4 参照）
4. firebase deploy --only firestore:rules

実装後: flutter analyze を実行してエラーがないことを確認

完了後:
- IMPLEMENTATION_ROADMAP.md のフェーズ4-B チェックボックスを [x] に更新
- FIRESTORE.md の areas・stores.areaId の管理方法を「管理者UIで設定」に更新
- 変更したファイルと変更概要を報告
```

---

## フェーズ完了後の手順書更新ルール

各フェーズ完了後は、この手順書（`AGENT_TEAM_GUIDE.md`）を最新状態に保つこと。

### 自動更新トリガー

「手順書を更新して」「ガイドを整理して」「フェーズが完了したのでマークダウンを整理して」と依頼すると、`agent-team-roadmap-update` スキルが発動し、以下を自動実行する：

1. `IMPLEMENTATION_ROADMAP.md` を読み込み、完了済みチェックボックスを確認
2. 完了済みフェーズのプロンプトセクションを「完了済み」としてアーカイブ
3. 次フェーズのプロンプトを「現在実行中」として先頭に移動
4. この手順書のステータス行を更新

### 手動での更新方法

各フェーズ完了時に以下を手動で更新する：

| 更新箇所 | 内容 |
|---------|------|
| 各フェーズの `> ステータス:` 行 | `未完了` → `完了 (YYYY-MM-DD)` |
| `IMPLEMENTATION_ROADMAP.md` | 完了チェックボックスを `[x]` に |
| `USER_APP_SCREENS.md` | 画面構成の変更を反映 |
| `FIRESTORE.md` | 新規フィールド・コレクションを追記 |

---

## トラブルシューティング

| 症状 | 対処 |
|------|------|
| エージェントが設計書を読まずに実装する | プロンプトの冒頭に「参照ファイルを全て読んでから実装を開始」と明記 |
| flutter analyze でエラーが出る | エラー内容をコピーして「このエラーを修正して」と依頼 |
| firebase deploy が失敗する | `firebase login` の状態を確認。`firebase use groumapapp` でプロジェクト選択 |
| エージェントが依存関係を無視して並列実行する | `開始条件:` を明記し、前エージェントの完了メッセージ待ちを指示 |
| 2つのエージェントが同じファイルを同時編集する | 逐次方式に切り替え、1エージェントずつ順番に実行する |
