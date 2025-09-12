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