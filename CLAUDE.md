# CLAUDE.md

## Language Preference

**重要**: このプロジェクトでは日本語で応答してください。ユーザーとのコミュニケーションは日本語で行い、コメントや説明も日本語で記述してください。

## Project Overview

「GrouMap」は、Firebase + Flutterで開発されるモバイルアプリケーション（iOS/Android対応）です。ユーザーアプリと店舗用アプリの2種類を提供し、地図を活用した店舗発見・ポイントシステム・クーポン機能を核とするプラットフォームアプリです。

### アプリの区分
- **ユーザー用アプリ**: 本リポジトリ（/Users/kanekohiroki/Desktop/groumapapp）
- **店舗用アプリ**: /Users/kanekohiroki/Desktop/groumapapp_store

### 主要な特徴
- **2つのアプリ種別**: ユーザーアプリと店舗用アプリ
- **統合バックエンド**: Firebase（Auth/Firestore/Functions/Storage/FCM）
- **リアルタイム地図連携**: Google Maps Integration
- **ポイント・スタンプシステム**: 来店促進機能
- **画像処理**: Firebase Storage + 圧縮処理
- **多階層権限管理**: 一般ユーザー・店舗オーナー・会社管理者

## Architecture

### システム構成
- **フロントエンド**: Flutter (Dart SDK ^3.5.0)
- **バックエンド**: Firebase Suite (Auth/Firestore/Functions/Storage/FCM)
- **地図サービス**: Google Maps Platform
- **タイムゾーン**: Asia/Tokyo

## Development Commands

### 開発コマンド
- **依存関係インストール**: `flutter pub get`
- **アプリ実行**: `flutter run`
- **コード解析**: `flutter analyze`
- **テスト実行**: `flutter test`
- **ビルド**: `flutter build apk` (Android) / `flutter build ios` (iOS)

## Code Style

`flutter_lints ^4.0.0` を使用し、Flutter推奨のコードスタイルに従います。

## 重要な注意事項

- Firebaseプロジェクト: groumapapp

## Firestore Rules

Firestoreのルールはユーザーアプリのリポジトリで管理します。ルールを更新する場合は
`/Users/kanekohiroki/Desktop/groumapapp/firestore.rules` を編集し、必要に応じてこのリポジトリからデプロイも実施してください。

## デバッグ時のターミナル実行方針

エラーが発生した場合、ターミナルでログ確認が可能ならあなたが実行して原因を確認し、修正まで対応してください。
gcloudのように権限が必要なコマンドでも、承認付きで実行して構いません。
ログインが必要な場合は私が先にログインするので、その後の実行はあなたが引き継いで進めてください。

## Firebase関連の変更

Firebase関連の設定変更は、このプロジェクト内のファイルを編集してください。
- `/Users/kanekohiroki/Desktop/groumapapp/firebase.json`
- `/Users/kanekohiroki/Desktop/groumapapp/firestore.indexes.json`

## UIコンポーネントの統一

以下のコンポーネントを統一して使用してください。
- **ヘッダー**: `/Users/kanekohiroki/Desktop/groumapapp/lib/widgets/common_header.dart`
- **ボタン**: `/Users/kanekohiroki/Desktop/groumapapp/lib/widgets/custom_button.dart`
- **テキストフィールド**: `/Users/kanekohiroki/Desktop/groumapapp/lib/widgets/error_dialog.dart`

## 画面背景の統一

- ホーム画面の背景色は `Colors.grey[50]` を基準とし、他の画面も同系統で統一すること

## 上部タブの統一

- 上部にタブを設置する場合は `/Users/kanekohiroki/Desktop/groumapapp/lib/widgets/custom_top_tab_bar.dart` を使用する
- デフォルトのオレンジは `#FF6B35`（`Color(0xFFFF6B35)`）
- 上部タブの配色はオレンジ背景（`#FF6B35`）+ 白テキストで統一する

## 通知・エラー表示ルール

- **成功時**: 緑のスナックバーで通知していた箇所は、何も表示しない
- **エラー時**: 赤のスナックバーは使用せず、デフォルトのダイアログで日本語のエラーメッセージを表示する

## アプリバージョン更新の依頼時

ユーザーから「アプリのバージョンを上げて」等の依頼が来た場合は、以下を実施すること（ヘルプページ表示は `+○○` のビルド番号を記載しない）。

- ユーザー用の `pubspec.yaml` のアプリバージョンを、最小桁数（`○.○.☆` の ☆）を1つ繰り上げ、ビルド番号（`+○○`）を1つ上げる
- 店舗用の `pubspec.yaml` のアプリバージョンを、最小桁数（`○.○.☆` の ☆）を1つ繰り上げ、ビルド番号（`+○○`）を1つ上げる
- ユーザー用の `pubspec.yaml` のバージョンを読み取り、`/Users/kanekohiroki/Desktop/groumapapp/lib/views/support/help_view.dart` の下部にあるバージョン表記を統一し、最終更新日を今日の日付にする（ビルド番号は除外）
- 店舗用の `pubspec.yaml` のバージョンを読み取り、`/Users/kanekohiroki/Desktop/groumapapp_store/lib/views/settings/help_support_view.dart` の下部にあるバージョン表記を統一し、最終更新日を今日の日付にする（ビルド番号は除外）

## GitHubコミット・プッシュ依頼時の実行ルール

ユーザーが「GitHubにコミットしてプッシュして」と依頼した場合は、以下の手順をこのまま実行すること。

- 現在のブランチをコミットしてプッシュする
- その後、`main` にマージして `main` へ push まで行う
- マージ後は元のブランチに戻す
- 元のブランチへ戻した時、そのブランチ名が今日の日付（`YYYY-mm-dd`）でない場合は、新しいブランチを `YYYY-mm-dd` 形式で作成して切り替える
- `.gitignore` に含まれているもの以外は全てコミットする
- コミットメッセージは任意でよい
- 店舗用・ユーザー用の両方に変更がある場合は、両方のリポジトリをコミットする
- どちらか一方のみの変更であれば、変更したリポジトリのみコミットする

## Firestore: コレクション一覧（abc順・コード参照ベース）

### badges
- `badges/{badgeId}`: バッジ定義
  - `name`: バッジ名
  - `description`: バッジ説明
  - `rarity`: レア度
  - `category`: 分類
  - `isActive`: 有効フラグ
  - `order`: 表示順
  - `requiredValue`: 条件の閾値
  - `imageUrl`: 画像URL
  - `condition`: 条件（typed/jsonlogic）
  - `conditionVersion`: 条件のバージョン
  - `createdBy`: 作成者UID
  - `createdAt`: 作成日時
  - `updatedAt`: 更新日時

### coupons
- `coupons/{storeId}/coupons/{couponId}`: 店舗別クーポン
  - `couponId`: クーポンID
  - `title`: タイトル
  - `description`: 説明
  - `storeId`: 店舗ID
  - `storeName`: 店舗名
  - `discountType`: 割引種別（割合/固定額/固定価格）
  - `discountValue`: 割引値
  - `validUntil`: 有効期限
  - `usageLimit`: 使用上限回数
  - `usedCount`: 使用済み回数
  - `viewCount`: 表示回数
  - `createdBy`: 作成者UID
  - `createdAt`: 作成日時
  - `updatedAt`: 更新日時
  - `isActive`: 有効フラグ
  - `imageUrl`: 画像URL
  - `usedBy/{userId}`: 使用済みユーザー履歴
    - `userId`: 使用者UID
    - `usedAt`: 使用日時
    - `couponId`: クーポンID
    - `storeId`: 店舗ID

### email_otp
- `email_otp/{uid}`: メール認証OTP
  - `codeHash`: 認証コードのハッシュ
  - `expiresAt`: 有効期限
  - `attempts`: 試行回数
  - `lastSentAt`: 最終送信日時
  - `updatedAt`: 更新日時

### feedback
- `feedback/{feedbackId}`: フィードバック
  - `userId`: 投稿者UID
  - `userName`: 投稿者名
  - `userEmail`: 返信先メール
  - `subject`: 件名
  - `message`: 本文
  - `category`: カテゴリ
  - `status`: 対応状況（pending/reviewed/resolved）
  - `createdAt`: 作成日時
  - `updatedAt`: 更新日時

### notifications
- `notifications/{notificationId}`: 全体お知らせ
  - `notificationId`: お知らせID
  - `title`: タイトル
  - `content`: 本文
  - `category`: カテゴリ
  - `priority`: 優先度
  - `createdBy`: 作成者UID
  - `createdAt`: 作成日時
  - `updatedAt`: 更新日時
  - `isActive`: 有効フラグ
  - `isPublished`: 公開フラグ
  - `scheduledDate`: 予約公開日時
  - `publishedAt`: 公開日時
  - `readCount`: 既読数
  - `totalViews`: 閲覧数
  - `tags`: タグ

### owner_settings
- `owner_settings/current`: オーナー設定
  - `basePointReturnRate`: 基本還元率
  - `levelPointReturnRateRanges`: レベル別還元率（`minLevel`, `maxLevel`, `rate`）
  - `campaignReturnRateBonus`: 還元率の上乗せ（キャンペーン）
  - `campaignReturnRateStartDate`: 還元率キャンペーン開始日
  - `campaignReturnRateEndDate`: 還元率キャンペーン終了日
  - `campaignReturnRateId`: 還元率キャンペーンID
  - `friendCampaignStartDate`: 友達紹介開始日
  - `friendCampaignEndDate`: 友達紹介終了日
  - `friendCampaignPoints`: 友達紹介付与ポイント
  - `storeCampaignStartDate`: 店舗紹介開始日
  - `storeCampaignEndDate`: 店舗紹介終了日
  - `storeCampaignPoints`: 店舗紹介付与ポイント
  - `maintenanceStartDate`: メンテナンス開始日
  - `maintenanceEndDate`: メンテナンス終了日
  - `maintenanceStartTime`: メンテ開始時刻
  - `maintenanceEndTime`: メンテ終了時刻
  - `minRequiredVersion`: 店舗アプリ必須バージョン
  - `latestVersion`: 店舗アプリ最新バージョン
  - `iosStoreUrl`: 店舗アプリApp Store URL
  - `androidStoreUrl`: 店舗アプリGoogle Play URL
  - `userMinRequiredVersion`: ユーザーアプリ必須バージョン
  - `userLatestVersion`: ユーザーアプリ最新バージョン
  - `userIosStoreUrl`: ユーザーApp Store URL
  - `userAndroidStoreUrl`: ユーザーGoogle Play URL
  - `createdAt`: 作成日時
  - `updatedAt`: 更新日時

### point_history
- `point_history/{historyId}`: 店舗側の手動付与履歴
  - `userId`: 対象ユーザーUID
  - `storeId`: 店舗ID
  - `points`: 付与ポイント
  - `type`: 種別（earned/spent/expired）
  - `reason`: 理由
  - `timestamp`: 発生日時
  - `createdAt`: 作成日時

### point_ledger
- `point_ledger/{ledgerId}`: 友達紹介ポイント台帳
  - `userId`: 付与対象UID
  - `amount`: 付与ポイント
  - `category`: ポイント種別
  - `reason`: 付与理由
  - `relatedUserId`: 関連ユーザーUID
  - `refId`: 関連ドキュメントID
  - `createdAt`: 作成日時

### point_requests
- `point_requests/{storeId}/{userId}/award_request`: 付与リクエスト
  - `status`: 状態（pending/accepted/rejected）
  - `requestType`: `award`
  - `pointsToAward`: 付与予定ポイント
  - `userPoints`: ユーザー付与ポイント
  - `baseRate`: 基本還元率（固定1.0）
  - `appliedRate`: 最終適用還元率
  - `normalPoints`: 通常ポイント
  - `specialPoints`: 特別ポイント
  - `totalPoints`: 付与合計ポイント
  - `rateCalculatedAt`: 還元率確定日時
  - `rateSource`: 還元率の適用元（level/campaign 等）
  - `campaignId`: 還元率キャンペーンID
  - `amount`: 会計金額
  - `storeId`: 店舗ID
  - `storeName`: 店舗名
  - `userId`: ユーザーID
  - `usedPoints`: 使用ポイント
  - `selectedCouponIds`: 使用クーポンID
  - `createdAt`: 作成日時
  - `respondedAt`: 応答日時
  - `respondedBy`: 応答者UID
  - `userNotified`: 通知済みフラグ
  - `userNotifiedAt`: 通知日時
- `point_requests/{storeId}/{userId}/usage_request`: 利用承認リクエスト
  - `status`: 状態（usage_pending_user_approval など）
  - `requestType`: `usage`
  - `usageApprovalNotified`: 通知済みフラグ
  - `usageApprovalNotifiedAt`: 通知日時
  - `usageExpiredAt`: 期限切れ日時

### point_transactions
- `point_transactions/{storeId}/{userId}/{transactionId}`: 店舗別ポイント取引
  - `transactionId`: 取引ID
  - `userId`: ユーザーUID
  - `storeId`: 店舗ID
  - `storeName`: 店舗名
  - `amount`: 付与/使用ポイント（使用はマイナス）
  - `paymentAmount`: 会計金額
  - `status`: ステータス
  - `paymentMethod`: 決済手段
  - `description`: 説明
  - `usedSpecialPoints`: 特別ポイント使用数
  - `usedNormalPoints`: 通常ポイント使用数
  - `totalUsedPoints`: 使用合計
  - `normalPointsAwarded`: 通常ポイント付与数
  - `specialPointsAwarded`: 特別ポイント付与数
  - `totalPointsAwarded`: 付与合計ポイント
  - `baseRate`: 基本還元率
  - `appliedRate`: 最終適用還元率
  - `rateSource`: 還元率の適用元（level/campaign 等）
  - `campaignId`: 還元率キャンペーンID
  - `createdAt`: 作成日時
  - `updatedAt`: 更新日時

### posts
- `posts/{storeId}/posts/{postId}`: 店舗投稿
  - `postId`: 投稿ID
  - `title`: タイトル
  - `content`: 本文
  - `storeId`: 店舗ID
  - `storeName`: 店舗名
  - `storeIconImageUrl`: 店舗アイコン
  - `category`: カテゴリ
  - `createdBy`: 作成者UID
  - `createdAt`: 作成日時
  - `updatedAt`: 更新日時
  - `isActive`: 有効フラグ
  - `isPublished`: 公開フラグ
  - `views`: 閲覧数
  - `viewCount`: 表示回数
  - `comments`: コメント配列
  - `imageUrls`: 画像URL配列
  - `imageCount`: 画像数

### public_coupons
- `public_coupons/{couponId}`: ユーザー向け公開クーポン
  - `key`: `storeId::couponId`
  - `couponId`: クーポンID
  - `storeId`: 店舗ID
  - `storeName`: 店舗名
  - `title`: タイトル
  - `description`: 説明
  - `discountType`: 割引種別
  - `discountValue`: 割引値
  - `validUntil`: 有効期限
  - `usageLimit`: 使用上限回数
  - `usedCount`: 使用済み回数
  - `viewCount`: 表示回数
  - `createdBy`: 作成者UID
  - `createdAt`: 作成日時
  - `updatedAt`: 更新日時
  - `isActive`: 有効フラグ
  - `imageUrl`: 画像URL

### public_posts
- `public_posts/{postId}`: ユーザー向け公開投稿
  - `key`: `storeId::postId`
  - `postId`: 投稿ID
  - `storeId`: 店舗ID
  - `storeName`: 店舗名
  - `storeIconImageUrl`: 店舗アイコン
  - `title`: タイトル
  - `content`: 本文
  - `category`: カテゴリ
  - `createdBy`: 作成者UID
  - `createdAt`: 作成日時
  - `updatedAt`: 更新日時
  - `isActive`: 有効フラグ
  - `isPublished`: 公開フラグ
  - `views`: 閲覧数
  - `viewCount`: 表示回数
  - `comments`: コメント配列
  - `imageUrls`: 画像URL配列
  - `imageCount`: 画像数

### sales
- `sales/{saleId}`: 売上記録（ポイント付与リクエスト作成時）
  - `storeId`: 店舗ID
  - `amount`: 会計金額
  - `requestId`: リクエストID
  - `source`: 記録元
  - `timestamp`: サーバー時刻
  - `createdAt`: 作成日時

### store_stats
- `store_stats/{storeId}/daily/{yyyy-mm-dd}`: 日別店舗集計
  - `date`: 日付キー
  - `pointsIssued`: 付与ポイント
  - `pointsUsed`: 使用ポイント
  - `totalPointsAwarded`: 付与合計
  - `specialPointsIssued`: 特別ポイント付与合計
  - `totalSales`: 売上合計
  - `totalTransactions`: 取引回数
  - `visitorCount`: 来店人数
  - `lastUpdated`: 更新日時

### store_users
- `store_users/{storeId}/users/{userId}`: 店舗来店ユーザー集計
  - `userId`: ユーザーUID
  - `storeId`: 店舗ID
  - `firstVisitAt`: 初回来店
  - `lastVisitAt`: 最終来店
  - `totalVisits`: 来店回数
  - `createdAt`: 作成日時
  - `updatedAt`: 更新日時

### stores
- `stores/{storeId}`: 店舗マスタ
  - `storeId`: 店舗ID
  - `name`: 店舗名
  - `category`: カテゴリ
  - `address`: 住所
  - `phone`: 電話番号
  - `description`: 店舗説明
  - `businessHours`: 営業時間（曜日ごとの `open/close/isOpen`）
  - `socialMedia`: SNSリンク（`instagram`, `x`, `facebook`, `website`）
  - `tags`: タグ
  - `location`: 位置（`latitude`, `longitude`）
  - `iconImageUrl`: アイコン画像
  - `storeImageUrl`: 店舗画像
  - `updatedAt`: 更新日時
  - `transactions/{transactionId}`: 店舗取引履歴
    - `type`: `award`/`use`
    - `points`: 付与/使用ポイント
    - `amountYen`: 会計金額
    - `paymentMethod`: 決済手段
    - `status`: ステータス
    - `source`: 記録元（`point_request`/`point_usage`）
    - `approvedBy`: 承認者UID
    - `usedSpecialPoints`: 特別ポイント使用数
    - `usedNormalPoints`: 通常ポイント使用数
    - `totalUsedPoints`: 使用合計
    - `createdAt`: 作成日時
    - `createdAtClient`: 端末時刻
  - `menu/{menuId}`: メニュー
    - `id`: メニューID
    - `name`: メニュー名
    - `description`: 説明
    - `price`: 価格
    - `category`: カテゴリ
    - `imageUrl`: 画像URL
    - `isAvailable`: 提供中フラグ
    - `sortOrder`: 並び順
    - `createdAt`: 作成日時
    - `updatedAt`: 更新日時

### user_achievement_events
- `user_achievement_events/{userId}/events/{eventId}`: 実績イベント
  - `type`: 種別（例: `point_award`）
  - `transactionId`: 取引ID
  - `storeId`: 店舗ID
  - `storeName`: 店舗名
  - `pointsAwarded`: 付与ポイント
  - `stampsAdded`: 追加スタンプ
  - `stampsAfter`: 付与後スタンプ
  - `cardCompleted`: カード完了フラグ
  - `xpAdded`: 追加XP
  - `xpBreakdown`: XP内訳（`points`, `stampPunch`, `cardComplete`）
  - `badges`: 付与バッジ配列
  - `createdAt`: 作成日時
  - `seenAt`: 既読日時

### user_badges
- `user_badges/{userId}/badges/{badgeId}`: ユーザー獲得バッジ
  - `userId`: ユーザーUID
  - `badgeId`: バッジID
  - `unlockedAt`: 獲得日時
  - `isNew`: 新規フラグ
  - `name`: バッジ名
  - `description`: 説明
  - `category`: カテゴリ
  - `imageUrl`: 画像URL
  - `iconUrl`: アイコンURL
  - `iconPath`: アイコンパス
  - `rarity`: レア度
  - `order`: 表示順
  - `progress`: 進捗
  - `requiredValue`: 閾値

### user_point_balances
- `user_point_balances/{userId}`: ユーザーのポイント残高
  - `userId`: ユーザーUID
  - `totalPoints`: 累計ポイント
  - `availablePoints`: 利用可能ポイント
  - `usedPoints`: 使用済みポイント
  - `lastUpdated`: 更新日時
  - `lastUpdatedByStoreId`: 更新した店舗ID

### users
- `users/{userId}`: ユーザープロフィール/状態
  - `uid`: ユーザーUID
  - `email`: メールアドレス
  - `displayName`: 表示名
  - `emailVerified`: メール認証フラグ
  - `emailVerifiedAt`: メール認証日時
  - `authProvider`: 認証プロバイダ
  - `isOwner`: オーナー判定
  - `isStoreOwner`: 店舗アカウント判定
  - `createdStores`: 作成店舗ID配列
  - `currentStoreId`: 選択中の店舗ID
  - `points`: 通常ポイント
  - `specialPoints`: 特別ポイント
  - `specialPointsTotal`: 特別ポイント累計
  - `totalPoints`: 総ポイント
  - `pointReturnRate`: 還元率
  - `paid`: 支払累計
  - `rank`: ランク
  - `currentLevel`: レベル（初期）
  - `level`: レベル（運用中）
  - `experience`: 経験値
  - `badgeCount`: 獲得バッジ数
  - `earnedBadges`: 獲得バッジID配列
  - `referralCode`: 友達紹介コード
  - `referralCount`: 招待数
  - `referralEarnings`: 紹介獲得ポイント
  - `referralEarningsPoints`: 紹介獲得ポイント合計
  - `referralUsed`: 紹介コード利用済み
  - `storeReferralCode`: 店舗紹介コード
  - `storeReferralCount`: 店舗紹介数
  - `storeReferralEarnings`: 店舗紹介獲得ポイント
  - `favoriteStoreIds`: お気に入り店舗ID配列
  - `fcmToken`: 端末FCMトークン
  - `fcmTokenUpdatedAt`: FCM更新日時
  - `profileImageUrl`: プロフィール画像
  - `friendReferralPopupShown`: 紹介通知表示済み
  - `friendReferralPopup`: 紹介通知データ
  - `friendReferralPopupReferrerShown`: 紹介者側通知表示済み
  - `friendReferralPopupReferrer`: 紹介者側通知データ
  - `createdAt`: 作成日時
  - `updatedAt`: 更新日時
  - `lastLoginAt`: 最終ログイン
  - `lastUpdated`: 最終更新（ランキング用）
  - `lastUpdatedByStoreId`: 更新店舗ID
  - `isActive`: 利用中フラグ
  - `showTutorial`: チュートリアル表示
  - `readNotifications`: 既読通知ID配列
  - `stores/{storeId}`: スタンプ/来店情報
    - `stamps`: スタンプ数
    - `lastVisited`: 最終来店
    - `totalSpending`: 累計支出
    - `updatedAt`: 更新日時
    - `storeId`: 店舗ID
    - `storeName`: 店舗名
  - `used_coupons/{couponId}`: 使用済みクーポン
    - `userId`: ユーザーUID
    - `usedAt`: 使用日時
    - `couponId`: クーポンID
    - `storeId`: 店舗ID
  - `liked_posts/{postId}`: いいね履歴
    - `postId`: 投稿ID
    - `postTitle`: 投稿タイトル
    - `storeId`: 店舗ID
    - `storeName`: 店舗名
    - `likedAt`: いいね日時
  - `favorite_stores/{storeId}`: お気に入り店舗
    - `storeId`: 店舗ID
    - `storeName`: 店舗名
    - `category`: カテゴリ
    - `storeImageUrl`: 店舗画像
    - `favoritedAt`: お気に入り日時
  - `comments/{commentId}`: コメント履歴
    - `commentId`: コメントID
    - `postId`: 投稿ID
    - `storeId`: 店舗ID
    - `postTitle`: 投稿タイトル
    - `content`: コメント内容
    - `createdAt`: 作成日時
  - `notifications/{notificationId}`: ユーザー通知
    - `id`: 通知ID
    - `title`: タイトル
    - `body`: 本文
    - `type`: 種別
    - `createdAt`: 作成日時
    - `isRead`: 既読フラグ
    - `isDelivered`: 配信済み
    - `data`: 付帯データ
    - `tags`: タグ
