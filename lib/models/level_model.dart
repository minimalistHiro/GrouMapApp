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

// UserLevelModel was removed along with user_levels collection usage.
