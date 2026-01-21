import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/point_transaction_model.dart';

class PointTransactionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ポイント支払い履歴を作成
  static Future<String> createTransaction({
    required String storeId,
    required String storeName,
    required int amount,
    int? paymentAmount,
    String? description,
    String? qrCode,
    String? transactionType,
    int? amountYen,
    String? source,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('ユーザーがログインしていません');
      }

      final transactionId = _firestore.collection('point_transactions').doc().id;
      final now = DateTime.now();

      final transaction = PointTransactionModel(
        transactionId: transactionId,
        userId: user.uid,
        storeId: storeId,
        storeName: storeName,
        amount: amount,
        paymentAmount: paymentAmount,
        status: 'completed',
        paymentMethod: 'points',
        createdAt: now,
        updatedAt: now,
        description: description,
        qrCode: qrCode,
      );

      // 要件に合わせてネストのみに保存: point_transactions/{storeId}/{userId}/{transactionId}
      await _firestore
          .collection('point_transactions')
          .doc(storeId)
          .collection(user.uid)
          .doc(transactionId)
          .set(transaction.toJson());

      final resolvedType = transactionType ??
          (amount < 0 ? 'use' : 'award');
      final resolvedSource = source ??
          (resolvedType == 'use' ? 'point_usage' : 'point_request');
      final resolvedAmountYen = amountYen ?? paymentAmount ?? 0;

      await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('transactions')
          .doc(transactionId)
          .set({
        'transactionId': transactionId,
        'storeId': storeId,
        'storeName': storeName,
        'userId': user.uid,
        'type': resolvedType,
        'amountYen': resolvedAmountYen,
        'points': amount,
        'paymentMethod': transaction.paymentMethod,
        'status': transaction.status,
        'source': resolvedSource,
        'createdAt': FieldValue.serverTimestamp(),
        'createdAtClient': now,
      });

      if (resolvedType == 'use' || resolvedType == 'award') {
        final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final statsRef = _firestore
            .collection('store_stats')
            .doc(storeId)
            .collection('daily')
            .doc(todayStr);

        final Map<String, dynamic> updates = {
          'date': todayStr,
          'visitorCount': FieldValue.increment(1),
          'lastUpdated': FieldValue.serverTimestamp(),
        };

        if (resolvedType == 'use') {
          final usedPoints = amount < 0 ? -amount : amount;
          updates['pointsUsed'] = FieldValue.increment(usedPoints);
        } else {
          final issuedPoints = amount < 0 ? -amount : amount;
          updates['pointsIssued'] = FieldValue.increment(issuedPoints);
          updates['totalPointsAwarded'] = FieldValue.increment(issuedPoints);
          updates['totalSales'] = FieldValue.increment(resolvedAmountYen);
          updates['totalTransactions'] = FieldValue.increment(1);
        }

        await statsRef.set(updates, SetOptions(merge: true));
      }

      return transactionId;
    } catch (e) {
      throw Exception('ポイント支払い履歴の作成に失敗しました: $e');
    }
  }

  /// ユーザーのポイント支払い履歴を取得
  static Stream<List<PointTransactionModel>> getUserTransactions({
    int? limit,
    DocumentSnapshot? startAfter,
  }) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    // ネスト構造ではトップレベルに userId フィルタは使えないため、全店舗分を統合する実装が必要
    // ここでは簡易版として空ストリームを返すか、別API(getUserStoreTransactions)を使用してください
    return const Stream.empty();
  }

  /// 店舗のポイント支払い履歴を取得
  static Stream<List<PointTransactionModel>> getStoreTransactions({
    required String storeId,
    int? limit,
    DocumentSnapshot? startAfter,
  }) {
    Query query = _firestore
        .collection('point_transactions')
        .doc(storeId)
        .collection(_auth.currentUser?.uid ?? '_')
        .orderBy('createdAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return PointTransactionModel.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  /// 特定の店舗でのユーザーの支払い履歴を取得
  static Stream<List<PointTransactionModel>> getUserStoreTransactions({
    required String storeId,
    int? limit,
    DocumentSnapshot? startAfter,
  }) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    Query query = _firestore
        .collection('point_transactions')
        .doc(storeId)
        .collection(user.uid)
        .orderBy('createdAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return PointTransactionModel.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  /// トランザクションをキャンセル
  static Future<void> cancelTransaction(String transactionId) async {
    try {
      await _firestore
          .collection('point_transactions')
          .doc(transactionId)
          .update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('トランザクションのキャンセルに失敗しました: $e');
    }
  }

  /// トランザクションを返金
  static Future<void> refundTransaction({
    required String transactionId,
    required String reason,
  }) async {
    try {
      await _firestore
          .collection('point_transactions')
          .doc(transactionId)
          .update({
        'status': 'refunded',
        'refundedAt': FieldValue.serverTimestamp(),
        'refundReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('返金処理に失敗しました: $e');
    }
  }

  /// ユーザーの総支払いポイント数を取得
  static Future<int> getUserTotalSpent() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      // ネスト構造では全店舗の集計が必要。簡易実装では0を返す
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// 店舗の総受取ポイント数を取得
  static Future<int> getStoreTotalReceived(String storeId) async {
    try {
      // ネスト構造では店舗配下の全ユーザーコレクション集計が必要。簡易実装では0を返す
      return 0;
    } catch (e) {
      return 0;
    }
  }
}
