// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coupon_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CouponImpl _$$CouponImplFromJson(Map<String, dynamic> json) => _$CouponImpl(
      id: json['id'] as String,
      storeId: json['storeId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$CouponTypeEnumMap, json['type']),
      discountValue: (json['discountValue'] as num).toDouble(),
      discountType: json['discountType'] as String,
      validFrom: DateTime.parse(json['validFrom'] as String),
      validUntil: DateTime.parse(json['validUntil'] as String),
      usageLimit: (json['usageLimit'] as num).toInt(),
      usedCount: (json['usedCount'] as num).toInt(),
      minOrderAmount: (json['minOrderAmount'] as num).toInt(),
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      imageUrl: json['imageUrl'] as String?,
      applicableItems: (json['applicableItems'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      conditions: json['conditions'] as Map<String, dynamic>?,
      usedBy: (json['usedBy'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      noUsageLimit: json['noUsageLimit'] as bool? ?? false,
    );

Map<String, dynamic> _$$CouponImplToJson(_$CouponImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'storeId': instance.storeId,
      'title': instance.title,
      'description': instance.description,
      'type': _$CouponTypeEnumMap[instance.type]!,
      'discountValue': instance.discountValue,
      'discountType': instance.discountType,
      'validFrom': instance.validFrom.toIso8601String(),
      'validUntil': instance.validUntil.toIso8601String(),
      'usageLimit': instance.usageLimit,
      'usedCount': instance.usedCount,
      'minOrderAmount': instance.minOrderAmount,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'imageUrl': instance.imageUrl,
      'applicableItems': instance.applicableItems,
      'conditions': instance.conditions,
      'usedBy': instance.usedBy,
      'noUsageLimit': instance.noUsageLimit,
    };

const _$CouponTypeEnumMap = {
  CouponType.discount: 'discount',
  CouponType.freeShipping: 'free_shipping',
  CouponType.buyOneGetOne: 'buy_one_get_one',
  CouponType.cashback: 'cashback',
  CouponType.pointsMultiplier: 'points_multiplier',
};

_$UserCouponImpl _$$UserCouponImplFromJson(Map<String, dynamic> json) =>
    _$UserCouponImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      couponId: json['couponId'] as String,
      obtainedAt: DateTime.parse(json['obtainedAt'] as String),
      usedAt: json['usedAt'] == null
          ? null
          : DateTime.parse(json['usedAt'] as String),
      isUsed: json['isUsed'] as bool,
      storeId: json['storeId'] as String?,
      orderId: json['orderId'] as String?,
    );

Map<String, dynamic> _$$UserCouponImplToJson(_$UserCouponImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'couponId': instance.couponId,
      'obtainedAt': instance.obtainedAt.toIso8601String(),
      'usedAt': instance.usedAt?.toIso8601String(),
      'isUsed': instance.isUsed,
      'storeId': instance.storeId,
      'orderId': instance.orderId,
    };

_$PromotionImpl _$$PromotionImplFromJson(Map<String, dynamic> json) =>
    _$PromotionImpl(
      id: json['id'] as String,
      storeId: json['storeId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$PromotionTypeEnumMap, json['type']),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      imageUrl: json['imageUrl'] as String?,
      conditions: json['conditions'] as Map<String, dynamic>?,
      targetUsers: (json['targetUsers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      clickCount: (json['clickCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$PromotionImplToJson(_$PromotionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'storeId': instance.storeId,
      'title': instance.title,
      'description': instance.description,
      'type': _$PromotionTypeEnumMap[instance.type]!,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'imageUrl': instance.imageUrl,
      'conditions': instance.conditions,
      'targetUsers': instance.targetUsers,
      'viewCount': instance.viewCount,
      'clickCount': instance.clickCount,
    };

const _$PromotionTypeEnumMap = {
  PromotionType.banner: 'banner',
  PromotionType.popup: 'popup',
  PromotionType.pushNotification: 'push_notification',
  PromotionType.email: 'email',
  PromotionType.inApp: 'in_app',
};
