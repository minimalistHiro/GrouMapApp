// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_point_balance_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserPointBalanceImpl _$$UserPointBalanceImplFromJson(
        Map<String, dynamic> json) =>
    _$UserPointBalanceImpl(
      userId: json['userId'] as String,
      totalPoints: (json['totalPoints'] as num).toInt(),
      availablePoints: (json['availablePoints'] as num).toInt(),
      usedPoints: (json['usedPoints'] as num).toInt(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$$UserPointBalanceImplToJson(
        _$UserPointBalanceImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'totalPoints': instance.totalPoints,
      'availablePoints': instance.availablePoints,
      'usedPoints': instance.usedPoints,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
    };
