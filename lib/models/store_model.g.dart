// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StoreModelImpl _$$StoreModelImplFromJson(Map<String, dynamic> json) =>
    _$StoreModelImpl(
      storeId: json['storeId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      address: json['address'] as String,
      location:
          StoreLocation.fromJson(json['location'] as Map<String, dynamic>),
      category: json['category'] as String,
      operatingHours: StoreOperatingHours.fromJson(
          json['operatingHours'] as Map<String, dynamic>),
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      ownerId: json['ownerId'] as String,
      plan: json['plan'] as String? ?? 'small',
      isCompanyAdmin: json['isCompanyAdmin'] as bool? ?? false,
      companyInfo: json['companyInfo'] == null
          ? null
          : StoreCompanyInfo.fromJson(
              json['companyInfo'] as Map<String, dynamic>),
      monthlyPointsIssued: (json['monthlyPointsIssued'] as num?)?.toInt() ?? 0,
      pointsLimit: (json['pointsLimit'] as num?)?.toInt() ?? 1000,
      qrCode: json['qrCode'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$StoreModelImplToJson(_$StoreModelImpl instance) =>
    <String, dynamic>{
      'storeId': instance.storeId,
      'name': instance.name,
      'description': instance.description,
      'address': instance.address,
      'location': instance.location,
      'category': instance.category,
      'operatingHours': instance.operatingHours,
      'images': instance.images,
      'ownerId': instance.ownerId,
      'plan': instance.plan,
      'isCompanyAdmin': instance.isCompanyAdmin,
      'companyInfo': instance.companyInfo,
      'monthlyPointsIssued': instance.monthlyPointsIssued,
      'pointsLimit': instance.pointsLimit,
      'qrCode': instance.qrCode,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

_$StoreLocationImpl _$$StoreLocationImplFromJson(Map<String, dynamic> json) =>
    _$StoreLocationImpl(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );

Map<String, dynamic> _$$StoreLocationImplToJson(_$StoreLocationImpl instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

_$StoreOperatingHoursImpl _$$StoreOperatingHoursImplFromJson(
        Map<String, dynamic> json) =>
    _$StoreOperatingHoursImpl(
      monday: StoreDayHours.fromJson(json['monday'] as Map<String, dynamic>),
      tuesday: StoreDayHours.fromJson(json['tuesday'] as Map<String, dynamic>),
      wednesday:
          StoreDayHours.fromJson(json['wednesday'] as Map<String, dynamic>),
      thursday:
          StoreDayHours.fromJson(json['thursday'] as Map<String, dynamic>),
      friday: StoreDayHours.fromJson(json['friday'] as Map<String, dynamic>),
      saturday:
          StoreDayHours.fromJson(json['saturday'] as Map<String, dynamic>),
      sunday: StoreDayHours.fromJson(json['sunday'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$StoreOperatingHoursImplToJson(
        _$StoreOperatingHoursImpl instance) =>
    <String, dynamic>{
      'monday': instance.monday,
      'tuesday': instance.tuesday,
      'wednesday': instance.wednesday,
      'thursday': instance.thursday,
      'friday': instance.friday,
      'saturday': instance.saturday,
      'sunday': instance.sunday,
    };

_$StoreDayHoursImpl _$$StoreDayHoursImplFromJson(Map<String, dynamic> json) =>
    _$StoreDayHoursImpl(
      open: json['open'] as String,
      close: json['close'] as String,
      isClosed: json['isClosed'] as bool? ?? false,
    );

Map<String, dynamic> _$$StoreDayHoursImplToJson(_$StoreDayHoursImpl instance) =>
    <String, dynamic>{
      'open': instance.open,
      'close': instance.close,
      'isClosed': instance.isClosed,
    };

_$StoreCompanyInfoImpl _$$StoreCompanyInfoImplFromJson(
        Map<String, dynamic> json) =>
    _$StoreCompanyInfoImpl(
      companyId: json['companyId'] as String?,
      companyName: json['companyName'] as String?,
      subsidiaryStores: (json['subsidiaryStores'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$StoreCompanyInfoImplToJson(
        _$StoreCompanyInfoImpl instance) =>
    <String, dynamic>{
      'companyId': instance.companyId,
      'companyName': instance.companyName,
      'subsidiaryStores': instance.subsidiaryStores,
    };
