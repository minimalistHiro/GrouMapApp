// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'level_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LevelModelImpl _$$LevelModelImplFromJson(Map<String, dynamic> json) =>
    _$LevelModelImpl(
      level: (json['level'] as num).toInt(),
      name: json['name'] as String,
      requiredPoints: (json['requiredPoints'] as num).toInt(),
      description: json['description'] as String,
      iconUrl: json['iconUrl'] as String,
      rewards:
          (json['rewards'] as List<dynamic>).map((e) => e as String).toList(),
      maxPoints: (json['maxPoints'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$LevelModelImplToJson(_$LevelModelImpl instance) =>
    <String, dynamic>{
      'level': instance.level,
      'name': instance.name,
      'requiredPoints': instance.requiredPoints,
      'description': instance.description,
      'iconUrl': instance.iconUrl,
      'rewards': instance.rewards,
      'maxPoints': instance.maxPoints,
    };

_$UserLevelModelImpl _$$UserLevelModelImplFromJson(Map<String, dynamic> json) =>
    _$UserLevelModelImpl(
      userId: json['userId'] as String,
      currentLevel: (json['currentLevel'] as num).toInt(),
      currentPoints: (json['currentPoints'] as num).toInt(),
      totalPoints: (json['totalPoints'] as num).toInt(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      experienceMultiplier:
          (json['experienceMultiplier'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$UserLevelModelImplToJson(
        _$UserLevelModelImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'currentLevel': instance.currentLevel,
      'currentPoints': instance.currentPoints,
      'totalPoints': instance.totalPoints,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
      'experienceMultiplier': instance.experienceMultiplier,
    };
