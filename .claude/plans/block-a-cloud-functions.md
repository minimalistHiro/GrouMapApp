# ブロックA: Cloud Functions 変更プラン

作成日: 2026-03-05
対象ファイル: `backend/functions/src/index.ts`（単一ファイル）

---

## 変更概要

| # | タスク | 関数 | 影響行（参考） |
|---|--------|------|--------------|
| 1 | `isFirstVisit` フラグ追加 + `discoveredCount` インクリメント | `nfcCheckin` | L4159-4234 |
| 2 | `visitorCount` バグ確認（既に修正済みの可能性あり） | `nfcCheckin` / `punchStamp` | L4192 / L2591 |
| 3 | スタンプ付与を全停止（全ユーザー・全店舗） | `nfcCheckin` / `punchStamp` | L4172-4188 / L2527-2587 |
| 4 | 来店ボーナスコイン付与を削除 | `nfcCheckin` | L4236-4250 |
| 5 | スタンプ達成クーポン自動付与を削除 | `nfcCheckin` / `punchStamp` | L4365-4411 / L2846-2887 |
| 6 | 自動フォローの source を `nfc_checkin` に変更 | `nfcCheckin` | L4344 |
| 7 | 戻り値・achievement イベントのスタンプ関連フィールドを整理 | `nfcCheckin` / `punchStamp` | L4226-4233 / L2693-2700 |

---

## 事前確認事項（実装前にチェック）

### visitorCount バグについて

`kpi-redefinition.md` では「`updateStoreDailyStats` が type='stamp' を除外している」と記述されているが、
現在のコードを確認すると:

- `nfcCheckin` L4192-4201: トランザクション内で `visitorCount: FieldValue.increment(1)` を**既に実施**
- `punchStamp` L2590-2600: 同様に**既に実施**

→ **nfcCheckin / punchStamp 側のバグは存在しない可能性が高い**。
別途 `updateStoreDailyStats` という Firestore トリガー関数が存在するかを検索して確認すること。
存在する場合は、その関数内の条件分岐も修正対象となる。

---

## 1. nfcCheckin の変更

### 1-1. トランザクション内: isFirstVisit 追加 + スタンプ削除（L4159-4234）

#### 削除するロジック

```typescript
// 以下を削除
const currentStamps = asInt(targetStoreSnap.data()?.['stamps'], 0);
const stampsAdded = 1;
const nextStamps = currentStamps + 1;
const cardCompleted = nextStamps % MAX_STAMPS === 0;
```

#### 追加するロジック

```typescript
// isFirstVisit 判定（storeUserStatsSnap.exists の否定）
const isFirstVisit = !storeUserStatsSnap.exists;

// 初発見時: stores/{storeId}.discoveredCount を +1
if (isFirstVisit) {
  txn.update(storeRef, {
    discoveredCount: FieldValue.increment(1),
    updatedAt: FieldValue.serverTimestamp(),
  });
}
```

#### txn.set(targetStoreRef, ...) の変更

```typescript
// Before: stamps/stampsAdded/nextStamps/cardCompleted を含む
txn.set(
  targetStoreRef,
  stripUndefined({
    storeId,
    storeName: storeName || undefined,
    stamps: nextStamps,          // ← 削除
    lastStampDate: todayJst,
    lastVisited: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  }),
  { merge: true },
);

// After: stamps を削除（lastStampDate は 1日1回制限チェックに必要なため残す）
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
```

#### トランザクションの return 変更

```typescript
// Before:
return {
  userId,
  storeId,
  storeName,
  stampsAdded,
  stampsAfter: nextStamps,
  cardCompleted,
};

// After:
return {
  userId,
  storeId,
  storeName,
  isFirstVisit,
};
```

---

### 1-2. コイン付与ブロックを削除（L4236-4250）

```typescript
// 以下のブロックを丸ごと削除
// 来店ボーナスコイン +1
let coinsAdded = 0;
try {
  const coinNow = new Date();
  const coinExpiresAt = new Date(coinNow.getTime() + 180 * 24 * 60 * 60 * 1000);
  await targetUserRef.update({
    coins: FieldValue.increment(1),
    coinLastEarnedAt: Timestamp.fromDate(coinNow),
    coinExpiresAt: Timestamp.fromDate(coinExpiresAt),
    updatedAt: FieldValue.serverTimestamp(),
  });
  coinsAdded = 1;
} catch (e) {
  console.error('[nfcCheckin] coin bonus error:', e);
}
```

---

### 1-3. achievement event の stamp フィールド整理（L4308-4323）

```typescript
// Before:
await eventRef.set(
  {
    type: 'stamp_punch',
    transactionId: stampTxnRef.id,
    storeId,
    storeName: result.storeName ?? '',
    pointsAwarded: 0,
    stampsAdded: result.stampsAdded ?? 0,   // ← 削除
    stampsAfter: result.stampsAfter ?? 0,   // ← 削除
    cardCompleted: result.cardCompleted ?? false, // ← 削除
    badges,
    createdAt: FieldValue.serverTimestamp(),
    seenAt: null,
  },
  { merge: true },
);

// After:
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
```

---

### 1-4. 自動フォローの source を変更（L4344）

```typescript
// Before:
source: 'stamp',

// After:
source: 'nfc_checkin',
```

---

### 1-5. スタンプ達成クーポン自動付与ブロックを削除（L4365-4411）

```typescript
// 以下のブロックを丸ごと削除
// スタンプ達成特典クーポンの自動付与
const awardedCoupons: Array<{ couponId: string; title: string; discountValue: number }> = [];
if (result.cardCompleted) {
  try {
    ... // クーポン付与処理全体
  } catch (e) {
    console.error('[nfcCheckin] stamp coupon award error:', e);
  }
}

// 代わりに: return で使用するため空配列を宣言
const awardedCoupons: Array<{ couponId: string; title: string; discountValue: number }> = [];
```

---

### 1-6. return の変更（L4584-4590）

```typescript
// Before:
return {
  ...result,
  coinsAdded,
  awardedCoupons,
  usedCoupons,
  usageVerificationCode,
};

// After: coinsAdded を削除
return {
  ...result,        // { userId, storeId, storeName, isFirstVisit }
  awardedCoupons,   // 常に空配列
  usedCoupons,
  usageVerificationCode,
};
```

---

### 1-7. console.log の更新（L4580-4582）

```typescript
// Before:
console.log(`[nfcCheckin] Success: user=${userId}, store=${storeId}, stamps=${result.stampsAfter}, coins=${coinsAdded}`);

// After:
console.log(`[nfcCheckin] Success: user=${userId}, store=${storeId}, isFirstVisit=${result.isFirstVisit}`);
```

---

## 2. punchStamp の変更

### 2-1. トランザクション内: スタンプ計算削除（L2527-2530）

```typescript
// 削除:
const currentStamps = asInt(targetStoreSnap.data()?.['stamps'], 0);
const stampsAdded = 1;
const nextStamps = currentStamps + 1;
const cardCompleted = nextStamps % MAX_STAMPS === 0;
```

### 2-2. txn.set(targetStoreRef, ...) の変更（L2576-2588）

```typescript
// Before: stamps: nextStamps を含む
txn.set(
  targetStoreRef,
  stripUndefined({
    storeId,
    storeName: storeName || undefined,
    stamps: nextStamps,          // ← 削除
    lastStampDate: todayJst,
    lastVisited: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  }),
  { merge: true },
);

// After:
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
```

### 2-3. トランザクションの return 変更（L2693-2700）

```typescript
// Before:
return {
  userId,
  storeId,
  storeName,
  stampsAdded,
  stampsAfter: nextStamps,
  cardCompleted,
};

// After:
return {
  userId,
  storeId,
  storeName,
};
```

### 2-4. achievement event の stamp フィールド整理（L2783-2798）

```typescript
// Before:
await eventRef.set(
  {
    type: 'stamp_punch',
    ...
    stampsAdded: result.stampsAdded ?? 0,
    stampsAfter: result.stampsAfter ?? 0,
    cardCompleted: result.cardCompleted ?? false,
    ...
  },
);

// After:
await eventRef.set(
  {
    type: 'punch_checkin',
    ...
    // stamp関連フィールド削除
    ...
  },
);
```

### 2-5. スタンプ達成クーポン自動付与ブロックを削除（L2846-2887）

`if (result.cardCompleted) { ... }` ブロック全体を削除。

### 2-6. 自動フォローの source を変更（L2825）

```typescript
// Before:
source: 'stamp',

// After:
source: 'punch_checkin',
```

---

## 3. Flutter 側の対応（ブロックBで対応・参考）

`nfcCheckin` の戻り値変更に伴い、Flutter 側の `NfcCheckinResult` モデルも更新が必要:

```dart
// lib/services/nfc_checkin_service.dart
class NfcCheckinResult {
  // 削除: stampsAfter, cardCompleted, coinsAdded
  // 追加: isFirstVisit
  final bool isFirstVisit;
  final String storeName;
  final List<Map<String, dynamic>> awardedCoupons;
  final List<Map<String, dynamic>> usedCoupons;
  final String? usageVerificationCode;
}
```

---

## 4. Firestore スキーマ追加（FIRESTORE.md 更新）

`stores/{storeId}` に追加するフィールド:

| フィールド | 型 | デフォルト | 説明 |
|-----------|-----|-----------|------|
| `discoveredCount` | int | 0（フィールド自体は初回 nfcCheckin まで存在しない） | NFCチェックイン初回来店ユニーク数 |
| `rarityOverride` | int \| null | null | 管理者手動レア度（1=コモン/2=レア/3=エピック/4=レジェンド） |

---

## 5. 実装の注意事項

### 変更しないもの（重要）

- `store_users/{storeId}/users/{userId}` ドキュメント生成ロジック（firstVisitAt/totalVisits）→ 来店記録のため維持
- `stores/{storeId}/transactions` への type:'stamp' レコード作成 → KPI集計のため維持
- `store_stats/daily.visitorCount` のインクリメント → 既に正しく動作
- 友達紹介コイン付与（`referralCoinAwarded` ロジック）→ TODO 対象外のため維持
- `user_coupons` の利用処理（`selectedUserCouponIds`）→ 変更なし
- `punchStamp` の `point_requests` 書き込み → 変更なし

### `lastStampDate` について

スタンプを廃止しても **`lastStampDate` フィールドは残す**。
現在「1日1回チェックイン制限」のキーとして使用されているため、
フィールド名を変更すると既存ユーザーが即日2回チェックインできてしまう。
→ フィールド名をそのまま流用し、「最終チェックイン日」として機能させ続ける。

---

## 6. デプロイ手順

```bash
cd /Users/kanekohiroki/Desktop/groumapapp/backend/functions
npm run build
firebase deploy --only functions:nfcCheckin,functions:punchStamp
```

---

## 7. 検証チェックリスト

- [ ] NFCチェックイン後、`stores/{storeId}.discoveredCount` が初回時のみ +1 されること
- [ ] 2回目以降のチェックインで `discoveredCount` が変化しないこと
- [ ] NFCチェックイン後、`users/{uid}.coins` が増加しないこと
- [ ] NFCチェックイン後、`users/{uid}/stores/{storeId}.stamps` が更新されないこと
- [ ] NFCチェックイン後、`store_users` ドキュメントが正しく作成/更新されること
- [ ] NFCチェックイン後、`stores/{storeId}/transactions` に type:'stamp' レコードが作成されること
- [ ] 1日1回制限が引き続き機能すること（2回目はエラーになること）
- [ ] クーポン利用（selectedUserCouponIds）が引き続き機能すること
- [ ] punchStamp でスタンプが付与されないこと
- [ ] 戻り値に `isFirstVisit` が含まれること
- [ ] 自動フォローが `source: 'nfc_checkin'` で記録されること
