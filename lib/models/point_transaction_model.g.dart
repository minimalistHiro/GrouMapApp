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
      createdAt:
          const TimestampDateTimeConverter().fromJson(json['createdAt']),
      updatedAt:
          const TimestampDateTimeConverter().fromJson(json['updatedAt']),
      description: json['description'] as String?,
      qrCode: json['qrCode'] as String?,
      refundedAt: const TimestampNullableDateTimeConverter()
          .fromJson(json['refundedAt']),
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
      'createdAt':
          const TimestampDateTimeConverter().toJson(instance.createdAt),
      'updatedAt':
          const TimestampDateTimeConverter().toJson(instance.updatedAt),
      'description': instance.description,
      'qrCode': instance.qrCode,
      'refundedAt':
          const TimestampNullableDateTimeConverter().toJson(instance.refundedAt),
      'refundReason': instance.refundReason,
    };
