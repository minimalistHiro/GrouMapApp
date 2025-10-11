import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/level_model.dart';

// レベルプロバイダー
final levelProvider = Provider<LevelService>((ref) {
  return LevelService();
});

// user_levels は廃止方針。ただしモデル型は他所の型整合のため残し、Firestore操作は users のみを使用します。

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

  // user_levels は廃止。ユーザーレベルの取得は users の level/experience を直接参照してください。

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

  // 経験値を追加（users のみを更新）
  Future<void> addExperience({
    required String userId,
    required int experience,
  }) async {
    if (experience == 0) return;
    try {
      final userDocRef = _firestore.collection('users').doc(userId);
      await _firestore.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userDocRef);
        int currentUserExperience = 0;
        if (userSnapshot.exists) {
          final data = userSnapshot.data() as Map<String, dynamic>;
          currentUserExperience = (data['experience'] is num) ? (data['experience'] as num).toInt() : 0;
        }
        final maxTotal = totalExperienceToReachLevel(maxLevel) + requiredExperienceForLevel(maxLevel);
        final newUserExperience = (currentUserExperience + experience).clamp(0, maxTotal);
        final newUserLevel = levelFromTotalExperience(newUserExperience);

        transaction.set(userDocRef, {
          'experience': newUserExperience,
          'level': newUserLevel,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint('Error adding experience to users: $e');
      rethrow;
    }
  }

  // ポイントからレベルを計算
  int _calculateLevel(int totalPoints) {
    return levelFromTotalExperience(totalPoints);
  }

  // user_levels 廃止に伴い addPoints は削除。addExperience のみ使用します。

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

  // initializeUserLevel は廃止。
}
