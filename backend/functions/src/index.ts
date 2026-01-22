import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onDocumentCreated, onDocumentWritten } from 'firebase-functions/v2/firestore';
import { initializeApp } from 'firebase-admin/app';
import { FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import { getMessaging } from 'firebase-admin/messaging';
import { defineSecret } from 'firebase-functions/params';
import nodemailer from 'nodemailer';
import { createHash, randomInt } from 'crypto';
import { issueQRToken, verifyQRToken } from './utils/jwt';

// Firebase Admin SDK初期化
initializeApp();
const db = getFirestore();
const auth = getAuth();
const messaging = getMessaging();

// タイムゾーン設定
process.env.TZ = 'Asia/Tokyo';

// デバッグ用のログ
console.log('Cloud Functions initialized with updated permissions');

const NOTIFICATIONS_COLLECTION = 'notifications';
const NOTIFICATION_SETTINGS_COLLECTION = 'notification_settings';
const USERS_COLLECTION = 'users';
const EMAIL_OTP_COLLECTION = 'email_otp';
const ANNOUNCEMENT_TOPIC = 'announcements';

const SMTP_HOST = defineSecret('SMTP_HOST');
const SMTP_PORT = defineSecret('SMTP_PORT');
const SMTP_USER = defineSecret('SMTP_USER');
const SMTP_PASS = defineSecret('SMTP_PASS');
const SMTP_FROM = defineSecret('SMTP_FROM');
const SMTP_SECURE = defineSecret('SMTP_SECURE');

function getDateKey(date: Date): string {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Tokyo',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(date);
}

type NotificationData = {
  userId?: string;
  title?: string;
  body?: string;
  content?: string;
  type?: string;
  actionUrl?: string;
  category?: string;
  isPublished?: boolean;
  isActive?: boolean;
  isDelivered?: boolean;
};

type EmailOtpRecord = {
  codeHash?: string;
  expiresAt?: Timestamp;
  attempts?: number;
  lastSentAt?: Timestamp;
};

async function getUserFcmTokens(userId: string): Promise<string[]> {
  const tokens = new Set<string>();

  const userDoc = await db.collection(USERS_COLLECTION).doc(userId).get();
  if (userDoc.exists) {
    const data = userDoc.data() as { fcmToken?: string; fcmTokens?: string[] } | undefined;
    if (data?.fcmToken) {
      tokens.add(data.fcmToken);
    }
    if (Array.isArray(data?.fcmTokens)) {
      data?.fcmTokens?.forEach((token) => {
        if (token) tokens.add(token);
      });
    }
  }

  const tokenDocs = await db
    .collection(USERS_COLLECTION)
    .doc(userId)
    .collection('fcmTokens')
    .get();
  tokenDocs.forEach((doc) => {
    const token = (doc.data() as { token?: string } | undefined)?.token ?? doc.id;
    if (token) tokens.add(token);
  });

  return Array.from(tokens);
}

async function isPushEnabled(userId: string): Promise<boolean> {
  const settingsDoc = await db.collection(NOTIFICATION_SETTINGS_COLLECTION).doc(userId).get();
  if (!settingsDoc.exists) {
    return true;
  }
  const data = settingsDoc.data() as { pushEnabled?: boolean } | undefined;
  return data?.pushEnabled !== false;
}

function buildNotificationPayload(notificationId: string, data: NotificationData) {
  const title = data.title ?? 'お知らせ';
  const body = data.body ?? data.content ?? '';

  const payloadData: Record<string, string> = {
    notificationId,
  };
  if (data.type) payloadData.type = data.type;
  if (data.actionUrl) payloadData.actionUrl = data.actionUrl;
  if (data.category) payloadData.category = data.category;

  return {
    title,
    body,
    data: payloadData,
  };
}

function createOtp(): string {
  const value = randomInt(0, 1000000);
  return value.toString().padStart(6, '0');
}

function hashOtp(code: string, uid: string): string {
  return createHash('sha256').update(`${uid}:${code}`).digest('hex');
}

function buildOtpEmailText(code: string): string {
  return [
    'Groumapをご利用いただきありがとうございます。',
    '以下の6桁の認証コードをアプリに入力してください。',
    '',
    `認証コード: ${code}`,
    '有効期限: 10分',
    '',
    'このメールに心当たりがない場合は、破棄してください。',
    '',
    'Groumap サポート',
  ].join('\n');
}

function getSmtpConfig() {
  const host = SMTP_HOST.value();
  const port = Number(SMTP_PORT.value() ?? '587');
  const user = SMTP_USER.value();
  const pass = SMTP_PASS.value();
  const from = SMTP_FROM.value();
  const secure = (SMTP_SECURE.value() ?? 'false').toLowerCase() === 'true';

  if (!host || !user || !pass || !from) {
    throw new HttpsError('failed-precondition', 'メール送信の設定が未完了です');
  }

  return {
    host,
    port,
    secure,
    auth: {
      user,
      pass,
    },
    from,
  };
}

export const sendNotificationOnPublish = onDocumentWritten(
  {
    document: `${NOTIFICATIONS_COLLECTION}/{notificationId}`,
    region: 'asia-northeast1',
  },
  async (event) => {
    if (!event.data?.after.exists) return;

    const notificationId = event.data.after.id;
    const afterData = event.data.after.data() as NotificationData | undefined;
    if (!afterData) return;

    const beforeData = event.data.before.exists
      ? (event.data.before.data() as NotificationData | undefined)
      : undefined;

    const wasPublished = beforeData?.isPublished === true;
    const isPublished = afterData.isPublished !== false;
    const isActive = afterData.isActive !== false;
    const alreadyDelivered = afterData.isDelivered === true;
    const userId = afterData.userId;

    if (alreadyDelivered) {
      return;
    }

    const isCreate = !event.data.before.exists;
    const shouldSendToTopic =
      !userId &&
      isActive &&
      ((isCreate && isPublished) || (!isCreate && !wasPublished && isPublished));
    const shouldSendToUser = Boolean(userId) && isCreate;
    if (!shouldSendToTopic && !shouldSendToUser) {
      return;
    }

    const payload = buildNotificationPayload(notificationId, afterData);

    if (shouldSendToUser && userId) {
      const pushEnabled = await isPushEnabled(userId);
      if (!pushEnabled) {
        console.log(`Push disabled for user ${userId}, skipping notification ${notificationId}`);
        return;
      }

      const tokens = await getUserFcmTokens(userId);
      if (tokens.length === 0) {
        console.log(`No FCM tokens found for user ${userId}, skipping notification ${notificationId}`);
        return;
      }

      const response = await messaging.sendEachForMulticast({
        tokens,
        notification: {
          title: payload.title,
          body: payload.body,
        },
        data: payload.data,
        android: {
          notification: {
            sound: 'default',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
            },
          },
        },
      });

      console.log(
        `Sent notification ${notificationId} to user ${userId}: ` +
          `${response.successCount} success, ${response.failureCount} failure`
      );
    }

    if (shouldSendToTopic) {
      await messaging.send({
        topic: ANNOUNCEMENT_TOPIC,
        notification: {
          title: payload.title,
          body: payload.body,
        },
        data: payload.data,
        android: {
          notification: {
            sound: 'default',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
            },
          },
        },
      });
      console.log(`Sent announcement notification ${notificationId} to topic ${ANNOUNCEMENT_TOPIC}`);
    }

    await event.data.after.ref.update({
      isDelivered: true,
      deliveredAt: new Date(),
    });
  }
);

export const requestEmailOtp = onCall(
  {
    region: 'asia-northeast1',
    secrets: [SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, SMTP_FROM, SMTP_SECURE],
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError('unauthenticated', 'ログインが必要です');
    }

    const uid = request.auth.uid;
    const userRecord = await auth.getUser(uid);
    const email = userRecord.email;

    if (!email) {
      throw new HttpsError('failed-precondition', 'メールアドレスが設定されていません');
    }

    const otpRef = db.collection(EMAIL_OTP_COLLECTION).doc(uid);
    const otpSnapshot = await otpRef.get();
    if (otpSnapshot.exists) {
      const existing = otpSnapshot.data() as EmailOtpRecord;
      const lastSentAt = existing.lastSentAt?.toDate();
      if (lastSentAt && Date.now() - lastSentAt.getTime() < 60 * 1000) {
        throw new HttpsError('resource-exhausted', '認証コードは1分以内に再送信できません');
      }
    }

    const code = createOtp();
    const codeHash = hashOtp(code, uid);
    const expiresAt = Timestamp.fromDate(new Date(Date.now() + 10 * 60 * 1000));

    await otpRef.set(
      {
        codeHash,
        expiresAt,
        attempts: 0,
        lastSentAt: Timestamp.fromDate(new Date()),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    try {
      const smtpConfig = getSmtpConfig();
      const transporter = nodemailer.createTransport({
        host: smtpConfig.host,
        port: smtpConfig.port,
        secure: smtpConfig.secure,
        auth: smtpConfig.auth,
      });

      await transporter.sendMail({
        from: smtpConfig.from,
        to: email,
        subject: '【Groumap】メール認証コードのお知らせ',
        text: buildOtpEmailText(code),
      });
    } catch (error) {
      await otpRef.delete();
      console.error('Failed to send OTP email:', error);
      throw new HttpsError('internal', '認証コードの送信に失敗しました');
    }

    return { success: true };
  }
);

export const verifyEmailOtp = onCall(
  { region: 'asia-northeast1' },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError('unauthenticated', 'ログインが必要です');
    }

    const uid = request.auth.uid;
    const code = String(request.data?.code ?? '').trim();
    if (!/^\d{6}$/.test(code)) {
      throw new HttpsError('invalid-argument', '6桁の認証コードを入力してください');
    }

    const otpRef = db.collection(EMAIL_OTP_COLLECTION).doc(uid);
    const otpSnapshot = await otpRef.get();
    if (!otpSnapshot.exists) {
      throw new HttpsError('not-found', '認証コードが見つかりません。再送信してください');
    }

    const data = otpSnapshot.data() as EmailOtpRecord;
    const expiresAt = data.expiresAt?.toDate();
    if (!expiresAt || expiresAt.getTime() < Date.now()) {
      await otpRef.delete();
      throw new HttpsError('failed-precondition', '認証コードの有効期限が切れています');
    }

    const attempts = data.attempts ?? 0;
    if (attempts >= 5) {
      throw new HttpsError('resource-exhausted', '認証コードの試行回数が上限に達しました');
    }

    const codeHash = hashOtp(code, uid);
    if (codeHash !== data.codeHash) {
      await otpRef.update({
        attempts: FieldValue.increment(1),
        updatedAt: FieldValue.serverTimestamp(),
      });
      throw new HttpsError('invalid-argument', '認証コードが正しくありません');
    }

    await Promise.all([
      otpRef.delete(),
      db.collection(USERS_COLLECTION).doc(uid).set(
        {
          emailVerified: true,
          emailVerifiedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      ),
    ]);

    return { verified: true };
  }
);

export const updateStoreDailyStats = onDocumentCreated(
  {
    document: 'stores/{storeId}/transactions/{transactionId}',
    region: 'asia-northeast1',
  },
  async (event) => {
    const data = event.data?.data() as Record<string, unknown> | undefined;
    if (!data) return;

    const storeId = event.params.storeId as string;
    const createdAtValue = data['createdAt'];
    const createdAt =
      typeof createdAtValue === 'object' &&
      createdAtValue !== null &&
      'toDate' in createdAtValue &&
      typeof (createdAtValue as { toDate: () => Date }).toDate === 'function'
        ? (createdAtValue as { toDate: () => Date }).toDate()
        : createdAtValue instanceof Date
          ? createdAtValue
          : new Date(event.time);

    const dateKey = getDateKey(createdAt);
    const type = typeof data['type'] === 'string' ? (data['type'] as string) : '';
    const amountYen = typeof data['amountYen'] === 'number' ? (data['amountYen'] as number) : 0;
    const points = typeof data['points'] === 'number' ? (data['points'] as number) : 0;
    const userId = typeof data['userId'] === 'string' ? (data['userId'] as string) : '';

    const updates: Record<string, unknown> = {
      date: dateKey,
      transactionCount: FieldValue.increment(1),
      lastUpdated: new Date(),
    };

    if (amountYen > 0) {
      updates['totalSales'] = FieldValue.increment(amountYen);
    }
    if (points > 0) {
      updates['pointsIssued'] = FieldValue.increment(points);
    } else if (points < 0) {
      updates['pointsUsed'] = FieldValue.increment(Math.abs(points));
    }
    if (type === 'award') {
      updates['visitorCount'] = FieldValue.increment(1);
    }

    await db
      .collection('store_stats')
      .doc(storeId)
      .collection('daily')
      .doc(dateKey)
      .set(updates, { merge: true });

    if (type === 'award' && userId) {
      const userRef = db
        .collection('store_users')
        .doc(storeId)
        .collection('users')
        .doc(userId);

      await db.runTransaction(async (transaction) => {
        const userSnap = await transaction.get(userRef);
        if (!userSnap.exists) {
          transaction.set(userRef, {
            userId,
            storeId,
            firstVisitAt: createdAt,
            lastVisitAt: createdAt,
            totalVisits: 1,
            createdAt: new Date(),
            updatedAt: new Date(),
          });
        } else {
          transaction.update(userRef, {
            lastVisitAt: createdAt,
            totalVisits: FieldValue.increment(1),
            updatedAt: new Date(),
          });
        }
      });
    }
  }
);

// シンプルなテスト関数（認証なし）
export const testFunction = onCall(
  {
    region: 'asia-northeast1',
    enforceAppCheck: false,
  },
  async (request) => {
    console.log('Test function called');
    return { message: 'Hello from test function!' };
  }
);

// HTTP関数としてのテスト関数
import { onRequest } from 'firebase-functions/v2/https';

export const testHttpFunction = onRequest(
  {
    region: 'asia-northeast1',
  },
  async (req, res) => {
    console.log('HTTP test function called');
    res.json({ message: 'Hello from HTTP test function!' });
  }
);

// QRトークン発行関数
export const issueQrToken = onCall(
  {
    region: 'asia-northeast1',
    enforceAppCheck: false, // 開発環境では無効化
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
    enforceAppCheck: false, // 開発環境では無効化
  },
  async (request) => {
    const requestId = Math.random().toString(36).substring(7);
    console.log(`[${requestId}] QR token verification started`);
    
    try {
      // 認証チェック
      if (!request.auth) {
        console.error(`[${requestId}] Authentication failed: No auth token`);
        throw new HttpsError('unauthenticated', 'Store must be authenticated');
      }

      console.log(`[${requestId}] Authenticated user: ${request.auth.uid}`);

      const { token, storeId } = request.data;
      
      if (!token || !storeId) {
        console.error(`[${requestId}] Missing parameters: token=${!!token}, storeId=${!!storeId}`);
        throw new HttpsError('invalid-argument', 'Missing required parameters: token and storeId');
      }

      console.log(`[${requestId}] Parameters: storeId=${storeId}, tokenLength=${token.length}`);

      // ストアロールチェック（開発環境では緩和）
      try {
        const user = await auth.getUser(request.auth.uid);
        const customClaims = user.customClaims || {};
        const userRole = customClaims.role;

        console.log(`[${requestId}] User role: ${userRole}`);

        // 開発環境ではロールチェックを緩和
        if (process.env.NODE_ENV === 'production' && (!userRole || !['store', 'company'].includes(userRole))) {
          console.error(`[${requestId}] Permission denied: role=${userRole}`);
          throw new HttpsError('permission-denied', 'Only stores can verify QR tokens');
        }
      } catch (authError) {
        console.error(`[${requestId}] Auth check failed:`, authError);
        // 開発環境では認証エラーを無視
        if (process.env.NODE_ENV === 'production') {
          throw new HttpsError('permission-denied', 'Authentication check failed');
        }
        console.warn(`[${requestId}] Auth check failed in development, continuing...`);
      }

      // JWTトークンを検証
      console.log(`[${requestId}] Verifying JWT token...`);
      let payload;
      try {
        payload = await verifyQRToken(token);
        console.log(`[${requestId}] JWT verification successful: sub=${payload.sub}, jti=${payload.jti}`);
      } catch (jwtError) {
        console.error(`[${requestId}] JWT verification failed:`, jwtError);
        const errorMessage = jwtError instanceof Error ? jwtError.message : String(jwtError);
        throw new HttpsError('invalid-argument', `Invalid token: ${errorMessage}`);
      }

      // リプレイ防止チェック
      const jti = payload.jti;
      const jtiRef = db.collection('qrJti').doc(jti);

      console.log(`[${requestId}] Checking JTI for replay prevention: ${jti}`);

      // トランザクションでJTIの使用をチェック
      try {
        await db.runTransaction(async (transaction) => {
          const jtiDoc = await transaction.get(jtiRef);
          
          if (jtiDoc.exists) {
            console.error(`[${requestId}] Token already used: ${jti}`);
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
        console.log(`[${requestId}] JTI recorded successfully`);
      } catch (transactionError) {
        console.error(`[${requestId}] Transaction failed:`, transactionError);
        if (transactionError instanceof HttpsError) {
          throw transactionError;
        }
        const errorMessage = transactionError instanceof Error ? transactionError.message : String(transactionError);
        throw new HttpsError('internal', `Transaction failed: ${errorMessage}`);
      }

      // チェックイン記録を作成
      try {
        await recordCheckIn(payload.sub, storeId, jti, payload.deviceId);
        console.log(`[${requestId}] Check-in recorded successfully`);
      } catch (checkInError) {
        console.error(`[${requestId}] Check-in recording failed:`, checkInError);
        // チェックイン記録の失敗は致命的ではないので、警告のみ
        console.warn(`[${requestId}] Check-in recording failed, but continuing...`);
      }

      const result = {
        uid: payload.sub,
        status: 'OK',
        jti: jti,
      };

      console.log(`[${requestId}] QR token verification completed successfully:`, result);
      return result;
    } catch (error) {
      console.error(`[${requestId}] QR token verification failed:`, error);
      
      // エラーの詳細をログに記録
      if (error instanceof Error) {
        console.error(`[${requestId}] Error stack:`, error.stack);
      }
      
      // HttpsErrorの場合はそのまま再スロー
      if (error instanceof HttpsError) {
        console.error(`[${requestId}] HttpsError: ${error.code} - ${error.message}`);
        throw error;
      }
      
      // その他のエラーはHttpsErrorに変換
      console.error(`[${requestId}] Converting error to HttpsError:`, error);
      const errorMessage = error instanceof Error ? error.message : String(error);
      throw new HttpsError('internal', `Failed to verify QR token: ${errorMessage}`);
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
          paymentAmount: null,
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

// チェックイン統計の更新（オプション）- 一時的に無効化
// export const updateCheckInStats = onDocumentCreated(
//   {
//     document: 'check_ins/{checkInId}',
//     region: 'asia-northeast1'
//   },
//   async (event) => {
//     try {
//       const checkInData = event.data?.data();
//       if (!checkInData) return;
      
//       const { userId, timestamp } = checkInData;
//       const date = new Date(timestamp.seconds * 1000);
//       const dateStr = date.toISOString().split('T')[0]; // YYYY-MM-DD
      
//       // 日別チェックイン統計を更新
//       const statsRef = db.collection('daily_stats').doc(dateStr);
//       await statsRef.set({
//         date: dateStr,
//         totalCheckIns: 1,
//         uniqueUsers: [userId],
//         lastUpdated: new Date()
//       }, { merge: true });
      
//       console.log(`Stats updated for date ${dateStr}`);
//     } catch (error) {
//       console.error('Error updating check-in stats:', error);
//     }
//   }
// );
