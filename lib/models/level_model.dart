import 'package:freezed_annotation/freezed_annotation.dart';

part 'level_model.freezed.dart';
part 'level_model.g.dart';

@freezed
class LevelModel with _$LevelModel {
  const factory LevelModel({
    required int level,
    required String name,
    required int requiredPoints,
    required String description,
    required String iconUrl,
    required List<String> rewards,
    @Default(0) int maxPoints,
  }) = _LevelModel;

  factory LevelModel.fromJson(Map<String, dynamic> json) => _$LevelModelFromJson(json);
}

@freezed
class UserLevelModel with _$UserLevelModel {
  const factory UserLevelModel({
    required String userId,
    required int currentLevel,
    required int currentPoints,
    required int totalPoints,
    required DateTime lastUpdated,
    @Default(0) int experienceMultiplier,
  }) = _UserLevelModel;

  factory UserLevelModel.fromJson(Map<String, dynamic> json) => _$UserLevelModelFromJson(json);
}

extension LevelModelExtension on LevelModel {
  double get progressPercentage {
    if (maxPoints == 0) return 0.0;
    return (requiredPoints / maxPoints).clamp(0.0, 1.0);
  }

  String get levelTitle {
    if (level <= 5) return '初心者';
    if (level <= 10) return '中級者';
    if (level <= 20) return '上級者';
    if (level <= 30) return 'エキスパート';
    return 'マスター';
  }
}

extension UserLevelModelExtension on UserLevelModel {
  int get pointsToNextLevel {
    // 次のレベルの必要ポイント数を計算
    final nextLevel = currentLevel + 1;
    final nextLevelRequired = _calculateRequiredPoints(nextLevel);
    return nextLevelRequired - currentPoints;
  }

  double get progressToNextLevel {
    final currentLevelRequired = _calculateRequiredPoints(currentLevel);
    final nextLevelRequired = _calculateRequiredPoints(currentLevel + 1);
    final progress = currentPoints - currentLevelRequired;
    final total = nextLevelRequired - currentLevelRequired;
    return (progress / total).clamp(0.0, 1.0);
  }

  double get currentLevelProgress {
    return progressToNextLevel;
  }

  int _calculateRequiredPoints(int level) {
    // レベルに応じた必要ポイント数を計算（例：レベル^2 * 100）
    return (level * level * 100).clamp(0, 999999);
  }
}
