// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qr_code_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$QRCodeModelImpl _$$QRCodeModelImplFromJson(Map<String, dynamic> json) =>
    _$QRCodeModelImpl(
      qrCodeId: json['qrCodeId'] as String,
      userId: json['userId'] as String,
      storeId: json['storeId'] as String,
      qrCodeData: json['qrCodeData'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      isUsed: json['isUsed'] as bool? ?? false,
      usedAt: json['usedAt'] == null
          ? null
          : DateTime.parse(json['usedAt'] as String),
    );

Map<String, dynamic> _$$QRCodeModelImplToJson(_$QRCodeModelImpl instance) =>
    <String, dynamic>{
      'qrCodeId': instance.qrCodeId,
      'userId': instance.userId,
      'storeId': instance.storeId,
      'qrCodeData': instance.qrCodeData,
      'createdAt': instance.createdAt.toIso8601String(),
      'expiresAt': instance.expiresAt.toIso8601String(),
      'isUsed': instance.isUsed,
      'usedAt': instance.usedAt?.toIso8601String(),
    };
