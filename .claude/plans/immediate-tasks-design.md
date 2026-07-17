# 設計プラン: フェーズ1〜2完了前に対応すべき小タスク群 (#7〜#11)

> 作成: 2026-03-05

---

## 概要

ビジネスモデルおよびSERVICE_FEATURES.mdに記載されているが設計・TODO化されていなかった5項目を実装する。
フェーズ1〜2の完了前に解決すべき事項として優先対応する。

---

## #7 ランキングオプトアウト設定

### 背景
BUSINESS_MODEL.mdに「設定でランキング参加をオフにできる（デフォルトはオン）。オフ時は『名無し探検家』+デフォルトアイコン+発見店舗数のみ表示（匿名参加）」と確定している。未実装のため、ランキング公開前（フェーズ2）に追加が必須。

### Firestoreフィールド追加
`users/{uid}` に以下を追加:
```
rankingOptOut: bool  // デフォルト: false（参加）
```

### 設定UI
`lib/views/settings/notification_settings_view.dart` の末尾に「ランキング設定」セクションを追加する。
既存の通知設定の実装パターン（`SetOptions(merge: true)` で即時保存）と同じ方式で実装。

```dart
_buildSectionHeader('ランキング設定'),
SwitchListTile(
  title: const Text('ランキングに参加する'),
  subtitle: const Text('OFFにすると「名無し探検家」として匿名表示されます'),
  value: _rankingParticipation,  // 初期値: !rankingOptOut
  onChanged: (val) => _updateRankingOptOut(!val),
),
```

Firestore保存:
```dart
await _firestore.collection('users').doc(uid).set({
  'rankingOptOut': !newParticipationValue,
  'updatedAt': FieldValue.serverTimestamp(),
}, SetOptions(merge: true));
```

### ランキング表示の匿名化
フェーズ2のランキング刷新（`ranking-redesign.md`）と同時に実装。
`ranking_scores` からデータ取得時に `rankingOptOut == true` のユーザーは:
- `displayName` → 「名無し探検家」
- `profileImageUrl` → null（デフォルトアイコン表示）
- スコア（discoveredStoreCount）はそのまま表示

### 変更ファイル
- `lib/views/settings/notification_settings_view.dart` - トグル追加
- `lib/providers/ranking_provider.dart` - 匿名化ロジック追加（フェーズ2時）
- `lib/views/ranking/leaderboard_view.dart` - 匿名ユーザー表示対応（フェーズ2時）
- `firestore.rules` - `users/{uid}.rankingOptOut` の書き込み許可確認
- `.claude/plans/ranking-redesign.md` - オプトアウト仕様を追記

---

## #8 プライバシーポリシー更新

### 背景
BUSINESS_MODEL.mdに「プライバシーポリシーに『ランキングでユーザー名・プロフィールアイコンが公開される』旨を明記する」と確定している。ランキング公開前（フェーズ2前）に必須対応。

### 変更ファイル
`/Users/kanekohiroki/Desktop/groumapapp/PRIVACY_POLICY.md`

### 追加内容

**1. 第4条（利用目的）に追記:**
```
・探検家ランキングへの参加（参加設定がONの場合）：ユーザー名（表示名）・プロフィール
  アイコン・発見店舗数を、ランキング画面で他の利用者に公開します。
  設定からOFFにすると「名無し探検家」として匿名表示されます。
```

**2. 第3条（取得する情報）の利用履歴に追記:**
```
・探検家ランキングスコア（発見店舗数・訪問ユニーク店舗数）
```

**3. 末尾に「ランキング機能に関する公開情報」セクションを新規追加:**
```markdown
## ランキング機能に関する公開情報

探検家ランキング機能では、以下の情報がアプリ内で他の利用者に公開されます。

- ユーザー名（表示名）
- プロフィールアイコン画像
- 発見店舗数（ランキングスコア）

ランキングへの参加はデフォルトでONとなっています。
設定 > ランキング設定からOFFにすると、「名無し探検家」として匿名表示されます。
OFFにした場合も順位の計算には含まれますが、他の利用者にはユーザー名・
プロフィールアイコンが表示されません。
```

---

## #9 STORE_AGREEMENT.md 新規作成

### 背景
BUSINESS_MODEL.mdに「A4一枚の簡易合意書を用意する（STORE_AGREEMENT.mdを参照）」とあるが、ファイルが存在しない。パイロット営業時に店舗と取り交わす文書として必要。

### 作成ファイル
`/Users/kanekohiroki/Desktop/groumapapp/STORE_AGREEMENT.md`

### 内容構成
BUSINESS_MODEL.mdの「パイロット運用方針」「精算方法」「NFCスタンド」の記述をもとに以下の項目を含む文書を作成:

- 掲載内容の許諾（店舗名・住所・営業時間・カテゴリ・写真・説明文）
- NFCスタンドの設置・管理（紛失・破損時の連絡、第三者への譲渡禁止）
- 100円引き特典の対応（アプリ初回ダウンロードのお客様が対象）
- 精算方法（月末締め・翌月初精算・現金手渡し・上限50,000円/月）
- 解約条件（申し出から翌月末をもって終了、スタンド回収）
- 個人情報の取扱い（来店者データはプライバシーポリシーに従い管理）
- 禁止事項（虚偽の来店データ発生など）
- 免責事項（集客効果・来店数の保証なし）

---

## #10 ウェルカムお知らせ更新

### 背景
`punchStamp` Cloud Function内の紹介通知タイトル・本文にコイン記述が残存。コインシステム廃止（2026-03-04）に伴い削除が必要。また `processFriendReferral` でウェルカムお知らせ（`users/{uid}/notifications`）を作成する実装が未着手。

### 変更ファイル
`/Users/kanekohiroki/Desktop/groumapapp/backend/functions/src/index.ts`

### A. punchStamp 内の紹介通知文言を更新

**被紹介者（referee）への通知:**
```typescript
// 変更前
title: '友達紹介コイン獲得',
body: `${referrerName}さんのコードで登録し、${referralAwardedInviteeCoins}コインが付与されました`

// 変更後
title: 'ようこそぐるまっぷへ！',
body: `${referrerName}さんの紹介でアプリを始めました。NFCタグにタッチして新しいお店を発見してみましょう！`
```

**紹介者（referrer）への通知:**
```typescript
// 変更前
title: '友達紹介コイン獲得',
body: `${refereeName}さんが初めてお店でスタンプを獲得し、${referralAwardedInviterCoins}コインが付与されました`

// 変更後
title: 'お友達が登録しました！',
body: `${refereeName}さんがぐるまっぷに参加しました。一緒に街を探検しましょう！`
```

### B. processFriendReferral にウェルカムお知らせを追加

紹介コードで登録したユーザーへ、初回ホーム画面遷移前に表示されるお知らせを追加する。

```typescript
// processFriendReferral 内、referral_uses 記録の後に追加
await db.collection('users').doc(refereeUid).collection('notifications').add({
  type: 'social',
  tags: ['referral', 'welcome'],
  title: 'ようこそぐるまっぷへ！',
  body: `${referrerDisplayName}さんの紹介でアプリを始めました。\n` +
        `お店のNFCタグにスマホをタッチすると、図鑑カードが解放されます。\n` +
        `まずは近くのお店を探してみましょう！`,
  isRead: false,
  createdAt: FieldValue.serverTimestamp(),
});
```

---

## #11 廃止システム依存バッジの扱い

### 背景
コイン・ミッションシステムの廃止に伴い、これらをトリガーとするバッジが取得不可能になっている。BADGE_LIST.mdの更新とFlutterコード内のトリガー削除が必要。

### バッジ分類と対応方針

| グループ | 個数 | 状態 | 対応 |
|---------|------|------|------|
| スロット関連 (slot_played_*, slot_win_*) | 8個 | BADGE_LIST.mdで対応済み | 変更不要 |
| コイン獲得 (coinsEarned_*) | 5個 | コイン付与停止 → 取得不可 | BADGE_LIST.md更新 + トリガー削除 |
| ミッション達成 (missionCompleted_*) | 5個 | ミッションUI廃止 → 取得不可 | BADGE_LIST.md更新 + トリガー削除 |
| スタンプカード達成 (stampCardCompleted_*) | 4個 | フェーズ1完了後に取得不可 | フェーズ1実装時に同時対応（現時点保留） |
| フォロー (followUser_*) | 4個 | 店舗フォローは継続 → 取得可能 | 対応不要 |

### 廃止対象バッジ一覧（コイン獲得 5個 + ミッション達成 5個 = 計10個）

**コイン獲得バッジ（廃止・獲得不可）:**
- `coins_earned_1` 初コイン獲得者
- `coins_earned_50` コインコレクター
- `coins_earned_200` コイン蒐集家
- `coins_earned_500` コイン長者
- `coins_earned_1000` コイン王

**ミッション達成バッジ（廃止・獲得不可）:**
- `mission_completed_1` ミッションデビュー
- `mission_completed_5` ミッションファン
- `mission_completed_10` ミッションマスター
- `mission_completed_25` ミッションエキスパート
- `mission_completed_50` ミッション王

### 変更ファイル

1. **`BADGE_LIST.md`** - 上記10個に「廃止・獲得不可」の注記を追加（スロット関連バッジと同じ書き方に統一）

2. **`lib/views/missions/missions_view.dart`** - 以下のトリガー呼び出しを削除:
   - `incrementBadgeCounter('coinsEarned')`
   - `incrementBadgeCounter('missionCompleted')`

3. **`lib/data/badge_definitions.dart`**（フェーズ1と合わせて対応・任意）- 廃止バッジに `isDeprecated: true` フィールドを追加して将来のバッジ一覧UI対応に備える

---

---

## #12 紹介UIの廃止

### 背景
BUSINESS_MODEL.md（2026-03-05確定）にて「キャンペーンUIをプロフィール画面から非表示化」が決定。バックエンドは全て維持するが、フロントエンドの導線を削除する。

### 対応方針
- **バックエンドは一切変更しない**（`processFriendReferral` / `referral_uses` / 紹介コード自動発行はそのまま）
- 新規登録フロー（`UserInfoView`）の紹介コード入力欄も**維持**
- UIの導線のみ削除

### 変更ファイル

**1. `lib/views/profile/profile_view.dart`**
- 「友達を紹介する」ボタン・セクションを削除
- `FriendReferralView` への `Navigator.push` 呼び出しを削除

**2. ルーティング（該当箇所を検索して削除）**
- `FriendReferralView` への `GoRoute` または `routes` 定義を削除
- 検索キーワード: `FriendReferralView`、`friend_referral`、`/referral`

**3. 不要なimportの削除**
- `profile_view.dart` から `friend_referral_view.dart` の import を削除

### 注意事項
- `FriendReferralView` 自体のファイルは削除しない（将来キャンペーン再開時にUIを復元するため）
- `user_coupons`・`referral_uses` のデータアクセスコードも削除しない

---

## #13 FIRESTORE.md 更新（3フィールド追記）

### 背景
フェーズ1〜2の実装で新たに追加される3フィールドが `FIRESTORE.md` に未記載。実装前に追記しておく。

### 変更ファイル
`/Users/kanekohiroki/Desktop/groumapapp/FIRESTORE.md`

### 追記内容

**`stores/{storeId}` ドキュメントへの追記:**

| フィールド | 型 | 説明 | 追加タイミング |
|-----------|-----|------|--------------|
| `discoveredCount` | `number` | ぐるまっぷ経由でNFCチェックインしたユニークユーザー数（初回来店のみカウント）。レア度の自動算出・コミュニティ開拓率に使用 | フェーズ1（nfcCheckin修正時） |
| `totalVisitCount` | `number` | NFCチェックインの累計来店回数（再来店を含む全ユーザー合計）。マップ賑わい度ビューに使用 | フェーズ1（nfcCheckin修正時） |
| `rarityOverride` | `number?` | 運営による手動レア度上書き（1〜4。未設定時は `discoveredCount` から自動算出） | フェーズ1（ZukanView実装時） |
| `areaId` | `string?` | 所属エリアのID（`areas` コレクションのドキュメントID。エリア半径外の場合は null → 秘境スポット扱い） | フェーズ2（エリアシステム実装時） |

### レア度の自動算出ロジック（参考として記載）
```
discoveredCount == 0           → ★★★★ レジェンド
discoveredCount 1〜5           → ★★★ エピック
discoveredCount 6〜20          → ★★ レア
discoveredCount 21以上         → ★ コモン
rarityOverride が設定されている → その値を優先
```

---

## #14 USER_APP_SCREENS.md 更新（3タブ構成への更新）

### 背景
現在の `USER_APP_SCREENS.md` は旧5タブ構成で記述されている。フェーズ1完了後、3タブ構成（マップ/図鑑/アカウント）への変更を反映する。

### 実装タイミング
**フェーズ1（3タブ化・ZukanView）の実装完了後に更新する。**
実装前に更新すると実態と乖離するため、コード実装完了を待って更新すること。

### 更新内容

**削除するタブ:**
- ホームタブ（`HomeView`）
- 投稿タブ（`PostView` / `FeedView`）
- QRフローティングボタン（FAB）

**追加するタブ:**
- 図鑑タブ（`ZukanView`）

**変更するタブ:**
- マップタブ: 起動時のメイン画面として位置づけを更新
- アカウントタブ: 探検統計カード・通知ベルアイコン移設・QRフォールバックボタンの追記

**新規追加画面の記載:**
- `ZukanView`（図鑑タブ）: フィルター・グリッド・開拓サマリーバー
- `ZukanCardDetailView`（図鑑カード詳細）: 発見済み/未発見の2モード

---

## 実装順序・タイミング

| 優先度 | 項目 | 実装タイミング |
|--------|------|--------------|
| 高 | #10 ウェルカムお知らせ更新 | フェーズ1実装開始前（Cloud Functionsデプロイ） |
| 高 | #11 廃止バッジのBADGE_LIST.md更新・トリガー削除 | フェーズ1実装と同時 |
| 高 | #12 紹介UIの廃止 | フェーズ1実装と同時 |
| 高 | #13 FIRESTORE.md更新 | フェーズ1実装開始前（nfcCheckin修正前） |
| 高 | #9 STORE_AGREEMENT.md作成 | パイロット営業開始前 |
| 中 | #7 ランキングオプトアウト設定UI | フェーズ2（ランキング刷新）実装時 |
| 中 | #8 プライバシーポリシー更新 | ランキング公開前（フェーズ2前） |
| 低 | #14 USER_APP_SCREENS.md更新 | フェーズ1完了後 |

---

## 確認・テスト方法

- **#7**: 設定画面でトグルをOFF → ランキング画面で「名無し探検家」表示確認
- **#8**: アプリ内プライバシーポリシー表示でランキング公開情報の追記を確認
- **#9**: STORE_AGREEMENT.mdの内容を印刷・口頭確認してパイロット店舗に使用
- **#10**: テストユーザーで紹介コード登録 → コイン記述なしのウェルカム通知が届くか確認
- **#11**: バッジ一覧でコイン獲得・ミッション達成バッジが廃止表記になっているか確認
- **#12**: ProfileViewに「友達を紹介する」ボタンが表示されないこと / `FriendReferralView` のファイルが残存していること
- **#13**: FIRESTORE.mdで3フィールドの記載を目視確認
- **#14**: USER_APP_SCREENS.mdが3タブ構成を正確に反映していること
