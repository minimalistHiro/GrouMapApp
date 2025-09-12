import 'package:freezed_annotation/freezed_annotation.dart';

part 'coupon_model.freezed.dart';
part 'coupon_model.g.dart';

@freezed
class Coupon with _$Coupon {
  const factory Coupon({
    required String id,
    required String storeId,
    required String title,
    required String description,
    required CouponType type,
    required double discountValue,
    required String discountType, // 'percentage' or 'fixed'
    required DateTime validFrom,
    required DateTime validUntil,
    required int usageLimit,
    required int usedCount,
    required int minOrderAmount,
    required bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? imageUrl,
    List<String>? applicableItems,
    Map<String, dynamic>? conditions,
    @Default([]) List<String> usedBy,
  }) = _Coupon;

  factory Coupon.fromJson(Map<String, dynamic> json) => _$CouponFromJson(json);
}

@freezed
class UserCoupon with _$UserCoupon {
  const factory UserCoupon({
    required String id,
    required String userId,
    required String couponId,
    required DateTime obtainedAt,
    required DateTime? usedAt,
    required bool isUsed,
    required String? storeId,
    required String? orderId,
  }) = _UserCoupon;

  factory UserCoupon.fromJson(Map<String, dynamic> json) => _$UserCouponFromJson(json);
}

@freezed
class Promotion with _$Promotion {
  const factory Promotion({
    required String id,
    required String storeId,
    required String title,
    required String description,
    required PromotionType type,
    required DateTime startDate,
    required DateTime endDate,
    required bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? imageUrl,
    Map<String, dynamic>? conditions,
    @Default([]) List<String> targetUsers,
    @Default(0) int viewCount,
    @Default(0) int clickCount,
  }) = _Promotion;

  factory Promotion.fromJson(Map<String, dynamic> json) => _$PromotionFromJson(json);
}

enum CouponType {
  @JsonValue('discount')
  discount,
  @JsonValue('free_shipping')
  freeShipping,
  @JsonValue('buy_one_get_one')
  buyOneGetOne,
  @JsonValue('cashback')
  cashback,
  @JsonValue('points_multiplier')
  pointsMultiplier,
}

enum PromotionType {
  @JsonValue('banner')
  banner,
  @JsonValue('popup')
  popup,
  @JsonValue('push_notification')
  pushNotification,
  @JsonValue('email')
  email,
  @JsonValue('in_app')
  inApp,
}