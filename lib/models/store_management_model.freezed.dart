// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'store_management_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

StoreManagement _$StoreManagementFromJson(Map<String, dynamic> json) {
  return _StoreManagement.fromJson(json);
}

/// @nodoc
mixin _$StoreManagement {
  String get id => throw _privateConstructorUsedError;
  String get storeId => throw _privateConstructorUsedError;
  String get managerId => throw _privateConstructorUsedError;
  String get storeName => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get address => throw _privateConstructorUsedError;
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;
  String get phoneNumber => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  StoreStatus get status => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  List<String>? get businessHours => throw _privateConstructorUsedError;
  List<String>? get paymentMethods => throw _privateConstructorUsedError;
  Map<String, dynamic>? get settings => throw _privateConstructorUsedError;
  int get totalVisitors => throw _privateConstructorUsedError;
  int get totalPointsAwarded => throw _privateConstructorUsedError;
  int get totalCouponsIssued => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;

  /// Serializes this StoreManagement to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StoreManagement
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StoreManagementCopyWith<StoreManagement> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StoreManagementCopyWith<$Res> {
  factory $StoreManagementCopyWith(
          StoreManagement value, $Res Function(StoreManagement) then) =
      _$StoreManagementCopyWithImpl<$Res, StoreManagement>;
  @useResult
  $Res call(
      {String id,
      String storeId,
      String managerId,
      String storeName,
      String description,
      String address,
      double latitude,
      double longitude,
      String phoneNumber,
      String email,
      StoreStatus status,
      DateTime createdAt,
      DateTime updatedAt,
      String? imageUrl,
      List<String>? businessHours,
      List<String>? paymentMethods,
      Map<String, dynamic>? settings,
      int totalVisitors,
      int totalPointsAwarded,
      int totalCouponsIssued,
      List<String> tags});
}

/// @nodoc
class _$StoreManagementCopyWithImpl<$Res, $Val extends StoreManagement>
    implements $StoreManagementCopyWith<$Res> {
  _$StoreManagementCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StoreManagement
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? storeId = null,
    Object? managerId = null,
    Object? storeName = null,
    Object? description = null,
    Object? address = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? phoneNumber = null,
    Object? email = null,
    Object? status = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? imageUrl = freezed,
    Object? businessHours = freezed,
    Object? paymentMethods = freezed,
    Object? settings = freezed,
    Object? totalVisitors = null,
    Object? totalPointsAwarded = null,
    Object? totalCouponsIssued = null,
    Object? tags = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      storeId: null == storeId
          ? _value.storeId
          : storeId // ignore: cast_nullable_to_non_nullable
              as String,
      managerId: null == managerId
          ? _value.managerId
          : managerId // ignore: cast_nullable_to_non_nullable
              as String,
      storeName: null == storeName
          ? _value.storeName
          : storeName // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      phoneNumber: null == phoneNumber
          ? _value.phoneNumber
          : phoneNumber // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as StoreStatus,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      businessHours: freezed == businessHours
          ? _value.businessHours
          : businessHours // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      paymentMethods: freezed == paymentMethods
          ? _value.paymentMethods
          : paymentMethods // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      settings: freezed == settings
          ? _value.settings
          : settings // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      totalVisitors: null == totalVisitors
          ? _value.totalVisitors
          : totalVisitors // ignore: cast_nullable_to_non_nullable
              as int,
      totalPointsAwarded: null == totalPointsAwarded
          ? _value.totalPointsAwarded
          : totalPointsAwarded // ignore: cast_nullable_to_non_nullable
              as int,
      totalCouponsIssued: null == totalCouponsIssued
          ? _value.totalCouponsIssued
          : totalCouponsIssued // ignore: cast_nullable_to_non_nullable
              as int,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StoreManagementImplCopyWith<$Res>
    implements $StoreManagementCopyWith<$Res> {
  factory _$$StoreManagementImplCopyWith(_$StoreManagementImpl value,
          $Res Function(_$StoreManagementImpl) then) =
      __$$StoreManagementImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String storeId,
      String managerId,
      String storeName,
      String description,
      String address,
      double latitude,
      double longitude,
      String phoneNumber,
      String email,
      StoreStatus status,
      DateTime createdAt,
      DateTime updatedAt,
      String? imageUrl,
      List<String>? businessHours,
      List<String>? paymentMethods,
      Map<String, dynamic>? settings,
      int totalVisitors,
      int totalPointsAwarded,
      int totalCouponsIssued,
      List<String> tags});
}

/// @nodoc
class __$$StoreManagementImplCopyWithImpl<$Res>
    extends _$StoreManagementCopyWithImpl<$Res, _$StoreManagementImpl>
    implements _$$StoreManagementImplCopyWith<$Res> {
  __$$StoreManagementImplCopyWithImpl(
      _$StoreManagementImpl _value, $Res Function(_$StoreManagementImpl) _then)
      : super(_value, _then);

  /// Create a copy of StoreManagement
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? storeId = null,
    Object? managerId = null,
    Object? storeName = null,
    Object? description = null,
    Object? address = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? phoneNumber = null,
    Object? email = null,
    Object? status = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? imageUrl = freezed,
    Object? businessHours = freezed,
    Object? paymentMethods = freezed,
    Object? settings = freezed,
    Object? totalVisitors = null,
    Object? totalPointsAwarded = null,
    Object? totalCouponsIssued = null,
    Object? tags = null,
  }) {
    return _then(_$StoreManagementImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      storeId: null == storeId
          ? _value.storeId
          : storeId // ignore: cast_nullable_to_non_nullable
              as String,
      managerId: null == managerId
          ? _value.managerId
          : managerId // ignore: cast_nullable_to_non_nullable
              as String,
      storeName: null == storeName
          ? _value.storeName
          : storeName // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      phoneNumber: null == phoneNumber
          ? _value.phoneNumber
          : phoneNumber // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as StoreStatus,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      businessHours: freezed == businessHours
          ? _value._businessHours
          : businessHours // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      paymentMethods: freezed == paymentMethods
          ? _value._paymentMethods
          : paymentMethods // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      settings: freezed == settings
          ? _value._settings
          : settings // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      totalVisitors: null == totalVisitors
          ? _value.totalVisitors
          : totalVisitors // ignore: cast_nullable_to_non_nullable
              as int,
      totalPointsAwarded: null == totalPointsAwarded
          ? _value.totalPointsAwarded
          : totalPointsAwarded // ignore: cast_nullable_to_non_nullable
              as int,
      totalCouponsIssued: null == totalCouponsIssued
          ? _value.totalCouponsIssued
          : totalCouponsIssued // ignore: cast_nullable_to_non_nullable
              as int,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StoreManagementImpl implements _StoreManagement {
  const _$StoreManagementImpl(
      {required this.id,
      required this.storeId,
      required this.managerId,
      required this.storeName,
      required this.description,
      required this.address,
      required this.latitude,
      required this.longitude,
      required this.phoneNumber,
      required this.email,
      required this.status,
      required this.createdAt,
      required this.updatedAt,
      this.imageUrl,
      final List<String>? businessHours,
      final List<String>? paymentMethods,
      final Map<String, dynamic>? settings,
      this.totalVisitors = 0,
      this.totalPointsAwarded = 0,
      this.totalCouponsIssued = 0,
      final List<String> tags = const []})
      : _businessHours = businessHours,
        _paymentMethods = paymentMethods,
        _settings = settings,
        _tags = tags;

  factory _$StoreManagementImpl.fromJson(Map<String, dynamic> json) =>
      _$$StoreManagementImplFromJson(json);

  @override
  final String id;
  @override
  final String storeId;
  @override
  final String managerId;
  @override
  final String storeName;
  @override
  final String description;
  @override
  final String address;
  @override
  final double latitude;
  @override
  final double longitude;
  @override
  final String phoneNumber;
  @override
  final String email;
  @override
  final StoreStatus status;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final String? imageUrl;
  final List<String>? _businessHours;
  @override
  List<String>? get businessHours {
    final value = _businessHours;
    if (value == null) return null;
    if (_businessHours is EqualUnmodifiableListView) return _businessHours;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _paymentMethods;
  @override
  List<String>? get paymentMethods {
    final value = _paymentMethods;
    if (value == null) return null;
    if (_paymentMethods is EqualUnmodifiableListView) return _paymentMethods;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final Map<String, dynamic>? _settings;
  @override
  Map<String, dynamic>? get settings {
    final value = _settings;
    if (value == null) return null;
    if (_settings is EqualUnmodifiableMapView) return _settings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey()
  final int totalVisitors;
  @override
  @JsonKey()
  final int totalPointsAwarded;
  @override
  @JsonKey()
  final int totalCouponsIssued;
  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  String toString() {
    return 'StoreManagement(id: $id, storeId: $storeId, managerId: $managerId, storeName: $storeName, description: $description, address: $address, latitude: $latitude, longitude: $longitude, phoneNumber: $phoneNumber, email: $email, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, imageUrl: $imageUrl, businessHours: $businessHours, paymentMethods: $paymentMethods, settings: $settings, totalVisitors: $totalVisitors, totalPointsAwarded: $totalPointsAwarded, totalCouponsIssued: $totalCouponsIssued, tags: $tags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StoreManagementImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.storeId, storeId) || other.storeId == storeId) &&
            (identical(other.managerId, managerId) ||
                other.managerId == managerId) &&
            (identical(other.storeName, storeName) ||
                other.storeName == storeName) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.phoneNumber, phoneNumber) ||
                other.phoneNumber == phoneNumber) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            const DeepCollectionEquality()
                .equals(other._businessHours, _businessHours) &&
            const DeepCollectionEquality()
                .equals(other._paymentMethods, _paymentMethods) &&
            const DeepCollectionEquality().equals(other._settings, _settings) &&
            (identical(other.totalVisitors, totalVisitors) ||
                other.totalVisitors == totalVisitors) &&
            (identical(other.totalPointsAwarded, totalPointsAwarded) ||
                other.totalPointsAwarded == totalPointsAwarded) &&
            (identical(other.totalCouponsIssued, totalCouponsIssued) ||
                other.totalCouponsIssued == totalCouponsIssued) &&
            const DeepCollectionEquality().equals(other._tags, _tags));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        storeId,
        managerId,
        storeName,
        description,
        address,
        latitude,
        longitude,
        phoneNumber,
        email,
        status,
        createdAt,
        updatedAt,
        imageUrl,
        const DeepCollectionEquality().hash(_businessHours),
        const DeepCollectionEquality().hash(_paymentMethods),
        const DeepCollectionEquality().hash(_settings),
        totalVisitors,
        totalPointsAwarded,
        totalCouponsIssued,
        const DeepCollectionEquality().hash(_tags)
      ]);

  /// Create a copy of StoreManagement
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StoreManagementImplCopyWith<_$StoreManagementImpl> get copyWith =>
      __$$StoreManagementImplCopyWithImpl<_$StoreManagementImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StoreManagementImplToJson(
      this,
    );
  }
}

abstract class _StoreManagement implements StoreManagement {
  const factory _StoreManagement(
      {required final String id,
      required final String storeId,
      required final String managerId,
      required final String storeName,
      required final String description,
      required final String address,
      required final double latitude,
      required final double longitude,
      required final String phoneNumber,
      required final String email,
      required final StoreStatus status,
      required final DateTime createdAt,
      required final DateTime updatedAt,
      final String? imageUrl,
      final List<String>? businessHours,
      final List<String>? paymentMethods,
      final Map<String, dynamic>? settings,
      final int totalVisitors,
      final int totalPointsAwarded,
      final int totalCouponsIssued,
      final List<String> tags}) = _$StoreManagementImpl;

  factory _StoreManagement.fromJson(Map<String, dynamic> json) =
      _$StoreManagementImpl.fromJson;

  @override
  String get id;
  @override
  String get storeId;
  @override
  String get managerId;
  @override
  String get storeName;
  @override
  String get description;
  @override
  String get address;
  @override
  double get latitude;
  @override
  double get longitude;
  @override
  String get phoneNumber;
  @override
  String get email;
  @override
  StoreStatus get status;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  String? get imageUrl;
  @override
  List<String>? get businessHours;
  @override
  List<String>? get paymentMethods;
  @override
  Map<String, dynamic>? get settings;
  @override
  int get totalVisitors;
  @override
  int get totalPointsAwarded;
  @override
  int get totalCouponsIssued;
  @override
  List<String> get tags;

  /// Create a copy of StoreManagement
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StoreManagementImplCopyWith<_$StoreManagementImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StoreAnalytics _$StoreAnalyticsFromJson(Map<String, dynamic> json) {
  return _StoreAnalytics.fromJson(json);
}

/// @nodoc
mixin _$StoreAnalytics {
  String get storeId => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  int get visitors => throw _privateConstructorUsedError;
  int get pointsAwarded => throw _privateConstructorUsedError;
  int get couponsIssued => throw _privateConstructorUsedError;
  double get revenue => throw _privateConstructorUsedError;
  Map<String, dynamic> get metrics => throw _privateConstructorUsedError;

  /// Serializes this StoreAnalytics to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StoreAnalytics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StoreAnalyticsCopyWith<StoreAnalytics> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StoreAnalyticsCopyWith<$Res> {
  factory $StoreAnalyticsCopyWith(
          StoreAnalytics value, $Res Function(StoreAnalytics) then) =
      _$StoreAnalyticsCopyWithImpl<$Res, StoreAnalytics>;
  @useResult
  $Res call(
      {String storeId,
      DateTime date,
      int visitors,
      int pointsAwarded,
      int couponsIssued,
      double revenue,
      Map<String, dynamic> metrics});
}

/// @nodoc
class _$StoreAnalyticsCopyWithImpl<$Res, $Val extends StoreAnalytics>
    implements $StoreAnalyticsCopyWith<$Res> {
  _$StoreAnalyticsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StoreAnalytics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? storeId = null,
    Object? date = null,
    Object? visitors = null,
    Object? pointsAwarded = null,
    Object? couponsIssued = null,
    Object? revenue = null,
    Object? metrics = null,
  }) {
    return _then(_value.copyWith(
      storeId: null == storeId
          ? _value.storeId
          : storeId // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      visitors: null == visitors
          ? _value.visitors
          : visitors // ignore: cast_nullable_to_non_nullable
              as int,
      pointsAwarded: null == pointsAwarded
          ? _value.pointsAwarded
          : pointsAwarded // ignore: cast_nullable_to_non_nullable
              as int,
      couponsIssued: null == couponsIssued
          ? _value.couponsIssued
          : couponsIssued // ignore: cast_nullable_to_non_nullable
              as int,
      revenue: null == revenue
          ? _value.revenue
          : revenue // ignore: cast_nullable_to_non_nullable
              as double,
      metrics: null == metrics
          ? _value.metrics
          : metrics // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StoreAnalyticsImplCopyWith<$Res>
    implements $StoreAnalyticsCopyWith<$Res> {
  factory _$$StoreAnalyticsImplCopyWith(_$StoreAnalyticsImpl value,
          $Res Function(_$StoreAnalyticsImpl) then) =
      __$$StoreAnalyticsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String storeId,
      DateTime date,
      int visitors,
      int pointsAwarded,
      int couponsIssued,
      double revenue,
      Map<String, dynamic> metrics});
}

/// @nodoc
class __$$StoreAnalyticsImplCopyWithImpl<$Res>
    extends _$StoreAnalyticsCopyWithImpl<$Res, _$StoreAnalyticsImpl>
    implements _$$StoreAnalyticsImplCopyWith<$Res> {
  __$$StoreAnalyticsImplCopyWithImpl(
      _$StoreAnalyticsImpl _value, $Res Function(_$StoreAnalyticsImpl) _then)
      : super(_value, _then);

  /// Create a copy of StoreAnalytics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? storeId = null,
    Object? date = null,
    Object? visitors = null,
    Object? pointsAwarded = null,
    Object? couponsIssued = null,
    Object? revenue = null,
    Object? metrics = null,
  }) {
    return _then(_$StoreAnalyticsImpl(
      storeId: null == storeId
          ? _value.storeId
          : storeId // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      visitors: null == visitors
          ? _value.visitors
          : visitors // ignore: cast_nullable_to_non_nullable
              as int,
      pointsAwarded: null == pointsAwarded
          ? _value.pointsAwarded
          : pointsAwarded // ignore: cast_nullable_to_non_nullable
              as int,
      couponsIssued: null == couponsIssued
          ? _value.couponsIssued
          : couponsIssued // ignore: cast_nullable_to_non_nullable
              as int,
      revenue: null == revenue
          ? _value.revenue
          : revenue // ignore: cast_nullable_to_non_nullable
              as double,
      metrics: null == metrics
          ? _value._metrics
          : metrics // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StoreAnalyticsImpl implements _StoreAnalytics {
  const _$StoreAnalyticsImpl(
      {required this.storeId,
      required this.date,
      required this.visitors,
      required this.pointsAwarded,
      required this.couponsIssued,
      required this.revenue,
      required final Map<String, dynamic> metrics})
      : _metrics = metrics;

  factory _$StoreAnalyticsImpl.fromJson(Map<String, dynamic> json) =>
      _$$StoreAnalyticsImplFromJson(json);

  @override
  final String storeId;
  @override
  final DateTime date;
  @override
  final int visitors;
  @override
  final int pointsAwarded;
  @override
  final int couponsIssued;
  @override
  final double revenue;
  final Map<String, dynamic> _metrics;
  @override
  Map<String, dynamic> get metrics {
    if (_metrics is EqualUnmodifiableMapView) return _metrics;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metrics);
  }

  @override
  String toString() {
    return 'StoreAnalytics(storeId: $storeId, date: $date, visitors: $visitors, pointsAwarded: $pointsAwarded, couponsIssued: $couponsIssued, revenue: $revenue, metrics: $metrics)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StoreAnalyticsImpl &&
            (identical(other.storeId, storeId) || other.storeId == storeId) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.visitors, visitors) ||
                other.visitors == visitors) &&
            (identical(other.pointsAwarded, pointsAwarded) ||
                other.pointsAwarded == pointsAwarded) &&
            (identical(other.couponsIssued, couponsIssued) ||
                other.couponsIssued == couponsIssued) &&
            (identical(other.revenue, revenue) || other.revenue == revenue) &&
            const DeepCollectionEquality().equals(other._metrics, _metrics));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      storeId,
      date,
      visitors,
      pointsAwarded,
      couponsIssued,
      revenue,
      const DeepCollectionEquality().hash(_metrics));

  /// Create a copy of StoreAnalytics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StoreAnalyticsImplCopyWith<_$StoreAnalyticsImpl> get copyWith =>
      __$$StoreAnalyticsImplCopyWithImpl<_$StoreAnalyticsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StoreAnalyticsImplToJson(
      this,
    );
  }
}

abstract class _StoreAnalytics implements StoreAnalytics {
  const factory _StoreAnalytics(
      {required final String storeId,
      required final DateTime date,
      required final int visitors,
      required final int pointsAwarded,
      required final int couponsIssued,
      required final double revenue,
      required final Map<String, dynamic> metrics}) = _$StoreAnalyticsImpl;

  factory _StoreAnalytics.fromJson(Map<String, dynamic> json) =
      _$StoreAnalyticsImpl.fromJson;

  @override
  String get storeId;
  @override
  DateTime get date;
  @override
  int get visitors;
  @override
  int get pointsAwarded;
  @override
  int get couponsIssued;
  @override
  double get revenue;
  @override
  Map<String, dynamic> get metrics;

  /// Create a copy of StoreAnalytics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StoreAnalyticsImplCopyWith<_$StoreAnalyticsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StoreStaff _$StoreStaffFromJson(Map<String, dynamic> json) {
  return _StoreStaff.fromJson(json);
}

/// @nodoc
mixin _$StoreStaff {
  String get id => throw _privateConstructorUsedError;
  String get storeId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  StaffRole get role => throw _privateConstructorUsedError;
  DateTime get joinedAt => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  Map<String, dynamic>? get permissions => throw _privateConstructorUsedError;

  /// Serializes this StoreStaff to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StoreStaff
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StoreStaffCopyWith<StoreStaff> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StoreStaffCopyWith<$Res> {
  factory $StoreStaffCopyWith(
          StoreStaff value, $Res Function(StoreStaff) then) =
      _$StoreStaffCopyWithImpl<$Res, StoreStaff>;
  @useResult
  $Res call(
      {String id,
      String storeId,
      String userId,
      String name,
      String email,
      StaffRole role,
      DateTime joinedAt,
      bool isActive,
      Map<String, dynamic>? permissions});
}

/// @nodoc
class _$StoreStaffCopyWithImpl<$Res, $Val extends StoreStaff>
    implements $StoreStaffCopyWith<$Res> {
  _$StoreStaffCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StoreStaff
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? storeId = null,
    Object? userId = null,
    Object? name = null,
    Object? email = null,
    Object? role = null,
    Object? joinedAt = null,
    Object? isActive = null,
    Object? permissions = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      storeId: null == storeId
          ? _value.storeId
          : storeId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as StaffRole,
      joinedAt: null == joinedAt
          ? _value.joinedAt
          : joinedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      permissions: freezed == permissions
          ? _value.permissions
          : permissions // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StoreStaffImplCopyWith<$Res>
    implements $StoreStaffCopyWith<$Res> {
  factory _$$StoreStaffImplCopyWith(
          _$StoreStaffImpl value, $Res Function(_$StoreStaffImpl) then) =
      __$$StoreStaffImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String storeId,
      String userId,
      String name,
      String email,
      StaffRole role,
      DateTime joinedAt,
      bool isActive,
      Map<String, dynamic>? permissions});
}

/// @nodoc
class __$$StoreStaffImplCopyWithImpl<$Res>
    extends _$StoreStaffCopyWithImpl<$Res, _$StoreStaffImpl>
    implements _$$StoreStaffImplCopyWith<$Res> {
  __$$StoreStaffImplCopyWithImpl(
      _$StoreStaffImpl _value, $Res Function(_$StoreStaffImpl) _then)
      : super(_value, _then);

  /// Create a copy of StoreStaff
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? storeId = null,
    Object? userId = null,
    Object? name = null,
    Object? email = null,
    Object? role = null,
    Object? joinedAt = null,
    Object? isActive = null,
    Object? permissions = freezed,
  }) {
    return _then(_$StoreStaffImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      storeId: null == storeId
          ? _value.storeId
          : storeId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as StaffRole,
      joinedAt: null == joinedAt
          ? _value.joinedAt
          : joinedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      permissions: freezed == permissions
          ? _value._permissions
          : permissions // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StoreStaffImpl implements _StoreStaff {
  const _$StoreStaffImpl(
      {required this.id,
      required this.storeId,
      required this.userId,
      required this.name,
      required this.email,
      required this.role,
      required this.joinedAt,
      required this.isActive,
      final Map<String, dynamic>? permissions})
      : _permissions = permissions;

  factory _$StoreStaffImpl.fromJson(Map<String, dynamic> json) =>
      _$$StoreStaffImplFromJson(json);

  @override
  final String id;
  @override
  final String storeId;
  @override
  final String userId;
  @override
  final String name;
  @override
  final String email;
  @override
  final StaffRole role;
  @override
  final DateTime joinedAt;
  @override
  final bool isActive;
  final Map<String, dynamic>? _permissions;
  @override
  Map<String, dynamic>? get permissions {
    final value = _permissions;
    if (value == null) return null;
    if (_permissions is EqualUnmodifiableMapView) return _permissions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'StoreStaff(id: $id, storeId: $storeId, userId: $userId, name: $name, email: $email, role: $role, joinedAt: $joinedAt, isActive: $isActive, permissions: $permissions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StoreStaffImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.storeId, storeId) || other.storeId == storeId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.joinedAt, joinedAt) ||
                other.joinedAt == joinedAt) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            const DeepCollectionEquality()
                .equals(other._permissions, _permissions));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      storeId,
      userId,
      name,
      email,
      role,
      joinedAt,
      isActive,
      const DeepCollectionEquality().hash(_permissions));

  /// Create a copy of StoreStaff
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StoreStaffImplCopyWith<_$StoreStaffImpl> get copyWith =>
      __$$StoreStaffImplCopyWithImpl<_$StoreStaffImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StoreStaffImplToJson(
      this,
    );
  }
}

abstract class _StoreStaff implements StoreStaff {
  const factory _StoreStaff(
      {required final String id,
      required final String storeId,
      required final String userId,
      required final String name,
      required final String email,
      required final StaffRole role,
      required final DateTime joinedAt,
      required final bool isActive,
      final Map<String, dynamic>? permissions}) = _$StoreStaffImpl;

  factory _StoreStaff.fromJson(Map<String, dynamic> json) =
      _$StoreStaffImpl.fromJson;

  @override
  String get id;
  @override
  String get storeId;
  @override
  String get userId;
  @override
  String get name;
  @override
  String get email;
  @override
  StaffRole get role;
  @override
  DateTime get joinedAt;
  @override
  bool get isActive;
  @override
  Map<String, dynamic>? get permissions;

  /// Create a copy of StoreStaff
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StoreStaffImplCopyWith<_$StoreStaffImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StoreMenu _$StoreMenuFromJson(Map<String, dynamic> json) {
  return _StoreMenu.fromJson(json);
}

/// @nodoc
mixin _$StoreMenu {
  String get id => throw _privateConstructorUsedError;
  String get storeId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  bool get isAvailable => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  List<String>? get ingredients => throw _privateConstructorUsedError;
  Map<String, dynamic>? get nutritionInfo => throw _privateConstructorUsedError;
  int get orderCount => throw _privateConstructorUsedError;

  /// Serializes this StoreMenu to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StoreMenu
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StoreMenuCopyWith<StoreMenu> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StoreMenuCopyWith<$Res> {
  factory $StoreMenuCopyWith(StoreMenu value, $Res Function(StoreMenu) then) =
      _$StoreMenuCopyWithImpl<$Res, StoreMenu>;
  @useResult
  $Res call(
      {String id,
      String storeId,
      String name,
      String description,
      double price,
      String category,
      bool isAvailable,
      DateTime createdAt,
      DateTime updatedAt,
      String? imageUrl,
      List<String>? ingredients,
      Map<String, dynamic>? nutritionInfo,
      int orderCount});
}

/// @nodoc
class _$StoreMenuCopyWithImpl<$Res, $Val extends StoreMenu>
    implements $StoreMenuCopyWith<$Res> {
  _$StoreMenuCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StoreMenu
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? storeId = null,
    Object? name = null,
    Object? description = null,
    Object? price = null,
    Object? category = null,
    Object? isAvailable = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? imageUrl = freezed,
    Object? ingredients = freezed,
    Object? nutritionInfo = freezed,
    Object? orderCount = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
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
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      isAvailable: null == isAvailable
          ? _value.isAvailable
          : isAvailable // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      ingredients: freezed == ingredients
          ? _value.ingredients
          : ingredients // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      nutritionInfo: freezed == nutritionInfo
          ? _value.nutritionInfo
          : nutritionInfo // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      orderCount: null == orderCount
          ? _value.orderCount
          : orderCount // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StoreMenuImplCopyWith<$Res>
    implements $StoreMenuCopyWith<$Res> {
  factory _$$StoreMenuImplCopyWith(
          _$StoreMenuImpl value, $Res Function(_$StoreMenuImpl) then) =
      __$$StoreMenuImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String storeId,
      String name,
      String description,
      double price,
      String category,
      bool isAvailable,
      DateTime createdAt,
      DateTime updatedAt,
      String? imageUrl,
      List<String>? ingredients,
      Map<String, dynamic>? nutritionInfo,
      int orderCount});
}

/// @nodoc
class __$$StoreMenuImplCopyWithImpl<$Res>
    extends _$StoreMenuCopyWithImpl<$Res, _$StoreMenuImpl>
    implements _$$StoreMenuImplCopyWith<$Res> {
  __$$StoreMenuImplCopyWithImpl(
      _$StoreMenuImpl _value, $Res Function(_$StoreMenuImpl) _then)
      : super(_value, _then);

  /// Create a copy of StoreMenu
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? storeId = null,
    Object? name = null,
    Object? description = null,
    Object? price = null,
    Object? category = null,
    Object? isAvailable = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? imageUrl = freezed,
    Object? ingredients = freezed,
    Object? nutritionInfo = freezed,
    Object? orderCount = null,
  }) {
    return _then(_$StoreMenuImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
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
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      isAvailable: null == isAvailable
          ? _value.isAvailable
          : isAvailable // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      ingredients: freezed == ingredients
          ? _value._ingredients
          : ingredients // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      nutritionInfo: freezed == nutritionInfo
          ? _value._nutritionInfo
          : nutritionInfo // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      orderCount: null == orderCount
          ? _value.orderCount
          : orderCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StoreMenuImpl implements _StoreMenu {
  const _$StoreMenuImpl(
      {required this.id,
      required this.storeId,
      required this.name,
      required this.description,
      required this.price,
      required this.category,
      required this.isAvailable,
      required this.createdAt,
      required this.updatedAt,
      this.imageUrl,
      final List<String>? ingredients,
      final Map<String, dynamic>? nutritionInfo,
      this.orderCount = 0})
      : _ingredients = ingredients,
        _nutritionInfo = nutritionInfo;

  factory _$StoreMenuImpl.fromJson(Map<String, dynamic> json) =>
      _$$StoreMenuImplFromJson(json);

  @override
  final String id;
  @override
  final String storeId;
  @override
  final String name;
  @override
  final String description;
  @override
  final double price;
  @override
  final String category;
  @override
  final bool isAvailable;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final String? imageUrl;
  final List<String>? _ingredients;
  @override
  List<String>? get ingredients {
    final value = _ingredients;
    if (value == null) return null;
    if (_ingredients is EqualUnmodifiableListView) return _ingredients;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final Map<String, dynamic>? _nutritionInfo;
  @override
  Map<String, dynamic>? get nutritionInfo {
    final value = _nutritionInfo;
    if (value == null) return null;
    if (_nutritionInfo is EqualUnmodifiableMapView) return _nutritionInfo;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey()
  final int orderCount;

  @override
  String toString() {
    return 'StoreMenu(id: $id, storeId: $storeId, name: $name, description: $description, price: $price, category: $category, isAvailable: $isAvailable, createdAt: $createdAt, updatedAt: $updatedAt, imageUrl: $imageUrl, ingredients: $ingredients, nutritionInfo: $nutritionInfo, orderCount: $orderCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StoreMenuImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.storeId, storeId) || other.storeId == storeId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.isAvailable, isAvailable) ||
                other.isAvailable == isAvailable) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            const DeepCollectionEquality()
                .equals(other._ingredients, _ingredients) &&
            const DeepCollectionEquality()
                .equals(other._nutritionInfo, _nutritionInfo) &&
            (identical(other.orderCount, orderCount) ||
                other.orderCount == orderCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      storeId,
      name,
      description,
      price,
      category,
      isAvailable,
      createdAt,
      updatedAt,
      imageUrl,
      const DeepCollectionEquality().hash(_ingredients),
      const DeepCollectionEquality().hash(_nutritionInfo),
      orderCount);

  /// Create a copy of StoreMenu
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StoreMenuImplCopyWith<_$StoreMenuImpl> get copyWith =>
      __$$StoreMenuImplCopyWithImpl<_$StoreMenuImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StoreMenuImplToJson(
      this,
    );
  }
}

abstract class _StoreMenu implements StoreMenu {
  const factory _StoreMenu(
      {required final String id,
      required final String storeId,
      required final String name,
      required final String description,
      required final double price,
      required final String category,
      required final bool isAvailable,
      required final DateTime createdAt,
      required final DateTime updatedAt,
      final String? imageUrl,
      final List<String>? ingredients,
      final Map<String, dynamic>? nutritionInfo,
      final int orderCount}) = _$StoreMenuImpl;

  factory _StoreMenu.fromJson(Map<String, dynamic> json) =
      _$StoreMenuImpl.fromJson;

  @override
  String get id;
  @override
  String get storeId;
  @override
  String get name;
  @override
  String get description;
  @override
  double get price;
  @override
  String get category;
  @override
  bool get isAvailable;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  String? get imageUrl;
  @override
  List<String>? get ingredients;
  @override
  Map<String, dynamic>? get nutritionInfo;
  @override
  int get orderCount;

  /// Create a copy of StoreMenu
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StoreMenuImplCopyWith<_$StoreMenuImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
