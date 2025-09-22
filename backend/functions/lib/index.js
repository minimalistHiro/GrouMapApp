"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.verifyQrToken = exports.issueQrToken = exports.testFunction = void 0;
const https_1 = require("firebase-functions/v2/https");
// import { onDocumentCreated } from 'firebase-functions/v2/firestore';
const app_1 = require("firebase-admin/app");
const firestore_1 = require("firebase-admin/firestore");
const auth_1 = require("firebase-admin/auth");
const jwt_1 = require("./utils/jwt");
// Firebase Admin SDK初期化
(0, app_1.initializeApp)();
const db = (0, firestore_1.getFirestore)();
const auth = (0, auth_1.getAuth)();
// タイムゾーン設定
process.env.TZ = 'Asia/Tokyo';
// デバッグ用のログ
console.log('Cloud Functions initialized with updated permissions');
// シンプルなテスト関数
exports.testFunction = (0, https_1.onCall)({
    region: 'asia-northeast1',
    enforceAppCheck: false,
}, async (request) => {
    console.log('Test function called');
    return { message: 'Hello from test function!' };
});
// QRトークン発行関数
exports.issueQrToken = (0, https_1.onCall)({
    region: 'asia-northeast1',
    enforceAppCheck: false, // 開発環境では無効化
}, async (request) => {
    try {
        // 認証チェック
        if (!request.auth) {
            throw new https_1.HttpsError('unauthenticated', 'User must be authenticated');
        }
        const uid = request.auth.uid;
        const { deviceId } = request.data || {};
        // ユーザーの存在確認
        try {
            await auth.getUser(uid);
        }
        catch (error) {
            throw new https_1.HttpsError('not-found', 'User not found');
        }
        // JWTトークンを発行
        const result = await (0, jwt_1.issueQRToken)(uid, deviceId);
        console.log(`QR token issued for user ${uid}, JTI: ${result.jti}`);
        return {
            token: result.token,
            expiresAt: result.expiresAt,
            jti: result.jti,
        };
    }
    catch (error) {
        console.error('Error issuing QR token:', error);
        if (error instanceof https_1.HttpsError) {
            throw error;
        }
        throw new https_1.HttpsError('internal', 'Failed to issue QR token');
    }
});
// QRトークン検証関数
exports.verifyQrToken = (0, https_1.onCall)({
    region: 'asia-northeast1',
    enforceAppCheck: false, // 開発環境では無効化
}, async (request) => {
    const requestId = Math.random().toString(36).substring(7);
    console.log(`[${requestId}] QR token verification started`);
    try {
        // 認証チェック
        if (!request.auth) {
            console.error(`[${requestId}] Authentication failed: No auth token`);
            throw new https_1.HttpsError('unauthenticated', 'Store must be authenticated');
        }
        console.log(`[${requestId}] Authenticated user: ${request.auth.uid}`);
        const { token, storeId } = request.data;
        if (!token || !storeId) {
            console.error(`[${requestId}] Missing parameters: token=${!!token}, storeId=${!!storeId}`);
            throw new https_1.HttpsError('invalid-argument', 'Missing required parameters: token and storeId');
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
                throw new https_1.HttpsError('permission-denied', 'Only stores can verify QR tokens');
            }
        }
        catch (authError) {
            console.error(`[${requestId}] Auth check failed:`, authError);
            // 開発環境では認証エラーを無視
            if (process.env.NODE_ENV === 'production') {
                throw new https_1.HttpsError('permission-denied', 'Authentication check failed');
            }
            console.warn(`[${requestId}] Auth check failed in development, continuing...`);
        }
        // JWTトークンを検証
        console.log(`[${requestId}] Verifying JWT token...`);
        let payload;
        try {
            payload = await (0, jwt_1.verifyQRToken)(token);
            console.log(`[${requestId}] JWT verification successful: sub=${payload.sub}, jti=${payload.jti}`);
        }
        catch (jwtError) {
            console.error(`[${requestId}] JWT verification failed:`, jwtError);
            const errorMessage = jwtError instanceof Error ? jwtError.message : String(jwtError);
            throw new https_1.HttpsError('invalid-argument', `Invalid token: ${errorMessage}`);
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
                    throw new https_1.HttpsError('failed-precondition', 'Token has already been used');
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
        }
        catch (transactionError) {
            console.error(`[${requestId}] Transaction failed:`, transactionError);
            if (transactionError instanceof https_1.HttpsError) {
                throw transactionError;
            }
            const errorMessage = transactionError instanceof Error ? transactionError.message : String(transactionError);
            throw new https_1.HttpsError('internal', `Transaction failed: ${errorMessage}`);
        }
        // チェックイン記録を作成
        try {
            await recordCheckIn(payload.sub, storeId, jti, payload.deviceId);
            console.log(`[${requestId}] Check-in recorded successfully`);
        }
        catch (checkInError) {
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
    }
    catch (error) {
        console.error(`[${requestId}] QR token verification failed:`, error);
        // エラーの詳細をログに記録
        if (error instanceof Error) {
            console.error(`[${requestId}] Error stack:`, error.stack);
        }
        // HttpsErrorの場合はそのまま再スロー
        if (error instanceof https_1.HttpsError) {
            console.error(`[${requestId}] HttpsError: ${error.code} - ${error.message}`);
            throw error;
        }
        // その他のエラーはHttpsErrorに変換
        console.error(`[${requestId}] Converting error to HttpsError:`, error);
        const errorMessage = error instanceof Error ? error.message : String(error);
        throw new https_1.HttpsError('internal', `Failed to verify QR token: ${errorMessage}`);
    }
});
// チェックイン記録
async function recordCheckIn(userId, storeId, jti, deviceId) {
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
    }
    catch (error) {
        console.error('Error recording check-in:', error);
        throw error;
    }
}
// ユーザーポイント更新
async function updateUserPoints(userId, points, storeId) {
    try {
        const userRef = db.collection('users').doc(userId);
        await db.runTransaction(async (transaction) => {
            var _a;
            const userDoc = await transaction.get(userRef);
            if (userDoc.exists) {
                const currentPoints = ((_a = userDoc.data()) === null || _a === void 0 ? void 0 : _a.points) || 0;
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
    }
    catch (error) {
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
//# sourceMappingURL=index.js.map