# 営業時間の複数時間帯対応

## Context

飲食店では「9:00〜12:00、17:00〜22:00」のように昼休憩を挟む営業形態が一般的。現在の実装では各曜日に1つの `open`/`close` ペアしか持てず、このような営業形態に対応できない。Firestoreデータ構造の拡張、店舗用アプリの入力UI改修、ユーザー用アプリの表示・判定ロジック更新を行う。

---

## 1. Firestoreデータ構造の拡張

### 現在
```
businessHours.monday: { open: "09:00", close: "18:00", isOpen: true }
```

### 変更後（後方互換性維持）
```
businessHours.monday: {
  open: "09:00",          // 1つ目の時間帯（後方互換用に残す）
  close: "12:00",
  isOpen: true,
  periods: [              // 新規追加：複数時間帯
    { open: "09:00", close: "12:00" },
    { open: "17:00", close: "22:00" }
  ]
}
```

**ルール**: `periods` が存在すればそちらを使用、なければ `open`/`close` にフォールバック。`periods` が1つだけの場合も `open`/`close` と同期する。

---

## 2. 店舗用アプリ：UI改修

**ファイル**: `groumapapp_store/lib/views/settings/store_profile_edit_view.dart`

### 2-1. state変数の変更（行62-70）

`_businessHours` の値を `periods` リスト形式に変更：
```dart
Map<String, Map<String, dynamic>> _businessHours = {
  'monday': {
    'isOpen': true,
    'periods': [{'open': '09:00', 'close': '18:00'}],
  },
  // ... 他の曜日も同様
};
```

### 2-2. データ読み込み処理の更新（行318前後）

Firestoreから読み込む際、`periods` がなければ `open`/`close` から `periods` リストを生成する移行ロジックを追加。

### 2-3. UI描画の改修（`_buildBusinessHoursSection()` 行1589-1686）

各曜日のUI構造を変更：
```
月曜日 [✓営業]
  [09:00] 〜 [12:00]  [−]
  [17:00] 〜 [22:00]  [−]
  [＋ 時間帯を追加]
```

- 各 period に開始・終了の `TextFormField` + 削除ボタン（`−`）
- 「時間帯を追加」ボタンで `periods` リストに空エントリを追加
- period が1つの場合は削除ボタンを非表示

### 2-4. 保存処理の更新（行740前後）

保存時に `periods` の最初の要素を `open`/`close` にも同期して保存（後方互換）：
```dart
for (final day in _businessHours.entries) {
  final periods = day.value['periods'] as List;
  if (periods.isNotEmpty) {
    day.value['open'] = periods.first['open'];
    day.value['close'] = periods.first['close'];
  }
}
```

---

## 3. ユーザー用アプリ：営業判定ロジック更新

### 3-1. map_view.dart

**`_isStoreOpenNow()`（行1259-1314）**
- `periods` 配列が存在する場合、いずれかの period 内であれば `true` を返す
- `periods` がなければ従来の `open`/`close` で判定（後方互換）

**`_getTodayHours()`（行1342-1394）**
- `periods` があれば全ての時間帯を結合表示：`"09:00〜12:00 / 17:00〜22:00"`
- `periods` がなければ従来通り `"$open〜$close"`

**`_isWithinTimeRange()`（行1317-1339）**
- 変更不要（単一時間帯の判定用として維持）

新規ヘルパー追加：
```dart
bool _isWithinAnyPeriod(List<dynamic> periods, DateTime now) {
  return periods.any((p) => _isWithinTimeRange(
    p['open']?.toString() ?? '',
    p['close']?.toString() ?? '',
    now,
  ));
}

String _formatPeriods(List<dynamic> periods) {
  return periods.map((p) {
    final open = p['open']?.toString() ?? '';
    final close = p['close']?.toString() ?? '';
    return '$open〜$close';
  }).join(' / ');
}
```

### 3-2. store_detail_view.dart

**`_buildBusinessHoursDisplay()`（行2476-2863）**
- 7日間カレンダー表示で、各日の `timeText` を複数時間帯対応
- `periods` があれば `"09:00-12:00 / 17:00-22:00"` 形式で表示
- なければ従来の `"$openTime - $closeTime"`

**`_getBusinessStatus()`（行2872-2932）**
- `periods` がある場合、いずれかの period で営業中かを判定
- 全 period を確認し、「まもなく営業開始」「まもなく営業終了」も正しく判定

**`_evaluateTimeRange()`（行2935-2971）**
- 変更不要（単一時間帯用として維持）

新規メソッド追加：
```dart
({String label, Color color}) _evaluateMultiplePeriods(
  List<dynamic> periods, DateTime now, {String? prefix}
)
```

### 3-3. daily_recommendation_view.dart

**`_formatBusinessHours()`（行663-713）**
- `periods` フィールドを参照し、複数時間帯をまとめて表示

---

## 4. モデルクラスの更新

**ファイル**: `groumapapp/lib/models/store_model.dart`

`StoreDayHours` に `periods` フィールドを追加：
```dart
@freezed
class StoreDayHours with _$StoreDayHours {
  const factory StoreDayHours({
    required String open,
    required String close,
    @Default(false) bool isClosed,
    @Default([]) List<Map<String, String>> periods,
  }) = _StoreDayHours;
}
```

**ファイル**: `groumapapp/lib/providers/store_provider.dart`（行47-88）
- `periods` フィールドの変換ロジックを追加

---

## 5. 変更対象ファイル一覧

| # | ファイル | 変更内容 |
|---|---------|---------|
| 1 | `groumapapp_store/.../store_profile_edit_view.dart` | state変数・UI・保存・読込の改修 |
| 2 | `groumapapp/lib/models/store_model.dart` | `StoreDayHours` に periods 追加 |
| 3 | `groumapapp/lib/providers/store_provider.dart` | periods 変換ロジック追加 |
| 4 | `groumapapp/lib/views/map/map_view.dart` | 営業判定・時間表示の複数時間帯対応 |
| 5 | `groumapapp/lib/views/stores/store_detail_view.dart` | 営業時間表示・ステータス判定の改修 |
| 6 | `groumapapp/lib/views/stamps/daily_recommendation_view.dart` | `_formatBusinessHours` 改修 |

---

## 6. 実装順序

1. **店舗用アプリのUI・保存ロジック**（ファイル#1）
2. **ユーザー用アプリのモデル更新**（ファイル#2 → `build_runner` 実行）
3. **store_provider のデータ変換**（ファイル#3）
4. **map_view の営業判定・表示**（ファイル#4）
5. **store_detail_view の表示・判定**（ファイル#5）
6. **daily_recommendation_view の表示**（ファイル#6）

---

## 7. 検証方法

1. **店舗用アプリ**: 店舗プロフィール編集画面で複数時間帯を設定・保存し、Firestoreに `periods` と `open`/`close`（後方互換）が正しく保存されることを確認
2. **ユーザー用アプリ - マップ画面**: 複数時間帯設定の店舗で「営業中/営業時間外」が正しく判定されること、時間表示が「09:00〜12:00 / 17:00〜22:00」形式であること
3. **ユーザー用アプリ - 店舗詳細**: 7日間カレンダーで複数時間帯が正しく表示されること
4. **後方互換**: `periods` フィールドのない既存店舗データが従来通り正しく表示されること
5. **コード解析**: `flutter analyze` でエラーがないこと
