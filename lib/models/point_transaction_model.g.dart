// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'point_transaction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PointTransactionModelImpl _$$PointTransactionModelImplFromJson(
        Map<String, dynamic> json) =>
    _$PointTransactionModelImpl(
      transactionId: json['transactionId'] as String,
      userId: json['userId'] as String,
      storeId: json['storeId'] as String,
      points: (json['points'] as num).toInt(),
      type: PointTransactionType.fromJson(json['type'] as Map<String, dynamic>),
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      qrCodeId: json['qrCodeId'] as String?,
      referenceId: json['referenceId'] as String?,
      isProcessed: json['isProcessed'] as bool? ?? false,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$$PointTransactionModelImplToJson(
        _$PointTransactionModelImpl instance) =>
    <String, dynamic>{
      'transactionId': instance.transactionId,
      'userId': instance.userId,
      'storeId': instance.storeId,
      'points': instance.points,
      'type': instance.type,
      'description': instance.description,
      'timestamp': instance.timestamp.toIso8601String(),
      'qrCodeId': instance.qrCodeId,
      'referenceId': instance.referenceId,
      'isProcessed': instance.isProcessed,
      'notes': instance.notes,
    };

_$PointEarnedImpl _$$PointEarnedImplFromJson(Map<String, dynamic> json) =>
    _$PointEarnedImpl(
      reason: json['reason'] as String,
      multiplier: (json['multiplier'] as num?)?.toDouble() ?? 1.0,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$PointEarnedImplToJson(_$PointEarnedImpl instance) =>
    <String, dynamic>{
      'reason': instance.reason,
      'multiplier': instance.multiplier,
      'runtimeType': instance.$type,
    };

_$PointUsedImpl _$$PointUsedImplFromJson(Map<String, dynamic> json) =>
    _$PointUsedImpl(
      reason: json['reason'] as String,
      amountUsed: (json['amountUsed'] as num).toInt(),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$PointUsedImplToJson(_$PointUsedImpl instance) =>
    <String, dynamic>{
      'reason': instance.reason,
      'amountUsed': instance.amountUsed,
      'runtimeType': instance.$type,
    };

_$PointExpiredImpl _$$PointExpiredImplFromJson(Map<String, dynamic> json) =>
    _$PointExpiredImpl(
      reason: json['reason'] as String,
      expiredAmount: (json['expiredAmount'] as num).toInt(),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$PointExpiredImplToJson(_$PointExpiredImpl instance) =>
    <String, dynamic>{
      'reason': instance.reason,
      'expiredAmount': instance.expiredAmount,
      'runtimeType': instance.$type,
    };

_$PointRefundedImpl _$$PointRefundedImplFromJson(Map<String, dynamic> json) =>
    _$PointRefundedImpl(
      reason: json['reason'] as String,
      refundedAmount: (json['refundedAmount'] as num).toInt(),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$PointRefundedImplToJson(_$PointRefundedImpl instance) =>
    <String, dynamic>{
      'reason': instance.reason,
      'refundedAmount': instance.refundedAmount,
      'runtimeType': instance.$type,
    };

_$UserPointBalanceImpl _$$UserPointBalanceImplFromJson(
        Map<String, dynamic> json) =>
    _$UserPointBalanceImpl(
      userId: json['userId'] as String,
      totalPoints: (json['totalPoints'] as num).toInt(),
      availablePoints: (json['availablePoints'] as num).toInt(),
      usedPoints: (json['usedPoints'] as num).toInt(),
      expiredPoints: (json['expiredPoints'] as num).toInt(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      recentTransactions: (json['recentTransactions'] as List<dynamic>?)
              ?.map((e) =>
                  PointTransactionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$UserPointBalanceImplToJson(
        _$UserPointBalanceImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'totalPoints': instance.totalPoints,
      'availablePoints': instance.availablePoints,
      'usedPoints': instance.usedPoints,
      'expiredPoints': instance.expiredPoints,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
      'recentTransactions': instance.recentTransactions,
    };

_$QRCodeModelImpl _$$QRCodeModelImplFromJson(Map<String, dynamic> json) =>
    _$QRCodeModelImpl(
      qrCodeId: json['qrCodeId'] as String,
      storeId: json['storeId'] as String,
      points: (json['points'] as num).toInt(),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdBy: json['createdBy'] as String,
      isUsed: json['isUsed'] as bool? ?? false,
      usedBy: json['usedBy'] as String?,
      usedAt: json['usedAt'] == null
          ? null
          : DateTime.parse(json['usedAt'] as String),
      description: json['description'] as String?,
    );

Map<String, dynamic> _$$QRCodeModelImplToJson(_$QRCodeModelImpl instance) =>
    <String, dynamic>{
      'qrCodeId': instance.qrCodeId,
      'storeId': instance.storeId,
      'points': instance.points,
      'expiresAt': instance.expiresAt.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'createdBy': instance.createdBy,
      'isUsed': instance.isUsed,
      'usedBy': instance.usedBy,
      'usedAt': instance.usedAt?.toIso8601String(),
      'description': instance.description,
    };
