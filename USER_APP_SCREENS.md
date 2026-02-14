# ユーザー用アプリ 画面一覧（構成と説明）

この一覧は `/Users/kanekohiroki/Desktop/groumapapp/lib/views` 配下の画面実装を基に整理しています。各画面の「構成」は主要なUI要素の概要、「説明」は用途の軽い要約です。
※ 2026-02-10更新: `StoreDetailView` のトップタブにクーポン一覧と投稿プレビュー（新着15件）を追加し、投稿の「全て見る＞」で上部タブ「投稿」へ遷移する導線を追加。`CouponsView` のクーポンリストカードUIを共通化し、`StoreListView` のヘッダーを `CommonHeader` + `CustomTopTabBar` 構成へ統一。
※ 2026-02-08更新: ユーザー用画面の遷移元差分を解消（`StoreListView` / `MapView` / `RecommendationAfterBadgeView` から `StoreDetailView` へ渡す店舗データを正規化）。

## 起動・ナビゲーション

### MainNavigationView (`lib/views/main_navigation_view.dart`)
- 構成: ボトムタブ（ホーム/マップ/投稿/プロフィール + ログイン時のみQR）、FAB（QR起動）
- 説明: アプリ全体のタブ切替と初期データ読込を担うメインナビゲーション

## 認証・登録

### WelcomeView (`lib/views/auth/welcome_view.dart`)
- 構成: ロゴ/サービス名、説明文、ログイン・新規作成ボタン、フッター
- 説明: 初回導入向けのウェルカム画面

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
- 説明: メール認証コード入力・再送画面

### UserInfoView (`lib/views/auth/user_info_view.dart`)
- 構成: 基本情報フォーム（名前/生年月日/性別/居住地）、プロフィール画像選択、送信ボタン
- 説明: 初回登録時のユーザー情報入力画面

### AccountDeletionProcessingView (`lib/views/auth/account_deletion_views.dart`)
- 構成: 共通ヘッダー、進行中メッセージ、ローディング表示
- 説明: 退会処理中の進捗画面

### AccountDeletionCompleteView (`lib/views/auth/account_deletion_views.dart`)
- 構成: 完了アイコン、完了メッセージ、ログインへボタン
- 説明: 退会処理完了画面

## ホーム・メインタブ

### HomeView (`lib/views/home_view.dart`)
- 構成: ログアウト時のみログイン/新規登録カード、現在地に近いおすすめ店舗カード（タイトル無し・タップで店舗詳細へ遷移）、メニュー、クーポン/投稿セクション（Instagram公開投稿）、各詳細への導線
- 説明: 主要情報と未訪問店舗のレコメンドを集約したダッシュボード

### MapView (`lib/views/map/map_view.dart`)
- 構成: GoogleMap、店舗マーカー、検索窓、店舗情報パネル
- 説明: 周辺店舗を地図で探す画面

### PostsView (`lib/views/posts/posts_view.dart`)
- 構成: 投稿グリッド（3列）、空/エラー/読み込み状態（`public_instagram_posts` から日付降順で取得し、50件ずつ追加読込・最大300件表示）
- 説明: 投稿の一覧をグリッド形式で閲覧する画面

### PostDetailView (`lib/views/posts/post_detail_view.dart`)
- 構成: 画像カルーセル、タイトル/本文、いいね、コメント一覧/入力
- 説明: 投稿の詳細表示・反応/コメント画面

### CouponsView (`lib/views/coupons/coupons_view.dart`)
- 構成: タブ（利用可能/使用済み）、クーポンリスト（共通 `CouponListCard` を使用）
- 説明: クーポン一覧（状態別）画面

### CouponDetailView (`lib/views/coupons/coupon_detail_view.dart`)
- 構成: ヘッダー画像、クーポン概要、期限/割引/必要スタンプ、店舗情報、注意事項
- 説明: クーポンの詳細表示画面

### StoreListView (`lib/views/stores/store_list_view.dart`)
- 構成: `CommonHeader` + 上部タブ（お気に入り/店舗一覧）、店舗カードリスト
- 説明: 店舗の一覧とお気に入り表示

### StoreDetailView (`lib/views/stores/store_detail_view.dart`)
- 構成: タブ表示（トップ/店内/メニュー/投稿）、お気に入り操作、スタンプ状況、トップタブは店舗名/店舗アイコンと店舗説明を同一の白背景内に表示、クーポン一覧（利用可能のみ）と投稿プレビュー（新着15件・3列グリッド）を表示、投稿グリッド下部の「全て見る＞」ボタンで上部タブ「投稿」へ遷移、投稿タブはInstagram投稿グリッド（動画除外・最新50件）、利用可能な決済方法をカテゴリ別にChip表示（現金/カード/電子マネー/QR決済）、メニュータブはPillTabBarでカテゴリ別フィルタ（コース/料理/ドリンク/デザート）・sortOrder順にリスト表示（画像あり時のみ左に60x60画像・メニュー名・右端に青太字価格）・メニューが無いカテゴリは非活性
- 説明: 店舗の詳細情報と関連コンテンツを表示

### QRGeneratorView (`lib/views/qr/qr_generator_view.dart`)
- 構成: タブ（QR表示/QR読み取り）、トークン表示、スキャナー、下部タブ
- 説明: 自分のQR提示と店舗QR読み取りを行う画面

## 通知・お知らせ

### NotificationsView (`lib/views/notifications/notifications_view.dart`)
- 構成: タブ（お知らせ/通知）、一覧表示、空/エラー状態
- 説明: お知らせと個別通知の一覧

### AnnouncementDetailView (`lib/views/notifications/announcement_detail_view.dart`)
- 構成: カテゴリ/優先度バッジ、タイトル、公開日時、本文
- 説明: お知らせ詳細画面

### NotificationDetailView (`lib/views/notifications/notification_detail_view.dart`)
- 構成: 種別バッジ、日時、タイトル、本文、画像、タグ
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
- 構成: 「スタンプ獲得」テキスト、店舗情報、スタンプ演出、使用クーポン、未使用クーポンリスト、完了ボタン
- 説明: ポイント付与・スタンプ押印の結果表示画面。取引履歴からのスタンプ確認にも使用（スタンプカード下に店舗の未使用クーポンをリスト表示）

### PaymentSuccessView (`lib/views/payment/payment_success_view.dart`)
- 構成: 成功メッセージ、店舗情報、支払い詳細、ホーム戻りボタン
- 説明: 支払い完了画面

## スタンプ・経験値・バッジ

### StampCardsView (`lib/views/stamps/stamp_cards_view.dart`)
- 構成: スタンプカード一覧、更新ボタン、空/エラー状態
- 説明: ユーザーのスタンプカード一覧

### ExperienceGainedView (`lib/views/stamps/experience_gained_view.dart`)
- 構成: 経験値/レベルアップ演出、内訳表示、継続ボタン
- 説明: 経験値獲得の演出画面

### BadgeAwardedView (`lib/views/stamps/badge_awarded_view.dart`)
- 構成: バッジ獲得アニメーション、バッジ情報、次へボタン
- 説明: バッジ獲得の演出画面

### RecommendationAfterBadgeView (`lib/views/stamps/recommendation_after_badge_view.dart`)
- 構成: おすすめ店舗リスト、店舗カード、遷移導線
- 説明: バッジ獲得後の店舗おすすめ画面

### BadgesView (`lib/views/badges/badges_view.dart`)
- 構成: カテゴリフィルタ、バッジグリッド、取得状態表示
- 説明: バッジ一覧と達成状況の確認画面

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
- 構成: プロフィール表示、ユーザー統計カード（全店舗スタンプ進捗/開拓済み/スタンプ満了）、設定/サポート/規約/退会などの導線
- 説明: ユーザーアカウントのハブ画面

### ProfileEditView (`lib/views/settings/profile_edit_view.dart`)
- 構成: プロフィール編集フォーム、画像選択/アップロード、保存ボタン
- 説明: プロフィール情報の編集画面

### UserIconCropView (`lib/views/settings/user_icon_crop_view.dart`)
- 構成: 画像プレビュー、切り抜き操作、保存ボタン
- 説明: アイコン画像のトリミング画面

### PasswordChangeView (`lib/views/settings/password_change_view.dart`)
- 構成: 現在/新規/確認パスワード入力、変更ボタン
- 説明: パスワード変更画面

### PushNotificationSettingsView (`lib/views/settings/push_notification_settings_view.dart`)
- 構成: 通知項目のスイッチ一覧
- 説明: プッシュ通知の受信設定画面

### EmailNotificationSettingsView (`lib/views/settings/email_notification_settings_view.dart`)
- 構成: メール通知のスイッチ一覧
- 説明: メール通知の受信設定画面

## サポート

### HelpView (`lib/views/support/help_view.dart`)
- 構成: FAQ、問い合わせ導線、アプリ情報セクション
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
- 構成: ポリシー概要、更新日、本文、問い合わせ案内
- 説明: サポート内のプライバシーポリシー画面

### TermsOfServiceView (`lib/views/support/terms_of_service_view.dart`)
- 構成: 規約概要、更新日、本文、問い合わせ案内
- 説明: サポート内の利用規約画面

## 法務

### TermsView (`lib/views/legal/terms_view.dart`)
- 構成: 利用規約本文、セクション見出し
- 説明: アプリ内の利用規約画面

### PrivacyPolicyView (`lib/views/legal/privacy_policy_view.dart`)
- 構成: プライバシーポリシー本文、セクション見出し
- 説明: アプリ内のプライバシーポリシー画面

---

# 階層図（画面構成の全体像）

```
アプリ起動
└─ AppUpdateGate
   └─ AuthWrapper
      ├─ 未ログイン（ゲスト）
      │  └─ MainNavigationView
      │     ├─ ホーム（HomeView）
      │     ├─ マップ（MapView）
      │     └─ 投稿（PostsView）
      │
      └─ ログイン済み
         ├─ EmailVerificationPendingView（未認証時）
         └─ MainNavigationView
            ├─ ホーム（HomeView）
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
            │  └─ フィードバック（FeedbackView）
            │
            ├─ マップ（MapView）
            │  └─ 店舗詳細（StoreDetailView）
            │
            ├─ QRコード（QRGeneratorView）
            │  ├─ QR表示（Tab）
            │  └─ QR読み取り（Tab）
            │     ├─ 支払い（PointPaymentView）
            │     │  └─ 支払い完了（PaymentSuccessView）
            │     ├─ ポイント付与確認（PointRequestConfirmationView）
            │     │  └─ 付与結果（PointPaymentDetailView）
            │     └─ ポイント利用承認（PointUsageApprovalView）
            │
            ├─ 投稿（PostsView）
            │  └─ 投稿詳細（PostDetailView）
            │
            └─ アカウント（ProfileView）
               ├─ プロフィール編集（ProfileEditView）
               │  └─ アイコン調整（UserIconCropView）
               ├─ パスワード変更（PasswordChangeView）
               ├─ プッシュ通知（PushNotificationSettingsView）
               ├─ メール通知（EmailNotificationSettingsView）
               ├─ 利用規約（TermsView）
               ├─ プライバシーポリシー（PrivacyPolicyView）
               ├─ ヘルプ・サポート（HelpView）
               │  ├─ メールサポート（EmailSupportView）
               │  ├─ 電話サポート（PhoneSupportView）
               │  ├─ ライブチャット（LiveChatView）
               │  ├─ 利用規約（TermsOfServiceView）
               │  └─ プライバシーポリシー（Support/PrivacyPolicyView）
               ├─ お問い合わせ（ContactView）
               └─ 退会
                  ├─ 退会処理中（AccountDeletionProcessingView）
                  └─ 退会完了（AccountDeletionCompleteView）

その他の単独遷移・演出系
├─ 体験値獲得（ExperienceGainedView）
├─ バッジ獲得（BadgeAwardedView）
│  └─ 獲得後おすすめ（RecommendationAfterBadgeView）
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
