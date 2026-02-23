# プロフィール編集画面から興味カテゴリを分離し、段階的完成フローを構築

## Context

現在、プロフィール編集画面（ProfileEditView）に興味カテゴリ（46カテゴリのチップ選択）が含まれており、プロフィール完成度は9項目一括で計算されている。ユーザーから、興味カテゴリを別ページに分離し、プロフィール基本情報→興味カテゴリ設定の2段階で完成させるフローへの変更が要求された。

## 変更対象ファイル

1. **`lib/views/settings/profile_edit_view.dart`** - 興味カテゴリセクション削除
2. **`lib/views/settings/interest_category_view.dart`** - 新規作成（興味カテゴリ設定画面）
3. **`lib/views/profile/profile_view.dart`** - 完成度ロジック変更＋UI分岐
4. **`USER_APP_SCREENS.md`** - ドキュメント更新

## 実装手順

### Step 1: 興味カテゴリ設定画面の新規作成

**ファイル**: `lib/views/settings/interest_category_view.dart`

- ProfileEditViewの興味カテゴリUI（チップ選択）を流用して独立画面を作成
- 46カテゴリの`_allCategories`リストをそのまま使用
- Firestoreから`interestCategories`を読み込み、保存する機能
- AppBarタイトル: 「興味カテゴリ設定」（CommonHeader使用）
- 保存ボタンで`interestCategories`フィールドをFirestoreに更新
- 保存成功後、`profile_completed`ミッション判定を実行（全9項目が揃った場合）

### Step 2: ProfileEditViewから興味カテゴリを削除

**ファイル**: `lib/views/settings/profile_edit_view.dart`

- 行820-862の「興味のあるカテゴリ」セクション（ラベル＋Wrapチップ）を削除
- `_selectedInterestCategories`状態変数は残す（保存時のデータ整合のため）
  - ただし保存時に`interestCategories`を既存の値で上書きしないよう、保存データから`interestCategories`キーを削除する
- `_allCategories`定数はInterestCategoryViewに移動するため削除

### Step 3: ProfileViewの完成度ロジックとUI更新

**ファイル**: `lib/views/profile/profile_view.dart`

#### 完成度計算の2段階化

- `_calcProfileCompletion`を修正: `interestCategories`を除外した8項目ベースに変更（基本プロフィール完成度）
- 新メソッド`_isInterestCategorySet`: `interestCategories`が空でないかをチェック
- 全体完成度: 基本プロフィール8項目 + 興味カテゴリ1項目 = 9項目のまま

#### UI条件分岐（3パターン）

**パターン1: 基本プロフィール未完成**
- 「プロフィールを完成させよう！」カード表示（現在と同様）
- プログレスバーは基本8項目の進捗を表示
- ボタン: 「プロフィールを編集する」→ ProfileEditView

**パターン2: 基本プロフィール完成済み＆興味カテゴリ未設定**
- 「興味カテゴリを設定しよう！」カード表示（新規）
- 説明: 「あなたに合ったお店が見つかりやすくなります」
- ボタン: 「興味カテゴリを設定する」→ InterestCategoryView

**パターン3: 全て完了（100%）**
- 完成度カード非表示
- アカウントセクションに以下を表示:
  - 「プロフィール編集」メニュー項目
  - 「興味カテゴリ設定」メニュー項目（新規追加）

#### 設定リストの更新

- `_calcProfileCompletion >= 1.0`（全9項目完了）の場合に「プロフィール編集」を表示（既存動作）
- 「興味カテゴリ設定」を「プロフィール編集」の下に追加（プロフィール完成後のみ表示、`_isInterestCategorySet`に関わらず常時表示）
- import文に`InterestCategoryView`を追加

### Step 4: USER_APP_SCREENS.md更新

- InterestCategoryViewを新画面として追記
- ProfileViewの説明を2段階完成フローに更新
- ProfileEditViewから興味カテゴリ記述を削除

## 検証方法

1. プロフィール基本情報が未完成の状態で「プロフィールを完成させよう」カードが表示されることを確認
2. 基本情報を全て入力して保存後、「興味カテゴリを設定しよう」カードが表示されることを確認
3. 興味カテゴリ設定画面でカテゴリを選択して保存後、完成度カードが非表示になることを確認
4. 全完了後のアカウントセクションに「プロフィール編集」「興味カテゴリ設定」の2項目が表示されることを確認
5. `flutter analyze`でエラーがないことを確認
