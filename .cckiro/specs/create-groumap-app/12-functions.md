# 12. Firebase Cloud Functions & プッシュ通知システム設計

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

### 19.2 課金システムFunctions

#### プラン変更処理
```typescript
// プラン変更処理
exports.onPlanChange = functions.firestore
  .document('subscriptions/{subscriptionId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    if (before.planType !== after.planType) {
      await updateStorePlanFeatures(after.storeId, after.planType);
      await sendPlanChangeNotification(after.storeId, after.planType);
    }
  });

async function updateStorePlanFeatures(storeId: string, planType: string) {
  const features = planType === 'premium' ? {
    maxCoupons: 50,
    advancedAnalytics: true,
    customBranding: true,
    prioritySupport: true
  } : {
    maxCoupons: 10,
    advancedAnalytics: false,
    customBranding: false,
    prioritySupport: false
  };

  await admin.firestore()
    .collection('stores')
    .doc(storeId)
    .update({ planFeatures: features });
}
```

### 19.3 レベル計算アルゴリズム

#### 経験値とレベルシステム
```typescript
// 経験値計算アルゴリズム
async function awardExperience(userId: string, points: number) {
  const experienceGained = Math.floor(points * 0.8); // ポイントの80%を経験値として付与
  
  const userRef = admin.firestore().collection('users').doc(userId);
  
  await admin.firestore().runTransaction(async (transaction) => {
    const userDoc = await transaction.get(userRef);
    const userData = userDoc.data();
    
    const currentExperience = userData?.experience || 0;
    const newExperience = currentExperience + experienceGained;
    const newLevel = await calculateLevel(newExperience);
    const currentLevel = userData?.level || 1;
    
    // レベル更新
    transaction.update(userRef, {
      experience: newExperience,
      level: newLevel,
      lastExperienceGain: admin.firestore.FieldValue.serverTimestamp()
    });
    
    // レベルアップ時の処理
    if (newLevel > currentLevel) {
      await handleLevelUp(userId, newLevel, transaction);
    }
  });
}

async function handleLevelUp(userId: string, newLevel: number, transaction: any) {
  // レベルアップボーナス
  const bonusPoints = newLevel * 100;
  
  // ボーナスポイント付与
  const userRef = admin.firestore().collection('users').doc(userId);
  transaction.update(userRef, {
    points: admin.firestore.FieldValue.increment(bonusPoints)
  });
  
  // レベルアップ通知
  await sendLevelUpNotification(userId, newLevel, bonusPoints);
}
```

### 19.4 バッジシステムFunctions
```typescript
// バッジチェック処理
async function checkAndAwardBadges(userId: string) {
  const userRef = admin.firestore().collection('users').doc(userId);
  const userDoc = await userRef.get();
  const userData = userDoc.data();
  
  if (!userData) return;
  
  const currentBadges = userData.badges || [];
  const newBadges = [];
  
  // 各種バッジの条件チェック
  if (userData.totalPoints >= 1000 && !currentBadges.includes('point_collector')) {
    newBadges.push('point_collector');
  }
  
  if (userData.visitedStores >= 10 && !currentBadges.includes('explorer')) {
    newBadges.push('explorer');
  }
  
  if (userData.level >= 10 && !currentBadges.includes('level_master')) {
    newBadges.push('level_master');
  }
  
  // 新しいバッジがある場合更新
  if (newBadges.length > 0) {
    await userRef.update({
      badges: [...currentBadges, ...newBadges]
    });
    
    await sendBadgeNotification(userId, newBadges);
  }
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

### 20.2 通知処理Functions
```typescript
// 通知送信サービス
class FCMService {
  static async sendToUser(options: {
    userId: string;
    title: string;
    body: string;
    data?: any;
  }) {
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(options.userId)
      .get();
    
    const fcmToken = userDoc.data()?.fcmToken;
    if (!fcmToken) return;
    
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: options.title,
        body: options.body,
      },
      data: options.data || {},
      android: {
        notification: {
          channelId: 'default',
          priority: 'high',
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          }
        }
      }
    });
  }

  static async sendToStore(options: {
    storeId: string;
    title: string;
    body: string;
    data?: any;
  }) {
    const storeDoc = await admin.firestore()
      .collection('stores')
      .doc(options.storeId)
      .get();
    
    const fcmToken = storeDoc.data()?.fcmToken;
    if (!fcmToken) return;
    
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: options.title,
        body: options.body,
      },
      data: options.data || {},
    });
  }

  static async sendToMultiple(options: {
    tokens: string[];
    title: string;
    body: string;
    data?: any;
  }) {
    if (options.tokens.length === 0) return;
    
    await admin.messaging().sendMulticast({
      tokens: options.tokens,
      notification: {
        title: options.title,
        body: options.body,
      },
      data: options.data || {},
    });
  }
}
```

### 20.3 通知種別と処理

#### レベルアップ通知
```typescript
async function sendLevelUpNotification(userId: string, level: number, bonusPoints: number) {
  await FCMService.sendToUser({
    userId,
    title: `🎉 レベルアップ！`,
    body: `レベル${level}に到達しました！ボーナス${bonusPoints}ポイント獲得！`,
    data: {
      type: 'level_up',
      level: level.toString(),
      bonusPoints: bonusPoints.toString(),
    }
  });
}
```

#### バッジ獲得通知
```typescript
async function sendBadgeNotification(userId: string, badges: string[]) {
  const badgeNames = badges.map(badge => getBadgeName(badge)).join(', ');
  
  await FCMService.sendToUser({
    userId,
    title: '🏆 新しいバッジ獲得！',
    body: `${badgeNames}を獲得しました！`,
    data: {
      type: 'badge_awarded',
      badges: JSON.stringify(badges),
    }
  });
}
```

#### 友達紹介通知
```typescript
async function sendReferralNotifications(relationship: ReferralRelationshipModel) {
  // 紹介者への通知
  await FCMService.sendToUser({
    userId: relationship.referrerId,
    title: '友達紹介成功！',
    body: `${relationship.referredName}さんが登録してくれました！${relationship.referrerReward}ポイント獲得！`,
    data: {
      type: 'referral_success',
      referredName: relationship.referredName,
      reward: relationship.referrerReward.toString(),
    }
  });
  
  // 被紹介者への通知
  await FCMService.sendToUser({
    userId: relationship.referredUserId,
    title: '友達紹介ボーナス！',
    body: `友達紹介で${relationship.referredReward}ポイント獲得しました！`,
    data: {
      type: 'referral_bonus',
      reward: relationship.referredReward.toString(),
    }
  });
}
```

#### 店舗承認通知
```typescript
async function sendStoreApprovalNotifications(storeId: string, approved: boolean) {
  const title = approved ? 'アカウントが承認されました！' : 'アカウント申請について';
  const body = approved 
    ? 'GrouMapへようこそ！アカウントが正式に承認されました。'
    : '申請が承認されませんでした。詳細については運営にお問い合わせください。';
  
  await FCMService.sendToStore({
    storeId,
    title,
    body,
    data: {
      type: 'store_approval',
      approved: approved.toString(),
    }
  });
}
```

### 20.4 通知設定管理
```dart
class NotificationSettings {
  bool pointNotifications;
  bool levelUpNotifications;
  bool badgeNotifications;
  bool couponNotifications;
  bool newsNotifications;
  
  NotificationSettings({
    this.pointNotifications = true,
    this.levelUpNotifications = true,
    this.badgeNotifications = true,
    this.couponNotifications = true,
    this.newsNotifications = true,
  });
  
  Map<String, dynamic> toJson() => {
    'pointNotifications': pointNotifications,
    'levelUpNotifications': levelUpNotifications,
    'badgeNotifications': badgeNotifications,
    'couponNotifications': couponNotifications,
    'newsNotifications': newsNotifications,
  };
  
  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      pointNotifications: json['pointNotifications'] ?? true,
      levelUpNotifications: json['levelUpNotifications'] ?? true,
      badgeNotifications: json['badgeNotifications'] ?? true,
      couponNotifications: json['couponNotifications'] ?? true,
      newsNotifications: json['newsNotifications'] ?? true,
    );
  }
}
```

### 20.5 スケジュール通知
```typescript
// 定期通知の設定
exports.scheduledNotifications = functions.pubsub
  .schedule('0 19 * * *') // 毎日19:00
  .timeZone('Asia/Tokyo')
  .onRun(async () => {
    // アクティブでないユーザーに対する再エンゲージメント通知
    const inactiveUsers = await getInactiveUsers(7); // 7日間未アクセス
    
    for (const user of inactiveUsers) {
      await FCMService.sendToUser({
        userId: user.id,
        title: 'GrouMapでお得を見つけよう！',
        body: '新しいクーポンやお店が追加されました。今すぐチェック！',
        data: {
          type: 'reengagement',
        }
      });
    }
  });

async function getInactiveUsers(daysSinceLastAccess: number): Promise<any[]> {
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - daysSinceLastAccess);
  
  const snapshot = await admin.firestore()
    .collection('users')
    .where('lastAccessAt', '<', cutoffDate)
    .where('fcmToken', '!=', null)
    .limit(100) // バッチ処理制限
    .get();
  
  return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
}
```