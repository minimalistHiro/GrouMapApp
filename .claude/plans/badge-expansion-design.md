# バッジ追加 設計書（フェーズ3）

> 作成日: 2026-03-06
> フェーズ: 3（フェーズ2完了後に実装着手）
> 関連ドキュメント: [BADGE_LIST.md](../../BADGE_LIST.md)・[BUSINESS_MODEL.md](../../BUSINESS_MODEL.md)

---

## 概要

フェーズ3で追加するバッジ3シリーズ。既存162種に追加する形で実装する。

| シリーズ | 追加バッジ数 | 概要 |
|---------|------------|------|
| 秘境探検家シリーズ | 4個 | エリア外（秘境スポット）への来店で獲得 |
| ジャンル別コンプリートバッジ | 10個 | 各ジャンルグループの全店舗訪問で獲得 |
| 週次ミッション達成バッジ | 4個 | 週次ミッション達成累計数で獲得 |
| **合計** | **18個** | 既存162 + 18 = **180種** |

---

## 1. 秘境探検家シリーズ（4段階）

### 定義

エリア外店舗（`stores/{storeId}.areaId == null`）への来店のみでカウント。

| バッジID | 名前 | 獲得条件 | レア度 |
|---------|------|---------|--------|
| `hidden_explorer_1` | 秘境探検家 ★ | エリア外店舗に初来店（1店舗） | rare |
| `hidden_explorer_2` | 秘境探検家 ★★ | エリア外店舗に3店舗来店 | epic |
| `hidden_explorer_3` | 秘境探検家 ★★★ | エリア外店舗に5店舗来店 | legendary |
| `hidden_explorer_4` | 真の冒険者 | 全エリア外店舗を制覇 | legendary |

### カウンターキー

```
badge_progress/{userId}_hiddenExplorer
  └── count: number  // エリア外店舗のユニーク来店数（firstVisitAt ベース）
```

### トリガー実装

**Cloud Functions: `nfcCheckin`（既存関数に追記）**

```typescript
// isFirstVisit == true かつ store.areaId == null の場合
if (isFirstVisit && !store.areaId) {
  // hiddenExplorer カウンターをインクリメント
  await incrementBadgeCounter(userId, 'hiddenExplorer');

  // 全エリア外店舗制覇チェック（true の場合 hidden_explorer_4 付与）
  const totalHiddenStores = await getHiddenStoresCount();
  const currentCount = await getHiddenExplorerCount(userId);
  if (currentCount >= totalHiddenStores) {
    await awardBadge(userId, 'hidden_explorer_4');
  }
}
```

**Flutter 側トリガー（`nfc_checkin_result_view.dart`）**

- Cloud Function の戻り値に `hiddenExplorerIncremented: bool` を追加
- Flutter 側で `BadgeProvider.checkAndAwardBadge('hiddenExplorer')` を呼び出し

### 注意事項

- `hidden_explorer_4`（真の冒険者）は「全エリア外店舗の制覇」が条件のため、
  店舗追加のたびに達成が遠のく動的な条件になる
- 現フェーズのパイロット規模（数店舗）では達成不可能な可能性が高い →
  条件説明を「現時点の全エリア外店舗を制覇」と明示する
- `stores` コレクションの `areaId == null` 件数を随時集計する必要がある

---

## 2. ジャンル別コンプリートバッジ（10個）

### 定義

各ジャンルグループの **登録済み全店舗**（`isActive == true && isApproved == true`）に来店（firstVisitAt 記録）で獲得。

| バッジID | 名前 | 対象グループ | レア度 |
|---------|------|------------|--------|
| `genre_complete_cafe_sweets` | カフェ・スイーツ完全制覇 | cafe_sweets | epic |
| `genre_complete_washoku` | 和食完全制覇 | washoku | epic |
| `genre_complete_izakaya_bar` | 居酒屋・バー完全制覇 | izakaya_bar | epic |
| `genre_complete_yakitori_age` | 焼き鳥・揚げ物完全制覇 | yakitori_age | epic |
| `genre_complete_nabe_yakiniku` | 鍋・焼肉完全制覇 | nabe_yakiniku | epic |
| `genre_complete_ramen_chinese` | ラーメン・中華完全制覇 | ramen_chinese | epic |
| `genre_complete_asian_ethnic` | アジア・エスニック完全制覇 | asian_ethnic | epic |
| `genre_complete_western_french` | 洋食・フレンチ完全制覇 | western_french | epic |
| `genre_complete_italian_meat` | イタリアン・肉料理完全制覇 | italian_meat | epic |
| `genre_complete_shokudo_other` | 食堂・その他完全制覇 | shokudo_other | epic |

### カテゴリグループ定義（BADGE_LIST.md と同一）

```dart
// lib/data/badge_definitions.dart に追記
const Map<String, List<String>> genreGroups = {
  'cafe_sweets': ['カフェ・喫茶店', 'スイーツ', 'ケーキ', 'タピオカ', 'パン・サンドイッチ'],
  'washoku': ['和食', '日本料理', '海鮮', '寿司', 'そば', 'うどん', 'うなぎ', '天ぷら'],
  'izakaya_bar': ['居酒屋', 'バー・お酒', 'スナック'],
  'yakitori_age': ['焼き鳥', 'とんかつ', '串揚げ', 'お好み焼き', 'もんじゃ焼き'],
  'nabe_yakiniku': ['しゃぶしゃぶ', '鍋', '焼肉', 'ホルモン'],
  'ramen_chinese': ['ラーメン', '中華料理', '餃子'],
  'asian_ethnic': ['韓国料理', 'タイ料理', 'カレー', '沖縄料理'],
  'western_french': ['レストラン', '洋食', 'フレンチ', 'スペイン料理', 'ビストロ'],
  'italian_meat': ['パスタ', 'ピザ', 'ステーキ', 'ハンバーグ', 'ハンバーガー'],
  'shokudo_other': ['ビュッフェ', '食堂', '料理旅館', 'その他'],
};
```

### トリガー実装

**Cloud Functions: `nfcCheckin`（既存関数に追記）**

```typescript
// isFirstVisit == true の場合にジャンルコンプリートチェック
if (isFirstVisit) {
  const storeCategory = store.category; // stores/{storeId}.category
  const genre = findGenreByCategory(storeCategory); // genreGroups からジャンルを特定

  if (genre) {
    // そのジャンルの全登録店舗ID一覧を取得
    const genreStoreIds = await getStoreIdsByGenre(genre);
    // ユーザーが訪問済みの store_users サブコレクション一覧と照合
    const visitedCount = await getVisitedCountInGenre(userId, genreStoreIds);

    if (visitedCount >= genreStoreIds.length) {
      await awardBadge(userId, `genre_complete_${genre}`);
    }
  }
}
```

### 注意事項

- ジャンル別コンプリートは「その時点の登録店舗全店制覇」が条件のため、
  店舗追加のたびに制覇が解除される可能性がある
  → 付与タイミング: NFC チェックイン時のみ（定期的な再チェックは行わない）
  → 付与後に新店舗が追加されても既得バッジは維持する（剥奪しない）
- 現フェーズ（パイロット: 5〜10店舗規模）では各ジャンルの店舗数が少ないため
  比較的早期に達成可能。ゲーム性の観点から「早期達成 → 新店舗追加で次の目標」
  というサイクルを意図した設計とする

---

## 3. 週次ミッション達成バッジ（4個）

### 定義

来店促進1週間ミッション（BUSINESS_MODEL.md「来店促進1週間ミッション」参照）の
達成累計回数でカウント。

| バッジID | 名前 | 獲得条件 | レア度 |
|---------|------|---------|--------|
| `weekly_mission_1` | 初めての週次ミッション | 週次ミッションを初めて達成 | common |
| `weekly_mission_5` | ミッション常連 | 週次ミッションを累計5回達成 | rare |
| `weekly_mission_10` | ミッションファイター | 週次ミッションを累計10回達成 | epic |
| `weekly_mission_25` | ミッションレジェンド | 週次ミッションを累計25回達成 | legendary |

### カウンターキー

```
badge_progress/{userId}_weeklyMission
  └── count: number  // 週次ミッション達成累計回数
```

### 週次ミッション定義（BUSINESS_MODEL.md 準拠）

7日間のうちに以下の条件を **全て** 満たすと達成:
1. 未訪問店舗でNFCチェックインを1回実施
2. 期間中NFCチェックイン合計3回実施
3. （将来拡張）登録店舗で合計1,000円以上利用（会計連携導入後に有効化）

達成時の報酬（BUSINESS_MODEL.md 準拠）:
- 限定バッジ + 発見ヒント（マップ上の点滅 + テキスト通知）

### トリガー実装

**Cloud Functions: `checkWeeklyMission`（新規関数）**

```typescript
// 毎日23:59 JST に Scheduled Function で実行（または NFC チェックイン時に評価）
// ユーザーの「今週開始日」〜「今日」の store_users/{storeId}/users/{userId} を集計
// 条件1: 今週に firstVisitAt が作成されたエントリが1件以上
// 条件2: 今週の totalVisits 合計（トランザクションカウント）が3回以上

// 達成時:
// 1. weekly_mission_{userId} のカウンターをインクリメント
// 2. `badge_progress/{userId}_weeklyMission` を更新
// 3. BadgeCheck を実行（weekly_mission_{N} バッジを付与）
// 4. 発見ヒント処理（マップ上の点滅通知 - 将来実装）
```

**Flutter 側トリガー（`nfc_checkin_result_view.dart`）**

- NFC チェックイン後に週次ミッション達成チェックを呼び出す
- 達成した場合にポップアップで通知

### 週次ミッションの実装前提

- 週次ミッション機能自体（`checkWeeklyMission` Functions・ミッション進捗画面）の
  実装が必要
- BUSINESS_MODEL.md では「ユーザー行動データを見て導入時期を判断」とあるため、
  バッジ定義は先行して追加するが、トリガー実装はミッション機能の実装と同時に行う

---

## 4. `lib/data/badge_definitions.dart` への追記

```dart
// 秘境探検家シリーズ
BadgeDefinition(
  id: 'hidden_explorer_1',
  name: '秘境探検家 ★',
  description: 'エリア外（秘境スポット）の店舗に初めて来店',
  iconUrl: 'assets/images/badges/hidden_explorer_1.png',
  rarity: BadgeRarity.rare,
  triggerType: BadgeTriggerType.hiddenExplorer,
  requiredCount: 1,
),
BadgeDefinition(
  id: 'hidden_explorer_2',
  name: '秘境探検家 ★★',
  description: 'エリア外の店舗に3店舗来店',
  iconUrl: 'assets/images/badges/hidden_explorer_2.png',
  rarity: BadgeRarity.epic,
  triggerType: BadgeTriggerType.hiddenExplorer,
  requiredCount: 3,
),
BadgeDefinition(
  id: 'hidden_explorer_3',
  name: '秘境探検家 ★★★',
  description: 'エリア外の店舗に5店舗来店',
  iconUrl: 'assets/images/badges/hidden_explorer_3.png',
  rarity: BadgeRarity.legendary,
  triggerType: BadgeTriggerType.hiddenExplorer,
  requiredCount: 5,
),
BadgeDefinition(
  id: 'hidden_explorer_4',
  name: '真の冒険者',
  description: '現在登録されている全エリア外店舗を制覇',
  iconUrl: 'assets/images/badges/hidden_explorer_4.png',
  rarity: BadgeRarity.legendary,
  triggerType: BadgeTriggerType.hiddenExplorerComplete,
  requiredCount: 1,
),

// ジャンル別コンプリートバッジ（10個：genreGroups の各キーで生成）
...genreGroups.keys.map((genre) => BadgeDefinition(
  id: 'genre_complete_$genre',
  name: '${genreCompleteLabels[genre]}完全制覇',
  description: '${genreCompleteLabels[genre]}の全店舗を訪問',
  iconUrl: 'assets/images/badges/genre_complete_$genre.png',
  rarity: BadgeRarity.epic,
  triggerType: BadgeTriggerType.genreComplete,
)),

// 週次ミッション達成バッジ
BadgeDefinition(
  id: 'weekly_mission_1',
  name: '初めての週次ミッション',
  description: '週次ミッションを初めて達成',
  iconUrl: 'assets/images/badges/weekly_mission_1.png',
  rarity: BadgeRarity.common,
  triggerType: BadgeTriggerType.weeklyMission,
  requiredCount: 1,
),
BadgeDefinition(
  id: 'weekly_mission_5',
  name: 'ミッション常連',
  description: '週次ミッションを累計5回達成',
  iconUrl: 'assets/images/badges/weekly_mission_5.png',
  rarity: BadgeRarity.rare,
  triggerType: BadgeTriggerType.weeklyMission,
  requiredCount: 5,
),
BadgeDefinition(
  id: 'weekly_mission_10',
  name: 'ミッションファイター',
  description: '週次ミッションを累計10回達成',
  iconUrl: 'assets/images/badges/weekly_mission_10.png',
  rarity: BadgeRarity.epic,
  triggerType: BadgeTriggerType.weeklyMission,
  requiredCount: 10,
),
BadgeDefinition(
  id: 'weekly_mission_25',
  name: 'ミッションレジェンド',
  description: '週次ミッションを累計25回達成',
  iconUrl: 'assets/images/badges/weekly_mission_25.png',
  rarity: BadgeRarity.legendary,
  triggerType: BadgeTriggerType.weeklyMission,
  requiredCount: 25,
),
```

---

## 5. バッジ画像生成（badge-image-gen スキル使用）

新規バッジ18種の画像を `badge-image-gen` スキルで生成する。

| バッジID | 画像イメージ |
|---------|------------|
| hidden_explorer_1〜3 | 星付きコンパス・地図・冒険者テイスト |
| hidden_explorer_4 | 黄金のコンパス・「真の冒険者」テキスト |
| genre_complete_{group} | 各ジャンルを象徴するアイコン + 「完全制覇」リボン |
| weekly_mission_1〜25 | カレンダー＋チェックマーク・ミッション達成テイスト |

保存先: `assets/images/badges/{badgeId}.png`（既存と同一ディレクトリ）

---

## 6. 実装タスク一覧（推奨順序）

### フェーズ3-A: 定義・画像（前提なし・先行着手可）

```
① badge_definitions.dart に18種を追記
② BADGE_LIST.md を更新（新バッジ追記）
③ badge-image-gen スキルで18種の画像生成・配置
```

### フェーズ3-B: 秘境探検家シリーズ（エリアシステム完了後）

```
④ Cloud Functions: nfcCheckin に hiddenExplorer カウンター追加
   → firebase deploy --only functions:nfcCheckin
⑤ Flutter: BadgeProvider に hiddenExplorer チェックロジック追加
⑥ nfc_checkin_result_view.dart に hiddenExplorer トリガー追加
```

### フェーズ3-C: ジャンル別コンプリートバッジ（エリアシステム完了後）

```
⑦ Cloud Functions: nfcCheckin にジャンルコンプリートチェック追加
   → firebase deploy --only functions:nfcCheckin
⑧ Flutter: ZukanView にジャンル別コンプリート進捗表示追加（任意）
```

### フェーズ3-D: 週次ミッション達成バッジ（週次ミッション機能実装後）

```
⑨ Cloud Functions: checkWeeklyMission 新規作成
   → firebase deploy --only functions:checkWeeklyMission
⑩ Flutter: 週次ミッション進捗画面（MissionsView 更新）
⑪ Flutter: ミッション達成時のバッジ付与トリガー追加
```

---

## 7. BADGE_LIST.md への追記内容

```markdown
## 秘境探検家シリーズ（hiddenExplorer）

| バッジID | 名前 | 獲得条件 | レア度 |
|---------|------|---------|--------|
| hidden_explorer_1 | 秘境探検家 ★ | エリア外店舗に初来店（1店舗） | rare |
| hidden_explorer_2 | 秘境探検家 ★★ | エリア外店舗に3店舗来店 | epic |
| hidden_explorer_3 | 秘境探検家 ★★★ | エリア外店舗に5店舗来店 | legendary |
| hidden_explorer_4 | 真の冒険者 | 現在登録されている全エリア外店舗を制覇 | legendary |

## ジャンル別コンプリートバッジ（genreComplete）

| バッジID | 名前 | 獲得条件 | レア度 |
|---------|------|---------|--------|
| genre_complete_cafe_sweets | カフェ・スイーツ完全制覇 | カフェ・スイーツ系の全店舗訪問 | epic |
| genre_complete_washoku | 和食完全制覇 | 和食系の全店舗訪問 | epic |
| genre_complete_izakaya_bar | 居酒屋・バー完全制覇 | 居酒屋・バー系の全店舗訪問 | epic |
| genre_complete_yakitori_age | 焼き鳥・揚げ物完全制覇 | 焼き鳥・揚げ物系の全店舗訪問 | epic |
| genre_complete_nabe_yakiniku | 鍋・焼肉完全制覇 | 鍋・焼肉系の全店舗訪問 | epic |
| genre_complete_ramen_chinese | ラーメン・中華完全制覇 | ラーメン・中華系の全店舗訪問 | epic |
| genre_complete_asian_ethnic | アジア・エスニック完全制覇 | アジア・エスニック系の全店舗訪問 | epic |
| genre_complete_western_french | 洋食・フレンチ完全制覇 | 洋食・フレンチ系の全店舗訪問 | epic |
| genre_complete_italian_meat | イタリアン・肉料理完全制覇 | イタリアン・肉料理系の全店舗訪問 | epic |
| genre_complete_shokudo_other | 食堂・その他完全制覇 | 食堂・その他の全店舗訪問 | epic |

## 週次ミッション達成バッジ（weeklyMission）

| バッジID | 名前 | 獲得条件 | レア度 |
|---------|------|---------|--------|
| weekly_mission_1 | 初めての週次ミッション | 週次ミッションを初めて達成 | common |
| weekly_mission_5 | ミッション常連 | 週次ミッションを累計5回達成 | rare |
| weekly_mission_10 | ミッションファイター | 週次ミッションを累計10回達成 | epic |
| weekly_mission_25 | ミッションレジェンド | 週次ミッションを累計25回達成 | legendary |
```

---

## 8. 依存関係・前提条件

| バッジシリーズ | 依存 |
|-------------|------|
| 秘境探検家シリーズ | フェーズ2 エリアシステム完了（`stores.areaId` が設定済みであること） |
| ジャンル別コンプリートバッジ | フェーズ1 図鑑実装完了（`store_users` への firstVisitAt 記録が完了していること） |
| 週次ミッション達成バッジ | 週次ミッション機能の実装（フェーズ3 内で並行設計） |
