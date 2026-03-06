# 月次探検レポート 設計書

> 作成日: 2026-03-06
> フェーズ: 3（フェーズ2完了後に実装着手）
> 関連設計書: [map-extension-design.md](map-extension-design.md)（賑わい度データ構造）

---

## 概要

毎月末にユーザーへプッシュ通知で「今月の探検まとめ」を配信する機能。
Spotifyの「年間振り返り」に相当する体験で、ユーザーの探索行動を可視化し
SNSシェアによるバイラル拡散経路を創出する。

---

## 1. Scheduled Cloud Functions 設計

### 1-1. 関数名・スケジュール

```
関数名: generateMonthlyReport
スケジュール: every month 23:00 JST (月末最終日 23:00)
  → Pub/Sub + Cloud Scheduler で設定
  → Cloud Scheduler cron 式: 0 14 L * * (UTC 14:00 = JST 23:00、月末最終日)
タイムゾーン: Asia/Tokyo
ランタイム: Node.js 20
メモリ: 512MB（全ユーザーを処理するためデフォルトより大きめ）
タイムアウト: 540秒
```

### 1-2. 処理フロー

```
1. 対象月（当月 yyyy-MM）の確定
2. アクティブユーザー一覧を取得（過去30日以内にログインしたユーザー）
   → Firestore: users コレクション、lastActiveAt >= 30日前
3. ユーザーごとに個人レポートデータを集計（バッチ処理・100件ずつ）
4. レポートドキュメントを Firestore に書き込み
   → monthly_reports/{userId}/reports/{yyyy-MM}
5. FCM プッシュ通知を送信（バッチ）
6. 完了ログを記録（admin_logs コレクション）
```

### 1-3. 個人データ集計ロジック

```typescript
// 集計対象コレクション
// - store_users/{storeId}/users/{userId}: firstVisitAt, totalVisits
// - users/{uid}: discoveredStoreCount, badges
// - badge_progress/{userId}_{counterKey}: カウンター値

interface MonthlyReportData {
  userId: string;
  yearMonth: string;           // "2026-03"
  generatedAt: Timestamp;

  // 個人データ
  monthlyDiscoveredCount: number;      // 今月の発見店舗数
  totalDiscoveredCount: number;        // 累計発見店舗数
  topGenre: string | null;             // 最もよく行ったジャンル（カテゴリグループキー）
  topGenreCount: number;               // topGenre の来店回数
  visitedAreas: string[];              // 今月訪問したエリア名リスト
  legendDiscoveredCount: number;       // 今月発見したレジェンド店舗数
  communityContributionCount: number;  // コミュニティ開拓率への貢献（新規発見店舗数）
  totalVisitsThisMonth: number;        // 今月の総来店回数（賑わい貢献）
  hotStoresCount: number;              // マイマップで炎マーク（10回来店）の店舗数

  // コミュニティデータ
  communityDiscoveredCount: number;    // 今月の全体発見店舗数（新規firstVisitAt件数）
  communityExplorationRateDelta: number; // エリア開拓率の変化（%ポイント）
  communityVisitsDelta: number;        // エリア賑わい度の変化（来店回数・先月比）
  newStoresAddedCount: number;         // 今月新規追加店舗数

  // 来月のおすすめ（未訪問の近くのレジェンド/エピック店舗 最大3件）
  recommendedStores: RecommendedStore[];
}

interface RecommendedStore {
  storeId: string;
  storeName: string;
  category: string;
  rarity: number;  // 4=レジェンド, 3=エピック
  areaId: string | null;
}
```

### 1-4. ジャンル集計ロジック

```typescript
// カテゴリグループキー（BADGE_LIST.md のカテゴリグループと同一）
const GENRE_GROUPS = {
  cafe_sweets: ['カフェ・喫茶店', 'スイーツ', 'ケーキ', 'タピオカ', 'パン・サンドイッチ'],
  washoku: ['和食', '日本料理', '海鮮', '寿司', 'そば', 'うどん', 'うなぎ', '天ぷら'],
  // ... 全10グループ（BADGE_LIST.md と同一）
};

// 各グループの今月来店数を集計し、最多グループを topGenre に設定
// store_users/{storeId}/users/{userId} の firstVisitAt が当月のものを対象
```

### 1-5. Firestore スキーマ

```
monthly_reports/{userId}/reports/{yyyy-MM}
  └── MonthlyReportData（上記 interface に準拠）

monthly_reports_community/{yyyy-MM}
  └── communityDiscoveredCount: number
  └── communityExplorationRateDelta: number
  └── communityVisitsDelta: number
  └── newStoresAddedCount: number
  └── generatedAt: Timestamp
```

### 1-6. FCM 通知内容

```
タイトル: 「今月の探検まとめが届きました！」
本文（例）: 「今月は3店舗を新たに発見！コミュニティと一緒に街を開拓しました」
data:
  type: monthly_report
  yearMonth: "2026-03"
  click_action: /monthly_report/2026-03
```

### 1-7. エラーハンドリング・冪等性

- 同月に2回実行された場合は既存ドキュメントを上書き（冪等）
- ユーザー単位でエラーが発生した場合はスキップしてログに記録（全体処理を止めない）
- 月末処理失敗時の手動再実行を考慮し、関数を HTTP トリガーでも呼び出し可能にする

---

## 2. レポート専用画面設計

### 2-1. 画面ファイルパス

```
lib/views/report/monthly_report_view.dart
lib/providers/monthly_report_provider.dart
```

### 2-2. 画面遷移

```
通知タップ
  → DeepLink: /monthly_report/{yyyy-MM}
  → MainNavigationView でルーティング
  → MonthlyReportView（アカウントタブのプロフィール画面内からも遷移可）

アカウント画面（ProfileView）
  → 「過去のレポート」ボタン
  → 月別リスト → MonthlyReportView
```

### 2-3. 画面構成

```
MonthlyReportView
├── ヘッダー
│   ├── 「{yyyy}年{MM}月の探検レポート」タイトル
│   └── シェアボタン（右上）
│
├── セクション1: 今月のハイライト（個人）
│   ├── 大きな数字: 今月の発見店舗数
│   ├── サブテキスト: 「累計 {totalDiscoveredCount} 店舗を発見」
│   ├── 最もよく行ったジャンル（アイコン + ジャンル名 + 回数）
│   ├── 訪問エリアタグ（チップ形式で複数表示）
│   ├── レジェンド発見数（★★★★ アイコン付き）
│   └── 今月の賑わい貢献（総来店回数）
│
├── セクション2: コミュニティへの貢献
│   ├── 「あなたはコミュニティの{N}店舗発見に貢献しました」
│   └── 炎マーク（常連店）の店舗数
│
├── セクション3: 今月のコミュニティ全体
│   ├── 全体発見店舗数
│   ├── エリア開拓率の変化（先月比 ±%）
│   ├── エリア賑わい度の変化（先月比）
│   └── 今月の新規追加店舗数
│
├── セクション4: 来月のおすすめ（最大3件）
│   ├── 未訪問・近くのレジェンド/エピック店舗カード（横スクロール）
│   └── 各カード: 店舗名 / カテゴリ / レア度 / エリア名
│
└── フッター: SNSシェアエリア
    ├── シェアテキストプレビュー（折りたたみ可能）
    └── 「コピーしてシェア」ボタン（クリップボードにコピー）
```

### 2-4. UI デザイン方針（ui-ux-rules.md 準拠）

- 背景: GrouMap ブランドカラー系（#FBF6F2 ベージュ）
- アクセント: オレンジ（#FF6B35）
- 数字を大きく・視覚的インパクトを重視（Spotify リプレイ的な演出）
- アニメーション: カウントアップ演出（発見店舗数・累計発見店舗数）
- スクロール: 縦スクロール1ページ構成

### 2-5. Provider 設計

```dart
// lib/providers/monthly_report_provider.dart

// 指定月のレポートデータを取得
final monthlyReportProvider = FutureProvider.family<MonthlyReportModel?, String>(
  (ref, yearMonth) async {
    // Firestore: monthly_reports/{userId}/reports/{yearMonth}
  }
);

// 利用可能なレポート月一覧
final availableReportMonthsProvider = FutureProvider<List<String>>((ref) async {
  // monthly_reports/{userId}/reports のサブコレクション一覧
});
```

---

## 3. SNS シェア文生成ロジック

### 3-1. シェアテキストテンプレート

```
【基本テンプレート】
{yyyy}年{MM}月のぐるまっぷ探検レポート🗺️

📍 今月の発見: {monthlyDiscoveredCount}店舗
🏆 累計発見: {totalDiscoveredCount}店舗
🍽️ 今月のお気に入りジャンル: {topGenreLabel}
{legendLine}
{areeLine}

みんなと一緒に街を探検中！
#ぐるまっぷ #街歩き #{topGenreHashtag}

【条件付き行】
legendLine（レジェンド発見がある場合）:
  ✨ レジェンド発見: {legendDiscoveredCount}店舗！
areeLine（訪問エリアがある場合）:
  🗾 探検エリア: {visitedAreas.join('・')}
```

### 3-2. ジャンルラベル・ハッシュタグマッピング

```dart
const Map<String, String> genreLabels = {
  'cafe_sweets': 'カフェ・スイーツ',
  'washoku': '和食',
  'izakaya_bar': '居酒屋・バー',
  'yakitori_age': '焼き鳥・揚げ物',
  'nabe_yakiniku': '鍋・焼肉',
  'ramen_chinese': 'ラーメン・中華',
  'asian_ethnic': 'アジア・エスニック',
  'western_french': '洋食・フレンチ',
  'italian_meat': 'イタリアン・肉料理',
  'shokudo_other': '食堂・その他',
};

const Map<String, String> genreHashtags = {
  'cafe_sweets': 'カフェ巡り',
  'washoku': '和食巡り',
  'izakaya_bar': '居酒屋巡り',
  'yakitori_age': '焼き鳥',
  'nabe_yakiniku': '焼肉',
  'ramen_chinese': 'ラーメン',
  'asian_ethnic': 'エスニック料理',
  'western_french': '洋食',
  'italian_meat': 'イタリアン',
  'shokudo_other': '食堂',
};
```

### 3-3. 実装クラス

```dart
// lib/utils/share_text_generator.dart

class ShareTextGenerator {
  static String generateMonthlyReport(MonthlyReportModel report) {
    final yearMonth = '${report.yearMonth.substring(0, 4)}年${report.yearMonth.substring(5, 7)}月';
    final topGenreLabel = genreLabels[report.topGenre] ?? '色々なジャンル';
    final topGenreHashtag = genreHashtags[report.topGenre] ?? 'グルメ';

    final legendLine = report.legendDiscoveredCount > 0
        ? '\n✨ レジェンド発見: ${report.legendDiscoveredCount}店舗！'
        : '';
    final areeLine = report.visitedAreas.isNotEmpty
        ? '\n🗾 探検エリア: ${report.visitedAreas.join('・')}'
        : '';

    return '''$yearMonthのぐるまっぷ探検レポート🗺️

📍 今月の発見: ${report.monthlyDiscoveredCount}店舗
🏆 累計発見: ${report.totalDiscoveredCount}店舗
🍽️ 今月のお気に入りジャンル: $topGenreLabel$legendLine$areeLine

みんなと一緒に街を探検中！
#ぐるまっぷ #街歩き #$topGenreHashtag''';
  }
}
```

### 3-4. シェア実装（クリップボードコピー方式）

```dart
// flutter/services の Clipboard を使用（share_plus パッケージ不使用）
// → 外部パッケージ追加なしで実装可能
await Clipboard.setData(ClipboardData(text: shareText));
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('コピーしました！SNSに貼り付けてシェアしよう')),
);
```

---

## 4. Firestore ルール追加

```
// monthly_reports コレクション
match /monthly_reports/{userId}/reports/{yearMonth} {
  allow read: if request.auth != null && request.auth.uid == userId;
  allow write: if false; // Functions のみ書き込み可
}

// monthly_reports_community コレクション
match /monthly_reports_community/{yearMonth} {
  allow read: if request.auth != null;
  allow write: if false; // Functions のみ書き込み可
}
```

---

## 5. 実装タスク一覧（推奨順序）

```
① Firestore スキーマ追加（FIRESTORE.md 更新）
    → monthly_reports コレクション定義

② Cloud Functions: generateMonthlyReport 実装
    → functions/src/index.ts に追加
    → firebase deploy --only functions:generateMonthlyReport

③ Firestore ルール追加
    → firebase deploy --only firestore:rules

④ Flutter: MonthlyReportModel 作成
    → lib/models/monthly_report_model.dart

⑤ Flutter: monthly_report_provider.dart 作成

⑥ Flutter: monthly_report_view.dart 作成

⑦ Flutter: share_text_generator.dart 作成

⑧ Flutter: DeepLink ルーティング追加（/monthly_report/{yearMonth}）
    → lib/services/deep_link_service.dart
    → lib/views/main_navigation_view.dart

⑨ Flutter: ProfileView に「過去のレポート」ボタン追加

⑩ USER_APP_SCREENS.md 更新
```

---

## 6. 依存関係・前提条件

| 依存 | 理由 |
|------|------|
| フェーズ2 エリアシステム完了 | `areas` コレクション・エリア名が必要 |
| フェーズ2 マップ拡張完了 | `totalVisits` ミラー書き込みが必要（賑わい度集計） |
| フェーズ2 ランキング刷新完了 | `discoveredStoreCount` フィールドが必要 |

---

## 7. 未決事項

| 項目 | 状態 | 備考 |
|------|------|------|
| 月末が日曜日の場合の実行タイミング | 未確定 | L（last day）指定で対応可能 |
| レポートがない月の表示（初月等） | 未確定 | 「まだレポートはありません」空表示 |
| 通知の opt-out | 未確定 | 通知設定画面にトグル追加を検討 |
| 画像シェア（OGP 画像生成） | 将来検討 | 現フェーズはテキストのみ |
