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
      storeName: json['storeName'] as String,
      amount: (json['amount'] as num).toInt(),
      paymentAmount: (json['paymentAmount'] as num?)?.toInt(),
      status: json['status'] as String? ?? 'completed',
      paymentMethod: json['paymentMethod'] as String? ?? 'points',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      description: json['description'] as String?,
      qrCode: json['qrCode'] as String?,
      refundedAt: json['refundedAt'] == null
          ? null
          : DateTime.parse(json['refundedAt'] as String),
      refundReason: json['refundReason'] as String?,
    );

Map<String, dynamic> _$$PointTransactionModelImplToJson(
        _$PointTransactionModelImpl instance) =>
    <String, dynamic>{
      'transactionId': instance.transactionId,
      'userId': instance.userId,
      'storeId': instance.storeId,
      'storeName': instance.storeName,
      'amount': instance.amount,
      'paymentAmount': instance.paymentAmount,
      'status': instance.status,
      'paymentMethod': instance.paymentMethod,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'description': instance.description,
      'qrCode': instance.qrCode,
      'refundedAt': instance.refundedAt?.toIso8601String(),
      'refundReason': instance.refundReason,
    };
