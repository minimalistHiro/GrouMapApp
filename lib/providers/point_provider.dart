import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/point_transaction_model.dart';
import '../models/badge_model.dart';
import 'badge_provider.dart';
import 'level_provider.dart';

// ポイントサービスプロバイダー
final pointServiceProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// ユーザーのポイント残高プロバイダー
final userPointBalanceProvider = StreamProvider.family<UserPointBalance?, String>((ref, userId) {
  final firestore = ref.watch(pointServiceProvider);
  
  return firestore
      .collection('user_point_balances')
      .doc(userId)
      .snapshots()
      .timeout(const Duration(seconds: 5))
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

// ユーザーのポイント取引履歴プロバイダー
final userPointTransactionsProvider = StreamProvider.family<List<PointTransactionModel>, String>((ref, userId) {
  final firestore = ref.watch(pointServiceProvider);
  
  return firestore
      .collection('point_transactions')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .timeout(const Duration(seconds: 5))
      .map((snapshot) => snapshot.docs
          .map((doc) => PointTransactionModel.fromJson({
                ...doc.data(),
                'transactionId': doc.id,
              }))
          .toList())
      .handleError((error) {
    debugPrint('Error getting user point transactions: $error');
    if (error.toString().contains('permission-denied')) {
      return <PointTransactionModel>[];
    }
    return <PointTransactionModel>[];
  });
});

// ポイント処理プロバイダー
final pointProcessorProvider = Provider<PointProcessor>((ref) {
  final firestore = ref.watch(pointServiceProvider);
  return PointProcessor(firestore);
});

// ポイント処理クラス
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
      final transaction = PointTransactionModel(
        transactionId: '', // Firestoreで自動生成
        userId: userId,
        storeId: storeId,
        points: points,
        type: const PointTransactionType.earned(reason: 'store_visit'),
        description: description,
        timestamp: DateTime.now(),
        qrCodeId: qrCodeId,
        isProcessed: true,
      );

      // 取引を記録
      await _firestore
          .collection('point_transactions')
          .add(transaction.toJson());

      // ユーザーのポイント残高を更新
      await _updateUserPointBalance(userId, points, 0);

      // バッジとレベルシステムを更新
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

      final transaction = PointTransactionModel(
        transactionId: '', // Firestoreで自動生成
        userId: userId,
        storeId: storeId,
        points: -points,
        type: PointTransactionType.used(
          reason: 'purchase',
          amountUsed: points,
        ),
        description: description,
        timestamp: DateTime.now(),
        isProcessed: true,
      );

      // 取引を記録
      await _firestore
          .collection('point_transactions')
          .add(transaction.toJson());

      // ユーザーのポイント残高を更新
      await _updateUserPointBalance(userId, 0, points);
    } catch (e) {
      throw Exception('ポイント使用に失敗しました: $e');
    }
  }

  // ユーザーのポイント残高を更新
  Future<void> _updateUserPointBalance(String userId, int earnedPoints, int usedPoints) async {
    final balanceRef = _firestore.collection('user_point_balances').doc(userId);
    
    await _firestore.runTransaction((transaction) async {
      final balanceDoc = await transaction.get(balanceRef);
      
      if (balanceDoc.exists) {
        final currentBalance = UserPointBalance.fromJson({
          ...balanceDoc.data()!,
          'userId': balanceDoc.id,
        });
        
        final newBalance = currentBalance.copyWith(
          totalPoints: currentBalance.totalPoints + earnedPoints,
          availablePoints: currentBalance.availablePoints + earnedPoints - usedPoints,
          usedPoints: currentBalance.usedPoints + usedPoints,
          lastUpdated: DateTime.now(),
        );
        
        transaction.update(balanceRef, newBalance.toJson());
      } else {
        // 新規ユーザーの場合
        final newBalance = UserPointBalance(
          userId: userId,
          totalPoints: earnedPoints,
          availablePoints: earnedPoints,
          usedPoints: usedPoints,
          expiredPoints: 0,
          lastUpdated: DateTime.now(),
          recentTransactions: [],
        );
        
        transaction.set(balanceRef, newBalance.toJson());
      }
    });
  }

  // ゲーミフィケーションシステムを更新
  Future<void> _updateGamificationSystems(String userId, int points, String storeId) async {
    try {
      // バッジプログレスを更新
      final badgeService = BadgeService();
      await badgeService.updateBadgeProgress(
        userId: userId,
        badgeType: BadgeType.pointsEarned,
        increment: points,
      );

      // レベルシステムを更新
      final levelService = LevelService();
      await levelService.addPoints(
        userId: userId,
        points: points,
      );
    } catch (e) {
      // ゲーミフィケーションシステムのエラーはポイント獲得を妨げない
      print('Gamification system update error: $e');
    }
  }

  // QRコードを生成
  Future<QRCodeModel> generateQRCode({
    required String storeId,
    required int points,
    required String createdBy,
    String? description,
    Duration? expiresIn,
  }) async {
    try {
      final qrCode = QRCodeModel(
        qrCodeId: '', // Firestoreで自動生成
        storeId: storeId,
        points: points,
        expiresAt: DateTime.now().add(expiresIn ?? const Duration(hours: 1)),
        createdAt: DateTime.now(),
        createdBy: createdBy,
        description: description,
      );

      final docRef = await _firestore
          .collection('qr_codes')
          .add(qrCode.toJson());

      return qrCode.copyWith(qrCodeId: docRef.id);
    } catch (e) {
      throw Exception('QRコード生成に失敗しました: $e');
    }
  }

  // QRコードを使用
  Future<void> useQRCode({
    required String qrCodeId,
    required String userId,
  }) async {
    try {
      final qrCodeRef = _firestore.collection('qr_codes').doc(qrCodeId);
      
      await _firestore.runTransaction((transaction) async {
        final qrCodeDoc = await transaction.get(qrCodeRef);
        
        if (!qrCodeDoc.exists) {
          throw Exception('QRコードが見つかりません');
        }
        
        final qrCode = QRCodeModel.fromJson({
          ...qrCodeDoc.data()!,
          'qrCodeId': qrCodeDoc.id,
        });
        
        if (qrCode.isUsed) {
          throw Exception('このQRコードは既に使用されています');
        }
        
        if (qrCode.expiresAt.isBefore(DateTime.now())) {
          throw Exception('このQRコードは期限切れです');
        }
        
        // QRコードを使用済みにマーク
        transaction.update(qrCodeRef, {
          'isUsed': true,
          'usedBy': userId,
          'usedAt': DateTime.now(),
        });
        
        // ポイントを獲得
        await earnPoints(
          userId: userId,
          storeId: qrCode.storeId,
          points: qrCode.points,
          description: qrCode.description ?? 'QRコード使用',
          qrCodeId: qrCodeId,
        );
      });
    } catch (e) {
      throw Exception('QRコード使用に失敗しました: $e');
    }
  }
}
