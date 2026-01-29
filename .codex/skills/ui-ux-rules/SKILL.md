---
name: ui-ux-rules
description: GrouMapの画面作成・画面編集でUI/UXルールを適用するためのガイド。ユーザーが「画面作成」「画面編集」「UI」「UX」「レイアウト」「デザイン」や画面の見た目・レイアウト変更を依頼したときに使う。
---

# UI/UX Rules

## 概要

GrouMapの画面作成・編集時に、既定のUI/UXルールを必ず適用する。既存のデザイン・ウィジェットがある場合はそれを優先し、統一感を保つ。

## ガイドライン

- ヘッダーは`/Users/kanekohiroki/Desktop/groumapapp/lib/widgets/common_header.dart`を使用する。
- ボタンは`/Users/kanekohiroki/Desktop/groumapapp/lib/widgets/custom_button.dart`を使用する。
- テキストフィールドは`/Users/kanekohiroki/Desktop/groumapapp/lib/widgets/error_dialog.dart`を使用する。
- 画面背景はホーム画面の`Colors.grey[50]`を基準に、他画面も同系統で統一する。
- 上部タブは`/Users/kanekohiroki/Desktop/groumapapp/lib/widgets/custom_top_tab_bar.dart`を使用する。
- 上部タブの配色はオレンジ背景`#FF6B35`（`Color(0xFFFF6B35)`）＋白テキストで統一する。
- 成功時の通知は表示しない（緑のスナックバーは使わない）。
- エラー時は赤いスナックバーを使わず、デフォルトのダイアログで日本語メッセージを表示する。
