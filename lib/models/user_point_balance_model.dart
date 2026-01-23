import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_point_balance_model.freezed.dart';
part 'user_point_balance_model.g.dart';

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

@freezed
class UserPointBalance with _$UserPointBalance {
  const factory UserPointBalance({
    required String userId,
    required int totalPoints,
    required int availablePoints,
    required int usedPoints,
    @TimestampDateTimeConverter() required DateTime lastUpdated,
  }) = _UserPointBalance;

  factory UserPointBalance.fromJson(Map<String, dynamic> json) =>
      _$UserPointBalanceFromJson(json);
}
