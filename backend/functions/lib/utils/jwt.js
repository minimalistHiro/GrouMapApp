"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.issueQRToken = issueQRToken;
exports.verifyQRToken = verifyQRToken;
exports.generateDeviceId = generateDeviceId;
exports.isTokenExpired = isTokenExpired;
exports.getTokenRemainingSeconds = getTokenRemainingSeconds;
const jose_1 = require("jose");
const crypto_1 = require("crypto");
// JWT設定
const JWT_SECRET = process.env.JWT_SECRET || 'groumap-jwt-secret-key-2024';
const JWT_ISSUER = 'groumap-functions';
const JWT_AUDIENCE = 'groumap/qr';
// シークレットキーを生成
const secretKey = new TextEncoder().encode(JWT_SECRET);
/**
 * QRトークンを発行
 */
async function issueQRToken(uid, deviceId, customExpiry) {
    const now = Math.floor(Date.now() / 1000);
    const exp = customExpiry || now + 60; // デフォルト60秒
    const jti = (0, crypto_1.randomBytes)(16).toString('hex'); // 128-bit random hex
    const payload = {
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
    const token = await new jose_1.SignJWT(payload)
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
async function verifyQRToken(token) {
    try {
        const { payload } = await (0, jose_1.jwtVerify)(token, secretKey, {
            audience: JWT_AUDIENCE,
            issuer: JWT_ISSUER,
            clockTolerance: 5, // 5秒のクロックスキュー許容
        });
        // 型チェック
        const qrPayload = payload;
        // 必須フィールドの検証
        if (!qrPayload.sub || !qrPayload.jti || !qrPayload.ver) {
            throw new Error('Invalid token payload: missing required fields');
        }
        // バージョンチェック
        if (qrPayload.ver !== 1) {
            throw new Error('Unsupported token version');
        }
        return qrPayload;
    }
    catch (error) {
        throw new Error(`Token verification failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
}
/**
 * デバイスIDを生成（オプション）
 */
function generateDeviceId(userAgent, platform) {
    return (0, crypto_1.randomBytes)(16).toString('hex');
}
/**
 * トークンの有効性をチェック（期限切れなど）
 */
function isTokenExpired(payload) {
    const now = Math.floor(Date.now() / 1000);
    return payload.exp < now;
}
/**
 * トークンの残り時間を取得（秒）
 */
function getTokenRemainingSeconds(payload) {
    const now = Math.floor(Date.now() / 1000);
    return Math.max(0, payload.exp - now);
}
//# sourceMappingURL=jwt.js.map