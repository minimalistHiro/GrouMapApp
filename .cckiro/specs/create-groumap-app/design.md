# GrouMapアプリ 設計仕様書

## 1. システム全体設計

### 1.1 アーキテクチャ概要
```
[ユーザーアプリ] ←→ [Firebase] ←→ [店舗用アプリ]
       ↓                 ↓              ↓
  [Google Maps]    [Firestore]    [管理機能]
                   [Auth]
                   [Storage]
                   [Functions]
                   [FCM]
```

### 1.2 技術スタック
- **フロントエンド**: Flutter (Dart SDK ^3.5.0)
- **状態管理**: Riverpod
- **バックエンド**: Firebase Suite
- **地図サービス**: Google Maps Platform
- **コードスタイル**: flutter_lints ^4.0.0

## 2. データベース設計

### 2.1 Firestore コレクション構成

#### 2.1.1 users コレクション
```json
{
  "userId": "string",
  "email": "string",
  "displayName": "string",
  "userName": "string", // ユーザー名（一意）
  "photoURL": "string?",
  "authProvider": "apple|google|email", // 認証プロバイダー
  "profile": {
    "gender": "male|female|other|not_specified", // 性別
    "ageRange": "teens|twenties|thirties|forties|fifties|sixties_plus", // 年代
    "address": {
      "prefecture": "string", // 都道府県
      "city": "string" // 市区町村
    }
  },
  "level": "number (1-100)",
  "experience": "number",
  "totalPoints": "number",
  "availablePoints": "number",
  "badges": ["string"], // バッジIDの配列
  "favoriteStores": ["string"], // 店舗IDの配列
  "referralInfo": {
    "referralCode": "string", // 自分の紹介コード
    "referredBy": "string?", // 紹介者のユーザーID
    "referredUsers": ["string"] // 自分が紹介したユーザーIDの配列
  },
  "isActive": "boolean",
  "lastLoginAt": "timestamp",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

#### 2.1.2 stores コレクション
```json
{
  "storeId": "string",
  "name": "string",
  "description": "string",
  "address": "string",
  "location": {
    "latitude": "number",
    "longitude": "number"
  },
  "category": "string",
  "operatingHours": {
    "monday": {"open": "string", "close": "string"},
    "tuesday": {"open": "string", "close": "string"},
    // ... 他の曜日
  },
  "images": ["string"], // Storage URLの配列
  "ownerId": "string", // 店舗オーナーのUID
  "plan": "small|standard|premium", // プラン種別
  "isCompanyAdmin": "boolean",
  "companyInfo": {
    "companyId": "string?",
    "companyName": "string?",
    "subsidiaryStores": ["string"] // 会社管理者の場合の配下店舗ID
  },
  "monthlyPointsIssued": "number",
  "pointsLimit": "number", // プランによる上限
  "qrCode": "string", // 店頭QRコード用データ
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

#### 2.1.3 transactions コレクション
```json
{
  "transactionId": "string",
  "userId": "string",
  "storeId": "string",
  "type": "point_earn|point_use|coupon_use",
  "points": "number",
  "experience": "number", // 獲得経験値
  "qrData": "string", // QRコード取引データ
  "description": "string",
  "createdAt": "timestamp"
}
```

#### 2.1.4 point_usage_history コレクション
```json
{
  "usageId": "string",
  "userId": "string",
  "storeId": "string",
  "transactionId": "string", // 関連する取引ID
  "pointsUsed": "number", // 使用ポイント数
  "pointsBalance": "number", // 使用後のポイント残高
  "usageType": "purchase|discount|exchange", // 使用種別
  "itemDescription": "string", // 使用対象（商品名等）
  "originalAmount": "number", // 元の金額
  "discountAmount": "number", // 割引金額
  "finalAmount": "number", // 最終金額
  "qrData": "string", // QRコード取引データ
  "storeName": "string", // 店舗名（非正規化）
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

#### 2.1.5 coupon_usage_history コレクション
```json
{
  "usageId": "string",
  "userId": "string",
  "storeId": "string",
  "couponId": "string",
  "transactionId": "string", // 関連する取引ID
  "couponTitle": "string", // クーポンタイトル（非正規化）
  "couponType": "percentage|fixed|freeitem", // クーポン種別
  "discountValue": "number", // 割引値（%または固定額）
  "originalAmount": "number", // 元の金額
  "discountAmount": "number", // 実際の割引金額
  "finalAmount": "number", // 最終支払額
  "itemsUsed": ["string"], // 使用対象商品リスト
  "qrData": "string", // QRコード取引データ
  "storeName": "string", // 店舗名（非正規化）
  "usedAt": "timestamp", // 使用日時
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}

#### 2.1.6 referral_codes コレクション
```json
{
  "referralCodeId": "string", // 紹介コードID
  "userId": "string", // 紹介コード所有者のユーザーID
  "referralCode": "string", // 紹介コード（8桁英数字）
  "isActive": "boolean", // 有効フラグ
  "totalReferrals": "number", // 総紹介数
  "totalRewards": "number", // 総獲得報酬（ポイント等）
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}

#### 2.1.7 referral_relationships コレクション
```json
{
  "relationshipId": "string",
  "referrerId": "string", // 紹介者ユーザーID
  "referredUserId": "string", // 被紹介者ユーザーID
  "referralCode": "string", // 使用された紹介コード
  "referredAt": "timestamp", // 紹介成立日時
  "referrerReward": "number", // 紹介者への報酬（ポイント）
  "referredReward": "number", // 被紹介者への報酬（ポイント）
  "rewardGiven": "boolean", // 報酬付与済みフラグ
  "status": "pending|completed|cancelled", // 紹介ステータス
  "referrerName": "string", // 紹介者名（非正規化）
  "referredName": "string", // 被紹介者名（非正規化）
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}

#### 2.1.8 store_referral_codes コレクション
```json
{
  "storeReferralCodeId": "string", // 店舗紹介コードID
  "storeId": "string", // 紹介コード所有者の店舗ID
  "referralCode": "string", // 店舗紹介コード（8桁英数字）
  "isActive": "boolean", // 有効フラグ
  "totalReferrals": "number", // 総紹介数
  "totalApprovedReferrals": "number", // 承認済み紹介数
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}

#### 2.1.9 store_referral_relationships コレクション
```json
{
  "storeRelationshipId": "string",
  "referrerStoreId": "string", // 紹介者店舗ID
  "referredStoreId": "string", // 被紹介者店舗ID
  "referralCode": "string", // 使用された紹介コード
  "referredAt": "timestamp", // 紹介申請日時
  "approvedAt": "timestamp", // 承認日時
  "approvedBy": "string", // 承認者（会社管理者）ID
  "status": "pending|approved|rejected", // 紹介ステータス
  "referrerStoreName": "string", // 紹介者店舗名（非正規化）
  "referredStoreName": "string", // 被紹介者店舗名（非正規化）
  "companyId": "string", // 承認を行う会社ID
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}

#### 2.1.10 user_feedback コレクション
```json
{
  "feedbackId": "string", // フィードバックID
  "userId": "string", // 送信者ユーザーID
  "userName": "string", // 送信者ユーザー名（非正規化）
  "userEmail": "string", // 送信者メールアドレス（非正規化）
  "companyId": "string", // 送信先会社ID
  "category": "bug_report|feature_request|general_inquiry|complaint|compliment", // フィードバックカテゴリ
  "subject": "string", // 件名
  "message": "string", // メッセージ本文
  "priority": "low|medium|high", // 優先度
  "status": "unread|read|in_progress|resolved", // 処理ステータス
  "attachmentUrls": ["string"], // 添付ファイルURL（任意）
  "isRead": "boolean", // 既読フラグ
  "readAt": "timestamp", // 既読日時
  "readBy": "string", // 既読者ID
  "response": "string", // 返信内容（任意）
  "respondedAt": "timestamp", // 返信日時（任意）
  "respondedBy": "string", // 返信者ID（任意）
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}

#### 2.1.11 company_mail_settings コレクション
```json
{
  "companyId": "string", // 会社ID
  "emailNotifications": "boolean", // メール通知有効/無効
  "autoReplyEnabled": "boolean", // 自動返信有効/無効
  "autoReplyMessage": "string", // 自動返信メッセージ
  "feedbackCategories": ["string"], // 受け付けるフィードバックカテゴリ
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

#### 2.1.6 badges コレクション
```json
{
  "badgeId": "string",
  "name": "string",
  "description": "string",
  "iconUrl": "string",
  "experienceReward": "number",
  "conditions": {
    "type": "first_visit|consecutive_visits|points_total|store_conquest",
    "target": "number",
    "storeIds": ["string"] // 対象店舗（必要な場合）
  },
  "createdAt": "timestamp"
}
```

#### 2.1.7 user_badges コレクション
```json
{
  "id": "string",
  "userId": "string",
  "badgeId": "string",
  "progress": "number",
  "isCompleted": "boolean",
  "completedAt": "timestamp?",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

#### 2.1.8 announcements コレクション
```json
{
  "announcementId": "string",
  "companyId": "string", // 発行会社ID
  "title": "string",
  "content": "string",
  "targetAudience": "stores|users|both", // 対象: 店舗向け|ユーザー向け|両方向け
  "priority": "low|medium|high", // 優先度
  "imageUrl": "string?", // 画像URL（オプション）
  "isPublished": "boolean",
  "publishedAt": "timestamp?",
  "expiresAt": "timestamp?", // 有効期限
  "createdBy": "string", // 作成者UID
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

#### 2.1.9 announcement_reads コレクション
```json
{
  "id": "string",
  "announcementId": "string",
  "userId": "string", // または storeId
  "userType": "user|store", // ユーザー種別
  "readAt": "timestamp",
  "createdAt": "timestamp"
}
```

#### 2.1.10 coupons コレクション
```json
{
  "couponId": "string",
  "storeId": "string",
  "title": "string",
  "description": "string",
  "discount": {
    "type": "percentage|fixed",
    "value": "number"
  },
  "validFrom": "timestamp",
  "validTo": "timestamp",
  "usageLimit": "number",
  "usedCount": "number",
  "createdAt": "timestamp"
}
```

### 2.2 Firebase Security Rules

#### 2.2.1 基本セキュリティ設計
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // ユーザーデータ - 本人のみアクセス可能
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // 店舗データ - 読み取りは認証ユーザー、書き込みは店舗オーナーまたは会社管理者
    match /stores/{storeId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        (resource.data.ownerId == request.auth.uid || 
         resource.data.isCompanyAdmin == true);
    }
    
    // 取引データ - 関係者のみアクセス可能
    match /transactions/{transactionId} {
      allow read, write: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         isStoreOwner(resource.data.storeId));
    }
    
    // ポイント利用履歴 - ユーザー本人と関連店舗のみアクセス可能
    match /point_usage_history/{usageId} {
      allow read, write: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         isStoreOwner(resource.data.storeId));
    }
    
    // クーポン利用履歴 - ユーザー本人と関連店舗のみアクセス可能
    match /coupon_usage_history/{usageId} {
      allow read, write: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         isStoreOwner(resource.data.storeId));
    }
    
    // お知らせデータ - 対象者のみ読み取り可能、会社管理者のみ書き込み可能
    match /announcements/{announcementId} {
      allow read: if request.auth != null && isTargetAudience(resource.data);
      allow write: if request.auth != null && isCompanyAdmin(request.auth.uid);
    }
    
    // お知らせ既読データ - 本人のみアクセス可能
    match /announcement_reads/{readId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
  }
}
```

## 3. アプリケーション設計

### 3.1 プロジェクト構成
```
lib/
├── main.dart                          # エントリポイント
├── core/                              # 共通コア機能
│   ├── constants/                     # 定数定義
│   │   ├── app_colors.dart           # ブランドカラー #E75B41
│   │   ├── app_strings.dart          # 文字列定数
│   │   └── firebase_constants.dart   # Firebase設定
│   ├── errors/                       # エラーハンドリング
│   ├── utils/                        # ユーティリティ
│   └── widgets/                      # 共通ウィジェット
├── models/                           # データモデル
│   ├── user_model.dart
│   ├── store_model.dart
│   ├── transaction_model.dart
│   ├── point_usage_history_model.dart
│   ├── coupon_usage_history_model.dart
│   ├── referral_code_model.dart
│   ├── referral_relationship_model.dart
│   ├── store_referral_code_model.dart
│   ├── store_referral_relationship_model.dart
│   ├── badge_model.dart
│   ├── coupon_model.dart
│   ├── announcement_model.dart
│   └── announcement_read_model.dart
├── repositories/                     # データアクセス層
│   ├── user_repository.dart
│   ├── store_repository.dart
│   ├── transaction_repository.dart
│   ├── point_usage_repository.dart
│   ├── coupon_usage_repository.dart
│   ├── badge_repository.dart
│   └── announcement_repository.dart
├── services/                         # サービス層
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   ├── storage_service.dart
│   ├── maps_service.dart
│   ├── qr_service.dart
│   ├── level_service.dart
│   └── announcement_service.dart
├── providers/                        # Riverpod状態管理
│   ├── auth_provider.dart
│   ├── user_provider.dart
│   ├── stores_provider.dart
│   ├── level_provider.dart
│   ├── badges_provider.dart
│   ├── point_usage_provider.dart
│   ├── coupon_usage_provider.dart
│   └── announcements_provider.dart
├── views/                           # UI画面
│   ├── auth/                        # 認証画面
│   │   ├── login_page.dart         # ログイン画面
│   │   ├── signup_page.dart        # アカウント作成画面
│   │   └── profile_setup_page.dart # プロフィール設定画面
│   ├── home/                        # ホーム画面
│   ├── map/                         # マップ画面
│   ├── post/                        # 投稿画面
│   ├── account/                     # アカウント画面
│   ├── qr/                          # QRコード画面
│   └── announcements/               # お知らせ画面
└── widgets/                         # 再利用可能ウィジェット
    ├── bottom_navigation.dart       # ボトムナビゲーション
    ├── qr_floating_button.dart      # QRフローティングボタン
    ├── custom_map_pin.dart          # カスタムマップピン
    ├── level_progress_bar.dart      # レベル進捗バー
    └── announcement_card.dart       # お知らせカード
```

### 3.2 状態管理設計（Riverpod）

#### 3.2.1 認証プロバイダー
```dart
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});

final currentUserProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges();
});
```

#### 3.2.2 ユーザープロバイダー
```dart
final userProvider = StreamProvider.family<UserModel?, String>((ref, userId) {
  return ref.watch(userRepositoryProvider).getUserStream(userId);
});

final userLevelProvider = Provider.family<int, UserModel?>((ref, user) {
  return user?.level ?? 1;
});
```

#### 3.2.3 店舗プロバイダー
```dart
final nearbyStoresProvider = FutureProvider.family<List<StoreModel>, Location>((ref, location) {
  return ref.watch(storeRepositoryProvider).getNearbyStores(location);
});

final storeDetailsProvider = StreamProvider.family<StoreModel?, String>((ref, storeId) {
  return ref.watch(storeRepositoryProvider).getStoreStream(storeId);
});
```

#### 3.2.4 お知らせプロバイダー
```dart
final announcementsProvider = StreamProvider.family<List<AnnouncementModel>, String>((ref, targetAudience) {
  return ref.watch(announcementRepositoryProvider).getAnnouncementsStream(targetAudience);
});

final unreadAnnouncementsCountProvider = FutureProvider.family<int, String>((ref, userId) {
  return ref.watch(announcementRepositoryProvider).getUnreadCount(userId);
});
```

#### 3.2.5 履歴プロバイダー
```dart
final pointUsageHistoryProvider = StreamProvider.family<List<PointUsageHistoryModel>, String>((ref, userId) {
  return ref.watch(pointUsageRepositoryProvider).getUserPointUsageHistory(userId);
});

final couponUsageHistoryProvider = StreamProvider.family<List<CouponUsageHistoryModel>, String>((ref, userId) {
  return ref.watch(couponUsageRepositoryProvider).getUserCouponUsageHistory(userId);
});

final monthlyPointUsageProvider = FutureProvider.family<Map<String, double>, String>((ref, userId) {
  return ref.watch(pointUsageRepositoryProvider).getMonthlyUsageStats(userId);
});
```

## 4. UI/UX 設計

### 4.1 デザインシステム

#### 4.1.1 カラーパレット
```dart
class AppColors {
  static const Color primary = Color(0xFFE75B41);      // メインカラー
  static const Color primaryLight = Color(0xFFFF8A65);  // ライト
  static const Color primaryDark = Color(0xFFBF360C);   // ダーク
  static const Color accent = Color(0xFF4CAF50);        // アクセント
  static const Color background = Color(0xFFF5F5F5);    // 背景
  static const Color surface = Color(0xFFFFFFFF);       // サーフェス
  static const Color text = Color(0xFF212121);          // テキスト
  static const Color textSecondary = Color(0xFF757575); // セカンダリテキスト
}
```

#### 4.1.2 テーマ設定
```dart
final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarTheme(
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.textSecondary,
  ),
);
```

### 4.2 画面設計

#### 4.2.1 ユーザーアプリ ホーム画面設計
```dart
class UserHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ヘッダー部分
              _buildHeader(),
              
              // メンテナンスバー
              _buildMaintenanceBar(),
              
              // ユーザーカード（ポイント・レベル・ゲージ）
              _buildUserCard(),
              
              // イベントガチャボタン（条件揃った場合のみ）
              _buildEventGachaButton(),
              
              // 4*2メニュー
              _buildMenuGrid(),
              
              // クーポンセクション
              _buildCouponsSection(),
              
              // 投稿セクション
              _buildPostsSection(),
            ],
          ),
        ),
      ),
    );
  }
  
  // ヘッダー: アイコン、サービス名、お知らせベル
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 左上アイコン
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          
          // サービス名
          const Expanded(
            child: Text(
              'GrouMap',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
          ),
          
          // お知らせベル
          Consumer(
            builder: (context, ref, child) {
              final unreadCount = ref.watch(unreadAnnouncementsCountProvider('userId'));
              return Stack(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pushNamed(context, '/announcements'),
                    icon: const Icon(Icons.notifications, size: 28),
                    color: AppColors.text,
                  ),
                  if (unreadCount.asData?.value != null && unreadCount.asData!.value! > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${unreadCount.asData!.value}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
  
  // メンテナンスバー
  Widget _buildMaintenanceBar() {
    return Consumer(
      builder: (context, ref, child) {
        // メンテナンス情報があれば表示
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            border: Border.all(color: Colors.orange),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: const [
              Icon(Icons.info_outline, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'システムメンテナンス: 2025/09/15 02:00-05:00',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // ユーザーカード（ポイント・レベル・ゲージ）
  Widget _buildUserCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Consumer(
        builder: (context, ref, child) {
          final user = ref.watch(currentUserProvider);
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '保有ポイント',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        '${user?.availablePoints ?? 0} P',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'レベル',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        'Lv.${user?.level ?? 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // レベルゲージ
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '次のレベルまで',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        '${_getExpToNextLevel(user?.experience ?? 0, user?.level ?? 1)} exp',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: _getLevelProgress(user?.experience ?? 0, user?.level ?? 1),
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
  
  // イベントガチャボタン（条件が揃った場合のみ表示）
  Widget _buildEventGachaButton() {
    return Consumer(
      builder: (context, ref, child) {
        final canPlayGacha = ref.watch(gachaAvailableProvider);
        
        if (!canPlayGacha) return const SizedBox.shrink();
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/event-gacha'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.casino, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  '✨ イベントガチャ開催中！',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // 4*2のメニューグリッド
  Widget _buildMenuGrid() {
    final menuItems = [
      // 上段4つ
      _MenuItem(icon: Icons.history, label: 'ポイント履歴', route: '/point-history'),
      _MenuItem(icon: Icons.stars, label: 'スタンプ', route: '/stamps'),
      _MenuItem(icon: Icons.emoji_events, label: 'バッジ', route: '/badges'),
      _MenuItem(icon: Icons.store, label: '店舗一覧', route: '/stores'),
      // 下段4つ
      _MenuItem(icon: Icons.leaderboard, label: 'ランキング', route: '/ranking'),
      _MenuItem(icon: Icons.person_add, label: '友達紹介', route: '/friend-invite'),
      _MenuItem(icon: Icons.campaign, label: '店舗紹介', route: '/store-intro'),
      _MenuItem(icon: Icons.feedback, label: 'フィードバック', route: '/feedback'),
    ];
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final item = menuItems[index];
          return InkWell(
            onTap: () => Navigator.pushNamed(context, item.route),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, size: 28, color: AppColors.primary),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: const TextStyle(fontSize: 12, color: AppColors.text),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  // クーポンセクション（横スライド、有効期限が近い順）
  Widget _buildCouponsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'クーポン',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/coupons'),
                child: const Text('すべて見る'),
              ),
            ],
          ),
        ),
        Consumer(
          builder: (context, ref, child) {
            final coupons = ref.watch(nearExpiryCouponsProvider);
            return SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 4, // 最大4つまで表示
                itemBuilder: (context, index) {
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade400, Colors.red.shade600],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '30%OFF',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '全商品対象',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Spacer(),
                          Text(
                            '有効期限: 2025/09/30',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
  
  // 投稿セクション（横スライド、投稿新規順）
  Widget _buildPostsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'みんなの投稿',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/posts'),
                child: const Text('すべて見る'),
              ),
            ],
          ),
        ),
        Consumer(
          builder: (context, ref, child) {
            final posts = ref.watch(recentPostsProvider);
            return SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 4, // 最大4つまで表示
                itemBuilder: (context, index) {
                  return Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // 投稿画像
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            color: Colors.grey.shade300,
                          ),
                          child: const Center(
                            child: Icon(Icons.image, size: 32, color: Colors.grey),
                          ),
                        ),
                        // 投稿内容
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                '美味しいランチでした！',
                                style: TextStyle(fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Text(
                                '2時間前',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
  
  // ヘルパーメソッド
  double _getLevelProgress(int experience, int level) {
    final currentLevelExp = LevelService.getRequiredExperience(level);
    final nextLevelExp = LevelService.getRequiredExperience(level + 1);
    final progressExp = experience - currentLevelExp;
    final requiredExp = nextLevelExp - currentLevelExp;
    return progressExp / requiredExp;
  }
  
  int _getExpToNextLevel(int experience, int level) {
    final nextLevelExp = LevelService.getRequiredExperience(level + 1);
    return nextLevelExp - experience;
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String route;
  
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
```

#### 4.2.2 店舗用アプリ ホーム画面設計
```dart
class StoreHomeView extends ConsumerStatefulWidget {
  @override
  ConsumerState<StoreHomeView> createState() => _StoreHomeViewState();
}

class _StoreHomeViewState extends ConsumerState<StoreHomeView> {
  @override
  Widget build(BuildContext context) {
    final currentStore = ref.watch(currentStoreProvider);
    final todayStats = ref.watch(todayStatsProvider);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              _buildStoreHeader(currentStore),
              
              // 今日の統計
              _buildTodayStats(todayStats),
              
              // 4×3メニューグリッド
              _buildStoreMenuGrid(),
              
              // 最近のアクティビティ
              _buildRecentActivity(),
            ],
          ),
        ),
      ),
    );
  }
  
  // 店舗ヘッダー
  Widget _buildStoreHeader(AsyncValue<StoreModel?> storeAsync) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: storeAsync.when(
        data: (store) {
          if (store == null) return const SizedBox();
          return Row(
            children: [
              // 店舗アイコン
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: store.iconUrl != null 
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: CachedNetworkImage(
                          imageUrl: store.iconUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Icon(
                            _getStoreIcon(store.category),
                            size: 30,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : Icon(
                        _getStoreIcon(store.category),
                        size: 30,
                        color: AppColors.primary,
                      ),
              ),
              const SizedBox(width: 16),
              
              // 店舗情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      store.category,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              
              // お知らせアイコン
              Consumer(
                builder: (context, ref, child) {
                  final unreadCount = ref.watch(unreadAnnouncementsCountProvider(store.storeId));
                  return Stack(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pushNamed(context, '/announcements'),
                        icon: const Icon(Icons.notifications, color: Colors.white),
                      ),
                      if (unreadCount.value != null && unreadCount.value! > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${unreadCount.value}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        },
        loading: () => const CircularProgressIndicator(color: Colors.white),
        error: (error, _) => Text('エラー: $error', style: const TextStyle(color: Colors.white)),
      ),
    );
  }
  
  // 今日の統計
  Widget _buildTodayStats(AsyncValue<TodayStatsModel> statsAsync) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '今日の実績',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          
          statsAsync.when(
            data: (stats) => Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.group,
                    label: '来店者数',
                    value: '${stats.todayVisitors}人',
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.stars,
                    label: 'ポイント発行',
                    value: '${stats.todayPointsIssued}P',
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.local_offer,
                    label: 'クーポン利用',
                    value: '${stats.todayCouponsUsed}回',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('統計の取得に失敗しました: $error'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
  
  // 4×3メニューグリッド
  Widget _buildStoreMenuGrid() {
    // ベースメニューアイテム
    List<_StoreMenuItem> menuItems = [
      // 1行目
      _StoreMenuItem(icon: Icons.point_of_sale, label: 'ポイント発行履歴', route: '/point-issue-history'),
      _StoreMenuItem(icon: Icons.receipt, label: 'ポイント利用履歴', route: '/point-usage-history'),
      _StoreMenuItem(icon: Icons.local_offer, label: 'クーポン管理', route: '/coupon-management'),
      _StoreMenuItem(icon: Icons.post_add, label: '投稿管理', route: '/post-management'),
      // 2行目  
      _StoreMenuItem(icon: Icons.analytics, label: '顧客分析', route: '/customer-analytics'),
      _StoreMenuItem(icon: Icons.show_chart, label: '売上データ', route: '/sales-data'),
      _StoreMenuItem(icon: Icons.group, label: 'スタッフ管理', route: '/staff-management'),
      _StoreMenuItem(icon: Icons.credit_card, label: 'プラン・契約情報', route: '/plan-contract'),
      // 3行目
      _StoreMenuItem(icon: Icons.announcement, label: '運営からのお知らせ', route: '/admin-announcements'),
      _StoreMenuItem(icon: Icons.feedback, label: 'フィードバック送信', route: '/feedback'),
    ];
    
    // 会社管理者の場合は「メール」ボタンを追加し、空きを1つに
    final isCompanyAdmin = ref.watch(currentStoreProvider)?.value?.isCompanyAdmin ?? false;
    
    if (isCompanyAdmin) {
      menuItems.add(_StoreMenuItem(icon: Icons.mail, label: 'メール', route: '/company-mail'));
      menuItems.add(_StoreMenuItem(icon: Icons.add, label: '', route: '', isEmpty: true)); // 空き（1つ）
    } else {
      // 通常の店舗オーナーの場合は空きを2つ
      menuItems.add(_StoreMenuItem(icon: Icons.add, label: '', route: '', isEmpty: true)); // 空き
      menuItems.add(_StoreMenuItem(icon: Icons.add, label: '', route: '', isEmpty: true)); // 空き
    }
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.85,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final item = menuItems[index];
          if (item.isEmpty) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2), style: BorderStyle.solid),
              ),
            );
          }
          
          return InkWell(
            onTap: () => Navigator.pushNamed(context, item.route),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    size: 28,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.text,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  // 最近のアクティビティ
  Widget _buildRecentActivity() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '最近のアクティビティ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          
          Consumer(
            builder: (context, ref, child) {
              final recentActivities = ref.watch(recentActivitiesProvider);
              
              return recentActivities.when(
                data: (activities) {
                  if (activities.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          '最近のアクティビティはありません',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }
                  
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activities.take(5).length, // 最新5件のみ表示
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final activity = activities[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getActivityColor(activity.type).withOpacity(0.1),
                          child: Icon(
                            _getActivityIcon(activity.type),
                            color: _getActivityColor(activity.type),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          activity.title,
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          DateFormat('HH:mm').format(activity.createdAt),
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: activity.amount != null 
                            ? Text(
                                '+${activity.amount}P',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              )
                            : null,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text('アクティビティの取得に失敗しました: $error'),
              );
            },
          ),
        ],
      ),
    );
  }
  
  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'point_issued':
        return Icons.add_circle;
      case 'point_used':
        return Icons.remove_circle;
      case 'coupon_used':
        return Icons.local_offer;
      case 'new_customer':
        return Icons.person_add;
      default:
        return Icons.info;
    }
  }
  
  Color _getActivityColor(String type) {
    switch (type) {
      case 'point_issued':
        return Colors.green;
      case 'point_used':
        return Colors.blue;
      case 'coupon_used':
        return Colors.orange;
      case 'new_customer':
        return Colors.purple;
      default:
        return AppColors.primary;
    }
  }
  
  IconData _getStoreIcon(String category) {
    switch (category.toLowerCase()) {
      case 'restaurant':
      case 'レストラン':
        return Icons.restaurant;
      case 'cafe':
      case 'カフェ':
        return Icons.local_cafe;
      case 'izakaya':
      case '居酒屋':
        return Icons.local_bar;
      case 'fastfood':
      case 'ファストフード':
        return Icons.fastfood;
      case 'ramen':
      case 'ラーメン':
        return Icons.ramen_dining;
      case 'sushi':
      case '寿司':
        return Icons.set_meal;
      case 'yakiniku':
      case '焼肉':
        return Icons.outdoor_grill;
      case 'sweets':
      case 'スイーツ':
        return Icons.cake;
      case 'bakery':
      case 'パン屋':
        return Icons.bakery_dining;
      case 'bar':
      case 'バー':
        return Icons.wine_bar;
      default:
        return Icons.restaurant;
    }
  }
}

class _StoreMenuItem {
  final IconData icon;
  final String label;
  final String route;
  final bool isEmpty;
  
  const _StoreMenuItem({
    required this.icon,
    required this.label,
    required this.route,
    this.isEmpty = false,
  });
}

// 統計データモデル
class TodayStatsModel {
  final int todayVisitors;
  final int todayPointsIssued;
  final int todayCouponsUsed;
  
  const TodayStatsModel({
    required this.todayVisitors,
    required this.todayPointsIssued,
    required this.todayCouponsUsed,
  });
}

// アクティビティモデル
class ActivityModel {
  final String id;
  final String type;
  final String title;
  final int? amount;
  final DateTime createdAt;
  
  const ActivityModel({
    required this.id,
    required this.type,
    required this.title,
    this.amount,
    required this.createdAt,
  });
}
```

#### 4.2.2.1 店舗用アプリRiverpodプロバイダー
```dart
// 今日の統計データプロバイダー
final todayStatsProvider = FutureProvider<TodayStatsModel>((ref) async {
  final currentStore = ref.watch(currentStoreProvider);
  return currentStore.when(
    data: (store) async {
      if (store == null) return const TodayStatsModel(todayVisitors: 0, todayPointsIssued: 0, todayCouponsUsed: 0);
      
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      // 今日の来店者数
      final todayTransactions = await ref.watch(firestoreServiceProvider).getTransactionsByDateRange(
        store.storeId, 
        startOfDay, 
        endOfDay,
      );
      final todayVisitors = todayTransactions.map((t) => t.userId).toSet().length;
      
      // 今日のポイント発行数
      final todayPointsIssued = todayTransactions
          .where((t) => t.pointsEarned > 0)
          .fold<int>(0, (sum, t) => sum + t.pointsEarned);
      
      // 今日のクーポン利用数
      final todayCouponsUsed = await ref.watch(firestoreServiceProvider).getTodayCouponUsageCount(store.storeId);
      
      return TodayStatsModel(
        todayVisitors: todayVisitors,
        todayPointsIssued: todayPointsIssued,
        todayCouponsUsed: todayCouponsUsed,
      );
    },
    loading: () => const TodayStatsModel(todayVisitors: 0, todayPointsIssued: 0, todayCouponsUsed: 0),
    error: (_, __) => const TodayStatsModel(todayVisitors: 0, todayPointsIssued: 0, todayCouponsUsed: 0),
  );
});

// 最近のアクティビティプロバイダー
final recentActivitiesProvider = StreamProvider<List<ActivityModel>>((ref) {
  final currentStore = ref.watch(currentStoreProvider);
  return currentStore.when(
    data: (store) {
      if (store == null) return Stream.value([]);
      return ref.watch(firestoreServiceProvider).getRecentActivities(store.storeId);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// 未読お知らせ数プロバイダー（店舗用）
final unreadAnnouncementsCountProvider = StreamProvider.family<int, String>((ref, storeId) {
  return ref.watch(firestoreServiceProvider).getUnreadAnnouncementsCount(storeId, AnnouncementUserType.store);
});
```

#### 4.2.3 店舗一覧画面設計
```dart
class StoreListPage extends StatefulWidget {
  @override
  _StoreListPageState createState() => _StoreListPageState();
}

class _StoreListPageState extends State<StoreListPage> {
  String _selectedRegion = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('店舗一覧'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          // 検索バー
          _buildSearchBar(),
          
          // 地域選択フィルター
          _buildRegionFilter(),
          
          // 店舗グリッド表示（4*N 縦スクロール）
          Expanded(
            child: _buildStoreGrid(),
          ),
        ],
      ),
    );
  }
  
  // 検索バー
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '店舗名で検索...',
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }
  
  // 地域選択フィルター
  Widget _buildRegionFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Consumer(
        builder: (context, ref, child) {
          final regions = ref.watch(availableRegionsProvider);
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRegionChip('all', 'すべて'),
                ...regions.when(
                  data: (regionList) => regionList.map(
                    (region) => _buildRegionChip(region.id, region.name),
                  ).toList(),
                  loading: () => [const CircularProgressIndicator()],
                  error: (_, __) => [],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildRegionChip(String regionId, String regionName) {
    final isSelected = _selectedRegion == regionId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(regionName),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedRegion = regionId;
          });
        },
        backgroundColor: Colors.grey.shade200,
        selectedColor: AppColors.primary.withOpacity(0.2),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.text,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
  
  // 店舗グリッド表示（4*N 縦スクロール）
  Widget _buildStoreGrid() {
    return Consumer(
      builder: (context, ref, child) {
        final stores = ref.watch(filteredStoresProvider(
          region: _selectedRegion,
          searchQuery: _searchQuery,
        ));
        
        return stores.when(
          data: (storeList) {
            if (storeList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.store_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isNotEmpty
                          ? '「$_searchQuery」に該当する店舗がありません'
                          : '該当する店舗がありません',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_searchQuery.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: TextButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                          child: const Text('検索をクリア'),
                        ),
                      ),
                  ],
                ),
              );
            }
            
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: storeList.length,
              itemBuilder: (context, index) {
                final store = storeList[index];
                return _buildStoreItem(store);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'エラーが発生しました',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => ref.refresh(filteredStoresProvider(
                    region: _selectedRegion,
                    searchQuery: _searchQuery,
                  )),
                  child: const Text('再試行'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  
  // 個別店舗アイテム
  Widget _buildStoreItem(StoreModel store) {
    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        '/store-detail',
        arguments: store.storeId,
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 店舗アイコン
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: AppColors.primary.withOpacity(0.1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: store.iconUrl != null
                    ? CachedNetworkImage(
                        imageUrl: store.iconUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Icon(
                          _getStoreIcon(store.category),
                          size: 24,
                          color: AppColors.primary,
                        ),
                      )
                    : Icon(
                        _getStoreIcon(store.category),
                        size: 24,
                        color: AppColors.primary,
                      ),
              ),
            ),
            const SizedBox(height: 8),
            
            // 店舗名
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                store.name,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.text,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // カテゴリバッジ
            if (store.category.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getCategoryColor(store.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  store.category,
                  style: TextStyle(
                    fontSize: 8,
                    color: _getCategoryColor(store.category),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  // 店舗カテゴリに応じたアイコンを取得
  IconData _getStoreIcon(String category) {
    switch (category.toLowerCase()) {
      case 'restaurant':
      case 'レストラン':
        return Icons.restaurant;
      case 'cafe':
      case 'カフェ':
        return Icons.local_cafe;
      case 'izakaya':
      case '居酒屋':
        return Icons.local_bar;
      case 'fastfood':
      case 'ファストフード':
        return Icons.fastfood;
      case 'ramen':
      case 'ラーメン':
        return Icons.ramen_dining;
      case 'sushi':
      case '寿司':
        return Icons.set_meal;
      case 'yakiniku':
      case '焼肉':
        return Icons.outdoor_grill;
      case 'sweets':
      case 'スイーツ':
        return Icons.cake;
      case 'bakery':
      case 'パン屋':
        return Icons.bakery_dining;
      case 'bar':
      case 'バー':
        return Icons.wine_bar;
      default:
        return Icons.restaurant;
    }
  }
  
  // カテゴリに応じた色を取得
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'restaurant':
      case 'レストラン':
        return Colors.orange;
      case 'cafe':
      case 'カフェ':
        return Colors.brown;
      case 'izakaya':
      case '居酒屋':
        return Colors.red;
      case 'fastfood':
      case 'ファストフード':
        return Colors.amber;
      case 'ramen':
      case 'ラーメン':
        return Colors.yellow;
      case 'sushi':
      case '寿司':
        return Colors.blue;
      case 'yakiniku':
      case '焼肉':
        return Colors.deepOrange;
      case 'sweets':
      case 'スイーツ':
        return Colors.pink;
      case 'bakery':
      case 'パン屋':
        return Colors.deepPurple;
      case 'bar':
      case 'バー':
        return Colors.indigo;
      default:
        return AppColors.primary;
    }
  }
  
}
```

#### 4.2.3 関連プロバイダー追加
```dart
// 検索・フィルタリング用パラメータクラス
class StoreFilterParams {
  final String region;
  final String searchQuery;
  
  const StoreFilterParams({
    required this.region,
    required this.searchQuery,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoreFilterParams &&
          runtimeType == other.runtimeType &&
          region == other.region &&
          searchQuery == other.searchQuery;
  
  @override
  int get hashCode => region.hashCode ^ searchQuery.hashCode;
}

// 地域別店舗データプロバイダー
final availableRegionsProvider = FutureProvider<List<RegionModel>>((ref) {
  return ref.watch(storeRepositoryProvider).getAvailableRegions();
});

final allStoresProvider = StreamProvider<List<StoreModel>>((ref) {
  return ref.watch(storeRepositoryProvider).getAllStoresStream();
});

// フィルタリング・検索機能付きプロバイダー
final filteredStoresProvider = StreamProvider.family<List<StoreModel>, ({String region, String searchQuery})>((ref, params) {
  final allStores = ref.watch(allStoresProvider);
  
  return allStores.when(
    data: (stores) {
      var filteredStores = stores;
      
      // 地域フィルター
      if (params.region != 'all') {
        filteredStores = filteredStores
            .where((store) => store.region == params.region)
            .toList();
      }
      
      // 検索フィルター
      if (params.searchQuery.isNotEmpty) {
        final query = params.searchQuery.toLowerCase();
        filteredStores = filteredStores
            .where((store) =>
                store.name.toLowerCase().contains(query) ||
                store.category.toLowerCase().contains(query) ||
                store.description?.toLowerCase().contains(query) == true)
            .toList();
      }
      
      return Stream.value(filteredStores);
    },
    loading: () => const Stream.empty(),
    error: (error, stackTrace) => Stream.error(error, stackTrace),
  ).asBroadcastStream();
});

// 検索結果の統計情報プロバイダー
final storeSearchStatsProvider = Provider.family<({int totalCount, int filteredCount}), ({String region, String searchQuery})>((ref, params) {
  final allStores = ref.watch(allStoresProvider);
  final filteredStores = ref.watch(filteredStoresProvider(params));
  
  return allStores.when(
    data: (all) => filteredStores.when(
      data: (filtered) => (totalCount: all.length, filteredCount: filtered.length),
      loading: () => (totalCount: all.length, filteredCount: 0),
      error: (_, __) => (totalCount: all.length, filteredCount: 0),
    ),
    loading: () => (totalCount: 0, filteredCount: 0),
    error: (_, __) => (totalCount: 0, filteredCount: 0),
  );
});

// 人気検索キーワードプロバイダー
final popularSearchKeywordsProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(storeRepositoryProvider).getPopularSearchKeywords();
});

// 店舗モデルに地域情報を追加
class StoreModel {
  final String storeId;
  final String name;
  final String? iconUrl;
  final String category;
  final String? region; // 地域情報追加
  final String? description; // 検索対象として説明文を追加
  // ... 他のフィールド
  
  const StoreModel({
    required this.storeId,
    required this.name,
    this.iconUrl,
    required this.category,
    this.region,
    this.description,
    // ... 他のパラメータ
  });
}

class RegionModel {
  final String id;
  final String name;
  final int storeCount;
  
  const RegionModel({
    required this.id,
    required this.name,
    required this.storeCount,
  });
}

// 検索履歴管理用モデル
class SearchHistoryModel {
  final String keyword;
  final DateTime searchedAt;
  final int resultCount;
  
  const SearchHistoryModel({
    required this.keyword,
    required this.searchedAt,
    required this.resultCount,
  });
}
```

#### 4.2.4 認証・アカウント作成画面設計

##### 4.2.4.1 ログイン画面
```dart
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ロゴ
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
                child: const Center(
                  child: Text(
                    'G',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              const Text(
                'GrouMapへようこそ',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              
              const Text(
                '地図でつながる、お得が見つかる',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 48),
              
              // ソーシャルログインボタン
              _buildSocialLoginButton(
                icon: Icons.apple,
                text: 'Appleでログイン',
                color: Colors.black,
                onPressed: () => _signInWithApple(),
              ),
              const SizedBox(height: 16),
              
              _buildSocialLoginButton(
                icon: Icons.g_mobiledata,
                text: 'Googleでログイン',
                color: Colors.red,
                onPressed: () => _signInWithGoogle(),
              ),
              const SizedBox(height: 32),
              
              // 区切り線
              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('または', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 32),
              
              // メールアドレスログイン
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'メールアドレス',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'パスワード',
                  prefixIcon: Icon(Icons.lock_outlined),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _signInWithEmail(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'ログイン',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              
              // アカウント作成
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/signup'),
                child: const Text('アカウントをお持ちでない場合はこちら'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSocialLoginButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : onPressed,
        icon: Icon(icon, color: color),
        label: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
  
  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(authServiceProvider).signInWithApple();
      if (result.isNewUser) {
        Navigator.pushReplacementNamed(context, '/profile-setup');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      _showErrorSnackBar('Appleログインに失敗しました');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(authServiceProvider).signInWithGoogle();
      if (result.isNewUser) {
        Navigator.pushReplacementNamed(context, '/profile-setup');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      _showErrorSnackBar('Googleログインに失敗しました');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _signInWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorSnackBar('メールアドレスとパスワードを入力してください');
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(authServiceProvider).signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (result.isNewUser) {
        Navigator.pushReplacementNamed(context, '/profile-setup');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      _showErrorSnackBar('ログインに失敗しました');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
```

##### 4.2.4.2 プロフィール設定画面
```dart
class ProfileSetupPage extends StatefulWidget {
  @override
  _ProfileSetupPageState createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _userNameController = TextEditingController();
  final _referralCodeController = TextEditingController();
  
  String _selectedGender = 'not_specified';
  String _selectedAgeRange = 'twenties';
  String _selectedPrefecture = '';
  String _selectedCity = '';
  
  bool _isLoading = false;
  
  final List<String> _genderOptions = [
    'male',
    'female',
    'other',
    'not_specified',
  ];
  
  final Map<String, String> _genderLabels = {
    'male': '男性',
    'female': '女性',
    'other': 'その他',
    'not_specified': '回答しない',
  };
  
  final List<String> _ageRangeOptions = [
    'teens',
    'twenties',
    'thirties',
    'forties',
    'fifties',
    'sixties_plus',
  ];
  
  final Map<String, String> _ageRangeLabels = {
    'teens': '10代',
    'twenties': '20代',
    'thirties': '30代',
    'forties': '40代',
    'fifties': '50代',
    'sixties_plus': '60代以上',
  };
  
  @override
  void dispose() {
    _userNameController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール設定'),
        backgroundColor: AppColors.primary,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'あなたについて教えてください',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'より良いサービスを提供するため、基本情報をお聞かせください',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              
              // ユーザー名
              TextFormField(
                controller: _userNameController,
                decoration: const InputDecoration(
                  labelText: 'ユーザー名 *',
                  hintText: '例: yamada_taro',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'ユーザー名を入力してください';
                  }
                  if (value.length < 3) {
                    return 'ユーザー名は3文字以上で入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // 性別
              const Text(
                '性別',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.wc),
                ),
                items: _genderOptions.map((gender) {
                  return DropdownMenuItem(
                    value: gender,
                    child: Text(_genderLabels[gender] ?? ''),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value ?? 'not_specified';
                  });
                },
              ),
              const SizedBox(height: 24),
              
              // 年代
              const Text(
                '年代',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedAgeRange,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.cake),
                ),
                items: _ageRangeOptions.map((age) {
                  return DropdownMenuItem(
                    value: age,
                    child: Text(_ageRangeLabels[age] ?? ''),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAgeRange = value ?? 'twenties';
                  });
                },
              ),
              const SizedBox(height: 24),
              
              // 住所
              const Text(
                '住所',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              
              // 都道府県
              Consumer(
                builder: (context, ref, child) {
                  final prefectures = ref.watch(prefecturesProvider);
                  return prefectures.when(
                    data: (prefList) => DropdownButtonFormField<String>(
                      value: _selectedPrefecture.isEmpty ? null : _selectedPrefecture,
                      decoration: const InputDecoration(
                        labelText: '都道府県 *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      items: prefList.map((pref) {
                        return DropdownMenuItem(
                          value: pref,
                          child: Text(pref),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPrefecture = value ?? '';
                          _selectedCity = ''; // 都道府県変更時に市区町村をリセット
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '都道府県を選択してください';
                        }
                        return null;
                      },
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('都道府県の取得に失敗しました'),
                  );
                },
              ),
              const SizedBox(height: 16),
              
              // 市区町村
              if (_selectedPrefecture.isNotEmpty)
                Consumer(
                  builder: (context, ref, child) {
                    final cities = ref.watch(citiesProvider(_selectedPrefecture));
                    return cities.when(
                      data: (cityList) => DropdownButtonFormField<String>(
                        value: _selectedCity.isEmpty ? null : _selectedCity,
                        decoration: const InputDecoration(
                          labelText: '市区町村 *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_city_outlined),
                        ),
                        items: cityList.map((city) {
                          return DropdownMenuItem(
                            value: city,
                            child: Text(city),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCity = value ?? '';
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '市区町村を選択してください';
                          }
                          return null;
                        },
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const Text('市区町村の取得に失敗しました'),
                    );
                  },
                ),
              const SizedBox(height: 24),
              
              // 友達紹介コード
              TextFormField(
                controller: _referralCodeController,
                decoration: const InputDecoration(
                  labelText: '友達紹介コード（任意）',
                  hintText: '友達からもらったコードを入力',
                  prefixIcon: Icon(Icons.card_giftcard),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 32),
              
              // 完了ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'プロフィールを保存',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              
              const Text(
                '※ 必須項目は後からでも変更できます',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) {
        throw Exception('ユーザー情報が取得できませんでした');
      }
      
      await ref.read(userServiceProvider).updateUserProfile(
        userId: currentUser.uid,
        userName: _userNameController.text.trim(),
        gender: _selectedGender,
        ageRange: _selectedAgeRange,
        prefecture: _selectedPrefecture,
        city: _selectedCity,
        referralCode: _referralCodeController.text.trim().isNotEmpty
            ? _referralCodeController.text.trim()
            : null,
      );
      
      Navigator.pushReplacementNamed(context, '/home');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('プロフィールを保存しました！')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('プロフィールの保存に失敗しました: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
```

#### 4.2.5 認証サービス設計
```dart
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  // Apple Sign-In
  Future<AuthResult> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      
      final oAuthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      
      final userCredential = await _auth.signInWithCredential(oAuthCredential);
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      
      if (isNewUser) {
        await _createUserDocument(
          userCredential.user!,
          authProvider: 'apple',
          displayName: '${appleCredential.givenName} ${appleCredential.familyName}',
        );
      }
      
      return AuthResult(user: userCredential.user, isNewUser: isNewUser);
    } catch (e) {
      throw AuthException('Appleログインに失敗しました: $e');
    }
  }
  
  // Google Sign-In
  Future<AuthResult> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthException('Googleログインがキャンセルされました');
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final userCredential = await _auth.signInWithCredential(credential);
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      
      if (isNewUser) {
        await _createUserDocument(
          userCredential.user!,
          authProvider: 'google',
          displayName: googleUser.displayName,
        );
      }
      
      return AuthResult(user: userCredential.user, isNewUser: isNewUser);
    } catch (e) {
      throw AuthException('Googleログインに失敗しました: $e');
    }
  }
  
  // Email Sign-In
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      return AuthResult(user: userCredential.user, isNewUser: false);
    } catch (e) {
      throw AuthException('メールログインに失敗しました: $e');
    }
  }
  
  // Email Sign-Up
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await _createUserDocument(
        userCredential.user!,
        authProvider: 'email',
      );
      
      return AuthResult(user: userCredential.user, isNewUser: true);
    } catch (e) {
      throw AuthException('アカウント作成に失敗しました: $e');
    }
  }
  
  // ユーザードキュメント作成
  Future<void> _createUserDocument(
    User user, {
    required String authProvider,
    String? displayName,
  }) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    
    await userDoc.set({
      'userId': user.uid,
      'email': user.email,
      'displayName': displayName ?? user.displayName ?? '',
      'userName': '', // プロフィール設定で入力
      'photoURL': user.photoURL,
      'authProvider': authProvider,
      'profile': {
        'gender': 'not_specified',
        'ageRange': 'twenties',
        'address': {
          'prefecture': '',
          'city': '',
        },
      },
      'level': 1,
      'experience': 0,
      'totalPoints': 0,
      'availablePoints': 0,
      'badges': [],
      'favoriteStores': [],
      'referralInfo': {
        'referralCode': _generateReferralCode(),
        'referredBy': null,
        'referredUsers': [],
      },
      'isActive': true,
      'lastLoginAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  // 紹介コード生成
  String _generateReferralCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(8, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }
}

class AuthResult {
  final User? user;
  final bool isNewUser;
  
  AuthResult({required this.user, required this.isNewUser});
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  
  @override
  String toString() => message;
}
```

#### 4.2.6 店舗詳細画面設計
```dart
class StoreDetailPage extends StatefulWidget {
  final String storeId;
  
  const StoreDetailPage({Key? key, required this.storeId}) : super(key: key);
  
  @override
  _StoreDetailPageState createState() => _StoreDetailPageState();
}

class _StoreDetailPageState extends State<StoreDetailPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  bool _isAppBarExpanded = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollListener() {
    const threshold = 200.0;
    if (_scrollController.offset > threshold && _isAppBarExpanded) {
      setState(() => _isAppBarExpanded = false);
    } else if (_scrollController.offset <= threshold && !_isAppBarExpanded) {
      setState(() => _isAppBarExpanded = true);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final store = ref.watch(storeDetailsProvider(widget.storeId));
        
        return store.when(
          data: (storeData) => Scaffold(
            body: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // カスタムAppBar（背景画像3:4比率）
                _buildCustomAppBar(storeData),
                
                // 店舗基本情報
                SliverToBoxAdapter(
                  child: _buildStoreBasicInfo(storeData),
                ),
                
                // スタンプカード（5*2）
                SliverToBoxAdapter(
                  child: _buildStampCard(storeData),
                ),
                
                // クーポン（横スライド4つ）
                SliverToBoxAdapter(
                  child: _buildCouponsSection(storeData),
                ),
                
                // タブバー
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    tabBar: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.primary,
                      tabs: const [
                        Tab(text: '投稿'),
                        Tab(text: 'メニュー'),
                        Tab(text: '詳細情報'),
                      ],
                    ),
                  ),
                ),
                
                // タブ内容
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPostsTab(storeData),
                      _buildMenuTab(storeData),
                      _buildDetailsTab(storeData),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => Navigator.pushNamed(
                context,
                '/qr',
                arguments: {'storeId': widget.storeId, 'action': 'checkin'},
              ),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.qr_code, color: Colors.white),
            ),
          ),
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Scaffold(
            appBar: AppBar(title: const Text('エラー')),
            body: Center(child: Text('店舗情報の取得に失敗しました: $error')),
          ),
        );
      },
    );
  }
  
  // カスタムAppBar（背景画像3:4比率）
  Widget _buildCustomAppBar(StoreModel store) {
    return SliverAppBar(
      expandedHeight: 300.0, // 3:4比率に調整
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // 背景画像
            Container(
              width: double.infinity,
              height: double.infinity,
              child: store.backgroundImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: store.backgroundImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade300,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.primary.withOpacity(0.1),
                        child: Icon(
                          Icons.store,
                          size: 64,
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primary.withOpacity(0.8),
                            AppColors.primary,
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.store,
                        size: 64,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
            ),
            
            // グラデーションオーバーレイ
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: AppColors.primary,
      actions: [
        Consumer(
          builder: (context, ref, child) {
            final isFavorite = ref.watch(isFavoriteStoreProvider(widget.storeId));
            return IconButton(
              onPressed: () => ref.read(userServiceProvider).toggleFavoriteStore(widget.storeId),
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.white,
              ),
            );
          },
        ),
        IconButton(
          onPressed: () => _shareStore(store),
          icon: const Icon(Icons.share, color: Colors.white),
        ),
      ],
    );
  }
  
  // 店舗基本情報（アイコン、名前、説明）
  Widget _buildStoreBasicInfo(StoreModel store) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 店舗アイコンと名前
          Row(
            children: [
              // 店舗アイコン
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: store.iconUrl != null
                      ? CachedNetworkImage(
                          imageUrl: store.iconUrl!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Icon(
                            _getStoreIcon(store.category),
                            size: 32,
                            color: AppColors.primary,
                          ),
                        )
                      : Icon(
                          _getStoreIcon(store.category),
                          size: 32,
                          color: AppColors.primary,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              
              // 店舗名と基本情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // カテゴリバッジ
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(store.category).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getCategoryColor(store.category).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        store.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: _getCategoryColor(store.category),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // 営業状態
                    Row(
                      children: [
                        Icon(
                          _isStoreOpen(store) ? Icons.access_time : Icons.access_time_filled,
                          size: 16,
                          color: _isStoreOpen(store) ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isStoreOpen(store) ? '営業中' : '営業時間外',
                          style: TextStyle(
                            fontSize: 12,
                            color: _isStoreOpen(store) ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 店舗説明
          if (store.description != null && store.description!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.description!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          
          // 基本情報チップ
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(Icons.location_on, store.address),
              if (store.phoneNumber != null)
                _buildInfoChip(Icons.phone, store.phoneNumber!),
              _buildInfoChip(Icons.star, '${store.rating?.toStringAsFixed(1) ?? '0.0'} (${store.reviewCount ?? 0})'),
            ],
          ),
        ],
      ),
    );
  }
  
  // スタンプカード（5*2）
  Widget _buildStampCard(StoreModel store) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'スタンプカード',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              Consumer(
                builder: (context, ref, child) {
                  final stampCount = ref.watch(userStampCountProvider(widget.storeId));
                  return Text(
                    '$stampCount/10',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // スタンプグリッド（5*2）
          Consumer(
            builder: (context, ref, child) {
              final stampCount = ref.watch(userStampCountProvider(widget.storeId));
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  childAspectRatio: 1,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 10,
                itemBuilder: (context, index) {
                  final isStamped = index < stampCount;
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isStamped 
                          ? AppColors.primary 
                          : Colors.grey.shade200,
                      border: Border.all(
                        color: isStamped 
                            ? AppColors.primary 
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        isStamped ? Icons.check : Icons.circle_outlined,
                        color: isStamped ? Colors.white : Colors.grey.shade400,
                        size: 20,
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 12),
          
          // 特典説明
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.card_giftcard,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'スタンプ10個で500ポイントプレゼント！',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // クーポンセクション（横スライド4つ）
  Widget _buildCouponsSection(StoreModel store) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '利用可能なクーポン',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/store-coupons',
                  arguments: widget.storeId,
                ),
                child: const Text('すべて見る'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        Consumer(
          builder: (context, ref, child) {
            final coupons = ref.watch(storeCouponsProvider(widget.storeId));
            return coupons.when(
              data: (couponList) {
                if (couponList.isEmpty) {
                  return Container(
                    height: 120,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Center(
                      child: Text(
                        '現在利用可能なクーポンはありません',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }
                
                return SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: math.min(couponList.length, 4),
                    itemBuilder: (context, index) {
                      final coupon = couponList[index];
                      return Container(
                        width: 200,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange.shade400, Colors.red.shade500],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                coupon.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                coupon.description,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Text(
                                '有効期限: ${DateFormat('MM/dd').format(coupon.validTo)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => Container(
                height: 120,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: const Center(
                  child: Text('クーポン情報の取得に失敗しました'),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  
  // 投稿タブ
  Widget _buildPostsTab(StoreModel store) {
    return Consumer(
      builder: (context, ref, child) {
        final posts = ref.watch(storePostsProvider(widget.storeId));
        return posts.when(
          data: (postList) {
            if (postList.isEmpty) {
              return const Center(
                child: Text(
                  'まだ投稿がありません\n最初の投稿をしてみませんか？',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }
            
            // Instagram風 3×N グリッド表示（正方形画像、新着順）
            return GridView.builder(
              padding: const EdgeInsets.all(4),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                childAspectRatio: 1.0, // 正方形
              ),
              itemCount: postList.length,
              itemBuilder: (context, index) {
                final post = postList[index];
                return GestureDetector(
                  onTap: () => _showPostDetail(post),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: post.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade300,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(
            child: Text('投稿の取得に失敗しました'),
          ),
        );
      },
    );
  }
  
  // メニュータブ
  Widget _buildMenuTab(StoreModel store) {
    return Consumer(
      builder: (context, ref, child) {
        final menu = ref.watch(storeMenuProvider(widget.storeId));
        return menu.when(
          data: (menuItems) {
            if (menuItems.isEmpty) {
              return const Center(
                child: Text(
                  'メニュー情報がありません',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }
            
            // カテゴリ別メニュー表示（ドリンク、フード、アルコール）
            final groupedMenus = _groupMenusByCategory(menuItems);
            
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groupedMenus.length,
              itemBuilder: (context, index) {
                final category = groupedMenus.keys.elementAt(index);
                final items = groupedMenus[category]!;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // カテゴリヘッダー
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    // メニューアイテム
                    ...items.map((item) => _buildMenuCard(item)),
                    const SizedBox(height: 16),
                  ],
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(
            child: Text('メニューの取得に失敗しました'),
          ),
        );
      },
    );
  }
  
  // 詳細情報タブ
  Widget _buildDetailsTab(StoreModel store) {
    final isOpen = _isStoreOpen(store.operatingHours);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 営業状況
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isOpen ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isOpen ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isOpen ? Icons.access_time : Icons.access_time_filled,
                  color: isOpen ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isOpen ? '営業中' : '営業時間外',
                  style: TextStyle(
                    color: isOpen ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // 基本情報
          _buildDetailSection('基本情報', [
            if (store.website != null)
              _buildDetailRowWithIcon(
                Icons.language,
                'ウェブサイト',
                store.website!,
                onTap: () => _launchUrl(store.website!),
              ),
            if (store.phoneNumber != null)
              _buildDetailRowWithIcon(
                Icons.phone,
                '電話番号',
                store.phoneNumber!,
                onTap: () => _launchPhone(store.phoneNumber!),
              ),
            _buildDetailRowWithIcon(
              Icons.category,
              'ジャンル',
              store.category,
            ),
            _buildDetailRowWithIcon(
              Icons.location_on,
              '住所',
              store.address,
            ),
          ]),
          
          // SNSリンク
          if (store.socialLinks != null && store.socialLinks!.isNotEmpty)
            _buildSocialLinksSection(store.socialLinks!),
          
          _buildDetailSection('営業時間', [
            ...store.operatingHours.entries.map(
              (entry) => _buildDetailRow(
                _getWeekdayLabel(entry.key),
                '${entry.value.open} - ${entry.value.close}',
              ),
            ),
          ]),
          
          _buildDetailSection('アクセス', [
            _buildDetailRow('最寄り駅', store.nearestStation ?? '情報なし'),
            _buildDetailRow('駐車場', store.hasParking ? 'あり' : 'なし'),
          ]),
          
          if (store.features.isNotEmpty)
            _buildDetailSection('特徴・設備', 
              store.features.map((feature) => 
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(feature),
                    ],
                  ),
                ),
              ).toList(),
            ),
        ],
      ),
    );
  }
  
  // ヘルパーメソッド
  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
        const SizedBox(height: 24),
      ],
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 投稿詳細表示
  void _showPostDetail(PostModel post) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              // 投稿画像
              Expanded(
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
              // 投稿情報
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.caption ?? '',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDateTime(post.createdAt),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // メニューカテゴリ別グルーピング
  Map<String, List<MenuItemModel>> _groupMenusByCategory(List<MenuItemModel> menuItems) {
    final grouped = <String, List<MenuItemModel>>{};
    
    for (final item in menuItems) {
      final category = item.category ?? 'その他';
      grouped.putIfAbsent(category, () => []).add(item);
    }
    
    // カテゴリ順序の定義
    final orderedCategories = ['ドリンク', 'フード', 'アルコール', 'その他'];
    final result = <String, List<MenuItemModel>>{};
    
    for (final category in orderedCategories) {
      if (grouped.containsKey(category)) {
        result[category] = grouped[category]!;
      }
    }
    
    // 定義されていないカテゴリも追加
    grouped.forEach((key, value) {
      if (!orderedCategories.contains(key)) {
        result[key] = value;
      }
    });
    
    return result;
  }
  
  // メニューカード（画像ありなし対応）
  Widget _buildMenuCard(MenuItemModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // メニュー画像（ある場合のみ）
            if (item.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade300,
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.restaurant, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
            
            // メニュー情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  if (item.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.description!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '¥${item.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // アイコン付き詳細情報行
  Widget _buildDetailRowWithIcon(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: onTap != null ? AppColors.primary : AppColors.text,
                  decoration: onTap != null ? TextDecoration.underline : null,
                ),
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.open_in_new,
                size: 16,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
  
  // SNSリンクセクション
  Widget _buildSocialLinksSection(Map<String, String> socialLinks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SNS',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (socialLinks['twitter'] != null)
              _buildSocialIcon(
                icon: Icons.flutter_dash, // Twitter icon代用
                onTap: () => _launchUrl(socialLinks['twitter']!),
                color: Colors.blue,
              ),
            if (socialLinks['instagram'] != null)
              _buildSocialIcon(
                icon: Icons.camera_alt,
                onTap: () => _launchUrl(socialLinks['instagram']!),
                color: Colors.purple,
              ),
            if (socialLinks['facebook'] != null)
              _buildSocialIcon(
                icon: Icons.facebook,
                onTap: () => _launchUrl(socialLinks['facebook']!),
                color: Colors.blue.shade800,
              ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
  
  // SNSアイコン
  Widget _buildSocialIcon({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
  
  // 営業中チェック
  bool _isStoreOpen(Map<String, OperatingHours> operatingHours) {
    final now = DateTime.now();
    final weekday = _getWeekdayKey(now.weekday);
    
    if (!operatingHours.containsKey(weekday)) return false;
    
    final hours = operatingHours[weekday]!;
    final currentTime = TimeOfDay.fromDateTime(now);
    
    return _isTimeInRange(currentTime, hours.open, hours.close);
  }
  
  String _getWeekdayKey(int weekday) {
    const keys = {
      1: 'monday',
      2: 'tuesday', 
      3: 'wednesday',
      4: 'thursday',
      5: 'friday',
      6: 'saturday',
      7: 'sunday',
    };
    return keys[weekday] ?? 'monday';
  }
  
  bool _isTimeInRange(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    
    if (startMinutes <= endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // 日をまたぐ場合
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }
  
  // URL・電話番号起動
  void _launchUrl(String url) {
    // URL起動の実装
  }
  
  void _launchPhone(String phoneNumber) {
    // 電話アプリ起動の実装
  }
  
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}年${dateTime.month}月${dateTime.day}日';
  }

  // その他のヘルパーメソッド...
  IconData _getStoreIcon(String category) {
    switch (category.toLowerCase()) {
      case 'restaurant':
      case 'レストラン':
        return Icons.restaurant;
      case 'cafe':
      case 'カフェ':
        return Icons.local_cafe;
      case 'izakaya':
      case '居酒屋':
        return Icons.local_bar;
      case 'fastfood':
      case 'ファストフード':
        return Icons.fastfood;
      case 'ramen':
      case 'ラーメン':
        return Icons.ramen_dining;
      case 'sushi':
      case '寿司':
        return Icons.set_meal;
      case 'yakiniku':
      case '焼肉':
        return Icons.outdoor_grill;
      case 'sweets':
      case 'スイーツ':
        return Icons.cake;
      case 'bakery':
      case 'パン屋':
        return Icons.bakery_dining;
      case 'bar':
      case 'バー':
        return Icons.wine_bar;
      default:
        return Icons.restaurant;
    }
  }
  
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'restaurant':
      case 'レストラン':
        return Colors.orange;
      case 'cafe':
      case 'カフェ':
        return Colors.brown;
      case 'izakaya':
      case '居酒屋':
        return Colors.red;
      case 'fastfood':
      case 'ファストフード':
        return Colors.amber;
      case 'ramen':
      case 'ラーメン':
        return Colors.yellow;
      case 'sushi':
      case '寿司':
        return Colors.blue;
      case 'yakiniku':
      case '焼肉':
        return Colors.deepOrange;
      case 'sweets':
      case 'スイーツ':
        return Colors.pink;
      case 'bakery':
      case 'パン屋':
        return Colors.deepPurple;
      case 'bar':
      case 'バー':
        return Colors.indigo;
      default:
        return AppColors.primary;
    }
  }
  
  String _getWeekdayLabel(String weekday) {
    const labels = {
      'monday': '月曜日',
      'tuesday': '火曜日',
      'wednesday': '水曜日',
      'thursday': '木曜日',
      'friday': '金曜日',
      'saturday': '土曜日',
      'sunday': '日曜日',
    };
    return labels[weekday] ?? weekday;
  }
  
  void _shareStore(StoreModel store) {
    // 店舗共有機能
  }
}

// タブバーデリゲート
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  
  _TabBarDelegate({required this.tabBar});
  
  @override
  double get minExtent => tabBar.preferredSize.height;
  
  @override
  double get maxExtent => tabBar.preferredSize.height;
  
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }
  
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
```

#### 4.2.7 ボトムナビゲーション
```dart
class MainBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  
  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: onTap,
        selectedItemColor: AppColors.primary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'マップ'),
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: '投稿'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'アカウント'),
        ],
      ),
    );
  }
}
```

#### 4.2.2 QRフローティングボタン
```dart
class QRFloatingActionButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const QRCodePage()),
      ),
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.qr_code, color: Colors.white),
    );
  }
}
```

#### 4.2.3 カスタムマップピン設計
```dart
class CustomMapPin extends StatelessWidget {
  final StoreModel store;
  final bool isSelected;
  
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isSelected ? 60 : 30,
      height: isSelected ? 60 : 30,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 影
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          // メインピン
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
          // 店舗アイコン
          Icon(
            _getStoreIcon(store.category),
            color: Colors.white,
            size: isSelected ? 24 : 12,
          ),
        ],
      ),
    );
  }
}
```

#### 4.2.4 マップ画面設計

##### 4.2.4.1 マップ画面メイン構造
```dart
class MapView extends ConsumerStatefulWidget {
  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  
  // マップ状態
  String _selectedStoreId = '';
  LatLng _currentPosition = const LatLng(35.6762, 139.6503); // 東京駅
  
  // フィルタ状態
  MapFilterMode _currentFilterMode = MapFilterMode.loyalty;
  String _selectedCategory = '';
  bool _showOpenOnly = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          _buildGoogleMap(),
          
          // 上部検索バー
          _buildSearchHeader(),
          
          // フィルタボタン
          _buildFilterButtons(),
          
          // 選択されたピンの詳細表示
          if (_selectedStoreId.isNotEmpty)
            _buildSelectedStoreInfo(),
        ],
      ),
    );
  }

  Widget _buildGoogleMap() {
    final storesAsync = ref.watch(filteredStoresProvider);
    
    return storesAsync.when(
      data: (stores) => GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
          _getCurrentLocation();
        },
        initialCameraPosition: CameraPosition(
          target: _currentPosition,
          zoom: 14.0,
        ),
        markers: _buildMapMarkers(stores),
        onTap: (LatLng position) {
          // マップタップで選択解除
          setState(() {
            _selectedStoreId = '';
          });
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: false, // カスタム位置ボタンを使用
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        compassEnabled: true,
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('マップの読み込みに失敗しました: $error'),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: '店舗名、住所で検索',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  _performSearch(value);
                },
                onSubmitted: (value) {
                  _performSearch(value);
                },
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: () {
                  _searchController.clear();
                  _clearSearch();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      left: 16,
      child: Column(
        children: [
          // フィルタモード切替ボタン
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFilterModeButton(
                  MapFilterMode.loyalty,
                  Icons.stars,
                  '常連度',
                ),
                _buildFilterModeButton(
                  MapFilterMode.openOnly,
                  Icons.access_time,
                  '営業中',
                ),
                _buildFilterModeButton(
                  MapFilterMode.category,
                  Icons.category,
                  'カテゴリ',
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // カテゴリ選択（カテゴリモード時のみ表示）
          if (_currentFilterMode == MapFilterMode.category)
            _buildCategoryFilter(),
        ],
      ),
    );
  }

  Widget _buildFilterModeButton(MapFilterMode mode, IconData icon, String label) {
    final isSelected = _currentFilterMode == mode;
    
    return Material(
      color: isSelected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _switchFilterMode(mode),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    const categories = [
      'レストラン', 'カフェ', '居酒屋', 'ファストフード', 'ラーメン', 
      '寿司', '焼肉', 'スイーツ', 'パン屋', 'バー'
    ];
    
    return Container(
      width: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 全て表示オプション
          Material(
            color: _selectedCategory.isEmpty ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () => _selectCategory(''),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.all_inclusive,
                      size: 14,
                      color: _selectedCategory.isEmpty ? AppColors.primary : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '全て',
                        style: TextStyle(
                          fontSize: 11,
                          color: _selectedCategory.isEmpty ? AppColors.primary : Colors.grey[600],
                          fontWeight: _selectedCategory.isEmpty ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // カテゴリリスト
          ...categories.map((category) => Material(
            color: _selectedCategory == category ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () => _selectCategory(category),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      _getCategoryIcon(category),
                      size: 14,
                      color: _selectedCategory == category ? AppColors.primary : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 11,
                          color: _selectedCategory == category ? AppColors.primary : Colors.grey[600],
                          fontWeight: _selectedCategory == category ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSelectedStoreInfo() {
    final selectedStoreAsync = ref.watch(storeByIdProvider(_selectedStoreId));
    
    return selectedStoreAsync.when(
      data: (store) {
        if (store == null) return const SizedBox();
        
        return Positioned(
          bottom: 100, // ボトムナビゲーションの上
          left: 16,
          right: 16,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // 店舗アイコン（2倍サイズ）
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getCategoryColor(store.category),
                        ),
                        child: store.iconUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: CachedNetworkImage(
                                  imageUrl: store.iconUrl!,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) => Icon(
                                    _getCategoryIcon(store.category),
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : Icon(
                                _getCategoryIcon(store.category),
                                size: 30,
                                color: Colors.white,
                              ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // 店舗情報
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 店舗名
                            Text(
                              store.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            
                            const SizedBox(height: 4),
                            
                            // 営業状況
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _isStoreOpen(store) ? Colors.green : Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isStoreOpen(store) ? '営業中' : '営業時間外',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _isStoreOpen(store) ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // 常連度表示
                            _buildLoyaltyStatus(store.storeId),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 店舗詳細ボタン
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/store-detail',
                          arguments: store.storeId,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '店舗詳細',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (error, stack) => const SizedBox(),
    );
  }

  Widget _buildLoyaltyStatus(String storeId) {
    final stampCountAsync = ref.watch(userStampCountProvider(storeId));
    
    return stampCountAsync.when(
      data: (count) {
        String status;
        Color statusColor;
        IconData statusIcon;
        
        if (count == 0) {
          status = '未開拓';
          statusColor = Colors.grey;
          statusIcon = Icons.explore_off;
        } else if (count < 10) {
          status = '開拓中 ($count/10)';
          statusColor = Colors.orange;
          statusIcon = Icons.explore;
        } else {
          status = '常連 (${count}個)';
          statusColor = Colors.purple;
          statusIcon = Icons.star;
        }
        
        return Row(
          children: [
            Icon(statusIcon, size: 14, color: statusColor),
            const SizedBox(width: 4),
            Text(
              status,
              style: TextStyle(
                fontSize: 12,
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(),
      error: (error, stack) => const SizedBox(),
    );
  }

  Set<Marker> _buildMapMarkers(List<StoreModel> stores) {
    return stores.map((store) {
      return Marker(
        markerId: MarkerId(store.storeId),
        position: LatLng(store.latitude, store.longitude),
        onTap: () {
          setState(() {
            _selectedStoreId = store.storeId;
          });
          _animateToStore(store);
        },
        icon: _getCustomMarkerIcon(store),
      );
    }).toSet();
  }

  BitmapDescriptor _getCustomMarkerIcon(StoreModel store) {
    // カスタムピンアイコンの生成
    // 実装では BitmapDescriptor.fromAssetImage() や custom painter を使用
    return BitmapDescriptor.defaultMarkerWithHue(
      _getMarkerHue(store.category),
    );
  }

  double _getMarkerHue(String category) {
    switch (category) {
      case 'レストラン': return BitmapDescriptor.hueOrange;
      case 'カフェ': return BitmapDescriptor.hueYellow;
      case '居酒屋': return BitmapDescriptor.hueRed;
      case 'ファストフード': return BitmapDescriptor.hueBlue;
      case 'ラーメン': return BitmapDescriptor.hueGreen;
      case '寿司': return BitmapDescriptor.hueCyan;
      case '焼肉': return BitmapDescriptor.hueMagenta;
      case 'スイーツ': return BitmapDescriptor.hueRose;
      case 'パン屋': return BitmapDescriptor.hueViolet;
      case 'バー': return BitmapDescriptor.hueAzure;
      default: return BitmapDescriptor.hueRed;
    }
  }

  // フィルタモード切替
  void _switchFilterMode(MapFilterMode mode) {
    setState(() {
      _currentFilterMode = mode;
      if (mode != MapFilterMode.category) {
        _selectedCategory = '';
      }
    });
    
    ref.read(mapFilterProvider.notifier).updateFilterMode(mode);
  }

  // カテゴリ選択
  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
    
    ref.read(mapFilterProvider.notifier).updateSelectedCategory(category);
  }

  // 検索実行
  void _performSearch(String query) {
    ref.read(mapSearchProvider.notifier).updateSearchQuery(query);
  }

  // 検索クリア
  void _clearSearch() {
    ref.read(mapSearchProvider.notifier).clearSearch();
  }

  // 店舗位置にアニメーション
  void _animateToStore(StoreModel store) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(store.latitude, store.longitude),
        16.0,
      ),
    );
  }

  // 現在位置取得
  void _getCurrentLocation() async {
    // 位置情報サービスの実装
    // Geolocator パッケージを使用
  }

  // 営業中判定
  bool _isStoreOpen(StoreModel store) {
    final now = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(now);
    final weekday = _getWeekdayString(now.weekday);
    
    final todayHours = store.operatingHours[weekday];
    if (todayHours == null) return false;
    
    final openTime = _parseTimeString(todayHours['open']!);
    final closeTime = _parseTimeString(todayHours['close']!);
    
    return _isTimeBetween(currentTime, openTime, closeTime);
  }

  String _getWeekdayString(int weekday) {
    const weekdays = {
      1: 'monday', 2: 'tuesday', 3: 'wednesday', 4: 'thursday',
      5: 'friday', 6: 'saturday', 7: 'sunday'
    };
    return weekdays[weekday] ?? 'monday';
  }

  TimeOfDay _parseTimeString(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  bool _isTimeBetween(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    
    if (startMinutes <= endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // 深夜営業の場合（例：22:00-02:00）
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'レストラン': return Icons.restaurant;
      case 'カフェ': return Icons.coffee;
      case '居酒屋': return Icons.sports_bar;
      case 'ファストフード': return Icons.fastfood;
      case 'ラーメン': return Icons.ramen_dining;
      case '寿司': return Icons.set_meal;
      case '焼肉': return Icons.outdoor_grill;
      case 'スイーツ': return Icons.cake;
      case 'パン屋': return Icons.bakery_dining;
      case 'バー': return Icons.wine_bar;
      default: return Icons.restaurant;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'レストラン': return Colors.orange;
      case 'カフェ': return Colors.brown;
      case '居酒屋': return Colors.red;
      case 'ファストフード': return Colors.amber;
      case 'ラーメン': return Colors.yellow;
      case '寿司': return Colors.blue;
      case '焼肉': return Colors.deepOrange;
      case 'スイーツ': return Colors.pink;
      case 'パン屋': return Colors.deepPurple;
      case 'バー': return Colors.indigo;
      default: return AppColors.primary;
    }
  }
}
```

##### 4.2.4.2 マップフィルタリングシステム
```dart
// フィルタモード列挙型
enum MapFilterMode {
  loyalty,    // 常連度フィルタ
  openOnly,   // 営業中のみ
  category,   // カテゴリ別
}

// マップフィルタ状態管理
class MapFilterState {
  final MapFilterMode filterMode;
  final String selectedCategory;
  final String searchQuery;
  
  const MapFilterState({
    this.filterMode = MapFilterMode.loyalty,
    this.selectedCategory = '',
    this.searchQuery = '',
  });
  
  MapFilterState copyWith({
    MapFilterMode? filterMode,
    String? selectedCategory,
    String? searchQuery,
  }) {
    return MapFilterState(
      filterMode: filterMode ?? this.filterMode,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// フィルタ状態プロバイダー
final mapFilterProvider = StateNotifierProvider<MapFilterNotifier, MapFilterState>((ref) {
  return MapFilterNotifier();
});

class MapFilterNotifier extends StateNotifier<MapFilterState> {
  MapFilterNotifier() : super(const MapFilterState());
  
  void updateFilterMode(MapFilterMode mode) {
    state = state.copyWith(filterMode: mode);
  }
  
  void updateSelectedCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }
  
  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

// 検索状態プロバイダー
final mapSearchProvider = StateNotifierProvider<MapSearchNotifier, String>((ref) {
  return MapSearchNotifier();
});

class MapSearchNotifier extends StateNotifier<String> {
  MapSearchNotifier() : super('');
  
  void updateSearchQuery(String query) {
    state = query;
  }
  
  void clearSearch() {
    state = '';
  }
}

// フィルタされた店舗一覧プロバイダー
final filteredStoresProvider = StreamProvider<List<StoreModel>>((ref) {
  final filterState = ref.watch(mapFilterProvider);
  final searchQuery = ref.watch(mapSearchProvider);
  final currentUser = ref.watch(authStateProvider).value;
  
  return ref.watch(firestoreServiceProvider).getFilteredStores(
    filterMode: filterState.filterMode,
    selectedCategory: filterState.selectedCategory,
    searchQuery: searchQuery,
    userId: currentUser?.uid ?? '',
  );
});

// ユーザーのスタンプ数取得プロバイダー
final userStampCountProvider = StreamProvider.family<int, String>((ref, storeId) {
  final currentUser = ref.watch(authStateProvider).value;
  if (currentUser == null) return Stream.value(0);
  
  return ref.watch(firestoreServiceProvider).getUserStampCount(currentUser.uid, storeId);
});

// 店舗詳細取得プロバイダー
final storeByIdProvider = StreamProvider.family<StoreModel?, String>((ref, storeId) {
  return ref.watch(firestoreServiceProvider).getStoreById(storeId);
});
```

##### 4.2.4.3 FirestoreServiceマップ機能拡張
```dart
extension MapService on FirestoreService {
  // フィルタされた店舗一覧取得
  Stream<List<StoreModel>> getFilteredStores({
    required MapFilterMode filterMode,
    required String selectedCategory,
    required String searchQuery,
    required String userId,
  }) async* {
    Query<Map<String, dynamic>> query = _firestore.collection('stores');
    
    // カテゴリフィルタ
    if (selectedCategory.isNotEmpty) {
      query = query.where('category', isEqualTo: selectedCategory);
    }
    
    // 営業中フィルタ
    if (filterMode == MapFilterMode.openOnly) {
      // 現在時刻での営業中判定は クライアントサイドで実行
    }
    
    await for (final snapshot in query.snapshots()) {
      var stores = snapshot.docs
          .map((doc) => StoreModel.fromJson({...doc.data(), 'storeId': doc.id}))
          .toList();
      
      // 検索フィルタ（クライアントサイド）
      if (searchQuery.isNotEmpty) {
        stores = stores.where((store) {
          return store.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                 store.address.toLowerCase().contains(searchQuery.toLowerCase());
        }).toList();
      }
      
      // 営業中フィルタ（クライアントサイド）
      if (filterMode == MapFilterMode.openOnly) {
        stores = stores.where((store) => _isStoreCurrentlyOpen(store)).toList();
      }
      
      // 常連度フィルタ（必要に応じてスタンプ数で並び替え）
      if (filterMode == MapFilterMode.loyalty && userId.isNotEmpty) {
        // スタンプ数による並び替えは複雑になるため、UI側で処理
      }
      
      yield stores;
    }
  }
  
  // ユーザーのスタンプ数取得
  Stream<int> getUserStampCount(String userId, String storeId) {
    return _firestore
        .collection('stamp_cards')
        .where('userId', isEqualTo: userId)
        .where('storeId', isEqualTo: storeId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return 0;
          final stampCard = StampCardModel.fromJson({
            ...snapshot.docs.first.data(),
            'cardId': snapshot.docs.first.id,
          });
          return stampCard.currentStamps;
        });
  }
  
  // 店舗詳細取得
  Stream<StoreModel?> getStoreById(String storeId) {
    return _firestore
        .collection('stores')
        .doc(storeId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return StoreModel.fromJson({...doc.data()!, 'storeId': doc.id});
        });
  }
  
  // 現在営業中判定
  bool _isStoreCurrentlyOpen(StoreModel store) {
    final now = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(now);
    final weekday = _getWeekdayString(now.weekday);
    
    final todayHours = store.operatingHours[weekday];
    if (todayHours == null) return false;
    
    final openTime = _parseTimeString(todayHours['open']!);
    final closeTime = _parseTimeString(todayHours['close']!);
    
    return _isTimeBetween(currentTime, openTime, closeTime);
  }
  
  String _getWeekdayString(int weekday) {
    const weekdays = {
      1: 'monday', 2: 'tuesday', 3: 'wednesday', 4: 'thursday',
      5: 'friday', 6: 'saturday', 7: 'sunday'
    };
    return weekdays[weekday] ?? 'monday';
  }
  
  TimeOfDay _parseTimeString(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
  
  bool _isTimeBetween(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    
    if (startMinutes <= endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // 深夜営業の場合
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }
}
```

## 5. レベルシステム設計

### 5.1 レベル計算アルゴリズム
```dart
class LevelService {
  // レベルアップに必要な経験値計算
  static int getRequiredExperience(int level) {
    return (100 * math.pow(level, 1.5)).round();
  }
  
  // 経験値からレベルを計算
  static int calculateLevel(int totalExperience) {
    int level = 1;
    int experienceForNextLevel = getRequiredExperience(level + 1);
    
    while (totalExperience >= experienceForNextLevel && level < 100) {
      level++;
      experienceForNextLevel = getRequiredExperience(level + 1);
    }
    
    return level;
  }
  
  // 経験値獲得条件
  static int getExperienceForAction(ExperienceAction action, {int points = 0}) {
    switch (action) {
      case ExperienceAction.pointEarn:
        return points; // 1ポイント = 1経験値
      case ExperienceAction.pointUse:
        return (points * 0.5).round(); // 1ポイント使用 = 0.5経験値
      case ExperienceAction.badgeEarn:
        return 50; // バッジ獲得 = 50経験値（バッジ種別により変動）
      default:
        return 0;
    }
  }
}
```

### 5.2 バッジシステム設計
```dart
class BadgeService {
  static final Map<String, BadgeCondition> badgeConditions = {
    'first_visit': BadgeCondition(
      type: BadgeType.firstVisit,
      target: 1,
      experienceReward: 100,
    ),
    'consecutive_visits_7': BadgeCondition(
      type: BadgeType.consecutiveVisits,
      target: 7,
      experienceReward: 200,
    ),
    'points_total_1000': BadgeCondition(
      type: BadgeType.pointsTotal,
      target: 1000,
      experienceReward: 300,
    ),
  };
  
  static Future<void> checkBadgeProgress(String userId, TransactionModel transaction) async {
    // バッジ進捗チェックロジック
    for (final badge in badgeConditions.entries) {
      await _updateBadgeProgress(userId, badge.key, badge.value, transaction);
    }
  }
}
```

## 6. セキュアQRコード機能設計

### 6.1 JWT ベース時間制限付きQRコード
```dart
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class SecureQRService {
  // JWTシークレット（Firebase Functions環境変数から取得）
  static const String _jwtSecret = 'your-super-secure-jwt-secret-key-here';
  
  // QRコードの有効期限（60秒）
  static const int _qrValiditySeconds = 60;
  
  // 時間窓の間隔（60秒）
  static const int _timeWindowSeconds = 60;

  /// セキュアなユーザー用QRコード生成（ポイント獲得用）
  static String generateSecureUserQRCode(String userId) {
    final currentTimeWindow = _getCurrentTimeWindow();
    
    final payload = {
      'type': 'user_point_earn',
      'userId': userId,
      'timeWindow': currentTimeWindow,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000, // issued at
      'exp': (DateTime.now().millisecondsSinceEpoch ~/ 1000) + _qrValiditySeconds, // expires
      'nonce': _generateNonce(), // 重複防止のランダム値
    };
    
    final jwt = _generateJWT(payload);
    return jwt;
  }
  
  /// セキュアな店舗用QRコード生成（ポイント利用用）
  static String generateSecureStoreQRCode(String storeId) {
    final currentTimeWindow = _getCurrentTimeWindow();
    
    final payload = {
      'type': 'store_point_use',
      'storeId': storeId,
      'timeWindow': currentTimeWindow,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp': (DateTime.now().millisecondsSinceEpoch ~/ 1000) + _qrValiditySeconds,
      'nonce': _generateNonce(),
    };
    
    final jwt = _generateJWT(payload);
    return jwt;
  }

  /// QRコード検証・処理
  static Future<QRResult> processSecureQRCode(String jwtToken, String readerId) async {
    try {
      // JWTの基本検証
      if (!_isJWTValid(jwtToken)) {
        return QRResult.error('無効なQRコードです');
      }
      
      // トークンをデコード
      final payload = _decodeJWT(jwtToken);
      if (payload == null) {
        return QRResult.error('QRコードの解析に失敗しました');
      }
      
      // 有効期限チェック
      final exp = payload['exp'] as int;
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (currentTime > exp) {
        return QRResult.error('QRコードの有効期限が切れています');
      }
      
      // 時間窓の検証
      final qrTimeWindow = payload['timeWindow'] as int;
      final currentTimeWindow = _getCurrentTimeWindow();
      
      // 現在の時間窓または直前の時間窓のみ有効（60秒の猶予）
      if (qrTimeWindow != currentTimeWindow && qrTimeWindow != (currentTimeWindow - 1)) {
        return QRResult.error('QRコードの有効期限が切れています');
      }
      
      // 重複使用チェック（Firebase Functionsで実装）
      final nonce = payload['nonce'] as String;
      final isUsed = await _checkQRUsage(nonce, readerId);
      if (isUsed) {
        return QRResult.error('既に使用されたQRコードです');
      }
      
      // QRコードタイプに基づく処理
      switch (payload['type']) {
        case 'user_point_earn':
          // 使用履歴を記録
          await _recordQRUsage(nonce, readerId, payload['userId']);
          return QRResult.userPointEarn(payload['userId']);
          
        case 'store_point_use':
          // 使用履歴を記録
          await _recordQRUsage(nonce, readerId, payload['storeId']);
          return QRResult.storePointUse(payload['storeId']);
          
        default:
          return QRResult.error('未知のQRコードタイプです');
      }
      
    } catch (e) {
      return QRResult.error('QRコードの処理中にエラーが発生しました: $e');
    }
  }

  /// 現在の時間窓を取得（60秒単位）
  static int _getCurrentTimeWindow() {
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return currentTime ~/ _timeWindowSeconds;
  }

  /// ランダムなnonce値を生成
  static String _generateNonce() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// JWT生成
  static String _generateJWT(Map<String, dynamic> payload) {
    // ヘッダー
    final header = {
      'alg': 'HS256',
      'typ': 'JWT',
    };
    
    // Base64エンコード
    final encodedHeader = base64Url.encode(utf8.encode(jsonEncode(header)));
    final encodedPayload = base64Url.encode(utf8.encode(jsonEncode(payload)));
    
    // 署名生成
    final signatureInput = '$encodedHeader.$encodedPayload';
    final signature = _generateSignature(signatureInput);
    
    return '$encodedHeader.$encodedPayload.$signature';
  }

  /// JWT検証
  static bool _isJWTValid(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      
      // 署名検証
      final signatureInput = '${parts[0]}.${parts[1]}';
      final expectedSignature = _generateSignature(signatureInput);
      
      return parts[2] == expectedSignature;
    } catch (e) {
      return false;
    }
  }

  /// JWTデコード
  static Map<String, dynamic>? _decodeJWT(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      final payloadJson = utf8.decode(base64Url.decode(parts[1]));
      return jsonDecode(payloadJson) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// HMAC署名生成
  static String _generateSignature(String input) {
    final key = utf8.encode(_jwtSecret);
    final bytes = utf8.encode(input);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return base64Url.encode(digest.bytes);
  }

  /// QRコード使用履歴チェック（Firebase Functions）
  static Future<bool> _checkQRUsage(String nonce, String readerId) async {
    // Firebase Functions呼び出し
    try {
      final response = await _callFirebaseFunction('checkQRUsage', {
        'nonce': nonce,
        'readerId': readerId,
      });
      
      return response['used'] as bool? ?? false;
    } catch (e) {
      // エラーの場合は安全側に倒して使用済みとして扱う
      return true;
    }
  }

  /// QRコード使用履歴記録（Firebase Functions）
  static Future<void> _recordQRUsage(String nonce, String readerId, String targetId) async {
    try {
      await _callFirebaseFunction('recordQRUsage', {
        'nonce': nonce,
        'readerId': readerId,
        'targetId': targetId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      // ログ記録失敗は処理を継続
      print('QR使用履歴の記録に失敗: $e');
    }
  }

  /// Firebase Functions呼び出しヘルパー
  static Future<Map<String, dynamic>> _callFirebaseFunction(String functionName, Map<String, dynamic> data) async {
    // Firebase Functions への HTTP リクエスト実装
    // 実際の実装では firebase_functions パッケージまたは http パッケージを使用
    throw UnimplementedError('Firebase Functions呼び出しの実装が必要');
  }
}

/// QRコード結果クラス
class QRResult {
  final QRResultType type;
  final String? targetId;
  final String? error;

  QRResult._(this.type, this.targetId, this.error);

  factory QRResult.userPointEarn(String userId) => QRResult._(QRResultType.userPointEarn, userId, null);
  factory QRResult.storePointUse(String storeId) => QRResult._(QRResultType.storePointUse, storeId, null);
  factory QRResult.error(String message) => QRResult._(QRResultType.error, null, message);

  bool get isSuccess => type != QRResultType.error;
  bool get isError => type == QRResultType.error;
}

enum QRResultType {
  userPointEarn,
  storePointUse,
  error,
}
```

### 6.2 動的QRコード表示Widget
```dart
class DynamicQRCodeWidget extends StatefulWidget {
  final String userId;
  final String storeId;
  final QRCodeType qrType;

  const DynamicQRCodeWidget({
    Key? key,
    required this.qrType,
    this.userId = '',
    this.storeId = '',
  }) : super(key: key);

  @override
  _DynamicQRCodeWidgetState createState() => _DynamicQRCodeWidgetState();
}

class _DynamicQRCodeWidgetState extends State<DynamicQRCodeWidget> {
  Timer? _refreshTimer;
  String _currentQRData = '';
  int _countdown = 60;

  @override
  void initState() {
    super.initState();
    _generateQRCode();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _generateQRCode() {
    switch (widget.qrType) {
      case QRCodeType.userPointEarn:
        _currentQRData = SecureQRService.generateSecureUserQRCode(widget.userId);
        break;
      case QRCodeType.storePointUse:
        _currentQRData = SecureQRService.generateSecureStoreQRCode(widget.storeId);
        break;
    }
    
    // カウントダウンリセット
    setState(() {
      _countdown = 60;
    });
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdown--;
      });

      if (_countdown <= 0) {
        _generateQRCode();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // QRコード表示
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: QrImageView(
            data: _currentQRData,
            version: QrVersions.auto,
            size: 200.0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
        ),
        
        const SizedBox(height: 20),
        
        // カウントダウンタイマー
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _countdown <= 10 ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _countdown <= 10 ? Colors.red : Colors.blue,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer,
                size: 16,
                color: _countdown <= 10 ? Colors.red : Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(
                'あと ${_countdown}秒で更新',
                style: TextStyle(
                  fontSize: 14,
                  color: _countdown <= 10 ? Colors.red : Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // セキュリティ説明
        Text(
          'セキュリティのため60秒ごとにQRコードが自動更新されます',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        
        // 手動更新ボタン
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: _generateQRCode,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('手動更新'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

enum QRCodeType {
  userPointEarn,
  storePointUse,
}
```

### 6.3 Firebase Functions（サーバーサイド検証）
```typescript
// Firebase Functions での QR コード検証
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as jwt from 'jsonwebtoken';

const JWT_SECRET = functions.config().security.jwt_secret;

// QRコード使用履歴チェック
export const checkQRUsage = functions.https.onCall(async (data, context) => {
  const { nonce, readerId } = data;
  
  // 認証チェック
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'ユーザー認証が必要です');
  }
  
  try {
    // Firestore でnonce の使用履歴をチェック
    const usageDoc = await admin.firestore()
      .collection('qr_usage_history')
      .doc(`${nonce}_${readerId}`)
      .get();
    
    return { used: usageDoc.exists };
  } catch (error) {
    console.error('QR使用履歴チェックエラー:', error);
    throw new functions.https.HttpsError('internal', 'サーバーエラーが発生しました');
  }
});

// QRコード使用履歴記録
export const recordQRUsage = functions.https.onCall(async (data, context) => {
  const { nonce, readerId, targetId, timestamp } = data;
  
  // 認証チェック
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'ユーザー認証が必要です');
  }
  
  try {
    // 使用履歴を記録
    await admin.firestore()
      .collection('qr_usage_history')
      .doc(`${nonce}_${readerId}`)
      .set({
        nonce,
        readerId,
        targetId,
        timestamp,
        userId: context.auth.uid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    
    return { success: true };
  } catch (error) {
    console.error('QR使用履歴記録エラー:', error);
    throw new functions.https.HttpsError('internal', 'サーバーエラーが発生しました');
  }
});

// QRコード検証（サーバーサイド）
export const verifySecureQR = functions.https.onCall(async (data, context) => {
  const { token, readerId } = data;
  
  try {
    // JWT検証
    const decoded = jwt.verify(token, JWT_SECRET) as any;
    
    // 有効期限チェック（追加の安全策）
    const currentTime = Math.floor(Date.now() / 1000);
    if (currentTime > decoded.exp) {
      throw new Error('QRコードの有効期限が切れています');
    }
    
    // 時間窓チェック
    const currentTimeWindow = Math.floor(currentTime / 60);
    if (decoded.timeWindow !== currentTimeWindow && decoded.timeWindow !== (currentTimeWindow - 1)) {
      throw new Error('QRコードの有効期限が切れています');
    }
    
    // 重複使用チェック
    const usageDoc = await admin.firestore()
      .collection('qr_usage_history')
      .doc(`${decoded.nonce}_${readerId}`)
      .get();
    
    if (usageDoc.exists) {
      throw new Error('既に使用されたQRコードです');
    }
    
    return {
      valid: true,
      type: decoded.type,
      targetId: decoded.type === 'user_point_earn' ? decoded.userId : decoded.storeId,
      nonce: decoded.nonce,
    };
    
  } catch (error) {
    console.error('QR検証エラー:', error);
    throw new functions.https.HttpsError('invalid-argument', error.message || 'QRコードが無効です');
  }
});
```

### 6.4 QRコード読み取りフロー詳細設計

#### 6.4.1 店舗用アプリ - 支払い金額入力画面
```dart
class PaymentAmountInputScreen extends ConsumerStatefulWidget {
  final String scannedUserId;
  
  const PaymentAmountInputScreen({
    Key? key,
    required this.scannedUserId,
  }) : super(key: key);

  @override
  ConsumerState<PaymentAmountInputScreen> createState() => _PaymentAmountInputScreenState();
}

class _PaymentAmountInputScreenState extends ConsumerState<PaymentAmountInputScreen> {
  final TextEditingController _amountController = TextEditingController();
  double _amount = 0.0;
  int _calculatedPoints = 0;

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(currentStoreProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('支払い金額入力'),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // お客様情報表示
            _buildCustomerInfo(),
            const SizedBox(height: 32),
            
            // 支払い金額入力
            _buildAmountInput(),
            const SizedBox(height: 24),
            
            // 獲得ポイント表示
            _buildPointsPreview(),
            const SizedBox(height: 32),
            
            // 確定ボタン
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: Colors.blue, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'お客様',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  'ユーザーID: ${widget.scannedUserId}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '支払い金額',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            prefixText: '¥ ',
            prefixStyle: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            hintText: '0',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
          ),
          onChanged: (value) {
            setState(() {
              _amount = double.tryParse(value) ?? 0.0;
              _calculatedPoints = (_amount ~/ 100); // 100円 = 1ポイント
            });
          },
        ),
      ],
    );
  }

  Widget _buildPointsPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.card_giftcard,
            color: AppColors.primary,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '獲得予定ポイント',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_calculatedPoints}P',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _amount > 0 ? _onConfirm : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          '確定',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _onConfirm() {
    // ユーザーアプリに獲得ポイント確認画面を表示させるため、
    // Firebase Functions を通じて通知を送信
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => PointAwardConfirmationScreen(
          userId: widget.scannedUserId,
          amount: _amount,
          points: _calculatedPoints,
        ),
      ),
    );
  }
}
```

#### 6.4.2 ユーザーアプリ - 獲得ポイント確認画面
```dart
class PointEarnConfirmationScreen extends ConsumerStatefulWidget {
  final double amount;
  final int points;
  final String storeId;
  
  const PointEarnConfirmationScreen({
    Key? key,
    required this.amount,
    required this.points,
    required this.storeId,
  }) : super(key: key);

  @override
  ConsumerState<PointEarnConfirmationScreen> createState() => _PointEarnConfirmationScreenState();
}

class _PointEarnConfirmationScreenState extends ConsumerState<PointEarnConfirmationScreen> {
  @override
  Widget build(BuildContext context) {
    final store = ref.watch(storeProvider(widget.storeId));
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('ポイント獲得確認'),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 店舗情報
                  store.when(
                    data: (storeData) => _buildStoreInfo(storeData),
                    loading: () => const CircularProgressIndicator(),
                    error: (error, _) => const Text('店舗情報の取得に失敗しました'),
                  ),
                  const SizedBox(height: 32),
                  
                  // 支払い金額
                  _buildAmountInfo(),
                  const SizedBox(height: 24),
                  
                  // 獲得ポイント
                  _buildPointsInfo(),
                  const SizedBox(height: 32),
                  
                  // 説明テキスト
                  Text(
                    'ポイントを獲得しますか？',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // ボタン
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreInfo(StoreModel store) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              store.images.isNotEmpty ? store.images.first : '',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.store),
                  ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  store.address,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'お支払い金額',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '¥${NumberFormat('#,###').format(widget.amount)}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '獲得ポイント',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              const Icon(
                Icons.card_giftcard,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.points}P',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _onDecline,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '辞退',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _onAccept,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '獲得',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onDecline() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  void _onAccept() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => PointEarnAnimationScreen(
          amount: widget.amount,
          points: widget.points,
          storeId: widget.storeId,
        ),
      ),
    );
  }
}
```

#### 6.4.3 ポイント獲得アニメーション画面
```dart
class PointEarnAnimationScreen extends ConsumerStatefulWidget {
  final double amount;
  final int points;
  final String storeId;
  
  const PointEarnAnimationScreen({
    Key? key,
    required this.amount,
    required this.points,
    required this.storeId,
  }) : super(key: key);

  @override
  ConsumerState<PointEarnAnimationScreen> createState() => _PointEarnAnimationScreenState();
}

class _PointEarnAnimationScreenState extends ConsumerState<PointEarnAnimationScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _pointsAnimationController;
  late AnimationController _totalPointsAnimationController;
  late Animation<double> _pointsScaleAnimation;
  late Animation<int> _totalPointsCountAnimation;
  
  int _previousTotalPoints = 0;
  int _newTotalPoints = 0;
  bool _animationCompleted = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadUserPoints();
    _performPointsTransaction();
  }

  void _setupAnimations() {
    _pointsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _totalPointsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pointsScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pointsAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  void _loadUserPoints() async {
    final user = ref.read(userProvider);
    if (user != null) {
      setState(() {
        _previousTotalPoints = user.totalPoints;
        _newTotalPoints = _previousTotalPoints + widget.points;
      });

      _totalPointsCountAnimation = IntTween(
        begin: _previousTotalPoints,
        end: _newTotalPoints,
      ).animate(CurvedAnimation(
        parent: _totalPointsAnimationController,
        curve: Curves.easeOutCubic,
      ));
    }
  }

  void _performPointsTransaction() async {
    // ポイント獲得処理をFirebase Functionsで実行
    try {
      await ref.read(pointServiceProvider).awardPoints(
        userId: ref.read(userProvider)!.userId,
        storeId: widget.storeId,
        points: widget.points,
        amount: widget.amount,
      );

      // アニメーション開始
      _pointsAnimationController.forward();
      
      Timer(const Duration(milliseconds: 800), () {
        _totalPointsAnimationController.forward().then((_) {
          setState(() {
            _animationCompleted = true;
          });
        });
      });

    } catch (e) {
      // エラーハンドリング
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ポイント獲得に失敗しました: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ポイント獲得表示
                    AnimatedBuilder(
                      animation: _pointsScaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pointsScaleAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.card_giftcard,
                                  size: 64,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '+${widget.points}P',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const Text(
                                  '獲得！',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // 総ポイント数アニメーション
                    AnimatedBuilder(
                      animation: _totalPointsCountAnimation,
                      builder: (context, child) {
                        return Column(
                          children: [
                            const Text(
                              '総ポイント',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${NumberFormat('#,###').format(_totalPointsCountAnimation.value)}P',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // 次へボタン
              if (_animationCompleted)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _goToStampScreen,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '次へ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _goToStampScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => StampPresentationScreen(storeId: widget.storeId),
      ),
    );
  }

  @override
  void dispose() {
    _pointsAnimationController.dispose();
    _totalPointsAnimationController.dispose();
    super.dispose();
  }
}
```

#### 6.4.4 スタンプ押印画面
```dart
class StampPresentationScreen extends ConsumerStatefulWidget {
  final String storeId;
  
  const StampPresentationScreen({
    Key? key,
    required this.storeId,
  }) : super(key: key);

  @override
  ConsumerState<StampPresentationScreen> createState() => _StampPresentationScreenState();
}

class _StampPresentationScreenState extends ConsumerState<StampPresentationScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _stampAnimationController;
  late Animation<double> _stampScaleAnimation;
  late Animation<double> _stampOpacityAnimation;
  bool _stampCompleted = false;

  @override
  void initState() {
    super.initState();
    _setupStampAnimation();
    _performStamping();
  }

  void _setupStampAnimation() {
    _stampAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _stampScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _stampAnimationController,
      curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
    ));

    _stampOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _stampAnimationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));
  }

  void _performStamping() async {
    try {
      // スタンプ記録処理
      await ref.read(stampServiceProvider).addStamp(
        userId: ref.read(userProvider)!.userId,
        storeId: widget.storeId,
      );

      // アニメーション開始
      _stampAnimationController.forward().then((_) {
        setState(() {
          _stampCompleted = true;
        });
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('スタンプの記録に失敗しました: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(storeProvider(widget.storeId));
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 店舗情報
                    store.when(
                      data: (storeData) => Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              storeData.images.isNotEmpty ? storeData.images.first : '',
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: 120,
                                    height: 120,
                                    color: Colors.grey.shade300,
                                    child: const Icon(Icons.store, size: 60),
                                  ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            storeData.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (error, _) => const Text('店舗情報の取得に失敗しました'),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // スタンプ押印アニメーション
                    AnimatedBuilder(
                      animation: _stampAnimationController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _stampOpacityAnimation.value,
                          child: Transform.scale(
                            scale: _stampScaleAnimation.value,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 4,
                                ),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check,
                                    size: 60,
                                    color: AppColors.primary,
                                  ),
                                  Text(
                                    'スタンプ',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    const Text(
                      'スタンプを獲得しました！',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 次へボタン
              if (_stampCompleted)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _goToBadgeScreen,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '次へ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _goToBadgeScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => BadgeAwardScreen(storeId: widget.storeId),
      ),
    );
  }

  @override
  void dispose() {
    _stampAnimationController.dispose();
    super.dispose();
  }
}
```

#### 6.4.5 バッジ獲得アニメーション画面
```dart
class BadgeAwardScreen extends ConsumerStatefulWidget {
  final String storeId;
  
  const BadgeAwardScreen({
    Key? key,
    required this.storeId,
  }) : super(key: key);

  @override
  ConsumerState<BadgeAwardScreen> createState() => _BadgeAwardScreenState();
}

class _BadgeAwardScreenState extends ConsumerState<BadgeAwardScreen>
    with TickerProviderStateMixin {
  
  List<BadgeModel> _newlyAwardedBadges = [];
  int _currentBadgeIndex = 0;
  late AnimationController _badgeAnimationController;
  late Animation<double> _badgeRotationAnimation;
  late Animation<double> _badgeScaleAnimation;
  bool _allBadgesShown = false;

  @override
  void initState() {
    super.initState();
    _setupBadgeAnimation();
    _checkAndAwardBadges();
  }

  void _setupBadgeAnimation() {
    _badgeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _badgeRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _badgeAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _badgeScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _badgeAnimationController,
      curve: const Interval(0.0, 0.8, curve: Curves.bounceOut),
    ));
  }

  void _checkAndAwardBadges() async {
    try {
      // バッジ獲得条件チェック
      final badges = await ref.read(badgeServiceProvider).checkAndAwardBadges(
        userId: ref.read(userProvider)!.userId,
        storeId: widget.storeId,
      );

      setState(() {
        _newlyAwardedBadges = badges;
      });

      if (_newlyAwardedBadges.isNotEmpty) {
        _showNextBadge();
      } else {
        // バッジ獲得がない場合は直接ホームに遷移
        _goToHome();
      }

    } catch (e) {
      // エラーが発生してもホームに遷移
      _goToHome();
    }
  }

  void _showNextBadge() {
    if (_currentBadgeIndex < _newlyAwardedBadges.length) {
      _badgeAnimationController.reset();
      _badgeAnimationController.forward().then((_) {
        // 2秒後に次のバッジまたは完了画面
        Timer(const Duration(seconds: 2), () {
          setState(() {
            _currentBadgeIndex++;
          });
          
          if (_currentBadgeIndex < _newlyAwardedBadges.length) {
            _showNextBadge();
          } else {
            setState(() {
              _allBadgesShown = true;
            });
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_newlyAwardedBadges.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentBadge = _currentBadgeIndex < _newlyAwardedBadges.length
        ? _newlyAwardedBadges[_currentBadgeIndex]
        : _newlyAwardedBadges.last;

    return Scaffold(
      backgroundColor: Colors.amber.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // バッジ獲得アニメーション
                    AnimatedBuilder(
                      animation: _badgeAnimationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _badgeScaleAnimation.value,
                          child: Transform.rotate(
                            angle: _badgeRotationAnimation.value * 3.14159,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _getBadgeIcon(currentBadge.type),
                                    size: 60,
                                    color: Colors.white,
                                  ),
                                  const Text(
                                    'バッジ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // バッジ名
                    Text(
                      currentBadge.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // バッジ説明
                    Text(
                      currentBadge.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // 進行状況表示（複数バッジの場合）
                    if (_newlyAwardedBadges.length > 1)
                      Text(
                        '${_currentBadgeIndex + 1} / ${_newlyAwardedBadges.length}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
              
              // 確認ボタン（全て表示完了後）
              if (_allBadgesShown)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _goToHome,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '確認',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getBadgeIcon(String badgeType) {
    switch (badgeType) {
      case 'first_visit':
        return Icons.star;
      case 'regular_customer':
        return Icons.favorite;
      case 'point_collector':
        return Icons.card_giftcard;
      case 'explorer':
        return Icons.explore;
      default:
        return Icons.emoji_events;
    }
  }

  void _goToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _badgeAnimationController.dispose();
    super.dispose();
  }
}
```

### 6.5 ポイント利用フロー詳細設計

#### 6.5.1 QRコード読み取り画面（カメラタブ）
```dart
class QRScanScreen extends ConsumerStatefulWidget {
  const QRScanScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends ConsumerState<QRScanScreen> 
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  QRViewController? _qrController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QRコード'),
        backgroundColor: AppColors.primary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'マイQRコード', icon: Icon(Icons.qr_code)),
            Tab(text: 'カメラで読み取り', icon: Icon(Icons.camera_alt)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // マイQRコード表示画面
          _buildMyQRCodeTab(),
          
          // カメラで読み取り画面
          _buildCameraScanTab(),
        ],
      ),
    );
  }

  Widget _buildMyQRCodeTab() {
    // 既存のユーザーQRコード表示
    return const DynamicQRWidget(qrType: QRCodeType.userPointEarn);
  }

  Widget _buildCameraScanTab() {
    return Column(
      children: [
        Expanded(
          child: QRView(
            key: GlobalKey(debugLabel: 'QR'),
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: AppColors.primary,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 10,
              cutOutSize: 300,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.black87,
          child: Column(
            children: [
              const Text(
                '店舗のQRコードを読み取ってください',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'ポイント利用時は店頭のQRコードまたは店舗アプリのQRコードをスキャンしてください',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      _qrController = controller;
    });

    controller.scannedDataStream.listen((scanData) {
      _handleQRScanned(scanData);
    });
  }

  void _handleQRScanned(Barcode scanData) async {
    if (scanData.code == null) return;

    // QRコードの検証と処理
    try {
      final qrResult = await ref.read(secureQRServiceProvider)
          .processSecureQRCode(scanData.code!, 'user_scanner');

      if (qrResult.type == 'store_point_use') {
        // 店舗QRコード読み取り成功 → ポイント利用画面へ
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PointUsageInputScreen(
              storeId: qrResult.targetId,
            ),
          ),
        );
      } else {
        _showErrorDialog('このQRコードはポイント利用に使用できません');
      }

    } catch (e) {
      _showErrorDialog('QRコードの読み取りに失敗しました: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エラー'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _qrController?.dispose();
    _tabController.dispose();
    super.dispose();
  }
}
```

#### 6.5.2 支払いポイント入力画面
```dart
class PointUsageInputScreen extends ConsumerStatefulWidget {
  final String storeId;
  
  const PointUsageInputScreen({
    Key? key,
    required this.storeId,
  }) : super(key: key);

  @override
  ConsumerState<PointUsageInputScreen> createState() => _PointUsageInputScreenState();
}

class _PointUsageInputScreenState extends ConsumerState<PointUsageInputScreen> {
  final TextEditingController _pointsController = TextEditingController();
  int _pointsToUse = 0;
  bool _isRotated = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final store = ref.watch(storeProvider(widget.storeId));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('ポイント利用'),
        backgroundColor: AppColors.primary,
      ),
      body: user == null 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 店舗情報
                store.when(
                  data: (storeData) => _buildStoreInfo(storeData),
                  loading: () => const CircularProgressIndicator(),
                  error: (error, _) => const Text('店舗情報の取得に失敗しました'),
                ),
                const SizedBox(height: 24),
                
                // 利用可能ポイント表示
                _buildAvailablePoints(user.availablePoints),
                const SizedBox(height: 32),
                
                // ポイント入力フィールド
                _buildPointsInput(),
                const SizedBox(height: 32),
                
                // 確定ボタン
                _buildConfirmButton(),
              ],
            ),
          ),
    );
  }

  Widget _buildStoreInfo(StoreModel store) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              store.images.isNotEmpty ? store.images.first : '',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.store),
                  ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  store.address,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailablePoints(int availablePoints) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_wallet,
            color: AppColors.primary,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '利用可能ポイント',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${NumberFormat('#,###').format(availablePoints)}P',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '利用ポイント',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          transform: _isRotated 
            ? (Matrix4.identity()..rotateZ(3.14159)) // 180度回転
            : Matrix4.identity(),
          child: TextFormField(
            controller: _pointsController,
            keyboardType: TextInputType.number,
            textAlign: _isRotated ? TextAlign.center : TextAlign.left,
            style: TextStyle(
              fontSize: _isRotated ? 48 : 24,
              fontWeight: FontWeight.bold,
              color: _isRotated ? Colors.red : AppColors.text,
            ),
            decoration: InputDecoration(
              suffixText: 'P',
              suffixStyle: TextStyle(
                fontSize: _isRotated ? 48 : 24,
                fontWeight: FontWeight.bold,
                color: _isRotated ? Colors.red : AppColors.primary,
              ),
              hintText: '0',
              hintStyle: TextStyle(
                fontSize: _isRotated ? 48 : 24,
                color: Colors.grey.shade400,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  width: _isRotated ? 4 : 2,
                  color: _isRotated ? Colors.red : Colors.grey,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _isRotated ? Colors.red : AppColors.primary,
                  width: _isRotated ? 4 : 2,
                ),
              ),
              contentPadding: EdgeInsets.all(_isRotated ? 24 : 16),
            ),
            enabled: !_isRotated,
            onChanged: (value) {
              setState(() {
                _pointsToUse = int.tryParse(value) ?? 0;
              });
            },
          ),
        ),
        if (_isRotated)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              '店舗スタッフに画面をお見せください',
              style: TextStyle(
                fontSize: 16,
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    final user = ref.watch(userProvider);
    final canUsePoints = user != null && 
                        _pointsToUse > 0 && 
                        _pointsToUse <= user.availablePoints;

    if (_isRotated) {
      // 回転後は店舗スタッフ用の確定ボタン
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _executePointUsage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'ポイント利用実行',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() {
                _isRotated = false;
              });
            },
            child: const Text(
              '戻る',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      );
    } else {
      // 通常の確定ボタン
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: canUsePoints ? _confirmPointUsage : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            '確定',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
  }

  void _confirmPointUsage() {
    setState(() {
      _isRotated = true;
    });
  }

  void _executePointUsage() async {
    try {
      final user = ref.read(userProvider)!;
      
      // Firebase Functionsでポイント利用処理
      await ref.read(pointServiceProvider).usePoints(
        userId: user.userId,
        storeId: widget.storeId,
        points: _pointsToUse,
      );

      // 成功ダイアログ表示後、ホームに戻る
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('ポイント利用完了'),
          content: Text('${_pointsToUse}ポイントを利用しました。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ダイアログを閉じる
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
                );
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ポイント利用に失敗しました: $e')),
      );
      setState(() {
        _isRotated = false;
      });
    }
  }
}
```

#### 6.5.3 ポイント利用履歴データモデル
```dart
// ユーザー側のポイント利用履歴
class UserPointUsageHistory {
  final String usageId;
  final String userId;
  final String storeId;
  final String storeName;
  final int pointsUsed;
  final DateTime usedAt;
  final String status; // 'completed', 'pending', 'failed'

  const UserPointUsageHistory({
    required this.usageId,
    required this.userId,
    required this.storeId,
    required this.storeName,
    required this.pointsUsed,
    required this.usedAt,
    required this.status,
  });

  factory UserPointUsageHistory.fromJson(Map<String, dynamic> json) {
    return UserPointUsageHistory(
      usageId: json['usageId'],
      userId: json['userId'],
      storeId: json['storeId'],
      storeName: json['storeName'],
      pointsUsed: json['pointsUsed'],
      usedAt: (json['usedAt'] as Timestamp).toDate(),
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'usageId': usageId,
      'userId': userId,
      'storeId': storeId,
      'storeName': storeName,
      'pointsUsed': pointsUsed,
      'usedAt': Timestamp.fromDate(usedAt),
      'status': status,
    };
  }
}

// 店舗側のポイント利用履歴
class StorePointUsageHistory {
  final String usageId;
  final String storeId;
  final String userId;
  final String? userName; // ユーザー名（取得可能な場合）
  final int pointsUsed;
  final DateTime usedAt;
  final String status;
  final double? equivalentAmount; // ポイントの金額換算値

  const StorePointUsageHistory({
    required this.usageId,
    required this.storeId,
    required this.userId,
    this.userName,
    required this.pointsUsed,
    required this.usedAt,
    required this.status,
    this.equivalentAmount,
  });

  factory StorePointUsageHistory.fromJson(Map<String, dynamic> json) {
    return StorePointUsageHistory(
      usageId: json['usageId'],
      storeId: json['storeId'],
      userId: json['userId'],
      userName: json['userName'],
      pointsUsed: json['pointsUsed'],
      usedAt: (json['usedAt'] as Timestamp).toDate(),
      status: json['status'],
      equivalentAmount: json['equivalentAmount']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'usageId': usageId,
      'storeId': storeId,
      'userId': userId,
      'userName': userName,
      'pointsUsed': pointsUsed,
      'usedAt': Timestamp.fromDate(usedAt),
      'status': status,
      'equivalentAmount': equivalentAmount,
    };
  }
}
```

#### 6.5.4 ポイント利用処理サービス
```dart
class PointUsageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> usePoints({
    required String userId,
    required String storeId,
    required int points,
  }) async {
    final usageId = _firestore.collection('user_point_usage').doc().id;
    final now = Timestamp.now();

    try {
      await _firestore.runTransaction((transaction) async {
        // ユーザーの利用可能ポイントを確認・減算
        final userRef = _firestore.collection('users').doc(userId);
        final userDoc = await transaction.get(userRef);
        
        if (!userDoc.exists) {
          throw Exception('ユーザーが見つかりません');
        }

        final userData = userDoc.data()!;
        final availablePoints = userData['availablePoints'] as int;

        if (availablePoints < points) {
          throw Exception('利用可能ポイントが不足しています');
        }

        // ユーザーのポイントを減算
        transaction.update(userRef, {
          'availablePoints': availablePoints - points,
          'updatedAt': now,
        });

        // 店舗情報を取得
        final storeRef = _firestore.collection('stores').doc(storeId);
        final storeDoc = await transaction.get(storeRef);
        final storeName = storeDoc.exists ? storeDoc.data()!['name'] : 'Unknown Store';

        // ユーザー側のポイント利用履歴を記録
        final userUsageRef = _firestore.collection('user_point_usage').doc(usageId);
        transaction.set(userUsageRef, {
          'usageId': usageId,
          'userId': userId,
          'storeId': storeId,
          'storeName': storeName,
          'pointsUsed': points,
          'usedAt': now,
          'status': 'completed',
        });

        // 店舗側のポイント利用履歴を記録
        final storeUsageRef = _firestore.collection('store_point_usage').doc(usageId);
        transaction.set(storeUsageRef, {
          'usageId': usageId,
          'storeId': storeId,
          'userId': userId,
          'userName': userData['displayName'], // 取得可能な場合
          'pointsUsed': points,
          'usedAt': now,
          'status': 'completed',
          'equivalentAmount': points.toDouble(), // 1ポイント = 1円として換算
        });

        // 取引履歴に記録
        final transactionRef = _firestore.collection('transactions').doc();
        transaction.set(transactionRef, {
          'userId': userId,
          'storeId': storeId,
          'points': points,
          'type': 'redeem',
          'createdAt': now,
        });
      });

    } catch (e) {
      print('ポイント利用エラー: $e');
      rethrow;
    }
  }

  // ユーザー側のポイント利用履歴取得
  Stream<List<UserPointUsageHistory>> getUserPointUsageHistory(String userId) {
    return _firestore
        .collection('user_point_usage')
        .where('userId', isEqualTo: userId)
        .orderBy('usedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserPointUsageHistory.fromJson(doc.data()))
            .toList());
  }

  // 店舗側のポイント利用履歴取得
  Stream<List<StorePointUsageHistory>> getStorePointUsageHistory(String storeId) {
    return _firestore
        .collection('store_point_usage')
        .where('storeId', isEqualTo: storeId)
        .orderBy('usedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StorePointUsageHistory.fromJson(doc.data()))
            .toList());
  }
}
```

#### 6.5.5 Riverpodプロバイダー
```dart
// ポイント利用サービスプロバイダー
final pointUsageServiceProvider = Provider<PointUsageService>((ref) {
  return PointUsageService();
});

// ユーザー側ポイント利用履歴プロバイダー
final userPointUsageHistoryProvider = StreamProvider.family<List<UserPointUsageHistory>, String>((ref, userId) {
  return ref.watch(pointUsageServiceProvider).getUserPointUsageHistory(userId);
});

// 店舗側ポイント利用履歴プロバイダー
final storePointUsageHistoryProvider = StreamProvider.family<List<StorePointUsageHistory>, String>((ref, storeId) {
  return ref.watch(pointUsageServiceProvider).getStorePointUsageHistory(storeId);
});
```

## 7. プラン・課金システム設計

### 7.1 プラン制限チェック
```dart
class PlanService {
  static bool canIssuePoints(StoreModel store, int pointsToIssue) {
    final limit = _getPlanLimit(store.plan);
    return (store.monthlyPointsIssued + pointsToIssue) <= limit;
  }
  
  static int _getPlanLimit(String plan) {
    switch (plan) {
      case 'small':
        return 1500;
      case 'standard':
        return 5000;
      default:
        return 1500;
    }
  }
  
  static bool hasPremiumFeatures(StoreModel store) {
    return store.plan.contains('premium');
  }
  
  // 超過課金計算
  static double calculateOverageFee(int overagePoints) {
    return overagePoints * 1.1; // 1P = 1.1円
  }
  
  // 利用手数料計算
  static double calculateUsageFee(int pointsUsed) {
    return pointsUsed * 0.01; // 1%手数料
  }
}
```

## 8. セキュリティ設計

### 8.1 認証・認可
```dart
class SecurityService {
  // 会社管理者権限チェック
  static Future<bool> isCompanyAdmin(String userId) async {
    final store = await FirestoreService.getStoreByOwnerId(userId);
    return store?.isCompanyAdmin ?? false;
  }
  
  // データアクセス権限チェック
  static bool canAccessStoreData(String userId, String storeId) {
    // Firebase Security Rulesと連携
    return true; // 実装詳細はSecurity Rulesで制御
  }
  
  // QRコード取引の有効性チェック
  static bool isValidQRTransaction(Map<String, dynamic> qrData) {
    final timestamp = qrData['timestamp'] as int?;
    if (timestamp == null) return false;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final timeDiff = now - timestamp;
    
    // 5分以内のQRコードのみ有効
    return timeDiff <= (5 * 60 * 1000);
  }
}
```

## 9. パフォーマンス最適化設計

### 9.1 画像最適化
```dart
class ImageOptimizationService {
  static Future<Uint8List> compressImage(Uint8List imageBytes) async {
    final codec = await instantiateImageCodec(
      imageBytes,
      targetWidth: 800,
      targetHeight: 600,
    );
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(format: ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }
}
```

### 9.2 地図パフォーマンス
```dart
class MapOptimizationService {
  // 表示範囲に基づく店舗フィルタリング
  static List<StoreModel> filterStoresByBounds(
    List<StoreModel> stores,
    LatLngBounds bounds,
  ) {
    return stores.where((store) {
      return bounds.contains(
        LatLng(store.location.latitude, store.location.longitude),
      );
    }).toList();
  }
  
  // マーカークラスタリング
  static List<MarkerCluster> clusterMarkers(
    List<StoreModel> stores,
    double zoomLevel,
  ) {
    // クラスタリングアルゴリズム実装
    return [];
  }
}
```

## 10. お知らせシステム設計

### 10.1 お知らせサービス
```dart
class AnnouncementService {
  // 会社管理者によるお知らせ作成
  static Future<void> createAnnouncement({
    required String companyId,
    required String title,
    required String content,
    required AnnouncementTarget targetAudience,
    required String createdBy,
    String? imageUrl,
    DateTime? expiresAt,
    AnnouncementPriority priority = AnnouncementPriority.medium,
  }) async {
    final announcement = AnnouncementModel(
      announcementId: FirestoreService.generateId(),
      companyId: companyId,
      title: title,
      content: content,
      targetAudience: targetAudience,
      priority: priority,
      imageUrl: imageUrl,
      isPublished: true,
      publishedAt: DateTime.now(),
      expiresAt: expiresAt,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await FirestoreService.createAnnouncement(announcement);
    
    // FCM通知送信
    await _sendPushNotification(announcement);
  }
  
  // 対象ユーザーへのプッシュ通知送信
  static Future<void> _sendPushNotification(AnnouncementModel announcement) async {
    List<String> targetTokens = [];
    
    switch (announcement.targetAudience) {
      case AnnouncementTarget.users:
        targetTokens = await _getUserFCMTokens(announcement.companyId);
        break;
      case AnnouncementTarget.stores:
        targetTokens = await _getStoreFCMTokens(announcement.companyId);
        break;
      case AnnouncementTarget.both:
        targetTokens = [
          ...await _getUserFCMTokens(announcement.companyId),
          ...await _getStoreFCMTokens(announcement.companyId),
        ];
        break;
    }
    
    await FCMService.sendToMultiple(
      tokens: targetTokens,
      title: announcement.title,
      body: announcement.content,
      data: {
        'type': 'announcement',
        'announcementId': announcement.announcementId,
      },
    );
  }
  
  // お知らせを既読にする
  static Future<void> markAsRead({
    required String announcementId,
    required String userId,
    required AnnouncementUserType userType,
  }) async {
    final readRecord = AnnouncementReadModel(
      id: FirestoreService.generateId(),
      announcementId: announcementId,
      userId: userId,
      userType: userType,
      readAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
    
    await FirestoreService.createAnnouncementRead(readRecord);
  }
  
  // 未読件数取得
  static Future<int> getUnreadCount({
    required String userId,
    required AnnouncementUserType userType,
  }) async {
    final announcements = await FirestoreService.getAnnouncementsForUser(
      userId: userId,
      userType: userType,
    );
    
    final readAnnouncements = await FirestoreService.getReadAnnouncements(userId);
    final readIds = readAnnouncements.map((r) => r.announcementId).toSet();
    
    return announcements.where((a) => !readIds.contains(a.announcementId)).length;
  }
  
  // 会社に関連するユーザーのFCMトークン取得
  static Future<List<String>> _getUserFCMTokens(String companyId) async {
    // 会社の店舗を利用するユーザーのトークンを取得
    final stores = await FirestoreService.getStoresByCompany(companyId);
    final storeIds = stores.map((s) => s.storeId).toList();
    
    // 各店舗を利用したことがあるユーザーを取得
    final transactions = await FirestoreService.getTransactionsByStores(storeIds);
    final userIds = transactions.map((t) => t.userId).toSet().toList();
    
    return await FirestoreService.getFCMTokensByUsers(userIds);
  }
  
  // 会社に関連する店舗のFCMトークン取得
  static Future<List<String>> _getStoreFCMTokens(String companyId) async {
    final stores = await FirestoreService.getStoresByCompany(companyId);
    final storeIds = stores.map((s) => s.storeId).toList();
    
    return await FirestoreService.getFCMTokensByStores(storeIds);
  }
}

enum AnnouncementTarget {
  users,   // ユーザー向け
  stores,  // 店舗向け
  both,    // 両方向け
}

enum AnnouncementPriority {
  low,
  medium,
  high,
}

enum AnnouncementUserType {
  user,
  store,
}
```

### 10.2 お知らせUI設計

#### 10.2.1 お知らせカード
```dart
class AnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;
  final bool isRead;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isRead ? 1 : 3,
      child: InkWell(
        onTap: () {
          onTap?.call();
          if (!isRead) {
            onMarkAsRead?.call();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 優先度インジケーター
                  Container(
                    width: 4,
                    height: 20,
                    color: _getPriorityColor(announcement.priority),
                  ),
                  const SizedBox(width: 12),
                  // 未読インジケーター
                  if (!isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  const SizedBox(width: 8),
                  // タイトル
                  Expanded(
                    child: Text(
                      announcement.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                        color: isRead ? AppColors.textSecondary : AppColors.text,
                      ),
                    ),
                  ),
                  // 対象バッジ
                  _buildTargetBadge(announcement.targetAudience),
                ],
              ),
              const SizedBox(height: 8),
              // コンテンツ
              Text(
                announcement.content,
                style: TextStyle(
                  fontSize: 14,
                  color: isRead ? AppColors.textSecondary : AppColors.text,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // 日付
              Text(
                DateFormat('yyyy/MM/dd HH:mm').format(announcement.publishedAt!),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getPriorityColor(AnnouncementPriority priority) {
    switch (priority) {
      case AnnouncementPriority.high:
        return Colors.red;
      case AnnouncementPriority.medium:
        return Colors.orange;
      case AnnouncementPriority.low:
        return Colors.grey;
    }
  }
  
  Widget _buildTargetBadge(AnnouncementTarget target) {
    String label;
    Color color;
    
    switch (target) {
      case AnnouncementTarget.users:
        label = 'ユーザー';
        color = Colors.blue;
        break;
      case AnnouncementTarget.stores:
        label = '店舗';
        color = Colors.green;
        break;
      case AnnouncementTarget.both:
        label = '全体';
        color = AppColors.primary;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
```

#### 10.2.2 お知らせ作成画面（会社管理者用）
```dart
class CreateAnnouncementPage extends StatefulWidget {
  @override
  _CreateAnnouncementPageState createState() => _CreateAnnouncementPageState();
}

class _CreateAnnouncementPageState extends State<CreateAnnouncementPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  AnnouncementTarget _selectedTarget = AnnouncementTarget.both;
  AnnouncementPriority _selectedPriority = AnnouncementPriority.medium;
  DateTime? _expiryDate;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('お知らせ作成'),
        backgroundColor: AppColors.primary,
        actions: [
          TextButton(
            onPressed: _createAnnouncement,
            child: const Text('投稿', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // タイトル入力
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'タイトル',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // 対象選択
            const Text('配信対象', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<AnnouncementTarget>(
              segments: const [
                ButtonSegment(value: AnnouncementTarget.users, label: Text('ユーザー')),
                ButtonSegment(value: AnnouncementTarget.stores, label: Text('店舗')),
                ButtonSegment(value: AnnouncementTarget.both, label: Text('両方')),
              ],
              selected: {_selectedTarget},
              onSelectionChanged: (Set<AnnouncementTarget> selection) {
                setState(() {
                  _selectedTarget = selection.first;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // コンテンツ入力
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: '本文',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _createAnnouncement() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('タイトルと本文を入力してください')),
      );
      return;
    }
    
    try {
      await AnnouncementService.createAnnouncement(
        companyId: 'current_company_id', // 実際は認証情報から取得
        title: _titleController.text,
        content: _contentController.text,
        targetAudience: _selectedTarget,
        createdBy: 'current_user_id', // 実際は認証情報から取得
        priority: _selectedPriority,
        expiresAt: _expiryDate,
      );
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('お知らせを投稿しました')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    }
  }
}
```

## 11. テスト設計

### 11.1 単体テスト
```dart
// レベルシステムテスト例
void main() {
  group('LevelService Tests', () {
    test('should calculate correct experience for level up', () {
      expect(LevelService.getRequiredExperience(1), equals(100));
      expect(LevelService.getRequiredExperience(2), equals(282));
      expect(LevelService.getRequiredExperience(10), equals(3162));
    });
    
    test('should calculate correct level from experience', () {
      expect(LevelService.calculateLevel(0), equals(1));
      expect(LevelService.calculateLevel(100), equals(1));
      expect(LevelService.calculateLevel(282), equals(2));
    });
  });
}
```

### 11.2 統合テスト
```dart
// QRコード機能統合テスト例
void main() {
  group('QR Code Integration Tests', () {
    testWidgets('should scan QR code and award points', (tester) async {
      // テスト実装
    });
  });
}
```

## 12. 友達紹介システム設計

### 12.1 友達紹介データモデル
```dart
class ReferralCodeModel {
  final String referralCodeId;
  final String userId;
  final String referralCode;
  final bool isActive;
  final int totalReferrals;
  final int totalRewards;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReferralCodeModel({
    required this.referralCodeId,
    required this.userId,
    required this.referralCode,
    required this.isActive,
    required this.totalReferrals,
    required this.totalRewards,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReferralCodeModel.fromJson(Map<String, dynamic> json) {
    return ReferralCodeModel(
      referralCodeId: json['referralCodeId'],
      userId: json['userId'],
      referralCode: json['referralCode'],
      isActive: json['isActive'] ?? true,
      totalReferrals: json['totalReferrals'] ?? 0,
      totalRewards: json['totalRewards'] ?? 0,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'referralCodeId': referralCodeId,
      'userId': userId,
      'referralCode': referralCode,
      'isActive': isActive,
      'totalReferrals': totalReferrals,
      'totalRewards': totalRewards,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class ReferralRelationshipModel {
  final String relationshipId;
  final String referrerId;
  final String referredUserId;
  final String referralCode;
  final DateTime referredAt;
  final int referrerReward;
  final int referredReward;
  final bool rewardGiven;
  final ReferralStatus status;
  final String referrerName;
  final String referredName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReferralRelationshipModel({
    required this.relationshipId,
    required this.referrerId,
    required this.referredUserId,
    required this.referralCode,
    required this.referredAt,
    required this.referrerReward,
    required this.referredReward,
    required this.rewardGiven,
    required this.status,
    required this.referrerName,
    required this.referredName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReferralRelationshipModel.fromJson(Map<String, dynamic> json) {
    return ReferralRelationshipModel(
      relationshipId: json['relationshipId'],
      referrerId: json['referrerId'],
      referredUserId: json['referredUserId'],
      referralCode: json['referralCode'],
      referredAt: (json['referredAt'] as Timestamp).toDate(),
      referrerReward: json['referrerReward'] ?? 0,
      referredReward: json['referredReward'] ?? 0,
      rewardGiven: json['rewardGiven'] ?? false,
      status: ReferralStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReferralStatus.pending,
      ),
      referrerName: json['referrerName'],
      referredName: json['referredName'],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'relationshipId': relationshipId,
      'referrerId': referrerId,
      'referredUserId': referredUserId,
      'referralCode': referralCode,
      'referredAt': Timestamp.fromDate(referredAt),
      'referrerReward': referrerReward,
      'referredReward': referredReward,
      'rewardGiven': rewardGiven,
      'status': status.name,
      'referrerName': referrerName,
      'referredName': referredName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

enum ReferralStatus {
  pending,
  completed,
  cancelled,
}
```

### 12.2 友達紹介サービス
```dart
class ReferralService {
  static const int REFERRER_REWARD_POINTS = 500; // 紹介者報酬
  static const int REFERRED_REWARD_POINTS = 300; // 被紹介者報酬
  
  // 紹介コード生成（ユーザー登録時）
  static Future<String> generateReferralCode(String userId) async {
    String code;
    bool isUnique = false;
    
    do {
      code = _generateRandomCode(8);
      isUnique = await _isReferralCodeUnique(code);
    } while (!isUnique);
    
    final referralCode = ReferralCodeModel(
      referralCodeId: FirestoreService.generateId(),
      userId: userId,
      referralCode: code,
      isActive: true,
      totalReferrals: 0,
      totalRewards: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await FirestoreService.createReferralCode(referralCode);
    return code;
  }
  
  // 友達紹介成立処理
  static Future<bool> processReferral({
    required String referralCode,
    required String newUserId,
    required String newUserName,
  }) async {
    try {
      // 紹介コードの有効性チェック
      final referralCodeData = await FirestoreService.getReferralCodeByCode(referralCode);
      if (referralCodeData == null || !referralCodeData.isActive) {
        return false;
      }
      
      // 自己紹介チェック
      if (referralCodeData.userId == newUserId) {
        throw Exception('自分の紹介コードは使用できません');
      }
      
      // 重複チェック
      final existingRelationship = await FirestoreService.getReferralRelationshipByUsers(
        referralCodeData.userId,
        newUserId,
      );
      if (existingRelationship != null) {
        throw Exception('既に紹介関係が成立しています');
      }
      
      // 紹介者情報取得
      final referrer = await FirestoreService.getUserById(referralCodeData.userId);
      if (referrer == null) {
        return false;
      }
      
      // 紹介関係作成
      final relationship = ReferralRelationshipModel(
        relationshipId: FirestoreService.generateId(),
        referrerId: referralCodeData.userId,
        referredUserId: newUserId,
        referralCode: referralCode,
        referredAt: DateTime.now(),
        referrerReward: REFERRER_REWARD_POINTS,
        referredReward: REFERRED_REWARD_POINTS,
        rewardGiven: false,
        status: ReferralStatus.pending,
        referrerName: referrer.username,
        referredName: newUserName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await FirestoreService.createReferralRelationship(relationship);
      
      // 報酬付与処理
      await _giveReferralRewards(relationship);
      
      // 紹介コード統計更新
      await _updateReferralCodeStats(referralCodeData.referralCodeId);
      
      return true;
    } catch (e) {
      print('友達紹介処理エラー: $e');
      return false;
    }
  }
  
  // 紹介リスト取得
  static Future<List<ReferralRelationshipModel>> getReferralList(String userId) async {
    return await FirestoreService.getReferralsByReferrer(userId);
  }
  
  // 紹介統計取得
  static Future<ReferralStats> getReferralStats(String userId) async {
    final referralCode = await FirestoreService.getReferralCodeByUserId(userId);
    if (referralCode == null) {
      return ReferralStats.empty();
    }
    
    final relationships = await FirestoreService.getReferralsByReferrer(userId);
    final totalRewards = relationships
        .where((r) => r.rewardGiven)
        .fold<int>(0, (sum, r) => sum + r.referrerReward);
    
    return ReferralStats(
      totalReferrals: referralCode.totalReferrals,
      totalRewards: totalRewards,
      completedReferrals: relationships.where((r) => r.status == ReferralStatus.completed).length,
      pendingReferrals: relationships.where((r) => r.status == ReferralStatus.pending).length,
    );
  }
  
  // 報酬付与処理
  static Future<void> _giveReferralRewards(ReferralRelationshipModel relationship) async {
    try {
      // 紹介者にポイント付与
      await PointService.addPoints(
        userId: relationship.referrerId,
        points: relationship.referrerReward,
        reason: 'friend_referral',
        sourceId: relationship.relationshipId,
      );
      
      // 被紹介者にポイント付与
      await PointService.addPoints(
        userId: relationship.referredUserId,
        points: relationship.referredReward,
        reason: 'referred_bonus',
        sourceId: relationship.relationshipId,
      );
      
      // 報酬付与フラグ更新
      await FirestoreService.updateReferralRelationship(
        relationship.relationshipId,
        {
          'rewardGiven': true,
          'status': ReferralStatus.completed.name,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        },
      );
      
      // プッシュ通知送信
      await _sendReferralNotifications(relationship);
      
    } catch (e) {
      print('報酬付与エラー: $e');
      // 失敗時はステータスをキャンセルに変更
      await FirestoreService.updateReferralRelationship(
        relationship.relationshipId,
        {
          'status': ReferralStatus.cancelled.name,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        },
      );
    }
  }
  
  // 通知送信
  static Future<void> _sendReferralNotifications(ReferralRelationshipModel relationship) async {
    // 紹介者への通知
    await FCMService.sendToUser(
      userId: relationship.referrerId,
      title: '友達紹介成功！',
      body: '${relationship.referredName}さんが登録してくれました！${relationship.referrerReward}ポイント獲得！',
      data: {
        'type': 'referral_success',
        'relationshipId': relationship.relationshipId,
      },
    );
    
    // 被紹介者への通知
    await FCMService.sendToUser(
      userId: relationship.referredUserId,
      title: '友達紹介ボーナス！',
      body: '友達紹介で${relationship.referredReward}ポイント獲得しました！',
      data: {
        'type': 'referral_bonus',
        'relationshipId': relationship.relationshipId,
      },
    );
  }
  
  // 紹介コード統計更新
  static Future<void> _updateReferralCodeStats(String referralCodeId) async {
    final relationships = await FirestoreService.getReferralsByReferralCodeId(referralCodeId);
    final totalReferrals = relationships.length;
    final totalRewards = relationships
        .where((r) => r.rewardGiven)
        .fold<int>(0, (sum, r) => sum + r.referrerReward);
    
    await FirestoreService.updateReferralCode(referralCodeId, {
      'totalReferrals': totalReferrals,
      'totalRewards': totalRewards,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
  
  // ランダムコード生成
  static String _generateRandomCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }
  
  // 紹介コードの一意性チェック
  static Future<bool> _isReferralCodeUnique(String code) async {
    final existing = await FirestoreService.getReferralCodeByCode(code);
    return existing == null;
  }
}

class ReferralStats {
  final int totalReferrals;
  final int totalRewards;
  final int completedReferrals;
  final int pendingReferrals;

  const ReferralStats({
    required this.totalReferrals,
    required this.totalRewards,
    required this.completedReferrals,
    required this.pendingReferrals,
  });

  factory ReferralStats.empty() {
    return const ReferralStats(
      totalReferrals: 0,
      totalRewards: 0,
      completedReferrals: 0,
      pendingReferrals: 0,
    );
  }
}
```

### 12.3 友達紹介UI設計

#### 12.3.1 友達紹介画面（ホーム画面からアクセス）
```dart
class ReferralPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends ConsumerState<ReferralPage> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final referralCode = ref.watch(userReferralCodeProvider(user?.uid ?? ''));
    final referralStats = ref.watch(referralStatsProvider(user?.uid ?? ''));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('友達紹介'),
        backgroundColor: AppColors.primary,
      ),
      body: referralCode.when(
        data: (code) => _buildReferralContent(code, referralStats),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('エラー: $error')),
      ),
    );
  }
  
  Widget _buildReferralContent(String referralCode, AsyncValue<ReferralStats> statsAsync) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 紹介コード表示カード
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(
                    Icons.card_giftcard,
                    size: 48,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'あなたの紹介コード',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // 紹介コード
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          referralCode,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () => _copyReferralCode(referralCode),
                          icon: const Icon(Icons.copy, color: AppColors.primary),
                          tooltip: 'コピー',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // シェアボタン
                  ElevatedButton.icon(
                    onPressed: () => _shareReferralCode(referralCode),
                    icon: const Icon(Icons.share),
                    label: const Text('友達に紹介する'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // 紹介方法説明
          _buildHowToSection(),
          const SizedBox(height: 24),
          
          // 統計情報
          statsAsync.when(
            data: (stats) => _buildStatsSection(stats),
            loading: () => const CircularProgressIndicator(),
            error: (error, _) => Text('統計エラー: $error'),
          ),
          const SizedBox(height: 24),
          
          // 紹介履歴
          _buildReferralHistorySection(),
        ],
      ),
    );
  }
  
  Widget _buildHowToSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '友達紹介の方法',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildHowToStep(
              step: '1',
              title: '紹介コードを友達に教える',
              description: '上記の8桁の紹介コードを友達に教えてください。',
              icon: Icons.share,
            ),
            const SizedBox(height: 16),
            
            _buildHowToStep(
              step: '2',
              title: '友達がアプリをダウンロード',
              description: '友達にGrouMapアプリをダウンロードしてもらいましょう。',
              icon: Icons.download,
            ),
            const SizedBox(height: 16),
            
            _buildHowToStep(
              step: '3',
              title: 'アカウント作成時にコード入力',
              description: '友達がアカウント作成時に、あなたの紹介コードを入力します。',
              icon: Icons.person_add,
            ),
            const SizedBox(height: 16),
            
            _buildHowToStep(
              step: '4',
              title: 'お互いにポイント獲得！',
              description: 'あなたは500P、友達は300Pをそれぞれ獲得できます！',
              icon: Icons.celebration,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHowToStep({
    required String step,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatsSection(ReferralStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '紹介実績',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    title: '総紹介数',
                    value: '${stats.totalReferrals}人',
                    icon: Icons.people,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    title: '獲得ポイント',
                    value: '${stats.totalRewards}P',
                    icon: Icons.stars,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildReferralHistorySection() {
    final user = ref.watch(currentUserProvider);
    final referralHistory = ref.watch(referralHistoryProvider(user?.uid ?? ''));
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '紹介履歴',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            referralHistory.when(
              data: (history) {
                if (history.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'まだ紹介実績がありません\n友達を紹介してポイントをゲット！',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }
                
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final referral = history[index];
                    return _buildReferralHistoryItem(referral);
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, _) => Text('エラー: $error'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildReferralHistoryItem(ReferralRelationshipModel referral) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getStatusColor(referral.status),
        child: Icon(
          _getStatusIcon(referral.status),
          color: Colors.white,
        ),
      ),
      title: Text(referral.referredName),
      subtitle: Text(
        DateFormat('yyyy/MM/dd').format(referral.referredAt),
      ),
      trailing: referral.rewardGiven
          ? Text(
              '+${referral.referrerReward}P',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            )
          : Text(
              referral.status == ReferralStatus.pending ? '処理中' : 'キャンセル',
              style: TextStyle(
                color: _getStatusColor(referral.status),
                fontSize: 12,
              ),
            ),
    );
  }
  
  Color _getStatusColor(ReferralStatus status) {
    switch (status) {
      case ReferralStatus.completed:
        return Colors.green;
      case ReferralStatus.pending:
        return Colors.orange;
      case ReferralStatus.cancelled:
        return Colors.red;
    }
  }
  
  IconData _getStatusIcon(ReferralStatus status) {
    switch (status) {
      case ReferralStatus.completed:
        return Icons.check;
      case ReferralStatus.pending:
        return Icons.schedule;
      case ReferralStatus.cancelled:
        return Icons.close;
    }
  }
  
  void _copyReferralCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('紹介コードをコピーしました')),
    );
  }
  
  void _shareReferralCode(String code) {
    Share.share(
      'GrouMapアプリを始めませんか？\n'
      '私の紹介コード「$code」を使って登録すると、お互いにポイントがもらえます！\n\n'
      'アプリダウンロード: [アプリストアのURL]',
      subject: 'GrouMapアプリの紹介',
    );
  }
}
```

#### 12.3.2 紹介コード入力フィールド（ユーザー登録時）
```dart
class ReferralCodeInputField extends StatefulWidget {
  final Function(String?) onReferralCodeChanged;
  
  const ReferralCodeInputField({
    Key? key,
    required this.onReferralCodeChanged,
  }) : super(key: key);
  
  @override
  State<ReferralCodeInputField> createState() => _ReferralCodeInputFieldState();
}

class _ReferralCodeInputFieldState extends State<ReferralCodeInputField> {
  final _controller = TextEditingController();
  bool _isValidating = false;
  bool? _isValid;
  String? _errorMessage;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: '友達紹介コード（任意）',
            hintText: '8桁の紹介コードを入力',
            border: const OutlineInputBorder(),
            suffixIcon: _buildSuffixIcon(),
            errorText: _errorMessage,
          ),
          maxLength: 8,
          textCapitalization: TextCapitalization.characters,
          onChanged: _onCodeChanged,
        ),
        if (_controller.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '紹介コードを使用すると、300ポイントがもらえます！',
            style: TextStyle(
              fontSize: 12,
              color: _isValid == true ? Colors.green : AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
  
  Widget? _buildSuffixIcon() {
    if (_isValidating) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    
    if (_isValid == true) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }
    
    if (_isValid == false) {
      return const Icon(Icons.error, color: Colors.red);
    }
    
    return null;
  }
  
  void _onCodeChanged(String value) {
    setState(() {
      _errorMessage = null;
      _isValid = null;
    });
    
    if (value.isEmpty) {
      widget.onReferralCodeChanged(null);
      return;
    }
    
    if (value.length == 8) {
      _validateReferralCode(value);
    } else {
      widget.onReferralCodeChanged(null);
    }
  }
  
  Future<void> _validateReferralCode(String code) async {
    setState(() {
      _isValidating = true;
    });
    
    try {
      final referralCode = await FirestoreService.getReferralCodeByCode(code);
      
      setState(() {
        _isValidating = false;
        if (referralCode != null && referralCode.isActive) {
          _isValid = true;
          _errorMessage = null;
          widget.onReferralCodeChanged(code);
        } else {
          _isValid = false;
          _errorMessage = '無効な紹介コードです';
          widget.onReferralCodeChanged(null);
        }
      });
    } catch (e) {
      setState(() {
        _isValidating = false;
        _isValid = false;
        _errorMessage = 'コードの確認に失敗しました';
        widget.onReferralCodeChanged(null);
      });
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### 12.4 Riverpodプロバイダー
```dart
// 紹介コード取得
final userReferralCodeProvider = FutureProvider.family<String, String>((ref, userId) async {
  final referralCode = await ref.watch(firestoreServiceProvider).getReferralCodeByUserId(userId);
  return referralCode?.referralCode ?? '';
});

// 紹介統計取得
final referralStatsProvider = FutureProvider.family<ReferralStats, String>((ref, userId) async {
  return await ReferralService.getReferralStats(userId);
});

// 紹介履歴取得
final referralHistoryProvider = StreamProvider.family<List<ReferralRelationshipModel>, String>((ref, userId) {
  return ref.watch(firestoreServiceProvider).getReferralsByReferrer(userId);
});
```

## 13. 店舗紹介システム設計

### 13.1 店舗紹介データモデル
```dart
class StoreReferralCodeModel {
  final String storeReferralCodeId;
  final String storeId;
  final String referralCode;
  final bool isActive;
  final int totalReferrals;
  final int totalApprovedReferrals;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StoreReferralCodeModel({
    required this.storeReferralCodeId,
    required this.storeId,
    required this.referralCode,
    required this.isActive,
    required this.totalReferrals,
    required this.totalApprovedReferrals,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StoreReferralCodeModel.fromJson(Map<String, dynamic> json) {
    return StoreReferralCodeModel(
      storeReferralCodeId: json['storeReferralCodeId'],
      storeId: json['storeId'],
      referralCode: json['referralCode'],
      isActive: json['isActive'] ?? true,
      totalReferrals: json['totalReferrals'] ?? 0,
      totalApprovedReferrals: json['totalApprovedReferrals'] ?? 0,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'storeReferralCodeId': storeReferralCodeId,
      'storeId': storeId,
      'referralCode': referralCode,
      'isActive': isActive,
      'totalReferrals': totalReferrals,
      'totalApprovedReferrals': totalApprovedReferrals,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class StoreReferralRelationshipModel {
  final String storeRelationshipId;
  final String referrerStoreId;
  final String referredStoreId;
  final String referralCode;
  final DateTime referredAt;
  final DateTime? approvedAt;
  final String? approvedBy;
  final StoreReferralStatus status;
  final String referrerStoreName;
  final String referredStoreName;
  final String companyId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StoreReferralRelationshipModel({
    required this.storeRelationshipId,
    required this.referrerStoreId,
    required this.referredStoreId,
    required this.referralCode,
    required this.referredAt,
    this.approvedAt,
    this.approvedBy,
    required this.status,
    required this.referrerStoreName,
    required this.referredStoreName,
    required this.companyId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StoreReferralRelationshipModel.fromJson(Map<String, dynamic> json) {
    return StoreReferralRelationshipModel(
      storeRelationshipId: json['storeRelationshipId'],
      referrerStoreId: json['referrerStoreId'],
      referredStoreId: json['referredStoreId'],
      referralCode: json['referralCode'],
      referredAt: (json['referredAt'] as Timestamp).toDate(),
      approvedAt: json['approvedAt'] != null 
          ? (json['approvedAt'] as Timestamp).toDate() 
          : null,
      approvedBy: json['approvedBy'],
      status: StoreReferralStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => StoreReferralStatus.pending,
      ),
      referrerStoreName: json['referrerStoreName'],
      referredStoreName: json['referredStoreName'],
      companyId: json['companyId'],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'storeRelationshipId': storeRelationshipId,
      'referrerStoreId': referrerStoreId,
      'referredStoreId': referredStoreId,
      'referralCode': referralCode,
      'referredAt': Timestamp.fromDate(referredAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approvedBy': approvedBy,
      'status': status.name,
      'referrerStoreName': referrerStoreName,
      'referredStoreName': referredStoreName,
      'companyId': companyId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

enum StoreReferralStatus {
  pending,
  approved,
  rejected,
}
```

### 13.2 店舗紹介サービス
```dart
class StoreReferralService {
  // 店舗紹介コード生成（店舗登録時）
  static Future<String> generateStoreReferralCode(String storeId) async {
    String code;
    bool isUnique = false;
    
    do {
      code = _generateRandomCode(8);
      isUnique = await _isStoreReferralCodeUnique(code);
    } while (!isUnique);
    
    final storeReferralCode = StoreReferralCodeModel(
      storeReferralCodeId: FirestoreService.generateId(),
      storeId: storeId,
      referralCode: code,
      isActive: true,
      totalReferrals: 0,
      totalApprovedReferrals: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await FirestoreService.createStoreReferralCode(storeReferralCode);
    return code;
  }
  
  // 店舗紹介申請処理
  static Future<bool> processStoreReferral({
    required String referralCode,
    required String newStoreId,
    required String newStoreName,
    required String companyId,
  }) async {
    try {
      // 店舗紹介コードの有効性チェック
      final storeReferralCode = await FirestoreService.getStoreReferralCodeByCode(referralCode);
      if (storeReferralCode == null || !storeReferralCode.isActive) {
        return false;
      }
      
      // 自己紹介チェック
      if (storeReferralCode.storeId == newStoreId) {
        throw Exception('自分の店舗紹介コードは使用できません');
      }
      
      // 重複チェック
      final existingRelationship = await FirestoreService.getStoreReferralRelationshipByStores(
        storeReferralCode.storeId,
        newStoreId,
      );
      if (existingRelationship != null) {
        throw Exception('既に紹介関係が存在します');
      }
      
      // 紹介者店舗情報取得
      final referrerStore = await FirestoreService.getStoreById(storeReferralCode.storeId);
      if (referrerStore == null) {
        return false;
      }
      
      // 店舗紹介関係作成（仮アカウント状態）
      final relationship = StoreReferralRelationshipModel(
        storeRelationshipId: FirestoreService.generateId(),
        referrerStoreId: storeReferralCode.storeId,
        referredStoreId: newStoreId,
        referralCode: referralCode,
        referredAt: DateTime.now(),
        status: StoreReferralStatus.pending,
        referrerStoreName: referrerStore.name,
        referredStoreName: newStoreName,
        companyId: companyId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await FirestoreService.createStoreReferralRelationship(relationship);
      
      // 会社管理者に通知送信
      await _sendCompanyAdminNotification(relationship);
      
      // 統計更新
      await _updateStoreReferralCodeStats(storeReferralCode.storeReferralCodeId);
      
      return true;
    } catch (e) {
      print('店舗紹介処理エラー: $e');
      return false;
    }
  }
  
  // 会社管理者による店舗紹介承認
  static Future<bool> approveStoreReferral({
    required String relationshipId,
    required String approvedBy,
  }) async {
    try {
      final relationship = await FirestoreService.getStoreReferralRelationship(relationshipId);
      if (relationship == null || relationship.status != StoreReferralStatus.pending) {
        return false;
      }
      
      // 承認処理
      await FirestoreService.updateStoreReferralRelationship(relationshipId, {
        'status': StoreReferralStatus.approved.name,
        'approvedAt': Timestamp.fromDate(DateTime.now()),
        'approvedBy': approvedBy,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      // 被紹介店舗のアカウントを本アカウントに変更
      await _activateReferredStoreAccount(relationship.referredStoreId);
      
      // 統計更新
      await _updateApprovedStoreReferralStats(relationship.referrerStoreId);
      
      // 通知送信
      await _sendApprovalNotifications(relationship);
      
      return true;
    } catch (e) {
      print('店舗紹介承認エラー: $e');
      return false;
    }
  }
  
  // 会社管理者による店舗紹介拒否
  static Future<bool> rejectStoreReferral({
    required String relationshipId,
    required String rejectedBy,
  }) async {
    try {
      await FirestoreService.updateStoreReferralRelationship(relationshipId, {
        'status': StoreReferralStatus.rejected.name,
        'approvedBy': rejectedBy,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      // 拒否通知送信
      await _sendRejectionNotifications(relationshipId);
      
      return true;
    } catch (e) {
      print('店舗紹介拒否エラー: $e');
      return false;
    }
  }
  
  // 店舗紹介リスト取得
  static Future<List<StoreReferralRelationshipModel>> getStoreReferralList(String storeId) async {
    return await FirestoreService.getStoreReferralsByReferrer(storeId);
  }
  
  // 未承認店舗リスト取得（会社管理者用）
  static Future<List<StoreReferralRelationshipModel>> getPendingStoreReferrals(String companyId) async {
    return await FirestoreService.getPendingStoreReferralsByCompany(companyId);
  }
  
  // 店舗紹介統計取得
  static Future<StoreReferralStats> getStoreReferralStats(String storeId) async {
    final storeReferralCode = await FirestoreService.getStoreReferralCodeByStoreId(storeId);
    if (storeReferralCode == null) {
      return StoreReferralStats.empty();
    }
    
    final relationships = await FirestoreService.getStoreReferralsByReferrer(storeId);
    
    return StoreReferralStats(
      totalReferrals: storeReferralCode.totalReferrals,
      approvedReferrals: storeReferralCode.totalApprovedReferrals,
      pendingReferrals: relationships.where((r) => r.status == StoreReferralStatus.pending).length,
      rejectedReferrals: relationships.where((r) => r.status == StoreReferralStatus.rejected).length,
    );
  }
  
  // 会社管理者通知
  static Future<void> _sendCompanyAdminNotification(StoreReferralRelationshipModel relationship) async {
    final companyAdmins = await FirestoreService.getCompanyAdmins(relationship.companyId);
    
    for (final admin in companyAdmins) {
      await FCMService.sendToUser(
        userId: admin.userId,
        title: '新規店舗の承認申請',
        body: '${relationship.referredStoreName}から加盟申請が届いています。',
        data: {
          'type': 'store_referral_pending',
          'relationshipId': relationship.storeRelationshipId,
        },
      );
    }
  }
  
  // 承認通知送信
  static Future<void> _sendApprovalNotifications(StoreReferralRelationshipModel relationship) async {
    // 紹介者への通知
    final referrerStore = await FirestoreService.getStoreById(relationship.referrerStoreId);
    if (referrerStore != null) {
      await FCMService.sendToStore(
        storeId: relationship.referrerStoreId,
        title: '店舗紹介が承認されました！',
        body: '${relationship.referredStoreName}の紹介が承認されました。',
        data: {
          'type': 'store_referral_approved',
          'relationshipId': relationship.storeRelationshipId,
        },
      );
    }
    
    // 被紹介者への通知
    await FCMService.sendToStore(
      storeId: relationship.referredStoreId,
      title: 'アカウントが承認されました！',
      body: 'GrouMapへようこそ！アカウントが正式に承認されました。',
      data: {
        'type': 'account_approved',
        'relationshipId': relationship.storeRelationshipId,
      },
    );
  }
  
  // 拒否通知送信
  static Future<void> _sendRejectionNotifications(String relationshipId) async {
    final relationship = await FirestoreService.getStoreReferralRelationship(relationshipId);
    if (relationship == null) return;
    
    // 被紹介者への通知
    await FCMService.sendToStore(
      storeId: relationship.referredStoreId,
      title: 'アカウント申請について',
      body: '申請が承認されませんでした。詳細については運営にお問い合わせください。',
      data: {
        'type': 'account_rejected',
        'relationshipId': relationshipId,
      },
    );
  }
  
  // 被紹介店舗アカウント有効化
  static Future<void> _activateReferredStoreAccount(String storeId) async {
    await FirestoreService.updateStore(storeId, {
      'accountStatus': 'active',
      'activatedAt': Timestamp.fromDate(DateTime.now()),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
  
  // 統計更新
  static Future<void> _updateStoreReferralCodeStats(String storeReferralCodeId) async {
    final relationships = await FirestoreService.getStoreReferralsByCodeId(storeReferralCodeId);
    final totalReferrals = relationships.length;
    final approvedReferrals = relationships
        .where((r) => r.status == StoreReferralStatus.approved).length;
    
    await FirestoreService.updateStoreReferralCode(storeReferralCodeId, {
      'totalReferrals': totalReferrals,
      'totalApprovedReferrals': approvedReferrals,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
  
  // 承認統計更新
  static Future<void> _updateApprovedStoreReferralStats(String referrerStoreId) async {
    final storeReferralCode = await FirestoreService.getStoreReferralCodeByStoreId(referrerStoreId);
    if (storeReferralCode == null) return;
    
    final relationships = await FirestoreService.getStoreReferralsByReferrer(referrerStoreId);
    final approvedCount = relationships
        .where((r) => r.status == StoreReferralStatus.approved).length;
    
    await FirestoreService.updateStoreReferralCode(storeReferralCode.storeReferralCodeId, {
      'totalApprovedReferrals': approvedCount,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
  
  // ランダムコード生成
  static String _generateRandomCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }
  
  // 店舗紹介コードの一意性チェック
  static Future<bool> _isStoreReferralCodeUnique(String code) async {
    final existing = await FirestoreService.getStoreReferralCodeByCode(code);
    return existing == null;
  }
}

class StoreReferralStats {
  final int totalReferrals;
  final int approvedReferrals;
  final int pendingReferrals;
  final int rejectedReferrals;

  const StoreReferralStats({
    required this.totalReferrals,
    required this.approvedReferrals,
    required this.pendingReferrals,
    required this.rejectedReferrals,
  });

  factory StoreReferralStats.empty() {
    return const StoreReferralStats(
      totalReferrals: 0,
      approvedReferrals: 0,
      pendingReferrals: 0,
      rejectedReferrals: 0,
    );
  }
}
```

### 13.3 店舗紹介UI設計

#### 13.3.1 店舗紹介画面（店舗用ホーム画面からアクセス）
```dart
class StoreReferralPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<StoreReferralPage> createState() => _StoreReferralPageState();
}

class _StoreReferralPageState extends ConsumerState<StoreReferralPage> {
  @override
  Widget build(BuildContext context) {
    final currentStore = ref.watch(currentStoreProvider);
    final storeReferralCode = ref.watch(storeReferralCodeProvider(currentStore?.storeId ?? ''));
    final storeReferralStats = ref.watch(storeReferralStatsProvider(currentStore?.storeId ?? ''));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('店舗紹介'),
        backgroundColor: AppColors.primary,
      ),
      body: storeReferralCode.when(
        data: (code) => _buildStoreReferralContent(code, storeReferralStats),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('エラー: $error')),
      ),
    );
  }
  
  Widget _buildStoreReferralContent(String referralCode, AsyncValue<StoreReferralStats> statsAsync) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 店舗紹介コード表示カード
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(
                    Icons.store_mall_directory,
                    size: 48,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'あなたの店舗紹介コード',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // 店舗紹介コード
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          referralCode,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () => _copyStoreReferralCode(referralCode),
                          icon: const Icon(Icons.copy, color: AppColors.primary),
                          tooltip: 'コピー',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // シェアボタン
                  ElevatedButton.icon(
                    onPressed: () => _shareStoreReferralCode(referralCode),
                    icon: const Icon(Icons.share),
                    label: const Text('店舗を紹介する'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // 店舗紹介方法説明
          _buildStoreHowToSection(),
          const SizedBox(height: 24),
          
          // 統計情報
          statsAsync.when(
            data: (stats) => _buildStoreStatsSection(stats),
            loading: () => const CircularProgressIndicator(),
            error: (error, _) => Text('統計エラー: $error'),
          ),
          const SizedBox(height: 24),
          
          // 紹介履歴
          _buildStoreReferralHistorySection(),
        ],
      ),
    );
  }
  
  Widget _buildStoreHowToSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '店舗紹介の方法',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildStoreHowToStep(
              step: '1',
              title: '紹介コードを新規店舗に教える',
              description: '上記の8桁の紹介コードを新規加盟希望店舗に教えてください。',
              icon: Icons.share,
            ),
            const SizedBox(height: 16),
            
            _buildStoreHowToStep(
              step: '2',
              title: '店舗用アプリをダウンロード',
              description: '新規店舗にGrouMap店舗用アプリをダウンロードしてもらいましょう。',
              icon: Icons.download,
            ),
            const SizedBox(height: 16),
            
            _buildStoreHowToStep(
              step: '3',
              title: 'アカウント作成時にコード入力',
              description: '新規店舗がアカウント作成時に、あなたの紹介コードを入力します。',
              icon: Icons.store_mall_directory,
            ),
            const SizedBox(height: 16),
            
            _buildStoreHowToStep(
              step: '4',
              title: '会社管理者が承認',
              description: '会社管理者に承認申請が送られ、承認されると正式に加盟が完了します。',
              icon: Icons.approval,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStoreHowToStep({
    required String step,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildStoreStatsSection(StoreReferralStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '紹介実績',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStoreStatItem(
                    title: '総紹介数',
                    value: '${stats.totalReferrals}店舗',
                    icon: Icons.store,
                  ),
                ),
                Expanded(
                  child: _buildStoreStatItem(
                    title: '承認済み',
                    value: '${stats.approvedReferrals}店舗',
                    icon: Icons.check_circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildStoreStatItem(
                    title: '承認待ち',
                    value: '${stats.pendingReferrals}店舗',
                    icon: Icons.schedule,
                  ),
                ),
                Expanded(
                  child: _buildStoreStatItem(
                    title: '拒否',
                    value: '${stats.rejectedReferrals}店舗',
                    icon: Icons.cancel,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStoreStatItem({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildStoreReferralHistorySection() {
    final currentStore = ref.watch(currentStoreProvider);
    final storeReferralHistory = ref.watch(storeReferralHistoryProvider(currentStore?.storeId ?? ''));
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '紹介履歴',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            storeReferralHistory.when(
              data: (history) {
                if (history.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'まだ店舗紹介の実績がありません\n新規店舗を紹介してみましょう！',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }
                
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final referral = history[index];
                    return _buildStoreReferralHistoryItem(referral);
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, _) => Text('エラー: $error'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStoreReferralHistoryItem(StoreReferralRelationshipModel referral) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getStoreStatusColor(referral.status),
        child: Icon(
          _getStoreStatusIcon(referral.status),
          color: Colors.white,
        ),
      ),
      title: Text(referral.referredStoreName),
      subtitle: Text(
        DateFormat('yyyy/MM/dd').format(referral.referredAt),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getStoreStatusColor(referral.status).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getStoreStatusColor(referral.status).withOpacity(0.3),
          ),
        ),
        child: Text(
          _getStoreStatusLabel(referral.status),
          style: TextStyle(
            color: _getStoreStatusColor(referral.status),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
  
  Color _getStoreStatusColor(StoreReferralStatus status) {
    switch (status) {
      case StoreReferralStatus.approved:
        return Colors.green;
      case StoreReferralStatus.pending:
        return Colors.orange;
      case StoreReferralStatus.rejected:
        return Colors.red;
    }
  }
  
  IconData _getStoreStatusIcon(StoreReferralStatus status) {
    switch (status) {
      case StoreReferralStatus.approved:
        return Icons.check;
      case StoreReferralStatus.pending:
        return Icons.schedule;
      case StoreReferralStatus.rejected:
        return Icons.close;
    }
  }
  
  String _getStoreStatusLabel(StoreReferralStatus status) {
    switch (status) {
      case StoreReferralStatus.approved:
        return '承認済み';
      case StoreReferralStatus.pending:
        return '承認待ち';
      case StoreReferralStatus.rejected:
        return '拒否';
    }
  }
  
  void _copyStoreReferralCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('店舗紹介コードをコピーしました')),
    );
  }
  
  void _shareStoreReferralCode(String code) {
    Share.share(
      'GrouMapで一緒にお店を盛り上げませんか？\n'
      '私の店舗紹介コード「$code」を使って登録すると、スムーズに加盟できます！\n\n'
      '店舗用アプリダウンロード: [店舗用アプリストアのURL]',
      subject: 'GrouMap店舗紹介',
    );
  }
}
```

#### 13.3.2 店舗紹介コード入力フィールド（店舗登録時）
```dart
class StoreReferralCodeInputField extends StatefulWidget {
  final Function(String?) onStoreReferralCodeChanged;
  
  const StoreReferralCodeInputField({
    Key? key,
    required this.onStoreReferralCodeChanged,
  }) : super(key: key);
  
  @override
  State<StoreReferralCodeInputField> createState() => _StoreReferralCodeInputFieldState();
}

class _StoreReferralCodeInputFieldState extends State<StoreReferralCodeInputField> {
  final _controller = TextEditingController();
  bool _isValidating = false;
  bool? _isValid;
  String? _errorMessage;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: '店舗紹介コード（任意）',
            hintText: '8桁の店舗紹介コードを入力',
            border: const OutlineInputBorder(),
            suffixIcon: _buildSuffixIcon(),
            errorText: _errorMessage,
          ),
          maxLength: 8,
          textCapitalization: TextCapitalization.characters,
          onChanged: _onCodeChanged,
        ),
        if (_controller.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '店舗紹介コードを使用すると、スムーズに承認プロセスが進みます',
            style: TextStyle(
              fontSize: 12,
              color: _isValid == true ? Colors.green : AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
  
  Widget? _buildSuffixIcon() {
    if (_isValidating) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    
    if (_isValid == true) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }
    
    if (_isValid == false) {
      return const Icon(Icons.error, color: Colors.red);
    }
    
    return null;
  }
  
  void _onCodeChanged(String value) {
    setState(() {
      _errorMessage = null;
      _isValid = null;
    });
    
    if (value.isEmpty) {
      widget.onStoreReferralCodeChanged(null);
      return;
    }
    
    if (value.length == 8) {
      _validateStoreReferralCode(value);
    } else {
      widget.onStoreReferralCodeChanged(null);
    }
  }
  
  Future<void> _validateStoreReferralCode(String code) async {
    setState(() {
      _isValidating = true;
    });
    
    try {
      final storeReferralCode = await FirestoreService.getStoreReferralCodeByCode(code);
      
      setState(() {
        _isValidating = false;
        if (storeReferralCode != null && storeReferralCode.isActive) {
          _isValid = true;
          _errorMessage = null;
          widget.onStoreReferralCodeChanged(code);
        } else {
          _isValid = false;
          _errorMessage = '無効な店舗紹介コードです';
          widget.onStoreReferralCodeChanged(null);
        }
      });
    } catch (e) {
      setState(() {
        _isValidating = false;
        _isValid = false;
        _errorMessage = 'コードの確認に失敗しました';
        widget.onStoreReferralCodeChanged(null);
      });
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

#### 13.3.3 未承認店舗一覧（会社管理者用）
```dart
class PendingStoreApprovalsPage extends ConsumerWidget {
  final String companyId;
  
  const PendingStoreApprovalsPage({Key? key, required this.companyId}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingReferrals = ref.watch(pendingStoreReferralsProvider(companyId));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('未承認店舗'),
        backgroundColor: AppColors.primary,
      ),
      body: pendingReferrals.when(
        data: (referrals) {
          if (referrals.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '承認待ちの店舗はありません',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }
          
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: referrals.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final referral = referrals[index];
              return _buildPendingStoreCard(context, ref, referral);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('エラー: $error')),
      ),
    );
  }
  
  Widget _buildPendingStoreCard(BuildContext context, WidgetRef ref, StoreReferralRelationshipModel referral) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.store,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        referral.referredStoreName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '紹介者: ${referral.referrerStoreName}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: const Text(
                    '承認待ち',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Text(
              '申請日時: ${DateFormat('yyyy/MM/dd HH:mm').format(referral.referredAt)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectStoreReferral(context, ref, referral),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('拒否'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _approveStoreReferral(context, ref, referral),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('承認'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _approveStoreReferral(BuildContext context, WidgetRef ref, StoreReferralRelationshipModel referral) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('店舗承認'),
        content: Text('${referral.referredStoreName}を承認しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final success = await StoreReferralService.approveStoreReferral(
                relationshipId: referral.storeRelationshipId,
                approvedBy: 'current_admin_id', // 実際は認証情報から取得
              );
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('店舗を承認しました')),
                );
                ref.invalidate(pendingStoreReferralsProvider(companyId));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('承認に失敗しました')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('承認', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  void _rejectStoreReferral(BuildContext context, WidgetRef ref, StoreReferralRelationshipModel referral) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('店舗拒否'),
        content: Text('${referral.referredStoreName}の申請を拒否しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final success = await StoreReferralService.rejectStoreReferral(
                relationshipId: referral.storeRelationshipId,
                rejectedBy: 'current_admin_id', // 実際は認証情報から取得
              );
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('申請を拒否しました')),
                );
                ref.invalidate(pendingStoreReferralsProvider(companyId));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('拒否処理に失敗しました')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('拒否', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
```

### 13.4 Riverpodプロバイダー
```dart
// 店舗紹介コード取得
final storeReferralCodeProvider = FutureProvider.family<String, String>((ref, storeId) async {
  final storeReferralCode = await ref.watch(firestoreServiceProvider).getStoreReferralCodeByStoreId(storeId);
  return storeReferralCode?.referralCode ?? '';
});

// 店舗紹介統計取得
final storeReferralStatsProvider = FutureProvider.family<StoreReferralStats, String>((ref, storeId) async {
  return await StoreReferralService.getStoreReferralStats(storeId);
});

// 店舗紹介履歴取得
final storeReferralHistoryProvider = StreamProvider.family<List<StoreReferralRelationshipModel>, String>((ref, storeId) {
  return ref.watch(firestoreServiceProvider).getStoreReferralsByReferrer(storeId);
});

// 未承認店舗一覧取得（会社管理者用）
final pendingStoreReferralsProvider = StreamProvider.family<List<StoreReferralRelationshipModel>, String>((ref, companyId) {
  return ref.watch(firestoreServiceProvider).getPendingStoreReferralsByCompany(companyId);
});

// 現在の店舗情報
final currentStoreProvider = StreamProvider<StoreModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(firestoreServiceProvider).getStoreByOwnerId(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});
```

## 16. 会社管理者専用メール機能

### 16.1 概要
会社管理者のみがアクセス可能なメール機能。ユーザーからのフィードバックを受信・管理する機能を提供。

### 16.2 メール画面設計（店舗用アプリ）

#### 16.2.1 メール受信箱画面
```dart
class CompanyMailInboxView extends ConsumerStatefulWidget {
  @override
  _CompanyMailInboxViewState createState() => _CompanyMailInboxViewState();
}

class _CompanyMailInboxViewState extends ConsumerState<CompanyMailInboxView> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _currentCompanyId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // 現在の店舗の会社IDを取得
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = ref.read(currentStoreProvider).value;
      if (store != null) {
        setState(() {
          _currentCompanyId = store.companyId;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentCompanyId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('メール')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('メール'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: '未読'),
            Tab(text: '既読'),
            Tab(text: '対応中'),
            Tab(text: '完了'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeedbackList('unread'),
          _buildFeedbackList('read'),
          _buildFeedbackList('in_progress'),
          _buildFeedbackList('resolved'),
        ],
      ),
    );
  }

  Widget _buildFeedbackList(String status) {
    final feedbackListProvider = companyFeedbackByStatusProvider('${_currentCompanyId}_$status');
    
    return Consumer(
      builder: (context, ref, child) {
        final feedbackAsync = ref.watch(feedbackListProvider);
        
        return feedbackAsync.when(
          data: (feedbackList) {
            if (feedbackList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.mail_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _getEmptyMessage(status),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return RefreshIndicator(
              onRefresh: () async {
                ref.refresh(feedbackListProvider);
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: feedbackList.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final feedback = feedbackList[index];
                  return _buildFeedbackCard(feedback);
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('エラーが発生しました: $error'),
          ),
        );
      },
    );
  }

  Widget _buildFeedbackCard(UserFeedbackModel feedback) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showFeedbackDetail(feedback),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー部分
              Row(
                children: [
                  _getFeedbackIcon(feedback.category),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feedback.subject,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'From: ${feedback.userName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _getStatusChip(feedback.status),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // メッセージプレビュー
              Text(
                feedback.message,
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // 送信日時
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getCategoryDisplayName(feedback.category),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    DateFormat('MM/dd HH:mm').format(feedback.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getEmptyMessage(String status) {
    switch (status) {
      case 'unread':
        return '未読のメールはありません';
      case 'read':
        return '既読のメールはありません';
      case 'in_progress':
        return '対応中のメールはありません';
      case 'resolved':
        return '完了したメールはありません';
      default:
        return 'メールはありません';
    }
  }

  void _showFeedbackDetail(UserFeedbackModel feedback) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FeedbackDetailView(feedback: feedback),
      ),
    );
  }
}
```

#### 16.2.2 フィードバック詳細表示画面
```dart
class FeedbackDetailView extends ConsumerStatefulWidget {
  final UserFeedbackModel feedback;

  const FeedbackDetailView({required this.feedback});

  @override
  _FeedbackDetailViewState createState() => _FeedbackDetailViewState();
}

class _FeedbackDetailViewState extends ConsumerState<FeedbackDetailView> {
  @override
  void initState() {
    super.initState();
    // 詳細を開いた時点で「既読」にマーク
    if (widget.feedback.status == 'unread') {
      _updateFeedbackStatus('read');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('フィードバック詳細'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          _buildStatusUpdateButton(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFeedbackHeader(),
            const SizedBox(height: 20),
            _buildMessageSection(),
            const SizedBox(height: 20),
            _buildStatusSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusUpdateButton() {
    return PopupMenuButton<String>(
      onSelected: _updateFeedbackStatus,
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'read', child: Text('既読')),
        const PopupMenuItem(value: 'in_progress', child: Text('対応中')),
        const PopupMenuItem(value: 'resolved', child: Text('完了')),
      ],
      child: const Icon(Icons.more_vert),
    );
  }

  Future<void> _updateFeedbackStatus(String newStatus) async {
    try {
      await ref.read(firestoreServiceProvider).updateFeedbackStatus(
        widget.feedback.feedbackId,
        newStatus,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ステータスを「${_getStatusDisplayName(newStatus)}」に更新しました')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新に失敗しました: $e')),
        );
      }
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'unread':
        return '未読';
      case 'read':
        return '既読';
      case 'in_progress':
        return '対応中';
      case 'resolved':
        return '完了';
      default:
        return status;
    }
  }
}
```

### 16.3 共通UIヘルパーメソッド
```dart
// フィードバック関連の共通UIメソッド
mixin FeedbackUIHelpers {
  Widget getFeedbackIcon(String category) {
    IconData icon;
    Color color;
    
    switch (category) {
      case 'bug_report':
        icon = Icons.bug_report;
        color = Colors.red;
        break;
      case 'feature_request':
        icon = Icons.lightbulb_outline;
        color = Colors.blue;
        break;
      case 'complaint':
        icon = Icons.warning;
        color = Colors.orange;
        break;
      case 'compliment':
        icon = Icons.favorite;
        color = Colors.pink;
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
    }
    
    return Icon(icon, color: color, size: 20);
  }

  Widget getStatusChip(String status) {
    String label;
    Color color;
    
    switch (status) {
      case 'unread':
        label = '未読';
        color = Colors.red;
        break;
      case 'read':
        label = '既読';
        color = Colors.blue;
        break;
      case 'in_progress':
        label = '対応中';
        color = Colors.orange;
        break;
      case 'resolved':
        label = '完了';
        color = Colors.green;
        break;
      default:
        label = status;
        color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  String getCategoryDisplayName(String category) {
    switch (category) {
      case 'bug_report':
        return 'バグ報告';
      case 'feature_request':
        return '機能要望';
      case 'general_inquiry':
        return '一般問い合わせ';
      case 'complaint':
        return '苦情';
      case 'compliment':
        return 'お褒めの言葉';
      default:
        return 'その他';
    }
  }
}
```

### 16.4 Provider定義
```dart
// 会社別フィードバック取得（ステータス別）
final companyFeedbackByStatusProvider = StreamProvider.family<List<UserFeedbackModel>, String>((ref, params) {
  // paramsは「companyId_status」形式で渡される
  final parts = params.split('_');
  final companyId = parts[0];
  final status = parts[1];
  
  return ref.watch(firestoreServiceProvider).getFeedbackByCompanyAndStatus(companyId, status);
});

// 未読フィードバック数取得
final unreadFeedbackCountProvider = StreamProvider.family<int, String>((ref, companyId) {
  return ref.watch(firestoreServiceProvider).getUnreadFeedbackCount(companyId);
});
```

### 16.5 FirestoreService拡張
```dart
extension FeedbackService on FirestoreService {
  // フィードバック取得（会社別・ステータス別）
  Stream<List<UserFeedbackModel>> getFeedbackByCompanyAndStatus(String companyId, String status) {
    return _firestore
        .collection('user_feedback')
        .where('companyId', isEqualTo: companyId)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserFeedbackModel.fromJson({...doc.data(), 'feedbackId': doc.id}))
            .toList());
  }

  // フィードバックのステータス更新
  Future<void> updateFeedbackStatus(String feedbackId, String status) async {
    await _firestore.collection('user_feedback').doc(feedbackId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 未読フィードバック数の取得
  Stream<int> getUnreadFeedbackCount(String companyId) {
    return _firestore
        .collection('user_feedback')
        .where('companyId', isEqualTo: companyId)
        .where('status', isEqualTo: 'unread')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
```

この設計により、会社管理者は店舗用アプリの「メール」ボタンから、ユーザーが送信したフィードバックを効率的に管理できるようになります。フィードバックはステータス別に整理され、適切な対応状況を追跡できます。

## 17. 投稿機能設計（プレミアム限定）

### 17.1 投稿データモデル
```dart
class PostModel {
  final String postId;
  final String userId;
  final String storeId;
  final String title;
  final String content;
  final int rating;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final PostStats stats;

  const PostModel({
    required this.postId,
    required this.userId,
    required this.storeId,
    required this.title,
    required this.content,
    required this.rating,
    required this.imageUrls,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    required this.stats,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      postId: json['postId'],
      userId: json['userId'],
      storeId: json['storeId'],
      title: json['title'],
      content: json['content'],
      rating: json['rating'],
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      isActive: json['isActive'] ?? true,
      stats: PostStats.fromJson(json['stats'] ?? {}),
    );
  }
}

class PostStats {
  final int likeCount;
  final int commentCount;
  final int viewCount;

  const PostStats({
    this.likeCount = 0,
    this.commentCount = 0,
    this.viewCount = 0,
  });

  factory PostStats.fromJson(Map<String, dynamic> json) {
    return PostStats(
      likeCount: json['likeCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      viewCount: json['viewCount'] ?? 0,
    );
  }
}
```

### 17.2 投稿・クーポンタブ画面設計

#### 17.2.1 投稿タブメイン画面
```dart
class PostsTabScreen extends ConsumerStatefulWidget {
  const PostsTabScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PostsTabScreen> createState() => _PostsTabScreenState();
}

class _PostsTabScreenState extends ConsumerState<PostsTabScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('投稿'),
        backgroundColor: AppColors.primary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: '投稿'),
            Tab(text: 'クーポン'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 投稿タブ
          PostsGridView(),
          
          // クーポンタブ
          CouponsGridView(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
```

#### 17.2.2 投稿グリッドビュー（2×N、20件表示、新規投稿順）
```dart
class PostsGridView extends ConsumerWidget {
  const PostsGridView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(recentPostsProvider);
    
    return posts.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorWidget(error: error.toString()),
      data: (postsList) => RefreshIndicator(
        onRefresh: () async {
          ref.refresh(recentPostsProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(12.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75, // 縦長のカード
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => PostCard(post: postsList[index]),
                  childCount: math.min(postsList.length, 20), // 最大20件
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final PostModel post;
  
  const PostCard({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 写真（上部）
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                width: double.infinity,
                child: post.imageUrls.isNotEmpty
                  ? Image.network(
                      post.imageUrls.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: 40,
                            ),
                          ),
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.photo,
                        color: Colors.grey,
                        size: 40,
                      ),
                    ),
              ),
            ),
          ),
          
          // コンテンツ部分
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // タイトル
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // テキスト
                  Expanded(
                    child: Text(
                      post.content,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 店舗情報（下部）
                  _buildStoreInfo(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreInfo() {
    return Consumer(
      builder: (context, ref, _) {
        final store = ref.watch(storeProvider(post.storeId));
        
        return store.when(
          data: (storeData) => Row(
            children: [
              // 小さな店舗アイコン
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  storeData.images.isNotEmpty ? storeData.images.first : '',
                  width: 16,
                  height: 16,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(
                        width: 16,
                        height: 16,
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.store,
                          size: 12,
                          color: Colors.grey,
                        ),
                      ),
                ),
              ),
              const SizedBox(width: 6),
              
              // 店舗名
              Expanded(
                child: Text(
                  storeData.name,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          loading: () => const SizedBox(height: 16),
          error: (error, _) => const SizedBox(height: 16),
        );
      },
    );
  }
}
```

#### 17.2.3 クーポングリッドビュー（2×N、20件表示、有効期限近い順）
```dart
class CouponsGridView extends ConsumerWidget {
  const CouponsGridView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coupons = ref.watch(availableCouponsProvider);
    
    return coupons.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorWidget(error: error.toString()),
      data: (couponsList) => RefreshIndicator(
        onRefresh: () async {
          ref.refresh(availableCouponsProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(12.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75, // 縦長のカード
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => CouponCard(coupon: couponsList[index]),
                  childCount: math.min(couponsList.length, 20), // 最大20件
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CouponCard extends StatelessWidget {
  final CouponModel coupon;
  
  const CouponCard({Key? key, required this.coupon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getExpiryColor(),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 写真（上部）
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Container(
                    width: double.infinity,
                    child: coupon.imageUrls != null && coupon.imageUrls!.isNotEmpty
                      ? Image.network(
                          coupon.imageUrls!.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.local_offer,
                                  color: Colors.grey,
                                  size: 40,
                                ),
                              ),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.local_offer,
                            color: Colors.grey,
                            size: 40,
                          ),
                        ),
                  ),
                ),
                
                // 有効期限バッジ（右上）
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getExpiryColor(),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getExpiryText(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // コンテンツ部分
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // タイトル
                  Text(
                    coupon.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // テキスト
                  Expanded(
                    child: Text(
                      coupon.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 店舗情報（下部）
                  _buildStoreInfo(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getExpiryText() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final expiryDate = DateTime(coupon.validUntil.year, coupon.validUntil.month, coupon.validUntil.day);

    if (expiryDate.isAtSameMomentAs(today)) {
      return '本日まで';
    } else if (expiryDate.isAtSameMomentAs(tomorrow)) {
      return '明日まで';
    } else {
      return '${coupon.validUntil.year}/${coupon.validUntil.month.toString().padLeft(2, '0')}/${coupon.validUntil.day.toString().padLeft(2, '0')}まで';
    }
  }

  Color _getExpiryColor() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final expiryDate = DateTime(coupon.validUntil.year, coupon.validUntil.month, coupon.validUntil.day);

    if (expiryDate.isAtSameMomentAs(today)) {
      return Colors.red; // 本日まで
    } else if (expiryDate.isAtSameMomentAs(tomorrow)) {
      return Colors.orange; // 明日まで
    } else {
      return AppColors.primary; // それ以外
    }
  }

  Widget _buildStoreInfo() {
    return Consumer(
      builder: (context, ref, _) {
        final store = ref.watch(storeProvider(coupon.storeId));
        
        return store.when(
          data: (storeData) => Row(
            children: [
              // 小さな店舗アイコン
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  storeData.images.isNotEmpty ? storeData.images.first : '',
                  width: 16,
                  height: 16,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(
                        width: 16,
                        height: 16,
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.store,
                          size: 12,
                          color: Colors.grey,
                        ),
                      ),
                ),
              ),
              const SizedBox(width: 6),
              
              // 店舗名
              Expanded(
                child: Text(
                  storeData.name,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          loading: () => const SizedBox(height: 16),
          error: (error, _) => const SizedBox(height: 16),
        );
      },
    );
  }
}
```

#### 17.2.4 データプロバイダー
```dart
// 最新投稿取得プロバイダー（新規投稿順）
final recentPostsProvider = StreamProvider<List<PostModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('posts')
      .where('isActive', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .limit(20)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => PostModel.fromJson({...doc.data(), 'postId': doc.id}))
          .toList());
});

// 利用可能クーポン取得プロバイダー（有効期限近い順）
final availableCouponsProvider = StreamProvider<List<CouponModel>>((ref) {
  final now = DateTime.now();
  
  return FirebaseFirestore.instance
      .collection('coupons')
      .where('isActive', isEqualTo: true)
      .where('validUntil', isGreaterThan: Timestamp.fromDate(now))
      .orderBy('validUntil', descending: false) // 有効期限近い順
      .limit(20)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => CouponModel.fromJson({...doc.data(), 'couponId': doc.id}))
          .toList());
});
```

### 17.3 投稿作成画面設計
```dart
class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final List<File> _images = [];
  String? _selectedStoreId;
  int _rating = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final stores = ref.watch(nearbyStoresProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('レビューを投稿'),
        actions: [
          TextButton(
            onPressed: _isValidPost() ? _submitPost : null,
            child: const Text('投稿', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStoreSelector(stores),
            const SizedBox(height: 16),
            _buildRatingSelector(),
            const SizedBox(height: 16),
            _buildTitleField(),
            const SizedBox(height: 16),
            _buildContentField(),
            const SizedBox(height: 16),
            _buildImageSelector(),
            const SizedBox(height: 16),
            _buildPreview(),
          ],
        ),
      ),
    );
  }

  bool _isValidPost() {
    return _titleController.text.isNotEmpty &&
           _contentController.text.isNotEmpty &&
           _selectedStoreId != null &&
           _rating > 0;
  }
}
```

## 18. クーポン機能詳細設計

### 18.1 クーポンデータモデル拡張
```dart
class CouponModel {
  final String couponId;
  final String storeId;
  final String title;
  final String description;
  final CouponType type;
  final CouponValue value;
  final CouponConditions conditions;
  final DateTime validFrom;
  final DateTime validUntil;
  final int totalQuantity;
  final int usedQuantity;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CouponModel({
    required this.couponId,
    required this.storeId,
    required this.title,
    required this.description,
    required this.type,
    required this.value,
    required this.conditions,
    required this.validFrom,
    required this.validUntil,
    required this.totalQuantity,
    this.usedQuantity = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });
}

enum CouponType {
  percentage,      // パーセント割引
  fixedAmount,     // 固定額割引
  freeItem,        // 無料商品
  pointMultiplier, // ポイント倍率
}
```

## 19. Firebase Cloud Functions設計

### 19.1 ポイント処理Functions
```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// ポイント付与処理
exports.awardPoints = functions.firestore
  .document('transactions/{transactionId}')
  .onCreate(async (snap, context) => {
    const transaction = snap.data();
    const { userId, storeId, points, type } = transaction;
    
    if (type !== 'award') return;
    
    try {
      // ユーザーのポイント更新
      await updateUserPoints(userId, points);
      
      // 経験値付与
      await awardExperience(userId, points);
      
      // バッジチェック
      await checkAndAwardBadges(userId);
      
      // 店舗の月間発行ポイント更新
      await updateStoreMonthlyPoints(storeId, points);
      
    } catch (error) {
      console.error('ポイント付与エラー:', error);
      throw new functions.https.HttpsError('internal', 'ポイント付与に失敗しました');
    }
  });

async function calculateLevel(experience: number): Promise<number> {
  // レベル計算式: experience = baseExp * (level ^ 1.5)
  const baseExp = 100;
  return Math.floor(Math.pow(experience / baseExp, 1/1.5)) + 1;
}
```

## 20. プッシュ通知システム設計

### 20.1 FCM設定とトークン管理
```dart
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize() async {
    // 通知権限リクエスト
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // FCMトークン取得
      String? token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToDatabase(token);
      }

      // トークンリフレッシュ監視
      _messaging.onTokenRefresh.listen(_saveTokenToDatabase);
    }

    // フォアグラウンド通知設定
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    }
  }
}
```

## 21. 統合ダッシュボード設計（会社管理者限定）

### 21.1 統合ダッシュボード画面
```dart
class CompanyDashboardScreen extends ConsumerWidget {
  const CompanyDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final companyStats = ref.watch(companyStatsProvider(user?.companyId ?? ''));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('統合ダッシュボード'),
        backgroundColor: AppColors.primary,
      ),
      body: companyStats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorWidget(error: error.toString()),
        data: (stats) => SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildKPICards(stats),
              const SizedBox(height: 20),
              _buildRevenueChart(stats),
              const SizedBox(height: 20),
              _buildStorePerformanceList(stats),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPICards(CompanyStats stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      children: [
        KPICard(
          title: '総店舗数',
          value: '${stats.totalStores}',
          icon: Icons.store,
          color: AppColors.primary,
        ),
        KPICard(
          title: '月間売上',
          value: '¥${NumberFormat('#,###').format(stats.monthlyRevenue)}',
          icon: Icons.monetization_on,
          color: Colors.green,
        ),
        KPICard(
          title: '総利用者数',
          value: '${stats.totalUsers}',
          icon: Icons.people,
          color: Colors.blue,
        ),
        KPICard(
          title: 'ポイント発行量',
          value: '${NumberFormat('#,###').format(stats.totalPointsIssued)}P',
          icon: Icons.card_giftcard,
          color: Colors.orange,
        ),
      ],
    );
  }
}
```

## 22. オフライン機能設計

### 22.1 オフラインデータキャッシュ
```dart
class OfflineService {
  static const String _kCachedStoresKey = 'cached_stores';
  static const String _kPendingTransactionsKey = 'pending_transactions';

  final SharedPreferences _prefs;
  final Box _hiveBox;

  OfflineService(this._prefs, this._hiveBox);

  // 店舗データのキャッシュ
  Future<void> cacheStores(List<StoreModel> stores) async {
    final storesJson = stores.map((store) => store.toJson()).toList();
    await _hiveBox.put(_kCachedStoresKey, storesJson);
  }

  // キャッシュされた店舗データの取得
  List<StoreModel> getCachedStores() {
    final cachedData = _hiveBox.get(_kCachedStoresKey, defaultValue: <dynamic>[]);
    return (cachedData as List)
        .map((json) => StoreModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  // オフライン時の取引データを保存
  Future<void> savePendingTransaction(TransactionModel transaction) async {
    final pendingTransactions = await getPendingTransactions();
    pendingTransactions.add(transaction);
    
    final transactionsJson = pendingTransactions.map((t) => t.toJson()).toList();
    await _hiveBox.put(_kPendingTransactionsKey, transactionsJson);
  }

  Future<List<TransactionModel>> getPendingTransactions() async {
    final cachedData = _hiveBox.get(_kPendingTransactionsKey, defaultValue: <dynamic>[]);
    return (cachedData as List)
        .map((json) => TransactionModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }
}
```

### 22.2 ネットワーク状態監視
```dart
final networkStatusProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map((result) {
    return result != ConnectivityResult.none;
  });
});

final offlineServiceProvider = Provider<OfflineService>((ref) {
  return OfflineService(
    ref.read(sharedPreferencesProvider),
    ref.read(hiveBoxProvider),
  );
});
```

この拡張により、design.mdは requirements.md で定義されたすべての機能を網羅する完全な設計仕様書となります。Flutter + Firebase アーキテクチャを活用し、スケーラブルで保守性の高いモバイルアプリケーションの技術的実現方法を詳細に設計しています。