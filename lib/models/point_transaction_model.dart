import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'point_transaction_model.freezed.dart';
part 'point_transaction_model.g.dart';

@freezed
class PointTransactionModel with _$PointTransactionModel {
  const factory PointTransactionModel({
    required String transactionId,
    required String userId,
    required String storeId,
    required int points,
    required PointTransactionType type,
    required String description,
    required DateTime timestamp,
    String? qrCodeId,
    String? referenceId,
    @Default(false) bool isProcessed,
    String? notes,
  }) = _PointTransactionModel;

  factory PointTransactionModel.fromJson(Map<String, dynamic> json) => 
      _$PointTransactionModelFromJson(json);
}

@freezed
class PointTransactionType with _$PointTransactionType {
  const factory PointTransactionType.earned({
    required String reason,
    @Default(1.0) double multiplier,
  }) = PointEarned;

  const factory PointTransactionType.used({
    required String reason,
    required int amountUsed,
  }) = PointUsed;

  const factory PointTransactionType.expired({
    required String reason,
    required int expiredAmount,
  }) = PointExpired;

  const factory PointTransactionType.refunded({
    required String reason,
    required int refundedAmount,
  }) = PointRefunded;

  factory PointTransactionType.fromJson(Map<String, dynamic> json) => 
      _$PointTransactionTypeFromJson(json);
}

@freezed
class UserPointBalance with _$UserPointBalance {
  const factory UserPointBalance({
    required String userId,
    required int totalPoints,
    required int availablePoints,
    required int usedPoints,
    required int expiredPoints,
    required DateTime lastUpdated,
    @Default([]) List<PointTransactionModel> recentTransactions,
  }) = _UserPointBalance;

  factory UserPointBalance.fromJson(Map<String, dynamic> json) => 
      _$UserPointBalanceFromJson(json);
}

@freezed
class QRCodeModel with _$QRCodeModel {
  const factory QRCodeModel({
    required String qrCodeId,
    required String storeId,
    required int points,
    required DateTime expiresAt,
    required DateTime createdAt,
    required String createdBy,
    @Default(false) bool isUsed,
    String? usedBy,
    DateTime? usedAt,
    String? description,
  }) = _QRCodeModel;

  factory QRCodeModel.fromJson(Map<String, dynamic> json) => 
      _$QRCodeModelFromJson(json);
}
