---
name: rarity-gradient-rules
description: レア度グラデーション（シルバー/ゴールド）を新しい場所に適用する依頼時に使う。「グラデーションを適用して」「レア度の色を使って」「図鑑カードと同じグラデーション」などの依頼時に、RarityGradient / RarityGradientContainer を使って実装するためのルール。
---

# レア度グラデーション実装ルール

## 概要

GrouMapのレア度グラデーション（ポケモンカード風シルバー/ゴールド）は、以下の2ファイルで一元管理されている。
新しくグラデーションを適用する際は、これらを必ず使うこと。ハードコードは禁止。

## ファイル構成

| ファイル | 役割 |
|---|---|
| `lib/widgets/rarity_gradient.dart` | 色定数・Widget用・Canvas用グラデーションヘルパー |
| `lib/widgets/rarity_gradient_container.dart` | 汎用コンテナウィジェット（Widget用） |

## グラデーションの種類

| rarityLevel | 種類 | 用途 |
|---|---|---|
| 1〜3 | シルバー（白×グレー交互） | 通常レア度 |
| 4 | ゴールド（白×金交互） | 最高レア度（レジェンド） |

## Widget に枠グラデーションを適用する場合

`RarityGradientContainer` を使う。

```dart
import 'package:groumapapp/widgets/rarity_gradient_container.dart';

RarityGradientContainer(
  rarityLevel: item.rarityLevel, // 1〜4
  borderRadius: 10,              // 省略可（デフォルト 10）
  padding: EdgeInsets.all(5),    // 省略可（デフォルト EdgeInsets.all(5)）
  glowOpacity: 0.35,             // 省略可（デフォルト 0.35）
  child: YourContentWidget(),
)
```

## グラデーションの色・Gradient だけを取得したい場合

`RarityGradient` の static メソッドを使う。

```dart
import 'package:groumapapp/widgets/rarity_gradient.dart';

// Widget用 LinearGradient（Container の gradient に直接渡す場合など）
final gradient = RarityGradient.borderGradient(rarityLevel);

// グロー色
final color = RarityGradient.glowColor(rarityLevel);

// BoxShadow（グロー効果）
final shadow = RarityGradient.glowBoxShadow(rarityLevel, opacity: 0.35);
```

## Canvas（BitmapDescriptor / マップピン）に適用する場合

`dart:ui` の `ui.Gradient` が必要な場面では Canvas用メソッドを使う。

```dart
import 'package:groumapapp/widgets/rarity_gradient.dart';

// 塗りつぶし用グラデーション
final fillGradient = RarityGradient.canvasFillGradient(
  rarityLevel,
  Offset(x1, y1), // 開始点
  Offset(x2, y2), // 終了点
);

// ボーダー用グラデーション
final borderGradient = RarityGradient.canvasBorderGradient(
  rarityLevel,
  Offset(x1, y1),
  Offset(x2, y2),
);

// 使用例（Paint に shader を設定）
final paint = Paint()..shader = fillGradient;
canvas.drawPath(path, paint);
```

## 適用済み箇所

- **図鑑カード**: `lib/widgets/zukan_card_face_widget.dart` — `RarityGradientContainer` を使用
- **マップピン（Legend/ゴールド）**: `lib/views/map/map_view.dart` — `canvasFillGradient(4, ...)` / `canvasBorderGradient(4, ...)`
- **マップピン（Gray/シルバー）**: `lib/views/map/map_view.dart` — `canvasFillGradient(1, ...)` / `canvasBorderGradient(1, ...)`
- **マップピン（Green/営業中）**: `lib/views/map/map_view.dart` — `canvasGreenFillGradient(...)`
- **マップピン（通常/カテゴリ色）**: `lib/views/map/map_view.dart` — `canvasColorFillGradient(...)` / `canvasColorBorderGradient(...)`

## 注意事項

- グラデーションの色定義を変えたい場合は `rarity_gradient.dart` のみを修正すること
- 各呼び出し側（zukan_card_face_widget.dart, map_view.dart など）は修正不要
- `RarityGradient` の色定数（`goldColors` / `silverColors` など）は `const` なのでパフォーマンスへの影響なし
