import 'package:freezed_annotation/freezed_annotation.dart';

part 'store_management_model.freezed.dart';
part 'store_management_model.g.dart';

@freezed
class StoreManagement with _$StoreManagement {
  const factory StoreManagement({
    required String id,
    required String storeId,
    required String managerId,
    required String storeName,
    required String description,
    required String address,
    required double latitude,
    required double longitude,
    required String phoneNumber,
    required String email,
    required StoreStatus status,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? imageUrl,
    List<String>? businessHours,
    List<String>? paymentMethods,
    Map<String, dynamic>? settings,
    @Default(0) int totalVisitors,
    @Default(0) int totalPointsAwarded,
    @Default(0) int totalCouponsIssued,
    @Default([]) List<String> tags,
  }) = _StoreManagement;

  factory StoreManagement.fromJson(Map<String, dynamic> json) => _$StoreManagementFromJson(json);
}

@freezed
class StoreAnalytics with _$StoreAnalytics {
  const factory StoreAnalytics({
    required String storeId,
    required DateTime date,
    required int visitors,
    required int pointsAwarded,
    required int couponsIssued,
    required double revenue,
    required Map<String, dynamic> metrics,
  }) = _StoreAnalytics;

  factory StoreAnalytics.fromJson(Map<String, dynamic> json) => _$StoreAnalyticsFromJson(json);
}

@freezed
class StoreStaff with _$StoreStaff {
  const factory StoreStaff({
    required String id,
    required String storeId,
    required String userId,
    required String name,
    required String email,
    required StaffRole role,
    required DateTime joinedAt,
    required bool isActive,
    Map<String, dynamic>? permissions,
  }) = _StoreStaff;

  factory StoreStaff.fromJson(Map<String, dynamic> json) => _$StoreStaffFromJson(json);
}

@freezed
class StoreMenu with _$StoreMenu {
  const factory StoreMenu({
    required String id,
    required String storeId,
    required String name,
    required String description,
    required double price,
    required String category,
    required bool isAvailable,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? imageUrl,
    List<String>? ingredients,
    Map<String, dynamic>? nutritionInfo,
    @Default(0) int orderCount,
  }) = _StoreMenu;

  factory StoreMenu.fromJson(Map<String, dynamic> json) => _$StoreMenuFromJson(json);
}

enum StoreStatus {
  @JsonValue('active')
  active,
  @JsonValue('inactive')
  inactive,
  @JsonValue('pending')
  pending,
  @JsonValue('suspended')
  suspended,
}

enum StaffRole {
  @JsonValue('owner')
  owner,
  @JsonValue('manager')
  manager,
  @JsonValue('staff')
  staff,
  @JsonValue('cashier')
  cashier,
}