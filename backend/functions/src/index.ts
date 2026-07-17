import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onDocumentCreated, onDocumentUpdated, onDocumentWritten } from 'firebase-functions/v2/firestore';
import { initializeApp } from 'firebase-admin/app';
import { FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import { getMessaging } from 'firebase-admin/messaging';
import { defineSecret } from 'firebase-functions/params';
import nodemailer from 'nodemailer';
import https from 'https';
import { createHash, randomInt, randomUUID } from 'crypto';
import { issueQRToken, verifyQRToken } from './utils/jwt';

// Firebase Admin SDK初期化
initializeApp();
const db = getFirestore();
db.settings({ ignoreUndefinedProperties: true });
const auth = getAuth();
const messaging = getMessaging();

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
const NFC_TAGS_COLLECTION = 'nfc_tags';
const CHECKIN_SESSIONS_COLLECTION = 'checkin_sessions';
const INSTAGRAM_API_BASE = 'https://graph.facebook.com/v19.0';
const DEFAULT_INSTAGRAM_SYNC_TIME = '09:00';
const MIN_INSTAGRAM_SYNC_MINUTES = 9 * 60;
const MAX_INSTAGRAM_SYNC_MINUTES = 21 * 60;

type BadgeAward = {
  id: string;
  name?: string;
  description?: string;
  category?: string;
  imageUrl?: string;
  iconUrl?: string;
  iconPath?: string;
  rarity?: string;
  order?: number;
  alreadyOwned?: boolean;
};

type InstagramMediaItem = {
  id: string;
  caption?: string;
  media_type?: string;
  media_url?: string;
  thumbnail_url?: string;
  permalink?: string;
  timestamp?: string;
  children?: {
    data?: InstagramMediaChild[];
  };
};

type InstagramMediaChild = {
  media_type?: string;
  media_url?: string;
  thumbnail_url?: string;
};

type InstagramAuth = {
  accessToken: string;
  instagramUserId: string;
  username?: string;
};

type InstagramSyncSettings = {
  enabled: boolean;
  syncTime: string;
  nextSyncAt: Date | null;
};

function stripUndefined<T extends Record<string, unknown>>(value: T): T {
  const entries = Object.entries(value).filter(([, v]) => v !== undefined);
  return Object.fromEntries(entries) as T;
}

/** JST日付文字列を取得（yyyy-MM-dd 形式）。process.env.TZ=Asia/Tokyo 設定前提 */
function getJstDateString(date?: Date): string {
  const d = date ?? new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

function toStringValue(value: unknown): string {
  if (typeof value === 'string') return value;
  if (value === null || value === undefined) return '';
  return String(value);
}

function parseInstagramUsername(value: unknown): string | null {
  const raw = toStringValue(value).trim();
  if (!raw) return null;
  const cleaned = raw.replace(/^@/, '');
  if (cleaned.includes('instagram.com/')) {
    try {
      const url = new URL(cleaned.startsWith('http') ? cleaned : `https://${cleaned}`);
      const parts = url.pathname.split('/').filter(Boolean);
      return parts[0] ?? null;
    } catch {
      return null;
    }
  }
  return cleaned;
}

function getInstagramAuth(storeData: Record<string, unknown>): InstagramAuth | null {
  const auth = storeData['instagramAuth'] as Record<string, unknown> | undefined;
  const accessToken = toStringValue(auth?.['accessToken'] ?? storeData['instagramAccessToken']).trim();
  const instagramUserId = toStringValue(auth?.['instagramUserId'] ?? storeData['instagramUserId']).trim();
  const socialMedia = storeData['socialMedia'] as Record<string, unknown> | undefined;
  const usernameFromSocial = parseInstagramUsername(socialMedia?.['instagram']);
  const username = toStringValue(auth?.['username']).trim() || usernameFromSocial || undefined;

  if (!accessToken || !instagramUserId) {
    return null;
  }

  return { accessToken, instagramUserId, username };
}

function normalizeMediaType(value: string): string {
  if (value === 'CAROUSEL_ALBUM') return 'CAROUSEL';
  return value || 'IMAGE';
}

function parseInstagramTimestamp(value: string | undefined): Date {
  if (!value) return new Date();
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) return new Date();
  return parsed;
}

function extractInstagramImageUrls(item: InstagramMediaItem): string[] {
  const childItems = item.children?.data ?? [];
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

function httpsGetJson<T>(url: string): Promise<T> {
  return new Promise((resolve, reject) => {
    const req = https.get(url, (res) => {
      let body = '';
      res.on('data', (chunk) => {
        body += chunk;
      });
      res.on('end', () => {
        const status = res.statusCode ?? 0;
        if (status >= 400) {
          reject(new Error(`Instagram API error ${status}: ${body}`));
          return;
        }
        try {
          resolve(JSON.parse(body) as T);
        } catch (error) {
          reject(error);
        }
      });
    });
    req.on('error', reject);
    req.end();
  });
}

function buildInstagramAuthUrl(): string {
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

async function exchangeInstagramCode(params: { code: string }): Promise<{ accessToken: string }> {
  const appId = INSTAGRAM_APP_ID.value();
  const appSecret = INSTAGRAM_APP_SECRET.value();
  const redirectUri = INSTAGRAM_REDIRECT_URI.value();
  const url = new URL(`${INSTAGRAM_API_BASE}/oauth/access_token`);
  url.searchParams.set('client_id', appId);
  url.searchParams.set('client_secret', appSecret);
  url.searchParams.set('redirect_uri', redirectUri);
  url.searchParams.set('code', params.code);
  const response = await httpsGetJson<{ access_token?: string }>(url.toString());
  const accessToken = toStringValue(response.access_token).trim();
  if (!accessToken) {
    throw new Error('アクセストークンの取得に失敗しました');
  }
  return { accessToken };
}

async function exchangeLongLivedToken(params: { accessToken: string }): Promise<string> {
  const appId = INSTAGRAM_APP_ID.value();
  const appSecret = INSTAGRAM_APP_SECRET.value();
  const url = new URL(`${INSTAGRAM_API_BASE}/oauth/access_token`);
  url.searchParams.set('grant_type', 'fb_exchange_token');
  url.searchParams.set('client_id', appId);
  url.searchParams.set('client_secret', appSecret);
  url.searchParams.set('fb_exchange_token', params.accessToken);
  const response = await httpsGetJson<{ access_token?: string }>(url.toString());
  const longToken = toStringValue(response.access_token).trim();
  if (!longToken) {
    throw new Error('長期アクセストークンの取得に失敗しました');
  }
  return longToken;
}

async function resolveInstagramUserId(accessToken: string): Promise<{ instagramUserId: string; username?: string }> {
  const pagesUrl = new URL(`${INSTAGRAM_API_BASE}/me/accounts`);
  pagesUrl.searchParams.set('access_token', accessToken);
  const pages = await httpsGetJson<{ data?: Array<{ id?: string }> }>(pagesUrl.toString());
  const pageId = pages.data?.[0]?.id;
  if (!pageId) {
    throw new Error('Facebookページが取得できません');
  }

  const igUrl = new URL(`${INSTAGRAM_API_BASE}/${pageId}`);
  igUrl.searchParams.set('fields', 'instagram_business_account');
  igUrl.searchParams.set('access_token', accessToken);
  const igResult = await httpsGetJson<{ instagram_business_account?: { id?: string } }>(igUrl.toString());
  const instagramUserId = toStringValue(igResult.instagram_business_account?.id).trim();
  if (!instagramUserId) {
    throw new Error('Instagramビジネスアカウントが取得できません');
  }

  const userUrl = new URL(`${INSTAGRAM_API_BASE}/${instagramUserId}`);
  userUrl.searchParams.set('fields', 'username');
  userUrl.searchParams.set('access_token', accessToken);
  const userInfo = await httpsGetJson<{ username?: string }>(userUrl.toString());

  return { instagramUserId, username: userInfo.username };
}

async function fetchInstagramMedia(params: {
  instagramUserId: string;
  accessToken: string;
  limit?: number;
}): Promise<InstagramMediaItem[]> {
  const { instagramUserId, accessToken, limit = 50 } = params;
  const url = new URL(`${INSTAGRAM_API_BASE}/${instagramUserId}/media`);
  url.searchParams.set(
    'fields',
    'id,caption,media_type,media_url,thumbnail_url,permalink,timestamp,children{media_type,media_url,thumbnail_url}',
  );
  url.searchParams.set('limit', String(limit));
  url.searchParams.set('access_token', accessToken);
  const response = await httpsGetJson<{ data?: InstagramMediaItem[] }>(url.toString());
  return response.data ?? [];
}

async function upsertInstagramPosts(params: {
  storeId: string;
  storeData: Record<string, unknown>;
  mediaItems: InstagramMediaItem[];
}): Promise<number> {
  const { storeId, storeData, mediaItems } = params;
  if (!mediaItems.length) return 0;

  const storeName = toStringValue(storeData['name']) || '店舗名なし';
  const storeIconImageUrl = toStringValue(storeData['storeIconImageUrl'] ?? storeData['iconImageUrl']);
  const category = toStringValue(storeData['category']) || undefined;

  const batch = db.batch();
  let count = 0;

  for (const item of mediaItems) {
    if (!item.id) continue;
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
      timestamp: Timestamp.fromDate(timestamp),
      isVideo,
      isActive: true,
      source: 'instagram',
      updatedAt: FieldValue.serverTimestamp(),
    });

    const storeDocRef = db.collection('stores').doc(storeId).collection('instagram_posts').doc(item.id);
    batch.set(
      storeDocRef,
      {
        ...baseData,
        createdAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    const publicDocRef = db.collection('public_instagram_posts').doc(item.id);
    batch.set(
      publicDocRef,
      {
        ...baseData,
        key: `${storeId}::${item.id}`,
        createdAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    count += 1;
  }

  await batch.commit();
  return count;
}

async function syncInstagramPostsForStore(params: {
  storeId: string;
  storeData: Record<string, unknown>;
}): Promise<number> {
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

  const updatePayload: Record<string, unknown> = {
    instagramSync: {
      lastSyncAt: FieldValue.serverTimestamp(),
      lastSyncCount: count,
    },
    'instagramSyncSettings.enabled': syncSettings.enabled,
    'instagramSyncSettings.syncTime': syncSettings.syncTime,
    'instagramSyncSettings.nextSyncAt': nextSyncDate
      ? Timestamp.fromDate(nextSyncDate)
      : FieldValue.delete(),
    'instagramSyncSettings.intervalMinutes': FieldValue.delete(),
  };

  await db.collection('stores').doc(storeId).set(updatePayload, { merge: true });

  return count;
}
function asInt(value: unknown, fallback = 0): number {
  if (typeof value === 'number') return Math.trunc(value);
  if (typeof value === 'string') {
    const parsed = Number.parseInt(value, 10);
    return Number.isNaN(parsed) ? fallback : parsed;
  }
  return fallback;
}

function parseInstagramSyncTime(value: string): { hour: number; minute: number } | null {
  const match = /^([01]\d|2[0-3]):(00|30)$/.exec(value);
  if (!match) return null;
  const hour = Number.parseInt(match[1], 10);
  const minute = Number.parseInt(match[2], 10);
  return { hour, minute };
}

function toInstagramSyncMinutes(value: { hour: number; minute: number }): number {
  return value.hour * 60 + value.minute;
}

function clampInstagramSyncMinutes(minutes: number): number {
  return Math.min(MAX_INSTAGRAM_SYNC_MINUTES, Math.max(MIN_INSTAGRAM_SYNC_MINUTES, minutes));
}

function formatInstagramSyncTime(params: { hour: number; minute: number }): string {
  const hour = params.hour.toString().padStart(2, '0');
  const minute = params.minute.toString().padStart(2, '0');
  return `${hour}:${minute}`;
}

function toInstagramSyncTimeFromDate(date: Date): string {
  const totalMinutes = date.getHours() * 60 + date.getMinutes();
  const rounded = Math.round(totalMinutes / 30) * 30;
  const normalized = clampInstagramSyncMinutes(
    ((rounded % (24 * 60)) + (24 * 60)) % (24 * 60),
  );
  const hour = Math.floor(normalized / 60);
  const minute = normalized % 60;
  return formatInstagramSyncTime({ hour, minute });
}

function normalizeInstagramSyncTime(value: unknown, fallbackDate?: Date | null): string {
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

function isInstagramSyncTimeAllowed(syncTime: string): boolean {
  const parsed = parseInstagramSyncTime(syncTime);
  if (!parsed) return false;
  const minutes = toInstagramSyncMinutes(parsed);
  return minutes >= MIN_INSTAGRAM_SYNC_MINUTES && minutes <= MAX_INSTAGRAM_SYNC_MINUTES;
}

function toDateValue(value: unknown): Date | null {
  if (!value) return null;
  if (value instanceof Timestamp) return value.toDate();
  if (value instanceof Date) return value;
  if (typeof value === 'string') {
    const parsed = new Date(value);
    if (!Number.isNaN(parsed.getTime())) {
      return parsed;
    }
  }
  if (typeof value === 'object' && value !== null && 'toDate' in value) {
    const toDate = (value as { toDate?: unknown }).toDate;
    if (typeof toDate === 'function') {
      const parsed = (toDate as () => Date)();
      if (parsed instanceof Date && !Number.isNaN(parsed.getTime())) {
        return parsed;
      }
    }
  }
  return null;
}

function getInstagramSyncSettings(storeData: Record<string, unknown>): InstagramSyncSettings {
  const settings = storeData['instagramSyncSettings'] as Record<string, unknown> | undefined;
  const enabled = settings?.['enabled'] === false ? false : true;
  const nextSyncAt = toDateValue(settings?.['nextSyncAt']);
  const syncInfo = storeData['instagramSync'] as Record<string, unknown> | undefined;
  const lastSyncAt = toDateValue(syncInfo?.['lastSyncAt']);
  const syncTime = normalizeInstagramSyncTime(settings?.['syncTime'], nextSyncAt ?? lastSyncAt);
  return {
    enabled,
    syncTime,
    nextSyncAt,
  };
}

function shouldRunInstagramSync(storeData: Record<string, unknown>, now: Date): boolean {
  const settings = getInstagramSyncSettings(storeData);
  if (!settings.enabled) {
    return false;
  }

  if (settings.nextSyncAt) {
    return settings.nextSyncAt.getTime() <= now.getTime();
  }

  const syncInfo = storeData['instagramSync'] as Record<string, unknown> | undefined;
  const lastSyncAt = toDateValue(syncInfo?.['lastSyncAt']);
  const todaySyncAt = buildTodayInstagramSyncDate(now, settings.syncTime);
  if (now.getTime() < todaySyncAt.getTime()) {
    return false;
  }

  if (!lastSyncAt) {
    return true;
  }
  return lastSyncAt.getTime() < todaySyncAt.getTime();
}

function buildTodayInstagramSyncDate(base: Date, syncTime: string): Date {
  const parsed = parseInstagramSyncTime(syncTime) ?? parseInstagramSyncTime(DEFAULT_INSTAGRAM_SYNC_TIME)!;
  return new Date(
    base.getFullYear(),
    base.getMonth(),
    base.getDate(),
    parsed.hour,
    parsed.minute,
    0,
    0,
  );
}

function buildNextInstagramSyncDate(base: Date, syncTime: string): Date {
  const todaySyncAt = buildTodayInstagramSyncDate(base, syncTime);
  if (todaySyncAt.getTime() <= base.getTime()) {
    todaySyncAt.setDate(todaySyncAt.getDate() + 1);
  }
  return todaySyncAt;
}

function startFromPeriod(period: string): Date {
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

function weekdayToStr(date: Date): string {
  const idx = (date.getDay() + 6) % 7;
  const map = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
  return map[idx] ?? 'monday';
}

const LEVEL_BASE_REQUIRED_EXPERIENCE = 20;
const LEVEL_REQUIRED_EXPERIENCE_INCREMENT = 10;
const LEVEL_MAX = 50;

function requiredExperienceForLevel(level: number): number {
  const safeLevel = Math.max(1, Math.min(LEVEL_MAX, level));
  return LEVEL_BASE_REQUIRED_EXPERIENCE + (safeLevel - 1) * LEVEL_REQUIRED_EXPERIENCE_INCREMENT;
}

function totalExperienceToReachLevel(level: number): number {
  const safeLevel = Math.max(1, Math.min(LEVEL_MAX, level));
  let total = 0;
  for (let i = 1; i < safeLevel; i += 1) {
    total += requiredExperienceForLevel(i);
  }
  return total;
}

function levelFromTotalExperience(totalExperience: number): number {
  if (totalExperience <= 0) return 1;
  let remaining = totalExperience;
  let level = 1;
  while (level < LEVEL_MAX) {
    const required = requiredExperienceForLevel(level);
    if (remaining < required) break;
    remaining -= required;
    level += 1;
  }
  return Math.max(1, Math.min(LEVEL_MAX, level));
}

function experienceForStampPunch(): number {
  return 10;
}

function experienceForStampCardComplete(): number {
  return 100;
}

async function countTransactions(params: {
  userId: string;
  since: Date;
  dayOfWeek?: string;
  storeId?: string;
}): Promise<number> {
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
      const data = doc.data() as Record<string, unknown>;
      const raw = data['createdAt'];
      let ts = new Date();
      if (raw instanceof Timestamp) {
        ts = raw.toDate();
      } else if (typeof raw === 'string') {
        const parsed = new Date(raw);
        if (!Number.isNaN(parsed.getTime())) ts = parsed;
      } else if (typeof raw === 'number') {
        ts = new Date(raw);
      }
      const inPeriod = ts.getTime() >= since.getTime();
      const weekdayOk = dayOfWeek ? weekdayToStr(ts) === dayOfWeek : true;
      if (inPeriod && weekdayOk) count += 1;
    }
  }
  return count;
}

async function getUserBadgeCount(userId: string): Promise<number> {
  const snap = await db.collection('user_badges').doc(userId).collection('badges').get();
  return snap.size;
}

async function getUserLevel(userId: string): Promise<number> {
  const doc = await db.collection('users').doc(userId).get();
  if (!doc.exists) return 1;
  return asInt((doc.data() as Record<string, unknown> | undefined)?.['level'], 1);
}

async function checkAndAwardBadges(params: {
  userId: string;
  storeId: string;
}): Promise<BadgeAward[]> {
  const { userId, storeId } = params;
  const firestore = db;
  const badgesSnap = await firestore.collection('badges').get();

  const badgeCount = await getUserBadgeCount(userId);
  const userLevel = await getUserLevel(userId);

  const newlyAwarded: BadgeAward[] = [];

  for (const doc of badgesSnap.docs) {
    const data = doc.data() as Record<string, unknown>;
    const isActive = (data['isActive'] as boolean | undefined) ?? true;
    if (!isActive) continue;

    const rawCond = data['condition'] ?? data['conditionData'] ?? data['jsonLogicCondition'];
    let condMap: Record<string, unknown> | null = null;
    if (typeof rawCond === 'string') {
      try {
        const parsed = JSON.parse(rawCond);
        if (parsed && typeof parsed === 'object') condMap = parsed as Record<string, unknown>;
      } catch (_) {}
    } else if (rawCond && typeof rawCond === 'object') {
      condMap = rawCond as Record<string, unknown>;
    }
    if (!condMap) continue;

    let isSatisfied = false;
    const mode = (condMap['mode'] ?? 'typed').toString();
    if (mode === 'typed') {
      const rule = (condMap['rule'] ?? {}) as Record<string, unknown>;
      const type = (rule['type'] ?? '').toString();
      const params = (rule['params'] ?? {}) as Record<string, unknown>;
      switch (type) {
        case 'first_checkin': {
          const c = await countTransactions({ userId, since: new Date(0) });
          isSatisfied = c >= 1;
          break;
        }
        case 'checkins_count': {
          const threshold = asInt(params['threshold']);
          const period = (params['period'] ?? 'month').toString();
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
          const period = (params['period'] ?? 'week').toString();
          const dow = (params['day_of_week'] ?? 'monday').toString();
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
          const period = (params['period'] ?? 'month').toString();
          const since = period === 'unlimited' ? new Date(0) : startFromPeriod(period);
          const c = await countTransactions({ userId, since });
          isSatisfied = c >= threshold;
          break;
        }
        case 'visit_frequency': {
          const threshold = asInt(params['threshold']);
          const period = (params['period'] ?? 'day').toString();
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
    } else {
      isSatisfied = false;
    }

    if (!isSatisfied) continue;

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
        unlockedAt: FieldValue.serverTimestamp(),
        isNew: true,
        name: data['name'],
        description: data['description'],
        category: data['category'],
        imageUrl: data['imageUrl'],
        iconUrl: data['iconUrl'],
        iconPath: data['iconPath'],
        rarity: data['rarity'],
        order: data['order'] ?? 0,
      });
      await userBadgeRef.set(badgeDoc);
    }

    const badgeAward = stripUndefined({
      id: badgeId,
      name: data['name'] as string | undefined,
      description: data['description'] as string | undefined,
      category: data['category'] as string | undefined,
      imageUrl: data['imageUrl'] as string | undefined,
      iconUrl: data['iconUrl'] as string | undefined,
      iconPath: data['iconPath'] as string | undefined,
      rarity: data['rarity'] as string | undefined,
      order: asInt(data['order'], 0),
      alreadyOwned,
    });
    newlyAwarded.push(badgeAward);
  }

  newlyAwarded.sort((a, b) => asInt(a.order) - asInt(b.order));
  return newlyAwarded;
}

type ReturnRateRange = {
  minLevel?: number;
  maxLevel?: number;
  rate?: number;
};

const SMTP_HOST = defineSecret('SMTP_HOST');
const SMTP_PORT = defineSecret('SMTP_PORT');
const SMTP_USER = defineSecret('SMTP_USER');
const SMTP_PASS = defineSecret('SMTP_PASS');
const SMTP_FROM = defineSecret('SMTP_FROM');
const SMTP_SECURE = defineSecret('SMTP_SECURE');
const INSTAGRAM_APP_ID = defineSecret('INSTAGRAM_APP_ID');
const INSTAGRAM_APP_SECRET = defineSecret('INSTAGRAM_APP_SECRET');
const INSTAGRAM_REDIRECT_URI = defineSecret('INSTAGRAM_REDIRECT_URI');

function getDateKey(date: Date): string {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Tokyo',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(date);
}

function normalizeReferralCode(code?: string): string {
  return (code ?? '').trim().toUpperCase();
}

/**
 * 生年月日から年代グループを算出
 */
function calculateAgeGroup(birthDate: Date | Timestamp): string | null {
  const bd = birthDate instanceof Timestamp ? birthDate.toDate() : birthDate;
  if (isNaN(bd.getTime())) return null;
  const now = new Date();
  let age = now.getFullYear() - bd.getFullYear();
  const monthDiff = now.getMonth() - bd.getMonth();
  if (monthDiff < 0 || (monthDiff === 0 && now.getDate() < bd.getDate())) {
    age--;
  }
  if (age < 20) return '~19';
  if (age < 30) return '20s';
  if (age < 40) return '30s';
  if (age < 50) return '40s';
  if (age < 60) return '50s';
  return '60+';
}

function toDate(value: unknown): Date | null {
  if (!value) return null;
  if (value instanceof Date) return value;
  if (value instanceof Timestamp) return value.toDate();
  if (typeof value === 'number') return new Date(value);
  if (typeof value === 'string') {
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
  }
  return null;
}

function parseRate(value: unknown, fallback = 0): number {
  if (typeof value === 'number') return value;
  if (typeof value === 'string') {
    const parsed = Number.parseFloat(value);
    return Number.isNaN(parsed) ? fallback : parsed;
  }
  return fallback;
}

function resolveLevelReturnRate(level: number, ranges: ReturnRateRange[] | undefined): number {
  if (!Array.isArray(ranges)) return 1.0;
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

function resolveCampaignBonus(settings: Record<string, unknown>): {
  bonusRate: number;
  campaignId?: string;
} {
  const bonusRate = parseRate(settings['campaignReturnRateBonus'], 0);
  const start = toDate(settings['campaignReturnRateStartDate']);
  const end = toDate(settings['campaignReturnRateEndDate']);
  if (!bonusRate || !start || !end) return { bonusRate: 0 };
  const now = new Date();
  if (now < start || now > end) return { bonusRate: 0 };
  const campaignId = typeof settings['campaignReturnRateId'] === 'string'
    ? settings['campaignReturnRateId']
    : undefined;
  return { bonusRate, campaignId };
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

type LiveChatRoomData = {
  roomId?: string;
  userId?: string;
  lastMessage?: string;
  lastMessageAt?: Timestamp | Date | string;
  lastSenderRole?: string;
  userUnreadCount?: number;
  ownerUnreadCount?: number;
  userLastReadAt?: Timestamp | Date | string;
  ownerLastReadAt?: Timestamp | Date | string;
};

type LiveChatMessageData = {
  messageId?: string;
  roomId?: string;
  userId?: string;
  senderId?: string;
  senderRole?: string;
  text?: string;
  createdAt?: Timestamp | Date | string;
};

type EmailOtpRecord = {
  codeHash?: string;
  expiresAt?: Timestamp;
  attempts?: number;
  lastSentAt?: Timestamp;
  targetEmail?: string;
  purpose?: string;
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

function resolveTimestamp(value: Timestamp | Date | string | undefined) {
  if (value instanceof Timestamp) return value;
  if (value instanceof Date) return Timestamp.fromDate(value);
  if (typeof value === 'string') {
    const parsed = new Date(value);
    if (!Number.isNaN(parsed.getTime())) {
      return Timestamp.fromDate(parsed);
    }
  }
  return null;
}

async function resolveUserName(userId: string): Promise<string> {
  const userDoc = await db.collection(USERS_COLLECTION).doc(userId).get();
  const data = userDoc.data() as { displayName?: string } | undefined;
  return data?.displayName ?? 'ユーザー';
}

async function createUserNotification({
  userId,
  title,
  body,
  data,
  type = 'system',
  tags = ['live_chat'],
}: {
  userId: string;
  title: string;
  body: string;
  data?: Record<string, unknown>;
  type?: string;
  tags?: string[];
}) {
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
    data: {
      source: 'user',
      ...stripUndefined(data ?? {}),
    },
    tags,
  });
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

export const processAwardAchievement = onDocumentCreated(
  {
    document: 'stores/{storeId}/transactions/{transactionId}',
    region: 'asia-northeast1',
  },
  async (event) => {
    const data = event.data?.data() as Record<string, unknown> | undefined;
    if (!data) return;

    const type = (data['type'] ?? '').toString();
    if (type !== 'award') return;

    const userId = (data['userId'] ?? '').toString();
    if (!userId) return;

    const storeId = event.params.storeId as string;
    const transactionId = event.params.transactionId as string;
    const storeName = (data['storeName'] ?? '').toString();
    const pointsAwarded = asInt(data['points'] ?? data['amount'], 0);
    if (pointsAwarded <= 0) return;

    const eventRef = db
      .collection(USER_ACHIEVEMENT_EVENTS_COLLECTION)
      .doc(userId)
      .collection('events')
      .doc(transactionId);
    const existingEvent = await eventRef.get();
    if (existingEvent.exists) return;

    const transactionRef = event.data?.ref;
    if (!transactionRef) return;

    const summary = await db.runTransaction(async (txn) => {
      const txnSnap = await txn.get(transactionRef);
      const txnData = txnSnap.data() as Record<string, unknown> | undefined;
      if (!txnData) return null;

      if (txnData['achievementProcessedAt']) {
        const existingSummary = txnData['achievementSummary'] as Record<string, unknown> | undefined;
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
      const currentStamps = asInt(userStoreSnap.data()?.['stamps'], 0);
      const stampsAdded = 1; // 上限なし・累積加算（punchStampと同じロジック）
      const nextStamps = currentStamps + 1;
      const cardCompleted = nextStamps % MAX_STAMPS === 0; // 10の倍数到達で達成

      txn.set(
        userStoreRef,
        {
          stamps: nextStamps,
          lastVisited: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      const pointsXp = pointsAwarded;
      const stampXp = stampsAdded > 0 ? experienceForStampPunch() : 0;
      const cardXp = cardCompleted ? experienceForStampCardComplete() : 0;
      const xpAdded = pointsXp + stampXp + cardXp;

      if (xpAdded > 0) {
        const currentExp = asInt(userSnap.data()?.['experience'], 0);
        const maxTotal =
          totalExperienceToReachLevel(LEVEL_MAX) + requiredExperienceForLevel(LEVEL_MAX);
        const newExp = Math.max(0, Math.min(maxTotal, currentExp + xpAdded));
        const newLevel = levelFromTotalExperience(newExp);
        txn.set(
          userRef,
          {
            experience: newExp,
            level: newLevel,
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
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
        achievementProcessedAt: FieldValue.serverTimestamp(),
        achievementSummary: summaryData,
      });

      return summaryData;
    });

    if (!summary) return;

    const badges = await checkAndAwardBadges({ userId, storeId });
    await eventRef.set(
      {
        type: 'point_award',
        transactionId,
        ...summary,
        badges,
        createdAt: FieldValue.serverTimestamp(),
        seenAt: null,
      },
      { merge: true },
    );
  },
);

export const processFriendReferral = onDocumentWritten(
  {
    document: `${USERS_COLLECTION}/{userId}`,
    region: 'asia-northeast1',
  },
  async (event) => {
    if (!event.data?.after.exists) return;

    const afterData = event.data.after.data() as Record<string, unknown>;
    const beforeData = event.data.before.exists
      ? (event.data.before.data() as Record<string, unknown>)
      : undefined;
    const userId = event.params.userId as string;
    const friendCode = normalizeReferralCode(
      typeof afterData.friendCode === 'string' ? afterData.friendCode : undefined,
    );

    if (!friendCode) return;
    if (afterData.referralUsed === true || afterData.referredBy) return;

    const beforeFriendCode = normalizeReferralCode(
      typeof beforeData?.friendCode === 'string' ? beforeData?.friendCode : undefined,
    );
    if (
      beforeFriendCode === friendCode &&
      (beforeData?.referralUsed ?? false) === (afterData.referralUsed ?? false)
    ) {
      return;
    }

    const referrerQuery = await db
      .collection(USERS_COLLECTION)
      .where('referralCode', '==', friendCode)
      .limit(1)
      .get();

    if (referrerQuery.empty) {
      await event.data.after.ref.update({
        friendCode: FieldValue.delete(),
        friendCodeStatus: 'invalid',
        friendCodeCheckedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    const referrerDoc = referrerQuery.docs[0];
    if (referrerDoc.id === userId) {
      await event.data.after.ref.update({
        friendCode: FieldValue.delete(),
        friendCodeStatus: 'self',
        friendCodeCheckedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    // コインシステムに移行: コインは初回スタンプ獲得時に付与（punchStamp で処理）
    // owner_settings/current からコイン数を動的に取得
    const ownerSettingsSnap = await db.collection('owner_settings').doc('current').get();
    const ownerSettingsData = ownerSettingsSnap.data() ?? {};
    const referralInviterCoins = typeof ownerSettingsData.friendCampaignInviterPoints === 'number'
      ? ownerSettingsData.friendCampaignInviterPoints : 5;
    const referralInviteeCoins = typeof ownerSettingsData.friendCampaignInviteePoints === 'number'
      ? ownerSettingsData.friendCampaignInviteePoints : 5;

    await db.runTransaction(async (transaction) => {
      const userRef = db.collection(USERS_COLLECTION).doc(userId);
      const referrerRef = db.collection(USERS_COLLECTION).doc(referrerDoc.id);
      const userSnap = await transaction.get(userRef);
      if (!userSnap.exists) return;

      const referrerSnap = await transaction.get(referrerRef);
      if (!referrerSnap.exists) return;

      const userData = userSnap.data() as Record<string, unknown>;
      if (userData.referralUsed === true || userData.referredBy) return;

      const currentFriendCode = normalizeReferralCode(
        typeof userData.friendCode === 'string' ? userData.friendCode : undefined,
      );
      if (!currentFriendCode || currentFriendCode !== friendCode) return;

      const referrerData = referrerSnap.data() as Record<string, unknown>;
      const referrerCode = normalizeReferralCode(
        typeof referrerData.referralCode === 'string' ? referrerData.referralCode : undefined,
      );
      if (referrerCode !== friendCode) return;

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
        createdAt: FieldValue.serverTimestamp(),
      });

      // refereeのユーザードキュメント更新（コインは初回スタンプ獲得時に付与）
      transaction.update(userRef, {
        referredBy: referrerRef.id,
        referralUsed: true,
        referralUsedAt: FieldValue.serverTimestamp(),
        referralCoinAwarded: false,
        friendCode: FieldValue.delete(),
        friendCodeStatus: 'applied',
        friendCodeCheckedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      // referrerのユーザードキュメント更新（紹介数カウントのみ。コインは初回スタンプ時に付与）
      transaction.update(referrerRef, {
        referralCount: FieldValue.increment(1),
        updatedAt: FieldValue.serverTimestamp(),
      });
    });

    // ウェルカムお知らせを被紹介者に送信
    const referrerDisplayName = typeof referrerDoc.data()?.displayName === 'string'
      ? ((referrerDoc.data()!.displayName as string).trim() || '友達')
      : '友達';
    await db.collection(USERS_COLLECTION).doc(userId).collection('notifications').add({
      type: 'social',
      tags: ['referral', 'welcome'],
      title: 'ようこそぐるまっぷへ！',
      body: `${referrerDisplayName}さんの紹介でアプリを始めました。\nお店のNFCタグにスマホをタッチすると、図鑑カードが解放されます。\nまずは近くのお店を探してみましょう！`,
      isRead: false,
      isDelivered: false,
      createdAt: FieldValue.serverTimestamp(),
    });
  },
);

export const sendUserNotificationOnCreate = onDocumentCreated(
  {
    document: `${USERS_COLLECTION}/{userId}/notifications/{notificationId}`,
    region: 'asia-northeast1',
  },
  async (event) => {
    if (!event.data?.exists) return;

    const notificationId = event.data.id;
    const userId = event.params.userId as string;
    const data = event.data.data() as NotificationData | undefined;
    if (!data) return;

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

    console.log(
      `Sent user notification ${notificationId} to user ${userId}: ` +
        `${response.successCount} success, ${response.failureCount} failure`
    );

    await event.data.ref.update({
      isDelivered: true,
      deliveredAt: new Date(),
    });
  },
);

export const sendLiveChatNotificationOnCreate = onDocumentCreated(
  {
    document: `${SERVICE_CHAT_ROOMS_COLLECTION}/{roomId}/messages/{messageId}`,
    region: 'asia-northeast1',
  },
  async (event) => {
    if (!event.data?.exists) return;

    const roomId = event.params.roomId as string;
    const messageId = event.params.messageId as string;
    const message = event.data.data() as LiveChatMessageData | undefined;
    if (!message) return;

    const roomRef = db.collection(SERVICE_CHAT_ROOMS_COLLECTION).doc(roomId);
    const roomSnap = await roomRef.get();
    const roomData = roomSnap.data() as LiveChatRoomData | undefined;

    const userId = (message.userId ?? roomData?.userId ?? '').toString();
    if (!userId) return;

    const senderRole = (message.senderRole ?? '').toString();
    const senderId = (message.senderId ?? '').toString();
    const messageText = (message.text ?? '').toString();
    const createdAt = resolveTimestamp(message.createdAt) ?? Timestamp.now();

    await db.runTransaction(async (transaction) => {
      const snap = await transaction.get(roomRef);
      const data = snap.data() as LiveChatRoomData | undefined;
      const ownerUnread = asInt(data?.ownerUnreadCount, 0);
      const userUnread = asInt(data?.userUnreadCount, 0);

      transaction.set(
        roomRef,
        stripUndefined({
          roomId,
          userId,
          lastMessage: messageText,
          lastMessageAt: createdAt,
          lastSenderRole: senderRole,
          ownerUnreadCount: senderRole === 'user' ? ownerUnread + 1 : ownerUnread,
          userUnreadCount: senderRole === 'owner' ? userUnread + 1 : userUnread,
          updatedAt: FieldValue.serverTimestamp(),
        }),
        { merge: true }
      );
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
  },
);

export const resetLiveChatUnreadOnRead = onDocumentUpdated(
  {
    document: `${SERVICE_CHAT_ROOMS_COLLECTION}/{roomId}`,
    region: 'asia-northeast1',
  },
  async (event) => {
    if (!event.data?.after.exists) return;

    const before = event.data.before.data() as LiveChatRoomData | undefined;
    const after = event.data.after.data() as LiveChatRoomData | undefined;
    if (!after) return;

    const userReadChanged =
      (before?.userLastReadAt ?? null) != (after.userLastReadAt ?? null);
    const ownerReadChanged =
      (before?.ownerLastReadAt ?? null) != (after.ownerLastReadAt ?? null);

    if (!userReadChanged && !ownerReadChanged) return;

    const updates: Record<string, unknown> = {};
    if (userReadChanged && asInt(after.userUnreadCount, 0) > 0) {
      updates.userUnreadCount = 0;
    }
    if (ownerReadChanged && asInt(after.ownerUnreadCount, 0) > 0) {
      updates.ownerUnreadCount = 0;
    }
    if (Object.keys(updates).length == 0) return;

    updates.updatedAt = FieldValue.serverTimestamp();
    await event.data.after.ref.update(updates);
  },
);

export const notifyPendingStoreRequest = onDocumentCreated(
  {
    document: 'stores/{storeId}',
    region: 'asia-northeast1',
  },
  async (event) => {
    if (!event.data?.exists) return;

    const storeId = event.params.storeId as string;
    const data = event.data.data() as Record<string, unknown> | undefined;
    if (!data) return;

    const isApproved = data['isApproved'] === true;
    const approvalStatus = (data['approvalStatus'] ?? 'pending').toString();
    const alreadyNotified = Boolean(data['pendingRequestNotifiedAt']);
    if (isApproved || approvalStatus != 'pending' || alreadyNotified) {
      return;
    }

    const storeName = (data['name'] ?? '店舗名未設定').toString();
    const createdBy = (data['createdBy'] ?? '').toString();

    const ownersSnapshot = await db
      .collection(USERS_COLLECTION)
      .where('isOwner', '==', true)
      .where('isStoreOwner', '==', true)
      .get();

    if (ownersSnapshot.empty) {
      await event.data.ref.update({
        pendingRequestNotifiedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    const notificationId = `store_request_${storeId}`;
    const now = FieldValue.serverTimestamp();

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
      pendingRequestNotifiedAt: FieldValue.serverTimestamp(),
    });
  },
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
        subject: '【ぐるまっぷ】メール認証コードのお知らせ',
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

export const requestEmailChangeOtp = onCall(
  {
    region: 'asia-northeast1',
    secrets: [SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, SMTP_FROM, SMTP_SECURE],
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError('unauthenticated', 'ログインが必要です');
    }

    const uid = request.auth.uid;
    const newEmail = String(request.data?.newEmail ?? '').trim().toLowerCase();

    if (!newEmail || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(newEmail)) {
      throw new HttpsError('invalid-argument', '有効なメールアドレスを入力してください');
    }

    const userRecord = await auth.getUser(uid);
    const currentEmail = userRecord.email;

    if (currentEmail && currentEmail.toLowerCase() === newEmail) {
      throw new HttpsError('invalid-argument', '現在のメールアドレスと同じです');
    }

    try {
      await auth.getUserByEmail(newEmail);
      throw new HttpsError('already-exists', 'このメールアドレスは既に使用されています');
    } catch (e: unknown) {
      if (e instanceof HttpsError) throw e;
      const firebaseError = e as { code?: string };
      if (firebaseError.code !== 'auth/user-not-found') {
        throw new HttpsError('internal', 'メールアドレスの確認に失敗しました');
      }
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
        targetEmail: newEmail,
        purpose: 'emailChange',
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
        to: newEmail,
        subject: '【ぐるまっぷ】メールアドレス変更 認証コードのお知らせ',
        text: buildOtpEmailText(code),
      });
    } catch (error) {
      await otpRef.delete();
      console.error('Failed to send email change OTP:', error);
      throw new HttpsError('internal', '認証コードの送信に失敗しました');
    }

    return { success: true };
  }
);

export const verifyEmailChangeOtp = onCall(
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

    if (data.purpose !== 'emailChange' || !data.targetEmail) {
      throw new HttpsError('failed-precondition', 'メールアドレス変更用の認証コードではありません');
    }

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

    const targetEmail = data.targetEmail;

    try {
      await auth.getUserByEmail(targetEmail);
      await otpRef.delete();
      throw new HttpsError('already-exists', 'このメールアドレスは既に使用されています');
    } catch (e: unknown) {
      if (e instanceof HttpsError) throw e;
      const firebaseError = e as { code?: string };
      if (firebaseError.code !== 'auth/user-not-found') {
        throw new HttpsError('internal', 'メールアドレスの確認に失敗しました');
      }
    }

    await auth.updateUser(uid, { email: targetEmail });

    await Promise.all([
      otpRef.delete(),
      db.collection(USERS_COLLECTION).doc(uid).set(
        {
          email: targetEmail,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      ),
    ]);

    return { verified: true, email: targetEmail };
  }
);

export const calculatePointRequestRates = onDocumentWritten(
  {
    document: 'point_requests/{storeId}/{userId}/award_request',
    region: 'asia-northeast1',
  },
  async (event) => {
    if (!event.data?.after.exists) return;
    const data = event.data.after.data() as Record<string, unknown>;
    if (!data) return;
    if (data['rateCalculatedAt']) return;
    if ((data['requestType'] ?? 'award') !== 'award') return;

    const amount = asInt(data['amount'], 0);
    if (amount <= 0) return;

    const userId = event.params.userId as string;
    const settingsDoc = await db.collection(OWNER_SETTINGS_COLLECTION).doc('current').get();
    const settings = (settingsDoc.data() as Record<string, unknown> | undefined) ?? {};

    const userDoc = await db.collection(USERS_COLLECTION).doc(userId).get();
    const userLevel = asInt(userDoc.data()?.['level'], 1);

    const levelRate = resolveLevelReturnRate(
      userLevel,
      settings['levelPointReturnRateRanges'] as ReturnRateRange[] | undefined,
    );
    const { bonusRate, campaignId } = resolveCampaignBonus(settings);
    const appliedRate = levelRate + bonusRate;
    const baseRate = 1.0;

    const normalPoints = Math.floor(amount * Math.min(appliedRate, baseRate) / 100);
    const specialPoints = Math.floor(amount * Math.max(appliedRate - baseRate, 0) / 100);
    const totalPoints = normalPoints + specialPoints;

    let rateSource = 'base';
    if (bonusRate > 0 && levelRate !== baseRate) rateSource = 'level+campaign';
    else if (bonusRate > 0) rateSource = 'campaign';
    else if (levelRate !== baseRate) rateSource = 'level';

    await event.data.after.ref.update(
      stripUndefined({
        baseRate,
        appliedRate,
        normalPoints,
        specialPoints,
        totalPoints,
        pointsToAward: totalPoints,
        userPoints: totalPoints,
        rateCalculatedAt: FieldValue.serverTimestamp(),
        rateSource,
        campaignId,
      }),
    );
  },
);

export const recordRecommendationVisitOnPointAward = onDocumentWritten(
  {
    document: 'point_requests/{storeId}/{userId}/award_request',
    region: 'asia-northeast1',
  },
  async (event) => {
    try {
      console.log('recordRecommendationVisitOnPointAward:start', {
        storeId: event.params.storeId,
        userId: event.params.userId,
        hasBefore: !!event.data?.before?.exists,
        hasAfter: !!event.data?.after?.exists,
      });
      if (!event.data?.after.exists) return;

      const after = (event.data.after.data() ?? {}) as Record<string, unknown>;
      const status = String(after['status'] ?? '');
      console.log('recordRecommendationVisitOnPointAward:after-status', { status });
      if (status !== 'accepted') return;

      const beforeStatus = event.data.before?.exists
        ? String((event.data.before.data() ?? {})['status'] ?? '')
        : '';
      console.log('recordRecommendationVisitOnPointAward:before-status', { beforeStatus });
      if (beforeStatus === 'accepted') return;

      const storeId = event.params.storeId as string;
      const userId = event.params.userId as string;
      const since = Timestamp.fromMillis(Date.now() - 30 * 24 * 60 * 60 * 1000);

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
      if (impressionSnap.empty) return;

      const impressionDoc = impressionSnap.docs[0];
      const impressionData = (impressionDoc.data() ?? {}) as Record<string, unknown>;
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
      if (!existing.empty) return;

      const sourceStoreId =
        typeof impressionData['sourceStoreId'] === 'string' ? (impressionData['sourceStoreId'] as string) : '';
      const triggerType =
        typeof impressionData['triggerType'] === 'string' ? (impressionData['triggerType'] as string) : 'point_award';

      await db.collection(RECOMMENDATION_VISITS_COLLECTION).add(
        stripUndefined({
          userId,
          sourceStoreId,
          targetStoreId: storeId,
          triggerType,
          impressionId,
          visitAt: FieldValue.serverTimestamp(),
          firstPointAwardAt: FieldValue.serverTimestamp(),
          withinHours: 720,
        }),
      );
      console.log('recordRecommendationVisitOnPointAward:visit-created', {
        impressionId,
        targetStoreId: storeId,
        userId,
      });
    } catch (error) {
      console.error('recordRecommendationVisitOnPointAward failed', error);
    }
  },
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

    const type = typeof data['type'] === 'string' ? (data['type'] as string) : '';

    // stamp タイプは punchStamp が直接 store_stats/store_users を更新済みのためスキップ
    if (type === 'stamp') return;

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
    if (type === 'award' || type === 'use') {
      updates['visitorCount'] = FieldValue.increment(1);
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

// スタンプ押印（店舗側アプリ用）
export const punchStamp = onCall(
  {
    region: 'asia-northeast1',
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Store must be authenticated');
    }

    const { userId, storeId, selectedCouponIds: rawSelectedCouponIds } = request.data || {};
    if (!userId || !storeId) {
      throw new HttpsError('invalid-argument', 'Missing required parameters: userId and storeId');
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
      const [storeUserSnap, storeSnap] = await Promise.all([
        txn.get(storeUserRef),
        txn.get(storeRef),
      ]);

      if (!storeUserSnap.exists) {
        throw new HttpsError('permission-denied', 'Store user not found');
      }
      if (!storeSnap.exists) {
        throw new HttpsError('not-found', 'Store not found');
      }

      const storeUserData = storeUserSnap.data() as Record<string, unknown>;
      const currentStoreId = (storeUserData['currentStoreId'] ?? '').toString();
      const createdStores = (storeUserData['createdStores'] as string[]) ?? [];
      const isOwner = storeUserData['isOwner'] === true || storeUserData['isStoreOwner'] === true;
      const storeCreatedBy = (storeSnap.data()?.createdBy ?? '').toString();

      const isMember =
        currentStoreId === storeId || createdStores.includes(storeId) || storeCreatedBy === storeUserId;

      if (!isOwner && !isMember) {
        throw new HttpsError('permission-denied', 'Not authorized for this store');
      }

      const storeName = (storeSnap.data()?.name ?? '').toString();

      const targetStoreSnap = await txn.get(targetStoreRef);
      const storeUserStatsSnap = await txn.get(storeUserStatsRef);

      // 1日1回制限チェック
      const todayJst = getJstDateString();
      const lastStampDate = targetStoreSnap.data()?.['lastStampDate'];
      if (typeof lastStampDate === 'string' && lastStampDate === todayJst) {
        throw new HttpsError('already-exists', 'Already stamped today for this store');
      }

      const currentStamps = asInt(targetStoreSnap.data()?.['stamps'], 0);
      let stampsAfter = 0;
      let cardCompleted = false;

      if (currentStamps >= 1) {
        // 救済措置: 既存スタンプ保有者はスタンプを +1 加算
        const nextStamps = currentStamps + 1;
        cardCompleted = nextStamps % MAX_STAMPS === 0;
        stampsAfter = nextStamps;
      }
      // currentStamps == 0 の場合は来店記録のみ（stampsAfter = 0 のまま）

      const couponReads: Array<{
        couponId: string;
        couponRef: FirebaseFirestore.DocumentReference;
        publicCouponRef: FirebaseFirestore.DocumentReference;
        usedByRef: FirebaseFirestore.DocumentReference;
        userUsedRef: FirebaseFirestore.DocumentReference;
        couponSnap: FirebaseFirestore.DocumentSnapshot;
        usedBySnap: FirebaseFirestore.DocumentSnapshot;
        userUsedSnap: FirebaseFirestore.DocumentSnapshot;
        publicSnap: FirebaseFirestore.DocumentSnapshot;
      }> = [];

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

      // スタンプ加算（救済措置対象ユーザーのみ）+ 1日1回制限用の日付記録
      if (currentStamps >= 1) {
        txn.set(
          targetStoreRef,
          stripUndefined({
            storeId,
            storeName: storeName || undefined,
            stamps: stampsAfter,
            lastStampDate: todayJst,
            lastVisited: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          }),
          { merge: true },
        );
      } else {
        // 新規ユーザー（stamps=0）: 来店記録のみ
        txn.set(
          targetStoreRef,
          stripUndefined({
            storeId,
            storeName: storeName || undefined,
            lastStampDate: todayJst,
            lastVisited: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          }),
          { merge: true },
        );
      }

      const todayStr = todayJst;
      const statsRef = db.collection('store_stats').doc(storeId).collection('daily').doc(todayStr);
      txn.set(
        statsRef,
        {
          date: todayStr,
          visitorCount: FieldValue.increment(1),
          lastUpdated: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      if (storeUserStatsSnap.exists) {
        txn.set(
          storeUserStatsRef,
          {
            lastVisitAt: FieldValue.serverTimestamp(),
            totalVisits: FieldValue.increment(1),
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      } else {
        txn.set(storeUserStatsRef, {
          userId,
          storeId,
          firstVisitAt: FieldValue.serverTimestamp(),
          lastVisitAt: FieldValue.serverTimestamp(),
          totalVisits: 1,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
      }

      if (couponReads.length > 0) {
        const now = new Date();
        for (const entry of couponReads) {
          const { couponId, couponRef, publicCouponRef, usedByRef, userUsedRef, couponSnap, usedBySnap, userUsedSnap, publicSnap } =
            entry;

          if (!couponSnap.exists) {
            throw new HttpsError('not-found', `Coupon not found: ${couponId}`);
          }
          const couponData = couponSnap.data() ?? {};
          const isActive = couponData['isActive'] !== false;
          const usageLimit = asInt(couponData['usageLimit'], 0);
          const usedCount = asInt(couponData['usedCount'], 0);
          const noExpiry = couponData['noExpiry'] === true;
          const noUsageLimit = couponData['noUsageLimit'] === true;
          const validUntilValue = couponData['validUntil'];
          const validUntil =
            validUntilValue instanceof Timestamp ? validUntilValue.toDate() : undefined;
          const isNoExpiry = noExpiry || (validUntil && validUntil.getFullYear() >= 2100);

          if (!isActive) {
            throw new HttpsError('failed-precondition', `Coupon inactive: ${couponId}`);
          }
          if (!isNoExpiry && (!validUntil || validUntil.getTime() <= now.getTime())) {
            throw new HttpsError('failed-precondition', `Coupon expired: ${couponId}`);
          }
          if (!noUsageLimit && usageLimit <= 0) {
            throw new HttpsError('failed-precondition', `Coupon usage limit invalid: ${couponId}`);
          }
          if (!noUsageLimit && usedCount >= usageLimit) {
            throw new HttpsError('failed-precondition', `Coupon usage limit reached: ${couponId}`);
          }
          if (usedBySnap.exists) {
            throw new HttpsError('already-exists', `Coupon already used: ${couponId}`);
          }
          if (userUsedSnap.exists) {
            throw new HttpsError('already-exists', `Coupon already used: ${couponId}`);
          }

          txn.set(usedByRef, {
            userId,
            usedAt: FieldValue.serverTimestamp(),
            couponId,
            storeId,
          });
          txn.set(userUsedRef, {
            userId,
            usedAt: FieldValue.serverTimestamp(),
            couponId,
            storeId,
          });

          const nextUsedCount = usedCount + 1;
          const shouldDeactivate = !noUsageLimit && usageLimit > 0 && nextUsedCount === usageLimit;
          txn.update(couponRef, {
            usedCount: nextUsedCount,
            ...(shouldDeactivate ? { isActive: false } : {}),
            updatedAt: FieldValue.serverTimestamp(),
          });

          if (publicSnap.exists) {
            txn.update(publicCouponRef, {
              usedCount: nextUsedCount,
              ...(shouldDeactivate ? { isActive: false } : {}),
              updatedAt: FieldValue.serverTimestamp(),
            });
          }
        }
      }

      return {
        userId,
        storeId,
        storeName,
        stampsAdded: currentStamps >= 1 ? 1 : 0,
        stampsAfter,
        cardCompleted,
      };
    });

    const requestRef = db
      .collection('point_requests')
      .doc(storeId)
      .collection(userId)
      .doc('award_request');
    await requestRef.set(
      {
        status: 'accepted',
        requestType: 'stamp',
        pointsToAward: 0,
        userPoints: 0,
        amount: 0,
        usedPoints: 0,
        selectedCouponIds: selectedCouponIds.length > 0 ? selectedCouponIds : FieldValue.delete(),
        storeId,
        storeName: result.storeName ?? '',
        userId,
        respondedBy: storeUserId,
        createdAt: FieldValue.serverTimestamp(),
        respondedAt: FieldValue.serverTimestamp(),
        userNotified: false,
        userNotifiedAt: FieldValue.delete(),
      },
      { merge: true },
    );

    // stores/{storeId}/transactions にスタンプ来店記録を作成
    // フィルター時のクエリ対象となるため、userGender/userAgeGroup を含める
    let userGender: string | null = null;
    let userAgeGroup: string | null = null;
    let userPrefecture: string | null = null;
    let userCity: string | null = null;
    try {
      const targetUserSnap = await db.collection(USERS_COLLECTION).doc(userId).get();
      if (targetUserSnap.exists) {
        const userData = targetUserSnap.data();
        userGender = (typeof userData?.gender === 'string' ? userData.gender : null);
        userPrefecture = (typeof userData?.prefecture === 'string' ? userData.prefecture : null);
        userCity = (typeof userData?.city === 'string' ? userData.city : null);
        const birthDateVal = userData?.birthDate;
        if (birthDateVal) {
          const bd = birthDateVal instanceof Timestamp
            ? birthDateVal
            : (birthDateVal instanceof Date ? Timestamp.fromDate(birthDateVal) : null);
          if (bd) {
            userAgeGroup = calculateAgeGroup(bd);
          }
        }
      }
    } catch (e) {
      console.error('[punchStamp] ユーザー属性取得エラー（続行）:', e);
    }

    const stampTxnRef = db.collection('stores').doc(storeId).collection('transactions').doc();
    await stampTxnRef.set({
      transactionId: stampTxnRef.id,
      storeId,
      storeName: result.storeName ?? '',
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
      createdAt: FieldValue.serverTimestamp(),
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
      await eventRef.set(
        {
          type: 'punch_checkin',
          transactionId: stampTxnRef.id,
          storeId,
          storeName: result.storeName ?? '',
          pointsAwarded: 0,
          badges,
          createdAt: FieldValue.serverTimestamp(),
          seenAt: null,
        },
        { merge: true },
      );
    } catch (e) {
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
        const storeData = storeDoc.data() as Record<string, unknown> | undefined;
        const userDoc = await db.collection(USERS_COLLECTION).doc(userId).get();
        const userData = userDoc.data() as Record<string, unknown> | undefined;

        const followBatch = db.batch();
        followBatch.set(followDocRef, {
          storeId,
          storeName: result.storeName ?? '',
          category: storeData?.category ?? '',
          storeImageUrl: storeData?.storeImageUrl ?? null,
          followedAt: FieldValue.serverTimestamp(),
          source: 'punch_checkin',
        });
        followBatch.set(
          db.collection('stores').doc(storeId).collection('followers').doc(userId),
          {
            userId,
            userName: userData?.displayName ?? 'ユーザー',
            followedAt: FieldValue.serverTimestamp(),
          },
        );
        followBatch.update(db.collection(USERS_COLLECTION).doc(userId), {
          followedStoreIds: FieldValue.arrayUnion(storeId),
          updatedAt: FieldValue.serverTimestamp(),
        });
        await followBatch.commit();
        console.log(`[punchStamp] Auto-followed store ${storeId} for user ${userId}`);
      }
    } catch (e) {
      console.error('[punchStamp] auto-follow error:', e);
    }

    // スタンプ達成クーポン自動付与を削除（廃止）

    // 友達紹介コイン付与（初回スタンプ時）
    let referralCoinJustAwarded = false;
    let referralReferredByUid: string | null = null;
    let referralAwardedInviteeCoins = 5;
    let referralAwardedInviterCoins = 5;
    let pendingReferralDocRef: FirebaseFirestore.DocumentReference | null = null;
    try {
      // referral_uses から plannedCoins を取得（トランザクション前に実行）
      const pendingReferralSnap = await db.collection(REFERRAL_USES_COLLECTION)
        .where('referredUserId', '==', userId)
        .where('status', '==', 'pending')
        .limit(1)
        .get();
      if (!pendingReferralSnap.empty) {
        pendingReferralDocRef = pendingReferralSnap.docs[0].ref;
        const plannedCoins = pendingReferralSnap.docs[0].data()?.plannedCoins;
        if (typeof plannedCoins?.invitee === 'number') {
          referralAwardedInviteeCoins = plannedCoins.invitee;
        }
        if (typeof plannedCoins?.inviter === 'number') {
          referralAwardedInviterCoins = plannedCoins.inviter;
        }
      }

      await db.runTransaction(async (refTxn) => {
        const refUserSnap = await refTxn.get(targetUserRef);
        if (!refUserSnap.exists) return;
        const refUserData = refUserSnap.data() as Record<string, unknown>;
        const referredBy = typeof refUserData.referredBy === 'string' ? refUserData.referredBy : null;
        const alreadyAwarded = refUserData.referralCoinAwarded === true;
        if (!referredBy || alreadyAwarded) return;

        const referrerRef = db.collection(USERS_COLLECTION).doc(referredBy);
        const referrerSnap = await refTxn.get(referrerRef);
        if (!referrerSnap.exists) return;

        const refNow = new Date();
        const refExpiresAt = new Date(refNow.getTime() + 180 * 24 * 60 * 60 * 1000);

        refTxn.update(targetUserRef, {
          coins: FieldValue.increment(referralAwardedInviteeCoins),
          coinLastEarnedAt: Timestamp.fromDate(refNow),
          coinExpiresAt: Timestamp.fromDate(refExpiresAt),
          referralCoinAwarded: true,
          updatedAt: FieldValue.serverTimestamp(),
        });
        refTxn.update(referrerRef, {
          coins: FieldValue.increment(referralAwardedInviterCoins),
          coinLastEarnedAt: Timestamp.fromDate(refNow),
          coinExpiresAt: Timestamp.fromDate(refExpiresAt),
          referralEarningsPoints: FieldValue.increment(referralAwardedInviterCoins),
          updatedAt: FieldValue.serverTimestamp(),
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
            awardedAt: FieldValue.serverTimestamp(),
          });
        }

        // 両者への通知
        const [refereeUserDoc, referrerUserDoc] = await Promise.all([
          db.collection(USERS_COLLECTION).doc(userId).get(),
          db.collection(USERS_COLLECTION).doc(referralReferredByUid).get(),
        ]);
        const refereeName = typeof refereeUserDoc.data()?.displayName === 'string'
          ? ((refereeUserDoc.data()!.displayName as string).trim() || '友達')
          : '友達';
        const referrerName = typeof referrerUserDoc.data()?.displayName === 'string'
          ? ((referrerUserDoc.data()!.displayName as string).trim() || '友達')
          : '友達';

        const refereeNotifRef = targetUserRef.collection('notifications').doc();
        await refereeNotifRef.set({
          id: refereeNotifRef.id,
          userId,
          title: 'ようこそぐるまっぷへ！',
          body: `${referrerName}さんの紹介でアプリを始めました。NFCタグにタッチして新しいお店を発見してみましょう！`,
          type: 'social',
          createdAt: refNow.toISOString(),
          isRead: false,
          isDelivered: true,
          data: {
            source: 'user',
            reason: 'friend_referral',
          },
          tags: ['referral'],
        });

        const referrerNotifRef = db.collection(USERS_COLLECTION).doc(referralReferredByUid).collection('notifications').doc();
        await referrerNotifRef.set({
          id: referrerNotifRef.id,
          userId: referralReferredByUid,
          title: 'お友達が登録しました！',
          body: `${refereeName}さんがぐるまっぷに参加しました。一緒に街を探検しましょう！`,
          type: 'social',
          createdAt: refNow.toISOString(),
          isRead: false,
          isDelivered: true,
          data: {
            source: 'user',
            reason: 'friend_referral',
          },
          tags: ['referral'],
        });

        console.log(`[punchStamp] Referral notification sent: referee=${userId}, referrer=${referralReferredByUid}`);
      }
    } catch (e) {
      console.error('[punchStamp] referral coin award error:', e);
    }

    return result;
  },
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

    console.log(`Check-in recorded for user ${userId} at store ${storeId}`);
  } catch (error) {
    console.error('Error recording check-in:', error);
    throw error;
  }
}

export const startInstagramAuth = onCall(
  {
    region: 'asia-northeast1',
    invoker: 'public',
    secrets: [INSTAGRAM_APP_ID, INSTAGRAM_APP_SECRET, INSTAGRAM_REDIRECT_URI],
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError('unauthenticated', 'ログインが必要です');
    }

    const storeId = toStringValue(request.data?.storeId).trim();
    if (!storeId) {
      throw new HttpsError('invalid-argument', 'storeId が必要です');
    }

    const storeDoc = await db.collection('stores').doc(storeId).get();
    if (!storeDoc.exists) {
      throw new HttpsError('not-found', '店舗が見つかりません');
    }

    const storeData = storeDoc.data() as Record<string, unknown>;
    const ownerId = toStringValue(storeData['ownerId'] ?? storeData['createdBy']);
    const isAdmin = request.auth.token?.admin === true;
    if (ownerId && request.auth.uid !== ownerId && !isAdmin) {
      throw new HttpsError('permission-denied', '権限がありません');
    }

    const authUrl = buildInstagramAuthUrl();
    return { success: true, authUrl };
  },
);

export const exchangeInstagramAuthCode = onCall(
  {
    region: 'asia-northeast1',
    invoker: 'public',
    secrets: [INSTAGRAM_APP_ID, INSTAGRAM_APP_SECRET, INSTAGRAM_REDIRECT_URI],
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError('unauthenticated', 'ログインが必要です');
    }

    const storeId = toStringValue(request.data?.storeId).trim();
    const code = toStringValue(request.data?.code).trim();
    if (!storeId || !code) {
      throw new HttpsError('invalid-argument', 'storeId と code が必要です');
    }

    const storeDoc = await db.collection('stores').doc(storeId).get();
    if (!storeDoc.exists) {
      throw new HttpsError('not-found', '店舗が見つかりません');
    }

    const storeData = storeDoc.data() as Record<string, unknown>;
    const ownerId = toStringValue(storeData['ownerId'] ?? storeData['createdBy']);
    const isAdmin = request.auth.token?.admin === true;
    if (ownerId && request.auth.uid !== ownerId && !isAdmin) {
      throw new HttpsError('permission-denied', '権限がありません');
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

      await storeDoc.ref.set(
        {
          instagramAuth,
        },
        { merge: true },
      );

      const count = await syncInstagramPostsForStore({
        storeId,
        storeData: {
          ...storeData,
          instagramAuth,
        },
      });
      return { success: true, count };
    } catch (error) {
      console.error('Instagram auth exchange failed:', error);
      throw new HttpsError('internal', 'Instagram連携に失敗しました');
    }
  },
);

export const updateInstagramSyncSettings = onCall(
  {
    region: 'asia-northeast1',
    invoker: 'public',
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError('unauthenticated', 'ログインが必要です');
    }

    const storeId = toStringValue(request.data?.storeId).trim();
    const enabled = request.data?.enabled === false ? false : true;
    const rawSyncTime = toStringValue(request.data?.syncTime).trim();

    if (!storeId) {
      throw new HttpsError('invalid-argument', 'storeId が必要です');
    }
    if (rawSyncTime && !isInstagramSyncTimeAllowed(rawSyncTime)) {
      throw new HttpsError(
        'invalid-argument',
        'syncTime は 09:00〜21:00 の30分単位（HH:mm）で指定してください',
      );
    }

    const storeDoc = await db.collection('stores').doc(storeId).get();
    if (!storeDoc.exists) {
      throw new HttpsError('not-found', '店舗が見つかりません');
    }

    const storeData = storeDoc.data() as Record<string, unknown>;
    const ownerId = toStringValue(storeData['ownerId'] ?? storeData['createdBy']);
    const isAdmin = request.auth.token?.admin === true;
    if (ownerId && request.auth.uid !== ownerId && !isAdmin) {
      throw new HttpsError('permission-denied', '権限がありません');
    }

    const currentSettings =
      (storeData['instagramSyncSettings'] as Record<string, unknown> | undefined) ?? {};
    const currentNextSyncAt = toDateValue(currentSettings['nextSyncAt']);
    const syncInfo = storeData['instagramSync'] as Record<string, unknown> | undefined;
    const lastSyncAt = toDateValue(syncInfo?.['lastSyncAt']);

    const syncTime = normalizeInstagramSyncTime(
      rawSyncTime || currentSettings['syncTime'],
      currentNextSyncAt ?? lastSyncAt,
    );

    const nextSyncDate = enabled
      ? buildNextInstagramSyncDate(new Date(), syncTime)
      : null;
    const updatePayload: Record<string, unknown> = {
      'instagramSyncSettings.enabled': enabled,
      'instagramSyncSettings.syncTime': syncTime,
      'instagramSyncSettings.updatedAt': FieldValue.serverTimestamp(),
      'instagramSyncSettings.nextSyncAt': nextSyncDate
        ? Timestamp.fromDate(nextSyncDate)
        : FieldValue.delete(),
      'instagramSyncSettings.intervalMinutes': FieldValue.delete(),
    };
    await storeDoc.ref.update(updatePayload);

    return {
      success: true,
      enabled,
      syncTime,
      nextSyncAt: nextSyncDate ? nextSyncDate.toISOString() : null,
    };
  },
);

export const syncInstagramPosts = onCall(
  {
    region: 'asia-northeast1',
    invoker: 'public',
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError('unauthenticated', 'ログインが必要です');
    }

    const storeId = toStringValue(request.data?.storeId).trim();
    if (!storeId) {
      throw new HttpsError('invalid-argument', 'storeId が必要です');
    }

    const storeDoc = await db.collection('stores').doc(storeId).get();
    if (!storeDoc.exists) {
      throw new HttpsError('not-found', '店舗が見つかりません');
    }

    const storeData = storeDoc.data() as Record<string, unknown>;
    const ownerId = toStringValue(storeData['ownerId'] ?? storeData['createdBy']);
    const isAdmin = request.auth.token?.admin === true;
    if (ownerId && request.auth.uid !== ownerId && !isAdmin) {
      throw new HttpsError('permission-denied', '権限がありません');
    }

    const count = await syncInstagramPostsForStore({ storeId, storeData });
    return { success: true, count };
  },
);

export const unlinkInstagramAuth = onCall(
  {
    region: 'asia-northeast1',
    invoker: 'public',
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError('unauthenticated', 'ログインが必要です');
    }

    const storeId = toStringValue(request.data?.storeId).trim();
    if (!storeId) {
      throw new HttpsError('invalid-argument', 'storeId が必要です');
    }

    const storeDoc = await db.collection('stores').doc(storeId).get();
    if (!storeDoc.exists) {
      throw new HttpsError('not-found', '店舗が見つかりません');
    }

    const storeData = storeDoc.data() as Record<string, unknown>;
    const ownerId = toStringValue(storeData['ownerId'] ?? storeData['createdBy']);
    const isAdmin = request.auth.token?.admin === true;
    if (ownerId && request.auth.uid !== ownerId && !isAdmin) {
      throw new HttpsError('permission-denied', '権限がありません');
    }

    await storeDoc.ref.set(
      {
        instagramAuth: FieldValue.delete(),
        instagramSync: FieldValue.delete(),
        instagramSyncSettings: FieldValue.delete(),
      },
      { merge: true },
    );

    return { success: true };
  },
);

export const syncInstagramPostsScheduled = onSchedule(
  {
    region: 'asia-northeast1',
    schedule: 'every 30 minutes',
    timeZone: 'Asia/Tokyo',
  },
  async () => {
    const stores = await db
      .collection('stores')
      .where('instagramAuth.instagramUserId', '!=', '')
      .get();
    const now = new Date();
    let processed = 0;
    let total = 0;

    for (const doc of stores.docs) {
      const storeData = doc.data() as Record<string, unknown>;
      if (!shouldRunInstagramSync(storeData, now)) {
        continue;
      }

      processed += 1;
      try {
        const count = await syncInstagramPostsForStore({ storeId: doc.id, storeData });
        total += count;
      } catch (error) {
        console.error(`Instagram sync failed: storeId=${doc.id}`, error);
      }
    }

    console.log(`Instagram sync finished: stores=${processed}, posts=${total}, checked=${stores.size}`);
  },
);

export const expireCoinsScheduled = onSchedule(
  {
    region: 'asia-northeast1',
    schedule: 'every day 03:30',
    timeZone: 'Asia/Tokyo',
  },
  async () => {
    const now = Timestamp.now();
    const BATCH_SIZE = 400;
    let expiredUsers = 0;
    let cleanedUsers = 0;

    while (true) {
      const snapshot = await db
        .collection(USERS_COLLECTION)
        .where('coinExpiresAt', '<=', now)
        .limit(BATCH_SIZE)
        .get();

      if (snapshot.empty) break;

      const batch = db.batch();
      let updates = 0;
      for (const doc of snapshot.docs) {
        const data = doc.data() as Record<string, unknown>;
        const currentCoins = asInt(data['coins'], 0);

        if (currentCoins > 0) {
          batch.update(doc.ref, {
            coins: 0,
            coinExpiredAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          });
          expiredUsers += 1;
          updates += 1;
          continue;
        }

        batch.update(doc.ref, {
          coinExpiresAt: FieldValue.delete(),
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

    console.log(
      `[expireCoinsScheduled] expiredUsers=${expiredUsers}, cleanedUsers=${cleanedUsers}`,
    );
  },
);

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
export const notifyFollowersOnNewPost = onDocumentCreated(
  {
    document: 'public_posts/{postId}',
    region: 'asia-northeast1',
  },
  async (event) => {
    const data = event.data?.data() as Record<string, unknown> | undefined;
    if (!data) return;

    const storeId = (data['storeId'] ?? '').toString();
    const storeName = (data['storeName'] ?? '').toString();
    const content = (data['content'] ?? '').toString();
    const isActive = data['isActive'] !== false;
    const isPublished = data['isPublished'] !== false;

    if (!storeId || !isActive || !isPublished) return;

    const followersSnap = await db
      .collection('stores')
      .doc(storeId)
      .collection('followers')
      .get();

    if (followersSnap.empty) return;

    const truncatedContent =
      content.length > 50 ? content.substring(0, 50) + '...' : content;

    const BATCH_SIZE = 500;
    const followerDocs = followersSnap.docs;
    for (let i = 0; i < followerDocs.length; i += BATCH_SIZE) {
      const chunk = followerDocs.slice(i, i + BATCH_SIZE);
      await Promise.all(
        chunk.map(async (followerDoc) => {
          const followerId = followerDoc.id;
          try {
            const userDoc = await db.collection(USERS_COLLECTION).doc(followerId).get();
            const userData = userDoc.data() as Record<string, unknown> | undefined;
            const postNotification = (userData?.notificationSettings as Record<string, unknown> | undefined)?.post;
            if (postNotification === false) return;

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
          } catch (e) {
            console.error(`[notifyFollowersOnNewPost] Error for follower ${followerId}:`, e);
          }
        }),
      );
    }

    console.log(
      `[notifyFollowersOnNewPost] Notified ${followersSnap.size} followers for store ${storeId}`,
    );
  },
);

// フォロワーへのクーポン通知
export const notifyFollowersOnNewCoupon = onDocumentCreated(
  {
    document: 'public_coupons/{couponId}',
    region: 'asia-northeast1',
  },
  async (event) => {
    const data = event.data?.data() as Record<string, unknown> | undefined;
    if (!data) return;

    const storeId = (data['storeId'] ?? '').toString();
    const storeName = (data['storeName'] ?? '').toString();
    const title = (data['title'] ?? '').toString();
    const isActive = data['isActive'] !== false;

    if (!storeId || !isActive) return;

    const followersSnap = await db
      .collection('stores')
      .doc(storeId)
      .collection('followers')
      .get();

    if (followersSnap.empty) return;

    const BATCH_SIZE = 500;
    const followerDocs = followersSnap.docs;
    for (let i = 0; i < followerDocs.length; i += BATCH_SIZE) {
      const chunk = followerDocs.slice(i, i + BATCH_SIZE);
      await Promise.all(
        chunk.map(async (followerDoc) => {
          const followerId = followerDoc.id;
          try {
            const userDoc = await db.collection(USERS_COLLECTION).doc(followerId).get();
            const userData = userDoc.data() as Record<string, unknown> | undefined;
            const couponNotification = (userData?.notificationSettings as Record<string, unknown> | undefined)?.couponIssued;
            if (couponNotification === false) return;

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
          } catch (e) {
            console.error(`[notifyFollowersOnNewCoupon] Error for follower ${followerId}:`, e);
          }
        }),
      );
    }

    console.log(
      `[notifyFollowersOnNewCoupon] Notified ${followersSnap.size} followers for store ${storeId}`,
    );
  },
);

// フォロワーへのInstagram投稿通知
export const notifyFollowersOnNewInstagramPost = onDocumentCreated(
  {
    document: 'public_instagram_posts/{postId}',
    region: 'asia-northeast1',
  },
  async (event) => {
    const data = event.data?.data() as Record<string, unknown> | undefined;
    if (!data) return;

    const storeId = (data['storeId'] ?? '').toString();
    const storeName = (data['storeName'] ?? '').toString();
    const caption = (data['caption'] ?? '').toString();
    const isActive = data['isActive'] !== false;
    const isVideo = data['isVideo'] === true;

    if (!storeId || !isActive || isVideo) return;

    const followersSnap = await db
      .collection('stores')
      .doc(storeId)
      .collection('followers')
      .get();

    if (followersSnap.empty) return;

    const truncatedCaption =
      caption.length > 50 ? caption.substring(0, 50) + '...' : caption;

    const BATCH_SIZE = 500;
    const followerDocs = followersSnap.docs;
    for (let i = 0; i < followerDocs.length; i += BATCH_SIZE) {
      const chunk = followerDocs.slice(i, i + BATCH_SIZE);
      await Promise.all(
        chunk.map(async (followerDoc) => {
          const followerId = followerDoc.id;
          try {
            const userDoc = await db.collection(USERS_COLLECTION).doc(followerId).get();
            const userData = userDoc.data() as Record<string, unknown> | undefined;
            const postNotification = (userData?.notificationSettings as Record<string, unknown> | undefined)?.post;
            if (postNotification === false) return;

            await createUserNotification({
              userId: followerId,
              title: `${storeName}がInstagramを更新しました`,
              body: truncatedCaption || '新しいInstagram投稿をチェックしましょう！',
              type: 'marketing',
              tags: ['instagram_post'],
              data: {
                type: 'instagram_post',
                storeId,
                storeName,
                postId: event.params.postId,
              },
            });
          } catch (e) {
            console.error(`[notifyFollowersOnNewInstagramPost] Error for follower ${followerId}:`, e);
          }
        }),
      );
    }

    console.log(
      `[notifyFollowersOnNewInstagramPost] Notified ${followersSnap.size} followers for store ${storeId}`,
    );
  },
);

// 店舗作成時にisOwnerフラグを自動設定
// 作成者がisOwnerユーザーの場合、店舗ドキュメントにisOwner=trueを設定
export const setStoreOwnerFlagOnCreate = onDocumentCreated(
  {
    document: 'stores/{storeId}',
    region: 'asia-northeast1',
  },
  async (event) => {
    const data = event.data?.data() as Record<string, unknown> | undefined;
    if (!data) return;

    // 既にisOwner=trueなら何もしない
    if (data['isOwner'] === true) return;

    const createdBy = (data['createdBy'] ?? data['ownerId'])?.toString();
    if (!createdBy) return;

    try {
      const userDoc = await db.collection(USERS_COLLECTION).doc(createdBy).get();
      const userData = userDoc.data() as Record<string, unknown> | undefined;
      if (userData?.isOwner === true) {
        await event.data?.ref.update({ isOwner: true });
        console.log(`[setStoreOwnerFlagOnCreate] isOwner=true を設定: ${event.params.storeId} (createdBy: ${createdBy})`);
      }
    } catch (e) {
      console.error(`[setStoreOwnerFlagOnCreate] Error:`, e);
    }
  },
);

// 既存店舗のisOwnerフラグ一括同期（ワンタイム実行用）
export const syncStoreOwnerFlags = onCall(
  { region: 'asia-northeast1' },
  async (request) => {
    // isOwner権限チェック
    if (!request.auth) {
      throw new HttpsError('unauthenticated', '認証が必要です');
    }
    const callerDoc = await db.collection(USERS_COLLECTION).doc(request.auth.uid).get();
    const callerData = callerDoc.data() as Record<string, unknown> | undefined;
    if (callerData?.isOwner !== true) {
      throw new HttpsError('permission-denied', 'isOwner権限が必要です');
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
      const storeData = storeDoc.data() as Record<string, unknown>;
      if (storeData['isOwner'] === true) continue;

      const createdBy = (storeData['createdBy'] ?? storeData['ownerId'])?.toString();
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
  },
);

// スタンプ数と来店回数の同期（管理者専用）
export const syncStampsWithVisits = onCall(
  {
    region: 'asia-northeast1',
    enforceAppCheck: false,
    timeoutSeconds: 300,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Authentication required');
    }

    const callerUid = request.auth.uid;
    const callerSnap = await db.collection(USERS_COLLECTION).doc(callerUid).get();
    if (!callerSnap.exists || callerSnap.data()?.['isOwner'] !== true) {
      throw new HttpsError('permission-denied', 'Only admin owners can execute this function');
    }

    const dryRun = request.data?.dryRun === true;
    console.log(`[syncStampsWithVisits] 開始 (dryRun=${dryRun})`);

    const storesSnap = await db.collection('stores').get();
    let totalChecked = 0;
    let mismatchCount = 0;
    let updatedCount = 0;
    const mismatches: Array<{
      storeId: string; userId: string; totalVisits: number; stamps: number;
      displayName: string; profileImageUrl: string | null; storeName: string;
    }> = [];

    const BATCH_SIZE = 500;
    let batch = db.batch();
    let batchCount = 0;

    for (const storeDoc of storesSnap.docs) {
      const storeId = storeDoc.id;
      const storeName = (storeDoc.data()['name'] as string) || '店舗名なし';
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
        const currentStamps = asInt(userStoreSnap.data()?.['stamps'], 0);

        totalChecked++;

        if (totalVisits > currentStamps) {
          mismatchCount++;

          // ユーザー情報を取得（最大50件まで詳細を返却）
          let displayName = 'Unknown';
          let profileImageUrl: string | null = null;
          if (mismatches.length < 50) {
            const userSnap = await db.collection(USERS_COLLECTION).doc(userId).get();
            if (userSnap.exists) {
              displayName = (userSnap.data()?.['displayName'] as string) || 'Unknown';
              profileImageUrl = (userSnap.data()?.['profileImageUrl'] as string) || null;
            }
          }
          mismatches.push({ storeId, userId, totalVisits, stamps: currentStamps, displayName, profileImageUrl, storeName });

          if (!dryRun) {
            batch.set(
              userStoreRef,
              {
                stamps: totalVisits,
                updatedAt: FieldValue.serverTimestamp(),
              },
              { merge: true },
            );
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

    console.log(
      `[syncStampsWithVisits] 完了: checked=${totalChecked}, mismatches=${mismatchCount}, updated=${updatedCount}`,
    );

    return {
      dryRun,
      totalChecked,
      mismatchCount,
      updatedCount,
      mismatches: mismatches.slice(0, 50),
    };
  },
);

// ===== 物理スタンプカード電子化移行 =====
// 店舗スタッフがユーザーのQRコードをスキャンし、物理カードのスタンプ数を入力して
// デジタルスタンプに移行する。来店扱い（コイン・visitCount）はしない。
export const migrateStampCard = onCall(
  {
    region: 'asia-northeast1',
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Store must be authenticated');
    }

    const { userId, storeId, physicalStamps: rawPhysicalStamps } = request.data || {};
    if (!userId || !storeId) {
      throw new HttpsError('invalid-argument', 'Missing required parameters: userId and storeId');
    }
    const physicalStamps = asInt(rawPhysicalStamps, 0);
    if (physicalStamps < 1 || physicalStamps > 99) {
      throw new HttpsError('invalid-argument', 'physicalStamps must be between 1 and 99');
    }

    const staffUserId = request.auth.uid;
    const staffUserRef = db.collection(USERS_COLLECTION).doc(staffUserId);
    const storeRef = db.collection('stores').doc(storeId);
    const targetUserRef = db.collection(USERS_COLLECTION).doc(userId);
    const targetStoreRef = targetUserRef.collection('stores').doc(storeId);
    const migrationDocId = `${storeId}_${userId}`;
    const migrationDocRef = db.collection('stamp_migrations').doc(migrationDocId);

    const result = await db.runTransaction(async (txn) => {
      // スタッフの店舗権限チェック（punchStamp と同じロジック）
      const [staffUserSnap, storeSnap] = await Promise.all([
        txn.get(staffUserRef),
        txn.get(storeRef),
      ]);

      if (!staffUserSnap.exists) {
        throw new HttpsError('permission-denied', 'Store user not found');
      }
      if (!storeSnap.exists) {
        throw new HttpsError('not-found', 'Store not found');
      }

      const staffUserData = staffUserSnap.data() as Record<string, unknown>;
      const currentStoreId = (staffUserData['currentStoreId'] ?? '').toString();
      const createdStores = (staffUserData['createdStores'] as string[]) ?? [];
      const isOwnerFlag = staffUserData['isOwner'] === true || staffUserData['isStoreOwner'] === true;
      const storeCreatedBy = (storeSnap.data()?.createdBy ?? '').toString();
      const isMember =
        currentStoreId === storeId || createdStores.includes(storeId) || storeCreatedBy === staffUserId;

      if (!isOwnerFlag && !isMember) {
        throw new HttpsError('permission-denied', 'Not authorized for this store');
      }

      // 対象ユーザー存在確認
      const targetUserSnap = await txn.get(targetUserRef);
      if (!targetUserSnap.exists) {
        throw new HttpsError('not-found', 'Target user not found');
      }

      // 二重移行チェック: migrationId を固定IDにすることでアトミックに防止
      const migrationSnap = await txn.get(migrationDocRef);
      if (migrationSnap.exists) {
        throw new HttpsError('already-exists', `Migration already exists for userId=${userId}, storeId=${storeId}`);
      }

      // 現在のデジタルスタンプ数を取得
      const targetStoreSnap = await txn.get(targetStoreRef);
      const stampsBefore = asInt(targetStoreSnap.data()?.['stamps'], 0);
      const stampsAfter = stampsBefore + physicalStamps;

      // 達成カード数を計算（10の倍数に到達した回数）
      let completedCards = 0;
      for (let s = stampsBefore + 1; s <= stampsAfter; s++) {
        if (s % MAX_STAMPS === 0) completedCards++;
      }

      const storeName = (storeSnap.data()?.name ?? '').toString();

      // users/{userId}/stores/{storeId} のスタンプを更新
      txn.set(
        targetStoreRef,
        {
          storeId,
          storeName: storeName || undefined,
          stamps: stampsAfter,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

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
        createdAt: FieldValue.serverTimestamp(),
        note: '',
      });

      return { userId, storeId, storeName, stampsBefore, stampsAfter, completedCards };
    });

    console.log(
      `[migrateStampCard] 完了: userId=${userId}, storeId=${storeId}, ` +
      `stampsBefore=${result.stampsBefore}, stampsAfter=${result.stampsAfter}, completedCards=${result.completedCards}`
    );

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
            if (!noUsageLimit && usageLimit > 0 && usedCount >= usageLimit) continue;

            const userCouponRef = db.collection('user_coupons').doc();
            await userCouponRef.set({
              userId,
              couponId: couponDoc.id,
              storeId,
              storeName: couponData['storeName'] ?? '',
              title: couponData['title'] ?? '',
              obtainedAt: FieldValue.serverTimestamp(),
              isUsed: false,
              noExpiry: true,
              validUntil: null,
              type: 'stamp_reward',
              discountValue: couponData['discountValue'] ?? 0,
              discountType: couponData['discountType'] ?? 'fixed_amount',
              couponType: couponData['couponType'] ?? 'discount',
              requiredStampCount: 0,
            });
          }
        }
        console.log(`[migrateStampCard] Awarded stamp coupons: userId=${userId}, storeId=${storeId}, cards=${result.completedCards}`);
      } catch (e) {
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
  },
);

// ─── コイン交換クーポン有効期限通知（毎日10:00 JST） ───
export const notifyCouponExpiryScheduled = onSchedule(
  {
    region: 'asia-northeast1',
    schedule: 'every day 10:00',
    timeZone: 'Asia/Tokyo',
  },
  async () => {
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
    let lastDoc7d: FirebaseFirestore.QueryDocumentSnapshot | null = null;
    while (true) {
      let query = db
        .collection('user_coupons')
        .where('type', '==', 'coin_exchange')
        .where('isUsed', '==', false)
        .where('validUntil', '>=', Timestamp.fromDate(sevenDaysStart))
        .where('validUntil', '<=', Timestamp.fromDate(sevenDaysEnd))
        .limit(BATCH_SIZE);

      if (lastDoc7d) {
        query = query.startAfter(lastDoc7d);
      }

      const snapshot = await query.get();
      if (snapshot.empty) break;

      for (const doc of snapshot.docs) {
        const data = doc.data();
        if (data['expiryNotified7d'] === true) continue;

        const userId = data['userId'] as string;
        const storeName = (data['storeName'] as string) ?? '店舗';
        const title = (data['title'] as string) ?? '100円引きクーポン';

        await createUserNotification({
          userId,
          title: 'クーポンの有効期限が近づいています',
          body: `${storeName}の「${title}」の有効期限が残り7日です。お早めにご利用ください。`,
          type: 'system',
          tags: ['coupon_expiry'],
          data: {
            userCouponId: doc.id,
            storeId: (data['storeId'] as string) ?? '',
            daysRemaining: 7,
          },
        });

        await doc.ref.update({ expiryNotified7d: true });
        notified7d++;
      }

      lastDoc7d = snapshot.docs[snapshot.docs.length - 1];
      if (snapshot.size < BATCH_SIZE) break;
    }

    // --- 3日前通知 ---
    let lastDoc3d: FirebaseFirestore.QueryDocumentSnapshot | null = null;
    while (true) {
      let query = db
        .collection('user_coupons')
        .where('type', '==', 'coin_exchange')
        .where('isUsed', '==', false)
        .where('validUntil', '>=', Timestamp.fromDate(threeDaysStart))
        .where('validUntil', '<=', Timestamp.fromDate(threeDaysEnd))
        .limit(BATCH_SIZE);

      if (lastDoc3d) {
        query = query.startAfter(lastDoc3d);
      }

      const snapshot = await query.get();
      if (snapshot.empty) break;

      for (const doc of snapshot.docs) {
        const data = doc.data();
        if (data['expiryNotified3d'] === true) continue;

        const userId = data['userId'] as string;
        const storeName = (data['storeName'] as string) ?? '店舗';
        const title = (data['title'] as string) ?? '100円引きクーポン';

        await createUserNotification({
          userId,
          title: 'クーポンの有効期限が迫っています',
          body: `${storeName}の「${title}」の有効期限が残り3日です。お早めにご利用ください！`,
          type: 'system',
          tags: ['coupon_expiry'],
          data: {
            userCouponId: doc.id,
            storeId: (data['storeId'] as string) ?? '',
            daysRemaining: 3,
          },
        });

        await doc.ref.update({ expiryNotified3d: true });
        notified3d++;
      }

      lastDoc3d = snapshot.docs[snapshot.docs.length - 1];
      if (snapshot.size < BATCH_SIZE) break;
    }

    console.log(
      `[notifyCouponExpiryScheduled] notified7d=${notified7d}, notified3d=${notified3d}`,
    );
  },
);

// Haversine距離計算（メートル単位）
function haversineDistance(
  a: { lat: number; lng: number },
  b: { lat: number; lng: number },
): number {
  const R = 6371000;
  const φ1 = (a.lat * Math.PI) / 180;
  const φ2 = (b.lat * Math.PI) / 180;
  const Δφ = ((b.lat - a.lat) * Math.PI) / 180;
  const Δλ = ((b.lng - a.lng) * Math.PI) / 180;
  const x =
    Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
    Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
  return R * 2 * Math.atan2(Math.sqrt(x), Math.sqrt(1 - x));
}

// チェックインセッション作成（NFCタグ検証 + 10分有効の使い捨てトークン発行）
export const createCheckinSession = onCall(
  {
    region: 'asia-northeast1',
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    const userId = request.auth.uid;
    const { storeId, tagSecret } = request.data || {};
    if (!storeId || !tagSecret) {
      throw new HttpsError('invalid-argument', 'Missing required parameters: storeId and tagSecret');
    }

    // NFCタグの検証
    const tagQuery = await db
      .collection(NFC_TAGS_COLLECTION)
      .where('storeId', '==', storeId)
      .where('tagSecret', '==', tagSecret)
      .limit(1)
      .get();

    if (tagQuery.empty) {
      throw new HttpsError('not-found', 'Invalid NFC tag');
    }

    const tagData = tagQuery.docs[0].data();
    if (tagData['isActive'] !== true) {
      throw new HttpsError('failed-precondition', 'NFC tag is deactivated');
    }

    // 店舗の有効性チェック
    const storeSnap = await db.collection('stores').doc(storeId).get();
    if (!storeSnap.exists) {
      throw new HttpsError('not-found', 'Store not found');
    }
    const storeData = storeSnap.data() as Record<string, unknown>;
    if (storeData['isActive'] !== true || storeData['isApproved'] !== true) {
      throw new HttpsError('failed-precondition', 'Store is not active or not approved');
    }

    // セッションドキュメントを作成（10分間有効）
    const sessionToken = randomUUID();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000);

    await db.collection(CHECKIN_SESSIONS_COLLECTION).doc(sessionToken).set({
      userId,
      storeId,
      expiresAt: Timestamp.fromDate(expiresAt),
      used: false,
      createdAt: FieldValue.serverTimestamp(),
    });

    console.log(`[createCheckinSession] session created: user=${userId}, store=${storeId}, token=${sessionToken}`);

    return { sessionToken };
  },
);

// NFCチェックイン（ユーザーアプリ用・完全自動スタンプ付与）
export const nfcCheckin = onCall(
  {
    region: 'asia-northeast1',
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    const userId = request.auth.uid;
    const { sessionToken, userLat, userLng, selectedUserCouponIds: rawSelectedUserCouponIds } = request.data || {};
    if (!sessionToken) {
      throw new HttpsError('invalid-argument', 'Missing required parameter: sessionToken');
    }
    if (typeof userLat !== 'number' || typeof userLng !== 'number') {
      throw new HttpsError('invalid-argument', 'Missing required parameters: userLat and userLng');
    }
    const selectedUserCouponIds: string[] = Array.isArray(rawSelectedUserCouponIds)
      ? rawSelectedUserCouponIds.filter((id: unknown) => typeof id === 'string' && (id as string).trim().length > 0)
      : [];

    // 1. セッショントークンの検証
    const sessionRef = db.collection(CHECKIN_SESSIONS_COLLECTION).doc(sessionToken);
    const sessionSnap = await sessionRef.get();
    if (!sessionSnap.exists) {
      throw new HttpsError('not-found', 'Invalid or expired session');
    }
    const sessionData = sessionSnap.data()!;
    if (sessionData['used'] === true) {
      throw new HttpsError('already-exists', 'Session already used');
    }
    if (sessionData['userId'] !== userId) {
      throw new HttpsError('permission-denied', 'Session user mismatch');
    }
    const sessionExpiresAt = (sessionData['expiresAt'] as Timestamp).toDate();
    if (sessionExpiresAt < new Date()) {
      throw new HttpsError('deadline-exceeded', 'Session has expired');
    }
    const storeId = sessionData['storeId'] as string;

    // セッションを使用済みにマーク（再利用防止）
    await sessionRef.update({ used: true });

    // 2. 店舗の有効性チェック
    const storeRef = db.collection('stores').doc(storeId);
    const storeSnap = await storeRef.get();
    if (!storeSnap.exists) {
      throw new HttpsError('not-found', 'Store not found');
    }
    const storeData = storeSnap.data() as Record<string, unknown>;
    if (storeData['isActive'] !== true || storeData['isApproved'] !== true) {
      throw new HttpsError('failed-precondition', 'Store is not active or not approved');
    }
    const storeName = (storeData['name'] ?? '').toString();

    // 3. 位置情報チェック（店舗から200m以内か検証）
    const storeLocation = storeData['location'] as { latitude?: number; longitude?: number } | undefined;
    if (!storeLocation || typeof storeLocation.latitude !== 'number' || typeof storeLocation.longitude !== 'number') {
      throw new HttpsError('failed-precondition', 'Store location is not configured');
    }
    const distanceMeters = haversineDistance(
      { lat: userLat, lng: userLng },
      { lat: storeLocation.latitude, lng: storeLocation.longitude },
    );
    console.log(`[nfcCheckin] distance check: user=(${userLat},${userLng}), store=(${storeLocation.latitude},${storeLocation.longitude}), distance=${Math.round(distanceMeters)}m`);
    if (distanceMeters > 200) {
      throw new HttpsError('permission-denied', `Too far from store: ${Math.round(distanceMeters)}m`);
    }

    // 3. トランザクション内でスタンプ処理
    const targetUserRef = db.collection(USERS_COLLECTION).doc(userId);
    const targetStoreRef = targetUserRef.collection('stores').doc(storeId);
    const storeUserStatsRef = db.collection('store_users').doc(storeId).collection('users').doc(userId);

    const result = await db.runTransaction(async (txn) => {
      const [targetStoreSnap, storeUserStatsSnap] = await Promise.all([
        txn.get(targetStoreRef),
        txn.get(storeUserStatsRef),
      ]);

      // 1日1回制限チェック
      const todayJst = getJstDateString();
      const lastStampDate = targetStoreSnap.data()?.['lastStampDate'];
      if (typeof lastStampDate === 'string' && lastStampDate === todayJst) {
        throw new HttpsError('already-exists', 'Already checked in today for this store');
      }

      const currentStamps = asInt(targetStoreSnap.data()?.['stamps'], 0);
      const isFirstVisit = !storeUserStatsSnap.exists;
      const currentTotalVisits = asInt(storeUserStatsSnap.data()?.['totalVisits'], 0);
      const newTotalVisits = isFirstVisit ? 1 : currentTotalVisits + 1;
      let stampsAfter = 0;
      let cardCompleted = false;

      if (currentStamps >= 1) {
        // 救済措置: 既存スタンプ保有者はスタンプを +1 加算
        const nextStamps = currentStamps + 1;
        cardCompleted = nextStamps % MAX_STAMPS === 0;
        stampsAfter = nextStamps;
        txn.set(
          targetStoreRef,
          stripUndefined({
            storeId,
            storeName: storeName || undefined,
            stamps: nextStamps,
            totalVisits: newTotalVisits,
            lastStampDate: todayJst,
            lastVisited: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          }),
          { merge: true },
        );
      } else {
        // 新規ユーザー（stamps=0）: 来店記録のみ（スタンプ加算なし）
        txn.set(
          targetStoreRef,
          stripUndefined({
            storeId,
            storeName: storeName || undefined,
            totalVisits: newTotalVisits,
            lastStampDate: todayJst,
            lastVisited: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          }),
          { merge: true },
        );
      }

      // 日次統計
      const statsRef = db.collection('store_stats').doc(storeId).collection('daily').doc(todayJst);
      txn.set(
        statsRef,
        {
          date: todayJst,
          visitorCount: FieldValue.increment(1),
          lastUpdated: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      // 来店ユーザー統計
      if (storeUserStatsSnap.exists) {
        txn.set(
          storeUserStatsRef,
          {
            lastVisitAt: FieldValue.serverTimestamp(),
            totalVisits: FieldValue.increment(1),
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      } else {
        txn.set(storeUserStatsRef, {
          userId,
          storeId,
          firstVisitAt: FieldValue.serverTimestamp(),
          lastVisitAt: FieldValue.serverTimestamp(),
          totalVisits: 1,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
      }

      // discoveredCount インクリメント（初回来店時のみ）
      if (isFirstVisit) {
        txn.update(storeRef, {
          discoveredCount: FieldValue.increment(1),
          updatedAt: FieldValue.serverTimestamp(),
        });
      }

      return {
        userId,
        storeId,
        storeName,
        stampsAfter,
        cardCompleted,
        isFirstVisit,
      };
    });

    // stores/{storeId}/transactions にスタンプ来店記録を作成
    let userGender: string | null = null;
    let userAgeGroup: string | null = null;
    let userPrefecture: string | null = null;
    let userCity: string | null = null;
    try {
      const targetUserSnap = await targetUserRef.get();
      if (targetUserSnap.exists) {
        const userData = targetUserSnap.data();
        userGender = typeof userData?.gender === 'string' ? userData.gender : null;
        userPrefecture = typeof userData?.prefecture === 'string' ? userData.prefecture : null;
        userCity = typeof userData?.city === 'string' ? userData.city : null;
        const birthDateVal = userData?.birthDate;
        if (birthDateVal) {
          const bd =
            birthDateVal instanceof Timestamp
              ? birthDateVal
              : birthDateVal instanceof Date
                ? Timestamp.fromDate(birthDateVal)
                : null;
          if (bd) {
            userAgeGroup = calculateAgeGroup(bd);
          }
        }
      }
    } catch (e) {
      console.error('[nfcCheckin] ユーザー属性取得エラー（続行）:', e);
    }

    const stampTxnRef = storeRef.collection('transactions').doc();
    await stampTxnRef.set({
      transactionId: stampTxnRef.id,
      storeId,
      storeName: result.storeName ?? '',
      userId,
      type: 'stamp',
      amountYen: 0,
      points: 0,
      status: 'completed',
      source: 'nfc_checkin',
      userGender,
      userAgeGroup,
      userPrefecture,
      userCity,
      createdAt: FieldValue.serverTimestamp(),
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
      await eventRef.set(
        {
          type: 'nfc_checkin',
          transactionId: stampTxnRef.id,
          storeId,
          storeName: result.storeName ?? '',
          pointsAwarded: 0,
          isFirstVisit: result.isFirstVisit ?? false,
          badges,
          createdAt: FieldValue.serverTimestamp(),
          seenAt: null,
        },
        { merge: true },
      );
    } catch (e) {
      console.error('[nfcCheckin] achievement event creation error:', e);
    }

    // discoveredStoreCount インクリメント + ranking_scores batch 更新（初回来店時のみ）
    if (result.isFirstVisit) {
      try {
        // users/{uid}.discoveredStoreCount をインクリメント
        await targetUserRef.update({
          discoveredStoreCount: FieldValue.increment(1),
          updatedAt: FieldValue.serverTimestamp(),
        });

        // ranking_scores 用の期間ID計算
        const rankingNow = new Date();
        const rankingYyyy = rankingNow.getFullYear();
        const rankingMM = String(rankingNow.getMonth() + 1).padStart(2, '0');
        const rankingDd = String(rankingNow.getDate()).padStart(2, '0');
        const rankingStartOfYear = new Date(rankingYyyy, 0, 1);
        const rankingWeekNum = Math.ceil(
          ((rankingNow.getTime() - rankingStartOfYear.getTime()) / 86400000 + rankingStartOfYear.getDay() + 1) / 7,
        );
        const rankingWw = String(rankingWeekNum).padStart(2, '0');
        const periodIds = {
          alltime: 'alltime',
          weekly: `${rankingYyyy}-W${rankingWw}`,
          monthly: `${rankingYyyy}-${rankingMM}`,
          daily: `${rankingYyyy}-${rankingMM}-${rankingDd}`,
        };

        const rankingUserSnap = await targetUserRef.get();
        const rankingUserData = rankingUserSnap.data();
        const rankingOptOut = rankingUserData?.rankingOptOut === true;
        const displayName = rankingOptOut
          ? '名無し探検家'
          : (typeof rankingUserData?.displayName === 'string' ? rankingUserData.displayName : '不明なユーザー');
        const photoURL = rankingOptOut
          ? null
          : (typeof rankingUserData?.profileImageUrl === 'string' ? rankingUserData.profileImageUrl : null);

        const rankingBatch = db.batch();
        for (const periodId of Object.values(periodIds)) {
          const rankingRef = db
            .collection('ranking_scores')
            .doc(periodId)
            .collection('users')
            .doc(userId);
          rankingBatch.set(
            rankingRef,
            {
              score: FieldValue.increment(1),
              displayName,
              photoURL: photoURL ?? null,
              rankingOptOut,
              updatedAt: FieldValue.serverTimestamp(),
            },
            { merge: true },
          );
        }
        await rankingBatch.commit();
        console.log(`[nfcCheckin] discoveredStoreCount & ranking_scores updated for user=${userId}`);
      } catch (e) {
        console.error('[nfcCheckin] discoveredStoreCount/ranking_scores update error:', e);
      }
    }

    // 秘境探検家バッジ + ジャンル別コンプリートバッジ（初回来店時のみ）
    let hiddenExplorerIncremented = false;
    if (result.isFirstVisit) {
      try {
        const storeAreaId = storeData['areaId'];

        // ① 秘境探検家シリーズ（エリア外店舗への初回来店）
        if (!storeAreaId) {
          hiddenExplorerIncremented = true;
          const hiddenProgressRef = db.collection('badge_progress').doc(`${userId}_hiddenExplorer`);
          await hiddenProgressRef.set({
            userId,
            badgeType: 'hiddenExplorer',
            currentValue: FieldValue.increment(1),
            lastUpdated: FieldValue.serverTimestamp(),
          }, { merge: true });

          const hiddenSnap = await hiddenProgressRef.get();
          const hiddenCount = asInt(hiddenSnap.data()?.['currentValue'], 0);

          // 段階バッジ付与（hidden_explorer_1〜3）
          const hiddenThresholds: Array<[string, number]> = [
            ['hidden_explorer_1', 1],
            ['hidden_explorer_2', 3],
            ['hidden_explorer_3', 5],
          ];
          for (const [badgeId, threshold] of hiddenThresholds) {
            if (hiddenCount >= threshold) {
              const badgeRef = db.collection('user_badges').doc(userId).collection('badges').doc(badgeId);
              const snap = await badgeRef.get();
              if (!snap.exists) {
                await badgeRef.set({
                  userId,
                  badgeId,
                  unlockedAt: FieldValue.serverTimestamp(),
                  progress: hiddenCount,
                  requiredValue: threshold,
                  isNew: true,
                });
                console.log(`[nfcCheckin] Badge awarded: ${badgeId} to user=${userId}`);
              }
            }
          }

          // hidden_explorer_4: 全エリア外店舗制覇チェック
          const allStoresForHiddenSnap = await db.collection('stores')
            .where('isActive', '==', true)
            .where('isApproved', '==', true)
            .get();
          const totalHiddenStoreCount = allStoresForHiddenSnap.docs
            .filter(d => !d.data()['areaId'] && d.data()['isOwner'] !== true)
            .length;
          if (totalHiddenStoreCount > 0 && hiddenCount >= totalHiddenStoreCount) {
            const badge4Ref = db.collection('user_badges').doc(userId).collection('badges').doc('hidden_explorer_4');
            if (!(await badge4Ref.get()).exists) {
              await badge4Ref.set({
                userId,
                badgeId: 'hidden_explorer_4',
                unlockedAt: FieldValue.serverTimestamp(),
                progress: hiddenCount,
                requiredValue: totalHiddenStoreCount,
                isNew: true,
              });
              console.log(`[nfcCheckin] Badge awarded: hidden_explorer_4 to user=${userId}`);
            }
          }
        }

        // ② ジャンル別コンプリートバッジ
        const storeCategory = storeData['category'] as string | undefined;
        if (storeCategory) {
          const genreGroupsMap: Record<string, string[]> = {
            'cafe_sweets': ['カフェ・喫茶店', 'スイーツ', 'ケーキ', 'タピオカ', 'パン・サンドイッチ'],
            'washoku': ['和食', '日本料理', '海鮮', '寿司', 'そば', 'うどん', 'うなぎ', '天ぷら'],
            'izakaya_bar': ['居酒屋', 'バー・お酒', 'スナック'],
            'yakitori_age': ['焼き鳥', 'とんかつ', '串揚げ', 'お好み焼き', 'もんじゃ焼き'],
            'nabe_yakiniku': ['しゃぶしゃぶ', '鍋', '焼肉', 'ホルモン'],
            'ramen_chinese': ['ラーメン', '中華料理', '餃子'],
            'asian_ethnic': ['韓国料理', 'タイ料理', 'カレー', '沖縄料理'],
            'western_french': ['レストラン', '洋食', 'フレンチ', 'スペイン料理', 'ビストロ'],
            'italian_meat': ['パスタ', 'ピザ', 'ステーキ', 'ハンバーグ', 'ハンバーガー'],
            'shokudo_other': ['ビュッフェ', '食堂', '料理旅館', 'その他'],
          };

          let matchedGenre: string | null = null;
          for (const [genre, cats] of Object.entries(genreGroupsMap)) {
            if (cats.includes(storeCategory)) {
              matchedGenre = genre;
              break;
            }
          }

          if (matchedGenre) {
            const genreCats = genreGroupsMap[matchedGenre];
            const allStoresForGenreSnap = await db.collection('stores')
              .where('isActive', '==', true)
              .where('isApproved', '==', true)
              .get();
            const genreStoreIds = allStoresForGenreSnap.docs
              .filter(d => genreCats.includes(d.data()['category'] as string) && d.data()['isOwner'] !== true)
              .map(d => d.id);

            if (genreStoreIds.length > 0) {
              let allVisited = true;
              for (const gStoreId of genreStoreIds) {
                const visitSnap = await db.collection('store_users').doc(gStoreId).collection('users').doc(userId).get();
                if (!visitSnap.exists) {
                  allVisited = false;
                  break;
                }
              }

              if (allVisited) {
                const genreBadgeId = `genre_complete_${matchedGenre}`;
                const genreBadgeRef = db.collection('user_badges').doc(userId).collection('badges').doc(genreBadgeId);
                if (!(await genreBadgeRef.get()).exists) {
                  await genreBadgeRef.set({
                    userId,
                    badgeId: genreBadgeId,
                    unlockedAt: FieldValue.serverTimestamp(),
                    progress: 1,
                    requiredValue: 1,
                    isNew: true,
                  });
                  console.log(`[nfcCheckin] Badge awarded: ${genreBadgeId} to user=${userId}`);
                }
              }
            }
          }
        }
      } catch (e) {
        console.error('[nfcCheckin] hiddenExplorer/genreComplete badge error:', e);
      }
    }

    // 自動フォロー
    try {
      const followDocRef = targetUserRef.collection('followed_stores').doc(storeId);
      const followSnap = await followDocRef.get();

      if (!followSnap.exists) {
        const userDoc = await targetUserRef.get();
        const userData = userDoc.data() as Record<string, unknown> | undefined;

        const followBatch = db.batch();
        followBatch.set(followDocRef, {
          storeId,
          storeName: result.storeName ?? '',
          category: storeData['category'] ?? '',
          storeImageUrl: storeData['storeImageUrl'] ?? null,
          followedAt: FieldValue.serverTimestamp(),
          source: 'nfc_checkin',
        });
        followBatch.set(
          storeRef.collection('followers').doc(userId),
          {
            userId,
            userName: userData?.displayName ?? 'ユーザー',
            followedAt: FieldValue.serverTimestamp(),
          },
        );
        followBatch.update(targetUserRef, {
          followedStoreIds: FieldValue.arrayUnion(storeId),
          updatedAt: FieldValue.serverTimestamp(),
        });
        await followBatch.commit();
        console.log(`[nfcCheckin] Auto-followed store ${storeId} for user ${userId}`);
      }
    } catch (e) {
      console.error('[nfcCheckin] auto-follow error:', e);
    }

    // スタンプ達成クーポン自動付与を削除（廃止）。常に空配列を返す
    const awardedCoupons: Array<{ couponId: string; title: string; discountValue: number }> = [];

    // 友達紹介コイン付与（初回スタンプ時）
    try {
      let referralAwardedInviteeCoins = 5;
      let referralAwardedInviterCoins = 5;
      let pendingReferralDocRef: FirebaseFirestore.DocumentReference | null = null;

      const pendingReferralSnap = await db
        .collection(REFERRAL_USES_COLLECTION)
        .where('referredUserId', '==', userId)
        .where('status', '==', 'pending')
        .limit(1)
        .get();
      if (!pendingReferralSnap.empty) {
        pendingReferralDocRef = pendingReferralSnap.docs[0].ref;
        const plannedCoins = pendingReferralSnap.docs[0].data()?.plannedCoins;
        if (typeof plannedCoins?.invitee === 'number') {
          referralAwardedInviteeCoins = plannedCoins.invitee;
        }
        if (typeof plannedCoins?.inviter === 'number') {
          referralAwardedInviterCoins = plannedCoins.inviter;
        }
      }

      let referralCoinJustAwarded = false;
      let referralReferredByUid: string | null = null;

      await db.runTransaction(async (refTxn) => {
        const refUserSnap = await refTxn.get(targetUserRef);
        if (!refUserSnap.exists) return;
        const refUserData = refUserSnap.data() as Record<string, unknown>;
        const referredBy = typeof refUserData.referredBy === 'string' ? refUserData.referredBy : null;
        const alreadyAwarded = refUserData.referralCoinAwarded === true;
        if (!referredBy || alreadyAwarded) return;

        const referrerRef = db.collection(USERS_COLLECTION).doc(referredBy);
        const referrerSnap = await refTxn.get(referrerRef);
        if (!referrerSnap.exists) return;

        const refNow = new Date();
        const refExpiresAt = new Date(refNow.getTime() + 180 * 24 * 60 * 60 * 1000);

        refTxn.update(targetUserRef, {
          coins: FieldValue.increment(referralAwardedInviteeCoins),
          coinLastEarnedAt: Timestamp.fromDate(refNow),
          coinExpiresAt: Timestamp.fromDate(refExpiresAt),
          referralCoinAwarded: true,
          updatedAt: FieldValue.serverTimestamp(),
        });
        refTxn.update(referrerRef, {
          coins: FieldValue.increment(referralAwardedInviterCoins),
          coinLastEarnedAt: Timestamp.fromDate(refNow),
          coinExpiresAt: Timestamp.fromDate(refExpiresAt),
          referralEarningsPoints: FieldValue.increment(referralAwardedInviterCoins),
          updatedAt: FieldValue.serverTimestamp(),
        });

        referralCoinJustAwarded = true;
        referralReferredByUid = referredBy;
      });

      if (referralCoinJustAwarded && referralReferredByUid) {
        if (pendingReferralDocRef) {
          await pendingReferralDocRef.update({
            status: 'awarded',
            awardedAt: FieldValue.serverTimestamp(),
          });
        }

        const [refereeUserDoc, referrerUserDoc] = await Promise.all([
          targetUserRef.get(),
          db.collection(USERS_COLLECTION).doc(referralReferredByUid).get(),
        ]);
        const refereeName =
          typeof refereeUserDoc.data()?.displayName === 'string'
            ? (refereeUserDoc.data()!.displayName as string).trim() || '友達'
            : '友達';
        const referrerName =
          typeof referrerUserDoc.data()?.displayName === 'string'
            ? (referrerUserDoc.data()!.displayName as string).trim() || '友達'
            : '友達';

        const refereeNotifRef = targetUserRef.collection('notifications').doc();
        await refereeNotifRef.set({
          id: refereeNotifRef.id,
          userId,
          title: 'ようこそぐるまっぷへ！',
          body: `${referrerName}さんの紹介でアプリを始めました。NFCタグにタッチして新しいお店を発見してみましょう！`,
          type: 'social',
          createdAt: new Date().toISOString(),
          isRead: false,
          isDelivered: true,
          data: { source: 'user', reason: 'friend_referral' },
          tags: ['referral'],
        });

        const referrerNotifRef = db
          .collection(USERS_COLLECTION)
          .doc(referralReferredByUid)
          .collection('notifications')
          .doc();
        await referrerNotifRef.set({
          id: referrerNotifRef.id,
          userId: referralReferredByUid,
          title: 'お友達が登録しました！',
          body: `${refereeName}さんがぐるまっぷに参加しました。一緒に街を探検しましょう！`,
          type: 'social',
          createdAt: new Date().toISOString(),
          isRead: false,
          isDelivered: true,
          data: { source: 'user', reason: 'friend_referral' },
          tags: ['referral'],
        });

        console.log(
          `[nfcCheckin] Referral notification sent: referee=${userId}, referrer=${referralReferredByUid}`,
        );
      }
    } catch (e) {
      console.error('[nfcCheckin] referral coin award error:', e);
    }

    // ユーザークーポンの利用処理（selectedUserCouponIds）
    const usedCoupons: Array<{ docId: string; title: string; discountValue: number }> = [];
    let usageVerificationCode: string | null = null;

    if (selectedUserCouponIds.length > 0) {
      try {
        for (const couponDocId of selectedUserCouponIds) {
          const userCouponRef = db.collection('user_coupons').doc(couponDocId);
          const userCouponSnap = await userCouponRef.get();
          if (!userCouponSnap.exists) continue;
          const couponData = userCouponSnap.data() as Record<string, unknown>;

          // 自分のクーポンか検証
          if (couponData['userId'] !== userId) continue;
          // この店舗のクーポンか検証
          if (couponData['storeId'] !== storeId) continue;
          // 未使用か検証
          if (couponData['isUsed'] === true) continue;

          // 使用済みに更新
          await userCouponRef.update({
            isUsed: true,
            usedAt: FieldValue.serverTimestamp(),
            usedVia: 'nfc_checkin',
          });

          usedCoupons.push({
            docId: couponDocId,
            title: typeof couponData['title'] === 'string' ? couponData['title'] : 'クーポン',
            discountValue: typeof couponData['discountValue'] === 'number' ? couponData['discountValue'] : 0,
          });
        }

        // 目視確認用ワンタイムコード生成（6桁）
        if (usedCoupons.length > 0) {
          usageVerificationCode = String(randomInt(100000, 999999));
        }

        console.log(
          `[nfcCheckin] Used ${usedCoupons.length} user coupons for user=${userId}, store=${storeId}`,
        );
      } catch (e) {
        console.error('[nfcCheckin] user coupon usage error:', e);
      }
    }

    console.log(
      `[nfcCheckin] Success: user=${userId}, store=${storeId}, isFirstVisit=${result.isFirstVisit}`,
    );

    return {
      storeName: result.storeName,
      stampsAfter: result.stampsAfter,
      cardCompleted: result.cardCompleted,
      isFirstVisit: result.isFirstVisit,
      awardedCoupons,
      usedCoupons,
      usageVerificationCode,
      hiddenExplorerIncremented,
    };
  },
);

// NFCタグ登録（管理者用）
export const registerNfcTag = onCall(
  {
    region: 'asia-northeast1',
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Must be authenticated');
    }

    const adminUserId = request.auth.uid;
    const adminUserSnap = await db.collection(USERS_COLLECTION).doc(adminUserId).get();
    if (!adminUserSnap.exists || adminUserSnap.data()?.isOwner !== true) {
      throw new HttpsError('permission-denied', 'Only admin owners can register NFC tags');
    }

    const { storeId, tagSecret, tagUid } = request.data || {};
    if (!storeId || !tagSecret) {
      throw new HttpsError('invalid-argument', 'Missing required parameters: storeId and tagSecret');
    }
    if (typeof tagSecret !== 'string' || tagSecret.length < 16) {
      throw new HttpsError('invalid-argument', 'tagSecret must be at least 16 characters');
    }

    // 店舗の存在確認
    const storeSnap = await db.collection('stores').doc(storeId).get();
    if (!storeSnap.exists) {
      throw new HttpsError('not-found', 'Store not found');
    }

    // 既存タグの確認（同じ店舗に既にタグがある場合は無効化）
    const existingTags = await db
      .collection(NFC_TAGS_COLLECTION)
      .where('storeId', '==', storeId)
      .where('isActive', '==', true)
      .get();

    const batch = db.batch();
    for (const existingTag of existingTags.docs) {
      batch.update(existingTag.ref, {
        isActive: false,
        deactivatedAt: FieldValue.serverTimestamp(),
      });
    }

    // 新しいタグを登録
    const tagRef = db.collection(NFC_TAGS_COLLECTION).doc();
    batch.set(tagRef, {
      storeId,
      tagSecret,
      tagUid: tagUid || null,
      isActive: true,
      createdAt: FieldValue.serverTimestamp(),
      createdBy: adminUserId,
    });

    // 店舗にタグIDを紐づけ
    batch.update(db.collection('stores').doc(storeId), {
      nfcTagId: tagRef.id,
      updatedAt: FieldValue.serverTimestamp(),
    });

    await batch.commit();

    console.log(`[registerNfcTag] Registered tag ${tagRef.id} for store ${storeId} by ${adminUserId}`);

    return {
      tagId: tagRef.id,
      storeId,
      nfcUrl: `https://groumapapp.web.app/checkin?storeId=${storeId}&secret=${tagSecret}`,
    };
  },
);

// ============================================================
// generateMonthlyReport
// Scheduled: 毎月末 23:00 JST（UTC 14:00、月末最終日）
// ============================================================
export const generateMonthlyReport = onSchedule(
  {
    schedule: '0 14 28-31 * *',
    timeZone: 'Asia/Tokyo',
    memory: '512MiB',
    timeoutSeconds: 540,
  },
  async () => {
    const now = new Date();
    // 月末最終日のみ実行（28〜31日スケジュールなので最終日以外はスキップ）
    const tomorrow = new Date(now);
    tomorrow.setDate(now.getDate() + 1);
    if (tomorrow.getMonth() === now.getMonth()) {
      // 翌日が同月 → 最終日ではない
      console.log('[generateMonthlyReport] Not the last day of month. Skipping.');
      return;
    }

    const yearMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
    console.log(`[generateMonthlyReport] Starting for yearMonth=${yearMonth}`);

    const GENRE_GROUPS: Record<string, string[]> = {
      'cafe_sweets': ['カフェ・喫茶店', 'スイーツ', 'ケーキ', 'タピオカ', 'パン・サンドイッチ'],
      'washoku': ['和食', '日本料理', '海鮮', '寿司', 'そば', 'うどん', 'うなぎ', '天ぷら'],
      'izakaya_bar': ['居酒屋', 'バー・お酒', 'スナック'],
      'yakitori_age': ['焼き鳥', 'とんかつ', '串揚げ', 'お好み焼き', 'もんじゃ焼き'],
      'nabe_yakiniku': ['しゃぶしゃぶ', '鍋', '焼肉', 'ホルモン'],
      'ramen_chinese': ['ラーメン', '中華料理', '餃子'],
      'asian_ethnic': ['韓国料理', 'タイ料理', 'カレー', '沖縄料理'],
      'western_french': ['レストラン', '洋食', 'フレンチ', 'スペイン料理', 'ビストロ'],
      'italian_meat': ['パスタ', 'ピザ', 'ステーキ', 'ハンバーグ', 'ハンバーガー'],
      'shokudo_other': ['ビュッフェ', '食堂', '料理旅館', 'その他'],
    };

    // 今月の開始・終了Timestamp
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
    const monthEnd = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59);
    const monthStartTs = Timestamp.fromDate(monthStart);
    const monthEndTs = Timestamp.fromDate(monthEnd);

    // 全店舗データを取得（ジャンル/エリア集計用）
    const allStoresSnap = await db.collection('stores')
      .where('isActive', '==', true)
      .where('isApproved', '==', true)
      .get();

    const storeDataMap: Record<string, { category: string; areaId: string | null; name: string; rarity?: number; discoveredCount: number }> = {};
    for (const doc of allStoresSnap.docs) {
      const d = doc.data();
      if (d['isOwner'] === true) continue;
      storeDataMap[doc.id] = {
        category: (d['category'] as string) ?? '',
        areaId: (d['areaId'] as string | null) ?? null,
        name: (d['name'] as string) ?? '',
        rarity: d['rarityOverride'] as number | undefined,
        discoveredCount: (d['discoveredCount'] as number) ?? 0,
      };
    }

    // エリア名マップを取得
    const areasSnap = await db.collection('areas').get();
    const areaNameMap: Record<string, string> = {};
    for (const doc of areasSnap.docs) {
      const d = doc.data();
      areaNameMap[doc.id] = (d['name'] as string) ?? doc.id;
    }

    // コミュニティデータ集計（今月全体の新規firstVisitAt件数）
    let communityDiscoveredCount = 0;
    // 全 store_users をスキャンして今月の新規発見を集計
    // （全体件数が多い場合はサンプリングだが、ここでは全件処理）
    // NOTE: 大規模運用時はCloud Firestoreの集計クエリへの移行を検討
    const storeIds = Object.keys(storeDataMap);
    for (const sid of storeIds) {
      const usersSnap = await db.collection('store_users').doc(sid).collection('users')
        .where('firstVisitAt', '>=', monthStartTs)
        .where('firstVisitAt', '<=', monthEndTs)
        .get();
      communityDiscoveredCount += usersSnap.size;
    }

    // 今月新規追加店舗数
    const newStoresSnap = await db.collection('stores')
      .where('isActive', '==', true)
      .where('isApproved', '==', true)
      .where('approvedAt', '>=', monthStartTs)
      .where('approvedAt', '<=', monthEndTs)
      .get();
    const newStoresAddedCount = newStoresSnap.size;

    // コミュニティドキュメントを書き込み
    const communityData = {
      yearMonth,
      communityDiscoveredCount,
      communityExplorationRateDelta: 0, // 将来: 先月比計算
      communityVisitsDelta: 0,          // 将来: 先月比計算
      newStoresAddedCount,
      generatedAt: FieldValue.serverTimestamp(),
    };
    await db.collection('monthly_reports_community').doc(yearMonth).set(communityData, { merge: true });
    console.log(`[generateMonthlyReport] Community data written: discovered=${communityDiscoveredCount}`);

    // アクティブユーザー一覧取得（過去30日以内にログイン）
    const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
    const thirtyDaysAgoTs = Timestamp.fromDate(thirtyDaysAgo);
    const usersSnap = await db.collection(USERS_COLLECTION)
      .where('lastLoginAt', '>=', thirtyDaysAgoTs)
      .get();

    console.log(`[generateMonthlyReport] Active users: ${usersSnap.size}`);

    const BATCH_SIZE = 100;
    const userDocs = usersSnap.docs;
    let processedCount = 0;
    let errorCount = 0;

    for (let i = 0; i < userDocs.length; i += BATCH_SIZE) {
      const chunk = userDocs.slice(i, i + BATCH_SIZE);
      await Promise.all(chunk.map(async (userDoc) => {
        const uid = userDoc.id;
        try {
          const userData = userDoc.data();
          const totalDiscoveredCount = (userData['discoveredStoreCount'] as number) ?? 0;
          const fcmToken = (userData['fcmToken'] as string | null) ?? null;

          // 今月来店したstore_usersを集計
          let monthlyDiscoveredCount = 0;
          let totalVisitsThisMonth = 0;
          let hotStoresCount = 0;
          let legendDiscoveredCount = 0;
          const visitedAreaIds = new Set<string>();
          const genreVisitCounts: Record<string, number> = {};
          const communityContributionCount_user: number[] = [];

          for (const sid of storeIds) {
            const visitRef = db.collection('store_users').doc(sid).collection('users').doc(uid);
            const visitSnap = await visitRef.get();
            if (!visitSnap.exists) continue;

            const vd = visitSnap.data()!;
            const firstVisitAt = vd['firstVisitAt'] as Timestamp | undefined;

            // 今月の訪問記録（users/{uid}/stores/{storeId} で来店回数確認）
            const userStoreRef = db.collection(USERS_COLLECTION).doc(uid).collection('stores').doc(sid);
            const userStoreSnap = await userStoreRef.get();
            const userStoreTotalVisits = userStoreSnap.exists ? ((userStoreSnap.data()!['totalVisits'] as number) ?? 0) : 0;

            // 今月の来店数を推定（totalVisits は累計なので今月分の正確な算出は困難。
            // store_users の lastVisitAt が今月以内のものを今月の来店として集計）
            const lastVisitAt = vd['lastVisitAt'] as Timestamp | undefined;
            const isVisitedThisMonth = lastVisitAt
              ? lastVisitAt.toDate() >= monthStart && lastVisitAt.toDate() <= monthEnd
              : false;

            if (isVisitedThisMonth) {
              totalVisitsThisMonth += 1; // 来店1件としてカウント
            }

            // 今月初回発見
            if (firstVisitAt && firstVisitAt.toDate() >= monthStart && firstVisitAt.toDate() <= monthEnd) {
              monthlyDiscoveredCount += 1;
              communityContributionCount_user.push(1);

              // エリア
              const storeInfo = storeDataMap[sid];
              if (storeInfo?.areaId && areaNameMap[storeInfo.areaId]) {
                visitedAreaIds.add(areaNameMap[storeInfo.areaId]);
              }

              // レジェンド発見
              const discoveredCount = storeInfo?.discoveredCount ?? 0;
              const rarity = storeInfo?.rarity ?? (discoveredCount === 0 ? 4 : discoveredCount <= 5 ? 3 : discoveredCount <= 20 ? 2 : 1);
              if (rarity === 4) legendDiscoveredCount += 1;

              // ジャンル集計
              const cat = storeInfo?.category ?? '';
              for (const [genre, cats] of Object.entries(GENRE_GROUPS)) {
                if (cats.includes(cat)) {
                  genreVisitCounts[genre] = (genreVisitCounts[genre] ?? 0) + 1;
                  break;
                }
              }
            }

            // 炎マーク（10回以上来店）
            if (userStoreTotalVisits >= 10) {
              hotStoresCount += 1;
            }
          }

          // topGenre 算出
          let topGenre: string | null = null;
          let topGenreCount = 0;
          for (const [g, c] of Object.entries(genreVisitCounts)) {
            if (c > topGenreCount) {
              topGenreCount = c;
              topGenre = g;
            }
          }

          // 来月おすすめ店舗（未訪問のレジェンド/エピック 最大3件）
          const recommendedStores: { storeId: string; storeName: string; category: string; rarity: number; areaId: string | null }[] = [];
          for (const [sid, info] of Object.entries(storeDataMap)) {
            if (recommendedStores.length >= 3) break;
            const visitRef = db.collection('store_users').doc(sid).collection('users').doc(uid);
            const visited = (await visitRef.get()).exists;
            if (visited) continue;

            const rarity = info.rarity ?? (info.discoveredCount === 0 ? 4 : info.discoveredCount <= 5 ? 3 : info.discoveredCount <= 20 ? 2 : 1);
            if (rarity >= 3) {
              recommendedStores.push({
                storeId: sid,
                storeName: info.name,
                category: info.category,
                rarity,
                areaId: info.areaId,
              });
            }
          }

          // レポートドキュメントを書き込み
          const reportData = {
            userId: uid,
            yearMonth,
            generatedAt: FieldValue.serverTimestamp(),
            monthlyDiscoveredCount,
            totalDiscoveredCount,
            topGenre,
            topGenreCount,
            visitedAreas: Array.from(visitedAreaIds),
            legendDiscoveredCount,
            communityContributionCount: communityContributionCount_user.length,
            totalVisitsThisMonth,
            hotStoresCount,
            communityDiscoveredCount,
            communityExplorationRateDelta: 0,
            communityVisitsDelta: 0,
            newStoresAddedCount,
            recommendedStores,
          };

          await db.collection('monthly_reports').doc(uid).collection('reports').doc(yearMonth).set(reportData, { merge: true });
          processedCount++;

          // FCM プッシュ通知送信
          const notificationsEnabled = (userData['notificationSettings'] as Record<string, unknown> | undefined)?.['pushEnabled'] !== false;
          if (fcmToken && notificationsEnabled && monthlyDiscoveredCount > 0) {
            try {
              await messaging.send({
                token: fcmToken,
                notification: {
                  title: '今月の探検まとめが届きました！',
                  body: `今月は${monthlyDiscoveredCount}店舗を新たに発見！コミュニティと一緒に街を開拓しました`,
                },
                data: {
                  type: 'monthly_report',
                  yearMonth,
                  click_action: `/monthly_report/${yearMonth}`,
                },
                apns: {
                  payload: {
                    aps: {
                      sound: 'default',
                      badge: 1,
                    },
                  },
                },
              });
            } catch (fcmErr) {
              console.warn(`[generateMonthlyReport] FCM error for user=${uid}:`, fcmErr);
            }
          }
        } catch (err) {
          errorCount++;
          console.error(`[generateMonthlyReport] Error for user=${uid}:`, err);
        }
      }));
    }

    // 管理ログを記録
    await db.collection('admin_logs').add({
      type: 'generateMonthlyReport',
      yearMonth,
      processedCount,
      errorCount,
      totalUsers: userDocs.length,
      createdAt: FieldValue.serverTimestamp(),
    });

    console.log(`[generateMonthlyReport] Completed: processed=${processedCount}, errors=${errorCount}`);
  },
);

// ============================================================
// checkWeeklyMission
// 週次ミッション達成チェック（NFC チェックイン後に Flutter から呼び出し）
// 条件1: 今週に未訪問店舗へ初来店 >= 1件
// 条件2: 今週の来店合計 >= 3回
// 達成時: badge_progress 更新 + バッジ付与 + 発見ヒント通知
// ============================================================
export const checkWeeklyMission = onCall(
  {
    region: 'asia-northeast1',
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    const userId = request.auth.uid;

    // 今週の月曜日を JST で計算
    const now = new Date();
    const jstNow = new Date(now.getTime() + 9 * 60 * 60 * 1000);
    const dayOfWeek = jstNow.getUTCDay(); // 0=日曜, 1=月曜...
    const daysFromMonday = dayOfWeek === 0 ? 6 : dayOfWeek - 1;
    const weekStartJst = new Date(jstNow);
    weekStartJst.setUTCDate(jstNow.getUTCDate() - daysFromMonday);
    weekStartJst.setUTCHours(0, 0, 0, 0);
    const weekStart = new Date(weekStartJst.getTime() - 9 * 60 * 60 * 1000); // JST → UTC

    // 週ID (e.g., "2026-W10")
    const weekYear = weekStartJst.getUTCFullYear();
    const jan1 = new Date(Date.UTC(weekYear, 0, 1));
    const weekNum = Math.ceil(((weekStartJst.getTime() - jan1.getTime()) / 86400000 + jan1.getUTCDay() + 1) / 7);
    const weekId = `${weekYear}-W${String(weekNum).padStart(2, '0')}`;

    // 既に今週達成済みか確認
    const weeklyProgressRef = db.collection('weekly_mission_progress').doc(userId);
    const weeklyProgressSnap = await weeklyProgressRef.get();
    const weeklyData = weeklyProgressSnap.data() ?? {};
    const achievedWeeks = (weeklyData['achievedWeeks'] as string[] | undefined) ?? [];

    const totalAchievedCount = asInt(weeklyData['totalAchievedCount'], 0);

    if (achievedWeeks.includes(weekId)) {
      return {
        achieved: false,
        newlyAchieved: false,
        weeklyMissionCount: totalAchievedCount,
        alreadyAchievedThisWeek: true,
        progress: null,
      };
    }

    // ユーザーの今週の来店データを取得
    const userStoresSnap = await db.collection(USERS_COLLECTION).doc(userId).collection('stores').get();

    let newStoresThisWeek = 0;
    let totalVisitsThisWeek = 0;

    for (const storeDoc of userStoresSnap.docs) {
      const sd = storeDoc.data();
      const lastVisited = sd['lastVisited'] as Timestamp | undefined;

      if (lastVisited && lastVisited.toDate() >= weekStart) {
        totalVisitsThisWeek++;

        // 初回訪問かチェック（store_users/{storeId}/users/{userId}.firstVisitAt）
        const storeId = storeDoc.id;
        const storeUserSnap = await db.collection('store_users').doc(storeId).collection('users').doc(userId).get();
        if (storeUserSnap.exists) {
          const firstVisitAt = storeUserSnap.data()!['firstVisitAt'] as Timestamp | undefined;
          if (firstVisitAt && firstVisitAt.toDate() >= weekStart) {
            newStoresThisWeek++;
          }
        }
      }
    }

    const progress = { newStoresThisWeek, totalVisitsThisWeek };

    // ミッション達成判定
    // 条件1: 未訪問店舗への初来店 >= 1件
    // 条件2: 今週の来店合計 >= 3回
    const missionAchieved = newStoresThisWeek >= 1 && totalVisitsThisWeek >= 3;

    if (!missionAchieved) {
      return {
        achieved: false,
        newlyAchieved: false,
        weeklyMissionCount: totalAchievedCount,
        alreadyAchievedThisWeek: false,
        progress,
      };
    }

    // 達成処理
    const newTotalCount = totalAchievedCount + 1;

    // weekly_mission_progress 更新
    await weeklyProgressRef.set({
      userId,
      totalAchievedCount: FieldValue.increment(1),
      achievedWeeks: FieldValue.arrayUnion(weekId),
      lastAchievedAt: FieldValue.serverTimestamp(),
    }, { merge: true });

    // badge_progress/{userId}_weeklyMission 更新
    const badgeProgressRef = db.collection('badge_progress').doc(`${userId}_weeklyMission`);
    await badgeProgressRef.set({
      userId,
      badgeType: 'weeklyMission',
      currentValue: FieldValue.increment(1),
      lastUpdated: FieldValue.serverTimestamp(),
    }, { merge: true });

    const badgeProgressSnap = await badgeProgressRef.get();
    const badgeCount = asInt(badgeProgressSnap.data()?.['currentValue'], 0);

    // バッジ付与チェック
    const weeklyBadgeThresholds: Array<[string, number]> = [
      ['weekly_mission_1', 1],
      ['weekly_mission_5', 5],
      ['weekly_mission_10', 10],
      ['weekly_mission_25', 25],
    ];

    const newBadges: string[] = [];
    for (const [badgeId, threshold] of weeklyBadgeThresholds) {
      if (badgeCount >= threshold) {
        const badgeRef = db.collection('user_badges').doc(userId).collection('badges').doc(badgeId);
        const snap = await badgeRef.get();
        if (!snap.exists) {
          await badgeRef.set({
            userId,
            badgeId,
            unlockedAt: FieldValue.serverTimestamp(),
            progress: badgeCount,
            requiredValue: threshold,
            isNew: true,
          });
          newBadges.push(badgeId);
          console.log(`[checkWeeklyMission] Badge awarded: ${badgeId} to user=${userId}`);
        }
      }
    }

    // 発見ヒント通知（近くの未発見レジェンド/エピック店舗）
    try {
      const userDoc = await db.collection(USERS_COLLECTION).doc(userId).get();
      const fcmToken = (userDoc.data()?.['fcmToken'] as string | null) ?? null;
      const notificationsEnabled =
        (userDoc.data()?.['notificationSettings'] as Record<string, unknown> | undefined)?.['pushEnabled'] !== false;

      if (fcmToken && notificationsEnabled) {
        const allStoresSnap = await db.collection('stores')
          .where('isActive', '==', true)
          .where('isApproved', '==', true)
          .get();

        let hintStoreName: string | null = null;
        let hintStoreCategory: string | null = null;

        for (const storeDoc of allStoresSnap.docs) {
          const sd = storeDoc.data();
          if (sd['isOwner'] === true) continue;

          const visitSnap = await db.collection('store_users').doc(storeDoc.id).collection('users').doc(userId).get();
          if (visitSnap.exists) continue;

          const discoveredCount = asInt(sd['discoveredCount'], 0);
          const rarityOverride = sd['rarityOverride'] as number | undefined;
          const rarity = rarityOverride ?? (discoveredCount === 0 ? 4 : discoveredCount <= 5 ? 3 : discoveredCount <= 20 ? 2 : 1);

          if (rarity >= 3) {
            hintStoreName = (sd['name'] as string) ?? null;
            hintStoreCategory = (sd['category'] as string) ?? null;
            break;
          }
        }

        const bodyText = hintStoreName
          ? `${hintStoreCategory ? `カテゴリ：${hintStoreCategory}系` : 'レジェンド店舗'}「${hintStoreName}」が光っています！マップを開いて確認しよう`
          : 'マップを開いて近くの未発見店舗を探してみましょう！';

        await messaging.send({
          token: fcmToken,
          notification: {
            title: '週次ミッション達成！発見ヒントが届きました',
            body: bodyText,
          },
          data: {
            type: 'weekly_mission_achieved',
            weekId,
            badgeCount: String(newTotalCount),
          },
          apns: {
            payload: {
              aps: {
                sound: 'default',
                badge: 1,
              },
            },
          },
        });
      }
    } catch (notifErr) {
      console.warn(`[checkWeeklyMission] Notification error for user=${userId}:`, notifErr);
    }

    console.log(`[checkWeeklyMission] Mission achieved: user=${userId}, weekId=${weekId}, count=${newTotalCount}, newBadges=${newBadges.join(',')}`);

    return {
      achieved: true,
      newlyAchieved: true,
      weeklyMissionCount: newTotalCount,
      alreadyAchievedThisWeek: false,
      newBadges,
      progress,
    };
  },
);
