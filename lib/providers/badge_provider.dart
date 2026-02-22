import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/badge_model.dart';
import '../data/badge_definitions.dart';

// バッジプロバイダー
final badgeProvider = Provider<BadgeService>((ref) {
  return BadgeService();
});

// ユーザーのバッジ一覧
final userBadgesProvider = FutureProvider.family<List<UserBadgeModel>, String>((ref, userId) async {
  final badgeService = ref.read(badgeProvider);
  return await badgeService.getUserBadges(userId);
});

// 利用可能なバッジ一覧（内蔵データから取得）
final availableBadgesProvider = Provider<List<BadgeModel>>((ref) {
  return List.from(kBadgeDefinitions)
    ..sort((a, b) => a.requiredValue.compareTo(b.requiredValue));
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
          .doc(userId)
          .collection('badges')
          .orderBy('unlockedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        // FirestoreのTimestampをISO8601文字列に変換
        if (data['unlockedAt'] is Timestamp) {
          data['unlockedAt'] = (data['unlockedAt'] as Timestamp).toDate().toIso8601String();
        } else if (data['unlockedAt'] == null) {
          data['unlockedAt'] = DateTime.now().toIso8601String();
        }
        // nullの場合のデフォルト値を設定
        data['progress'] ??= 0;
        data['requiredValue'] ??= 0;
        return UserBadgeModel.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching user badges: $e');
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
      final badgeRef = _firestore
          .collection('user_badges')
          .doc(userId)
          .collection('badges')
          .doc(badge.badgeId);

      final existing = await badgeRef.get();
      if (existing.exists) {
        return false;
      }

      await badgeRef.set({
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

  // 利用可能なバッジ一覧を取得（内蔵データ）
  Future<List<BadgeModel>> getAvailableBadges() async {
    return List.from(kBadgeDefinitions)
      ..sort((a, b) => a.requiredValue.compareTo(b.requiredValue));
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

  // バッジの条件をチェックして付与（内蔵データから判定）
  Future<void> _checkAndAwardBadge(String userId, BadgeType badgeType, int currentValue) async {
    try {
      final matchingBadges = kBadgeDefinitions
          .where((b) => b.type == badgeType && b.requiredValue <= currentValue)
          .toList();

      for (final badge in matchingBadges) {
        final badgeRef = _firestore
            .collection('user_badges')
            .doc(userId)
            .collection('badges')
            .doc(badge.badgeId);

        final existingBadge = await badgeRef.get();

        if (!existingBadge.exists) {
          await badgeRef.set({
            'userId': userId,
            'badgeId': badge.badgeId,
            'name': badge.name,
            'description': badge.description,
            'iconUrl': badge.iconUrl,
            'rarity': badge.rarity.name,
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
      await _firestore
          .collection('user_badges')
          .doc(userId)
          .collection('badges')
          .doc(badgeId)
          .update({'isNew': false});
    } catch (e) {
      debugPrint('Error marking badge as seen: $e');
    }
  }

  // 複数バッジのisNewフラグを一括解除
  Future<void> markBadgesAsSeen(String userId, List<String> badgeIds) async {
    if (badgeIds.isEmpty) return;
    try {
      final batch = _firestore.batch();
      for (final id in badgeIds) {
        batch.update(
          _firestore.collection('user_badges').doc(userId).collection('badges').doc(id),
          {'isNew': false},
        );
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking badges as seen: $e');
    }
  }

  // 新規バッジの数を取得
  Future<int> getNewBadgeCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('user_badges')
          .doc(userId)
          .collection('badges')
          .where('isNew', isEqualTo: true)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting new badge count: $e');
      return 0;
    }
  }

  // 軽量チェック: isNew: true のバッジ一覧を取得（毎回ホーム画面表示時）
  // ローカル定義（kBadgeDefinitions）に存在するバッジのみ返す
  Future<List<Map<String, dynamic>>> getNewBadges(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('user_badges')
          .doc(userId)
          .collection('badges')
          .where('isNew', isEqualTo: true)
          .get();

      final validBadgeIds = kBadgeDefinitions.map((b) => b.badgeId).toSet();
      final List<Map<String, dynamic>> validBadges = [];
      final List<String> obsoleteBadgeIds = [];

      for (final d in snapshot.docs) {
        final badgeId = d.id;
        if (validBadgeIds.contains(badgeId)) {
          final data = d.data();
          data['badgeId'] = badgeId;
          // ローカル定義の情報で上書き（最新のname/iconUrl等を使用）
          final localBadge = findBadgeById(badgeId);
          if (localBadge != null) {
            data['name'] = localBadge.name;
            data['description'] = localBadge.description;
            data['iconUrl'] = localBadge.iconUrl;
            data['rarity'] = localBadge.rarity.name;
          }
          validBadges.add(data);
        } else {
          obsoleteBadgeIds.add(badgeId);
        }
      }

      // 旧バッジのisNewフラグをバックグラウンドで解除
      if (obsoleteBadgeIds.isNotEmpty) {
        debugPrint('旧バッジ ${obsoleteBadgeIds.length}件のisNewフラグを解除');
        markBadgesAsSeen(userId, obsoleteBadgeIds);
      }

      return validBadges;
    } catch (e) {
      debugPrint('Error getting new badges: $e');
      return [];
    }
  }

  // バッジカウンターインクリメント（badge_progressに記録 + 即時バッジ判定）
  Future<void> incrementBadgeCounter(String userId, String counterKey) async {
    try {
      final docRef = _firestore
          .collection('badge_progress')
          .doc('${userId}_$counterKey');

      await docRef.set({
        'userId': userId,
        'badgeType': counterKey,
        'currentValue': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // インクリメント後の値を取得してバッジ判定を実行
      final snapshot = await docRef.get();
      final newValue = (snapshot.data()?['currentValue'] as num?)?.toInt() ?? 0;

      // counterKeyに対応するBadgeTypeを特定
      final badgeType = BadgeType.values.cast<BadgeType?>().firstWhere(
        (e) => e?.name == counterKey,
        orElse: () => null,
      );

      if (badgeType != null) {
        await _checkAndAwardBadge(userId, badgeType, newValue);
      }
    } catch (e) {
      debugPrint('Error incrementing badge counter ($counterKey): $e');
    }
  }

  // 包括バッジチェック（日次初ログイン時に実行）
  Future<List<Map<String, dynamic>>> runComprehensiveBadgeCheck(String userId) async {
    try {
      // 1. 既存バッジID一覧を取得
      final existingBadgesSnapshot = await _firestore
          .collection('user_badges')
          .doc(userId)
          .collection('badges')
          .get();
      final existingBadgeIds = existingBadgesSnapshot.docs.map((d) => d.id).toSet();

      // 2. 各データソースから現在値を並列取得
      final results = await Future.wait([
        _getUserDoc(userId),                    // 0: userDoc
        _getUserStores(userId),                 // 1: userStores
        _getBadgeProgressValues(userId),        // 2: badge_progress
      ]);

      final userDoc = results[0] as Map<String, dynamic>?;
      final userStores = results[1] as List<Map<String, dynamic>>;
      final badgeProgressMap = results[2] as Map<String, int>;

      // 3. 各バッジタイプの現在値を算出
      final Map<String, int> currentValues = {};

      // stampsTotal: ユーザーの全店舗のスタンプ合計
      int totalStamps = 0;
      for (final store in userStores) {
        totalStamps += (store['stamps'] as num?)?.toInt() ?? 0;
      }
      currentValues['stampsTotal'] = totalStamps;

      // visitsCount: ユーザーの全店舗の来店回数合計
      int totalVisits = 0;
      for (final store in userStores) {
        totalVisits += (store['totalVisits'] as num?)?.toInt() ?? 0;
      }
      currentValues['visitsCount'] = totalVisits;

      // consecutiveDays: ログインストリーク
      currentValues['consecutiveDays'] = (userDoc?['loginStreak'] as num?)?.toInt() ?? 0;

      // storesVisited: 訪問店舗数
      currentValues['storesVisited'] = userStores.length;

      // favoriteAdded: お気に入り店舗数
      final favoriteIds = userDoc?['favoriteStoreIds'];
      currentValues['favoriteAdded'] = (favoriteIds is List) ? favoriteIds.length : 0;

      // profileCompleted: プロフィール完成
      final missionProgress = userDoc?['missionProgress'];
      final profileCompleted = (missionProgress is Map && missionProgress['profile_completed'] == true) ? 1 : 0;
      currentValues['profileCompleted'] = profileCompleted;

      // coinsEarned: コイン累計獲得（badge_progressから）
      currentValues['coinsEarned'] = badgeProgressMap['coinsEarned'] ?? 0;

      // badge_progress由来のカウンター
      for (final key in [
        'specialEvents', 'mapOpened', 'storeDetailViewed',
        'slotPlayed', 'slotWin', 'couponUsed', 'likeGiven',
        'commentPosted', 'followUser', 'missionCompleted',
        'recommendViewed', 'stampCardCompleted',
      ]) {
        currentValues[key] = badgeProgressMap[key] ?? 0;
      }

      // カテゴリ別来店カウント
      final Map<String, int> categoryVisitCounts = {};
      for (final store in userStores) {
        final storeCategory = store['category'] as String?;
        if (storeCategory == null) continue;
        final groupKey = findCategoryGroupKey(storeCategory);
        if (groupKey != null) {
          categoryVisitCounts[groupKey] = (categoryVisitCounts[groupKey] ?? 0) + 1;
        }
      }

      // 4. 全バッジ定義と比較、新規バッジを付与
      final newlyAwarded = <Map<String, dynamic>>[];
      final batch = _firestore.batch();
      bool hasBatchWrites = false;

      for (final badge in kBadgeDefinitions) {
        if (existingBadgeIds.contains(badge.badgeId)) continue;

        int currentValue;
        if (badge.type == BadgeType.categoryVisit) {
          currentValue = categoryVisitCounts[badge.categoryGroupKey] ?? 0;
        } else {
          currentValue = currentValues[badge.type.name] ?? 0;
        }

        if (currentValue >= badge.requiredValue) {
          final badgeRef = _firestore
              .collection('user_badges')
              .doc(userId)
              .collection('badges')
              .doc(badge.badgeId);

          batch.set(badgeRef, {
            'userId': userId,
            'badgeId': badge.badgeId,
            'name': badge.name,
            'description': badge.description,
            'iconUrl': badge.iconUrl,
            'rarity': badge.rarity.name,
            'unlockedAt': FieldValue.serverTimestamp(),
            'progress': currentValue,
            'requiredValue': badge.requiredValue,
            'isNew': true,
          });
          hasBatchWrites = true;

          newlyAwarded.add({
            'badgeId': badge.badgeId,
            'name': badge.name,
            'description': badge.description,
            'iconUrl': badge.iconUrl,
            'rarity': badge.rarity.name,
            'alreadyOwned': false,
          });
        }
      }

      if (hasBatchWrites) {
        await batch.commit();
      }

      debugPrint('包括バッジチェック完了: ${newlyAwarded.length}個の新規バッジを付与');
      return newlyAwarded;
    } catch (e) {
      debugPrint('Error in comprehensive badge check: $e');
      return [];
    }
  }

  // ユーザードキュメント取得
  Future<Map<String, dynamic>?> _getUserDoc(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      debugPrint('Error getting user doc: $e');
      return null;
    }
  }

  // ユーザーの店舗サブコレクション取得（スタンプ・来店・カテゴリ用）
  Future<List<Map<String, dynamic>>> _getUserStores(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('stores')
          .get();
      return snapshot.docs.map((d) {
        final data = d.data();
        data['storeId'] = d.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error getting user stores: $e');
      return [];
    }
  }

  // badge_progressの全カウンター取得
  Future<Map<String, int>> _getBadgeProgressValues(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('badge_progress')
          .where('userId', isEqualTo: userId)
          .get();

      final Map<String, int> values = {};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final key = data['badgeType'] as String? ?? '';
        if (key.isNotEmpty) {
          values[key] = (data['currentValue'] as num?)?.toInt() ?? 0;
        }
      }
      return values;
    } catch (e) {
      debugPrint('Error getting badge progress values: $e');
      return {};
    }
  }
}
