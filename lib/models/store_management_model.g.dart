// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_management_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StoreManagementImpl _$$StoreManagementImplFromJson(
        Map<String, dynamic> json) =>
    _$StoreManagementImpl(
      id: json['id'] as String,
      storeId: json['storeId'] as String,
      managerId: json['managerId'] as String,
      storeName: json['storeName'] as String,
      description: json['description'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String,
      status: $enumDecode(_$StoreStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      imageUrl: json['imageUrl'] as String?,
      businessHours: (json['businessHours'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      paymentMethods: (json['paymentMethods'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      settings: json['settings'] as Map<String, dynamic>?,
      totalVisitors: (json['totalVisitors'] as num?)?.toInt() ?? 0,
      totalPointsAwarded: (json['totalPointsAwarded'] as num?)?.toInt() ?? 0,
      totalCouponsIssued: (json['totalCouponsIssued'] as num?)?.toInt() ?? 0,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
    );

Map<String, dynamic> _$$StoreManagementImplToJson(
        _$StoreManagementImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'storeId': instance.storeId,
      'managerId': instance.managerId,
      'storeName': instance.storeName,
      'description': instance.description,
      'address': instance.address,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'phoneNumber': instance.phoneNumber,
      'email': instance.email,
      'status': _$StoreStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'imageUrl': instance.imageUrl,
      'businessHours': instance.businessHours,
      'paymentMethods': instance.paymentMethods,
      'settings': instance.settings,
      'totalVisitors': instance.totalVisitors,
      'totalPointsAwarded': instance.totalPointsAwarded,
      'totalCouponsIssued': instance.totalCouponsIssued,
      'tags': instance.tags,
    };

const _$StoreStatusEnumMap = {
  StoreStatus.active: 'active',
  StoreStatus.inactive: 'inactive',
  StoreStatus.pending: 'pending',
  StoreStatus.suspended: 'suspended',
};

_$StoreAnalyticsImpl _$$StoreAnalyticsImplFromJson(Map<String, dynamic> json) =>
    _$StoreAnalyticsImpl(
      storeId: json['storeId'] as String,
      date: DateTime.parse(json['date'] as String),
      visitors: (json['visitors'] as num).toInt(),
      pointsAwarded: (json['pointsAwarded'] as num).toInt(),
      couponsIssued: (json['couponsIssued'] as num).toInt(),
      revenue: (json['revenue'] as num).toDouble(),
      metrics: json['metrics'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$$StoreAnalyticsImplToJson(
        _$StoreAnalyticsImpl instance) =>
    <String, dynamic>{
      'storeId': instance.storeId,
      'date': instance.date.toIso8601String(),
      'visitors': instance.visitors,
      'pointsAwarded': instance.pointsAwarded,
      'couponsIssued': instance.couponsIssued,
      'revenue': instance.revenue,
      'metrics': instance.metrics,
    };

_$StoreStaffImpl _$$StoreStaffImplFromJson(Map<String, dynamic> json) =>
    _$StoreStaffImpl(
      id: json['id'] as String,
      storeId: json['storeId'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: $enumDecode(_$StaffRoleEnumMap, json['role']),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      isActive: json['isActive'] as bool,
      permissions: json['permissions'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$StoreStaffImplToJson(_$StoreStaffImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'storeId': instance.storeId,
      'userId': instance.userId,
      'name': instance.name,
      'email': instance.email,
      'role': _$StaffRoleEnumMap[instance.role]!,
      'joinedAt': instance.joinedAt.toIso8601String(),
      'isActive': instance.isActive,
      'permissions': instance.permissions,
    };

const _$StaffRoleEnumMap = {
  StaffRole.owner: 'owner',
  StaffRole.manager: 'manager',
  StaffRole.staff: 'staff',
  StaffRole.cashier: 'cashier',
};

_$StoreMenuImpl _$$StoreMenuImplFromJson(Map<String, dynamic> json) =>
    _$StoreMenuImpl(
      id: json['id'] as String,
      storeId: json['storeId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      category: json['category'] as String,
      isAvailable: json['isAvailable'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      imageUrl: json['imageUrl'] as String?,
      ingredients: (json['ingredients'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      nutritionInfo: json['nutritionInfo'] as Map<String, dynamic>?,
      orderCount: (json['orderCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$StoreMenuImplToJson(_$StoreMenuImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'storeId': instance.storeId,
      'name': instance.name,
      'description': instance.description,
      'price': instance.price,
      'category': instance.category,
      'isAvailable': instance.isAvailable,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'imageUrl': instance.imageUrl,
      'ingredients': instance.ingredients,
      'nutritionInfo': instance.nutritionInfo,
      'orderCount': instance.orderCount,
    };
