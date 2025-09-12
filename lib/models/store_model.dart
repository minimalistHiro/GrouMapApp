import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'store_model.freezed.dart';
part 'store_model.g.dart';

@freezed
class StoreModel with _$StoreModel {
  const factory StoreModel({
    required String storeId,
    required String name,
    required String description,
    required String address,
    required StoreLocation location,
    required String category,
    required StoreOperatingHours operatingHours,
    @Default([]) List<String> images,
    required String ownerId,
    @Default('small') String plan,
    @Default(false) bool isCompanyAdmin,
    StoreCompanyInfo? companyInfo,
    @Default(0) int monthlyPointsIssued,
    @Default(1000) int pointsLimit,
    String? qrCode,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _StoreModel;

  factory StoreModel.fromJson(Map<String, dynamic> json) => _$StoreModelFromJson(json);
}

@freezed
class StoreLocation with _$StoreLocation {
  const factory StoreLocation({
    required double latitude,
    required double longitude,
  }) = _StoreLocation;

  factory StoreLocation.fromJson(Map<String, dynamic> json) => _$StoreLocationFromJson(json);
}

@freezed
class StoreOperatingHours with _$StoreOperatingHours {
  const factory StoreOperatingHours({
    required StoreDayHours monday,
    required StoreDayHours tuesday,
    required StoreDayHours wednesday,
    required StoreDayHours thursday,
    required StoreDayHours friday,
    required StoreDayHours saturday,
    required StoreDayHours sunday,
  }) = _StoreOperatingHours;

  factory StoreOperatingHours.fromJson(Map<String, dynamic> json) => _$StoreOperatingHoursFromJson(json);
}

@freezed
class StoreDayHours with _$StoreDayHours {
  const factory StoreDayHours({
    required String open,
    required String close,
    @Default(false) bool isClosed,
  }) = _StoreDayHours;

  factory StoreDayHours.fromJson(Map<String, dynamic> json) => _$StoreDayHoursFromJson(json);
}

@freezed
class StoreCompanyInfo with _$StoreCompanyInfo {
  const factory StoreCompanyInfo({
    String? companyId,
    String? companyName,
    @Default([]) List<String> subsidiaryStores,
  }) = _StoreCompanyInfo;

  factory StoreCompanyInfo.fromJson(Map<String, dynamic> json) => _$StoreCompanyInfoFromJson(json);
}
