# ユーザー用アプリ 画面一覧（構成と説明）

この一覧は `/Users/kanekohiroki/Desktop/groumapapp/lib/views` 配下の画面実装を基に整理しています。各画面の「構成」は主要なUI要素の概要、「説明」は用途の軽い要約です。
※ 2026-02-24更新（12回目）: `HomeView` の「今日のレコメンド」を微調整。見出し文字サイズを「クーポン」「投稿」と同一に統一し、カード内テキストと余白をコンパクト化。カードの表示高さも縮小して縦方向の過密を解消。
※ 2026-02-24更新（11回目）: メール認証後の遷移を統一。`EmailVerificationPendingView` で `users/{uid}` のプロフィール入力状態（`birthDate` / `displayName`）を判定し、未完了時は `UserInfoView` へ遷移。`UserInfoView` 完了後は `TutorialView` を表示してから `MainNavigationView` へ遷移する導線に整理。
※ 2026-02-24更新（10回目）: `MissionsView` のコイン交換タブに表示する未訪問店舗一覧で `stores.isOwner=true` の店舗を除外。表示対象を `isActive=true` かつ `isApproved=true` かつ `isOwner!=true` の未訪問店舗に統一。
※ 2026-02-24更新（9回目）: `HomeView` の「今日のレコメンド」を刷新。おすすめ店舗の表示を1ページ1店舗の全幅カードに変更し、取得件数を5件へ調整。カード下部の円10個インジケータを廃止し、状態表示を「未訪問 / スタンプ X/10 / 満了」に統一。`PageView` を3秒間隔で自動送り（操作中は一時停止）するカルーセルに更新。
※ 2026-02-24更新（8回目）: `MapView` のマップ閲覧報酬カウントを1日1回に制限。Firestore `users/{uid}/daily_missions/{yyyy-MM-dd}.map_open` で日次制御し、同日にマップを複数回開いても報酬加算は初回のみ実行。
※ 2026-02-24更新（7回目）: `HomeView` 右下のミッションフローティングボタンを小型化（72x72）し、影を薄めに調整。受取可能時カラーをティール系から黄色系へ変更。`MissionsView` の達成状態カード・タブアクティブ色・報酬ポップアップも黄色基調に統一。
※ 2026-02-24更新（6回目）: `HomeView` のおすすめ店舗表示ロジックをフォールバック方式に更新。優先順は「未訪問（スタンプ0）」→「開拓中（スタンプ1〜9）」→「達成済み（スタンプ10以上）」で、上位カテゴリが空の場合に次カテゴリを表示。
※ 2026-02-24更新（5回目）: `HomeView` の統計カプセルバー（コイン/バッジ/スタンプ）を「おすすめ店舗」セクションの上へ移動。カプセルUIを白背景・強い丸角・左側の丸アイコン・「数値 + ラベル」表記のコンパクトデザインに更新（全体サイズ/テキスト/アイコンを小型化）。
※ 2026-02-24更新（4回目）: 新規登録後チュートリアル（`TutorialView`）を追加。新規登録後に初めてホーム画面に遷移したとき4枚スライドのチュートリアルを全画面表示（地図発見/スタンプ/コイン/バッジ）。`showTutorial` フラグ（Firestore `users/{uid}.showTutorial`）で初回1回のみ表示。`MainNavigationView` の `_maybeShowDailyRecommendation()` でチュートリアルを最優先表示し、完了後にレコメンドへ流れる順序を維持。
※ 2026-02-24更新（3回目）: 不定休（`isRegularHoliday=true`）の店舗における営業日表示を改善。`StoreDetailView` の7日間スケジュールで、scheduleOverrides（type='open'）がない日は「定休日」表示に統一（従来の「不定休です。営業日は各自ご確認ください。」メッセージを廃止）。type='open' override がある日は「通常営業 HH:mm〜HH:mm」として表示（「臨時営業」ラベルを使わない）。同様に14日バナー・ステータスチップも対応。`MapView` の `_getTodayHours()` で不定休かつ override なしの場合の表示を「不定休」→「定休日」に変更。
※ 2026-02-24更新（2回目）: `StoreDetailView` の営業時間セクションを週別日付表示に変更（今日〜6日後の7日間を `2/24(火)` 形式で表示、scheduleOverrides優先）。`MapView` の店舗吹き出しに今日の具体的な営業時間を表示（臨時休業/時間変更を反映）。`_isStoreOpenNow()` が scheduleOverrides・isRegularHoliday を考慮するよう修正し、「営業中のみ」フィルターにも反映。
※ 2026-02-24更新: 未ログイン起動時の導線を `WelcomeView` 起点に変更。ウェルカム画面に「ログインせずに開始」を追加し、3ボタン（新規登録/ログイン/ログインせずに開始）で遷移できるように更新。
※ 2026-02-24更新: スプラッシュスクリーン（ネイティブ）を追加。`flutter_native_splash` パッケージで背景色 `#FBF6F2` + 中央にGrouMapロゴを表示。Firebase初期化完了までスプラッシュを保持し、完了後に解除。
※ 2026-02-23更新: ユーザー用アプリ全画面のUI基盤を統一（共通ThemeData導入、`AppBar` を `CommonHeader` に統一、標準背景色を `#FBF6F2` に統一、共通ボタン/入力/トグル/上部タブのスタイルを統一）。
※ 2026-02-20更新: `MissionsView` の新規登録ミッション「スロット初挑戦」を「スタンプ初獲得」に変更。新規登録ミッション未完了時はデイリー/ログインタブを非活性化し、新規登録タブにガイドメッセージバナーを表示。
※ 2026-02-20更新: スロットキャンペーンボタンを廃止（コードはコメントアウトで保持）。
※ 2026-02-20更新: `UserInfoView` を簡略化（生年月日+性別のみ、都道府県・市区町村・プロフィール画像を削除）。`ProfileView` にプロフィール完成度カード（9項目ベース・100%未満時のみ表示）を追加、プロフィール未完成時は「プロフィール編集」メニューを非表示化。
※ 2026-02-23更新: `MapView` / `StoreListView` / `HomeView` / `DailyRecommendationView` のisOwner店舗除外を簡潔化。`stores.isOwner` フラグのみで判定（`users` コレクションのクロス参照を廃止）。Cloud Functions `setStoreOwnerFlagOnCreate` で店舗作成時に自動フラグ設定。
※ 2026-02-23更新: 法務画面（`TermsView` / `Legal/PrivacyPolicyView`）を最新規約Markdownに同期。サポート内の `TermsOfServiceView` / `Support/PrivacyPolicyView` は法務画面の共通表示を参照する構成に統一。問い合わせ先を `info@groumapapp.com` / `080-6050-7194（平日 11:00-18:00）` に統一。
※ 2026-02-20更新: `MapView` / `StoreListView` の表示対象店舗条件を整理。`isActive=true` かつ `isApproved=true` の店舗のみ表示。
※ 2026-02-19更新: スタンプカード表示を共通ウィジェット（`StampCardWidget`）に統一。スタンプ押印画面・スタンプカード一覧・店舗詳細画面で同一のスタンプカードUIを使用。スタンプ画像取得中はカード中心にローディングインジケーター表示。プログレスバー（ゲージ）を削除。
※ 2026-02-19更新: 投稿画面の追加読み込みを自動スクロールからボタン式に変更、取得件数を51件ずつ最大306件に変更、画像なし投稿のフィルタリング追加。
※ 2026-02-19更新: ホーム画面のミッションフローティングボタンに受取可能ミッション判定を追加（受取可能ミッションがない場合はグレーアウト表示）。
※ 2026-02-23更新: `AppInfoView` を新規追加（アプリ情報・開発者情報・法的リンク・公式アカウント）。`ProfileView` のサポートセクションに「アプリについて」メニューを追加。`HelpView` からアプリ情報セクションを削除（専用画面に移設）。
※ 2026-02-23更新: 興味カテゴリを `ProfileEditView` から分離し `InterestCategoryView` を新規作成。`ProfileView` のプロフィール完成度カードを2段階化（基本プロフィール8項目完成→興味カテゴリ設定→100%完了）。設定リストに「興味カテゴリ設定」メニューを追加。
※ 2026-02-22更新: `BadgesView` でFirestoreから取得済みバッジを取得し、全バッジ定義を表示しつつ未取得バッジは画像を「？」アイコン・名前を「？？？」に置換。詳細ダイアログも取得済み/未取得で表示を分岐。
※ 2026-02-18更新: `BadgesView` の上部カテゴリ一覧を廃止し、ヘッダー右上フィルターに統一。ロック/アンロック表示と詳細ポップアップ内のロック操作UIを削除。
※ 2026-02-10更新: `StoreDetailView` のトップタブにクーポン一覧と投稿プレビュー（新着15件）を追加し、投稿の「全て見る＞」で上部タブ「投稿」へ遷移する導線を追加。`CouponsView` のクーポンリストカードUIを共通化し、`StoreListView` のヘッダーを `CommonHeader` + `CustomTopTabBar` 構成へ統一。
※ 2026-02-08更新: ユーザー用画面の遷移元差分を解消（`StoreListView` / `MapView` / `DailyRecommendationView` から `StoreDetailView` へ渡す店舗データを正規化）。

## 起動・ナビゲーション

### MainNavigationView (`lib/views/main_navigation_view.dart`)
- 構成: ボトムタブ（ホーム/マップ/投稿/プロフィール + ログイン時のみQR）、FAB（QR起動）
- 説明: アプリ全体のタブ切替と初期データ読込を担うメインナビゲーション。バッジ獲得ポップアップの協調制御を一元管理（本日初ログイン時: レコメンドポップアップ→2秒→バッジポップアップ、2回目以降: 2秒後にバッジポップアップ）

## 認証・登録

### WelcomeView (`lib/views/auth/welcome_view.dart`)
- 構成: ロゴ画像（`splash_logo`）/サービス名/キャッチフレーズ、新規アカウント登録ボタン、ログインボタン、ログインせずに開始ボタン（青字・太字のテキストボタン）、補助文言（「一部機能はログインが必要です」）、フッター
- 説明: 未ログイン時の起動導線となるウェルカム画面。認証あり/なしを選択して先に進める

### SignInView (`lib/views/auth/sign_in_view.dart`)
- 構成: AppBar、Apple/Googleサインイン、メール/パスワード入力、ログインボタン、パスワード再設定導線
- 説明: 既存ユーザーのログイン画面

### TermsPrivacyConsentView (`lib/views/auth/terms_privacy_consent_view.dart`)
- 構成: 利用規約カード、プライバシーポリシーカード、同意ボタン
- 説明: 登録前の規約同意画面

### SignUpView (`lib/views/auth/sign_up_view.dart`)
- 構成: AppBar、Apple/Googleサインアップ、メール/パスワード/確認入力、登録ボタン
- 説明: 新規アカウント作成画面

### EmailVerificationPendingView (`lib/views/auth/email_verification_pending_view.dart`)
- 構成: 認証案内、注意事項、6桁コード入力、認証/再送ボタン
- 説明: メール認証コード入力・再送画面。認証成功後は `goToUserInfoAfterVerify` フラグに加えて Firestore `users/{uid}` のプロフィール入力状態を判定し、未入力項目がある場合は `UserInfoView`、入力済みなら `MainNavigationView` へ遷移

### UserInfoView (`lib/views/auth/user_info_view.dart`)
- 構成: ユーザー名入力（メール/Apple登録時のみ）、生年月日選択（年/月/日ドロップダウン）、性別選択（4択ドロップダウン）、送信ボタン
- 説明: 初回登録時のユーザー情報入力画面（簡略化済み：都道府県・市区町村・プロフィール画像は後からプロフィール編集で入力）。入力完了後は `TutorialView` を表示してから `MainNavigationView` に遷移

### AccountDeletionProcessingView (`lib/views/auth/account_deletion_views.dart`)
- 構成: 共通ヘッダー、進行中メッセージ、ローディング表示
- 説明: 退会処理中の進捗画面

### AccountDeletionCompleteView (`lib/views/auth/account_deletion_views.dart`)
- 構成: 完了アイコン、完了メッセージ、ログインへボタン
- 説明: 退会処理完了画面

## チュートリアル

### TutorialView (`lib/views/tutorial/tutorial_view.dart`)
- 構成: 全画面スライド4枚（PageView）、左上 × スキップボタン、下部ドットインジケーター（アクティブ時は横長・オレンジ）、右下 → 次へボタン（最終スライドは「はじめる」オレンジボタン）。スライド: ①地図発見 / ②スタンプ収集 / ③コイン獲得 / ④バッジコレクション。各スライドはイラスト画像（`assets/images/tutorial_1〜4.png`）＋タイトル（太字22px）＋説明文（14px）で構成。完了・スキップ時に Firestore `users/{uid}.showTutorial = false` を更新
- 説明: 新規登録後に初回のみ表示するオンボーディングチュートリアル画面。基本導線は `UserInfoView` 完了直後に `MaterialPageRoute`（fullscreenDialog）で表示し、保険として `MainNavigationView` 側でも `showTutorial == true` 時に表示可能。セッション内重複防止のための `static bool _tutorialShown` フラグあり

## ホーム・メインタブ

### HomeView (`lib/views/home_view.dart`)
- 構成: ログアウト時のみログイン/新規登録カード、統計カプセルバー（コイン・バッジ・スタンプの保有数を「おすすめ店舗」セクションの上に横並びで表示。白背景・丸角・左丸アイコン付きのコンパクトカプセルで「数値 + ラベル」を表示。値はFirestoreリアルタイム取得、コイン有効期限をカプセル下に表示、期限切れ時は赤文字）、`今日のレコメンド` セクション（見出しは「クーポン」「投稿」と同一サイズ。候補優先順は未訪問（スタンプ0）→開拓中（スタンプ1〜9）→達成済み（スタンプ10以上）のフォールバック。最大5件を取得し、1ページ1店舗の全幅カードで表示。3秒ごとに次ページへ自動送りし、ユーザー操作中は一時停止。カード上部は店舗画像、下部はコンパクト化したテキストで「未訪問 / スタンプ X/10 / 満了」の状態バッジ＋カテゴリ、店舗名、左下に「現在地から 距離」を表示。距離未取得時は `--` を表示。タップで店舗詳細へ遷移）、メニュー、スロットキャンペーンボタン（※廃止・コードはコメントアウトで保持）、ニュースセクション（掲載期間内・画像のみ1:1横スクロール・最大7件）、特別クーポンセクション（コイン交換で獲得した100円引きクーポンを黄色テーマの横スクロールカードで表示・1枚以上ある場合のみ表示・ヘッダーに枚数バッジ付き・タップでクーポン詳細へ遷移）、クーポン/投稿セクション（Instagram投稿と通常投稿を日付順で混合表示・最大10件・タイトル非表示・テキスト2行表示・Instagram投稿は「Instagram」バッジ（ピンク）、通常投稿は店舗ジャンルバッジ（オレンジ）を表示）、各詳細への導線、ミッションフローティングボタン（ログインユーザーのみ・右下・72x72の小型ボタン・受取可能ミッションがある場合は黄色系グラデーション・ない場合はグレーアウト表示・ミッション画面へ遷移・ミッション画面から戻った時に状態を再判定）
- 説明: 主要情報と、ユーザーのスタンプ進捗に応じたおすすめ店舗レコメンドを集約したダッシュボード

### MapView (`lib/views/map/map_view.dart`)
- 構成: GoogleMap（現在地青ドット表示あり・現在地ボタンはカスタム実装）、店舗マーカー、検索窓（左）＋フィルターボタン（右）、店舗情報パネル（マーカータップで表示。店舗名・今日の営業状況バッジ + 具体的な営業時間「営業中 09:00〜21:00」または「臨時休業」等を表示。scheduleOverrides・isRegularHoliday を考慮した正確な営業状況を表示。不定休（`isRegularHoliday=true`）で今日の scheduleOverride がない場合は「定休日」と表示）
- 説明: 周辺店舗を地図で探す画面。`isActive=true` かつ `isApproved=true` の店舗のみ表示し、`stores.isOwner=true` の店舗は表示しない。フィルターボタンから詳細フィルター設定画面へ遷移可能。「営業中のみ」フィルターは scheduleOverrides（臨時休業・臨時営業）および isRegularHoliday を考慮した判定を行う。マップ閲覧報酬（`mapOpened`）は `daily_missions/{date}.map_open` で1日1回のみカウントする

### FilterSettingsView (`lib/views/map/filter_settings_view.dart`)
- 構成: CommonHeader、各フィルターセクション（営業状況/ジャンル/開拓状態/お気に入り/決済方法/クーポン/距離）、リセット＋保存ボタン
- 説明: マップ表示のフィルター条件を設定する画面。設定はFirestore（users/{userId}/map_filter/settings）に保存

### PostsView (`lib/views/posts/posts_view.dart`)
- 構成: 投稿グリッド（3列）、空/エラー/読み込み状態（`public_instagram_posts` と `public_posts` の統一フィードを日付降順で取得し、画像なし投稿は除外・51件ずつボタン式追加読込・最大306件表示・1店舗あたり最大51件）、グリッド下部に青テキスト「さらに表示する」ボタン（追加データありの場合のみ表示）
- 説明: 投稿の一覧をグリッド形式で閲覧する画面

### PostDetailView (`lib/views/posts/post_detail_view.dart`)
- 構成: 画像カルーセル、店舗アイコン画像+店舗名+投稿日付、タイトル/本文、Instagram投稿時は本文下部に青テキスト「Instagramを開く」ボタン（タップで外部ブラウザ/Instagramアプリに遷移）、いいね、コメント一覧/入力
- 説明: 投稿の詳細表示・反応/コメント画面（店舗アイコンはFirestoreから取得、Instagram投稿の場合タイトルが店舗名と同一なら非表示、Instagram投稿・通常投稿の両方でいいね・コメント・閲覧記録に対応、Instagram投稿はpermalinkフィールドで元投稿にリンク）

### NewsDetailView (`lib/views/news/news_detail_view.dart`)
- 構成: CommonHeader、ニュース画像（1:1）、タイトル、掲載期間、本文
- 説明: ニュース詳細表示画面

### CouponsView (`lib/views/coupons/coupons_view.dart`)
- 構成: タブ（利用可能/使用済み）、クーポンリスト（共通 `CouponListCard` を使用、無制限クーポンの場合は残り枚数非表示）
- 説明: クーポン一覧（状態別）画面

### CouponDetailView (`lib/views/coupons/coupon_detail_view.dart`)
- 構成: ヘッダー画像、クーポン概要、期限/割引/必要スタンプ、残り枚数（無制限クーポンの場合は非表示）、店舗情報、注意事項、下部固定「使用する」ボタン（使用済み/期限切れ/スタンプ不足/配布終了時は無効化）
- 説明: クーポンの詳細表示・直接使用画面。確認ダイアログ後にFirestoreトランザクションでクーポン使用処理を実行

### StoreListView (`lib/views/stores/store_list_view.dart`)
- 構成: `CommonHeader` + 上部タブ（お気に入り/フォロー/店舗一覧）、店舗カードリスト
- 説明: 店舗の一覧・お気に入り・フォロー中店舗の表示。`isActive=true` かつ `isApproved=true` の店舗のみ表示し、`stores.isOwner=true` の店舗は表示しない。フォロータブはユーザーの `followedStoreIds` でフィルタ

### StoreDetailView (`lib/views/stores/store_detail_view.dart`)
- 構成: タブ表示（トップ/店内/メニュー/投稿）、お気に入り操作、店舗フォロー操作（通知ベルアイコン・フォロー中=青/未フォロー=グレー・来店時に自動フォロー）、共通スタンプカード（`StampCardWidget`・画像取得中はカード中心にインジケーター表示）、トップタブは店舗名/店舗アイコンと店舗説明を同一の白背景内に表示、クーポン一覧（利用可能のみ）と投稿プレビュー（新着15件・3列グリッド）を表示、投稿グリッド下部の「全て見る＞」ボタンで上部タブ「投稿」へ遷移、投稿タブはInstagram投稿と通常投稿を混合表示（動画除外・最大51件・日付降順）、利用可能な決済方法をカテゴリ別にChip表示（現金/カード/電子マネー/QR決済）、座席数セクション（テキスト直書き「、」区切り、データ未設定時は非表示）、設備・サービス情報セクション（アクセス情報・駐車場/テイクアウト/喫煙/Wi-Fi/バリアフリー/子連れ/ペットをChip表示（利用可能=オレンジ/不可=グレー色分け）、全項目常時表示）、メニュータブはPillTabBarでカテゴリ別フィルタ（コース/料理/ドリンク/デザート）・sortOrder順にリスト表示（画像あり時のみ左に60x60画像・メニュー名・右端に青太字価格）・メニューが無いカテゴリは非活性
- 営業ステータス判定: `scheduleOverrides[今日]` → `isRegularHoliday`（不定休=定休日） → `businessHours[曜日]` の優先順で判定。臨時休業/通常営業（不定休時）/臨時営業/時間変更のステータスチップ表示に対応
- 営業時間セクション: 今日〜6日後の7日間を `2/24(火)` 形式の日付付きで表示（scheduleOverrides優先。臨時休業は「臨時」赤バッジ、時間変更は「変更」青バッジを右端に表示。今日の行はオレンジハイライト + 「今日」バッジ）。不定休（`isRegularHoliday=true`）の場合: type='open' override がある日は「通常営業 HH:mm〜HH:mm」（緑・バッジなし）、それ以外は「定休日」を表示（「不定休です。営業日は各自ご確認ください。」メッセージは廃止）
- 今後14日以内にスケジュール変更がある場合は営業時間セクション上部に黄色バナーで一覧表示（臨時休業/通常営業（不定休時）/臨時営業/時間変更ごとにアイコン付き）
- 説明: 店舗の詳細情報と関連コンテンツを表示

### QRGeneratorView (`lib/views/qr/qr_generator_view.dart`)
- 構成: QRトークン表示（JWTベース・60秒自動更新・残り秒数カウントダウン）、ユーザーアイコン＋名前、QRコード文字列コピー
- 説明: 自分のQRコードを提示する画面。画面表示時に輝度をMAXに設定し、他画面への遷移時に元の輝度に復元

## 通知・お知らせ

### NotificationsView (`lib/views/notifications/notifications_view.dart`)
- 構成: お知らせと通知を統合した単一リスト（ListTile形式）、未読/既読表示、空/エラー状態
- 説明: お知らせと個別通知を日時順で統合表示する一覧画面

### AnnouncementDetailView (`lib/views/notifications/announcement_detail_view.dart`)
- 構成: カテゴリ/優先度バッジ、タイトル、公開日時、本文
- 説明: お知らせ詳細画面

### NotificationDetailView (`lib/views/notifications/notification_detail_view.dart`)
- 構成: 種別バッジ、日時、タイトル、本文、画像
- 説明: 通知詳細画面

## ポイント・支払い

### PointsView (`lib/views/points/points_view.dart`)
- 構成: タブ（全て/利用履歴/獲得履歴）、履歴リスト
- 説明: ポイント履歴の一覧画面

### TransactionHistoryView (`lib/views/points/transaction_history_view.dart`)
- 構成: 取引リスト、詳細ダイアログ、スタンプ受取導線
- 説明: 取引履歴を時系列で表示

### PointUsageView (`lib/views/points/point_usage_view.dart`)
- 構成: 残高カード、店舗ID/ポイント数/理由入力、実行ボタン
- 説明: 手動でポイント利用を申請する画面

### PointUsageRequestView (`lib/views/points/point_usage_request_view.dart`)
- 構成: 入力プロンプト、ポイント入力UI、確定/キャンセル
- 説明: 店舗利用ポイントを入力して申請する画面

### PointUsageWaitingView (`lib/views/points/point_usage_waiting_view.dart`)
- 構成: 状態表示、待機メッセージ
- 説明: 店舗側の入力完了を待つ画面

### PointUsageApprovalView (`lib/views/points/point_usage_approval_view.dart`)
- 構成: 利用ポイント確認、承認/拒否ボタン
- 説明: 店舗側入力後のユーザー承認画面

### PointPaymentView (`lib/views/payment/point_payment_view.dart`)
- 構成: 金額入力パッド、残高表示、支払い確認ダイアログ
- 説明: ポイント支払いを実行する画面

### PointRequestConfirmationView (`lib/views/payment/point_request_confirmation_view.dart`)
- 構成: 店舗/金額/ポイントの確認表示、承認待ち/キャンセル
- 説明: ポイント付与リクエストの確認画面

### PointPaymentDetailView (`lib/views/payment/point_payment_detail_view.dart`)
- 構成: 「スタンプ獲得」テキスト、共通スタンプカード（`StampCardWidget`・画像取得中はカード中心にインジケーター表示・押印アニメーション・コンプリートシャインエフェクト対応）、来店ボーナスバナー（+1コイン表示）、使用クーポン、未使用クーポンリスト、完了ボタン
- 説明: ポイント付与・スタンプ押印の結果表示画面。取引履歴からのスタンプ確認にも使用（スタンプカード下に来店ボーナス+1コインバナーを表示、その下に店舗の未使用クーポンをリスト表示）

### PaymentSuccessView (`lib/views/payment/payment_success_view.dart`)
- 構成: 成功メッセージ、店舗情報、支払い詳細、ホーム戻りボタン
- 説明: 支払い完了画面

## スタンプ・バッジ

### StampCardsView (`lib/views/stamps/stamp_cards_view.dart`)
- 構成: 共通スタンプカード（`StampCardWidget`）のリスト表示、空/エラー状態
- 説明: ユーザーのスタンプカード一覧。ホーム画面のスタンプ統計カプセルタップから遷移

### BadgeAwardedView (`lib/views/stamps/badge_awarded_view.dart`)
- 構成: バッジ獲得アニメーション、バッジ情報、次へボタン
- 説明: バッジ獲得の演出画面

### DailyRecommendationView (`lib/views/stamps/daily_recommendation_view.dart`)
- 構成: おすすめ店舗リスト（最大3件）、店舗カード（画像・アイコン・営業時間・説明・レコメンド理由タグ）、「詳細を見る」ボタン、「閉じる」ボタン
- 説明: その日初めてのアプリ起動時にホーム画面から自動表示されるおすすめ店舗画面（MainNavigationView initState → userDataListenerから発火）。スコアリングアルゴリズム（カテゴリ一致+2/エリア一致+1/未訪問+2/訪問済み−1/1km以内+3/3km以内+2/5km以内+1）で上位3件を選定。storesコレクションから最大50件取得（isActive=true, isApproved=true）。レコメンド理由タグ（近く/近距離/好み/未訪問/エリア）を店舗カードに表示。インプレッション・クリックをFirestoreに記録

### BadgesView (`lib/views/badges/badges_view.dart`)
- 構成: ヘッダー右上フィルター、バッジグリッド（内蔵データ全162種＋Firestoreで取得済み判定）、バッジ詳細ポップアップ（取得済み: 名前/カテゴリ/説明、未取得: 「？」アイコン/「？？？」名前/「条件を達成してバッジを獲得しよう！」）
- 説明: アプリ内蔵のバッジ定義（全162種、うちスロット関連8個は廃止・獲得不可）を全て一覧表示。Firestoreの `user_badges` から取得済みバッジを判定し、取得済みバッジは画像・名前を通常表示、未取得バッジは「？」アイコンと「？？？」で表示。ヘッダー右上フィルターでカテゴリ絞り込み可能

## ミッション

### MissionsView (`lib/views/missions/missions_view.dart`)
- 構成: AppBar、コイン残高表示（有効期限日付き・Firestore取得）、PillTabBar（デイリー/ログイン/新規登録/コイン交換の4タブ）、ミッションリスト（3状態: 未達成=グレイアウト / 達成済み未受取=黄色〜アンバーグラデーション背景・タップで報酬受取 / 受取済み=半透明の黄色グラデーション+チェックマーク）、コイン交換タブ（交換レート説明+未訪問店舗リスト+交換ボタン。未訪問店舗は `isActive=true` かつ `isApproved=true` かつ `stores.isOwner!=true` のみ表示）、新規登録ミッション未完了時はデイリー/ログインタブを非活性化（グレーアウト・タップ不可）し新規登録タブを初期選択、新規登録タブ上部にオレンジグラデーションのガイドメッセージバナー表示（「まずは新規登録ミッションを完了しよう!」）
- 説明: コイン獲得ミッションの一覧画面。Firestore連携でミッション達成状態をリアルタイム反映し、「受け取る」タップでコインをDBに加算。デイリーミッションは日付ベースで自動リセット。コイン交換タブでは10コインで未訪問店舗の100円引きクーポンを取得可能（有効期限30日、交換候補は `isActive=true` かつ `isApproved=true` かつ `stores.isOwner!=true` の未訪問店舗のみ）。新規登録ミッション（5種）をすべて受取完了するまでデイリー・ログインタブはロックされる。ホーム画面右下のフローティングボタンから遷移

## スロット（廃止）

### LotteryView (`lib/views/lottery/lottery_view.dart`)（廃止）
- 構成: ※スロット機能廃止に伴い利用停止。コードは保持
- 説明: スロット機能は廃止。ホーム画面からの導線も削除済み

## ランキング・フィードバック

### LeaderboardView (`lib/views/ranking/leaderboard_view.dart`)
- 構成: ランキング種別/期間フィルタ、ランキングリスト
- 説明: ユーザーランキングの表示画面

### FeedbackView (`lib/views/feedback/feedback_view.dart`)
- 構成: カテゴリ選択、件名/本文/メール入力、送信ボタン
- 説明: フィードバック送信画面

## 紹介

### FriendReferralView (`lib/views/referral/friend_referral_view.dart`)
- 構成: 紹介コード、紹介数/獲得ポイント、コピー/招待ボタン
- 説明: 友達紹介コードの確認と共有

### StoreReferralView (`lib/views/referral/store_referral_view.dart`)
- 構成: ヘッダー、紹介コード、手順/注意事項
- 説明: 店舗紹介コードの案内画面

## プロフィール・設定

### ProfileView (`lib/views/profile/profile_view.dart`)
- 構成: プロフィール表示、ユーザー統計カード（全店舗スタンプ進捗/開拓済み(スタンプ1〜9個)/スタンプ満了(スタンプ10個以上)・各ラベル下に条件テキストをグレー小文字で表示）、プロフィール完成度カード（2段階：基本プロフィール8項目未完成時は「プロフィールを完成させよう」カード表示、基本完成済み＆興味カテゴリ未設定時は「興味カテゴリを設定しよう」カード表示、全9項目完了で非表示）、設定リスト（店舗アプリ設定画面と同一のListTileスタイル：オレンジアイコン・タイトル+サブタイトル・chevron_right、セクション別白背景角丸16コンテナ。基本プロフィール完成後に「プロフィール編集」「興味カテゴリ設定」メニュー表示）、サポート/規約/退会などの導線、背景色 `Color(0xFFFBF6F2)`
- 説明: ユーザーアカウントのハブ画面。プロフィール完成度を2段階（基本プロフィール→興味カテゴリ）で段階的に促す

### ProfileEditView (`lib/views/settings/profile_edit_view.dart`)
- 構成: プロフィール編集フォーム（表示名、ユーザーID（@プレフィックス・英数字+アンダースコア・3〜20文字・ユニーク制約）、自己紹介（最大100文字・3行入力）、生年月日、性別、職業（8種ドロップダウン）、都道府県/市区町村、画像選択/アップロード）、保存ボタン
- 説明: プロフィール基本情報の編集画面（興味カテゴリは別画面に分離）。ユーザーIDは`usernames`コレクションで重複防止。Google/Appleユーザーは表示名と画像の編集不可

### InterestCategoryView (`lib/views/settings/interest_category_view.dart`)
- 構成: 説明テキスト、46カテゴリのチップ形式複数選択（選択時オレンジ色）、保存ボタン
- 説明: 興味カテゴリの設定画面。ProfileEditViewから分離された独立画面。保存時にプロフィール完成ミッション判定を実行

### UserIconCropView (`lib/views/settings/user_icon_crop_view.dart`)
- 構成: 画像プレビュー、切り抜き操作、保存ボタン
- 説明: アイコン画像のトリミング画面

### PasswordChangeView (`lib/views/settings/password_change_view.dart`)
- 構成: 現在/新規/確認パスワード入力、変更ボタン
- 説明: パスワード変更画面

### EmailChangeView (`lib/views/settings/email_change_view.dart`)
- 構成: 現在のメールアドレス表示（読み取り専用）、新しいメールアドレス入力、パスワード入力（再認証用）、認証コード送信ボタン
- 説明: メールアドレス変更画面。パスワード再認証後、新メールアドレスに6桁OTP認証コードを送信し、EmailChangeOtpViewに遷移

### EmailChangeOtpView (`lib/views/settings/email_change_otp_view.dart`)
- 構成: メールアイコン、説明文、6桁認証コード入力フィールド、認証ボタン、再送信ボタン
- 説明: メールアドレス変更用OTP認証画面。新メールアドレスに送信された6桁コードを入力し、Cloud FunctionsでFirebase AuthとFirestoreのメールアドレスを更新

### NotificationSettingsView (`lib/views/settings/notification_settings_view.dart`)
- 構成: プッシュ通知セクション（クーポン発行・投稿）、メール通知セクション（お知らせメール・ニュースレター・キャンペーン）のスイッチ一覧
- 説明: プッシュ通知・メール通知の受信設定を統合した画面

## サポート

### HelpView (`lib/views/support/help_view.dart`)
- 構成: FAQ、問い合わせ導線
- 説明: ヘルプ・サポートの入口画面

### ContactView (`lib/views/support/contact_view.dart`)
- 構成: 連絡先（電話/メール/住所）、タップで起動
- 説明: 連絡先一覧画面

### EmailSupportView (`lib/views/support/email_support_view.dart`)
- 構成: お問い合わせフォーム、カテゴリ選択、送信処理
- 説明: メールサポート申請画面

### PhoneSupportView (`lib/views/support/phone_support_view.dart`)
- 構成: 電話番号表示、営業時間、対応内容
- 説明: 電話サポート案内画面

### LiveChatView (`lib/views/support/live_chat_view.dart`)
- 構成: メッセージ一覧、入力欄、送信ボタン
- 説明: ライブチャットによるサポート画面

### PrivacyPolicyView (`lib/views/support/privacy_policy_view.dart`)
- 構成: サポート導線用ラッパー（表示本体は `lib/views/legal/privacy_policy_view.dart` を参照）
- 説明: サポート内のプライバシーポリシー導線画面（法務画面と表示内容を共通化）

### TermsOfServiceView (`lib/views/support/terms_of_service_view.dart`)
- 構成: サポート導線用ラッパー（表示本体は `lib/views/legal/terms_view.dart` を参照）
- 説明: サポート内の利用規約導線画面（法務画面と表示内容を共通化）

## 設定・情報

### AppInfoView (`lib/views/settings/app_info_view.dart`)
- 構成: アプリ情報（名前・バージョン・更新日）、開発者情報（会社名・代表者・設立日・所在地・サポートメール・電話・公式サイト）、ライセンス・法的事項（プライバシーポリシー・利用規約への遷移）、公式アカウント（公式サイト・メールサポートへの遷移）
- 説明: アプリのバージョン情報・開発者情報・法的リンクを表示する画面。ProfileViewのサポートセクションから遷移

## 法務

### TermsView (`lib/views/legal/terms_view.dart`)
- 構成: 利用規約本文（制定日/改定日、条文、事業者情報、問い合わせ先）
- 説明: アプリ内の利用規約画面（`/TERMS_OF_SERVICE.md` 準拠）

### PrivacyPolicyView (`lib/views/legal/privacy_policy_view.dart`)
- 構成: ポリシー本文（制定日/改定日、各章、事業者情報、問い合わせ先）
- 説明: アプリ内のプライバシーポリシー画面（`/PRIVACY_POLICY.md` 準拠）

---

# 階層図（画面構成の全体像）

```
アプリ起動
└─ スプラッシュスクリーン（ネイティブ・背景#FBF6F2+ロゴ中央表示）
   └─ AppUpdateGate
   └─ AuthWrapper
      ├─ 未ログイン（ゲスト）
      │  └─ WelcomeView
      │     ├─ ログインせずに開始
      │     │  └─ MainNavigationView
      │     │     ├─ ホーム（HomeView）
      │     │     ├─ マップ（MapView）
      │     │     └─ 投稿（PostsView）
      │     ├─ ログイン（SignInView）
      │     └─ 新規アカウント登録（TermsPrivacyConsentView）
      │
      └─ ログイン済み
         ├─ EmailVerificationPendingView（未認証時）
         │  ├─ UserInfoView（プロフィール未入力時）
         │  │  └─ TutorialView（showTutorial=true）
         │  │     └─ MainNavigationView
         │  └─ MainNavigationView（プロフィール入力済み）
         └─ MainNavigationView
            ├─ ホーム（HomeView）
            │  ├─ ニュース詳細（NewsDetailView）
            │  ├─ お知らせ（NotificationsView）
            │  │  ├─ お知らせ詳細（AnnouncementDetailView）
            │  │  └─ 通知詳細（NotificationDetailView）
            │  ├─ 店舗一覧（StoreListView）
            │  │  └─ 店舗詳細（StoreDetailView）
            │  ├─ クーポン一覧（CouponsView）
            │  │  └─ クーポン詳細（CouponDetailView）
            │  ├─ 投稿一覧（PostsView）
            │  │  └─ 投稿詳細（PostDetailView）
            │  ├─ スタンプカード（StampCardsView）
            │  ├─ バッジ一覧（BadgesView）
            │  ├─ ランキング（LeaderboardView）
            │  ├─ 友達紹介（FriendReferralView）
            │  ├─ 店舗紹介（StoreReferralView）
            │  ├─ ミッション（MissionsView）
            │  ├─ スロット（LotteryView）※廃止
            │  └─ フィードバック（FeedbackView）
            │
            ├─ マップ（MapView）
            │  ├─ フィルター設定（FilterSettingsView）
            │  └─ 店舗詳細（StoreDetailView）
            │
            ├─ QRコード（QRGeneratorView）※輝度MAX自動制御
            │  ├─ 支払い（PointPaymentView）
            │  │  └─ 支払い完了（PaymentSuccessView）
            │  ├─ ポイント付与確認（PointRequestConfirmationView）
            │  │  └─ 付与結果（PointPaymentDetailView）
            │  └─ ポイント利用承認（PointUsageApprovalView）
            │
            ├─ 投稿（PostsView）
            │  └─ 投稿詳細（PostDetailView）
            │
            └─ アカウント（ProfileView）
               ├─ プロフィール編集（ProfileEditView）
               │  └─ アイコン調整（UserIconCropView）
               ├─ 興味カテゴリ設定（InterestCategoryView）
               ├─ パスワード変更（PasswordChangeView）
               ├─ メールアドレス変更（EmailChangeView）
               │  └─ OTP認証（EmailChangeOtpView）
               ├─ 通知設定（NotificationSettingsView）
               ├─ 利用規約（TermsView）
               ├─ プライバシーポリシー（PrivacyPolicyView）
               ├─ ヘルプ・サポート（HelpView）
               │  ├─ メールサポート（EmailSupportView）
               │  ├─ 電話サポート（PhoneSupportView）
               │  ├─ ライブチャット（LiveChatView）
               │  ├─ 利用規約（TermsOfServiceView）
               │  └─ プライバシーポリシー（Support/PrivacyPolicyView）
               ├─ アプリについて（AppInfoView）
               │  ├─ プライバシーポリシー（Legal/PrivacyPolicyView）
               │  ├─ 利用規約（TermsView）
               │  └─ メールサポート（EmailSupportView）
               ├─ お問い合わせ（ContactView）
               └─ 退会
                  ├─ 退会処理中（AccountDeletionProcessingView）
                  └─ 退会完了（AccountDeletionCompleteView）

その他の単独遷移・演出系
├─ チュートリアル（TutorialView）→ 新規登録後の `UserInfoView` 完了直後に自動表示（showTutorial=true のユーザーのみ、保険でホーム遷移時にも表示可能）
├─ バッジ獲得（BadgeAwardedView）→ ホーム画面に戻る
├─ おすすめ店舗（DailyRecommendationView）→ その日初回ログイン時に自動表示
├─ ポイント利用入力（PointUsageRequestView）
│  └─ 店舗側入力待ち（PointUsageWaitingView）
└─ 取引履歴（TransactionHistoryView）
   └─ スタンプ確認（PointPaymentDetailView）

認証フロー（入り口）
├─ ウェルカム（WelcomeView）
├─ ログイン（SignInView）
├─ 規約同意（TermsPrivacyConsentView）
├─ 新規登録（SignUpView）
├─ メール認証（EmailVerificationPendingView）
└─ ユーザー情報入力（UserInfoView）
```
