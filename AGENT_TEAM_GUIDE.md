# エージェントチーム実行ガイド

> 最終更新: 2026-03-05
> 目的: Claude Code エージェントチームを使ってフェーズ1〜3を段階的に実装するための手順書

---

## 目次

- [事前準備](#事前準備)
- [エージェントチームとは](#エージェントチームとは)
- [フェーズ0: 事前準備](#フェーズ0-事前準備の実行)
- [フェーズ1: 図鑑・3タブ化](#フェーズ1-図鑑3タブ化)
- [フェーズ2: 地図塗り・エリア・ランキング](#フェーズ2-地図塗りエリアランキング)
- [フェーズ3: 月次レポート・バッジ拡充](#フェーズ3-月次レポートバッジ拡充)
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

> ステータス: 未完了
> フェーズ1 の Cloud Functions 修正前に必ず完了させること。

### 逐次方式プロンプト（推奨）

以下をそのまま CLI のチャット欄に貼り付けて実行する：

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

> ステータス: 未完了（フェーズ0 完了後に着手）
> 設計書は全て `.claude/plans/` 配下に存在。

### 重要ルール（フェーズ1 全体）

- Cloud Functions の正規仕様は `nfc-zukan-flow-redesign.md` を優先
- `block-a-cloud-functions.md` はコイン削除・フォロー source の詳細参照のみ
- `business-model-simplification.md` は UI 削除のみ参照（Cloud Functions は触らない）
- 実装後は必ず `flutter analyze` でエラー確認

---

### Step 1-①: バックエンド（Cloud Functions）

以下を CLI に貼り付けて実行する：

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

### Step 1-②: 図鑑UI（ZukanView）

Step 1-① 完了後に実行する：

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

### Step 1-③: 3タブ化・ProfileView 強化（#11・#12 を同時実施）

Step 1-② 完了後に実行する：

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

### Step 1-④: ビジネスモデル簡素化（コイン・クーポンUI削除）

Step 1-③ 完了後に実行する：

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

### Step 1-⑤: KPI再定義

Step 1-④ と並行して実行可能：

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

### Step 1-⑥: ドキュメント更新

フェーズ1 全タスク完了後に実行する：

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

> ステータス: 未着手（フェーズ1 完了後に着手）
> 設計書は全て `.claude/plans/` 配下に存在。

### 依存関係

```
① エリアシステム（area-system-design.md）
    ↓
② マップ拡張（map-extension-design.md）

③ ランキング刷新（ranking-redesign.md）← ① ② と並行可能
```

### Step 2-①: エリアシステム

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

### Step 2-②: マップ拡張

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

### Step 2-③: ランキング刷新（#7・#8 同時実施）

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

> ステータス: 設計プラン未作成（フェーズ2 完了後に設計から着手）

フェーズ2 完了後、以下のプロンプトで設計から開始する：

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
