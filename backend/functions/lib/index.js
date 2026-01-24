"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.verifyQrToken = exports.issueQrToken = exports.testHttpFunction = exports.testFunction = exports.updateStoreDailyStats = exports.verifyEmailOtp = exports.requestEmailOtp = exports.sendUserNotificationOnCreate = exports.processFriendReferral = exports.sendNotificationOnPublish = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-functions/v2/firestore");
const app_1 = require("firebase-admin/app");
const firestore_2 = require("firebase-admin/firestore");
const auth_1 = require("firebase-admin/auth");
const messaging_1 = require("firebase-admin/messaging");
const params_1 = require("firebase-functions/params");
const nodemailer_1 = __importDefault(require("nodemailer"));
const crypto_1 = require("crypto");
const jwt_1 = require("./utils/jwt");
// Firebase Admin SDK初期化
(0, app_1.initializeApp)();
const db = (0, firestore_2.getFirestore)();
const auth = (0, auth_1.getAuth)();
const messaging = (0, messaging_1.getMessaging)();
// タイムゾーン設定
process.env.TZ = 'Asia/Tokyo';
// デバッグ用のログ
console.log('Cloud Functions initialized with updated permissions');
const NOTIFICATIONS_COLLECTION = 'notifications';
const NOTIFICATION_SETTINGS_COLLECTION = 'notification_settings';
const USERS_COLLECTION = 'users';
const EMAIL_OTP_COLLECTION = 'email_otp';
const ANNOUNCEMENT_TOPIC = 'announcements';
const OWNER_SETTINGS_COLLECTION = 'owner_settings';
const REFERRAL_USES_COLLECTION = 'referral_uses';
const POINT_LEDGER_COLLECTION = 'point_ledger';
const SMTP_HOST = (0, params_1.defineSecret)('SMTP_HOST');
const SMTP_PORT = (0, params_1.defineSecret)('SMTP_PORT');
const SMTP_USER = (0, params_1.defineSecret)('SMTP_USER');
const SMTP_PASS = (0, params_1.defineSecret)('SMTP_PASS');
const SMTP_FROM = (0, params_1.defineSecret)('SMTP_FROM');
const SMTP_SECURE = (0, params_1.defineSecret)('SMTP_SECURE');
function getDateKey(date) {
    return new Intl.DateTimeFormat('en-CA', {
        timeZone: 'Asia/Tokyo',
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
    }).format(date);
}
function normalizeReferralCode(code) {
    return (code !== null && code !== void 0 ? code : '').trim().toUpperCase();
}
async function resolveReferralPoints() {
    var _a;
    const settingsDoc = await db.collection(OWNER_SETTINGS_COLLECTION).doc('current').get();
    const settings = (_a = settingsDoc.data()) !== null && _a !== void 0 ? _a : {};
    const readPoints = (keys, fallback) => {
        for (const key of keys) {
            const value = settings[key];
            if (typeof value === 'number')
                return Math.floor(value);
            if (typeof value === 'string') {
                const parsed = Number.parseInt(value, 10);
                if (!Number.isNaN(parsed))
                    return parsed;
            }
        }
        return fallback;
    };
    return {
        inviterPoints: readPoints(['friendCampaignInviterPoints', 'friendCampaignUserPoints', 'friendCampaignPoints'], 100),
        inviteePoints: readPoints(['friendCampaignInviteePoints', 'friendCampaignFriendPoints', 'friendCampaignPoints'], 100),
    };
}
async function getUserFcmTokens(userId) {
    var _a;
    const tokens = new Set();
    const userDoc = await db.collection(USERS_COLLECTION).doc(userId).get();
    if (userDoc.exists) {
        const data = userDoc.data();
        if (data === null || data === void 0 ? void 0 : data.fcmToken) {
            tokens.add(data.fcmToken);
        }
        if (Array.isArray(data === null || data === void 0 ? void 0 : data.fcmTokens)) {
            (_a = data === null || data === void 0 ? void 0 : data.fcmTokens) === null || _a === void 0 ? void 0 : _a.forEach((token) => {
                if (token)
                    tokens.add(token);
            });
        }
    }
    const tokenDocs = await db
        .collection(USERS_COLLECTION)
        .doc(userId)
        .collection('fcmTokens')
        .get();
    tokenDocs.forEach((doc) => {
        var _a, _b;
        const token = (_b = (_a = doc.data()) === null || _a === void 0 ? void 0 : _a.token) !== null && _b !== void 0 ? _b : doc.id;
        if (token)
            tokens.add(token);
    });
    return Array.from(tokens);
}
async function isPushEnabled(userId) {
    const settingsDoc = await db.collection(NOTIFICATION_SETTINGS_COLLECTION).doc(userId).get();
    if (!settingsDoc.exists) {
        return true;
    }
    const data = settingsDoc.data();
    return (data === null || data === void 0 ? void 0 : data.pushEnabled) !== false;
}
function buildNotificationPayload(notificationId, data) {
    var _a, _b, _c;
    const title = (_a = data.title) !== null && _a !== void 0 ? _a : 'お知らせ';
    const body = (_c = (_b = data.body) !== null && _b !== void 0 ? _b : data.content) !== null && _c !== void 0 ? _c : '';
    const payloadData = {
        notificationId,
    };
    if (data.type)
        payloadData.type = data.type;
    if (data.actionUrl)
        payloadData.actionUrl = data.actionUrl;
    if (data.category)
        payloadData.category = data.category;
    return {
        title,
        body,
        data: payloadData,
    };
}
function createOtp() {
    const value = (0, crypto_1.randomInt)(0, 1000000);
    return value.toString().padStart(6, '0');
}
function hashOtp(code, uid) {
    return (0, crypto_1.createHash)('sha256').update(`${uid}:${code}`).digest('hex');
}
function buildOtpEmailText(code) {
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
    var _a, _b;
    const host = SMTP_HOST.value();
    const port = Number((_a = SMTP_PORT.value()) !== null && _a !== void 0 ? _a : '587');
    const user = SMTP_USER.value();
    const pass = SMTP_PASS.value();
    const from = SMTP_FROM.value();
    const secure = ((_b = SMTP_SECURE.value()) !== null && _b !== void 0 ? _b : 'false').toLowerCase() === 'true';
    if (!host || !user || !pass || !from) {
        throw new https_1.HttpsError('failed-precondition', 'メール送信の設定が未完了です');
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
exports.sendNotificationOnPublish = (0, firestore_1.onDocumentWritten)({
    document: `${NOTIFICATIONS_COLLECTION}/{notificationId}`,
    region: 'asia-northeast1',
}, async (event) => {
    var _a;
    if (!((_a = event.data) === null || _a === void 0 ? void 0 : _a.after.exists))
        return;
    const notificationId = event.data.after.id;
    const afterData = event.data.after.data();
    if (!afterData)
        return;
    const beforeData = event.data.before.exists
        ? event.data.before.data()
        : undefined;
    const wasPublished = (beforeData === null || beforeData === void 0 ? void 0 : beforeData.isPublished) === true;
    const isPublished = afterData.isPublished !== false;
    const isActive = afterData.isActive !== false;
    const alreadyDelivered = afterData.isDelivered === true;
    const userId = afterData.userId;
    if (alreadyDelivered) {
        return;
    }
    const isCreate = !event.data.before.exists;
    const shouldSendToTopic = !userId &&
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
        console.log(`Sent notification ${notificationId} to user ${userId}: ` +
            `${response.successCount} success, ${response.failureCount} failure`);
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
});
exports.processFriendReferral = (0, firestore_1.onDocumentWritten)({
    document: `${USERS_COLLECTION}/{userId}`,
    region: 'asia-northeast1',
}, async (event) => {
    var _a, _b, _c;
    if (!((_a = event.data) === null || _a === void 0 ? void 0 : _a.after.exists))
        return;
    const afterData = event.data.after.data();
    const beforeData = event.data.before.exists
        ? event.data.before.data()
        : undefined;
    const userId = event.params.userId;
    const friendCode = normalizeReferralCode(typeof afterData.friendCode === 'string' ? afterData.friendCode : undefined);
    if (!friendCode)
        return;
    if (afterData.referralUsed === true || afterData.referredBy)
        return;
    const beforeFriendCode = normalizeReferralCode(typeof (beforeData === null || beforeData === void 0 ? void 0 : beforeData.friendCode) === 'string' ? beforeData === null || beforeData === void 0 ? void 0 : beforeData.friendCode : undefined);
    if (beforeFriendCode === friendCode &&
        ((_b = beforeData === null || beforeData === void 0 ? void 0 : beforeData.referralUsed) !== null && _b !== void 0 ? _b : false) === ((_c = afterData.referralUsed) !== null && _c !== void 0 ? _c : false)) {
        return;
    }
    const referrerQuery = await db
        .collection(USERS_COLLECTION)
        .where('referralCode', '==', friendCode)
        .limit(1)
        .get();
    if (referrerQuery.empty) {
        await event.data.after.ref.update({
            friendCode: firestore_2.FieldValue.delete(),
            friendCodeStatus: 'invalid',
            friendCodeCheckedAt: firestore_2.FieldValue.serverTimestamp(),
        });
        return;
    }
    const referrerDoc = referrerQuery.docs[0];
    if (referrerDoc.id === userId) {
        await event.data.after.ref.update({
            friendCode: firestore_2.FieldValue.delete(),
            friendCodeStatus: 'self',
            friendCodeCheckedAt: firestore_2.FieldValue.serverTimestamp(),
        });
        return;
    }
    const { inviterPoints, inviteePoints } = await resolveReferralPoints();
    const now = new Date();
    await db.runTransaction(async (transaction) => {
        const userRef = db.collection(USERS_COLLECTION).doc(userId);
        const referrerRef = db.collection(USERS_COLLECTION).doc(referrerDoc.id);
        const userSnap = await transaction.get(userRef);
        if (!userSnap.exists)
            return;
        const referrerSnap = await transaction.get(referrerRef);
        if (!referrerSnap.exists)
            return;
        const userData = userSnap.data();
        if (userData.referralUsed === true || userData.referredBy)
            return;
        const currentFriendCode = normalizeReferralCode(typeof userData.friendCode === 'string' ? userData.friendCode : undefined);
        if (!currentFriendCode || currentFriendCode !== friendCode)
            return;
        const referrerData = referrerSnap.data();
        const referrerCode = normalizeReferralCode(typeof referrerData.referralCode === 'string' ? referrerData.referralCode : undefined);
        if (referrerCode !== friendCode)
            return;
        const referredName = typeof userData.displayName === 'string' ? userData.displayName.trim() : '';
        const referrerName = typeof referrerData.displayName === 'string' ? referrerData.displayName.trim() : '';
        const safeReferredName = referredName.length === 0 ? '友達' : referredName;
        const safeReferrerName = referrerName.length === 0 ? '友達' : referrerName;
        const referralUseRef = db.collection(REFERRAL_USES_COLLECTION).doc();
        transaction.set(referralUseRef, {
            referrerUserId: referrerRef.id,
            referredUserId: userId,
            usedCode: friendCode,
            awardedPoints: {
                inviter: inviterPoints,
                invitee: inviteePoints,
            },
            status: 'awarded',
            createdAt: firestore_2.FieldValue.serverTimestamp(),
        });
        transaction.update(userRef, {
            referredBy: referrerRef.id,
            referralUsed: true,
            referralUsedAt: firestore_2.FieldValue.serverTimestamp(),
            friendCode: firestore_2.FieldValue.delete(),
            friendCodeStatus: 'applied',
            friendCodeCheckedAt: firestore_2.FieldValue.serverTimestamp(),
            friendReferralPopupShown: false,
            friendReferralPopup: {
                points: inviteePoints,
                referrerName: safeReferrerName,
            },
            specialPoints: firestore_2.FieldValue.increment(inviteePoints),
            specialPointsTotal: firestore_2.FieldValue.increment(inviteePoints),
            updatedAt: firestore_2.FieldValue.serverTimestamp(),
        });
        transaction.update(referrerRef, {
            referralCount: firestore_2.FieldValue.increment(1),
            referralEarningsPoints: firestore_2.FieldValue.increment(inviterPoints),
            specialPoints: firestore_2.FieldValue.increment(inviterPoints),
            specialPointsTotal: firestore_2.FieldValue.increment(inviterPoints),
            friendReferralPopupReferrerShown: false,
            friendReferralPopupReferrer: {
                points: inviterPoints,
                referredName: safeReferredName,
            },
            updatedAt: firestore_2.FieldValue.serverTimestamp(),
        });
        const inviterLedgerRef = db.collection(POINT_LEDGER_COLLECTION).doc();
        transaction.set(inviterLedgerRef, {
            userId: referrerRef.id,
            amount: inviterPoints,
            category: 'special',
            reason: 'friend_referral',
            relatedUserId: userId,
            refId: referralUseRef.id,
            createdAt: firestore_2.FieldValue.serverTimestamp(),
        });
        const inviteeLedgerRef = db.collection(POINT_LEDGER_COLLECTION).doc();
        transaction.set(inviteeLedgerRef, {
            userId,
            amount: inviteePoints,
            category: 'special',
            reason: 'friend_referral',
            relatedUserId: referrerRef.id,
            refId: referralUseRef.id,
            createdAt: firestore_2.FieldValue.serverTimestamp(),
        });
        const referrerNotificationRef = referrerRef.collection('notifications').doc();
        transaction.set(referrerNotificationRef, {
            id: referrerNotificationRef.id,
            userId: referrerRef.id,
            title: '友達紹介ポイント獲得',
            body: `${safeReferredName}さんがあなたの友達コードで登録し${inviterPoints}ポイント付与されました`,
            type: 'social',
            createdAt: now.toISOString(),
            isRead: false,
            isDelivered: true,
            data: {
                source: 'user',
                reason: 'friend_referral',
                referralUseId: referralUseRef.id,
                points: inviterPoints,
                referredUserId: userId,
            },
            tags: ['referral'],
        });
        const referredNotificationRef = userRef.collection('notifications').doc();
        transaction.set(referredNotificationRef, {
            id: referredNotificationRef.id,
            userId,
            title: '友達紹介ポイント獲得',
            body: `${safeReferrerName}さんの友達コードで${inviteePoints}ポイント付与されました`,
            type: 'social',
            createdAt: now.toISOString(),
            isRead: false,
            isDelivered: true,
            data: {
                source: 'user',
                reason: 'friend_referral',
                referralUseId: referralUseRef.id,
                points: inviteePoints,
                referrerUserId: referrerRef.id,
            },
            tags: ['referral'],
        });
    });
});
exports.sendUserNotificationOnCreate = (0, firestore_1.onDocumentCreated)({
    document: `${USERS_COLLECTION}/{userId}/notifications/{notificationId}`,
    region: 'asia-northeast1',
}, async (event) => {
    var _a;
    if (!((_a = event.data) === null || _a === void 0 ? void 0 : _a.exists))
        return;
    const notificationId = event.data.id;
    const userId = event.params.userId;
    const data = event.data.data();
    if (!data)
        return;
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
    const payload = buildNotificationPayload(notificationId, data);
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
    console.log(`Sent user notification ${notificationId} to user ${userId}: ` +
        `${response.successCount} success, ${response.failureCount} failure`);
    await event.data.ref.update({
        isDelivered: true,
        deliveredAt: new Date(),
    });
});
exports.requestEmailOtp = (0, https_1.onCall)({
    region: 'asia-northeast1',
    secrets: [SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, SMTP_FROM, SMTP_SECURE],
}, async (request) => {
    var _a, _b;
    if (!((_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid)) {
        throw new https_1.HttpsError('unauthenticated', 'ログインが必要です');
    }
    const uid = request.auth.uid;
    const userRecord = await auth.getUser(uid);
    const email = userRecord.email;
    if (!email) {
        throw new https_1.HttpsError('failed-precondition', 'メールアドレスが設定されていません');
    }
    const otpRef = db.collection(EMAIL_OTP_COLLECTION).doc(uid);
    const otpSnapshot = await otpRef.get();
    if (otpSnapshot.exists) {
        const existing = otpSnapshot.data();
        const lastSentAt = (_b = existing.lastSentAt) === null || _b === void 0 ? void 0 : _b.toDate();
        if (lastSentAt && Date.now() - lastSentAt.getTime() < 60 * 1000) {
            throw new https_1.HttpsError('resource-exhausted', '認証コードは1分以内に再送信できません');
        }
    }
    const code = createOtp();
    const codeHash = hashOtp(code, uid);
    const expiresAt = firestore_2.Timestamp.fromDate(new Date(Date.now() + 10 * 60 * 1000));
    await otpRef.set({
        codeHash,
        expiresAt,
        attempts: 0,
        lastSentAt: firestore_2.Timestamp.fromDate(new Date()),
        updatedAt: firestore_2.FieldValue.serverTimestamp(),
    }, { merge: true });
    try {
        const smtpConfig = getSmtpConfig();
        const transporter = nodemailer_1.default.createTransport({
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
    }
    catch (error) {
        await otpRef.delete();
        console.error('Failed to send OTP email:', error);
        throw new https_1.HttpsError('internal', '認証コードの送信に失敗しました');
    }
    return { success: true };
});
exports.verifyEmailOtp = (0, https_1.onCall)({ region: 'asia-northeast1' }, async (request) => {
    var _a, _b, _c, _d, _e;
    if (!((_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid)) {
        throw new https_1.HttpsError('unauthenticated', 'ログインが必要です');
    }
    const uid = request.auth.uid;
    const code = String((_c = (_b = request.data) === null || _b === void 0 ? void 0 : _b.code) !== null && _c !== void 0 ? _c : '').trim();
    if (!/^\d{6}$/.test(code)) {
        throw new https_1.HttpsError('invalid-argument', '6桁の認証コードを入力してください');
    }
    const otpRef = db.collection(EMAIL_OTP_COLLECTION).doc(uid);
    const otpSnapshot = await otpRef.get();
    if (!otpSnapshot.exists) {
        throw new https_1.HttpsError('not-found', '認証コードが見つかりません。再送信してください');
    }
    const data = otpSnapshot.data();
    const expiresAt = (_d = data.expiresAt) === null || _d === void 0 ? void 0 : _d.toDate();
    if (!expiresAt || expiresAt.getTime() < Date.now()) {
        await otpRef.delete();
        throw new https_1.HttpsError('failed-precondition', '認証コードの有効期限が切れています');
    }
    const attempts = (_e = data.attempts) !== null && _e !== void 0 ? _e : 0;
    if (attempts >= 5) {
        throw new https_1.HttpsError('resource-exhausted', '認証コードの試行回数が上限に達しました');
    }
    const codeHash = hashOtp(code, uid);
    if (codeHash !== data.codeHash) {
        await otpRef.update({
            attempts: firestore_2.FieldValue.increment(1),
            updatedAt: firestore_2.FieldValue.serverTimestamp(),
        });
        throw new https_1.HttpsError('invalid-argument', '認証コードが正しくありません');
    }
    await Promise.all([
        otpRef.delete(),
        db.collection(USERS_COLLECTION).doc(uid).set({
            emailVerified: true,
            emailVerifiedAt: firestore_2.FieldValue.serverTimestamp(),
            updatedAt: firestore_2.FieldValue.serverTimestamp(),
        }, { merge: true }),
    ]);
    return { verified: true };
});
exports.updateStoreDailyStats = (0, firestore_1.onDocumentCreated)({
    document: 'stores/{storeId}/transactions/{transactionId}',
    region: 'asia-northeast1',
}, async (event) => {
    var _a;
    const data = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
    if (!data)
        return;
    const storeId = event.params.storeId;
    const createdAtValue = data['createdAt'];
    const createdAt = typeof createdAtValue === 'object' &&
        createdAtValue !== null &&
        'toDate' in createdAtValue &&
        typeof createdAtValue.toDate === 'function'
        ? createdAtValue.toDate()
        : createdAtValue instanceof Date
            ? createdAtValue
            : new Date(event.time);
    const dateKey = getDateKey(createdAt);
    const type = typeof data['type'] === 'string' ? data['type'] : '';
    const amountYen = typeof data['amountYen'] === 'number' ? data['amountYen'] : 0;
    const points = typeof data['points'] === 'number' ? data['points'] : 0;
    const userId = typeof data['userId'] === 'string' ? data['userId'] : '';
    const updates = {
        date: dateKey,
        transactionCount: firestore_2.FieldValue.increment(1),
        lastUpdated: new Date(),
    };
    if (amountYen > 0) {
        updates['totalSales'] = firestore_2.FieldValue.increment(amountYen);
    }
    if (points > 0) {
        updates['pointsIssued'] = firestore_2.FieldValue.increment(points);
    }
    else if (points < 0) {
        updates['pointsUsed'] = firestore_2.FieldValue.increment(Math.abs(points));
    }
    if (type === 'award') {
        updates['visitorCount'] = firestore_2.FieldValue.increment(1);
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
            }
            else {
                transaction.update(userRef, {
                    lastVisitAt: createdAt,
                    totalVisits: firestore_2.FieldValue.increment(1),
                    updatedAt: new Date(),
                });
            }
        });
    }
});
// シンプルなテスト関数（認証なし）
exports.testFunction = (0, https_1.onCall)({
    region: 'asia-northeast1',
    enforceAppCheck: false,
}, async (request) => {
    console.log('Test function called');
    return { message: 'Hello from test function!' };
});
// HTTP関数としてのテスト関数
const https_2 = require("firebase-functions/v2/https");
exports.testHttpFunction = (0, https_2.onRequest)({
    region: 'asia-northeast1',
}, async (req, res) => {
    console.log('HTTP test function called');
    res.json({ message: 'Hello from HTTP test function!' });
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