import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_point_balance_model.freezed.dart';
part 'user_point_balance_model.g.dart';

@freezed
class UserPointBalance with _$UserPointBalance {
  const factory UserPointBalance({
    required String userId,
    required int totalPoints,
    required int availablePoints,
    required int usedPoints,
    required DateTime lastUpdated,
  }) = _UserPointBalance;

  factory UserPointBalance.fromJson(Map<String, dynamic> json) =>
      _$UserPointBalanceFromJson(json);
}
