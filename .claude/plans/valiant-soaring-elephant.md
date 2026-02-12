# 全ユーザー数推移の修正プラン

## Context

店舗用アプリの分析画面「全ユーザー数推移」で、1月31日よりも2月1日の方がユーザー数が少なく表示されるバグがある。
原因は、累計ユーザー数が「表示期間内」のみの積み上げで計算されており、月が変わると0からリセットされてしまうこと。
また、isOwner/isStoreOwnerの除外処理も行われていない。

## 現在の実装の問題点

### 問題1: 累計ユーザー数が期間内のみの積み上げ
- `AllUserTrendNotifier.fetchTrendData()` は表示期間内（例: 2月1日〜2月28日）の新規ユーザーのみカウント
- `_buildCumulativeTrendData()` はその新規ユーザーを0から積み上げるだけ
- **結果**: 1月表示時は1月の新規ユーザーの累計、2月表示時は2月の新規ユーザーの累計 → 月が変わるとリセット

### 問題2: isOwner/isStoreOwner の除外なし
- 全ユーザーを無条件にカウントしている
- `ranking_provider.dart` には `_shouldExcludeUser()` が存在するが、ここでは使われていない

## 修正方針

「その日時点での全ユーザー数（isOwner/isStoreOwner除外）」を正しく表示する。

## 修正ファイル

### 1. `groumapapp_store/lib/providers/store_provider.dart` (963-1070行付近)

`AllUserTrendNotifier.fetchTrendData()` を以下のように修正:

1. **isOwner/isStoreOwner 除外条件を追加** (1007-1021行のループ内)
   ```dart
   for (final userDoc in usersSnapshot.docs) {
     final data = userDoc.data();
     // 除外: isOwner または isStoreOwner
     if (data['isOwner'] == true || data['isStoreOwner'] == true) continue;

     final createdAt = _parseCreatedAt(data['createdAt']);
     if (createdAt == null) continue;
     // ...
   }
   ```

2. **表示期間より前のユーザー数（baseCumulative）を計算**
   - 全ユーザー（除外対象外）の中で、`createdAt < startDate` のユーザー数をカウント
   - これが累計の基底値になる

3. **各日付の累計ユーザー数を直接計算して返す**
   - 結果データに `totalUsers`（その日の新規）と `cumulativeUsers`（その日時点の合計）を含める
   - `cumulativeUsers` = baseCumulative + その日までの新規ユーザー累計

### 2. `groumapapp_store/lib/views/analytics/all_user_trend_view.dart` (54-77行)

`_buildCumulativeTrendData()` を修正:
- fetchTrendDataで事前計算済みの `cumulativeUsers` をそのまま使用する
- 0からの積み上げ計算を削除

## 具体的な実装

### store_provider.dart の fetchTrendData 修正

```dart
// ループで以下のように処理:
int baseCumulative = 0;
final Map<String, int> groupedUsers = {};

for (final userDoc in usersSnapshot.docs) {
  final data = userDoc.data();
  // isOwner/isStoreOwner を除外
  if (data['isOwner'] == true || data['isStoreOwner'] == true) continue;

  final createdAt = _parseCreatedAt(data['createdAt']);
  if (createdAt == null) continue;

  if (earliestDate == null || createdAt.isBefore(earliestDate!)) {
    earliestDate = createdAt;
  }

  // 表示期間より前のユーザーは baseCumulative にカウント
  if (createdAt.isBefore(startDate)) {
    baseCumulative++;
    continue;
  }

  // 表示期間内のユーザーをグルーピング
  if (createdAt.isAfter(endDate)) continue;

  final groupKey = _buildGroupKey(createdAt, period);
  groupedUsers[groupKey] = (groupedUsers[groupKey] ?? 0) + 1;
}

// 結果構築時に cumulativeUsers を付与
var cumulative = baseCumulative;
for (var date in datePoints) {
  final key = ...;
  final newUsers = groupedUsers[key] ?? 0;
  cumulative += newUsers;
  result.add({
    'date': key,
    'totalUsers': newUsers,
    'cumulativeUsers': cumulative,
  });
}
```

### all_user_trend_view.dart の _buildCumulativeTrendData 修正

```dart
static List<Map<String, dynamic>> _buildCumulativeTrendData(
    List<Map<String, dynamic>> trendData) {
  return trendData.map((data) {
    return {
      'date': data['date'],
      'cumulativeUsers': data['cumulativeUsers'] ?? 0,
    };
  }).toList();
}
```

## 検証方法

1. 店舗用アプリを起動し、分析画面 → 全ユーザー推移を開く
2. 「日」表示で1月を表示 → 1月31日の累計ユーザー数を確認
3. 「>」ボタンで2月に移動 → 2月1日の累計ユーザー数が1月31日以上であることを確認
4. 「月」表示で各月の累計が単調増加であることを確認
5. isOwner/isStoreOwnerのユーザーがカウントから除外されていることを確認
