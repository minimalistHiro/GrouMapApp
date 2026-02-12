# 全ユーザー数推移画面 - 統計情報をグラフ直下に配置

## Context

店舗用アプリの「全ユーザー数推移」画面で、統計情報セクションが画面下部に1つだけ表示されている。ユーザーの要望は、各グラフ（新規ユーザー数推移・累計ユーザー数推移）の直下にそれぞれ専用の統計情報を配置すること。

**現在のレイアウト:**
```
期間選択
新規ユーザー数推移グラフ
累計ユーザー数推移グラフ
統計情報（総/最大/最小/平均の4項目）  ← 下部に一括表示
```

**変更後のレイアウト:**
```
期間選択
新規ユーザー数推移グラフ
  統計情報（最大/最小/平均の3項目）    ← グラフ直下
累計ユーザー数推移グラフ
  統計情報（総ユーザー数の1項目のみ）  ← グラフ直下
```

## 変更対象ファイル

1. `/Users/kanekohiroki/Desktop/groumapapp_store/lib/views/analytics/trend_base_view.dart`
2. `/Users/kanekohiroki/Desktop/groumapapp_store/lib/views/analytics/all_user_trend_view.dart`

## 実装手順

### Step 1: TrendBaseViewに新しいデータモデルを追加

`trend_base_view.dart` に以下のクラスを追加:

```dart
enum TrendStatType { total, max, min, avg, lastValue }

class TrendStatItem {
  const TrendStatItem({
    required this.type,
    required this.label,
    required this.icon,
    required this.color,
  });
  final TrendStatType type;
  final String label;
  final IconData icon;
  final Color color;
}

class ChartStatsConfig {
  const ChartStatsConfig({required this.items});
  final List<TrendStatItem> items;
}
```

- `lastValue` タイプは累計グラフ用（データの最終値 = 総ユーザー数）

### Step 2: TrendBaseViewにオプションパラメータを追加

`TrendBaseView` コンストラクタに以下を追加:

- `primaryChartStats: ChartStatsConfig?` — プライマリグラフ直下の統計設定
- `secondaryChartStats: ChartStatsConfig?` — セカンダリグラフ直下の統計設定

### Step 3: 統計値の計算メソッドを追加

`_TrendBaseViewState` に `_computeStatValue` メソッドを追加:

```dart
int _computeStatValue(TrendStatType type, List<Map<String, dynamic>> data, String valueKey) {
  if (data.isEmpty) return 0;
  switch (type) {
    case TrendStatType.total:
      return data.fold<int>(0, (sum, d) => sum + _getValue(d, valueKey));
    case TrendStatType.max:
      return data.map((d) => _getValue(d, valueKey)).reduce((a, b) => a > b ? a : b);
    case TrendStatType.min:
      return data.map((d) => _getValue(d, valueKey)).reduce((a, b) => a < b ? a : b);
    case TrendStatType.avg:
      final total = data.fold<int>(0, (sum, d) => sum + _getValue(d, valueKey));
      return (total / data.length).round();
    case TrendStatType.lastValue:
      return _getValue(data.last, valueKey);
  }
}
```

### Step 4: チャート直下用の統計Widgetメソッドを追加

`_buildInlineStats` メソッドを追加。既存の `_buildStatsRow` を再利用し、`ChartStatsConfig` の `items` から統計データ配列を生成して描画する。白背景カードではなく、グラフカード内に自然に溶け込むデザインにする。

### Step 5: buildメソッドのレイアウトを変更

`_TrendBaseViewState.build` 内の `data:` ケースで:

- `primaryChartStats` または `secondaryChartStats` が設定されている場合:
  - プライマリグラフの後に `_buildInlineStats` を表示
  - セカンダリグラフの後に `_buildInlineStats` を表示
  - 下部の `_buildStatsSectionWithData` を**表示しない**
- どちらも設定されていない場合:
  - 既存の動作を維持（下部に統計セクション表示）

同様に `loading:` と `error:` のケースも対応。

### Step 6: AllUserTrendViewの設定を変更

`all_user_trend_view.dart` で `TrendBaseView` に新しいパラメータを追加:

```dart
primaryChartStats: const ChartStatsConfig(
  items: [
    TrendStatItem(type: TrendStatType.max, label: '最大ユーザー数', icon: Icons.trending_up, color: Color(0xFFFF6B35)),
    TrendStatItem(type: TrendStatType.min, label: '最小ユーザー数', icon: Icons.trending_down, color: Color(0xFFFF6B35)),
    TrendStatItem(type: TrendStatType.avg, label: '平均ユーザー数', icon: Icons.analytics, color: Color(0xFFFF6B35)),
  ],
),
secondaryChartStats: const ChartStatsConfig(
  items: [
    TrendStatItem(type: TrendStatType.lastValue, label: '総ユーザー数', icon: Icons.group, color: Color(0xFFFF6B35)),
  ],
),
```

## 既存画面への影響

- **StoreUserTrendView**: `primaryChartStats`/`secondaryChartStats` を設定しないため、既存の下部統計セクションがそのまま表示される。**変更なし**。
- **NewCustomerTrendView**: 同上。**変更なし**。

## 検証方法

1. 店舗用アプリで「全ユーザー推移」画面を開く
2. 新規ユーザー数推移グラフの直下に「最大/最小/平均」の3統計が表示されることを確認
3. 累計ユーザー数推移グラフの直下に「総ユーザー数」のみ表示されることを確認
4. 下部に統計情報セクションが表示されないことを確認
5. 「店舗利用者推移」「新規顧客推移」画面で既存の下部統計セクションが正常に表示されることを確認
6. 期間切り替え（日/月/年）で統計値が正しく再計算されることを確認
7. `flutter analyze` でエラーがないことを確認
