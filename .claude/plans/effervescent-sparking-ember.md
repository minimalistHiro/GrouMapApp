# チュートリアル/ウォークスルーが新規登録後に開始されない問題の修正

## Context

新規アカウント登録後、マップ画面を開くウォークスルー（チュートリアル）が開始されない。Chrome/Web で実行した場合に特に顕著。原因は3つの問題の複合。

## 原因分析

### 原因1: `walkthroughCompleted` が初期ユーザードキュメントに未設定
- `lib/services/auth_service.dart` 行562: `_saveUserToFirestore()` で `showTutorial: true` は設定するが `walkthroughCompleted` フィールドが存在しない
- MainNavigationView の Path 2 条件 `userData['walkthroughCompleted'] == false` で、`null == false` → Dart では `false` に評価される → ウォークスルーが起動しない

### 原因2: `_completeTutorial()` が Firestore 更新を await していない
- `lib/views/tutorial/tutorial_view.dart` 行60-74: Firestore update が fire-and-forget
- TutorialView が pop された後、MainNavigationView が古いデータを受信する可能性

### 原因3: static `_tutorialShown` フラグのレースコンディション
- `lib/views/main_navigation_view.dart` 行92: `static bool _tutorialShown`
- メール認証完了時に AuthWrapper が "/" ルートで MainNavigationView(A) を一瞬作成 → `_tutorialShown = true` を設定
- その後 `pushAndRemoveUntil` で MainNavigationView(A) は破棄されるが、static フラグは残存
- 正規ルート（UserInfoView → TutorialView → MainNavigationView(B)）で `_tutorialShown = true` のため Path 1 がスキップされる
- 原因1・2により Path 2 も失敗 → **何も表示されない**

### Chrome/Web 特有の影響
- Firestore スナップショットリスナーの伝播タイミングがモバイルと異なり、レースコンディションが発生しやすい
- AuthWrapper の再ビルドが即座に起こるため、MainNavigationView(A) が確実に作成される

## 修正内容

### 修正1: `_saveUserToFirestore()` に `walkthroughCompleted: false` を追加
**ファイル:** `lib/services/auth_service.dart` 行562付近

```dart
'showTutorial': true,
'walkthroughCompleted': false,  // 追加
```

### 修正2: `_completeTutorial()` で Firestore 更新を await する
**ファイル:** `lib/views/tutorial/tutorial_view.dart` 行60-74

```dart
Future<void> _completeTutorial() async {
  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({
      'showTutorial': false,
      'walkthroughCompleted': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    debugPrint('チュートリアル完了フラグ更新エラー: $e');
  }
  if (mounted) {
    Navigator.of(context).pop();
  }
}
```

### 修正3: Path 2 の条件を null-safe に変更
**ファイル:** `lib/views/main_navigation_view.dart` 行782

変更前:
```dart
if (!_walkthroughStarted && userData['walkthroughCompleted'] == false && userData['showTutorial'] != true) {
```

変更後:
```dart
if (!_walkthroughStarted && userData['walkthroughCompleted'] != true && userData['showTutorial'] != true) {
```

`== false` を `!= true` に変更することで、`walkthroughCompleted` が `null`（未設定）の場合も `false` と同等に扱われる。既存ユーザーで `walkthroughCompleted` フィールドが存在しないケースにも対応。

## 修正対象ファイル
1. `lib/services/auth_service.dart` - 行562付近（1行追加）
2. `lib/views/tutorial/tutorial_view.dart` - 行60-74（await追加 + try/catch構造変更）
3. `lib/views/main_navigation_view.dart` - 行782（条件式変更）

## 検証方法
1. Chrome で `flutter run -d chrome` を実行
2. 新規アカウントをメールで作成
3. OTP 認証 → ユーザー情報入力 → チュートリアル4スライド表示を確認
4. チュートリアル完了後、ウォークスルー「マップ画面を開いてみよう！」が表示されることを確認
5. Google サインインでも同様にテスト
