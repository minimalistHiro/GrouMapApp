import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import { issueQRToken, verifyQRToken } from './utils/jwt';

// Firebase Admin SDK初期化
initializeApp();
const db = getFirestore();
const auth = getAuth();

// タイムゾーン設定
process.env.TZ = 'Asia/Tokyo';

// QRトークン発行関数
export const issueQrToken = onCall(
  {
    region: 'asia-northeast1',
    enforceAppCheck: true,
  },
  async (request) => {
    try {
      // 認証チェック
      if (!request.auth) {
        throw new HttpsError('unauthenticated', 'User must be authenticated');
      }

      const uid = request.auth.uid;
      const { deviceId } = request.data || {};

      // ユーザーの存在確認
      try {
        await auth.getUser(uid);
      } catch (error) {
        throw new HttpsError('not-found', 'User not found');
      }

      // JWTトークンを発行
      const result = await issueQRToken(uid, deviceId);

      console.log(`QR token issued for user ${uid}, JTI: ${result.jti}`);

      return {
        token: result.token,
        expiresAt: result.expiresAt,
        jti: result.jti,
      };
    } catch (error) {
      console.error('Error issuing QR token:', error);
      if (error instanceof HttpsError) {
        throw error;
      }
      throw new HttpsError('internal', 'Failed to issue QR token');
    }
  }
);

// QRトークン検証関数
export const verifyQrToken = onCall(
  {
    region: 'asia-northeast1',
    enforceAppCheck: true,
  },
  async (request) => {
    try {
      // 認証チェック
      if (!request.auth) {
        throw new HttpsError('unauthenticated', 'Store must be authenticated');
      }

      const { token, storeId } = request.data;
      
      if (!token || !storeId) {
        throw new HttpsError('invalid-argument', 'Missing required parameters: token and storeId');
      }

      // ストアロールチェック
      const user = await auth.getUser(request.auth.uid);
      const customClaims = user.customClaims || {};
      const userRole = customClaims.role;

      if (!userRole || !['store', 'company'].includes(userRole)) {
        throw new HttpsError('permission-denied', 'Only stores can verify QR tokens');
      }

      // JWTトークンを検証
      const payload = await verifyQRToken(token);

      // リプレイ防止チェック
      const jti = payload.jti;
      const jtiRef = db.collection('qrJti').doc(jti);

      // トランザクションでJTIの使用をチェック
      await db.runTransaction(async (transaction) => {
        const jtiDoc = await transaction.get(jtiRef);
        
        if (jtiDoc.exists) {
          // 既に使用済み
          throw new HttpsError('failed-precondition', 'Token has already been used');
        }

        // JTIを記録
        transaction.set(jtiRef, {
          usedAt: new Date(),
          storeId: storeId,
          uid: payload.sub,
          deviceId: payload.deviceId || null,
        });
      });

      // チェックイン記録を作成
      await recordCheckIn(payload.sub, storeId, jti, payload.deviceId);

      console.log(`QR token verified for user ${payload.sub} at store ${storeId}`);

      return {
        uid: payload.sub,
        status: 'OK',
        jti: jti,
      };
    } catch (error) {
      console.error('Error verifying QR token:', error);
      if (error instanceof HttpsError) {
        throw error;
      }
      throw new HttpsError('internal', 'Failed to verify QR token');
    }
  }
);

// チェックイン記録
async function recordCheckIn(
  userId: string, 
  storeId: string, 
  jti: string, 
  deviceId?: string
): Promise<void> {
  try {
    const checkInData = {
      userId,
      storeId,
      jti,
      deviceId: deviceId || null,
      timestamp: new Date(),
      createdAt: new Date()
    };
    
    await db.collection('check_ins').add(checkInData);
    
    // ユーザーのポイントを更新（例：10ポイント付与）
    await updateUserPoints(userId, 10, storeId);
    
    console.log(`Check-in recorded for user ${userId} at store ${storeId}`);
  } catch (error) {
    console.error('Error recording check-in:', error);
    throw error;
  }
}

// ユーザーポイント更新
async function updateUserPoints(userId: string, points: number, storeId: string): Promise<void> {
  try {
    const userRef = db.collection('users').doc(userId);
    
    await db.runTransaction(async (transaction) => {
      const userDoc = await transaction.get(userRef);
      
      if (userDoc.exists) {
        const currentPoints = userDoc.data()?.points || 0;
        const newPoints = currentPoints + points;
        
        transaction.update(userRef, {
          points: newPoints,
          lastCheckIn: new Date(),
          updatedAt: new Date()
        });
        
        // ポイント履歴を記録
        const pointTransaction = {
          userId,
          amount: points,
          type: 'check_in',
          description: `QRコードチェックイン (店舗: ${storeId})`,
          storeId: storeId,
          timestamp: new Date(),
          createdAt: new Date()
        };
        
        transaction.set(db.collection('point_transactions').doc(), pointTransaction);
      }
    });
  } catch (error) {
    console.error('Error updating user points:', error);
    throw error;
  }
}

// チェックイン統計の更新（オプション）
export const updateCheckInStats = onDocumentCreated(
  {
    document: 'check_ins/{checkInId}',
    region: 'asia-northeast1'
  },
  async (event) => {
    try {
      const checkInData = event.data?.data();
      if (!checkInData) return;
      
      const { userId, timestamp } = checkInData;
      const date = new Date(timestamp.seconds * 1000);
      const dateStr = date.toISOString().split('T')[0]; // YYYY-MM-DD
      
      // 日別チェックイン統計を更新
      const statsRef = db.collection('daily_stats').doc(dateStr);
      await statsRef.set({
        date: dateStr,
        totalCheckIns: 1,
        uniqueUsers: [userId],
        lastUpdated: new Date()
      }, { merge: true });
      
      console.log(`Stats updated for date ${dateStr}`);
    } catch (error) {
      console.error('Error updating check-in stats:', error);
    }
  }
);
