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
    String? description,
    String? qrCode,
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
        status: 'completed',
        paymentMethod: 'points',
        createdAt: now,
        updatedAt: now,
        description: description,
        qrCode: qrCode,
      );

      await _firestore
          .collection('point_transactions')
          .doc(transactionId)
          .set(transaction.toJson());

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
    Query query = _firestore
        .collection('point_transactions')
        .where('userId', isEqualTo: _auth.currentUser?.uid)
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

  /// 店舗のポイント支払い履歴を取得
  static Stream<List<PointTransactionModel>> getStoreTransactions({
    required String storeId,
    int? limit,
    DocumentSnapshot? startAfter,
  }) {
    Query query = _firestore
        .collection('point_transactions')
        .where('storeId', isEqualTo: storeId)
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
        .where('userId', isEqualTo: user.uid)
        .where('storeId', isEqualTo: storeId)
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

      final snapshot = await _firestore
          .collection('point_transactions')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'completed')
          .get();

      int total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        total += (data['amount'] as int? ?? 0);
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  /// 店舗の総受取ポイント数を取得
  static Future<int> getStoreTotalReceived(String storeId) async {
    try {
      final snapshot = await _firestore
          .collection('point_transactions')
          .where('storeId', isEqualTo: storeId)
          .where('status', isEqualTo: 'completed')
          .get();

      int total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        total += (data['amount'] as int? ?? 0);
      }
      return total;
    } catch (e) {
      return 0;
    }
  }
}
