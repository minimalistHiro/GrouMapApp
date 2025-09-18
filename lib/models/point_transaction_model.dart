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
    required String storeName,
    required int amount,
    @Default('completed') String status,
    @Default('points') String paymentMethod,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? description,
    String? qrCode,
    DateTime? refundedAt,
    String? refundReason,
  }) = _PointTransactionModel;

  factory PointTransactionModel.fromJson(Map<String, dynamic> json) =>
      _$PointTransactionModelFromJson(json);
}

@freezed
class PointTransactionStatus with _$PointTransactionStatus {
  const factory PointTransactionStatus({
    @Default('completed') String completed,
    @Default('pending') String pending,
    @Default('cancelled') String cancelled,
    @Default('refunded') String refunded,
  }) = _PointTransactionStatus;
}

@freezed
class PaymentMethod with _$PaymentMethod {
  const factory PaymentMethod({
    @Default('points') String points,
    @Default('cash') String cash,
    @Default('card') String card,
  }) = _PaymentMethod;
}
