// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'store_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

StoreModel _$StoreModelFromJson(Map<String, dynamic> json) {
  return _StoreModel.fromJson(json);
}

/// @nodoc
mixin _$StoreModel {
  String get storeId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get address => throw _privateConstructorUsedError;
  StoreLocation get location => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  StoreOperatingHours get operatingHours => throw _privateConstructorUsedError;
  List<String> get images => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;
  String get plan => throw _privateConstructorUsedError;
  bool get isCompanyAdmin => throw _privateConstructorUsedError;
  StoreCompanyInfo? get companyInfo => throw _privateConstructorUsedError;
  int get monthlyPointsIssued => throw _privateConstructorUsedError;
  int get pointsLimit => throw _privateConstructorUsedError;
  String? get qrCode => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this StoreModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StoreModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StoreModelCopyWith<StoreModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StoreModelCopyWith<$Res> {
  factory $StoreModelCopyWith(
          StoreModel value, $Res Function(StoreModel) then) =
      _$StoreModelCopyWithImpl<$Res, StoreModel>;
  @useResult
  $Res call(
      {String storeId,
      String name,
      String description,
      String address,
      StoreLocation location,
      String category,
      StoreOperatingHours operatingHours,
      List<String> images,
      String ownerId,
      String plan,
      bool isCompanyAdmin,
      StoreCompanyInfo? companyInfo,
      int monthlyPointsIssued,
      int pointsLimit,
      String? qrCode,
      DateTime createdAt,
      DateTime updatedAt});

  $StoreLocationCopyWith<$Res> get location;
  $StoreOperatingHoursCopyWith<$Res> get operatingHours;
  $StoreCompanyInfoCopyWith<$Res>? get companyInfo;
}

/// @nodoc
class _$StoreModelCopyWithImpl<$Res, $Val extends StoreModel>
    implements $StoreModelCopyWith<$Res> {
  _$StoreModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StoreModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? storeId = null,
    Object? name = null,
    Object? description = null,
    Object? address = null,
    Object? location = null,
    Object? category = null,
    Object? operatingHours = null,
    Object? images = null,
    Object? ownerId = null,
    Object? plan = null,
    Object? isCompanyAdmin = null,
    Object? companyInfo = freezed,
    Object? monthlyPointsIssued = null,
    Object? pointsLimit = null,
    Object? qrCode = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      storeId: null == storeId
          ? _value.storeId
          : storeId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      location: null == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as StoreLocation,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      operatingHours: null == operatingHours
          ? _value.operatingHours
          : operatingHours // ignore: cast_nullable_to_non_nullable
              as StoreOperatingHours,
      images: null == images
          ? _value.images
          : images // ignore: cast_nullable_to_non_nullable
              as List<String>,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      plan: null == plan
          ? _value.plan
          : plan // ignore: cast_nullable_to_non_nullable
              as String,
      isCompanyAdmin: null == isCompanyAdmin
          ? _value.isCompanyAdmin
          : isCompanyAdmin // ignore: cast_nullable_to_non_nullable
              as bool,
      companyInfo: freezed == companyInfo
          ? _value.companyInfo
          : companyInfo // ignore: cast_nullable_to_non_nullable
              as StoreCompanyInfo?,
      monthlyPointsIssued: null == monthlyPointsIssued
          ? _value.monthlyPointsIssued
          : monthlyPointsIssued // ignore: cast_nullable_to_non_nullable
              as int,
      pointsLimit: null == pointsLimit
          ? _value.pointsLimit
          : pointsLimit // ignore: cast_nullable_to_non_nullable
              as int,
      qrCode: freezed == qrCode
          ? _value.qrCode
          : qrCode // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }

  /// Create a copy of StoreModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StoreLocationCopyWith<$Res> get location {
    return $StoreLocationCopyWith<$Res>(_value.location, (value) {
      return _then(_value.copyWith(location: value) as $Val);
    });
  }

  /// Create a copy of StoreModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StoreOperatingHoursCopyWith<$Res> get operatingHours {
    return $StoreOperatingHoursCopyWith<$Res>(_value.operatingHours, (value) {
      return _then(_value.copyWith(operatingHours: value) as $Val);
    });
  }

  /// Create a copy of StoreModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StoreCompanyInfoCopyWith<$Res>? get companyInfo {
    if (_value.companyInfo == null) {
      return null;
    }

    return $StoreCompanyInfoCopyWith<$Res>(_value.companyInfo!, (value) {
      return _then(_value.copyWith(companyInfo: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$StoreModelImplCopyWith<$Res>
    implements $StoreModelCopyWith<$Res> {
  factory _$$StoreModelImplCopyWith(
          _$StoreModelImpl value, $Res Function(_$StoreModelImpl) then) =
      __$$StoreModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String storeId,
      String name,
      String description,
      String address,
      StoreLocation location,
      String category,
      StoreOperatingHours operatingHours,
      List<String> images,
      String ownerId,
      String plan,
      bool isCompanyAdmin,
      StoreCompanyInfo? companyInfo,
      int monthlyPointsIssued,
      int pointsLimit,
      String? qrCode,
      DateTime createdAt,
      DateTime updatedAt});

  @override
  $StoreLocationCopyWith<$Res> get location;
  @override
  $StoreOperatingHoursCopyWith<$Res> get operatingHours;
  @override
  $StoreCompanyInfoCopyWith<$Res>? get companyInfo;
}

/// @nodoc
class __$$StoreModelImplCopyWithImpl<$Res>
    extends _$StoreModelCopyWithImpl<$Res, _$StoreModelImpl>
    implements _$$StoreModelImplCopyWith<$Res> {
  __$$StoreModelImplCopyWithImpl(
      _$StoreModelImpl _value, $Res Function(_$StoreModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of StoreModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? storeId = null,
    Object? name = null,
    Object? description = null,
    Object? address = null,
    Object? location = null,
    Object? category = null,
    Object? operatingHours = null,
    Object? images = null,
    Object? ownerId = null,
    Object? plan = null,
    Object? isCompanyAdmin = null,
    Object? companyInfo = freezed,
    Object? monthlyPointsIssued = null,
    Object? pointsLimit = null,
    Object? qrCode = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$StoreModelImpl(
      storeId: null == storeId
          ? _value.storeId
          : storeId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      location: null == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as StoreLocation,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      operatingHours: null == operatingHours
          ? _value.operatingHours
          : operatingHours // ignore: cast_nullable_to_non_nullable
              as StoreOperatingHours,
      images: null == images
          ? _value._images
          : images // ignore: cast_nullable_to_non_nullable
              as List<String>,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      plan: null == plan
          ? _value.plan
          : plan // ignore: cast_nullable_to_non_nullable
              as String,
      isCompanyAdmin: null == isCompanyAdmin
          ? _value.isCompanyAdmin
          : isCompanyAdmin // ignore: cast_nullable_to_non_nullable
              as bool,
      companyInfo: freezed == companyInfo
          ? _value.companyInfo
          : companyInfo // ignore: cast_nullable_to_non_nullable
              as StoreCompanyInfo?,
      monthlyPointsIssued: null == monthlyPointsIssued
          ? _value.monthlyPointsIssued
          : monthlyPointsIssued // ignore: cast_nullable_to_non_nullable
              as int,
      pointsLimit: null == pointsLimit
          ? _value.pointsLimit
          : pointsLimit // ignore: cast_nullable_to_non_nullable
              as int,
      qrCode: freezed == qrCode
          ? _value.qrCode
          : qrCode // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StoreModelImpl implements _StoreModel {
  const _$StoreModelImpl(
      {required this.storeId,
      required this.name,
      required this.description,
      required this.address,
      required this.location,
      required this.category,
      required this.operatingHours,
      final List<String> images = const [],
      required this.ownerId,
      this.plan = 'small',
      this.isCompanyAdmin = false,
      this.companyInfo,
      this.monthlyPointsIssued = 0,
      this.pointsLimit = 1000,
      this.qrCode,
      required this.createdAt,
      required this.updatedAt})
      : _images = images;

  factory _$StoreModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$StoreModelImplFromJson(json);

  @override
  final String storeId;
  @override
  final String name;
  @override
  final String description;
  @override
  final String address;
  @override
  final StoreLocation location;
  @override
  final String category;
  @override
  final StoreOperatingHours operatingHours;
  final List<String> _images;
  @override
  @JsonKey()
  List<String> get images {
    if (_images is EqualUnmodifiableListView) return _images;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_images);
  }

  @override
  final String ownerId;
  @override
  @JsonKey()
  final String plan;
  @override
  @JsonKey()
  final bool isCompanyAdmin;
  @override
  final StoreCompanyInfo? companyInfo;
  @override
  @JsonKey()
  final int monthlyPointsIssued;
  @override
  @JsonKey()
  final int pointsLimit;
  @override
  final String? qrCode;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'StoreModel(storeId: $storeId, name: $name, description: $description, address: $address, location: $location, category: $category, operatingHours: $operatingHours, images: $images, ownerId: $ownerId, plan: $plan, isCompanyAdmin: $isCompanyAdmin, companyInfo: $companyInfo, monthlyPointsIssued: $monthlyPointsIssued, pointsLimit: $pointsLimit, qrCode: $qrCode, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StoreModelImpl &&
            (identical(other.storeId, storeId) || other.storeId == storeId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.operatingHours, operatingHours) ||
                other.operatingHours == operatingHours) &&
            const DeepCollectionEquality().equals(other._images, _images) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.plan, plan) || other.plan == plan) &&
            (identical(other.isCompanyAdmin, isCompanyAdmin) ||
                other.isCompanyAdmin == isCompanyAdmin) &&
            (identical(other.companyInfo, companyInfo) ||
                other.companyInfo == companyInfo) &&
            (identical(other.monthlyPointsIssued, monthlyPointsIssued) ||
                other.monthlyPointsIssued == monthlyPointsIssued) &&
            (identical(other.pointsLimit, pointsLimit) ||
                other.pointsLimit == pointsLimit) &&
            (identical(other.qrCode, qrCode) || other.qrCode == qrCode) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      storeId,
      name,
      description,
      address,
      location,
      category,
      operatingHours,
      const DeepCollectionEquality().hash(_images),
      ownerId,
      plan,
      isCompanyAdmin,
      companyInfo,
      monthlyPointsIssued,
      pointsLimit,
      qrCode,
      createdAt,
      updatedAt);

  /// Create a copy of StoreModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StoreModelImplCopyWith<_$StoreModelImpl> get copyWith =>
      __$$StoreModelImplCopyWithImpl<_$StoreModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StoreModelImplToJson(
      this,
    );
  }
}

abstract class _StoreModel implements StoreModel {
  const factory _StoreModel(
      {required final String storeId,
      required final String name,
      required final String description,
      required final String address,
      required final StoreLocation location,
      required final String category,
      required final StoreOperatingHours operatingHours,
      final List<String> images,
      required final String ownerId,
      final String plan,
      final bool isCompanyAdmin,
      final StoreCompanyInfo? companyInfo,
      final int monthlyPointsIssued,
      final int pointsLimit,
      final String? qrCode,
      required final DateTime createdAt,
      required final DateTime updatedAt}) = _$StoreModelImpl;

  factory _StoreModel.fromJson(Map<String, dynamic> json) =
      _$StoreModelImpl.fromJson;

  @override
  String get storeId;
  @override
  String get name;
  @override
  String get description;
  @override
  String get address;
  @override
  StoreLocation get location;
  @override
  String get category;
  @override
  StoreOperatingHours get operatingHours;
  @override
  List<String> get images;
  @override
  String get ownerId;
  @override
  String get plan;
  @override
  bool get isCompanyAdmin;
  @override
  StoreCompanyInfo? get companyInfo;
  @override
  int get monthlyPointsIssued;
  @override
  int get pointsLimit;
  @override
  String? get qrCode;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of StoreModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StoreModelImplCopyWith<_$StoreModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StoreLocation _$StoreLocationFromJson(Map<String, dynamic> json) {
  return _StoreLocation.fromJson(json);
}

/// @nodoc
mixin _$StoreLocation {
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;

  /// Serializes this StoreLocation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StoreLocation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StoreLocationCopyWith<StoreLocation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StoreLocationCopyWith<$Res> {
  factory $StoreLocationCopyWith(
          StoreLocation value, $Res Function(StoreLocation) then) =
      _$StoreLocationCopyWithImpl<$Res, StoreLocation>;
  @useResult
  $Res call({double latitude, double longitude});
}

/// @nodoc
class _$StoreLocationCopyWithImpl<$Res, $Val extends StoreLocation>
    implements $StoreLocationCopyWith<$Res> {
  _$StoreLocationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StoreLocation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? latitude = null,
    Object? longitude = null,
  }) {
    return _then(_value.copyWith(
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StoreLocationImplCopyWith<$Res>
    implements $StoreLocationCopyWith<$Res> {
  factory _$$StoreLocationImplCopyWith(
          _$StoreLocationImpl value, $Res Function(_$StoreLocationImpl) then) =
      __$$StoreLocationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double latitude, double longitude});
}

/// @nodoc
class __$$StoreLocationImplCopyWithImpl<$Res>
    extends _$StoreLocationCopyWithImpl<$Res, _$StoreLocationImpl>
    implements _$$StoreLocationImplCopyWith<$Res> {
  __$$StoreLocationImplCopyWithImpl(
      _$StoreLocationImpl _value, $Res Function(_$StoreLocationImpl) _then)
      : super(_value, _then);

  /// Create a copy of StoreLocation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? latitude = null,
    Object? longitude = null,
  }) {
    return _then(_$StoreLocationImpl(
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StoreLocationImpl implements _StoreLocation {
  const _$StoreLocationImpl({required this.latitude, required this.longitude});

  factory _$StoreLocationImpl.fromJson(Map<String, dynamic> json) =>
      _$$StoreLocationImplFromJson(json);

  @override
  final double latitude;
  @override
  final double longitude;

  @override
  String toString() {
    return 'StoreLocation(latitude: $latitude, longitude: $longitude)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StoreLocationImpl &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, latitude, longitude);

  /// Create a copy of StoreLocation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StoreLocationImplCopyWith<_$StoreLocationImpl> get copyWith =>
      __$$StoreLocationImplCopyWithImpl<_$StoreLocationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StoreLocationImplToJson(
      this,
    );
  }
}

abstract class _StoreLocation implements StoreLocation {
  const factory _StoreLocation(
      {required final double latitude,
      required final double longitude}) = _$StoreLocationImpl;

  factory _StoreLocation.fromJson(Map<String, dynamic> json) =
      _$StoreLocationImpl.fromJson;

  @override
  double get latitude;
  @override
  double get longitude;

  /// Create a copy of StoreLocation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StoreLocationImplCopyWith<_$StoreLocationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StoreOperatingHours _$StoreOperatingHoursFromJson(Map<String, dynamic> json) {
  return _StoreOperatingHours.fromJson(json);
}

/// @nodoc
mixin _$StoreOperatingHours {
  StoreDayHours get monday => throw _privateConstructorUsedError;
  StoreDayHours get tuesday => throw _privateConstructorUsedError;
  StoreDayHours get wednesday => throw _privateConstructorUsedError;
  StoreDayHours get thursday => throw _privateConstructorUsedError;
  StoreDayHours get friday => throw _privateConstructorUsedError;
  StoreDayHours get saturday => throw _privateConstructorUsedError;
  StoreDayHours get sunday => throw _privateConstructorUsedError;

  /// Serializes this StoreOperatingHours to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StoreOperatingHours
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StoreOperatingHoursCopyWith<StoreOperatingHours> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StoreOperatingHoursCopyWith<$Res> {
  factory $StoreOperatingHoursCopyWith(
          StoreOperatingHours value, $Res Function(StoreOperatingHours) then) =
      _$StoreOperatingHoursCopyWithImpl<$Res, StoreOperatingHours>;
  @useResult
  $Res call(
      {StoreDayHours monday,
      StoreDayHours tuesday,
      StoreDayHours wednesday,
      StoreDayHours thursday,
      StoreDayHours friday,
      StoreDayHours saturday,
      StoreDayHours sunday});

  $StoreDayHoursCopyWith<$Res> get monday;
  $StoreDayHoursCopyWith<$Res> get tuesday;
  $StoreDayHoursCopyWith<$Res> get wednesday;
  $StoreDayHoursCopyWith<$Res> get thursday;
  $StoreDayHoursCopyWith<$Res> get friday;
  $StoreDayHoursCopyWith<$Res> get saturday;
  $StoreDayHoursCopyWith<$Res> get sunday;
}

/// @nodoc
class _$StoreOperatingHoursCopyWithImpl<$Res, $Val extends StoreOperatingHours>
    implements $StoreOperatingHoursCopyWith<$Res> {
  _$StoreOperatingHoursCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StoreOperatingHours
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? monday = null,
    Object? tuesday = null,
    Object? wednesday = null,
    Object? thursday = null,
    Object? friday = null,
    Object? saturday = null,
    Object? sunday = null,
  }) {
    return _then(_value.copyWith(
      monday: null == monday
          ? _value.monday
          : monday // ignore: cast_nullable_to_non_nullable
              as StoreDayHours,
      tuesday: null == tuesday
          ? _value.tuesday
          : tuesday // ignore: cast_nullable_to_non_nullable
              as StoreDayHours,
      wednesday: null == wednesday
          ? _value.wednesday
          : wednesday // ignore: cast_nullable_to_non_nullable
              as StoreDayHours,
      thursday: null == thursday
          ? _value.thursday
          : thursday // ignore: cast_nullable_to_non_nullable
              as StoreDayHours,
      friday: null == friday
          ? _value.friday
          : friday // ignore: cast_nullable_to_non_nullable
              as StoreDayHours,
      saturday: null == saturday
          ? _value.saturday
          : saturday // ignore: cast_nullable_to_non_nullable
              as StoreDayHours,
      sunday: null == sunday
          ? _value.sunday
          : sunday // ignore: cast_nullable_to_non_nullable
              as StoreDayHours,
    ) as $Val);
  }

  /// Create a copy of StoreOperatingHours
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StoreDayHoursCopyWith<$Res> get monday {
    return $StoreDayHoursCopyWith<$Res>(_value.monday, (value) {
      return _then(_value.copyWith(monday: value) as $Val);
    });
  }

  /// Create a copy of StoreOperatingHours
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StoreDayHoursCopyWith<$Res> get tuesday {
    return $StoreDayHoursCopyWith<$Res>(_value.tuesday, (value) {
      return _then(_value.copyWith(tuesday: value) as $Val);
    });
  }

  /// Create a copy of StoreOperatingHours
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StoreDayHoursCopyWith<$Res> get wednesday {
    return $StoreDayHoursCopyWith<$Res>(_value.wednesday, (value) {
      return _then(_value.copyWith(wednesday: value) as $Val);
    });
  }

  /// Create a copy of StoreOperatingHours
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StoreDayHoursCopyWith<$Res> get thursday {
    return $StoreDayHoursCopyWith<$Res>(_value.thursday, (value) {
      return _then(_value.copyWith(thursday: value) as $Val);
    });
  }

  /// Create a copy of StoreOperatingHours
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StoreDayHoursCopyWith<$Res> get friday {
    return $StoreDayHoursCopyWith<$Res>(_value.friday, (value) {
      return _then(_value.copyWith(friday: value) as $Val);
    });
  }

  /// Create a copy of StoreOperatingHours
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StoreDayHoursCopyWith<$Res> get saturday {
    return $StoreDayHoursCopyWith<$Res>(_value.saturday, (value) {
      return _then(_value.copyWith(saturday: value) as $Val);
    });
  }

  /// Create a copy of StoreOperatingHours
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StoreDayHoursCopyWith<$Res> get sunday {
    return $StoreDayHoursCopyWith<$Res>(_value.sunday, (value) {
      return _then(_value.copyWith(sunday: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$StoreOperatingHoursImplCopyWith<$Res>
    implements $StoreOperatingHoursCopyWith<$Res> {
  factory _$$StoreOperatingHoursImplCopyWith(_$StoreOperatingHoursImpl value,
          $Res Function(_$StoreOperatingHoursImpl) then) =
      __$$StoreOperatingHoursImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {StoreDayHours monday,
      StoreDayHours tuesday,
      StoreDayHours wednesday,
      StoreDayHours thursday,
      StoreDayHours friday,
      StoreDayHours saturday,
      StoreDayHours sunday});

  @override
  $StoreDayHoursCopyWith<$Res> get monday;
  @override
  $StoreDayHoursCopyWith<$Res> get tuesday;
  @override
  $StoreDayHoursCopyWith<$Res> get wednesday;
  @override
  $StoreDayHoursCopyWith<$Res> get thursday;
  @override
  $StoreDayHoursCopyWith<$Res> get friday;
  @override
  $StoreDayHoursCopyWith<$Res> get saturday;
  @override
  $StoreDayHoursCopyWith<$Res> get sunday;
}

/// @nodoc
class __$$StoreOperatingHoursImplCopyWithImpl<$Res>
    extends _$StoreOperatingHoursCopyWithImpl<$Res, _$StoreOperatingHoursImpl>
    implements _$$StoreOperatingHoursImplCopyWith<$Res> {
  __$$StoreOperatingHoursImplCopyWithImpl(_$StoreOperatingHoursImpl _value,
      $Res Function(_$StoreOperatingHoursImpl) _then)
      : super(_value, _then);

  /// Create a copy of StoreOperatingHours
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? monday = null,
    Object? tuesday = null,
    Object? wednesday = null,
    Object? thursday = null,
    Object? friday = null,
    Object? saturday = null,
    Object? sunday = null,
  }) {
    return _then(_$StoreOperatingHoursImpl(
      monday: null == monday
          ? _value.monday
          : monday // ignore: cast_nullable_to_non_nullable
              as StoreDayHours,
      tuesday: null == tuesday
          ? _value.tuesday
          : tuesday // ignore: cast_nullable_to_non_nullable
              as StoreDayHours,
      wednesday: null == wednesday
          ? _value.wednesday
          : wednesday // ignore: cast_nullable_to_non_nullable
              as StoreDayHours,
      thursday: null == thursday
          ? _value.thursday
          : thursday // ignore: cast_nullable_to_non_nullable
              as StoreDayHours,
      friday: null == friday
          ? _value.friday
          : friday // ignore: cast_nullable_to_non_nullable
              as StoreDayHours,
      saturday: null == saturday
          ? _value.saturday
          : saturday // ignore: cast_nullable_to_non_nullable
              as StoreDayHours,
      sunday: null == sunday
          ? _value.sunday
          : sunday // ignore: cast_nullable_to_non_nullable
              as StoreDayHours,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StoreOperatingHoursImpl implements _StoreOperatingHours {
  const _$StoreOperatingHoursImpl(
      {required this.monday,
      required this.tuesday,
      required this.wednesday,
      required this.thursday,
      required this.friday,
      required this.saturday,
      required this.sunday});

  factory _$StoreOperatingHoursImpl.fromJson(Map<String, dynamic> json) =>
      _$$StoreOperatingHoursImplFromJson(json);

  @override
  final StoreDayHours monday;
  @override
  final StoreDayHours tuesday;
  @override
  final StoreDayHours wednesday;
  @override
  final StoreDayHours thursday;
  @override
  final StoreDayHours friday;
  @override
  final StoreDayHours saturday;
  @override
  final StoreDayHours sunday;

  @override
  String toString() {
    return 'StoreOperatingHours(monday: $monday, tuesday: $tuesday, wednesday: $wednesday, thursday: $thursday, friday: $friday, saturday: $saturday, sunday: $sunday)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StoreOperatingHoursImpl &&
            (identical(other.monday, monday) || other.monday == monday) &&
            (identical(other.tuesday, tuesday) || other.tuesday == tuesday) &&
            (identical(other.wednesday, wednesday) ||
                other.wednesday == wednesday) &&
            (identical(other.thursday, thursday) ||
                other.thursday == thursday) &&
            (identical(other.friday, friday) || other.friday == friday) &&
            (identical(other.saturday, saturday) ||
                other.saturday == saturday) &&
            (identical(other.sunday, sunday) || other.sunday == sunday));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, monday, tuesday, wednesday,
      thursday, friday, saturday, sunday);

  /// Create a copy of StoreOperatingHours
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StoreOperatingHoursImplCopyWith<_$StoreOperatingHoursImpl> get copyWith =>
      __$$StoreOperatingHoursImplCopyWithImpl<_$StoreOperatingHoursImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StoreOperatingHoursImplToJson(
      this,
    );
  }
}

abstract class _StoreOperatingHours implements StoreOperatingHours {
  const factory _StoreOperatingHours(
      {required final StoreDayHours monday,
      required final StoreDayHours tuesday,
      required final StoreDayHours wednesday,
      required final StoreDayHours thursday,
      required final StoreDayHours friday,
      required final StoreDayHours saturday,
      required final StoreDayHours sunday}) = _$StoreOperatingHoursImpl;

  factory _StoreOperatingHours.fromJson(Map<String, dynamic> json) =
      _$StoreOperatingHoursImpl.fromJson;

  @override
  StoreDayHours get monday;
  @override
  StoreDayHours get tuesday;
  @override
  StoreDayHours get wednesday;
  @override
  StoreDayHours get thursday;
  @override
  StoreDayHours get friday;
  @override
  StoreDayHours get saturday;
  @override
  StoreDayHours get sunday;

  /// Create a copy of StoreOperatingHours
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StoreOperatingHoursImplCopyWith<_$StoreOperatingHoursImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StoreDayHours _$StoreDayHoursFromJson(Map<String, dynamic> json) {
  return _StoreDayHours.fromJson(json);
}

/// @nodoc
mixin _$StoreDayHours {
  String get open => throw _privateConstructorUsedError;
  String get close => throw _privateConstructorUsedError;
  bool get isClosed => throw _privateConstructorUsedError;

  /// Serializes this StoreDayHours to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StoreDayHours
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StoreDayHoursCopyWith<StoreDayHours> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StoreDayHoursCopyWith<$Res> {
  factory $StoreDayHoursCopyWith(
          StoreDayHours value, $Res Function(StoreDayHours) then) =
      _$StoreDayHoursCopyWithImpl<$Res, StoreDayHours>;
  @useResult
  $Res call({String open, String close, bool isClosed});
}

/// @nodoc
class _$StoreDayHoursCopyWithImpl<$Res, $Val extends StoreDayHours>
    implements $StoreDayHoursCopyWith<$Res> {
  _$StoreDayHoursCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StoreDayHours
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? open = null,
    Object? close = null,
    Object? isClosed = null,
  }) {
    return _then(_value.copyWith(
      open: null == open
          ? _value.open
          : open // ignore: cast_nullable_to_non_nullable
              as String,
      close: null == close
          ? _value.close
          : close // ignore: cast_nullable_to_non_nullable
              as String,
      isClosed: null == isClosed
          ? _value.isClosed
          : isClosed // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StoreDayHoursImplCopyWith<$Res>
    implements $StoreDayHoursCopyWith<$Res> {
  factory _$$StoreDayHoursImplCopyWith(
          _$StoreDayHoursImpl value, $Res Function(_$StoreDayHoursImpl) then) =
      __$$StoreDayHoursImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String open, String close, bool isClosed});
}

/// @nodoc
class __$$StoreDayHoursImplCopyWithImpl<$Res>
    extends _$StoreDayHoursCopyWithImpl<$Res, _$StoreDayHoursImpl>
    implements _$$StoreDayHoursImplCopyWith<$Res> {
  __$$StoreDayHoursImplCopyWithImpl(
      _$StoreDayHoursImpl _value, $Res Function(_$StoreDayHoursImpl) _then)
      : super(_value, _then);

  /// Create a copy of StoreDayHours
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? open = null,
    Object? close = null,
    Object? isClosed = null,
  }) {
    return _then(_$StoreDayHoursImpl(
      open: null == open
          ? _value.open
          : open // ignore: cast_nullable_to_non_nullable
              as String,
      close: null == close
          ? _value.close
          : close // ignore: cast_nullable_to_non_nullable
              as String,
      isClosed: null == isClosed
          ? _value.isClosed
          : isClosed // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StoreDayHoursImpl implements _StoreDayHours {
  const _$StoreDayHoursImpl(
      {required this.open, required this.close, this.isClosed = false});

  factory _$StoreDayHoursImpl.fromJson(Map<String, dynamic> json) =>
      _$$StoreDayHoursImplFromJson(json);

  @override
  final String open;
  @override
  final String close;
  @override
  @JsonKey()
  final bool isClosed;

  @override
  String toString() {
    return 'StoreDayHours(open: $open, close: $close, isClosed: $isClosed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StoreDayHoursImpl &&
            (identical(other.open, open) || other.open == open) &&
            (identical(other.close, close) || other.close == close) &&
            (identical(other.isClosed, isClosed) ||
                other.isClosed == isClosed));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, open, close, isClosed);

  /// Create a copy of StoreDayHours
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StoreDayHoursImplCopyWith<_$StoreDayHoursImpl> get copyWith =>
      __$$StoreDayHoursImplCopyWithImpl<_$StoreDayHoursImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StoreDayHoursImplToJson(
      this,
    );
  }
}

abstract class _StoreDayHours implements StoreDayHours {
  const factory _StoreDayHours(
      {required final String open,
      required final String close,
      final bool isClosed}) = _$StoreDayHoursImpl;

  factory _StoreDayHours.fromJson(Map<String, dynamic> json) =
      _$StoreDayHoursImpl.fromJson;

  @override
  String get open;
  @override
  String get close;
  @override
  bool get isClosed;

  /// Create a copy of StoreDayHours
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StoreDayHoursImplCopyWith<_$StoreDayHoursImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StoreCompanyInfo _$StoreCompanyInfoFromJson(Map<String, dynamic> json) {
  return _StoreCompanyInfo.fromJson(json);
}

/// @nodoc
mixin _$StoreCompanyInfo {
  String? get companyId => throw _privateConstructorUsedError;
  String? get companyName => throw _privateConstructorUsedError;
  List<String> get subsidiaryStores => throw _privateConstructorUsedError;

  /// Serializes this StoreCompanyInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StoreCompanyInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StoreCompanyInfoCopyWith<StoreCompanyInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StoreCompanyInfoCopyWith<$Res> {
  factory $StoreCompanyInfoCopyWith(
          StoreCompanyInfo value, $Res Function(StoreCompanyInfo) then) =
      _$StoreCompanyInfoCopyWithImpl<$Res, StoreCompanyInfo>;
  @useResult
  $Res call(
      {String? companyId, String? companyName, List<String> subsidiaryStores});
}

/// @nodoc
class _$StoreCompanyInfoCopyWithImpl<$Res, $Val extends StoreCompanyInfo>
    implements $StoreCompanyInfoCopyWith<$Res> {
  _$StoreCompanyInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StoreCompanyInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? companyId = freezed,
    Object? companyName = freezed,
    Object? subsidiaryStores = null,
  }) {
    return _then(_value.copyWith(
      companyId: freezed == companyId
          ? _value.companyId
          : companyId // ignore: cast_nullable_to_non_nullable
              as String?,
      companyName: freezed == companyName
          ? _value.companyName
          : companyName // ignore: cast_nullable_to_non_nullable
              as String?,
      subsidiaryStores: null == subsidiaryStores
          ? _value.subsidiaryStores
          : subsidiaryStores // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StoreCompanyInfoImplCopyWith<$Res>
    implements $StoreCompanyInfoCopyWith<$Res> {
  factory _$$StoreCompanyInfoImplCopyWith(_$StoreCompanyInfoImpl value,
          $Res Function(_$StoreCompanyInfoImpl) then) =
      __$$StoreCompanyInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? companyId, String? companyName, List<String> subsidiaryStores});
}

/// @nodoc
class __$$StoreCompanyInfoImplCopyWithImpl<$Res>
    extends _$StoreCompanyInfoCopyWithImpl<$Res, _$StoreCompanyInfoImpl>
    implements _$$StoreCompanyInfoImplCopyWith<$Res> {
  __$$StoreCompanyInfoImplCopyWithImpl(_$StoreCompanyInfoImpl _value,
      $Res Function(_$StoreCompanyInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of StoreCompanyInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? companyId = freezed,
    Object? companyName = freezed,
    Object? subsidiaryStores = null,
  }) {
    return _then(_$StoreCompanyInfoImpl(
      companyId: freezed == companyId
          ? _value.companyId
          : companyId // ignore: cast_nullable_to_non_nullable
              as String?,
      companyName: freezed == companyName
          ? _value.companyName
          : companyName // ignore: cast_nullable_to_non_nullable
              as String?,
      subsidiaryStores: null == subsidiaryStores
          ? _value._subsidiaryStores
          : subsidiaryStores // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StoreCompanyInfoImpl implements _StoreCompanyInfo {
  const _$StoreCompanyInfoImpl(
      {this.companyId,
      this.companyName,
      final List<String> subsidiaryStores = const []})
      : _subsidiaryStores = subsidiaryStores;

  factory _$StoreCompanyInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$StoreCompanyInfoImplFromJson(json);

  @override
  final String? companyId;
  @override
  final String? companyName;
  final List<String> _subsidiaryStores;
  @override
  @JsonKey()
  List<String> get subsidiaryStores {
    if (_subsidiaryStores is EqualUnmodifiableListView)
      return _subsidiaryStores;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_subsidiaryStores);
  }

  @override
  String toString() {
    return 'StoreCompanyInfo(companyId: $companyId, companyName: $companyName, subsidiaryStores: $subsidiaryStores)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StoreCompanyInfoImpl &&
            (identical(other.companyId, companyId) ||
                other.companyId == companyId) &&
            (identical(other.companyName, companyName) ||
                other.companyName == companyName) &&
            const DeepCollectionEquality()
                .equals(other._subsidiaryStores, _subsidiaryStores));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, companyId, companyName,
      const DeepCollectionEquality().hash(_subsidiaryStores));

  /// Create a copy of StoreCompanyInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StoreCompanyInfoImplCopyWith<_$StoreCompanyInfoImpl> get copyWith =>
      __$$StoreCompanyInfoImplCopyWithImpl<_$StoreCompanyInfoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StoreCompanyInfoImplToJson(
      this,
    );
  }
}

abstract class _StoreCompanyInfo implements StoreCompanyInfo {
  const factory _StoreCompanyInfo(
      {final String? companyId,
      final String? companyName,
      final List<String> subsidiaryStores}) = _$StoreCompanyInfoImpl;

  factory _StoreCompanyInfo.fromJson(Map<String, dynamic> json) =
      _$StoreCompanyInfoImpl.fromJson;

  @override
  String? get companyId;
  @override
  String? get companyName;
  @override
  List<String> get subsidiaryStores;

  /// Create a copy of StoreCompanyInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StoreCompanyInfoImplCopyWith<_$StoreCompanyInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
