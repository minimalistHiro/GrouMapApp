import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/level_model.dart';
import '../providers/auth_provider.dart';

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

        final newTotalPoints = currentLevel.totalPoints + points;
        final newCurrentPoints = currentLevel.currentPoints + points;
        
        // レベルアップをチェック
        final newLevel = _calculateLevel(newTotalPoints);
        final levelUp = newLevel > currentLevel.currentLevel;
        
        final updatedLevel = currentLevel.copyWith(
          currentLevel: newLevel,
          currentPoints: newCurrentPoints,
          totalPoints: newTotalPoints,
          lastUpdated: DateTime.now(),
        );

        transaction.set(userLevelRef, updatedLevel.toJson());

        return updatedLevel;
      });
    } catch (e) {
      debugPrint('Error adding points: $e');
      throw Exception('ポイントの追加に失敗しました');
    }
  }

  // ポイントからレベルを計算
  int _calculateLevel(int totalPoints) {
    // レベル計算式: sqrt(points / 100) + 1
    return math.sqrt(totalPoints / 100).floor() + 1;
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
