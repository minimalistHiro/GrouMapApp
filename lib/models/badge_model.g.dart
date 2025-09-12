// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'badge_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BadgeModelImpl _$$BadgeModelImplFromJson(Map<String, dynamic> json) =>
    _$BadgeModelImpl(
      badgeId: json['badgeId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconUrl: json['iconUrl'] as String,
      type: $enumDecode(_$BadgeTypeEnumMap, json['type']),
      requiredValue: (json['requiredValue'] as num).toInt(),
      rarity: $enumDecode(_$BadgeRarityEnumMap, json['rarity']),
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] == null
          ? null
          : DateTime.parse(json['unlockedAt'] as String),
      category: json['category'] as String?,
    );

Map<String, dynamic> _$$BadgeModelImplToJson(_$BadgeModelImpl instance) =>
    <String, dynamic>{
      'badgeId': instance.badgeId,
      'name': instance.name,
      'description': instance.description,
      'iconUrl': instance.iconUrl,
      'type': _$BadgeTypeEnumMap[instance.type]!,
      'requiredValue': instance.requiredValue,
      'rarity': _$BadgeRarityEnumMap[instance.rarity]!,
      'isUnlocked': instance.isUnlocked,
      'unlockedAt': instance.unlockedAt?.toIso8601String(),
      'category': instance.category,
    };

const _$BadgeTypeEnumMap = {
  BadgeType.pointsEarned: 'points_earned',
  BadgeType.visitsCount: 'visits_count',
  BadgeType.consecutiveDays: 'consecutive_days',
  BadgeType.qrScans: 'qr_scans',
  BadgeType.storesVisited: 'stores_visited',
  BadgeType.specialEvents: 'special_events',
};

const _$BadgeRarityEnumMap = {
  BadgeRarity.common: 'common',
  BadgeRarity.rare: 'rare',
  BadgeRarity.epic: 'epic',
  BadgeRarity.legendary: 'legendary',
};

_$UserBadgeModelImpl _$$UserBadgeModelImplFromJson(Map<String, dynamic> json) =>
    _$UserBadgeModelImpl(
      userId: json['userId'] as String,
      badgeId: json['badgeId'] as String,
      unlockedAt: DateTime.parse(json['unlockedAt'] as String),
      progress: (json['progress'] as num).toInt(),
      requiredValue: (json['requiredValue'] as num).toInt(),
      isNew: json['isNew'] as bool? ?? false,
    );

Map<String, dynamic> _$$UserBadgeModelImplToJson(
        _$UserBadgeModelImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'badgeId': instance.badgeId,
      'unlockedAt': instance.unlockedAt.toIso8601String(),
      'progress': instance.progress,
      'requiredValue': instance.requiredValue,
      'isNew': instance.isNew,
    };
