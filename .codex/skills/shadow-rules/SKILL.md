---
name: shadow-rules
description: 「影をつけて」「影付き」「シャドウをつけて」「shadow」「ポップアップと同じ影」「カードに影」など、UIコンポーネントへの影付け依頼時に、GrouMap標準の影スタイルを適用するためのルール。
---

# Shadow Rules

## 概要

GrouMapのUIで影を付ける場合は、必ずアカウント画面のリストアイテム（`FloatingListItem`）と同じ影スタイルを使用する。独自の影定義を作ることは禁止。

## 標準影スタイル（必須）

影が必要な場合は、以下の `boxShadow` 定義をそのまま使用すること。

```dart
boxShadow: [
  BoxShadow(
    color: Colors.black.withOpacity(0.07),
    blurRadius: 8,
    offset: const Offset(0, 2),
  ),
],
```

### 定義元
- `lib/widgets/floating_list_item.dart` の `FloatingListItem` ウィジェット（`build` メソッド内 `BoxDecoration`）

## 適用ルール

- **「影をつけて」「影付き」「シャドウ」「shadow」** などのキーワードが含まれる依頼では、上記の標準影スタイルを適用する。
- `Container` / `DecoratedBox` の `BoxDecoration.boxShadow` に設定する。
- `Material` ウィジェットの `elevation` で影を付けることは禁止（標準影スタイルを使うこと）。
- カードUIは原則「影なし」だが、ユーザーから明示的に影付きを求められた場合のみ標準影スタイルを適用する（参照: ui-ux-rules「カードUIは角丸16・白背景・影なし」）。

## 使用例

```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.07),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: ...,
)
```
