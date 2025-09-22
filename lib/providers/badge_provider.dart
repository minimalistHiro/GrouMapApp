import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/badge_model.dart';

// バッジプロバイダー
final badgeProvider = Provider<BadgeService>((ref) {
  return BadgeService();
});

// ユーザーのバッジ一覧
final userBadgesProvider = FutureProvider.family<List<UserBadgeModel>, String>((ref, userId) async {
  final badgeService = ref.read(badgeProvider);
  return await badgeService.getUserBadges(userId);
});

// 利用可能なバッジ一覧
final availableBadgesProvider = FutureProvider<List<BadgeModel>>((ref) async {
  final badgeService = ref.read(badgeProvider);
  return await badgeService.getAvailableBadges();
});

// バッジの進捗状況
final badgeProgressProvider = FutureProvider.family<Map<String, int>, String>((ref, userId) async {
  final badgeService = ref.read(badgeProvider);
  return await badgeService.getBadgeProgress(userId);
});

class BadgeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ユーザーのバッジ一覧を取得
  Future<List<UserBadgeModel>> getUserBadges(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('user_badges')
          .where('userId', isEqualTo: userId)
          .orderBy('unlockedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => UserBadgeModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching user badges: $e');
      // Firestoreの権限エラーの場合は空のリストを返す
      if (e.toString().contains('permission-denied')) {
        return [];
      }
      throw Exception('バッジの取得に失敗しました');
    }
  }

  // バッジを手動で付与（重複付与は防止）
  Future<bool> awardBadge({
    required String userId,
    required BadgeModel badge,
  }) async {
    try {
      // 既に同じバッジを持っているか確認
      final existing = await _firestore
          .collection('user_badges')
          .where('userId', isEqualTo: userId)
          .where('badgeId', isEqualTo: badge.badgeId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        return false; // すでに付与済み
      }

      await _firestore.collection('user_badges').add({
        'userId': userId,
        'badgeId': badge.badgeId,
        'unlockedAt': FieldValue.serverTimestamp(),
        'progress': badge.requiredValue,
        'requiredValue': badge.requiredValue,
        'isNew': true,
      });
      return true;
    } catch (e) {
      debugPrint('Error awarding badge: $e');
      throw Exception('バッジの保存に失敗しました');
    }
  }

  // 利用可能なバッジ一覧を取得
  Future<List<BadgeModel>> getAvailableBadges() async {
    try {
      final querySnapshot = await _firestore
          .collection('badges')
          .orderBy('requiredValue')
          .get();

      return querySnapshot.docs
          .map((doc) => BadgeModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching available badges: $e');
      // Firestoreの権限エラーの場合は空のリストを返す
      if (e.toString().contains('permission-denied')) {
        return [];
      }
      throw Exception('バッジ一覧の取得に失敗しました');
    }
  }

  // バッジの進捗状況を取得
  Future<Map<String, int>> getBadgeProgress(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('badge_progress')
          .where('userId', isEqualTo: userId)
          .get();

      final Map<String, int> progress = {};
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        progress[data['badgeType']] = data['currentValue'] ?? 0;
      }
      return progress;
    } catch (e) {
      debugPrint('Error fetching badge progress: $e');
      return {};
    }
  }

  // バッジの進捗を更新
  Future<void> updateBadgeProgress({
    required String userId,
    required BadgeType badgeType,
    required int increment,
  }) async {
    try {
      final progressRef = _firestore
          .collection('badge_progress')
          .doc('${userId}_${badgeType.name}');

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(progressRef);
        
        int currentValue = 0;
        if (snapshot.exists) {
          currentValue = snapshot.data()?['currentValue'] ?? 0;
        }

        final newValue = currentValue + increment;
        
        transaction.set(progressRef, {
          'userId': userId,
          'badgeType': badgeType.name,
          'currentValue': newValue,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        // バッジの条件をチェックして、達成した場合はバッジを付与
        await _checkAndAwardBadge(userId, badgeType, newValue);
      });
    } catch (e) {
      debugPrint('Error updating badge progress: $e');
      throw Exception('バッジ進捗の更新に失敗しました');
    }
  }

  // バッジの条件をチェックして付与
  Future<void> _checkAndAwardBadge(String userId, BadgeType badgeType, int currentValue) async {
    try {
      // 該当するバッジを検索
      final badgesSnapshot = await _firestore
          .collection('badges')
          .where('type', isEqualTo: badgeType.name)
          .where('requiredValue', isLessThanOrEqualTo: currentValue)
          .get();

      for (final badgeDoc in badgesSnapshot.docs) {
        final badge = BadgeModel.fromJson(badgeDoc.data());
        
        // 既に獲得済みかチェック
        final existingBadge = await _firestore
            .collection('user_badges')
            .where('userId', isEqualTo: userId)
            .where('badgeId', isEqualTo: badge.badgeId)
            .get();

        if (existingBadge.docs.isEmpty) {
          // バッジを付与
          await _firestore.collection('user_badges').add({
            'userId': userId,
            'badgeId': badge.badgeId,
            'unlockedAt': FieldValue.serverTimestamp(),
            'progress': currentValue,
            'requiredValue': badge.requiredValue,
            'isNew': true,
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking and awarding badge: $e');
    }
  }

  // バッジを新規フラグを解除
  Future<void> markBadgeAsSeen(String userId, String badgeId) async {
    try {
      final querySnapshot = await _firestore
          .collection('user_badges')
          .where('userId', isEqualTo: userId)
          .where('badgeId', isEqualTo: badgeId)
          .get();

      for (final doc in querySnapshot.docs) {
        await doc.reference.update({'isNew': false});
      }
    } catch (e) {
      debugPrint('Error marking badge as seen: $e');
    }
  }

  // 新規バッジの数を取得
  Future<int> getNewBadgeCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('user_badges')
          .where('userId', isEqualTo: userId)
          .where('isNew', isEqualTo: true)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting new badge count: $e');
      return 0;
    }
  }
}
