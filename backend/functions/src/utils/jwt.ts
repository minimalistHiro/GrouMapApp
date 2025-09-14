import { SignJWT, jwtVerify, JWTPayload } from 'jose';
import { randomBytes } from 'crypto';

// JWT設定
const JWT_SECRET = process.env.JWT_SECRET || 'groumap-jwt-secret-key-2024';
const JWT_ISSUER = 'groumap-functions';
const JWT_AUDIENCE = 'groumap/qr';

// シークレットキーを生成
const secretKey = new TextEncoder().encode(JWT_SECRET);

export interface QRTokenPayload extends JWTPayload {
  sub: string; // user ID
  iat: number; // issued at
  exp: number; // expiration
  jti: string; // JWT ID (random 128-bit hex)
  ver: number; // version
  aud: string; // audience
  iss: string; // issuer
  deviceId?: string; // optional device binding
}

export interface QRTokenResult {
  token: string;
  expiresAt: number;
  jti: string;
}

/**
 * QRトークンを発行
 */
export async function issueQRToken(
  uid: string,
  deviceId?: string,
  customExpiry?: number
): Promise<QRTokenResult> {
  const now = Math.floor(Date.now() / 1000);
  const exp = customExpiry || now + 60; // デフォルト60秒
  const jti = randomBytes(16).toString('hex'); // 128-bit random hex

  const payload: QRTokenPayload = {
    sub: uid,
    iat: now,
    exp: exp,
    jti: jti,
    ver: 1,
    aud: JWT_AUDIENCE,
    iss: JWT_ISSUER,
  };

  // デバイスIDが提供された場合は追加
  if (deviceId) {
    payload.deviceId = deviceId;
  }

  const token = await new SignJWT(payload)
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime(exp)
    .setAudience(JWT_AUDIENCE)
    .setIssuer(JWT_ISSUER)
    .setJti(jti)
    .sign(secretKey);

  return {
    token,
    expiresAt: exp * 1000, // JavaScript Date用にミリ秒に変換
    jti,
  };
}

/**
 * QRトークンを検証
 */
export async function verifyQRToken(token: string): Promise<QRTokenPayload> {
  try {
    const { payload } = await jwtVerify(token, secretKey, {
      audience: JWT_AUDIENCE,
      issuer: JWT_ISSUER,
      clockTolerance: 5, // 5秒のクロックスキュー許容
    });

    // 型チェック
    const qrPayload = payload as QRTokenPayload;
    
    // 必須フィールドの検証
    if (!qrPayload.sub || !qrPayload.jti || !qrPayload.ver) {
      throw new Error('Invalid token payload: missing required fields');
    }

    // バージョンチェック
    if (qrPayload.ver !== 1) {
      throw new Error('Unsupported token version');
    }

    return qrPayload;
  } catch (error) {
    throw new Error(`Token verification failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
  }
}

/**
 * デバイスIDを生成（オプション）
 */
export function generateDeviceId(userAgent?: string, platform?: string): string {
  return randomBytes(16).toString('hex');
}

/**
 * トークンの有効性をチェック（期限切れなど）
 */
export function isTokenExpired(payload: QRTokenPayload): boolean {
  const now = Math.floor(Date.now() / 1000);
  return payload.exp < now;
}

/**
 * トークンの残り時間を取得（秒）
 */
export function getTokenRemainingSeconds(payload: QRTokenPayload): number {
  const now = Math.floor(Date.now() / 1000);
  return Math.max(0, payload.exp - now);
}
