import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'qr_code_model.freezed.dart';
part 'qr_code_model.g.dart';

@freezed
class QRCodeModel with _$QRCodeModel {
  const factory QRCodeModel({
    required String qrCodeId,
    required String userId,
    required String storeId,
    required String qrCodeData,
    required DateTime createdAt,
    required DateTime expiresAt,
    @Default(false) bool isUsed,
    DateTime? usedAt,
  }) = _QRCodeModel;

  factory QRCodeModel.fromJson(Map<String, dynamic> json) =>
      _$QRCodeModelFromJson(json);
}
