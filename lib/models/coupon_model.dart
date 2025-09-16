import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  
  // Firestore用のカスタムfromJsonメソッド
  factory Coupon.fromFirestore(Map<String, dynamic> data, String id) {
    return Coupon(
      id: id,
      storeId: data['storeId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      type: _parseCouponType(data['type'] as String?),
      discountValue: _parseDouble(data['discountValue']),
      discountType: _parseDiscountType(data['discountType'] as String?),
      validFrom: _parseDateTime(data['startDate'] ?? data['validFrom']),
      validUntil: _parseDateTime(data['endDate'] ?? data['validUntil']),
      usageLimit: _parseInt(data['maxUsagePerUser'] ?? data['usageLimit']),
      usedCount: _parseInt(data['usageCount'] ?? data['usedCount']),
      minOrderAmount: _parseInt(data['minOrderAmount']),
      isActive: data['isActive'] as bool? ?? true,
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
      imageUrl: data['imageUrl'] as String?,
      applicableItems: (data['applicableItems'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      conditions: _parseConditions(data['conditions']),
      usedBy: (data['usedBy'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }
  
  static CouponType _parseCouponType(String? type) {
    switch (type) {
      case 'discount':
        return CouponType.discount;
      case 'free_shipping':
        return CouponType.freeShipping;
      case 'buy_one_get_one':
        return CouponType.buyOneGetOne;
      case 'cashback':
        return CouponType.cashback;
      case 'points_multiplier':
        return CouponType.pointsMultiplier;
      default:
        return CouponType.discount;
    }
  }
  
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    if (value is Timestamp) return value.toDate();
    return DateTime.now();
  }
  
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
  
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
  
  static String _parseDiscountType(String? type) {
    switch (type) {
      case '割引率':
        return 'percentage';
      case '割引額':
        return 'fixed_amount';
      case '固定価格':
        return 'fixed_price';
      default:
        return 'percentage';
    }
  }
  
  static Map<String, dynamic>? _parseConditions(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is String) return {'description': value};
    return null;
  }
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
  
  // Firestore用のカスタムfromJsonメソッド
  factory UserCoupon.fromFirestore(Map<String, dynamic> data, String id) {
    return UserCoupon(
      id: id,
      userId: data['userId'] as String? ?? '',
      couponId: data['couponId'] as String? ?? '',
      obtainedAt: Coupon._parseDateTime(data['obtainedAt']),
      usedAt: data['usedAt'] != null ? Coupon._parseDateTime(data['usedAt']) : null,
      isUsed: data['isUsed'] as bool? ?? false,
      storeId: data['storeId'] as String?,
      orderId: data['orderId'] as String?,
    );
  }
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
  
  // Firestore用のカスタムfromJsonメソッド
  factory Promotion.fromFirestore(Map<String, dynamic> data, String id) {
    return Promotion(
      id: id,
      storeId: data['storeId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      type: _parsePromotionType(data['type'] as String?),
      startDate: Coupon._parseDateTime(data['startDate']),
      endDate: Coupon._parseDateTime(data['endDate']),
      isActive: data['isActive'] as bool? ?? true,
      createdAt: Coupon._parseDateTime(data['createdAt']),
      updatedAt: Coupon._parseDateTime(data['updatedAt']),
      imageUrl: data['imageUrl'] as String?,
      conditions: data['conditions'] as Map<String, dynamic>?,
      targetUsers: (data['targetUsers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      viewCount: Coupon._parseInt(data['viewCount']),
      clickCount: Coupon._parseInt(data['clickCount']),
    );
  }
  
  static PromotionType _parsePromotionType(String? type) {
    switch (type) {
      case 'banner':
        return PromotionType.banner;
      case 'popup':
        return PromotionType.popup;
      case 'push_notification':
        return PromotionType.pushNotification;
      case 'email':
        return PromotionType.email;
      case 'in_app':
        return PromotionType.inApp;
      default:
        return PromotionType.banner;
    }
  }
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