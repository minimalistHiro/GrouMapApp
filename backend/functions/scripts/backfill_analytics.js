/* eslint-disable no-console */
const admin = require('firebase-admin');
const fs = require('fs');

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

if (admin.apps.length === 0) {
  if (keyFilePath) {
    const raw = fs.readFileSync(keyFilePath, 'utf8');
    const serviceAccount = JSON.parse(raw);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId,
    });
  } else {
    admin.initializeApp({ projectId });
  }
}

const db = admin.firestore();
const isDryRun = args.includes('--dry-run');
const skipLegacy = args.includes('--skip-legacy');
const skipAggregate = args.includes('--skip-aggregate');
const storeArg = args.find((arg) => arg.startsWith('--store='));
const targetStoreId = storeArg ? storeArg.split('=')[1] : null;

function getDateKey(date) {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Tokyo',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(date);
}

function extractDate(data) {
  const createdAt = data.createdAt;
  if (createdAt && typeof createdAt.toDate === 'function') return createdAt.toDate();
  if (createdAt instanceof Date) return createdAt;
  if (typeof createdAt === 'string') {
    const parsed = new Date(createdAt);
    if (!Number.isNaN(parsed.getTime())) return parsed;
  }

  const timestamp = data.timestamp;
  if (timestamp && typeof timestamp.toDate === 'function') return timestamp.toDate();
  if (timestamp instanceof Date) return timestamp;
  if (typeof timestamp === 'string') {
    const parsed = new Date(timestamp);
    if (!Number.isNaN(parsed.getTime())) return parsed;
  }

  return null;
}

async function commitBatch(batch, count) {
  if (count === 0) return;
  if (isDryRun) return;
  await batch.commit();
}

async function backfillStoreTransactionsFromSales() {
  console.log('Backfill from legacy transactions...');
  const snapshot = await db.collection('transactions').get();
  let batch = db.batch();
  let batchCount = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const storeId = data.storeId;
    if (!storeId) continue;
    if (targetStoreId && storeId !== targetStoreId) continue;

    const createdAt = extractDate(data);
    if (!createdAt) continue;

    const transactionRef = db
      .collection('stores')
      .doc(storeId)
      .collection('transactions')
      .doc(data.transactionId || doc.id);

    const payload = {
      transactionId: data.transactionId || doc.id,
      storeId,
      storeName: data.storeName || '',
      userId: data.userId || '',
      userName: data.userName || '',
      type: 'sale',
      amountYen: typeof data.amount === 'number' ? data.amount : 0,
      points: typeof data.pointsAwarded === 'number' ? data.pointsAwarded : 0,
      paymentMethod: data.paymentMethod || 'unknown',
      status: data.status || 'completed',
      source: 'legacy_store_payment',
      createdAt: admin.firestore.Timestamp.fromDate(createdAt),
      createdAtClient: createdAt,
    };

    batch.set(transactionRef, payload, { merge: true });
    batchCount += 1;

    if (batchCount >= 400) {
      await commitBatch(batch, batchCount);
      batch = db.batch();
      batchCount = 0;
    }
  }

  await commitBatch(batch, batchCount);
  console.log('Backfill from legacy transactions done.');
}

async function backfillStoreTransactionsFromPointTransactions() {
  console.log('Backfill from point_transactions...');
  const storeDocs = targetStoreId
    ? [db.collection('point_transactions').doc(targetStoreId)]
    : await db.collection('point_transactions').listDocuments();

  let batch = db.batch();
  let batchCount = 0;

  for (const storeDoc of storeDocs) {
    const storeId = storeDoc.id;
    if (targetStoreId && storeId !== targetStoreId) continue;
    const userCollections = await storeDoc.listCollections();

    for (const userCollection of userCollections) {
      const userId = userCollection.id;
      const transactionsSnap = await userCollection.get();

      for (const doc of transactionsSnap.docs) {
        const data = doc.data();
        const createdAt = extractDate(data);
        if (!createdAt) continue;

        const amount = typeof data.amount === 'number' ? data.amount : 0;
        const type = amount < 0 ? 'use' : 'award';
        const amountYen =
          typeof data.paymentAmount === 'number' ? data.paymentAmount : 0;

        const transactionRef = db
          .collection('stores')
          .doc(storeId)
          .collection('transactions')
          .doc(data.transactionId || doc.id);

        const payload = {
          transactionId: data.transactionId || doc.id,
          storeId,
          storeName: data.storeName || '',
          userId: data.userId || userId,
          userName: data.userName || '',
          type,
          amountYen,
          points: amount,
          paymentMethod: data.paymentMethod || 'points',
          status: data.status || 'completed',
          source: 'legacy_point_transaction',
          createdAt: admin.firestore.Timestamp.fromDate(createdAt),
          createdAtClient: createdAt,
        };

        batch.set(transactionRef, payload, { merge: true });
        batchCount += 1;

        if (batchCount >= 400) {
          await commitBatch(batch, batchCount);
          batch = db.batch();
          batchCount = 0;
        }
      }
    }
  }

  await commitBatch(batch, batchCount);
  console.log('Backfill from point_transactions done.');
}

async function rebuildAggregates() {
  console.log('Rebuild store_stats and store_users...');
  const storeDocs = targetStoreId
    ? [db.collection('stores').doc(targetStoreId)]
    : await db.collection('stores').listDocuments();

  for (const storeDoc of storeDocs) {
    const storeId = storeDoc.id;

    const dailyMap = new Map();
    const userMap = new Map();

    let lastDoc = null;
    while (true) {
      let query = db
        .collection('stores')
        .doc(storeId)
        .collection('transactions')
        .orderBy('createdAt')
        .limit(500);
      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }
      const snap = await query.get();
      if (snap.empty) break;

      for (const doc of snap.docs) {
        const data = doc.data();
        const createdAt = extractDate(data);
        if (!createdAt) continue;

        const dateKey = getDateKey(createdAt);
        const current = dailyMap.get(dateKey) || {
          date: dateKey,
          totalSales: 0,
          pointsIssued: 0,
          pointsUsed: 0,
          visitorCount: 0,
          transactionCount: 0,
        };

        const amountYen = typeof data.amountYen === 'number' ? data.amountYen : 0;
        const points = typeof data.points === 'number' ? data.points : 0;
        const type = typeof data.type === 'string' ? data.type : '';

        current.transactionCount += 1;
        if (amountYen > 0) current.totalSales += amountYen;
        if (points > 0) current.pointsIssued += points;
        if (points < 0) current.pointsUsed += Math.abs(points);
        if (type === 'award') current.visitorCount += 1;

        dailyMap.set(dateKey, current);

        if (type === 'award') {
          const userId = typeof data.userId === 'string' ? data.userId : '';
          if (userId) {
            const userCurrent = userMap.get(userId) || {
              userId,
              storeId,
              firstVisitAt: createdAt,
              lastVisitAt: createdAt,
              totalVisits: 0,
            };
            if (createdAt < userCurrent.firstVisitAt) userCurrent.firstVisitAt = createdAt;
            if (createdAt > userCurrent.lastVisitAt) userCurrent.lastVisitAt = createdAt;
            userCurrent.totalVisits += 1;
            userMap.set(userId, userCurrent);
          }
        }
      }

      lastDoc = snap.docs[snap.docs.length - 1];
    }

    let batch = db.batch();
    let batchCount = 0;

    for (const [dateKey, data] of dailyMap.entries()) {
      const ref = db
        .collection('store_stats')
        .doc(storeId)
        .collection('daily')
        .doc(dateKey);
      batch.set(
        ref,
        {
          ...data,
          lastUpdated: new Date(),
        },
        { merge: false }
      );
      batchCount += 1;
      if (batchCount >= 400) {
        await commitBatch(batch, batchCount);
        batch = db.batch();
        batchCount = 0;
      }
    }

    for (const [, data] of userMap.entries()) {
      const ref = db
        .collection('store_users')
        .doc(storeId)
        .collection('users')
        .doc(data.userId);
      batch.set(
        ref,
        {
          ...data,
          createdAt: new Date(),
          updatedAt: new Date(),
        },
        { merge: false }
      );
      batchCount += 1;
      if (batchCount >= 400) {
        await commitBatch(batch, batchCount);
        batch = db.batch();
        batchCount = 0;
      }
    }

    await commitBatch(batch, batchCount);
    console.log(`Rebuild done for store ${storeId}`);
  }
}

async function main() {
  console.log('Backfill started.');
  if (!skipLegacy) {
    await backfillStoreTransactionsFromSales();
    await backfillStoreTransactionsFromPointTransactions();
  }
  if (!skipAggregate) {
    await rebuildAggregates();
  }
  console.log('Backfill finished.');
}

main().catch((error) => {
  console.error('Backfill failed:', error);
  process.exit(1);
});
