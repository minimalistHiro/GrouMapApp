import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/point_transaction_model.dart';
import '../models/user_point_balance_model.dart';
import '../models/qr_code_model.dart';

// ポイントサービスプロバイダー
final pointServiceProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// users/{uid}.points を残高として取得
final userPointsProvider = StreamProvider.family<int, String>((ref, userId) {
  final firestore = ref.watch(pointServiceProvider);
  return firestore
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((snapshot) {
    final data = snapshot.data() ?? {};
    final value = data['points'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  });
});

// ユーザーのポイント残高プロバイダー
final userPointBalanceProvider = StreamProvider.family<UserPointBalance?, String>((ref, userId) {
  final firestore = ref.watch(pointServiceProvider);
  
  return firestore
      .collection('user_point_balances')
      .doc(userId)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) return null;
    return UserPointBalance.fromJson({
      ...snapshot.data()!,
      'userId': snapshot.id,
    });
  }).handleError((error) {
    debugPrint('Error getting user point balance: $error');
    return null;
  });
});

// ポイントプロセッサークラス
class PointProcessor {
  final FirebaseFirestore _firestore;

  PointProcessor(this._firestore);

  // ポイントを獲得
  Future<void> earnPoints({
    required String userId,
    required String storeId,
    required int points,
    required String description,
    String? qrCodeId,
  }) async {
    try {
      final transactionId = _firestore.collection('point_transactions').doc().id;
      final now = DateTime.now();
      
      final transaction = PointTransactionModel(
        transactionId: transactionId,
        userId: userId,
        storeId: storeId,
        storeName: '', // 店舗名は別途取得
        amount: points,
        paymentAmount: null,
        status: 'completed',
        paymentMethod: 'points',
        createdAt: now,
        updatedAt: now,
        description: description,
        qrCode: qrCodeId,
      );

      // 取引を記録（ネスト構造） point_transactions/{storeId}/{userId}/{transactionId}
      await _firestore
          .collection('point_transactions')
          .doc(storeId)
          .collection(userId)
          .doc(transactionId)
          .set(transaction.toJson());

      // 旧構造の重複データを念のため削除
      try {
        await _firestore.collection('point_transactions').doc(transactionId).delete();
      } catch (_) {}

      // ユーザーのポイント残高を更新
      await _updateUserPointBalance(userId, points, 0);

      // バッジシステムを更新
      await _updateGamificationSystems(userId, points, storeId);
    } catch (e) {
      throw Exception('ポイント獲得に失敗しました: $e');
    }
  }

  // ポイントを使用
  Future<void> usePoints({
    required String userId,
    required String storeId,
    required int points,
    required String description,
  }) async {
    try {
      // 現在のポイント残高を確認
      final balanceDoc = await _firestore
          .collection('user_point_balances')
          .doc(userId)
          .get();

      if (!balanceDoc.exists) {
        throw Exception('ポイント残高が見つかりません');
      }

      final currentBalance = UserPointBalance.fromJson({
        ...balanceDoc.data()!,
        'userId': balanceDoc.id,
      });

      if (currentBalance.availablePoints < points) {
        throw Exception('ポイントが不足しています');
      }

      final transactionId = _firestore.collection('point_transactions').doc().id;
      final now = DateTime.now();
      
      final transaction = PointTransactionModel(
        transactionId: transactionId,
        userId: userId,
        storeId: storeId,
        storeName: '', // 店舗名は別途取得
        amount: -points, // 負の値で使用を表現
        paymentAmount: null,
        status: 'completed',
        paymentMethod: 'points',
        createdAt: now,
        updatedAt: now,
        description: description,
      );

      // 取引を記録（ネスト構造） point_transactions/{storeId}/{userId}/{transactionId}
      await _firestore
          .collection('point_transactions')
          .doc(storeId)
          .collection(userId)
          .doc(transactionId)
          .set(transaction.toJson());

      // 旧構造の重複データを念のため削除
      try {
        await _firestore.collection('point_transactions').doc(transactionId).delete();
      } catch (_) {}

      await _updateStoreStatsForPointsUsed(storeId, points);

      // ユーザーのポイント残高を更新
      await _updateUserPointBalance(userId, 0, points);
    } catch (e) {
      throw Exception('ポイント使用に失敗しました: $e');
    }
  }

  Future<void> _updateStoreStatsForPointsUsed(String storeId, int points) async {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    await _firestore
        .collection('store_stats')
        .doc(storeId)
        .collection('daily')
        .doc(todayStr)
        .set({
      'date': todayStr,
      'pointsUsed': FieldValue.increment(points),
      'visitorCount': FieldValue.increment(1),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ユーザーのポイント残高を更新
  Future<void> _updateUserPointBalance(String userId, int earned, int used) async {
    final balanceDoc = await _firestore
        .collection('user_point_balances')
        .doc(userId)
        .get();

    if (balanceDoc.exists) {
      final currentBalance = UserPointBalance.fromJson({
        ...balanceDoc.data()!,
        'userId': balanceDoc.id,
      });

      final newBalance = UserPointBalance(
        userId: userId,
        totalPoints: currentBalance.totalPoints + earned,
        availablePoints: currentBalance.availablePoints + earned - used,
        usedPoints: currentBalance.usedPoints + used,
        lastUpdated: DateTime.now(),
      );

      await _firestore
          .collection('user_point_balances')
          .doc(userId)
          .update(newBalance.toJson());
    } else {
      // 新規作成
      final newBalance = UserPointBalance(
        userId: userId,
        totalPoints: earned,
        availablePoints: earned - used,
        usedPoints: used,
        lastUpdated: DateTime.now(),
      );

      await _firestore
          .collection('user_point_balances')
          .doc(userId)
          .set(newBalance.toJson());
    }
  }

  // バッジシステムを更新
  Future<void> _updateGamificationSystems(String userId, int points, String storeId) async {
    // バッジシステムの更新（実装は後で追加）
    // final badgeProcessor = BadgeProcessor(_firestore);
    // await badgeProcessor.checkAndAwardBadges(userId, points, storeId);
  }

  // QRコードを生成
  Future<QRCodeModel> generateQRCode({
    required String userId,
    required String storeId,
    required int points,
    required String description,
  }) async {
    try {
      final qrCodeId = _firestore.collection('qr_codes').doc().id;
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 1)); // 1時間で期限切れ

      final qrCode = QRCodeModel(
        qrCodeId: qrCodeId,
        userId: userId,
        storeId: storeId,
        qrCodeData: 'points:$qrCodeId:$userId:$storeId:$points',
        createdAt: now,
        expiresAt: expiresAt,
        isUsed: false,
      );

      await _firestore
          .collection('qr_codes')
          .doc(qrCodeId)
          .set(qrCode.toJson());

      return qrCode;
    } catch (e) {
      throw Exception('QRコード生成に失敗しました: $e');
    }
  }

  // QRコードを使用
  Future<void> useQRCode(String qrCodeData) async {
    try {
      final parts = qrCodeData.split(':');
      if (parts.length != 5 || parts[0] != 'points') {
        throw Exception('無効なQRコードです');
      }

      final qrCodeId = parts[1];
      final userId = parts[2];
      final storeId = parts[3];
      final points = int.tryParse(parts[4]) ?? 0;

      if (points <= 0) {
        throw Exception('無効なポイント数です');
      }

      // QRコードの存在と有効性を確認
      final qrDoc = await _firestore
          .collection('qr_codes')
          .doc(qrCodeId)
          .get();

      if (!qrDoc.exists) {
        throw Exception('QRコードが見つかりません');
      }

      final qrCode = QRCodeModel.fromJson({
        ...qrDoc.data()!,
        'qrCodeId': qrDoc.id,
      });

      if (qrCode.isUsed) {
        throw Exception('このQRコードは既に使用されています');
      }

      if (qrCode.expiresAt.isBefore(DateTime.now())) {
        throw Exception('QRコードの有効期限が切れています');
      }

      // QRコードを使用済みにマーク
      await _firestore
          .collection('qr_codes')
          .doc(qrCodeId)
          .update({
        'isUsed': true,
        'usedAt': FieldValue.serverTimestamp(),
      });

      // ポイントを獲得
      await earnPoints(
        userId: userId,
        storeId: storeId,
        points: points,
        description: 'QRコード使用',
        qrCodeId: qrCodeId,
      );
    } catch (e) {
      throw Exception('QRコード使用に失敗しました: $e');
    }
  }
}

// ポイントプロセッサープロバイダー
final pointProcessorProvider = Provider<PointProcessor>((ref) {
  final firestore = ref.watch(pointServiceProvider);
  return PointProcessor(firestore);
});

// ユーザーのポイント取引履歴プロバイダー
final userPointTransactionsProvider = StreamProvider.family<List<PointTransactionModel>, String>((ref, userId) {
  final firestore = ref.watch(pointServiceProvider);

  DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  return firestore
      .collectionGroup('transactions')
      .where('userId', isEqualTo: userId)
      .where('paymentMethod', isEqualTo: 'points')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final createdAt = data['createdAt'] ?? data['createdAtClient'];
          final updatedAt = data['updatedAt'] ?? createdAt;
        final amountRaw = data['points'] ?? data['amount'];
        final baseAmount = amountRaw is num ? amountRaw.toInt() : int.tryParse('$amountRaw') ?? 0;
        final type = data['type'] as String?;
        final source = data['source'] as String?;
        final description = data['description'] as String?;
        var amount = baseAmount;
        if (amount > 0 &&
            (type == 'use' ||
                source == 'point_usage' ||
                description == 'ポイント利用' ||
                description == 'ポイント支払い')) {
          amount = -amount;
        }

          return PointTransactionModel(
            transactionId: (data['transactionId'] as String?) ?? doc.id,
            userId: (data['userId'] as String?) ?? userId,
            storeId: (data['storeId'] as String?) ?? '',
            storeName: (data['storeName'] as String?) ?? '店舗名なし',
            amount: amount,
            paymentAmount: (data['amountYen'] as num?)?.toInt(),
            status: (data['status'] as String?) ?? 'completed',
            paymentMethod: (data['paymentMethod'] as String?) ?? 'points',
            createdAt: _parseTimestamp(createdAt),
            updatedAt: _parseTimestamp(updatedAt),
            description: data['description'] as String?,
            qrCode: data['qrCode'] as String?,
            usedNormalPoints: _parseInt(data['usedNormalPoints']),
            usedSpecialPoints: _parseInt(data['usedSpecialPoints']),
            totalUsedPoints: _parseInt(data['totalUsedPoints']),
            refundedAt: data['refundedAt'] is Timestamp
                ? (data['refundedAt'] as Timestamp).toDate()
                : null,
            refundReason: data['refundReason'] as String?,
          );
        }).toList();
      });
});
