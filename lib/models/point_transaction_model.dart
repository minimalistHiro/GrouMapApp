import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'point_transaction_model.freezed.dart';
part 'point_transaction_model.g.dart';

class TimestampDateTimeConverter implements JsonConverter<DateTime, Object?> {
  const TimestampDateTimeConverter();

  @override
  DateTime fromJson(Object? json) {
    if (json == null) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    if (json is Timestamp) {
      return json.toDate();
    }
    if (json is DateTime) {
      return json;
    }
    if (json is int) {
      return DateTime.fromMillisecondsSinceEpoch(json);
    }
    if (json is String) {
      return DateTime.tryParse(json) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  Object toJson(DateTime object) => object.toIso8601String();
}

class TimestampNullableDateTimeConverter implements JsonConverter<DateTime?, Object?> {
  const TimestampNullableDateTimeConverter();

  @override
  DateTime? fromJson(Object? json) {
    if (json == null) {
      return null;
    }
    if (json is Timestamp) {
      return json.toDate();
    }
    if (json is DateTime) {
      return json;
    }
    if (json is int) {
      return DateTime.fromMillisecondsSinceEpoch(json);
    }
    if (json is String) {
      return DateTime.tryParse(json);
    }
    return null;
  }

  @override
  Object? toJson(DateTime? object) => object?.toIso8601String();
}

@freezed
class PointTransactionModel with _$PointTransactionModel {
  const factory PointTransactionModel({
    required String transactionId,
    required String userId,
    required String storeId,
    required String storeName,
    required int amount,
    int? paymentAmount,
    @Default('completed') String status,
    @Default('points') String paymentMethod,
    @TimestampDateTimeConverter() required DateTime createdAt,
    @TimestampDateTimeConverter() required DateTime updatedAt,
    String? description,
    String? qrCode,
    @TimestampNullableDateTimeConverter() DateTime? refundedAt,
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
