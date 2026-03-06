# ウォークスルー改善計画

作成日: 2026-03-06

## 背景・目的

現在のウォークスルーは「UIの操作方法」を教えるだけで、アプリの楽しさ・価値が伝わっていない。
新規ユーザーが最初の数分でアプリの魅力を体感し、実際に店舗へ足を運ぶ動機付けをすることが目的。

### 現状の問題

| 現ステップ | 問題点 |
|---|---|
| マップを開いてみよう | なぜ開くのかの動機がない |
| お店をタップしてみよう | タップして何が嬉しいか不明 |
| 閉じてみよう | 作業的でゲーム感ゼロ |
| 図鑑タブを確認しよう | 図鑑の価値・NFCタッチの説明がない |

最大の欠陥: **NFCタッチ（コア体験）への言及が一切ない**。アカウントタブの紹介もない。

### 心理学的根拠（ビジネスモデルの5理論を活用）

| 理論 | ウォークスルーへの適用 |
|---|---|
| 情報ギャップ理論 | 「まだ誰も知らないお店がある」と先に言って好奇心を刺激 |
| ツァイガルニク効果 | 「？？？」シルエットを早期に見せてコンプリート欲求を植え付ける |
| 可変報酬 | 「レア度はタッチするまでわからない」という不確実性を言語化 |
| FOMO | 「あなたが最初の発見者になれる」という希少性の強調 |
| 自己決定理論 | 「どの店に行くかはあなたが決める」という自律性の尊重 |

---

## 新しいウォークスルーフロー（6ステップ）

### ステップ0: コンセプト提示（フルスクリーンオーバーレイ）
- **メッセージ**: 「街を舞台にした探検ゲームへようこそ。ただし、実際に行かないと進まない。」
- **UI**: 3つのアイコンで価値を説明
  - マップで未発見の店を探す → NFCタッチで図鑑GET → コレクション達成
- **進め方**: 「はじめる」ボタンタップで次へ（操作不要）
- **心理**: 全体像を先に見せることで次ステップへの期待が生まれる

### ステップ1: マップタブ（現ステップ1を改善）
- **enum**: `tapMapTab`（既存）
- **メッセージ**: 「マップを開いてみよう！」
- **サブテキスト**: 「グレーのマーカーが"まだ誰も発見していない"お店です」
- **心理**: 「誰も発見していない」という希少性がFOMOと好奇心を刺激

### ステップ2: マーカータップ（現ステップ2を改善）
- **enum**: `tapMarker`（既存）
- **メッセージ**: 「気になるお店をタップしてみよう！」
- **サブテキスト**: 「★の数がレア度。少ない発見者数ほどレアなお店です」
- **心理**: レア度という可変報酬概念を提示し、どの店に行くか考えさせる

### ステップ3: NFCタッチ説明（新規・操作不要ステップ）
- **enum**: `learnNfcTouch`（新規追加）
- **メッセージ**: 「実際のお店でNFCタッチしてみよう！」
- **サブテキスト**: 「レジ近くのスタンドにスマホをかざすと図鑑カードが発見できます。何のレア度が出るかはお楽しみ✦」
- **UI**: 「次へ」ボタンで進む（実操作は不要）
- **心理**: コア体験を「お楽しみ」として提示し、店舗へ行く行動トリガーを作る

### ステップ4: 図鑑タブ（現ステップ4を改善）
- **enum**: `tapZukanTab`（既存）
- **メッセージ**: 「図鑑タブを開いてみよう！」
- **サブテキスト**: 「？？？のシルエットは、まだ行っていないお店。コンプリートを目指そう！」
- **心理**: ツァイガルニク効果。未完了カードが「埋めたい」衝動を生む

### ステップ5: アカウントタブ（新規追加）
- **enum**: `tapProfileTab`（新規追加）
- **メッセージ**: 「アカウントタブもチェック！」
- **サブテキスト**: 「バッジ・ランキング・毎月の探検レポートが見られます」
- **心理**: 達成物・社会的比較・振り返りの3つのモチベーション維持装置を紹介

### 完了時メッセージ（モーダル or スナックバー）
- 「準備完了！探検を始めよう」
- 「近くにはまだ誰も訪れていないお店があります。あなたが最初の発見者になってみませんか？」

---

## 実装内容

### 1. `WalkthroughStep` enumの拡張

**ファイル**: `lib/views/walkthrough/walkthrough_step_config.dart`

```dart
enum WalkthroughStep {
  none,
  concept,        // 新規: フルスクリーンコンセプト説明
  tapMapTab,      // 既存
  tapMarker,      // 既存
  tapClosePanel,  // 既存（削除または維持）
  learnNfcTouch,  // 新規: NFCタッチ説明（操作不要）
  tapZukanTab,    // 既存
  tapProfileTab,  // 新規: アカウントタブ
}
```

各ステップの `walkthroughStepConfigs` にサブテキスト（`subMessage`）フィールドを追加。

### 2. `WalkthroughStepConfig` にサブテキスト追加

```dart
class WalkthroughStepConfig {
  final WalkthroughStep step;
  final String message;
  final String? subMessage;   // 新規追加
  final IconData? icon;
  final MessagePosition messagePosition;
  final bool requiresAction;  // 新規: trueなら操作が必要、falseなら「次へ」ボタン表示
}
```

### 3. `WalkthroughOverlay` の改善

**ファイル**: `lib/views/walkthrough/walkthrough_overlay.dart`

- サブテキスト（`subMessage`）の表示対応
- `requiresAction: false` のステップには「次へ」ボタンを表示
- ステップ0（`concept`）用のフルスクリーンモード対応

### 4. `WalkthroughNotifier` のステップ順序調整

**ファイル**: `lib/providers/walkthrough_provider.dart`

- `startWalkthrough` の開始ステップを `concept` に変更
- ステップ遷移ロジックは既存の `nextStep()` をそのまま活用

### 5. `MainNavigationView` の対応

**ファイル**: `lib/views/main_navigation_view.dart`

- `_walkthroughAllowedTab` にアカウントタブ（`tapProfileTab`）を追加
- `_onBottomTabChanged` でアカウントタブタップ時のステップ進行を追加
- `_buildBottomScaffold` の `showTabOverlay` 条件にアカウントタブのステップを追加

### 6. `concept` / `learnNfcTouch` ステップのUI

これら2ステップは「タブをタップさせる」のではなく「次へボタンで進む」形式のため、
`WalkthroughOverlay` に専用のフルスクリーン表示モードを追加するか、
別途 `ConceptWalkthroughView` として `Navigator.push` で表示する方法を採用する。

**推奨**: `WalkthroughOverlay` 内で `targetRect == null && requiresAction == false` の場合に
フルスクリーンオーバーレイ + 「次へ」ボタンを表示するモードを実装する。

---

## ファイル変更一覧

| ファイル | 変更内容 |
|---|---|
| `lib/views/walkthrough/walkthrough_step_config.dart` | enum追加、subMessage・requiresAction追加、config更新 |
| `lib/views/walkthrough/walkthrough_overlay.dart` | subMessage表示、次へボタン、フルスクリーンモード追加 |
| `lib/providers/walkthrough_provider.dart` | startWalkthroughの開始ステップをconceptに変更 |
| `lib/views/main_navigation_view.dart` | アカウントタブ対応、showTabOverlay条件追加 |

---

## 実装優先順位

1. **フェーズ1（最小実装）**: 既存ステップのメッセージ文言改善 + サブテキスト追加
   - `walkthrough_step_config.dart` の文言・config更新のみ
   - `walkthrough_overlay.dart` にサブテキスト表示追加

2. **フェーズ2（ステップ追加）**: NFCタッチ説明ステップ・アカウントタブステップ追加
   - enumに `learnNfcTouch` / `tapProfileTab` 追加
   - 「次へ」ボタン対応

3. **フェーズ3（コンセプト画面）**: ステップ0のフルスクリーンコンセプト画面
   - 3アイコンの説明レイアウト実装

---

## 注意事項

- `tapClosePanel` ステップは「お店を閉じる」操作を求めるが、ゲーム感に貢献しないため**削除検討**
- ウォークスルー完了後（`walkthroughCompleted: true`）のユーザーには表示しない（既存の仕組みを維持）
- レコメンド・バッジポップアップとの競合は対策済み（`_walkthroughStarted` によるスキップ）
- スキップボタンは引き続き全ステップに表示する（自己決定理論：強制しない）
