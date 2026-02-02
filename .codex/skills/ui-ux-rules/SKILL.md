---
name: ui-ux-rules
description: GrouMapの画面作成・画面編集でUI/UXルールを適用するためのガイド。ユーザーが「画面作成」「画面編集」「UI」「UX」「レイアウト」「デザイン」や画面の見た目・レイアウト変更を依頼したときに使う。
---

# UI/UX Rules

## 概要

GrouMapの画面作成・編集時に、既定のUI/UXルールを必ず適用する。ユーザー用・店舗用の両方で同一UIとなるように、共通ウィジェットは同等実装を維持する。

## ガイドライン

- **ユーザー用**は `/Users/kanekohiroki/Desktop/groumapapp/lib/widgets/` の各ウィジェットを使用する。
- **店舗用**は `/Users/kanekohiroki/Desktop/groumapapp_store/lib/widgets/` の同名ウィジェットを使用し、ユーザー用と同一UIになるよう実装を揃える。
- ヘッダーは `common_header.dart` を使用する。
- ボタンは `custom_button.dart` を使用する。
- テキストフィールドは `error_dialog.dart` を使用する。
- 画面背景はホーム画面の `Colors.grey[50]` を基準に、他画面も同系統で統一する。
- 上部タブは `custom_top_tab_bar.dart` を使用する。
- 上部タブの配色はオレンジ背景 `#FF6B35`（`Color(0xFFFF6B35)`）＋白テキストで統一する。
- 青色のテキストボタンは `Colors.blue`（`Color(0xFF2196F3)` 相当）を使用し、文字は **ボールド** にする。
- 入力不備がある場合は、ボタンの下に赤文字（`Colors.red`）・フォントサイズ12のテキストを表示する（ボールドにしない）。
- 店舗アイコン未設定時のデフォルト表示は、店舗詳細画面の既定仕様に合わせる（アイコンと背景色はカテゴリ依存、背景色はアイコン色の `withOpacity(0.1)` を使用）。
  - アイコン: レストラン `Icons.restaurant` / カフェ `Icons.local_cafe` / ショップ `Icons.shopping_bag` / 美容院 `Icons.content_cut` / 薬局 `Icons.local_pharmacy` / コンビニ `Icons.store` / スーパー `Icons.shopping_cart` / 書店 `Icons.menu_book` / その他 `Icons.store`
  - 背景色: レストラン `Colors.red` / カフェ `Colors.brown` / ショップ `Colors.blue` / 美容院 `Colors.pink` / 薬局 `Colors.green` / コンビニ `Colors.orange` / スーパー `Colors.lightGreen` / 書店 `Colors.purple` / その他 `Colors.grey`
- ユーザーのデフォルトアイコンは、背景色をアイコン色の `withOpacity(0.1)` にし、アイコンはホーム画面と同じ人型（`Icons.person`）を使用する。
- 成功時の通知は表示しない（緑のスナックバーは使わない）。
- エラー時は赤いスナックバーを使わず、デフォルトのダイアログで日本語メッセージを表示する。
