"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.notifyCouponExpiryScheduled = exports.migrateStampCard = exports.syncStampsWithVisits = exports.syncStoreOwnerFlags = exports.setStoreOwnerFlagOnCreate = exports.notifyFollowersOnNewCoupon = exports.notifyFollowersOnNewPost = exports.expireCoinsScheduled = exports.syncInstagramPostsScheduled = exports.unlinkInstagramAuth = exports.syncInstagramPosts = exports.updateInstagramSyncSettings = exports.exchangeInstagramAuthCode = exports.startInstagramAuth = exports.punchStamp = exports.verifyQrToken = exports.issueQrToken = exports.testHttpFunction = exports.testFunction = exports.updateStoreDailyStats = exports.verifyEmailOtp = exports.recordRecommendationVisitOnPointAward = exports.calculatePointRequestRates = exports.verifyEmailChangeOtp = exports.requestEmailChangeOtp = exports.requestEmailOtp = exports.notifyPendingStoreRequest = exports.resetLiveChatUnreadOnRead = exports.sendLiveChatNotificationOnCreate = exports.sendUserNotificationOnCreate = exports.processFriendReferral = exports.processAwardAchievement = exports.sendNotificationOnPublish = void 0;
const https_1 = require("firebase-functions/v2/https");
const scheduler_1 = require("firebase-functions/v2/scheduler");
const firestore_1 = require("firebase-functions/v2/firestore");
const app_1 = require("firebase-admin/app");
const firestore_2 = require("firebase-admin/firestore");
const auth_1 = require("firebase-admin/auth");
const messaging_1 = require("firebase-admin/messaging");
const params_1 = require("firebase-functions/params");
const nodemailer_1 = __importDefault(require("nodemailer"));
const https_2 = __importDefault(require("https"));
const crypto_1 = require("crypto");
const jwt_1 = require("./utils/jwt");
// Firebase Admin SDK初期化
(0, app_1.initializeApp)();
const db = (0, firestore_2.getFirestore)();
db.settings({ ignoreUndefinedProperties: true });
const auth = (0, auth_1.getAuth)();
const messaging = (0, messaging_1.getMessaging)();
// タイムゾーン設定
process.env.TZ = 'Asia/Tokyo';
// デバッグ用のログ
console.log('Cloud Functions initialized with updated permissions');
const NOTIFICATIONS_COLLECTION = 'notifications';
const NOTIFICATION_SETTINGS_COLLECTION = 'notification_settings';
const USERS_COLLECTION = 'users';
const SERVICE_CHAT_ROOMS_COLLECTION = 'service_chat_rooms';
const EMAIL_OTP_COLLECTION = 'email_otp';
const ANNOUNCEMENT_TOPIC = 'announcements';
const OWNER_SETTINGS_COLLECTION = 'owner_settings';
const REFERRAL_USES_COLLECTION = 'referral_uses';
const USER_ACHIEVEMENT_EVENTS_COLLECTION = 'user_achievement_events';
const RECOMMENDATION_IMPRESSIONS_COLLECTION = 'recommendation_impressions';
const RECOMMENDATION_VISITS_COLLECTION = 'recommendation_visits';
const MAX_STAMPS = 10;
const INSTAGRAM_API_BASE = 'https://graph.facebook.com/v19.0';
const DEFAULT_INSTAGRAM_SYNC_TIME = '09:00';
const MIN_INSTAGRAM_SYNC_MINUTES = 9 * 60;
const MAX_INSTAGRAM_SYNC_MINUTES = 21 * 60;
function stripUndefined(value) {
    const entries = Object.entries(value).filter(([, v]) => v !== undefined);
    return Object.fromEntries(entries);
}
function toStringValue(value) {
    if (typeof value === 'string')
        return value;
    if (value === null || value === undefined)
        return '';
    return String(value);
}
function parseInstagramUsername(value) {
    var _a;
    const raw = toStringValue(value).trim();
    if (!raw)
        return null;
    const cleaned = raw.replace(/^@/, '');
    if (cleaned.includes('instagram.com/')) {
        try {
            const url = new URL(cleaned.startsWith('http') ? cleaned : `https://${cleaned}`);
            const parts = url.pathname.split('/').filter(Boolean);
            return (_a = parts[0]) !== null && _a !== void 0 ? _a : null;
        }
        catch (_b) {
            return null;
        }
    }
    return cleaned;
}
function getInstagramAuth(storeData) {
    var _a, _b;
    const auth = storeData['instagramAuth'];
    const accessToken = toStringValue((_a = auth === null || auth === void 0 ? void 0 : auth['accessToken']) !== null && _a !== void 0 ? _a : storeData['instagramAccessToken']).trim();
    const instagramUserId = toStringValue((_b = auth === null || auth === void 0 ? void 0 : auth['instagramUserId']) !== null && _b !== void 0 ? _b : storeData['instagramUserId']).trim();
    const socialMedia = storeData['socialMedia'];
    const usernameFromSocial = parseInstagramUsername(socialMedia === null || socialMedia === void 0 ? void 0 : socialMedia['instagram']);
    const username = toStringValue(auth === null || auth === void 0 ? void 0 : auth['username']).trim() || usernameFromSocial || undefined;
    if (!accessToken || !instagramUserId) {
        return null;
    }
    return { accessToken, instagramUserId, username };
}
function normalizeMediaType(value) {
    if (value === 'CAROUSEL_ALBUM')
        return 'CAROUSEL';
    return value || 'IMAGE';
}
function parseInstagramTimestamp(value) {
    if (!value)
        return new Date();
    const parsed = new Date(value);
    if (Number.isNaN(parsed.getTime()))
        return new Date();
    return parsed;
}
function extractInstagramImageUrls(item) {
    var _a, _b;
    const childItems = (_b = (_a = item.children) === null || _a === void 0 ? void 0 : _a.data) !== null && _b !== void 0 ? _b : [];
    if (childItems.length > 0) {
        const childUrls = childItems
            .map((child) => {
            const childType = normalizeMediaType(toStringValue(child.media_type));
            if (childType === 'VIDEO') {
                return toStringValue(child.thumbnail_url).trim();
            }
            return toStringValue(child.media_url).trim();
        })
            .filter((url) => url.length > 0);
        if (childUrls.length > 0) {
            return childUrls;
        }
    }
    const mediaType = normalizeMediaType(toStringValue(item.media_type));
    if (mediaType === 'VIDEO') {
        const thumbnail = toStringValue(item.thumbnail_url).trim();
        return thumbnail ? [thumbnail] : [];
    }
    const mediaUrl = toStringValue(item.media_url).trim();
    return mediaUrl ? [mediaUrl] : [];
}
function httpsGetJson(url) {
    return new Promise((resolve, reject) => {
        const req = https_2.default.get(url, (res) => {
            let body = '';
            res.on('data', (chunk) => {
                body += chunk;
            });
            res.on('end', () => {
                var _a;
                const status = (_a = res.statusCode) !== null && _a !== void 0 ? _a : 0;
                if (status >= 400) {
                    reject(new Error(`Instagram API error ${status}: ${body}`));
                    return;
                }
                try {
                    resolve(JSON.parse(body));
                }
                catch (error) {
                    reject(error);
                }
            });
        });
        req.on('error', reject);
        req.end();
    });
}
function buildInstagramAuthUrl() {
    const appId = INSTAGRAM_APP_ID.value();
    const redirectUri = INSTAGRAM_REDIRECT_URI.value();
    const scope = [
        'instagram_basic',
        'pages_show_list',
        'pages_read_engagement',
        'business_management',
        'instagram_manage_insights',
    ].join(',');
    const url = new URL('https://www.facebook.com/v19.0/dialog/oauth');
    url.searchParams.set('client_id', appId);
    url.searchParams.set('redirect_uri', redirectUri);
    url.searchParams.set('response_type', 'code');
    url.searchParams.set('scope', scope);
    return url.toString();
}
async function exchangeInstagramCode(params) {
    const appId = INSTAGRAM_APP_ID.value();
    const appSecret = INSTAGRAM_APP_SECRET.value();
    const redirectUri = INSTAGRAM_REDIRECT_URI.value();
    const url = new URL(`${INSTAGRAM_API_BASE}/oauth/access_token`);
    url.searchParams.set('client_id', appId);
    url.searchParams.set('client_secret', appSecret);
    url.searchParams.set('redirect_uri', redirectUri);
    url.searchParams.set('code', params.code);
    const response = await httpsGetJson(url.toString());
    const accessToken = toStringValue(response.access_token).trim();
    if (!accessToken) {
        throw new Error('アクセストークンの取得に失敗しました');
    }
    return { accessToken };
}
async function exchangeLongLivedToken(params) {
    const appId = INSTAGRAM_APP_ID.value();
    const appSecret = INSTAGRAM_APP_SECRET.value();
    const url = new URL(`${INSTAGRAM_API_BASE}/oauth/access_token`);
    url.searchParams.set('grant_type', 'fb_exchange_token');
    url.searchParams.set('client_id', appId);
    url.searchParams.set('client_secret', appSecret);
    url.searchParams.set('fb_exchange_token', params.accessToken);
    const response = await httpsGetJson(url.toString());
    const longToken = toStringValue(response.access_token).trim();
    if (!longToken) {
        throw new Error('長期アクセストークンの取得に失敗しました');
    }
    return longToken;
}
async function resolveInstagramUserId(accessToken) {
    var _a, _b, _c;
    const pagesUrl = new URL(`${INSTAGRAM_API_BASE}/me/accounts`);
    pagesUrl.searchParams.set('access_token', accessToken);
    const pages = await httpsGetJson(pagesUrl.toString());
    const pageId = (_b = (_a = pages.data) === null || _a === void 0 ? void 0 : _a[0]) === null || _b === void 0 ? void 0 : _b.id;
    if (!pageId) {
        throw new Error('Facebookページが取得できません');
    }
    const igUrl = new URL(`${INSTAGRAM_API_BASE}/${pageId}`);
    igUrl.searchParams.set('fields', 'instagram_business_account');
    igUrl.searchParams.set('access_token', accessToken);
    const igResult = await httpsGetJson(igUrl.toString());
    const instagramUserId = toStringValue((_c = igResult.instagram_business_account) === null || _c === void 0 ? void 0 : _c.id).trim();
    if (!instagramUserId) {
        throw new Error('Instagramビジネスアカウントが取得できません');
    }
    const userUrl = new URL(`${INSTAGRAM_API_BASE}/${instagramUserId}`);
    userUrl.searchParams.set('fields', 'username');
    userUrl.searchParams.set('access_token', accessToken);
    const userInfo = await httpsGetJson(userUrl.toString());
    return { instagramUserId, username: userInfo.username };
}
async function fetchInstagramMedia(params) {
    var _a;
    const { instagramUserId, accessToken, limit = 50 } = params;
    const url = new URL(`${INSTAGRAM_API_BASE}/${instagramUserId}/media`);
    url.searchParams.set('fields', 'id,caption,media_type,media_url,thumbnail_url,permalink,timestamp,children{media_type,media_url,thumbnail_url}');
    url.searchParams.set('limit', String(limit));
    url.searchParams.set('access_token', accessToken);
    const response = await httpsGetJson(url.toString());
    return (_a = response.data) !== null && _a !== void 0 ? _a : [];
}
async function upsertInstagramPosts(params) {
    var _a;
    const { storeId, storeData, mediaItems } = params;
    if (!mediaItems.length)
        return 0;
    const storeName = toStringValue(storeData['name']) || '店舗名なし';
    const storeIconImageUrl = toStringValue((_a = storeData['storeIconImageUrl']) !== null && _a !== void 0 ? _a : storeData['iconImageUrl']);
    const category = toStringValue(storeData['category']) || undefined;
    const batch = db.batch();
    let count = 0;
    for (const item of mediaItems) {
        if (!item.id)
            continue;
        const mediaType = normalizeMediaType(toStringValue(item.media_type));
        const isVideo = mediaType === 'VIDEO';
        const timestamp = parseInstagramTimestamp(item.timestamp);
        const imageUrls = extractInstagramImageUrls(item);
        const baseData = stripUndefined({
            instagramPostId: item.id,
            storeId,
            storeName,
            storeIconImageUrl,
            category,
            mediaType,
            mediaUrl: toStringValue(item.media_url),
            thumbnailUrl: toStringValue(item.thumbnail_url),
            imageUrls,
            caption: toStringValue(item.caption),
            permalink: toStringValue(item.permalink),
            timestamp: firestore_2.Timestamp.fromDate(timestamp),
            isVideo,
            isActive: true,
            source: 'instagram',
            updatedAt: firestore_2.FieldValue.serverTimestamp(),
        });
        const storeDocRef = db.collection('stores').doc(storeId).collection('instagram_posts').doc(item.id);
        batch.set(storeDocRef, Object.assign(Object.assign({}, baseData), { createdAt: firestore_2.FieldValue.serverTimestamp() }), { merge: true });
        const publicDocRef = db.collection('public_instagram_posts').doc(item.id);
        batch.set(publicDocRef, Object.assign(Object.assign({}, baseData), { key: `${storeId}::${item.id}`, createdAt: firestore_2.FieldValue.serverTimestamp() }), { merge: true });
        count += 1;
    }
    await batch.commit();
    return count;
}
async function syncInstagramPostsForStore(params) {
    const { storeId, storeData } = params;
    const authInfo = getInstagramAuth(storeData);
    if (!authInfo) {
        console.log(`Instagram auth missing: storeId=${storeId}`);
        return 0;
    }
    const mediaItems = await fetchInstagramMedia({
        instagramUserId: authInfo.instagramUserId,
        accessToken: authInfo.accessToken,
    });
    const count = await upsertInstagramPosts({
        storeId,
        storeData,
        mediaItems,
    });
    const syncSettings = getInstagramSyncSettings(storeData);
    const nextSyncDate = syncSettings.enabled
        ? buildNextInstagramSyncDate(new Date(), syncSettings.syncTime)
        : null;
    const updatePayload = {
        instagramSync: {
            lastSyncAt: firestore_2.FieldValue.serverTimestamp(),
            lastSyncCount: count,
        },
        'instagramSyncSettings.enabled': syncSettings.enabled,
        'instagramSyncSettings.syncTime': syncSettings.syncTime,
        'instagramSyncSettings.nextSyncAt': nextSyncDate
            ? firestore_2.Timestamp.fromDate(nextSyncDate)
            : firestore_2.FieldValue.delete(),
        'instagramSyncSettings.intervalMinutes': firestore_2.FieldValue.delete(),
    };
    await db.collection('stores').doc(storeId).set(updatePayload, { merge: true });
    return count;
}
function asInt(value, fallback = 0) {
    if (typeof value === 'number')
        return Math.trunc(value);
    if (typeof value === 'string') {
        const parsed = Number.parseInt(value, 10);
        return Number.isNaN(parsed) ? fallback : parsed;
    }
    return fallback;
}
function parseInstagramSyncTime(value) {
    const match = /^([01]\d|2[0-3]):(00|30)$/.exec(value);
    if (!match)
        return null;
    const hour = Number.parseInt(match[1], 10);
    const minute = Number.parseInt(match[2], 10);
    return { hour, minute };
}
function toInstagramSyncMinutes(value) {
    return value.hour * 60 + value.minute;
}
function clampInstagramSyncMinutes(minutes) {
    return Math.min(MAX_INSTAGRAM_SYNC_MINUTES, Math.max(MIN_INSTAGRAM_SYNC_MINUTES, minutes));
}
function formatInstagramSyncTime(params) {
    const hour = params.hour.toString().padStart(2, '0');
    const minute = params.minute.toString().padStart(2, '0');
    return `${hour}:${minute}`;
}
function toInstagramSyncTimeFromDate(date) {
    const totalMinutes = date.getHours() * 60 + date.getMinutes();
    const rounded = Math.round(totalMinutes / 30) * 30;
    const normalized = clampInstagramSyncMinutes(((rounded % (24 * 60)) + (24 * 60)) % (24 * 60));
    const hour = Math.floor(normalized / 60);
    const minute = normalized % 60;
    return formatInstagramSyncTime({ hour, minute });
}
function normalizeInstagramSyncTime(value, fallbackDate) {
    const raw = toStringValue(value).trim();
    const parsedRaw = parseInstagramSyncTime(raw);
    if (parsedRaw) {
        const normalized = clampInstagramSyncMinutes(toInstagramSyncMinutes(parsedRaw));
        const hour = Math.floor(normalized / 60);
        const minute = normalized % 60;
        return formatInstagramSyncTime({ hour, minute });
    }
    if (fallbackDate) {
        return toInstagramSyncTimeFromDate(fallbackDate);
    }
    return DEFAULT_INSTAGRAM_SYNC_TIME;
}
function isInstagramSyncTimeAllowed(syncTime) {
    const parsed = parseInstagramSyncTime(syncTime);
    if (!parsed)
        return false;
    const minutes = toInstagramSyncMinutes(parsed);
    return minutes >= MIN_INSTAGRAM_SYNC_MINUTES && minutes <= MAX_INSTAGRAM_SYNC_MINUTES;
}
function toDateValue(value) {
    if (!value)
        return null;
    if (value instanceof firestore_2.Timestamp)
        return value.toDate();
    if (value instanceof Date)
        return value;
    if (typeof value === 'string') {
        const parsed = new Date(value);
        if (!Number.isNaN(parsed.getTime())) {
            return parsed;
        }
    }
    if (typeof value === 'object' && value !== null && 'toDate' in value) {
        const toDate = value.toDate;
        if (typeof toDate === 'function') {
            const parsed = toDate();
            if (parsed instanceof Date && !Number.isNaN(parsed.getTime())) {
                return parsed;
            }
        }
    }
    return null;
}
function getInstagramSyncSettings(storeData) {
    const settings = storeData['instagramSyncSettings'];
    const enabled = (settings === null || settings === void 0 ? void 0 : settings['enabled']) === false ? false : true;
    const nextSyncAt = toDateValue(settings === null || settings === void 0 ? void 0 : settings['nextSyncAt']);
    const syncInfo = storeData['instagramSync'];
    const lastSyncAt = toDateValue(syncInfo === null || syncInfo === void 0 ? void 0 : syncInfo['lastSyncAt']);
    const syncTime = normalizeInstagramSyncTime(settings === null || settings === void 0 ? void 0 : settings['syncTime'], nextSyncAt !== null && nextSyncAt !== void 0 ? nextSyncAt : lastSyncAt);
    return {
        enabled,
        syncTime,
        nextSyncAt,
    };
}
function shouldRunInstagramSync(storeData, now) {
    const settings = getInstagramSyncSettings(storeData);
    if (!settings.enabled) {
        return false;
    }
    if (settings.nextSyncAt) {
        return settings.nextSyncAt.getTime() <= now.getTime();
    }
    const syncInfo = storeData['instagramSync'];
    const lastSyncAt = toDateValue(syncInfo === null || syncInfo === void 0 ? void 0 : syncInfo['lastSyncAt']);
    const todaySyncAt = buildTodayInstagramSyncDate(now, settings.syncTime);
    if (now.getTime() < todaySyncAt.getTime()) {
        return false;
    }
    if (!lastSyncAt) {
        return true;
    }
    return lastSyncAt.getTime() < todaySyncAt.getTime();
}
function buildTodayInstagramSyncDate(base, syncTime) {
    var _a;
    const parsed = (_a = parseInstagramSyncTime(syncTime)) !== null && _a !== void 0 ? _a : parseInstagramSyncTime(DEFAULT_INSTAGRAM_SYNC_TIME);
    return new Date(base.getFullYear(), base.getMonth(), base.getDate(), parsed.hour, parsed.minute, 0, 0);
}
function buildNextInstagramSyncDate(base, syncTime) {
    const todaySyncAt = buildTodayInstagramSyncDate(base, syncTime);
    if (todaySyncAt.getTime() <= base.getTime()) {
        todaySyncAt.setDate(todaySyncAt.getDate() + 1);
    }
    return todaySyncAt;
}
function startFromPeriod(period) {
    const now = new Date();
    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    switch (period) {
        case 'day':
            return todayStart;
        case 'week': {
            const diff = (todayStart.getDay() + 6) % 7; // Monday=0
            return new Date(todayStart.getTime() - diff * 24 * 60 * 60 * 1000);
        }
        case 'month':
            return new Date(now.getFullYear(), now.getMonth(), 1);
        case 'year':
            return new Date(now.getFullYear(), 0, 1);
        default:
            return new Date(now.getFullYear(), now.getMonth(), 1);
    }
}
function weekdayToStr(date) {
    var _a;
    const idx = (date.getDay() + 6) % 7;
    const map = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return (_a = map[idx]) !== null && _a !== void 0 ? _a : 'monday';
}
const LEVEL_BASE_REQUIRED_EXPERIENCE = 20;
const LEVEL_REQUIRED_EXPERIENCE_INCREMENT = 10;
const LEVEL_MAX = 50;
function requiredExperienceForLevel(level) {
    const safeLevel = Math.max(1, Math.min(LEVEL_MAX, level));
    return LEVEL_BASE_REQUIRED_EXPERIENCE + (safeLevel - 1) * LEVEL_REQUIRED_EXPERIENCE_INCREMENT;
}
function totalExperienceToReachLevel(level) {
    const safeLevel = Math.max(1, Math.min(LEVEL_MAX, level));
    let total = 0;
    for (let i = 1; i < safeLevel; i += 1) {
        total += requiredExperienceForLevel(i);
    }
    return total;
}
function levelFromTotalExperience(totalExperience) {
    if (totalExperience <= 0)
        return 1;
    let remaining = totalExperience;
    let level = 1;
    while (level < LEVEL_MAX) {
        const required = requiredExperienceForLevel(level);
        if (remaining < required)
            break;
        remaining -= required;
        level += 1;
    }
    return Math.max(1, Math.min(LEVEL_MAX, level));
}
function experienceForStampPunch() {
    return 10;
}
function experienceForStampCardComplete() {
    return 100;
}
async function countTransactions(params) {
    const { userId, since, dayOfWeek, storeId } = params;
    let count = 0;
    const storeIds = storeId
        ? [storeId]
        : (await db.collection('stores').get()).docs.map((doc) => doc.id);
    for (const sid of storeIds) {
        const snap = await db.collection('stores').doc(sid).collection('transactions')
            .where('type', '==', 'stamp')
            .where('userId', '==', userId)
            .get();
        for (const doc of snap.docs) {
            const data = doc.data();
            const raw = data['createdAt'];
            let ts = new Date();
            if (raw instanceof firestore_2.Timestamp) {
                ts = raw.toDate();
            }
            else if (typeof raw === 'string') {
                const parsed = new Date(raw);
                if (!Number.isNaN(parsed.getTime()))
                    ts = parsed;
            }
            else if (typeof raw === 'number') {
                ts = new Date(raw);
            }
            const inPeriod = ts.getTime() >= since.getTime();
            const weekdayOk = dayOfWeek ? weekdayToStr(ts) === dayOfWeek : true;
            if (inPeriod && weekdayOk)
                count += 1;
        }
    }
    return count;
}
async function getUserBadgeCount(userId) {
    const snap = await db.collection('user_badges').doc(userId).collection('badges').get();
    return snap.size;
}
async function getUserLevel(userId) {
    var _a;
    const doc = await db.collection('users').doc(userId).get();
    if (!doc.exists)
        return 1;
    return asInt((_a = doc.data()) === null || _a === void 0 ? void 0 : _a['level'], 1);
}
async function checkAndAwardBadges(params) {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l, _m, _o;
    const { userId, storeId } = params;
    const firestore = db;
    const badgesSnap = await firestore.collection('badges').get();
    const badgeCount = await getUserBadgeCount(userId);
    const userLevel = await getUserLevel(userId);
    const newlyAwarded = [];
    for (const doc of badgesSnap.docs) {
        const data = doc.data();
        const isActive = (_a = data['isActive']) !== null && _a !== void 0 ? _a : true;
        if (!isActive)
            continue;
        const rawCond = (_c = (_b = data['condition']) !== null && _b !== void 0 ? _b : data['conditionData']) !== null && _c !== void 0 ? _c : data['jsonLogicCondition'];
        let condMap = null;
        if (typeof rawCond === 'string') {
            try {
                const parsed = JSON.parse(rawCond);
                if (parsed && typeof parsed === 'object')
                    condMap = parsed;
            }
            catch (_) { }
        }
        else if (rawCond && typeof rawCond === 'object') {
            condMap = rawCond;
        }
        if (!condMap)
            continue;
        let isSatisfied = false;
        const mode = ((_d = condMap['mode']) !== null && _d !== void 0 ? _d : 'typed').toString();
        if (mode === 'typed') {
            const rule = ((_e = condMap['rule']) !== null && _e !== void 0 ? _e : {});
            const type = ((_f = rule['type']) !== null && _f !== void 0 ? _f : '').toString();
            const params = ((_g = rule['params']) !== null && _g !== void 0 ? _g : {});
            switch (type) {
                case 'first_checkin': {
                    const c = await countTransactions({ userId, since: new Date(0) });
                    isSatisfied = c >= 1;
                    break;
                }
                case 'checkins_count': {
                    const threshold = asInt(params['threshold']);
                    const period = ((_h = params['period']) !== null && _h !== void 0 ? _h : 'month').toString();
                    const since = startFromPeriod(period);
                    const c = await countTransactions({ userId, since });
                    isSatisfied = c >= threshold;
                    break;
                }
                case 'user_level': {
                    const threshold = asInt(params['threshold']);
                    isSatisfied = userLevel >= threshold;
                    break;
                }
                case 'badge_count': {
                    const threshold = asInt(params['threshold']);
                    isSatisfied = badgeCount >= threshold;
                    break;
                }
                case 'day_of_week_count': {
                    const threshold = asInt(params['threshold']);
                    const period = ((_j = params['period']) !== null && _j !== void 0 ? _j : 'week').toString();
                    const dow = ((_k = params['day_of_week']) !== null && _k !== void 0 ? _k : 'monday').toString();
                    const since = startFromPeriod(period);
                    const c = await countTransactions({
                        userId,
                        since,
                        dayOfWeek: dow,
                    });
                    isSatisfied = c >= threshold;
                    break;
                }
                case 'usage_count': {
                    const threshold = asInt(params['threshold']);
                    const period = ((_l = params['period']) !== null && _l !== void 0 ? _l : 'month').toString();
                    const since = period === 'unlimited' ? new Date(0) : startFromPeriod(period);
                    const c = await countTransactions({ userId, since });
                    isSatisfied = c >= threshold;
                    break;
                }
                case 'visit_frequency': {
                    const threshold = asInt(params['threshold']);
                    const period = ((_m = params['period']) !== null && _m !== void 0 ? _m : 'day').toString();
                    const since = period === 'unlimited' ? new Date(0) : startFromPeriod(period);
                    const c = await countTransactions({
                        userId,
                        since,
                        storeId,
                    });
                    isSatisfied = c >= threshold;
                    break;
                }
                default:
                    isSatisfied = false;
            }
        }
        else {
            isSatisfied = false;
        }
        if (!isSatisfied)
            continue;
        const badgeId = doc.id;
        const userBadgeRef = firestore
            .collection('user_badges')
            .doc(userId)
            .collection('badges')
            .doc(badgeId);
        const userBadgeSnap = await userBadgeRef.get();
        const alreadyOwned = userBadgeSnap.exists;
        if (!alreadyOwned) {
            const badgeDoc = stripUndefined({
                userId,
                badgeId,
                unlockedAt: firestore_2.FieldValue.serverTimestamp(),
                isNew: true,
                name: data['name'],
                description: data['description'],
                category: data['category'],
                imageUrl: data['imageUrl'],
                iconUrl: data['iconUrl'],
                iconPath: data['iconPath'],
                rarity: data['rarity'],
                order: (_o = data['order']) !== null && _o !== void 0 ? _o : 0,
            });
            await userBadgeRef.set(badgeDoc);
        }
        const badgeAward = stripUndefined({
            id: badgeId,
            name: data['name'],
            description: data['description'],
            category: data['category'],
            imageUrl: data['imageUrl'],
            iconUrl: data['iconUrl'],
            iconPath: data['iconPath'],
            rarity: data['rarity'],
            order: asInt(data['order'], 0),
            alreadyOwned,
        });
        newlyAwarded.push(badgeAward);
    }
    newlyAwarded.sort((a, b) => asInt(a.order) - asInt(b.order));
    return newlyAwarded;
}
const SMTP_HOST = (0, params_1.defineSecret)('SMTP_HOST');
const SMTP_PORT = (0, params_1.defineSecret)('SMTP_PORT');
const SMTP_USER = (0, params_1.defineSecret)('SMTP_USER');
const SMTP_PASS = (0, params_1.defineSecret)('SMTP_PASS');
const SMTP_FROM = (0, params_1.defineSecret)('SMTP_FROM');
const SMTP_SECURE = (0, params_1.defineSecret)('SMTP_SECURE');
const INSTAGRAM_APP_ID = (0, params_1.defineSecret)('INSTAGRAM_APP_ID');
const INSTAGRAM_APP_SECRET = (0, params_1.defineSecret)('INSTAGRAM_APP_SECRET');
const INSTAGRAM_REDIRECT_URI = (0, params_1.defineSecret)('INSTAGRAM_REDIRECT_URI');
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
/**
 * 生年月日から年代グループを算出
 */
function calculateAgeGroup(birthDate) {
    const bd = birthDate instanceof firestore_2.Timestamp ? birthDate.toDate() : birthDate;
    if (isNaN(bd.getTime()))
        return null;
    const now = new Date();
    let age = now.getFullYear() - bd.getFullYear();
    const monthDiff = now.getMonth() - bd.getMonth();
    if (monthDiff < 0 || (monthDiff === 0 && now.getDate() < bd.getDate())) {
        age--;
    }
    if (age < 20)
        return '~19';
    if (age < 30)
        return '20s';
    if (age < 40)
        return '30s';
    if (age < 50)
        return '40s';
    if (age < 60)
        return '50s';
    return '60+';
}
function toDate(value) {
    if (!value)
        return null;
    if (value instanceof Date)
        return value;
    if (value instanceof firestore_2.Timestamp)
        return value.toDate();
    if (typeof value === 'number')
        return new Date(value);
    if (typeof value === 'string') {
        const parsed = new Date(value);
        return Number.isNaN(parsed.getTime()) ? null : parsed;
    }
    return null;
}
function parseRate(value, fallback = 0) {
    if (typeof value === 'number')
        return value;
    if (typeof value === 'string') {
        const parsed = Number.parseFloat(value);
        return Number.isNaN(parsed) ? fallback : parsed;
    }
    return fallback;
}
function resolveLevelReturnRate(level, ranges) {
    if (!Array.isArray(ranges))
        return 1.0;
    for (const range of ranges) {
        const min = asInt(range.minLevel, 1);
        const max = asInt(range.maxLevel, LEVEL_MAX);
        const rate = parseRate(range.rate, 1.0);
        if (level >= min && level <= max) {
            return rate;
        }
    }
    return 1.0;
}
function resolveCampaignBonus(settings) {
    const bonusRate = parseRate(settings['campaignReturnRateBonus'], 0);
    const start = toDate(settings['campaignReturnRateStartDate']);
    const end = toDate(settings['campaignReturnRateEndDate']);
    if (!bonusRate || !start || !end)
        return { bonusRate: 0 };
    const now = new Date();
    if (now < start || now > end)
        return { bonusRate: 0 };
    const campaignId = typeof settings['campaignReturnRateId'] === 'string'
        ? settings['campaignReturnRateId']
        : undefined;
    return { bonusRate, campaignId };
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
function resolveTimestamp(value) {
    if (value instanceof firestore_2.Timestamp)
        return value;
    if (value instanceof Date)
        return firestore_2.Timestamp.fromDate(value);
    if (typeof value === 'string') {
        const parsed = new Date(value);
        if (!Number.isNaN(parsed.getTime())) {
            return firestore_2.Timestamp.fromDate(parsed);
        }
    }
    return null;
}
async function resolveUserName(userId) {
    var _a;
    const userDoc = await db.collection(USERS_COLLECTION).doc(userId).get();
    const data = userDoc.data();
    return (_a = data === null || data === void 0 ? void 0 : data.displayName) !== null && _a !== void 0 ? _a : 'ユーザー';
}
async function createUserNotification({ userId, title, body, data, type = 'system', tags = ['live_chat'], }) {
    const notificationRef = db
        .collection(USERS_COLLECTION)
        .doc(userId)
        .collection('notifications')
        .doc();
    await notificationRef.set({
        id: notificationRef.id,
        userId,
        title,
        body,
        type,
        createdAt: new Date().toISOString(),
        isRead: false,
        isDelivered: false,
        data: Object.assign({ source: 'user' }, stripUndefined(data !== null && data !== void 0 ? data : {})),
        tags,
    });
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
        'ぐるまっぷをご利用いただきありがとうございます。',
        '以下の6桁の認証コードをアプリに入力してください。',
        '',
        `認証コード: ${code}`,
        '有効期限: 10分',
        '',
        'このメールに心当たりがない場合は、破棄してください。',
        '',
        'ぐるまっぷ サポート',
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
exports.processAwardAchievement = (0, firestore_1.onDocumentCreated)({
    document: 'stores/{storeId}/transactions/{transactionId}',
    region: 'asia-northeast1',
}, async (event) => {
    var _a, _b, _c, _d, _e, _f;
    const data = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
    if (!data)
        return;
    const type = ((_b = data['type']) !== null && _b !== void 0 ? _b : '').toString();
    if (type !== 'award')
        return;
    const userId = ((_c = data['userId']) !== null && _c !== void 0 ? _c : '').toString();
    if (!userId)
        return;
    const storeId = event.params.storeId;
    const transactionId = event.params.transactionId;
    const storeName = ((_d = data['storeName']) !== null && _d !== void 0 ? _d : '').toString();
    const pointsAwarded = asInt((_e = data['points']) !== null && _e !== void 0 ? _e : data['amount'], 0);
    if (pointsAwarded <= 0)
        return;
    const eventRef = db
        .collection(USER_ACHIEVEMENT_EVENTS_COLLECTION)
        .doc(userId)
        .collection('events')
        .doc(transactionId);
    const existingEvent = await eventRef.get();
    if (existingEvent.exists)
        return;
    const transactionRef = (_f = event.data) === null || _f === void 0 ? void 0 : _f.ref;
    if (!transactionRef)
        return;
    const summary = await db.runTransaction(async (txn) => {
        var _a, _b;
        const txnSnap = await txn.get(transactionRef);
        const txnData = txnSnap.data();
        if (!txnData)
            return null;
        if (txnData['achievementProcessedAt']) {
            const existingSummary = txnData['achievementSummary'];
            if (!existingSummary) {
                return {
                    storeId,
                    storeName,
                    pointsAwarded,
                    stampsAdded: 0,
                    stampsAfter: 0,
                    cardCompleted: false,
                    xpAdded: 0,
                    xpBreakdown: {
                        points: 0,
                        stampPunch: 0,
                        cardComplete: 0,
                    },
                };
            }
            return existingSummary;
        }
        const userRef = db.collection(USERS_COLLECTION).doc(userId);
        const userStoreRef = userRef.collection('stores').doc(storeId);
        const userStoreSnap = await txn.get(userStoreRef);
        const userSnap = await txn.get(userRef);
        const currentStamps = asInt((_a = userStoreSnap.data()) === null || _a === void 0 ? void 0 : _a['stamps'], 0);
        const stampsAdded = 1; // 上限なし・累積加算（punchStampと同じロジック）
        const nextStamps = currentStamps + 1;
        const cardCompleted = nextStamps % MAX_STAMPS === 0; // 10の倍数到達で達成
        txn.set(userStoreRef, {
            stamps: nextStamps,
            lastVisited: firestore_2.FieldValue.serverTimestamp(),
        }, { merge: true });
        const pointsXp = pointsAwarded;
        const stampXp = stampsAdded > 0 ? experienceForStampPunch() : 0;
        const cardXp = cardCompleted ? experienceForStampCardComplete() : 0;
        const xpAdded = pointsXp + stampXp + cardXp;
        if (xpAdded > 0) {
            const currentExp = asInt((_b = userSnap.data()) === null || _b === void 0 ? void 0 : _b['experience'], 0);
            const maxTotal = totalExperienceToReachLevel(LEVEL_MAX) + requiredExperienceForLevel(LEVEL_MAX);
            const newExp = Math.max(0, Math.min(maxTotal, currentExp + xpAdded));
            const newLevel = levelFromTotalExperience(newExp);
            txn.set(userRef, {
                experience: newExp,
                level: newLevel,
                updatedAt: firestore_2.FieldValue.serverTimestamp(),
            }, { merge: true });
        }
        const summaryData = {
            storeId,
            storeName,
            pointsAwarded,
            stampsAdded,
            stampsAfter: nextStamps,
            cardCompleted,
            xpAdded,
            xpBreakdown: {
                points: pointsXp,
                stampPunch: stampXp,
                cardComplete: cardXp,
            },
        };
        txn.update(transactionRef, {
            achievementProcessedAt: firestore_2.FieldValue.serverTimestamp(),
            achievementSummary: summaryData,
        });
        return summaryData;
    });
    if (!summary)
        return;
    const badges = await checkAndAwardBadges({ userId, storeId });
    await eventRef.set(Object.assign(Object.assign({ type: 'point_award', transactionId }, summary), { badges, createdAt: firestore_2.FieldValue.serverTimestamp(), seenAt: null }), { merge: true });
});
exports.processFriendReferral = (0, firestore_1.onDocumentWritten)({
    document: `${USERS_COLLECTION}/{userId}`,
    region: 'asia-northeast1',
}, async (event) => {
    var _a, _b, _c, _d;
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
    // コインシステムに移行: コインは初回スタンプ獲得時に付与（punchStamp で処理）
    // owner_settings/current からコイン数を動的に取得
    const ownerSettingsSnap = await db.collection('owner_settings').doc('current').get();
    const ownerSettingsData = (_d = ownerSettingsSnap.data()) !== null && _d !== void 0 ? _d : {};
    const referralInviterCoins = typeof ownerSettingsData.friendCampaignInviterPoints === 'number'
        ? ownerSettingsData.friendCampaignInviterPoints : 5;
    const referralInviteeCoins = typeof ownerSettingsData.friendCampaignInviteePoints === 'number'
        ? ownerSettingsData.friendCampaignInviteePoints : 5;
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
        // referral_uses に pending レコードを作成（初回スタンプ後に awarded に更新）
        const referralUseRef = db.collection(REFERRAL_USES_COLLECTION).doc();
        transaction.set(referralUseRef, {
            referrerUserId: referrerRef.id,
            referredUserId: userId,
            usedCode: friendCode,
            plannedCoins: {
                inviter: referralInviterCoins,
                invitee: referralInviteeCoins,
            },
            status: 'pending',
            createdAt: firestore_2.FieldValue.serverTimestamp(),
        });
        // refereeのユーザードキュメント更新（コインは初回スタンプ獲得時に付与）
        transaction.update(userRef, {
            referredBy: referrerRef.id,
            referralUsed: true,
            referralUsedAt: firestore_2.FieldValue.serverTimestamp(),
            referralCoinAwarded: false,
            friendCode: firestore_2.FieldValue.delete(),
            friendCodeStatus: 'applied',
            friendCodeCheckedAt: firestore_2.FieldValue.serverTimestamp(),
            updatedAt: firestore_2.FieldValue.serverTimestamp(),
        });
        // referrerのユーザードキュメント更新（紹介数カウントのみ。コインは初回スタンプ時に付与）
        transaction.update(referrerRef, {
            referralCount: firestore_2.FieldValue.increment(1),
            updatedAt: firestore_2.FieldValue.serverTimestamp(),
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
exports.sendLiveChatNotificationOnCreate = (0, firestore_1.onDocumentCreated)({
    document: `${SERVICE_CHAT_ROOMS_COLLECTION}/{roomId}/messages/{messageId}`,
    region: 'asia-northeast1',
}, async (event) => {
    var _a, _b, _c, _d, _e, _f, _g;
    if (!((_a = event.data) === null || _a === void 0 ? void 0 : _a.exists))
        return;
    const roomId = event.params.roomId;
    const messageId = event.params.messageId;
    const message = event.data.data();
    if (!message)
        return;
    const roomRef = db.collection(SERVICE_CHAT_ROOMS_COLLECTION).doc(roomId);
    const roomSnap = await roomRef.get();
    const roomData = roomSnap.data();
    const userId = ((_c = (_b = message.userId) !== null && _b !== void 0 ? _b : roomData === null || roomData === void 0 ? void 0 : roomData.userId) !== null && _c !== void 0 ? _c : '').toString();
    if (!userId)
        return;
    const senderRole = ((_d = message.senderRole) !== null && _d !== void 0 ? _d : '').toString();
    const senderId = ((_e = message.senderId) !== null && _e !== void 0 ? _e : '').toString();
    const messageText = ((_f = message.text) !== null && _f !== void 0 ? _f : '').toString();
    const createdAt = (_g = resolveTimestamp(message.createdAt)) !== null && _g !== void 0 ? _g : firestore_2.Timestamp.now();
    await db.runTransaction(async (transaction) => {
        const snap = await transaction.get(roomRef);
        const data = snap.data();
        const ownerUnread = asInt(data === null || data === void 0 ? void 0 : data.ownerUnreadCount, 0);
        const userUnread = asInt(data === null || data === void 0 ? void 0 : data.userUnreadCount, 0);
        transaction.set(roomRef, stripUndefined({
            roomId,
            userId,
            lastMessage: messageText,
            lastMessageAt: createdAt,
            lastSenderRole: senderRole,
            ownerUnreadCount: senderRole === 'user' ? ownerUnread + 1 : ownerUnread,
            userUnreadCount: senderRole === 'owner' ? userUnread + 1 : userUnread,
            updatedAt: firestore_2.FieldValue.serverTimestamp(),
        }), { merge: true });
    });
    if (senderRole == 'user') {
        const userName = await resolveUserName(userId);
        const ownersSnap = await db
            .collection(USERS_COLLECTION)
            .where('isOwner', '==', true)
            .get();
        for (const doc of ownersSnap.docs) {
            await createUserNotification({
                userId: doc.id,
                title: 'ライブチャット',
                body: `${userName}さんからライブチャットでメッセージが届いています`,
                data: {
                    type: 'service_live_chat',
                    roomId,
                    userId,
                    messageId,
                    senderRole,
                    senderId,
                },
            });
        }
        return;
    }
    if (senderRole == 'owner') {
        await createUserNotification({
            userId,
            title: 'ライブチャット',
            body: 'サポートからメッセージが届いています',
            data: {
                type: 'service_live_chat',
                roomId,
                userId,
                messageId,
                senderRole,
                senderId,
            },
        });
    }
});
exports.resetLiveChatUnreadOnRead = (0, firestore_1.onDocumentUpdated)({
    document: `${SERVICE_CHAT_ROOMS_COLLECTION}/{roomId}`,
    region: 'asia-northeast1',
}, async (event) => {
    var _a, _b, _c, _d, _e;
    if (!((_a = event.data) === null || _a === void 0 ? void 0 : _a.after.exists))
        return;
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (!after)
        return;
    const userReadChanged = ((_b = before === null || before === void 0 ? void 0 : before.userLastReadAt) !== null && _b !== void 0 ? _b : null) != ((_c = after.userLastReadAt) !== null && _c !== void 0 ? _c : null);
    const ownerReadChanged = ((_d = before === null || before === void 0 ? void 0 : before.ownerLastReadAt) !== null && _d !== void 0 ? _d : null) != ((_e = after.ownerLastReadAt) !== null && _e !== void 0 ? _e : null);
    if (!userReadChanged && !ownerReadChanged)
        return;
    const updates = {};
    if (userReadChanged && asInt(after.userUnreadCount, 0) > 0) {
        updates.userUnreadCount = 0;
    }
    if (ownerReadChanged && asInt(after.ownerUnreadCount, 0) > 0) {
        updates.ownerUnreadCount = 0;
    }
    if (Object.keys(updates).length == 0)
        return;
    updates.updatedAt = firestore_2.FieldValue.serverTimestamp();
    await event.data.after.ref.update(updates);
});
exports.notifyPendingStoreRequest = (0, firestore_1.onDocumentCreated)({
    document: 'stores/{storeId}',
    region: 'asia-northeast1',
}, async (event) => {
    var _a, _b, _c, _d;
    if (!((_a = event.data) === null || _a === void 0 ? void 0 : _a.exists))
        return;
    const storeId = event.params.storeId;
    const data = event.data.data();
    if (!data)
        return;
    const isApproved = data['isApproved'] === true;
    const approvalStatus = ((_b = data['approvalStatus']) !== null && _b !== void 0 ? _b : 'pending').toString();
    const alreadyNotified = Boolean(data['pendingRequestNotifiedAt']);
    if (isApproved || approvalStatus != 'pending' || alreadyNotified) {
        return;
    }
    const storeName = ((_c = data['name']) !== null && _c !== void 0 ? _c : '店舗名未設定').toString();
    const createdBy = ((_d = data['createdBy']) !== null && _d !== void 0 ? _d : '').toString();
    const ownersSnapshot = await db
        .collection(USERS_COLLECTION)
        .where('isOwner', '==', true)
        .where('isStoreOwner', '==', true)
        .get();
    if (ownersSnapshot.empty) {
        await event.data.ref.update({
            pendingRequestNotifiedAt: firestore_2.FieldValue.serverTimestamp(),
        });
        return;
    }
    const notificationId = `store_request_${storeId}`;
    const now = firestore_2.FieldValue.serverTimestamp();
    const ownerDocs = ownersSnapshot.docs;
    const batchSize = 400;
    for (let i = 0; i < ownerDocs.length; i += batchSize) {
        const batch = db.batch();
        const slice = ownerDocs.slice(i, i + batchSize);
        slice.forEach((ownerDoc) => {
            const notificationRef = ownerDoc.ref.collection('notifications').doc(notificationId);
            batch.set(notificationRef, {
                id: notificationId,
                userId: ownerDoc.id,
                title: '未承認店舗の新規申請',
                body: '新しい店舗申請が届きました',
                type: 'store_announcement',
                createdAt: now,
                isRead: false,
                isDelivered: false,
                data: {
                    source: 'store_request',
                    storeId,
                    storeName,
                    createdBy,
                },
                tags: ['store_request', 'pending_store'],
            });
        });
        await batch.commit();
    }
    await event.data.ref.update({
        pendingRequestNotifiedAt: firestore_2.FieldValue.serverTimestamp(),
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
            subject: '【ぐるまっぷ】メール認証コードのお知らせ',
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
exports.requestEmailChangeOtp = (0, https_1.onCall)({
    region: 'asia-northeast1',
    secrets: [SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, SMTP_FROM, SMTP_SECURE],
}, async (request) => {
    var _a, _b, _c, _d;
    if (!((_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid)) {
        throw new https_1.HttpsError('unauthenticated', 'ログインが必要です');
    }
    const uid = request.auth.uid;
    const newEmail = String((_c = (_b = request.data) === null || _b === void 0 ? void 0 : _b.newEmail) !== null && _c !== void 0 ? _c : '').trim().toLowerCase();
    if (!newEmail || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(newEmail)) {
        throw new https_1.HttpsError('invalid-argument', '有効なメールアドレスを入力してください');
    }
    const userRecord = await auth.getUser(uid);
    const currentEmail = userRecord.email;
    if (currentEmail && currentEmail.toLowerCase() === newEmail) {
        throw new https_1.HttpsError('invalid-argument', '現在のメールアドレスと同じです');
    }
    try {
        await auth.getUserByEmail(newEmail);
        throw new https_1.HttpsError('already-exists', 'このメールアドレスは既に使用されています');
    }
    catch (e) {
        if (e instanceof https_1.HttpsError)
            throw e;
        const firebaseError = e;
        if (firebaseError.code !== 'auth/user-not-found') {
            throw new https_1.HttpsError('internal', 'メールアドレスの確認に失敗しました');
        }
    }
    const otpRef = db.collection(EMAIL_OTP_COLLECTION).doc(uid);
    const otpSnapshot = await otpRef.get();
    if (otpSnapshot.exists) {
        const existing = otpSnapshot.data();
        const lastSentAt = (_d = existing.lastSentAt) === null || _d === void 0 ? void 0 : _d.toDate();
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
        targetEmail: newEmail,
        purpose: 'emailChange',
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
            to: newEmail,
            subject: '【ぐるまっぷ】メールアドレス変更 認証コードのお知らせ',
            text: buildOtpEmailText(code),
        });
    }
    catch (error) {
        await otpRef.delete();
        console.error('Failed to send email change OTP:', error);
        throw new https_1.HttpsError('internal', '認証コードの送信に失敗しました');
    }
    return { success: true };
});
exports.verifyEmailChangeOtp = (0, https_1.onCall)({ region: 'asia-northeast1' }, async (request) => {
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
    if (data.purpose !== 'emailChange' || !data.targetEmail) {
        throw new https_1.HttpsError('failed-precondition', 'メールアドレス変更用の認証コードではありません');
    }
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
    const targetEmail = data.targetEmail;
    try {
        await auth.getUserByEmail(targetEmail);
        await otpRef.delete();
        throw new https_1.HttpsError('already-exists', 'このメールアドレスは既に使用されています');
    }
    catch (e) {
        if (e instanceof https_1.HttpsError)
            throw e;
        const firebaseError = e;
        if (firebaseError.code !== 'auth/user-not-found') {
            throw new https_1.HttpsError('internal', 'メールアドレスの確認に失敗しました');
        }
    }
    await auth.updateUser(uid, { email: targetEmail });
    await Promise.all([
        otpRef.delete(),
        db.collection(USERS_COLLECTION).doc(uid).set({
            email: targetEmail,
            updatedAt: firestore_2.FieldValue.serverTimestamp(),
        }, { merge: true }),
    ]);
    return { verified: true, email: targetEmail };
});
exports.calculatePointRequestRates = (0, firestore_1.onDocumentWritten)({
    document: 'point_requests/{storeId}/{userId}/award_request',
    region: 'asia-northeast1',
}, async (event) => {
    var _a, _b, _c, _d;
    if (!((_a = event.data) === null || _a === void 0 ? void 0 : _a.after.exists))
        return;
    const data = event.data.after.data();
    if (!data)
        return;
    if (data['rateCalculatedAt'])
        return;
    if (((_b = data['requestType']) !== null && _b !== void 0 ? _b : 'award') !== 'award')
        return;
    const amount = asInt(data['amount'], 0);
    if (amount <= 0)
        return;
    const userId = event.params.userId;
    const settingsDoc = await db.collection(OWNER_SETTINGS_COLLECTION).doc('current').get();
    const settings = (_c = settingsDoc.data()) !== null && _c !== void 0 ? _c : {};
    const userDoc = await db.collection(USERS_COLLECTION).doc(userId).get();
    const userLevel = asInt((_d = userDoc.data()) === null || _d === void 0 ? void 0 : _d['level'], 1);
    const levelRate = resolveLevelReturnRate(userLevel, settings['levelPointReturnRateRanges']);
    const { bonusRate, campaignId } = resolveCampaignBonus(settings);
    const appliedRate = levelRate + bonusRate;
    const baseRate = 1.0;
    const normalPoints = Math.floor(amount * Math.min(appliedRate, baseRate) / 100);
    const specialPoints = Math.floor(amount * Math.max(appliedRate - baseRate, 0) / 100);
    const totalPoints = normalPoints + specialPoints;
    let rateSource = 'base';
    if (bonusRate > 0 && levelRate !== baseRate)
        rateSource = 'level+campaign';
    else if (bonusRate > 0)
        rateSource = 'campaign';
    else if (levelRate !== baseRate)
        rateSource = 'level';
    await event.data.after.ref.update(stripUndefined({
        baseRate,
        appliedRate,
        normalPoints,
        specialPoints,
        totalPoints,
        pointsToAward: totalPoints,
        userPoints: totalPoints,
        rateCalculatedAt: firestore_2.FieldValue.serverTimestamp(),
        rateSource,
        campaignId,
    }));
});
exports.recordRecommendationVisitOnPointAward = (0, firestore_1.onDocumentWritten)({
    document: 'point_requests/{storeId}/{userId}/award_request',
    region: 'asia-northeast1',
}, async (event) => {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l;
    try {
        console.log('recordRecommendationVisitOnPointAward:start', {
            storeId: event.params.storeId,
            userId: event.params.userId,
            hasBefore: !!((_b = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before) === null || _b === void 0 ? void 0 : _b.exists),
            hasAfter: !!((_d = (_c = event.data) === null || _c === void 0 ? void 0 : _c.after) === null || _d === void 0 ? void 0 : _d.exists),
        });
        if (!((_e = event.data) === null || _e === void 0 ? void 0 : _e.after.exists))
            return;
        const after = ((_f = event.data.after.data()) !== null && _f !== void 0 ? _f : {});
        const status = String((_g = after['status']) !== null && _g !== void 0 ? _g : '');
        console.log('recordRecommendationVisitOnPointAward:after-status', { status });
        if (status !== 'accepted')
            return;
        const beforeStatus = ((_h = event.data.before) === null || _h === void 0 ? void 0 : _h.exists)
            ? String((_k = ((_j = event.data.before.data()) !== null && _j !== void 0 ? _j : {})['status']) !== null && _k !== void 0 ? _k : '')
            : '';
        console.log('recordRecommendationVisitOnPointAward:before-status', { beforeStatus });
        if (beforeStatus === 'accepted')
            return;
        const storeId = event.params.storeId;
        const userId = event.params.userId;
        const since = firestore_2.Timestamp.fromMillis(Date.now() - 30 * 24 * 60 * 60 * 1000);
        const impressionSnap = await db
            .collection(RECOMMENDATION_IMPRESSIONS_COLLECTION)
            .where('userId', '==', userId)
            .where('targetStoreId', '==', storeId)
            .where('shownAt', '>=', since)
            .orderBy('shownAt', 'desc')
            .limit(1)
            .get();
        console.log('recordRecommendationVisitOnPointAward:impression-check', {
            storeId,
            userId,
            impressionCount: impressionSnap.size,
        });
        if (impressionSnap.empty)
            return;
        const impressionDoc = impressionSnap.docs[0];
        const impressionData = ((_l = impressionDoc.data()) !== null && _l !== void 0 ? _l : {});
        const impressionId = impressionDoc.id;
        const existing = await db
            .collection(RECOMMENDATION_VISITS_COLLECTION)
            .where('impressionId', '==', impressionId)
            .limit(1)
            .get();
        console.log('recordRecommendationVisitOnPointAward:existing-visit-check', {
            impressionId,
            existingCount: existing.size,
        });
        if (!existing.empty)
            return;
        const sourceStoreId = typeof impressionData['sourceStoreId'] === 'string' ? impressionData['sourceStoreId'] : '';
        const triggerType = typeof impressionData['triggerType'] === 'string' ? impressionData['triggerType'] : 'point_award';
        await db.collection(RECOMMENDATION_VISITS_COLLECTION).add(stripUndefined({
            userId,
            sourceStoreId,
            targetStoreId: storeId,
            triggerType,
            impressionId,
            visitAt: firestore_2.FieldValue.serverTimestamp(),
            firstPointAwardAt: firestore_2.FieldValue.serverTimestamp(),
            withinHours: 720,
        }));
        console.log('recordRecommendationVisitOnPointAward:visit-created', {
            impressionId,
            targetStoreId: storeId,
            userId,
        });
    }
    catch (error) {
        console.error('recordRecommendationVisitOnPointAward failed', error);
    }
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
    const type = typeof data['type'] === 'string' ? data['type'] : '';
    // stamp タイプは punchStamp が直接 store_stats/store_users を更新済みのためスキップ
    if (type === 'stamp')
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
    if (type === 'award' || type === 'use') {
        updates['visitorCount'] = firestore_2.FieldValue.increment(1);
    }
    await db
        .collection('store_stats')
        .doc(storeId)
        .collection('daily')
        .doc(dateKey)
        .set(updates, { merge: true });
    if ((type === 'award' || type === 'use') && userId) {
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
const https_3 = require("firebase-functions/v2/https");
exports.testHttpFunction = (0, https_3.onRequest)({
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
// スタンプ押印（店舗側アプリ用）
exports.punchStamp = (0, https_1.onCall)({
    region: 'asia-northeast1',
    enforceAppCheck: false,
}, async (request) => {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l, _m, _o, _p, _q, _r, _s, _t;
    if (!request.auth) {
        throw new https_1.HttpsError('unauthenticated', 'Store must be authenticated');
    }
    const { userId, storeId, selectedCouponIds: rawSelectedCouponIds } = request.data || {};
    if (!userId || !storeId) {
        throw new https_1.HttpsError('invalid-argument', 'Missing required parameters: userId and storeId');
    }
    const selectedCouponIds = Array.isArray(rawSelectedCouponIds)
        ? rawSelectedCouponIds.filter((id) => typeof id === 'string' && id.trim().length > 0)
        : [];
    console.log('[punchStamp] selectedCouponIds:', selectedCouponIds);
    const storeUserId = request.auth.uid;
    const storeUserRef = db.collection(USERS_COLLECTION).doc(storeUserId);
    const storeRef = db.collection('stores').doc(storeId);
    const targetUserRef = db.collection(USERS_COLLECTION).doc(userId);
    const targetStoreRef = targetUserRef.collection('stores').doc(storeId);
    const storeUserStatsRef = db.collection('store_users').doc(storeId).collection('users').doc(userId);
    const result = await db.runTransaction(async (txn) => {
        var _a, _b, _c, _d, _e, _f, _g, _h;
        const [storeUserSnap, storeSnap] = await Promise.all([
            txn.get(storeUserRef),
            txn.get(storeRef),
        ]);
        if (!storeUserSnap.exists) {
            throw new https_1.HttpsError('permission-denied', 'Store user not found');
        }
        if (!storeSnap.exists) {
            throw new https_1.HttpsError('not-found', 'Store not found');
        }
        const storeUserData = storeUserSnap.data();
        const currentStoreId = ((_a = storeUserData['currentStoreId']) !== null && _a !== void 0 ? _a : '').toString();
        const createdStores = (_b = storeUserData['createdStores']) !== null && _b !== void 0 ? _b : [];
        const isOwner = storeUserData['isOwner'] === true || storeUserData['isStoreOwner'] === true;
        const storeCreatedBy = ((_d = (_c = storeSnap.data()) === null || _c === void 0 ? void 0 : _c.createdBy) !== null && _d !== void 0 ? _d : '').toString();
        const isMember = currentStoreId === storeId || createdStores.includes(storeId) || storeCreatedBy === storeUserId;
        if (!isOwner && !isMember) {
            throw new https_1.HttpsError('permission-denied', 'Not authorized for this store');
        }
        const storeName = ((_f = (_e = storeSnap.data()) === null || _e === void 0 ? void 0 : _e.name) !== null && _f !== void 0 ? _f : '').toString();
        const targetStoreSnap = await txn.get(targetStoreRef);
        const storeUserStatsSnap = await txn.get(storeUserStatsRef);
        const currentStamps = asInt((_g = targetStoreSnap.data()) === null || _g === void 0 ? void 0 : _g['stamps'], 0);
        const stampsAdded = 1; // 上限なし・常に加算
        const nextStamps = currentStamps + 1;
        const cardCompleted = nextStamps % MAX_STAMPS === 0; // 10の倍数到達で達成
        const couponReads = [];
        if (selectedCouponIds.length > 0) {
            for (const couponId of selectedCouponIds) {
                const couponRef = db
                    .collection('coupons')
                    .doc(storeId)
                    .collection('coupons')
                    .doc(couponId);
                const publicCouponRef = db.collection('public_coupons').doc(couponId);
                const usedByRef = couponRef.collection('usedBy').doc(userId);
                const userUsedRef = targetUserRef.collection('used_coupons').doc(couponId);
                const [couponSnap, usedBySnap, userUsedSnap, publicSnap] = await Promise.all([
                    txn.get(couponRef),
                    txn.get(usedByRef),
                    txn.get(userUsedRef),
                    txn.get(publicCouponRef),
                ]);
                couponReads.push({
                    couponId,
                    couponRef,
                    publicCouponRef,
                    usedByRef,
                    userUsedRef,
                    couponSnap,
                    usedBySnap,
                    userUsedSnap,
                    publicSnap,
                });
            }
        }
        // 常にスタンプ加算（上限なし）
        txn.set(targetStoreRef, stripUndefined({
            storeId,
            storeName: storeName || undefined,
            stamps: nextStamps,
            lastVisited: firestore_2.FieldValue.serverTimestamp(),
            updatedAt: firestore_2.FieldValue.serverTimestamp(),
        }), { merge: true });
        const now = new Date();
        const todayStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
        const statsRef = db.collection('store_stats').doc(storeId).collection('daily').doc(todayStr);
        txn.set(statsRef, {
            date: todayStr,
            visitorCount: firestore_2.FieldValue.increment(1),
            lastUpdated: firestore_2.FieldValue.serverTimestamp(),
        }, { merge: true });
        if (storeUserStatsSnap.exists) {
            txn.set(storeUserStatsRef, {
                lastVisitAt: firestore_2.FieldValue.serverTimestamp(),
                totalVisits: firestore_2.FieldValue.increment(1),
                updatedAt: firestore_2.FieldValue.serverTimestamp(),
            }, { merge: true });
        }
        else {
            txn.set(storeUserStatsRef, {
                userId,
                storeId,
                firstVisitAt: firestore_2.FieldValue.serverTimestamp(),
                lastVisitAt: firestore_2.FieldValue.serverTimestamp(),
                totalVisits: 1,
                createdAt: firestore_2.FieldValue.serverTimestamp(),
                updatedAt: firestore_2.FieldValue.serverTimestamp(),
            });
        }
        if (couponReads.length > 0) {
            const now = new Date();
            for (const entry of couponReads) {
                const { couponId, couponRef, publicCouponRef, usedByRef, userUsedRef, couponSnap, usedBySnap, userUsedSnap, publicSnap } = entry;
                if (!couponSnap.exists) {
                    throw new https_1.HttpsError('not-found', `Coupon not found: ${couponId}`);
                }
                const couponData = (_h = couponSnap.data()) !== null && _h !== void 0 ? _h : {};
                const isActive = couponData['isActive'] !== false;
                const usageLimit = asInt(couponData['usageLimit'], 0);
                const usedCount = asInt(couponData['usedCount'], 0);
                const noExpiry = couponData['noExpiry'] === true;
                const noUsageLimit = couponData['noUsageLimit'] === true;
                const validUntilValue = couponData['validUntil'];
                const validUntil = validUntilValue instanceof firestore_2.Timestamp ? validUntilValue.toDate() : undefined;
                const isNoExpiry = noExpiry || (validUntil && validUntil.getFullYear() >= 2100);
                if (!isActive) {
                    throw new https_1.HttpsError('failed-precondition', `Coupon inactive: ${couponId}`);
                }
                if (!isNoExpiry && (!validUntil || validUntil.getTime() <= now.getTime())) {
                    throw new https_1.HttpsError('failed-precondition', `Coupon expired: ${couponId}`);
                }
                if (!noUsageLimit && usageLimit <= 0) {
                    throw new https_1.HttpsError('failed-precondition', `Coupon usage limit invalid: ${couponId}`);
                }
                if (!noUsageLimit && usedCount >= usageLimit) {
                    throw new https_1.HttpsError('failed-precondition', `Coupon usage limit reached: ${couponId}`);
                }
                if (usedBySnap.exists) {
                    throw new https_1.HttpsError('already-exists', `Coupon already used: ${couponId}`);
                }
                if (userUsedSnap.exists) {
                    throw new https_1.HttpsError('already-exists', `Coupon already used: ${couponId}`);
                }
                txn.set(usedByRef, {
                    userId,
                    usedAt: firestore_2.FieldValue.serverTimestamp(),
                    couponId,
                    storeId,
                });
                txn.set(userUsedRef, {
                    userId,
                    usedAt: firestore_2.FieldValue.serverTimestamp(),
                    couponId,
                    storeId,
                });
                const nextUsedCount = usedCount + 1;
                const shouldDeactivate = !noUsageLimit && usageLimit > 0 && nextUsedCount === usageLimit;
                txn.update(couponRef, Object.assign(Object.assign({ usedCount: nextUsedCount }, (shouldDeactivate ? { isActive: false } : {})), { updatedAt: firestore_2.FieldValue.serverTimestamp() }));
                if (publicSnap.exists) {
                    txn.update(publicCouponRef, Object.assign(Object.assign({ usedCount: nextUsedCount }, (shouldDeactivate ? { isActive: false } : {})), { updatedAt: firestore_2.FieldValue.serverTimestamp() }));
                }
            }
        }
        return {
            userId,
            storeId,
            storeName,
            stampsAdded,
            stampsAfter: nextStamps,
            cardCompleted,
        };
    });
    const requestRef = db
        .collection('point_requests')
        .doc(storeId)
        .collection(userId)
        .doc('award_request');
    await requestRef.set({
        status: 'accepted',
        requestType: 'stamp',
        pointsToAward: 0,
        userPoints: 0,
        amount: 0,
        usedPoints: 0,
        selectedCouponIds: selectedCouponIds.length > 0 ? selectedCouponIds : firestore_2.FieldValue.delete(),
        storeId,
        storeName: (_a = result.storeName) !== null && _a !== void 0 ? _a : '',
        userId,
        respondedBy: storeUserId,
        createdAt: firestore_2.FieldValue.serverTimestamp(),
        respondedAt: firestore_2.FieldValue.serverTimestamp(),
        userNotified: false,
        userNotifiedAt: firestore_2.FieldValue.delete(),
    }, { merge: true });
    // stores/{storeId}/transactions にスタンプ来店記録を作成
    // フィルター時のクエリ対象となるため、userGender/userAgeGroup を含める
    let userGender = null;
    let userAgeGroup = null;
    let userPrefecture = null;
    let userCity = null;
    try {
        const targetUserSnap = await db.collection(USERS_COLLECTION).doc(userId).get();
        if (targetUserSnap.exists) {
            const userData = targetUserSnap.data();
            userGender = (typeof (userData === null || userData === void 0 ? void 0 : userData.gender) === 'string' ? userData.gender : null);
            userPrefecture = (typeof (userData === null || userData === void 0 ? void 0 : userData.prefecture) === 'string' ? userData.prefecture : null);
            userCity = (typeof (userData === null || userData === void 0 ? void 0 : userData.city) === 'string' ? userData.city : null);
            const birthDateVal = userData === null || userData === void 0 ? void 0 : userData.birthDate;
            if (birthDateVal) {
                const bd = birthDateVal instanceof firestore_2.Timestamp
                    ? birthDateVal
                    : (birthDateVal instanceof Date ? firestore_2.Timestamp.fromDate(birthDateVal) : null);
                if (bd) {
                    userAgeGroup = calculateAgeGroup(bd);
                }
            }
        }
    }
    catch (e) {
        console.error('[punchStamp] ユーザー属性取得エラー（続行）:', e);
    }
    const stampTxnRef = db.collection('stores').doc(storeId).collection('transactions').doc();
    await stampTxnRef.set({
        transactionId: stampTxnRef.id,
        storeId,
        storeName: (_b = result.storeName) !== null && _b !== void 0 ? _b : '',
        userId,
        type: 'stamp',
        amountYen: 0,
        points: 0,
        status: 'completed',
        source: 'stamp_punch',
        userGender,
        userAgeGroup,
        userPrefecture,
        userCity,
        createdAt: firestore_2.FieldValue.serverTimestamp(),
        createdAtClient: new Date(),
    });
    // バッジ判定 & user_achievement_events 作成
    try {
        const badges = await checkAndAwardBadges({ userId, storeId });
        const eventRef = db
            .collection(USER_ACHIEVEMENT_EVENTS_COLLECTION)
            .doc(userId)
            .collection('events')
            .doc(stampTxnRef.id);
        await eventRef.set({
            type: 'stamp_punch',
            transactionId: stampTxnRef.id,
            storeId,
            storeName: (_c = result.storeName) !== null && _c !== void 0 ? _c : '',
            pointsAwarded: 0,
            stampsAdded: (_d = result.stampsAdded) !== null && _d !== void 0 ? _d : 0,
            stampsAfter: (_e = result.stampsAfter) !== null && _e !== void 0 ? _e : 0,
            cardCompleted: (_f = result.cardCompleted) !== null && _f !== void 0 ? _f : false,
            badges,
            createdAt: firestore_2.FieldValue.serverTimestamp(),
            seenAt: null,
        }, { merge: true });
    }
    catch (e) {
        console.error('[punchStamp] achievement event creation error:', e);
    }
    // 自動フォロー: スタンプ押印時に店舗を自動フォロー（未フォローの場合のみ）
    try {
        const followDocRef = db
            .collection(USERS_COLLECTION)
            .doc(userId)
            .collection('followed_stores')
            .doc(storeId);
        const followSnap = await followDocRef.get();
        if (!followSnap.exists) {
            const storeDoc = await db.collection('stores').doc(storeId).get();
            const storeData = storeDoc.data();
            const userDoc = await db.collection(USERS_COLLECTION).doc(userId).get();
            const userData = userDoc.data();
            const followBatch = db.batch();
            followBatch.set(followDocRef, {
                storeId,
                storeName: (_g = result.storeName) !== null && _g !== void 0 ? _g : '',
                category: (_h = storeData === null || storeData === void 0 ? void 0 : storeData.category) !== null && _h !== void 0 ? _h : '',
                storeImageUrl: (_j = storeData === null || storeData === void 0 ? void 0 : storeData.storeImageUrl) !== null && _j !== void 0 ? _j : null,
                followedAt: firestore_2.FieldValue.serverTimestamp(),
                source: 'stamp',
            });
            followBatch.set(db.collection('stores').doc(storeId).collection('followers').doc(userId), {
                userId,
                userName: (_k = userData === null || userData === void 0 ? void 0 : userData.displayName) !== null && _k !== void 0 ? _k : 'ユーザー',
                followedAt: firestore_2.FieldValue.serverTimestamp(),
            });
            followBatch.update(db.collection(USERS_COLLECTION).doc(userId), {
                followedStoreIds: firestore_2.FieldValue.arrayUnion(storeId),
                updatedAt: firestore_2.FieldValue.serverTimestamp(),
            });
            await followBatch.commit();
            console.log(`[punchStamp] Auto-followed store ${storeId} for user ${userId}`);
        }
    }
    catch (e) {
        console.error('[punchStamp] auto-follow error:', e);
    }
    // スタンプカード達成時のクーポン自動付与
    if (result.cardCompleted) {
        try {
            const stampCoupons = await db
                .collection('coupons')
                .doc(storeId)
                .collection('coupons')
                .where('requiredStampCount', '>', 0)
                .where('isActive', '==', true)
                .get();
            for (const couponDoc of stampCoupons.docs) {
                const couponData = couponDoc.data();
                // 発行枚数制限チェック
                const noUsageLimit = couponData['noUsageLimit'] === true;
                const usageLimit = asInt(couponData['usageLimit'], 0);
                const usedCount = asInt(couponData['usedCount'], 0);
                if (!noUsageLimit && usageLimit > 0 && usedCount >= usageLimit)
                    continue;
                const userCouponRef = db.collection('user_coupons').doc();
                await userCouponRef.set({
                    userId,
                    couponId: couponDoc.id,
                    storeId,
                    storeName: (_l = couponData['storeName']) !== null && _l !== void 0 ? _l : '',
                    title: (_m = couponData['title']) !== null && _m !== void 0 ? _m : '',
                    obtainedAt: firestore_2.FieldValue.serverTimestamp(),
                    isUsed: false,
                    noExpiry: true,
                    validUntil: null,
                    type: 'stamp_reward',
                    discountValue: (_o = couponData['discountValue']) !== null && _o !== void 0 ? _o : 0,
                    discountType: (_p = couponData['discountType']) !== null && _p !== void 0 ? _p : 'fixed_amount',
                    couponType: (_q = couponData['couponType']) !== null && _q !== void 0 ? _q : 'discount',
                    requiredStampCount: 0,
                });
            }
            console.log(`[punchStamp] Awarded stamp coupons for user ${userId}, store ${storeId}`);
        }
        catch (e) {
            console.error('[punchStamp] stamp coupon award error:', e);
        }
    }
    // 友達紹介コイン付与（初回スタンプ時）
    let referralCoinJustAwarded = false;
    let referralReferredByUid = null;
    let referralAwardedInviteeCoins = 5;
    let referralAwardedInviterCoins = 5;
    let pendingReferralDocRef = null;
    try {
        // referral_uses から plannedCoins を取得（トランザクション前に実行）
        const pendingReferralSnap = await db.collection(REFERRAL_USES_COLLECTION)
            .where('referredUserId', '==', userId)
            .where('status', '==', 'pending')
            .limit(1)
            .get();
        if (!pendingReferralSnap.empty) {
            pendingReferralDocRef = pendingReferralSnap.docs[0].ref;
            const plannedCoins = (_r = pendingReferralSnap.docs[0].data()) === null || _r === void 0 ? void 0 : _r.plannedCoins;
            if (typeof (plannedCoins === null || plannedCoins === void 0 ? void 0 : plannedCoins.invitee) === 'number') {
                referralAwardedInviteeCoins = plannedCoins.invitee;
            }
            if (typeof (plannedCoins === null || plannedCoins === void 0 ? void 0 : plannedCoins.inviter) === 'number') {
                referralAwardedInviterCoins = plannedCoins.inviter;
            }
        }
        await db.runTransaction(async (refTxn) => {
            const refUserSnap = await refTxn.get(targetUserRef);
            if (!refUserSnap.exists)
                return;
            const refUserData = refUserSnap.data();
            const referredBy = typeof refUserData.referredBy === 'string' ? refUserData.referredBy : null;
            const alreadyAwarded = refUserData.referralCoinAwarded === true;
            if (!referredBy || alreadyAwarded)
                return;
            const referrerRef = db.collection(USERS_COLLECTION).doc(referredBy);
            const referrerSnap = await refTxn.get(referrerRef);
            if (!referrerSnap.exists)
                return;
            const refNow = new Date();
            const refExpiresAt = new Date(refNow.getTime() + 180 * 24 * 60 * 60 * 1000);
            refTxn.update(targetUserRef, {
                coins: firestore_2.FieldValue.increment(referralAwardedInviteeCoins),
                coinLastEarnedAt: firestore_2.Timestamp.fromDate(refNow),
                coinExpiresAt: firestore_2.Timestamp.fromDate(refExpiresAt),
                referralCoinAwarded: true,
                updatedAt: firestore_2.FieldValue.serverTimestamp(),
            });
            refTxn.update(referrerRef, {
                coins: firestore_2.FieldValue.increment(referralAwardedInviterCoins),
                coinLastEarnedAt: firestore_2.Timestamp.fromDate(refNow),
                coinExpiresAt: firestore_2.Timestamp.fromDate(refExpiresAt),
                referralEarningsPoints: firestore_2.FieldValue.increment(referralAwardedInviterCoins),
                updatedAt: firestore_2.FieldValue.serverTimestamp(),
            });
            referralCoinJustAwarded = true;
            referralReferredByUid = referredBy;
        });
        if (referralCoinJustAwarded && referralReferredByUid) {
            const refNow = new Date();
            // referral_uses のステータスを 'awarded' に更新
            if (pendingReferralDocRef) {
                await pendingReferralDocRef.update({
                    status: 'awarded',
                    awardedAt: firestore_2.FieldValue.serverTimestamp(),
                });
            }
            // 両者への通知
            const [refereeUserDoc, referrerUserDoc] = await Promise.all([
                db.collection(USERS_COLLECTION).doc(userId).get(),
                db.collection(USERS_COLLECTION).doc(referralReferredByUid).get(),
            ]);
            const refereeName = typeof ((_s = refereeUserDoc.data()) === null || _s === void 0 ? void 0 : _s.displayName) === 'string'
                ? (refereeUserDoc.data().displayName.trim() || '友達')
                : '友達';
            const referrerName = typeof ((_t = referrerUserDoc.data()) === null || _t === void 0 ? void 0 : _t.displayName) === 'string'
                ? (referrerUserDoc.data().displayName.trim() || '友達')
                : '友達';
            const refereeNotifRef = targetUserRef.collection('notifications').doc();
            await refereeNotifRef.set({
                id: refereeNotifRef.id,
                userId,
                title: '友達紹介コイン獲得',
                body: `${referrerName}さんのコードで登録し、${referralAwardedInviteeCoins}コインが付与されました`,
                type: 'social',
                createdAt: refNow.toISOString(),
                isRead: false,
                isDelivered: true,
                data: {
                    source: 'user',
                    reason: 'friend_referral',
                    coins: referralAwardedInviteeCoins,
                },
                tags: ['referral'],
            });
            const referrerNotifRef = db.collection(USERS_COLLECTION).doc(referralReferredByUid).collection('notifications').doc();
            await referrerNotifRef.set({
                id: referrerNotifRef.id,
                userId: referralReferredByUid,
                title: '友達紹介コイン獲得',
                body: `${refereeName}さんが初めてお店でスタンプを獲得し、${referralAwardedInviterCoins}コインが付与されました`,
                type: 'social',
                createdAt: refNow.toISOString(),
                isRead: false,
                isDelivered: true,
                data: {
                    source: 'user',
                    reason: 'friend_referral',
                    coins: referralAwardedInviterCoins,
                },
                tags: ['referral'],
            });
            console.log(`[punchStamp] Referral coins awarded: referee=${userId} (${referralAwardedInviteeCoins}coins), referrer=${referralReferredByUid} (${referralAwardedInviterCoins}coins)`);
        }
    }
    catch (e) {
        console.error('[punchStamp] referral coin award error:', e);
    }
    return result;
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
        console.log(`Check-in recorded for user ${userId} at store ${storeId}`);
    }
    catch (error) {
        console.error('Error recording check-in:', error);
        throw error;
    }
}
exports.startInstagramAuth = (0, https_1.onCall)({
    region: 'asia-northeast1',
    invoker: 'public',
    secrets: [INSTAGRAM_APP_ID, INSTAGRAM_APP_SECRET, INSTAGRAM_REDIRECT_URI],
}, async (request) => {
    var _a, _b, _c, _d;
    if (!((_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid)) {
        throw new https_1.HttpsError('unauthenticated', 'ログインが必要です');
    }
    const storeId = toStringValue((_b = request.data) === null || _b === void 0 ? void 0 : _b.storeId).trim();
    if (!storeId) {
        throw new https_1.HttpsError('invalid-argument', 'storeId が必要です');
    }
    const storeDoc = await db.collection('stores').doc(storeId).get();
    if (!storeDoc.exists) {
        throw new https_1.HttpsError('not-found', '店舗が見つかりません');
    }
    const storeData = storeDoc.data();
    const ownerId = toStringValue((_c = storeData['ownerId']) !== null && _c !== void 0 ? _c : storeData['createdBy']);
    const isAdmin = ((_d = request.auth.token) === null || _d === void 0 ? void 0 : _d.admin) === true;
    if (ownerId && request.auth.uid !== ownerId && !isAdmin) {
        throw new https_1.HttpsError('permission-denied', '権限がありません');
    }
    const authUrl = buildInstagramAuthUrl();
    return { success: true, authUrl };
});
exports.exchangeInstagramAuthCode = (0, https_1.onCall)({
    region: 'asia-northeast1',
    invoker: 'public',
    secrets: [INSTAGRAM_APP_ID, INSTAGRAM_APP_SECRET, INSTAGRAM_REDIRECT_URI],
}, async (request) => {
    var _a, _b, _c, _d, _e;
    if (!((_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid)) {
        throw new https_1.HttpsError('unauthenticated', 'ログインが必要です');
    }
    const storeId = toStringValue((_b = request.data) === null || _b === void 0 ? void 0 : _b.storeId).trim();
    const code = toStringValue((_c = request.data) === null || _c === void 0 ? void 0 : _c.code).trim();
    if (!storeId || !code) {
        throw new https_1.HttpsError('invalid-argument', 'storeId と code が必要です');
    }
    const storeDoc = await db.collection('stores').doc(storeId).get();
    if (!storeDoc.exists) {
        throw new https_1.HttpsError('not-found', '店舗が見つかりません');
    }
    const storeData = storeDoc.data();
    const ownerId = toStringValue((_d = storeData['ownerId']) !== null && _d !== void 0 ? _d : storeData['createdBy']);
    const isAdmin = ((_e = request.auth.token) === null || _e === void 0 ? void 0 : _e.admin) === true;
    if (ownerId && request.auth.uid !== ownerId && !isAdmin) {
        throw new https_1.HttpsError('permission-denied', '権限がありません');
    }
    try {
        const { accessToken } = await exchangeInstagramCode({ code });
        const longToken = await exchangeLongLivedToken({ accessToken });
        const { instagramUserId, username } = await resolveInstagramUserId(longToken);
        const instagramAuth = stripUndefined({
            instagramUserId,
            accessToken: longToken,
            username,
        });
        await storeDoc.ref.set({
            instagramAuth,
        }, { merge: true });
        const count = await syncInstagramPostsForStore({
            storeId,
            storeData: Object.assign(Object.assign({}, storeData), { instagramAuth }),
        });
        return { success: true, count };
    }
    catch (error) {
        console.error('Instagram auth exchange failed:', error);
        throw new https_1.HttpsError('internal', 'Instagram連携に失敗しました');
    }
});
exports.updateInstagramSyncSettings = (0, https_1.onCall)({
    region: 'asia-northeast1',
    invoker: 'public',
}, async (request) => {
    var _a, _b, _c, _d, _e, _f, _g;
    if (!((_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid)) {
        throw new https_1.HttpsError('unauthenticated', 'ログインが必要です');
    }
    const storeId = toStringValue((_b = request.data) === null || _b === void 0 ? void 0 : _b.storeId).trim();
    const enabled = ((_c = request.data) === null || _c === void 0 ? void 0 : _c.enabled) === false ? false : true;
    const rawSyncTime = toStringValue((_d = request.data) === null || _d === void 0 ? void 0 : _d.syncTime).trim();
    if (!storeId) {
        throw new https_1.HttpsError('invalid-argument', 'storeId が必要です');
    }
    if (rawSyncTime && !isInstagramSyncTimeAllowed(rawSyncTime)) {
        throw new https_1.HttpsError('invalid-argument', 'syncTime は 09:00〜21:00 の30分単位（HH:mm）で指定してください');
    }
    const storeDoc = await db.collection('stores').doc(storeId).get();
    if (!storeDoc.exists) {
        throw new https_1.HttpsError('not-found', '店舗が見つかりません');
    }
    const storeData = storeDoc.data();
    const ownerId = toStringValue((_e = storeData['ownerId']) !== null && _e !== void 0 ? _e : storeData['createdBy']);
    const isAdmin = ((_f = request.auth.token) === null || _f === void 0 ? void 0 : _f.admin) === true;
    if (ownerId && request.auth.uid !== ownerId && !isAdmin) {
        throw new https_1.HttpsError('permission-denied', '権限がありません');
    }
    const currentSettings = (_g = storeData['instagramSyncSettings']) !== null && _g !== void 0 ? _g : {};
    const currentNextSyncAt = toDateValue(currentSettings['nextSyncAt']);
    const syncInfo = storeData['instagramSync'];
    const lastSyncAt = toDateValue(syncInfo === null || syncInfo === void 0 ? void 0 : syncInfo['lastSyncAt']);
    const syncTime = normalizeInstagramSyncTime(rawSyncTime || currentSettings['syncTime'], currentNextSyncAt !== null && currentNextSyncAt !== void 0 ? currentNextSyncAt : lastSyncAt);
    const nextSyncDate = enabled
        ? buildNextInstagramSyncDate(new Date(), syncTime)
        : null;
    const updatePayload = {
        'instagramSyncSettings.enabled': enabled,
        'instagramSyncSettings.syncTime': syncTime,
        'instagramSyncSettings.updatedAt': firestore_2.FieldValue.serverTimestamp(),
        'instagramSyncSettings.nextSyncAt': nextSyncDate
            ? firestore_2.Timestamp.fromDate(nextSyncDate)
            : firestore_2.FieldValue.delete(),
        'instagramSyncSettings.intervalMinutes': firestore_2.FieldValue.delete(),
    };
    await storeDoc.ref.update(updatePayload);
    return {
        success: true,
        enabled,
        syncTime,
        nextSyncAt: nextSyncDate ? nextSyncDate.toISOString() : null,
    };
});
exports.syncInstagramPosts = (0, https_1.onCall)({
    region: 'asia-northeast1',
    invoker: 'public',
}, async (request) => {
    var _a, _b, _c, _d;
    if (!((_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid)) {
        throw new https_1.HttpsError('unauthenticated', 'ログインが必要です');
    }
    const storeId = toStringValue((_b = request.data) === null || _b === void 0 ? void 0 : _b.storeId).trim();
    if (!storeId) {
        throw new https_1.HttpsError('invalid-argument', 'storeId が必要です');
    }
    const storeDoc = await db.collection('stores').doc(storeId).get();
    if (!storeDoc.exists) {
        throw new https_1.HttpsError('not-found', '店舗が見つかりません');
    }
    const storeData = storeDoc.data();
    const ownerId = toStringValue((_c = storeData['ownerId']) !== null && _c !== void 0 ? _c : storeData['createdBy']);
    const isAdmin = ((_d = request.auth.token) === null || _d === void 0 ? void 0 : _d.admin) === true;
    if (ownerId && request.auth.uid !== ownerId && !isAdmin) {
        throw new https_1.HttpsError('permission-denied', '権限がありません');
    }
    const count = await syncInstagramPostsForStore({ storeId, storeData });
    return { success: true, count };
});
exports.unlinkInstagramAuth = (0, https_1.onCall)({
    region: 'asia-northeast1',
    invoker: 'public',
}, async (request) => {
    var _a, _b, _c, _d;
    if (!((_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid)) {
        throw new https_1.HttpsError('unauthenticated', 'ログインが必要です');
    }
    const storeId = toStringValue((_b = request.data) === null || _b === void 0 ? void 0 : _b.storeId).trim();
    if (!storeId) {
        throw new https_1.HttpsError('invalid-argument', 'storeId が必要です');
    }
    const storeDoc = await db.collection('stores').doc(storeId).get();
    if (!storeDoc.exists) {
        throw new https_1.HttpsError('not-found', '店舗が見つかりません');
    }
    const storeData = storeDoc.data();
    const ownerId = toStringValue((_c = storeData['ownerId']) !== null && _c !== void 0 ? _c : storeData['createdBy']);
    const isAdmin = ((_d = request.auth.token) === null || _d === void 0 ? void 0 : _d.admin) === true;
    if (ownerId && request.auth.uid !== ownerId && !isAdmin) {
        throw new https_1.HttpsError('permission-denied', '権限がありません');
    }
    await storeDoc.ref.set({
        instagramAuth: firestore_2.FieldValue.delete(),
        instagramSync: firestore_2.FieldValue.delete(),
        instagramSyncSettings: firestore_2.FieldValue.delete(),
    }, { merge: true });
    return { success: true };
});
exports.syncInstagramPostsScheduled = (0, scheduler_1.onSchedule)({
    region: 'asia-northeast1',
    schedule: 'every 30 minutes',
    timeZone: 'Asia/Tokyo',
}, async () => {
    const stores = await db
        .collection('stores')
        .where('instagramAuth.instagramUserId', '!=', '')
        .get();
    const now = new Date();
    let processed = 0;
    let total = 0;
    for (const doc of stores.docs) {
        const storeData = doc.data();
        if (!shouldRunInstagramSync(storeData, now)) {
            continue;
        }
        processed += 1;
        try {
            const count = await syncInstagramPostsForStore({ storeId: doc.id, storeData });
            total += count;
        }
        catch (error) {
            console.error(`Instagram sync failed: storeId=${doc.id}`, error);
        }
    }
    console.log(`Instagram sync finished: stores=${processed}, posts=${total}, checked=${stores.size}`);
});
exports.expireCoinsScheduled = (0, scheduler_1.onSchedule)({
    region: 'asia-northeast1',
    schedule: 'every day 03:30',
    timeZone: 'Asia/Tokyo',
}, async () => {
    const now = firestore_2.Timestamp.now();
    const BATCH_SIZE = 400;
    let expiredUsers = 0;
    let cleanedUsers = 0;
    while (true) {
        const snapshot = await db
            .collection(USERS_COLLECTION)
            .where('coinExpiresAt', '<=', now)
            .limit(BATCH_SIZE)
            .get();
        if (snapshot.empty)
            break;
        const batch = db.batch();
        let updates = 0;
        for (const doc of snapshot.docs) {
            const data = doc.data();
            const currentCoins = asInt(data['coins'], 0);
            if (currentCoins > 0) {
                batch.update(doc.ref, {
                    coins: 0,
                    coinExpiredAt: firestore_2.FieldValue.serverTimestamp(),
                    updatedAt: firestore_2.FieldValue.serverTimestamp(),
                });
                expiredUsers += 1;
                updates += 1;
                continue;
            }
            batch.update(doc.ref, {
                coinExpiresAt: firestore_2.FieldValue.delete(),
            });
            cleanedUsers += 1;
            updates += 1;
        }
        if (updates > 0) {
            await batch.commit();
        }
        if (snapshot.size < BATCH_SIZE) {
            break;
        }
    }
    console.log(`[expireCoinsScheduled] expiredUsers=${expiredUsers}, cleanedUsers=${cleanedUsers}`);
});
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
// フォロワーへの投稿通知
exports.notifyFollowersOnNewPost = (0, firestore_1.onDocumentCreated)({
    document: 'public_posts/{postId}',
    region: 'asia-northeast1',
}, async (event) => {
    var _a, _b, _c, _d;
    const data = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
    if (!data)
        return;
    const storeId = ((_b = data['storeId']) !== null && _b !== void 0 ? _b : '').toString();
    const storeName = ((_c = data['storeName']) !== null && _c !== void 0 ? _c : '').toString();
    const content = ((_d = data['content']) !== null && _d !== void 0 ? _d : '').toString();
    const isActive = data['isActive'] !== false;
    const isPublished = data['isPublished'] !== false;
    if (!storeId || !isActive || !isPublished)
        return;
    const followersSnap = await db
        .collection('stores')
        .doc(storeId)
        .collection('followers')
        .get();
    if (followersSnap.empty)
        return;
    const truncatedContent = content.length > 50 ? content.substring(0, 50) + '...' : content;
    const BATCH_SIZE = 500;
    const followerDocs = followersSnap.docs;
    for (let i = 0; i < followerDocs.length; i += BATCH_SIZE) {
        const chunk = followerDocs.slice(i, i + BATCH_SIZE);
        await Promise.all(chunk.map(async (followerDoc) => {
            var _a;
            const followerId = followerDoc.id;
            try {
                const userDoc = await db.collection(USERS_COLLECTION).doc(followerId).get();
                const userData = userDoc.data();
                const postNotification = (_a = userData === null || userData === void 0 ? void 0 : userData.notificationSettings) === null || _a === void 0 ? void 0 : _a.post;
                if (postNotification === false)
                    return;
                await createUserNotification({
                    userId: followerId,
                    title: `${storeName}が新しい投稿を公開しました`,
                    body: truncatedContent || '新しい投稿をチェックしましょう！',
                    type: 'marketing',
                    tags: ['store_post'],
                    data: {
                        type: 'store_post',
                        storeId,
                        storeName,
                        postId: event.params.postId,
                    },
                });
            }
            catch (e) {
                console.error(`[notifyFollowersOnNewPost] Error for follower ${followerId}:`, e);
            }
        }));
    }
    console.log(`[notifyFollowersOnNewPost] Notified ${followersSnap.size} followers for store ${storeId}`);
});
// フォロワーへのクーポン通知
exports.notifyFollowersOnNewCoupon = (0, firestore_1.onDocumentCreated)({
    document: 'public_coupons/{couponId}',
    region: 'asia-northeast1',
}, async (event) => {
    var _a, _b, _c, _d;
    const data = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
    if (!data)
        return;
    const storeId = ((_b = data['storeId']) !== null && _b !== void 0 ? _b : '').toString();
    const storeName = ((_c = data['storeName']) !== null && _c !== void 0 ? _c : '').toString();
    const title = ((_d = data['title']) !== null && _d !== void 0 ? _d : '').toString();
    const isActive = data['isActive'] !== false;
    if (!storeId || !isActive)
        return;
    const followersSnap = await db
        .collection('stores')
        .doc(storeId)
        .collection('followers')
        .get();
    if (followersSnap.empty)
        return;
    const BATCH_SIZE = 500;
    const followerDocs = followersSnap.docs;
    for (let i = 0; i < followerDocs.length; i += BATCH_SIZE) {
        const chunk = followerDocs.slice(i, i + BATCH_SIZE);
        await Promise.all(chunk.map(async (followerDoc) => {
            var _a;
            const followerId = followerDoc.id;
            try {
                const userDoc = await db.collection(USERS_COLLECTION).doc(followerId).get();
                const userData = userDoc.data();
                const couponNotification = (_a = userData === null || userData === void 0 ? void 0 : userData.notificationSettings) === null || _a === void 0 ? void 0 : _a.couponIssued;
                if (couponNotification === false)
                    return;
                await createUserNotification({
                    userId: followerId,
                    title: `${storeName}が新しいクーポンを発行しました`,
                    body: title || '新しいクーポンをチェックしましょう！',
                    type: 'marketing',
                    tags: ['store_coupon'],
                    data: {
                        type: 'store_coupon',
                        storeId,
                        storeName,
                        couponId: event.params.couponId,
                    },
                });
            }
            catch (e) {
                console.error(`[notifyFollowersOnNewCoupon] Error for follower ${followerId}:`, e);
            }
        }));
    }
    console.log(`[notifyFollowersOnNewCoupon] Notified ${followersSnap.size} followers for store ${storeId}`);
});
// 店舗作成時にisOwnerフラグを自動設定
// 作成者がisOwnerユーザーの場合、店舗ドキュメントにisOwner=trueを設定
exports.setStoreOwnerFlagOnCreate = (0, firestore_1.onDocumentCreated)({
    document: 'stores/{storeId}',
    region: 'asia-northeast1',
}, async (event) => {
    var _a, _b, _c, _d;
    const data = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
    if (!data)
        return;
    // 既にisOwner=trueなら何もしない
    if (data['isOwner'] === true)
        return;
    const createdBy = (_c = ((_b = data['createdBy']) !== null && _b !== void 0 ? _b : data['ownerId'])) === null || _c === void 0 ? void 0 : _c.toString();
    if (!createdBy)
        return;
    try {
        const userDoc = await db.collection(USERS_COLLECTION).doc(createdBy).get();
        const userData = userDoc.data();
        if ((userData === null || userData === void 0 ? void 0 : userData.isOwner) === true) {
            await ((_d = event.data) === null || _d === void 0 ? void 0 : _d.ref.update({ isOwner: true }));
            console.log(`[setStoreOwnerFlagOnCreate] isOwner=true を設定: ${event.params.storeId} (createdBy: ${createdBy})`);
        }
    }
    catch (e) {
        console.error(`[setStoreOwnerFlagOnCreate] Error:`, e);
    }
});
// 既存店舗のisOwnerフラグ一括同期（ワンタイム実行用）
exports.syncStoreOwnerFlags = (0, https_1.onCall)({ region: 'asia-northeast1' }, async (request) => {
    var _a, _b;
    // isOwner権限チェック
    if (!request.auth) {
        throw new https_1.HttpsError('unauthenticated', '認証が必要です');
    }
    const callerDoc = await db.collection(USERS_COLLECTION).doc(request.auth.uid).get();
    const callerData = callerDoc.data();
    if ((callerData === null || callerData === void 0 ? void 0 : callerData.isOwner) !== true) {
        throw new https_1.HttpsError('permission-denied', 'isOwner権限が必要です');
    }
    // isOwner=true の全ユーザーIDを取得
    const ownerUsersSnapshot = await db
        .collection(USERS_COLLECTION)
        .where('isOwner', '==', true)
        .get();
    const ownerUserIds = new Set(ownerUsersSnapshot.docs.map((doc) => doc.id));
    console.log(`[syncStoreOwnerFlags] isOwnerユーザー数: ${ownerUserIds.size}`);
    // 全店舗を確認し、createdBy/ownerIdがisOwnerユーザーならフラグ設定
    const storesSnapshot = await db.collection('stores').get();
    let updatedCount = 0;
    const BATCH_SIZE = 500;
    let batch = db.batch();
    let batchCount = 0;
    for (const storeDoc of storesSnapshot.docs) {
        const storeData = storeDoc.data();
        if (storeData['isOwner'] === true)
            continue;
        const createdBy = (_b = ((_a = storeData['createdBy']) !== null && _a !== void 0 ? _a : storeData['ownerId'])) === null || _b === void 0 ? void 0 : _b.toString();
        if (createdBy && ownerUserIds.has(createdBy)) {
            batch.update(storeDoc.ref, { isOwner: true });
            updatedCount++;
            batchCount++;
            if (batchCount >= BATCH_SIZE) {
                await batch.commit();
                batch = db.batch();
                batchCount = 0;
            }
        }
    }
    if (batchCount > 0) {
        await batch.commit();
    }
    console.log(`[syncStoreOwnerFlags] ${updatedCount}件の店舗を更新しました`);
    return { updatedCount };
});
// スタンプ数と来店回数の同期（管理者専用）
exports.syncStampsWithVisits = (0, https_1.onCall)({
    region: 'asia-northeast1',
    enforceAppCheck: false,
    timeoutSeconds: 300,
}, async (request) => {
    var _a, _b, _c, _d, _e;
    if (!request.auth) {
        throw new https_1.HttpsError('unauthenticated', 'Authentication required');
    }
    const callerUid = request.auth.uid;
    const callerSnap = await db.collection(USERS_COLLECTION).doc(callerUid).get();
    if (!callerSnap.exists || ((_a = callerSnap.data()) === null || _a === void 0 ? void 0 : _a['isOwner']) !== true) {
        throw new https_1.HttpsError('permission-denied', 'Only admin owners can execute this function');
    }
    const dryRun = ((_b = request.data) === null || _b === void 0 ? void 0 : _b.dryRun) === true;
    console.log(`[syncStampsWithVisits] 開始 (dryRun=${dryRun})`);
    const storesSnap = await db.collection('stores').get();
    let totalChecked = 0;
    let mismatchCount = 0;
    let updatedCount = 0;
    const mismatches = [];
    const BATCH_SIZE = 500;
    let batch = db.batch();
    let batchCount = 0;
    for (const storeDoc of storesSnap.docs) {
        const storeId = storeDoc.id;
        const storeName = storeDoc.data()['name'] || '店舗名なし';
        const storeUsersSnap = await db
            .collection('store_users')
            .doc(storeId)
            .collection('users')
            .get();
        for (const userDoc of storeUsersSnap.docs) {
            const userId = userDoc.id;
            const totalVisits = asInt(userDoc.data()['totalVisits'], 0);
            const userStoreRef = db
                .collection(USERS_COLLECTION)
                .doc(userId)
                .collection('stores')
                .doc(storeId);
            const userStoreSnap = await userStoreRef.get();
            const currentStamps = asInt((_c = userStoreSnap.data()) === null || _c === void 0 ? void 0 : _c['stamps'], 0);
            totalChecked++;
            if (totalVisits > currentStamps) {
                mismatchCount++;
                // ユーザー情報を取得（最大50件まで詳細を返却）
                let displayName = 'Unknown';
                let profileImageUrl = null;
                if (mismatches.length < 50) {
                    const userSnap = await db.collection(USERS_COLLECTION).doc(userId).get();
                    if (userSnap.exists) {
                        displayName = ((_d = userSnap.data()) === null || _d === void 0 ? void 0 : _d['displayName']) || 'Unknown';
                        profileImageUrl = ((_e = userSnap.data()) === null || _e === void 0 ? void 0 : _e['profileImageUrl']) || null;
                    }
                }
                mismatches.push({ storeId, userId, totalVisits, stamps: currentStamps, displayName, profileImageUrl, storeName });
                if (!dryRun) {
                    batch.set(userStoreRef, {
                        stamps: totalVisits,
                        updatedAt: firestore_2.FieldValue.serverTimestamp(),
                    }, { merge: true });
                    updatedCount++;
                    batchCount++;
                    if (batchCount >= BATCH_SIZE) {
                        await batch.commit();
                        batch = db.batch();
                        batchCount = 0;
                    }
                }
            }
        }
    }
    if (!dryRun && batchCount > 0) {
        await batch.commit();
    }
    console.log(`[syncStampsWithVisits] 完了: checked=${totalChecked}, mismatches=${mismatchCount}, updated=${updatedCount}`);
    return {
        dryRun,
        totalChecked,
        mismatchCount,
        updatedCount,
        mismatches: mismatches.slice(0, 50),
    };
});
// ===== 物理スタンプカード電子化移行 =====
// 店舗スタッフがユーザーのQRコードをスキャンし、物理カードのスタンプ数を入力して
// デジタルスタンプに移行する。来店扱い（コイン・visitCount）はしない。
exports.migrateStampCard = (0, https_1.onCall)({
    region: 'asia-northeast1',
    enforceAppCheck: false,
}, async (request) => {
    var _a, _b, _c, _d, _e;
    if (!request.auth) {
        throw new https_1.HttpsError('unauthenticated', 'Store must be authenticated');
    }
    const { userId, storeId, physicalStamps: rawPhysicalStamps } = request.data || {};
    if (!userId || !storeId) {
        throw new https_1.HttpsError('invalid-argument', 'Missing required parameters: userId and storeId');
    }
    const physicalStamps = asInt(rawPhysicalStamps, 0);
    if (physicalStamps < 1 || physicalStamps > 99) {
        throw new https_1.HttpsError('invalid-argument', 'physicalStamps must be between 1 and 99');
    }
    const staffUserId = request.auth.uid;
    const staffUserRef = db.collection(USERS_COLLECTION).doc(staffUserId);
    const storeRef = db.collection('stores').doc(storeId);
    const targetUserRef = db.collection(USERS_COLLECTION).doc(userId);
    const targetStoreRef = targetUserRef.collection('stores').doc(storeId);
    const migrationDocId = `${storeId}_${userId}`;
    const migrationDocRef = db.collection('stamp_migrations').doc(migrationDocId);
    const result = await db.runTransaction(async (txn) => {
        var _a, _b, _c, _d, _e, _f, _g;
        // スタッフの店舗権限チェック（punchStamp と同じロジック）
        const [staffUserSnap, storeSnap] = await Promise.all([
            txn.get(staffUserRef),
            txn.get(storeRef),
        ]);
        if (!staffUserSnap.exists) {
            throw new https_1.HttpsError('permission-denied', 'Store user not found');
        }
        if (!storeSnap.exists) {
            throw new https_1.HttpsError('not-found', 'Store not found');
        }
        const staffUserData = staffUserSnap.data();
        const currentStoreId = ((_a = staffUserData['currentStoreId']) !== null && _a !== void 0 ? _a : '').toString();
        const createdStores = (_b = staffUserData['createdStores']) !== null && _b !== void 0 ? _b : [];
        const isOwnerFlag = staffUserData['isOwner'] === true || staffUserData['isStoreOwner'] === true;
        const storeCreatedBy = ((_d = (_c = storeSnap.data()) === null || _c === void 0 ? void 0 : _c.createdBy) !== null && _d !== void 0 ? _d : '').toString();
        const isMember = currentStoreId === storeId || createdStores.includes(storeId) || storeCreatedBy === staffUserId;
        if (!isOwnerFlag && !isMember) {
            throw new https_1.HttpsError('permission-denied', 'Not authorized for this store');
        }
        // 対象ユーザー存在確認
        const targetUserSnap = await txn.get(targetUserRef);
        if (!targetUserSnap.exists) {
            throw new https_1.HttpsError('not-found', 'Target user not found');
        }
        // 二重移行チェック: migrationId を固定IDにすることでアトミックに防止
        const migrationSnap = await txn.get(migrationDocRef);
        if (migrationSnap.exists) {
            throw new https_1.HttpsError('already-exists', `Migration already exists for userId=${userId}, storeId=${storeId}`);
        }
        // 現在のデジタルスタンプ数を取得
        const targetStoreSnap = await txn.get(targetStoreRef);
        const stampsBefore = asInt((_e = targetStoreSnap.data()) === null || _e === void 0 ? void 0 : _e['stamps'], 0);
        const stampsAfter = stampsBefore + physicalStamps;
        // 達成カード数を計算（10の倍数に到達した回数）
        let completedCards = 0;
        for (let s = stampsBefore + 1; s <= stampsAfter; s++) {
            if (s % MAX_STAMPS === 0)
                completedCards++;
        }
        const storeName = ((_g = (_f = storeSnap.data()) === null || _f === void 0 ? void 0 : _f.name) !== null && _g !== void 0 ? _g : '').toString();
        // users/{userId}/stores/{storeId} のスタンプを更新
        txn.set(targetStoreRef, {
            storeId,
            storeName: storeName || undefined,
            stamps: stampsAfter,
            updatedAt: firestore_2.FieldValue.serverTimestamp(),
        }, { merge: true });
        // stamp_migrations ドキュメントを作成（二重移行防止の記録）
        txn.set(migrationDocRef, {
            migrationId: migrationDocId,
            userId,
            storeId,
            staffUserId,
            stampsBefore,
            physicalStamps,
            stampsAfter,
            completedCards,
            createdAt: firestore_2.FieldValue.serverTimestamp(),
            note: '',
        });
        return { userId, storeId, storeName, stampsBefore, stampsAfter, completedCards };
    });
    console.log(`[migrateStampCard] 完了: userId=${userId}, storeId=${storeId}, ` +
        `stampsBefore=${result.stampsBefore}, stampsAfter=${result.stampsAfter}, completedCards=${result.completedCards}`);
    // トランザクション外: スタンプカード達成時のクーポン自動付与（punchStamp と同じロジック）
    if (result.completedCards > 0) {
        try {
            const stampCoupons = await db
                .collection('coupons')
                .doc(storeId)
                .collection('coupons')
                .where('requiredStampCount', '>', 0)
                .where('isActive', '==', true)
                .get();
            for (let card = 0; card < result.completedCards; card++) {
                for (const couponDoc of stampCoupons.docs) {
                    const couponData = couponDoc.data();
                    const noUsageLimit = couponData['noUsageLimit'] === true;
                    const usageLimit = asInt(couponData['usageLimit'], 0);
                    const usedCount = asInt(couponData['usedCount'], 0);
                    if (!noUsageLimit && usageLimit > 0 && usedCount >= usageLimit)
                        continue;
                    const userCouponRef = db.collection('user_coupons').doc();
                    await userCouponRef.set({
                        userId,
                        couponId: couponDoc.id,
                        storeId,
                        storeName: (_a = couponData['storeName']) !== null && _a !== void 0 ? _a : '',
                        title: (_b = couponData['title']) !== null && _b !== void 0 ? _b : '',
                        obtainedAt: firestore_2.FieldValue.serverTimestamp(),
                        isUsed: false,
                        noExpiry: true,
                        validUntil: null,
                        type: 'stamp_reward',
                        discountValue: (_c = couponData['discountValue']) !== null && _c !== void 0 ? _c : 0,
                        discountType: (_d = couponData['discountType']) !== null && _d !== void 0 ? _d : 'fixed_amount',
                        couponType: (_e = couponData['couponType']) !== null && _e !== void 0 ? _e : 'discount',
                        requiredStampCount: 0,
                    });
                }
            }
            console.log(`[migrateStampCard] Awarded stamp coupons: userId=${userId}, storeId=${storeId}, cards=${result.completedCards}`);
        }
        catch (e) {
            // クーポン付与失敗は致命的エラーとしない（スタンプ加算は完了済み）
            console.error('[migrateStampCard] stamp coupon award error:', e);
        }
    }
    return {
        success: true,
        userId: result.userId,
        storeId: result.storeId,
        storeName: result.storeName,
        stampsBefore: result.stampsBefore,
        stampsAfter: result.stampsAfter,
        completedCards: result.completedCards,
    };
});
// ─── コイン交換クーポン有効期限通知（毎日10:00 JST） ───
exports.notifyCouponExpiryScheduled = (0, scheduler_1.onSchedule)({
    region: 'asia-northeast1',
    schedule: 'every day 10:00',
    timeZone: 'Asia/Tokyo',
}, async () => {
    var _a, _b, _c, _d, _e, _f;
    const now = new Date();
    const BATCH_SIZE = 400;
    let notified7d = 0;
    let notified3d = 0;
    // 7日後の日付範囲（0:00〜23:59:59）
    const sevenDaysLater = new Date(now);
    sevenDaysLater.setDate(sevenDaysLater.getDate() + 7);
    const sevenDaysStart = new Date(sevenDaysLater);
    sevenDaysStart.setHours(0, 0, 0, 0);
    const sevenDaysEnd = new Date(sevenDaysLater);
    sevenDaysEnd.setHours(23, 59, 59, 999);
    // 3日後の日付範囲（0:00〜23:59:59）
    const threeDaysLater = new Date(now);
    threeDaysLater.setDate(threeDaysLater.getDate() + 3);
    const threeDaysStart = new Date(threeDaysLater);
    threeDaysStart.setHours(0, 0, 0, 0);
    const threeDaysEnd = new Date(threeDaysLater);
    threeDaysEnd.setHours(23, 59, 59, 999);
    // --- 7日前通知 ---
    let lastDoc7d = null;
    while (true) {
        let query = db
            .collection('user_coupons')
            .where('type', '==', 'coin_exchange')
            .where('isUsed', '==', false)
            .where('validUntil', '>=', firestore_2.Timestamp.fromDate(sevenDaysStart))
            .where('validUntil', '<=', firestore_2.Timestamp.fromDate(sevenDaysEnd))
            .limit(BATCH_SIZE);
        if (lastDoc7d) {
            query = query.startAfter(lastDoc7d);
        }
        const snapshot = await query.get();
        if (snapshot.empty)
            break;
        for (const doc of snapshot.docs) {
            const data = doc.data();
            if (data['expiryNotified7d'] === true)
                continue;
            const userId = data['userId'];
            const storeName = (_a = data['storeName']) !== null && _a !== void 0 ? _a : '店舗';
            const title = (_b = data['title']) !== null && _b !== void 0 ? _b : '100円引きクーポン';
            await createUserNotification({
                userId,
                title: 'クーポンの有効期限が近づいています',
                body: `${storeName}の「${title}」の有効期限が残り7日です。お早めにご利用ください。`,
                type: 'system',
                tags: ['coupon_expiry'],
                data: {
                    userCouponId: doc.id,
                    storeId: (_c = data['storeId']) !== null && _c !== void 0 ? _c : '',
                    daysRemaining: 7,
                },
            });
            await doc.ref.update({ expiryNotified7d: true });
            notified7d++;
        }
        lastDoc7d = snapshot.docs[snapshot.docs.length - 1];
        if (snapshot.size < BATCH_SIZE)
            break;
    }
    // --- 3日前通知 ---
    let lastDoc3d = null;
    while (true) {
        let query = db
            .collection('user_coupons')
            .where('type', '==', 'coin_exchange')
            .where('isUsed', '==', false)
            .where('validUntil', '>=', firestore_2.Timestamp.fromDate(threeDaysStart))
            .where('validUntil', '<=', firestore_2.Timestamp.fromDate(threeDaysEnd))
            .limit(BATCH_SIZE);
        if (lastDoc3d) {
            query = query.startAfter(lastDoc3d);
        }
        const snapshot = await query.get();
        if (snapshot.empty)
            break;
        for (const doc of snapshot.docs) {
            const data = doc.data();
            if (data['expiryNotified3d'] === true)
                continue;
            const userId = data['userId'];
            const storeName = (_d = data['storeName']) !== null && _d !== void 0 ? _d : '店舗';
            const title = (_e = data['title']) !== null && _e !== void 0 ? _e : '100円引きクーポン';
            await createUserNotification({
                userId,
                title: 'クーポンの有効期限が迫っています',
                body: `${storeName}の「${title}」の有効期限が残り3日です。お早めにご利用ください！`,
                type: 'system',
                tags: ['coupon_expiry'],
                data: {
                    userCouponId: doc.id,
                    storeId: (_f = data['storeId']) !== null && _f !== void 0 ? _f : '',
                    daysRemaining: 3,
                },
            });
            await doc.ref.update({ expiryNotified3d: true });
            notified3d++;
        }
        lastDoc3d = snapshot.docs[snapshot.docs.length - 1];
        if (snapshot.size < BATCH_SIZE)
            break;
    }
    console.log(`[notifyCouponExpiryScheduled] notified7d=${notified7d}, notified3d=${notified3d}`);
});
//# sourceMappingURL=index.js.map