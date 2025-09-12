// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'coupon_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Coupon _$CouponFromJson(Map<String, dynamic> json) {
  return _Coupon.fromJson(json);
}

/// @nodoc
mixin _$Coupon {
  String get id => throw _privateConstructorUsedError;
  String get storeId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  CouponType get type => throw _privateConstructorUsedError;
  double get discountValue => throw _privateConstructorUsedError;
  String get discountType =>
      throw _privateConstructorUsedError; // 'percentage' or 'fixed'
  DateTime get validFrom => throw _privateConstructorUsedError;
  DateTime get validUntil => throw _privateConstructorUsedError;
  int get usageLimit => throw _privateConstructorUsedError;
  int get usedCount => throw _privateConstructorUsedError;
  int get minOrderAmount => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  List<String>? get applicableItems => throw _privateConstructorUsedError;
  Map<String, dynamic>? get conditions => throw _privateConstructorUsedError;
  List<String> get usedBy => throw _privateConstructorUsedError;

  /// Serializes this Coupon to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Coupon
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CouponCopyWith<Coupon> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CouponCopyWith<$Res> {
  factory $CouponCopyWith(Coupon value, $Res Function(Coupon) then) =
      _$CouponCopyWithImpl<$Res, Coupon>;
  @useResult
  $Res call(
      {String id,
      String storeId,
      String title,
      String description,
      CouponType type,
      double discountValue,
      String discountType,
      DateTime validFrom,
      DateTime validUntil,
      int usageLimit,
      int usedCount,
      int minOrderAmount,
      bool isActive,
      DateTime createdAt,
      DateTime updatedAt,
      String? imageUrl,
      List<String>? applicableItems,
      Map<String, dynamic>? conditions,
      List<String> usedBy});
}

/// @nodoc
class _$CouponCopyWithImpl<$Res, $Val extends Coupon>
    implements $CouponCopyWith<$Res> {
  _$CouponCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Coupon
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? storeId = null,
    Object? title = null,
    Object? description = null,
    Object? type = null,
    Object? discountValue = null,
    Object? discountType = null,
    Object? validFrom = null,
    Object? validUntil = null,
    Object? usageLimit = null,
    Object? usedCount = null,
    Object? minOrderAmount = null,
    Object? isActive = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? imageUrl = freezed,
    Object? applicableItems = freezed,
    Object? conditions = freezed,
    Object? usedBy = null,
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
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as CouponType,
      discountValue: null == discountValue
          ? _value.discountValue
          : discountValue // ignore: cast_nullable_to_non_nullable
              as double,
      discountType: null == discountType
          ? _value.discountType
          : discountType // ignore: cast_nullable_to_non_nullable
              as String,
      validFrom: null == validFrom
          ? _value.validFrom
          : validFrom // ignore: cast_nullable_to_non_nullable
              as DateTime,
      validUntil: null == validUntil
          ? _value.validUntil
          : validUntil // ignore: cast_nullable_to_non_nullable
              as DateTime,
      usageLimit: null == usageLimit
          ? _value.usageLimit
          : usageLimit // ignore: cast_nullable_to_non_nullable
              as int,
      usedCount: null == usedCount
          ? _value.usedCount
          : usedCount // ignore: cast_nullable_to_non_nullable
              as int,
      minOrderAmount: null == minOrderAmount
          ? _value.minOrderAmount
          : minOrderAmount // ignore: cast_nullable_to_non_nullable
              as int,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
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
      applicableItems: freezed == applicableItems
          ? _value.applicableItems
          : applicableItems // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      conditions: freezed == conditions
          ? _value.conditions
          : conditions // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      usedBy: null == usedBy
          ? _value.usedBy
          : usedBy // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CouponImplCopyWith<$Res> implements $CouponCopyWith<$Res> {
  factory _$$CouponImplCopyWith(
          _$CouponImpl value, $Res Function(_$CouponImpl) then) =
      __$$CouponImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String storeId,
      String title,
      String description,
      CouponType type,
      double discountValue,
      String discountType,
      DateTime validFrom,
      DateTime validUntil,
      int usageLimit,
      int usedCount,
      int minOrderAmount,
      bool isActive,
      DateTime createdAt,
      DateTime updatedAt,
      String? imageUrl,
      List<String>? applicableItems,
      Map<String, dynamic>? conditions,
      List<String> usedBy});
}

/// @nodoc
class __$$CouponImplCopyWithImpl<$Res>
    extends _$CouponCopyWithImpl<$Res, _$CouponImpl>
    implements _$$CouponImplCopyWith<$Res> {
  __$$CouponImplCopyWithImpl(
      _$CouponImpl _value, $Res Function(_$CouponImpl) _then)
      : super(_value, _then);

  /// Create a copy of Coupon
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? storeId = null,
    Object? title = null,
    Object? description = null,
    Object? type = null,
    Object? discountValue = null,
    Object? discountType = null,
    Object? validFrom = null,
    Object? validUntil = null,
    Object? usageLimit = null,
    Object? usedCount = null,
    Object? minOrderAmount = null,
    Object? isActive = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? imageUrl = freezed,
    Object? applicableItems = freezed,
    Object? conditions = freezed,
    Object? usedBy = null,
  }) {
    return _then(_$CouponImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      storeId: null == storeId
          ? _value.storeId
          : storeId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as CouponType,
      discountValue: null == discountValue
          ? _value.discountValue
          : discountValue // ignore: cast_nullable_to_non_nullable
              as double,
      discountType: null == discountType
          ? _value.discountType
          : discountType // ignore: cast_nullable_to_non_nullable
              as String,
      validFrom: null == validFrom
          ? _value.validFrom
          : validFrom // ignore: cast_nullable_to_non_nullable
              as DateTime,
      validUntil: null == validUntil
          ? _value.validUntil
          : validUntil // ignore: cast_nullable_to_non_nullable
              as DateTime,
      usageLimit: null == usageLimit
          ? _value.usageLimit
          : usageLimit // ignore: cast_nullable_to_non_nullable
              as int,
      usedCount: null == usedCount
          ? _value.usedCount
          : usedCount // ignore: cast_nullable_to_non_nullable
              as int,
      minOrderAmount: null == minOrderAmount
          ? _value.minOrderAmount
          : minOrderAmount // ignore: cast_nullable_to_non_nullable
              as int,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
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
      applicableItems: freezed == applicableItems
          ? _value._applicableItems
          : applicableItems // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      conditions: freezed == conditions
          ? _value._conditions
          : conditions // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      usedBy: null == usedBy
          ? _value._usedBy
          : usedBy // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CouponImpl implements _Coupon {
  const _$CouponImpl(
      {required this.id,
      required this.storeId,
      required this.title,
      required this.description,
      required this.type,
      required this.discountValue,
      required this.discountType,
      required this.validFrom,
      required this.validUntil,
      required this.usageLimit,
      required this.usedCount,
      required this.minOrderAmount,
      required this.isActive,
      required this.createdAt,
      required this.updatedAt,
      this.imageUrl,
      final List<String>? applicableItems,
      final Map<String, dynamic>? conditions,
      final List<String> usedBy = const []})
      : _applicableItems = applicableItems,
        _conditions = conditions,
        _usedBy = usedBy;

  factory _$CouponImpl.fromJson(Map<String, dynamic> json) =>
      _$$CouponImplFromJson(json);

  @override
  final String id;
  @override
  final String storeId;
  @override
  final String title;
  @override
  final String description;
  @override
  final CouponType type;
  @override
  final double discountValue;
  @override
  final String discountType;
// 'percentage' or 'fixed'
  @override
  final DateTime validFrom;
  @override
  final DateTime validUntil;
  @override
  final int usageLimit;
  @override
  final int usedCount;
  @override
  final int minOrderAmount;
  @override
  final bool isActive;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final String? imageUrl;
  final List<String>? _applicableItems;
  @override
  List<String>? get applicableItems {
    final value = _applicableItems;
    if (value == null) return null;
    if (_applicableItems is EqualUnmodifiableListView) return _applicableItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final Map<String, dynamic>? _conditions;
  @override
  Map<String, dynamic>? get conditions {
    final value = _conditions;
    if (value == null) return null;
    if (_conditions is EqualUnmodifiableMapView) return _conditions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  final List<String> _usedBy;
  @override
  @JsonKey()
  List<String> get usedBy {
    if (_usedBy is EqualUnmodifiableListView) return _usedBy;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_usedBy);
  }

  @override
  String toString() {
    return 'Coupon(id: $id, storeId: $storeId, title: $title, description: $description, type: $type, discountValue: $discountValue, discountType: $discountType, validFrom: $validFrom, validUntil: $validUntil, usageLimit: $usageLimit, usedCount: $usedCount, minOrderAmount: $minOrderAmount, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt, imageUrl: $imageUrl, applicableItems: $applicableItems, conditions: $conditions, usedBy: $usedBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CouponImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.storeId, storeId) || other.storeId == storeId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.discountValue, discountValue) ||
                other.discountValue == discountValue) &&
            (identical(other.discountType, discountType) ||
                other.discountType == discountType) &&
            (identical(other.validFrom, validFrom) ||
                other.validFrom == validFrom) &&
            (identical(other.validUntil, validUntil) ||
                other.validUntil == validUntil) &&
            (identical(other.usageLimit, usageLimit) ||
                other.usageLimit == usageLimit) &&
            (identical(other.usedCount, usedCount) ||
                other.usedCount == usedCount) &&
            (identical(other.minOrderAmount, minOrderAmount) ||
                other.minOrderAmount == minOrderAmount) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            const DeepCollectionEquality()
                .equals(other._applicableItems, _applicableItems) &&
            const DeepCollectionEquality()
                .equals(other._conditions, _conditions) &&
            const DeepCollectionEquality().equals(other._usedBy, _usedBy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        storeId,
        title,
        description,
        type,
        discountValue,
        discountType,
        validFrom,
        validUntil,
        usageLimit,
        usedCount,
        minOrderAmount,
        isActive,
        createdAt,
        updatedAt,
        imageUrl,
        const DeepCollectionEquality().hash(_applicableItems),
        const DeepCollectionEquality().hash(_conditions),
        const DeepCollectionEquality().hash(_usedBy)
      ]);

  /// Create a copy of Coupon
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CouponImplCopyWith<_$CouponImpl> get copyWith =>
      __$$CouponImplCopyWithImpl<_$CouponImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CouponImplToJson(
      this,
    );
  }
}

abstract class _Coupon implements Coupon {
  const factory _Coupon(
      {required final String id,
      required final String storeId,
      required final String title,
      required final String description,
      required final CouponType type,
      required final double discountValue,
      required final String discountType,
      required final DateTime validFrom,
      required final DateTime validUntil,
      required final int usageLimit,
      required final int usedCount,
      required final int minOrderAmount,
      required final bool isActive,
      required final DateTime createdAt,
      required final DateTime updatedAt,
      final String? imageUrl,
      final List<String>? applicableItems,
      final Map<String, dynamic>? conditions,
      final List<String> usedBy}) = _$CouponImpl;

  factory _Coupon.fromJson(Map<String, dynamic> json) = _$CouponImpl.fromJson;

  @override
  String get id;
  @override
  String get storeId;
  @override
  String get title;
  @override
  String get description;
  @override
  CouponType get type;
  @override
  double get discountValue;
  @override
  String get discountType; // 'percentage' or 'fixed'
  @override
  DateTime get validFrom;
  @override
  DateTime get validUntil;
  @override
  int get usageLimit;
  @override
  int get usedCount;
  @override
  int get minOrderAmount;
  @override
  bool get isActive;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  String? get imageUrl;
  @override
  List<String>? get applicableItems;
  @override
  Map<String, dynamic>? get conditions;
  @override
  List<String> get usedBy;

  /// Create a copy of Coupon
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CouponImplCopyWith<_$CouponImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserCoupon _$UserCouponFromJson(Map<String, dynamic> json) {
  return _UserCoupon.fromJson(json);
}

/// @nodoc
mixin _$UserCoupon {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get couponId => throw _privateConstructorUsedError;
  DateTime get obtainedAt => throw _privateConstructorUsedError;
  DateTime? get usedAt => throw _privateConstructorUsedError;
  bool get isUsed => throw _privateConstructorUsedError;
  String? get storeId => throw _privateConstructorUsedError;
  String? get orderId => throw _privateConstructorUsedError;

  /// Serializes this UserCoupon to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserCoupon
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserCouponCopyWith<UserCoupon> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserCouponCopyWith<$Res> {
  factory $UserCouponCopyWith(
          UserCoupon value, $Res Function(UserCoupon) then) =
      _$UserCouponCopyWithImpl<$Res, UserCoupon>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String couponId,
      DateTime obtainedAt,
      DateTime? usedAt,
      bool isUsed,
      String? storeId,
      String? orderId});
}

/// @nodoc
class _$UserCouponCopyWithImpl<$Res, $Val extends UserCoupon>
    implements $UserCouponCopyWith<$Res> {
  _$UserCouponCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserCoupon
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? couponId = null,
    Object? obtainedAt = null,
    Object? usedAt = freezed,
    Object? isUsed = null,
    Object? storeId = freezed,
    Object? orderId = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      couponId: null == couponId
          ? _value.couponId
          : couponId // ignore: cast_nullable_to_non_nullable
              as String,
      obtainedAt: null == obtainedAt
          ? _value.obtainedAt
          : obtainedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      usedAt: freezed == usedAt
          ? _value.usedAt
          : usedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isUsed: null == isUsed
          ? _value.isUsed
          : isUsed // ignore: cast_nullable_to_non_nullable
              as bool,
      storeId: freezed == storeId
          ? _value.storeId
          : storeId // ignore: cast_nullable_to_non_nullable
              as String?,
      orderId: freezed == orderId
          ? _value.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserCouponImplCopyWith<$Res>
    implements $UserCouponCopyWith<$Res> {
  factory _$$UserCouponImplCopyWith(
          _$UserCouponImpl value, $Res Function(_$UserCouponImpl) then) =
      __$$UserCouponImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String couponId,
      DateTime obtainedAt,
      DateTime? usedAt,
      bool isUsed,
      String? storeId,
      String? orderId});
}

/// @nodoc
class __$$UserCouponImplCopyWithImpl<$Res>
    extends _$UserCouponCopyWithImpl<$Res, _$UserCouponImpl>
    implements _$$UserCouponImplCopyWith<$Res> {
  __$$UserCouponImplCopyWithImpl(
      _$UserCouponImpl _value, $Res Function(_$UserCouponImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserCoupon
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? couponId = null,
    Object? obtainedAt = null,
    Object? usedAt = freezed,
    Object? isUsed = null,
    Object? storeId = freezed,
    Object? orderId = freezed,
  }) {
    return _then(_$UserCouponImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      couponId: null == couponId
          ? _value.couponId
          : couponId // ignore: cast_nullable_to_non_nullable
              as String,
      obtainedAt: null == obtainedAt
          ? _value.obtainedAt
          : obtainedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      usedAt: freezed == usedAt
          ? _value.usedAt
          : usedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isUsed: null == isUsed
          ? _value.isUsed
          : isUsed // ignore: cast_nullable_to_non_nullable
              as bool,
      storeId: freezed == storeId
          ? _value.storeId
          : storeId // ignore: cast_nullable_to_non_nullable
              as String?,
      orderId: freezed == orderId
          ? _value.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserCouponImpl implements _UserCoupon {
  const _$UserCouponImpl(
      {required this.id,
      required this.userId,
      required this.couponId,
      required this.obtainedAt,
      required this.usedAt,
      required this.isUsed,
      required this.storeId,
      required this.orderId});

  factory _$UserCouponImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserCouponImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String couponId;
  @override
  final DateTime obtainedAt;
  @override
  final DateTime? usedAt;
  @override
  final bool isUsed;
  @override
  final String? storeId;
  @override
  final String? orderId;

  @override
  String toString() {
    return 'UserCoupon(id: $id, userId: $userId, couponId: $couponId, obtainedAt: $obtainedAt, usedAt: $usedAt, isUsed: $isUsed, storeId: $storeId, orderId: $orderId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserCouponImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.couponId, couponId) ||
                other.couponId == couponId) &&
            (identical(other.obtainedAt, obtainedAt) ||
                other.obtainedAt == obtainedAt) &&
            (identical(other.usedAt, usedAt) || other.usedAt == usedAt) &&
            (identical(other.isUsed, isUsed) || other.isUsed == isUsed) &&
            (identical(other.storeId, storeId) || other.storeId == storeId) &&
            (identical(other.orderId, orderId) || other.orderId == orderId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, userId, couponId, obtainedAt,
      usedAt, isUsed, storeId, orderId);

  /// Create a copy of UserCoupon
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserCouponImplCopyWith<_$UserCouponImpl> get copyWith =>
      __$$UserCouponImplCopyWithImpl<_$UserCouponImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserCouponImplToJson(
      this,
    );
  }
}

abstract class _UserCoupon implements UserCoupon {
  const factory _UserCoupon(
      {required final String id,
      required final String userId,
      required final String couponId,
      required final DateTime obtainedAt,
      required final DateTime? usedAt,
      required final bool isUsed,
      required final String? storeId,
      required final String? orderId}) = _$UserCouponImpl;

  factory _UserCoupon.fromJson(Map<String, dynamic> json) =
      _$UserCouponImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get couponId;
  @override
  DateTime get obtainedAt;
  @override
  DateTime? get usedAt;
  @override
  bool get isUsed;
  @override
  String? get storeId;
  @override
  String? get orderId;

  /// Create a copy of UserCoupon
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserCouponImplCopyWith<_$UserCouponImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Promotion _$PromotionFromJson(Map<String, dynamic> json) {
  return _Promotion.fromJson(json);
}

/// @nodoc
mixin _$Promotion {
  String get id => throw _privateConstructorUsedError;
  String get storeId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  PromotionType get type => throw _privateConstructorUsedError;
  DateTime get startDate => throw _privateConstructorUsedError;
  DateTime get endDate => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  Map<String, dynamic>? get conditions => throw _privateConstructorUsedError;
  List<String> get targetUsers => throw _privateConstructorUsedError;
  int get viewCount => throw _privateConstructorUsedError;
  int get clickCount => throw _privateConstructorUsedError;

  /// Serializes this Promotion to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Promotion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PromotionCopyWith<Promotion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PromotionCopyWith<$Res> {
  factory $PromotionCopyWith(Promotion value, $Res Function(Promotion) then) =
      _$PromotionCopyWithImpl<$Res, Promotion>;
  @useResult
  $Res call(
      {String id,
      String storeId,
      String title,
      String description,
      PromotionType type,
      DateTime startDate,
      DateTime endDate,
      bool isActive,
      DateTime createdAt,
      DateTime updatedAt,
      String? imageUrl,
      Map<String, dynamic>? conditions,
      List<String> targetUsers,
      int viewCount,
      int clickCount});
}

/// @nodoc
class _$PromotionCopyWithImpl<$Res, $Val extends Promotion>
    implements $PromotionCopyWith<$Res> {
  _$PromotionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Promotion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? storeId = null,
    Object? title = null,
    Object? description = null,
    Object? type = null,
    Object? startDate = null,
    Object? endDate = null,
    Object? isActive = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? imageUrl = freezed,
    Object? conditions = freezed,
    Object? targetUsers = null,
    Object? viewCount = null,
    Object? clickCount = null,
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
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as PromotionType,
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endDate: null == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
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
      conditions: freezed == conditions
          ? _value.conditions
          : conditions // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      targetUsers: null == targetUsers
          ? _value.targetUsers
          : targetUsers // ignore: cast_nullable_to_non_nullable
              as List<String>,
      viewCount: null == viewCount
          ? _value.viewCount
          : viewCount // ignore: cast_nullable_to_non_nullable
              as int,
      clickCount: null == clickCount
          ? _value.clickCount
          : clickCount // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PromotionImplCopyWith<$Res>
    implements $PromotionCopyWith<$Res> {
  factory _$$PromotionImplCopyWith(
          _$PromotionImpl value, $Res Function(_$PromotionImpl) then) =
      __$$PromotionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String storeId,
      String title,
      String description,
      PromotionType type,
      DateTime startDate,
      DateTime endDate,
      bool isActive,
      DateTime createdAt,
      DateTime updatedAt,
      String? imageUrl,
      Map<String, dynamic>? conditions,
      List<String> targetUsers,
      int viewCount,
      int clickCount});
}

/// @nodoc
class __$$PromotionImplCopyWithImpl<$Res>
    extends _$PromotionCopyWithImpl<$Res, _$PromotionImpl>
    implements _$$PromotionImplCopyWith<$Res> {
  __$$PromotionImplCopyWithImpl(
      _$PromotionImpl _value, $Res Function(_$PromotionImpl) _then)
      : super(_value, _then);

  /// Create a copy of Promotion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? storeId = null,
    Object? title = null,
    Object? description = null,
    Object? type = null,
    Object? startDate = null,
    Object? endDate = null,
    Object? isActive = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? imageUrl = freezed,
    Object? conditions = freezed,
    Object? targetUsers = null,
    Object? viewCount = null,
    Object? clickCount = null,
  }) {
    return _then(_$PromotionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      storeId: null == storeId
          ? _value.storeId
          : storeId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as PromotionType,
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endDate: null == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
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
      conditions: freezed == conditions
          ? _value._conditions
          : conditions // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      targetUsers: null == targetUsers
          ? _value._targetUsers
          : targetUsers // ignore: cast_nullable_to_non_nullable
              as List<String>,
      viewCount: null == viewCount
          ? _value.viewCount
          : viewCount // ignore: cast_nullable_to_non_nullable
              as int,
      clickCount: null == clickCount
          ? _value.clickCount
          : clickCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PromotionImpl implements _Promotion {
  const _$PromotionImpl(
      {required this.id,
      required this.storeId,
      required this.title,
      required this.description,
      required this.type,
      required this.startDate,
      required this.endDate,
      required this.isActive,
      required this.createdAt,
      required this.updatedAt,
      this.imageUrl,
      final Map<String, dynamic>? conditions,
      final List<String> targetUsers = const [],
      this.viewCount = 0,
      this.clickCount = 0})
      : _conditions = conditions,
        _targetUsers = targetUsers;

  factory _$PromotionImpl.fromJson(Map<String, dynamic> json) =>
      _$$PromotionImplFromJson(json);

  @override
  final String id;
  @override
  final String storeId;
  @override
  final String title;
  @override
  final String description;
  @override
  final PromotionType type;
  @override
  final DateTime startDate;
  @override
  final DateTime endDate;
  @override
  final bool isActive;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final String? imageUrl;
  final Map<String, dynamic>? _conditions;
  @override
  Map<String, dynamic>? get conditions {
    final value = _conditions;
    if (value == null) return null;
    if (_conditions is EqualUnmodifiableMapView) return _conditions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  final List<String> _targetUsers;
  @override
  @JsonKey()
  List<String> get targetUsers {
    if (_targetUsers is EqualUnmodifiableListView) return _targetUsers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_targetUsers);
  }

  @override
  @JsonKey()
  final int viewCount;
  @override
  @JsonKey()
  final int clickCount;

  @override
  String toString() {
    return 'Promotion(id: $id, storeId: $storeId, title: $title, description: $description, type: $type, startDate: $startDate, endDate: $endDate, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt, imageUrl: $imageUrl, conditions: $conditions, targetUsers: $targetUsers, viewCount: $viewCount, clickCount: $clickCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PromotionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.storeId, storeId) || other.storeId == storeId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            const DeepCollectionEquality()
                .equals(other._conditions, _conditions) &&
            const DeepCollectionEquality()
                .equals(other._targetUsers, _targetUsers) &&
            (identical(other.viewCount, viewCount) ||
                other.viewCount == viewCount) &&
            (identical(other.clickCount, clickCount) ||
                other.clickCount == clickCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      storeId,
      title,
      description,
      type,
      startDate,
      endDate,
      isActive,
      createdAt,
      updatedAt,
      imageUrl,
      const DeepCollectionEquality().hash(_conditions),
      const DeepCollectionEquality().hash(_targetUsers),
      viewCount,
      clickCount);

  /// Create a copy of Promotion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PromotionImplCopyWith<_$PromotionImpl> get copyWith =>
      __$$PromotionImplCopyWithImpl<_$PromotionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PromotionImplToJson(
      this,
    );
  }
}

abstract class _Promotion implements Promotion {
  const factory _Promotion(
      {required final String id,
      required final String storeId,
      required final String title,
      required final String description,
      required final PromotionType type,
      required final DateTime startDate,
      required final DateTime endDate,
      required final bool isActive,
      required final DateTime createdAt,
      required final DateTime updatedAt,
      final String? imageUrl,
      final Map<String, dynamic>? conditions,
      final List<String> targetUsers,
      final int viewCount,
      final int clickCount}) = _$PromotionImpl;

  factory _Promotion.fromJson(Map<String, dynamic> json) =
      _$PromotionImpl.fromJson;

  @override
  String get id;
  @override
  String get storeId;
  @override
  String get title;
  @override
  String get description;
  @override
  PromotionType get type;
  @override
  DateTime get startDate;
  @override
  DateTime get endDate;
  @override
  bool get isActive;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  String? get imageUrl;
  @override
  Map<String, dynamic>? get conditions;
  @override
  List<String> get targetUsers;
  @override
  int get viewCount;
  @override
  int get clickCount;

  /// Create a copy of Promotion
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PromotionImplCopyWith<_$PromotionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
