import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/point_transaction_model.dart';

class PointTransactionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 生年月日から年代グループを算出
  static String? _calculateAgeGroup(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    if (age < 20) return '~19';
    if (age < 30) return '20s';
    if (age < 40) return '30s';
    if (age < 50) return '40s';
    if (age < 60) return '50s';
    return '60+';
  }

  /// birthDateフィールドをDateTimeに変換
  static DateTime? _parseBirthDate(dynamic birthDate) {
    if (birthDate == null) return null;
    if (birthDate is DateTime) return birthDate;
    if (birthDate is Timestamp) return birthDate.toDate();
    if (birthDate is String) {
      try {
        return DateTime.parse(birthDate);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

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

      // ユーザープロフィールからgender/birthDateを取得し、属性情報をデノーマライズ保存
      String? userGender;
      String? userAgeGroup;
      try {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          userGender = userData['gender'] as String?;
          final birthDate = _parseBirthDate(userData['birthDate']);
          if (birthDate != null) {
            userAgeGroup = _calculateAgeGroup(birthDate);
          }
        }
      } catch (e) {
        debugPrint('ユーザープロフィール取得エラー（続行）: $e');
      }

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
        'userGender': userGender,
        'userAgeGroup': userAgeGroup,
        'createdAt': FieldValue.serverTimestamp(),
        'createdAtClient': now,
      });

      // store_stats の更新は Cloud Function (updateStoreDailyStats) に一元化
      // クライアント側での二重カウントを防止

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
