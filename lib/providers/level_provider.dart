import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/level_model.dart';

// レベルプロバイダー
final levelProvider = Provider<LevelService>((ref) {
  return LevelService();
});

// ユーザーのレベル情報
final userLevelProvider = FutureProvider.family<UserLevelModel?, String>((ref, userId) async {
  final levelService = ref.read(levelProvider);
  return await levelService.getUserLevel(userId);
});

// レベル一覧
final levelsProvider = FutureProvider<List<LevelModel>>((ref) async {
  final levelService = ref.read(levelProvider);
  return await levelService.getLevels();
});

// レベルアップ通知
final levelUpNotifierProvider = StateNotifierProvider<LevelUpNotifier, LevelUpState>((ref) {
  return LevelUpNotifier();
});

class LevelUpState {
  final bool isLevelUp;
  final LevelModel? newLevel;
  final List<String> rewards;

  LevelUpState({
    this.isLevelUp = false,
    this.newLevel,
    this.rewards = const [],
  });

  LevelUpState copyWith({
    bool? isLevelUp,
    LevelModel? newLevel,
    List<String>? rewards,
  }) {
    return LevelUpState(
      isLevelUp: isLevelUp ?? this.isLevelUp,
      newLevel: newLevel ?? this.newLevel,
      rewards: rewards ?? this.rewards,
    );
  }
}

class LevelUpNotifier extends StateNotifier<LevelUpState> {
  LevelUpNotifier() : super(LevelUpState());

  void showLevelUp(LevelModel newLevel, List<String> rewards) {
    state = LevelUpState(
      isLevelUp: true,
      newLevel: newLevel,
      rewards: rewards,
    );
  }

  void hideLevelUp() {
    state = LevelUpState();
  }
}

class LevelService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int maxLevel = 100;

  // 1レベルあたりの必要経験値（シンプルに100固定）
  // UIの進捗表示と整合が取れるよう、各レベル100XPで統一します。
  int requiredExperienceForLevel(int level) {
    if (level >= maxLevel) return 0; // 以降は上限
    return 100;
  }

  // 指定レベル到達までに必要な累計経験値（レベル1 -> 0, レベル2 -> 100, ...）
  int totalExperienceToReachLevel(int level) {
    if (level <= 1) return 0;
    final cappedLevel = level.clamp(1, maxLevel);
    return 100 * (cappedLevel - 1);
  }

  // 累計経験値からレベルを計算（最大100）
  int levelFromTotalExperience(int totalExperience) {
    if (totalExperience <= 0) return 1;
    final level = (totalExperience ~/ 100) + 1;
    return level > maxLevel ? maxLevel : level;
  }

  // 現在の累計経験値から次レベルまでに必要な残り経験値
  int remainingExperienceToNextLevel(int totalExperience) {
    final currentLevel = levelFromTotalExperience(totalExperience);
    if (currentLevel >= maxLevel) return 0;
    final base = totalExperienceToReachLevel(currentLevel + 1);
    return (base - totalExperience).clamp(0, requiredExperienceForLevel(currentLevel));
  }

  // 経験値報酬（支払い）: 10ポイント消費ごとに1XP（最低1）
  int experienceForPayment(int amount) {
    if (amount <= 0) return 0;
    final xp = amount ~/ 10;
    return xp > 0 ? xp : 1;
  }

  // 経験値報酬（スタンプ押印/コンプリート）
  int experienceForStampPunch() => 10;
  int experienceForStampCardComplete() => 100;

  // 経験値報酬（バッジ獲得）
  int experienceForBadgeByRarity(String? rarity) {
    switch ((rarity ?? '').toLowerCase()) {
      case 'legendary':
        return 1000;
      case 'epic':
        return 400;
      case 'rare':
        return 150;
      case 'common':
        return 50;
      default:
        return 50;
    }
  }

  // ユーザーのレベル情報を取得
  Future<UserLevelModel?> getUserLevel(String userId) async {
    try {
      final doc = await _firestore
          .collection('user_levels')
          .doc(userId)
          .get();

      if (doc.exists) {
        return UserLevelModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user level: $e');
      return null;
    }
  }

  // レベル一覧を取得
  Future<List<LevelModel>> getLevels() async {
    try {
      final querySnapshot = await _firestore
          .collection('levels')
          .orderBy('level')
          .get();

      return querySnapshot.docs
          .map((doc) => LevelModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching levels: $e');
      // Firestoreの権限エラーの場合は空のリストを返す
      if (e.toString().contains('permission-denied')) {
        return [];
      }
      return [];
    }
  }

  // ポイントを追加してレベルアップをチェック
  Future<UserLevelModel> addPoints({
    required String userId,
    required int points,
  }) async {
    try {
      final userLevelRef = _firestore.collection('user_levels').doc(userId);
      
      return await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userLevelRef);
        final userDocRef = _firestore.collection('users').doc(userId);
        final userSnapshot = await transaction.get(userDocRef);
        
        UserLevelModel currentLevel;
        if (snapshot.exists) {
          currentLevel = UserLevelModel.fromJson(snapshot.data()!);
        } else {
          // 新規ユーザーの場合
          currentLevel = UserLevelModel(
            userId: userId,
            currentLevel: 1,
            currentPoints: 0,
            totalPoints: 0,
            lastUpdated: DateTime.now(),
          );
        }

        final unclampedTotal = currentLevel.totalPoints + points;
        final totalPoints = unclampedTotal.clamp(0, totalExperienceToReachLevel(maxLevel) + requiredExperienceForLevel(maxLevel));

        // 新しいレベル（最大100）
        final newLevel = levelFromTotalExperience(totalPoints);

        // 現在レベル内の経験値（レベル到達に必要な累計を差し引く）
        final levelBase = totalExperienceToReachLevel(newLevel);
        final newCurrentPoints = totalPoints - levelBase;

        final updatedLevel = currentLevel.copyWith(
          currentLevel: newLevel,
          currentPoints: newCurrentPoints,
          totalPoints: totalPoints,
          lastUpdated: DateTime.now(),
        );

        transaction.set(userLevelRef, updatedLevel.toJson());

        // users コレクションにも experience と level を同期
        int currentUserExperience = 0;
        if (userSnapshot.exists) {
          final data = userSnapshot.data() as Map<String, dynamic>;
          currentUserExperience = (data['experience'] is num) ? (data['experience'] as num).toInt() : 0;
        }
        final newUserExperience = (currentUserExperience + points).clamp(0, totalExperienceToReachLevel(maxLevel) + requiredExperienceForLevel(maxLevel));
        final newUserLevel = levelFromTotalExperience(newUserExperience);

        transaction.set(userDocRef, {
          'experience': newUserExperience,
          'level': newUserLevel,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        return updatedLevel;
      });
    } catch (e) {
      debugPrint('Error adding points: $e');
      throw Exception('ポイントの追加に失敗しました');
    }
  }

  // ポイントからレベルを計算
  int _calculateLevel(int totalPoints) {
    return levelFromTotalExperience(totalPoints);
  }

  // エイリアス（可読性のため）
  Future<UserLevelModel> addExperience({
    required String userId,
    required int experience,
  }) {
    return addPoints(userId: userId, points: experience);
  }

  // レベルアップ報酬を取得
  Future<List<String>> getLevelUpRewards(int newLevel) async {
    try {
      final levelDoc = await _firestore
          .collection('levels')
          .doc(newLevel.toString())
          .get();

      if (levelDoc.exists) {
        final level = LevelModel.fromJson(levelDoc.data()!);
        return level.rewards;
      }
      return [];
    } catch (e) {
      debugPrint('Error getting level up rewards: $e');
      return [];
    }
  }

  // ユーザーレベルを初期化
  Future<UserLevelModel> initializeUserLevel(String userId) async {
    try {
      final userLevel = UserLevelModel(
        userId: userId,
        currentLevel: 1,
        currentPoints: 0,
        totalPoints: 0,
        lastUpdated: DateTime.now(),
      );

      await _firestore
          .collection('user_levels')
          .doc(userId)
          .set(userLevel.toJson());

      return userLevel;
    } catch (e) {
      debugPrint('Error initializing user level: $e');
      throw Exception('ユーザーレベルの初期化に失敗しました');
    }
  }
}
