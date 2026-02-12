/* eslint-disable no-console */
const admin = require('firebase-admin');

const args = process.argv.slice(2);
const projectArg = args.find((arg) => arg.startsWith('--project='));
const keyArg = args.find((arg) => arg.startsWith('--key-file='));
const keyFilePath = keyArg ? keyArg.split('=')[1] : null;
const projectIdFromArg = projectArg ? projectArg.split('=')[1] : null;
const projectId =
  projectIdFromArg ||
  process.env.GCLOUD_PROJECT ||
  process.env.GOOGLE_CLOUD_PROJECT ||
  process.env.FIREBASE_PROJECT ||
  (() => {
    try {
      const config = process.env.FIREBASE_CONFIG;
      if (!config) return null;
      const parsed = JSON.parse(config);
      return parsed.projectId || null;
    } catch (_) {
      return null;
    }
  })();

if (!projectId) {
  console.error('Missing project id. Use --project=YOUR_PROJECT_ID');
  process.exit(1);
}

const initOptions = { projectId };
if (keyFilePath) {
  const serviceAccount = require(keyFilePath);
  initOptions.credential = admin.credential.cert(serviceAccount);
}

admin.initializeApp(initOptions);
const db = admin.firestore();

/**
 * 生年月日から年代グループを算出
 */
function calculateAgeGroup(birthDate) {
  const now = new Date();
  let age = now.getFullYear() - birthDate.getFullYear();
  const monthDiff = now.getMonth() - birthDate.getMonth();
  if (monthDiff < 0 || (monthDiff === 0 && now.getDate() < birthDate.getDate())) {
    age--;
  }
  if (age < 20) return '~19';
  if (age < 30) return '20s';
  if (age < 40) return '30s';
  if (age < 50) return '40s';
  if (age < 60) return '50s';
  return '60+';
}

/**
 * check_insコレクションから過去のスタンプ来店をstores/{storeId}/transactionsにバックフィル
 *
 * フィルタークエリがstores/{storeId}/transactionsを参照するため、
 * 過去のスタンプ来店（punchStampで作成されたcheck_ins）にも
 * type='stamp' のトランザクションを作成する。
 *
 * ユニークユーザー/日で集計されるため、同一ユーザー・同日の重複は
 * フィルター結果に影響しない。
 */
async function backfillStampTransactions() {
  console.log(`Project: ${projectId}`);
  console.log('=== バックフィル開始: スタンプ来店トランザクション ===');

  // ユーザープロフィールキャッシュ
  const userCache = new Map();
  // 店舗名キャッシュ
  const storeNameCache = new Map();

  // 既存のstamp transactionを確認（重複防止）
  // storeId -> Set<"userId_YYYY-MM-DD"> で管理
  const existingStampKeys = new Map();

  // 全ストアを取得して名前をキャッシュ
  const storesSnapshot = await db.collection('stores').get();
  for (const doc of storesSnapshot.docs) {
    storeNameCache.set(doc.id, doc.data().name || doc.id);

    // 既存のstampトランザクションを取得
    const existingStamps = await db
      .collection('stores')
      .doc(doc.id)
      .collection('transactions')
      .where('type', '==', 'stamp')
      .get();

    const keys = new Set();
    for (const txn of existingStamps.docs) {
      const data = txn.data();
      if (data.userId && data.createdAt) {
        const ts = data.createdAt.toDate ? data.createdAt.toDate() : new Date(data.createdAt);
        const dateStr = `${ts.getFullYear()}-${String(ts.getMonth() + 1).padStart(2, '0')}-${String(ts.getDate()).padStart(2, '0')}`;
        keys.add(`${data.userId}_${dateStr}`);
      }
    }
    existingStampKeys.set(doc.id, keys);
  }
  console.log(`ストア数: ${storesSnapshot.size}`);

  // check_insコレクションを全取得
  const checkInsSnapshot = await db.collection('check_ins').get();
  console.log(`check_ins総数: ${checkInsSnapshot.size}`);

  let totalCreated = 0;
  let totalSkipped = 0;

  // storeId別にグルーピング
  const checkInsByStore = new Map();
  for (const doc of checkInsSnapshot.docs) {
    const data = doc.data();
    if (!data.storeId || !data.userId) {
      totalSkipped++;
      continue;
    }
    if (!checkInsByStore.has(data.storeId)) {
      checkInsByStore.set(data.storeId, []);
    }
    checkInsByStore.set(data.storeId, [...checkInsByStore.get(data.storeId), data]);
  }

  for (const [storeId, checkIns] of checkInsByStore) {
    const storeName = storeNameCache.get(storeId) || storeId;
    const existing = existingStampKeys.get(storeId) || new Set();

    let batch = db.batch();
    let batchCount = 0;
    let storeCreated = 0;

    for (const checkIn of checkIns) {
      const userId = checkIn.userId;
      const timestamp = checkIn.timestamp || checkIn.createdAt;
      if (!timestamp) {
        totalSkipped++;
        continue;
      }

      const ts = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
      if (isNaN(ts.getTime())) {
        totalSkipped++;
        continue;
      }

      const dateStr = `${ts.getFullYear()}-${String(ts.getMonth() + 1).padStart(2, '0')}-${String(ts.getDate()).padStart(2, '0')}`;
      const key = `${userId}_${dateStr}`;

      // 同日・同ユーザーの重複スキップ
      if (existing.has(key)) {
        totalSkipped++;
        continue;
      }
      existing.add(key);

      // ユーザープロフィール取得（キャッシュ活用）
      if (!userCache.has(userId)) {
        try {
          const userDoc = await db.collection('users').doc(userId).get();
          if (userDoc.exists) {
            const userData = userDoc.data();
            const gender = userData.gender || null;
            let ageGroup = null;
            if (userData.birthDate) {
              const bd = userData.birthDate.toDate
                ? userData.birthDate.toDate()
                : new Date(userData.birthDate);
              if (!isNaN(bd.getTime())) {
                ageGroup = calculateAgeGroup(bd);
              }
            }
            userCache.set(userId, { gender, ageGroup });
          } else {
            userCache.set(userId, { gender: null, ageGroup: null });
          }
        } catch (e) {
          console.error(`ユーザー ${userId} の取得エラー: ${e.message}`);
          userCache.set(userId, { gender: null, ageGroup: null });
        }
      }

      const profile = userCache.get(userId);
      const txnRef = db.collection('stores').doc(storeId).collection('transactions').doc();
      batch.set(txnRef, {
        transactionId: txnRef.id,
        storeId,
        storeName,
        userId,
        type: 'stamp',
        amountYen: 0,
        points: 0,
        status: 'completed',
        source: 'backfill_stamp',
        userGender: profile.gender,
        userAgeGroup: profile.ageGroup,
        createdAt: timestamp,
        createdAtClient: ts,
      });

      batchCount++;
      storeCreated++;

      if (batchCount >= 500) {
        await batch.commit();
        batch = db.batch();
        batchCount = 0;
        console.log(`  [${storeName}] ... ${storeCreated} 件処理済み`);
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    totalCreated += storeCreated;
    if (storeCreated > 0) {
      console.log(`[${storeName}] 完了: ${storeCreated} 件作成`);
    }
  }

  console.log('=== バックフィル完了 ===');
  console.log(`作成: ${totalCreated} 件, スキップ: ${totalSkipped} 件`);
  console.log(`ユーザーキャッシュ: ${userCache.size} 件`);
}

backfillStampTransactions()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('バックフィルエラー:', err);
    process.exit(1);
  });
