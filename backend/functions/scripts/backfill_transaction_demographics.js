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
 * 既存のstores/{storeId}/transactionsにuserGender/userAgeGroupをバックフィル
 */
async function backfillTransactionDemographics() {
  console.log(`Project: ${projectId}`);
  console.log('=== バックフィル開始: トランザクション属性情報 ===');

  // ユーザープロフィールキャッシュ
  const userCache = new Map();

  // 全ストアを取得
  const storesSnapshot = await db.collection('stores').get();
  console.log(`対象ストア数: ${storesSnapshot.size}`);

  let totalUpdated = 0;
  let totalSkipped = 0;

  for (const storeDoc of storesSnapshot.docs) {
    const storeId = storeDoc.id;
    const storeName = storeDoc.data().name || storeId;

    // 全トランザクションを取得
    const txnSnapshot = await db
      .collection('stores')
      .doc(storeId)
      .collection('transactions')
      .get();

    if (txnSnapshot.empty) continue;

    // userGenderが未設定のもののみ対象
    const toUpdate = txnSnapshot.docs.filter((doc) => {
      const data = doc.data();
      return data.userGender === undefined || data.userGender === null;
    });

    if (toUpdate.length === 0) {
      console.log(`[${storeName}] スキップ（全トランザクション設定済み）`);
      continue;
    }

    console.log(`[${storeName}] 更新対象: ${toUpdate.length}/${txnSnapshot.size} 件`);

    let batch = db.batch();
    let batchCount = 0;
    let storeUpdated = 0;

    for (const txnDoc of toUpdate) {
      const data = txnDoc.data();
      const userId = data.userId;

      if (!userId) {
        totalSkipped++;
        continue;
      }

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
      batch.update(txnDoc.ref, {
        userGender: profile.gender,
        userAgeGroup: profile.ageGroup,
      });

      batchCount++;
      storeUpdated++;

      // Firestoreバッチ上限（500件）
      if (batchCount >= 500) {
        await batch.commit();
        batch = db.batch();
        batchCount = 0;
        console.log(`  ... ${storeUpdated}/${toUpdate.length} 件処理済み`);
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    totalUpdated += storeUpdated;
    console.log(`[${storeName}] 完了: ${storeUpdated} 件更新`);
  }

  console.log('=== バックフィル完了 ===');
  console.log(`更新: ${totalUpdated} 件, スキップ: ${totalSkipped} 件`);
  console.log(`ユーザーキャッシュ: ${userCache.size} 件`);
}

backfillTransactionDemographics()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('バックフィルエラー:', err);
    process.exit(1);
  });
