// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'point_transaction_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PointTransactionModel _$PointTransactionModelFromJson(
    Map<String, dynamic> json) {
  return _PointTransactionModel.fromJson(json);
}

/// @nodoc
mixin _$PointTransactionModel {
  String get transactionId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get storeId => throw _privateConstructorUsedError;
  String get storeName => throw _privateConstructorUsedError;
  int get amount => throw _privateConstructorUsedError;
  int? get paymentAmount => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String get paymentMethod => throw _privateConstructorUsedError;
  @TimestampDateTimeConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @TimestampDateTimeConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get qrCode => throw _privateConstructorUsedError;
  int? get usedNormalPoints => throw _privateConstructorUsedError;
  int? get usedSpecialPoints => throw _privateConstructorUsedError;
  int? get totalUsedPoints => throw _privateConstructorUsedError;
  @TimestampNullableDateTimeConverter()
  DateTime? get refundedAt => throw _privateConstructorUsedError;
  String? get refundReason => throw _privateConstructorUsedError;

  /// Serializes this PointTransactionModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PointTransactionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PointTransactionModelCopyWith<PointTransactionModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PointTransactionModelCopyWith<$Res> {
  factory $PointTransactionModelCopyWith(PointTransactionModel value,
          $Res Function(PointTransactionModel) then) =
      _$PointTransactionModelCopyWithImpl<$Res, PointTransactionModel>;
  @useResult
  $Res call(
      {String transactionId,
      String userId,
      String storeId,
      String storeName,
      int amount,
      int? paymentAmount,
      String status,
      String paymentMethod,
      @TimestampDateTimeConverter() DateTime createdAt,
      @TimestampDateTimeConverter() DateTime updatedAt,
      String? description,
      String? qrCode,
      int? usedNormalPoints,
      int? usedSpecialPoints,
      int? totalUsedPoints,
      @TimestampNullableDateTimeConverter() DateTime? refundedAt,
      String? refundReason});
}

/// @nodoc
class _$PointTransactionModelCopyWithImpl<$Res,
        $Val extends PointTransactionModel>
    implements $PointTransactionModelCopyWith<$Res> {
  _$PointTransactionModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PointTransactionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? transactionId = null,
    Object? userId = null,
    Object? storeId = null,
    Object? storeName = null,
    Object? amount = null,
    Object? paymentAmount = freezed,
    Object? status = null,
    Object? paymentMethod = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? description = freezed,
    Object? qrCode = freezed,
    Object? usedNormalPoints = freezed,
    Object? usedSpecialPoints = freezed,
    Object? totalUsedPoints = freezed,
    Object? refundedAt = freezed,
    Object? refundReason = freezed,
  }) {
    return _then(_value.copyWith(
      transactionId: null == transactionId
          ? _value.transactionId
          : transactionId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      storeId: null == storeId
          ? _value.storeId
          : storeId // ignore: cast_nullable_to_non_nullable
              as String,
      storeName: null == storeName
          ? _value.storeName
          : storeName // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as int,
      paymentAmount: freezed == paymentAmount
          ? _value.paymentAmount
          : paymentAmount // ignore: cast_nullable_to_non_nullable
              as int?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      paymentMethod: null == paymentMethod
          ? _value.paymentMethod
          : paymentMethod // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      qrCode: freezed == qrCode
          ? _value.qrCode
          : qrCode // ignore: cast_nullable_to_non_nullable
              as String?,
      usedNormalPoints: freezed == usedNormalPoints
          ? _value.usedNormalPoints
          : usedNormalPoints // ignore: cast_nullable_to_non_nullable
              as int?,
      usedSpecialPoints: freezed == usedSpecialPoints
          ? _value.usedSpecialPoints
          : usedSpecialPoints // ignore: cast_nullable_to_non_nullable
              as int?,
      totalUsedPoints: freezed == totalUsedPoints
          ? _value.totalUsedPoints
          : totalUsedPoints // ignore: cast_nullable_to_non_nullable
              as int?,
      refundedAt: freezed == refundedAt
          ? _value.refundedAt
          : refundedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      refundReason: freezed == refundReason
          ? _value.refundReason
          : refundReason // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PointTransactionModelImplCopyWith<$Res>
    implements $PointTransactionModelCopyWith<$Res> {
  factory _$$PointTransactionModelImplCopyWith(
          _$PointTransactionModelImpl value,
          $Res Function(_$PointTransactionModelImpl) then) =
      __$$PointTransactionModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String transactionId,
      String userId,
      String storeId,
      String storeName,
      int amount,
      int? paymentAmount,
      String status,
      String paymentMethod,
      @TimestampDateTimeConverter() DateTime createdAt,
      @TimestampDateTimeConverter() DateTime updatedAt,
      String? description,
      String? qrCode,
      int? usedNormalPoints,
      int? usedSpecialPoints,
      int? totalUsedPoints,
      @TimestampNullableDateTimeConverter() DateTime? refundedAt,
      String? refundReason});
}

/// @nodoc
class __$$PointTransactionModelImplCopyWithImpl<$Res>
    extends _$PointTransactionModelCopyWithImpl<$Res,
        _$PointTransactionModelImpl>
    implements _$$PointTransactionModelImplCopyWith<$Res> {
  __$$PointTransactionModelImplCopyWithImpl(_$PointTransactionModelImpl _value,
      $Res Function(_$PointTransactionModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of PointTransactionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? transactionId = null,
    Object? userId = null,
    Object? storeId = null,
    Object? storeName = null,
    Object? amount = null,
    Object? paymentAmount = freezed,
    Object? status = null,
    Object? paymentMethod = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? description = freezed,
    Object? qrCode = freezed,
    Object? usedNormalPoints = freezed,
    Object? usedSpecialPoints = freezed,
    Object? totalUsedPoints = freezed,
    Object? refundedAt = freezed,
    Object? refundReason = freezed,
  }) {
    return _then(_$PointTransactionModelImpl(
      transactionId: null == transactionId
          ? _value.transactionId
          : transactionId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      storeId: null == storeId
          ? _value.storeId
          : storeId // ignore: cast_nullable_to_non_nullable
              as String,
      storeName: null == storeName
          ? _value.storeName
          : storeName // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as int,
      paymentAmount: freezed == paymentAmount
          ? _value.paymentAmount
          : paymentAmount // ignore: cast_nullable_to_non_nullable
              as int?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      paymentMethod: null == paymentMethod
          ? _value.paymentMethod
          : paymentMethod // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      qrCode: freezed == qrCode
          ? _value.qrCode
          : qrCode // ignore: cast_nullable_to_non_nullable
              as String?,
      usedNormalPoints: freezed == usedNormalPoints
          ? _value.usedNormalPoints
          : usedNormalPoints // ignore: cast_nullable_to_non_nullable
              as int?,
      usedSpecialPoints: freezed == usedSpecialPoints
          ? _value.usedSpecialPoints
          : usedSpecialPoints // ignore: cast_nullable_to_non_nullable
              as int?,
      totalUsedPoints: freezed == totalUsedPoints
          ? _value.totalUsedPoints
          : totalUsedPoints // ignore: cast_nullable_to_non_nullable
              as int?,
      refundedAt: freezed == refundedAt
          ? _value.refundedAt
          : refundedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      refundReason: freezed == refundReason
          ? _value.refundReason
          : refundReason // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PointTransactionModelImpl implements _PointTransactionModel {
  const _$PointTransactionModelImpl(
      {required this.transactionId,
      required this.userId,
      required this.storeId,
      required this.storeName,
      required this.amount,
      this.paymentAmount,
      this.status = 'completed',
      this.paymentMethod = 'points',
      @TimestampDateTimeConverter() required this.createdAt,
      @TimestampDateTimeConverter() required this.updatedAt,
      this.description,
      this.qrCode,
      this.usedNormalPoints,
      this.usedSpecialPoints,
      this.totalUsedPoints,
      @TimestampNullableDateTimeConverter() this.refundedAt,
      this.refundReason});

  factory _$PointTransactionModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PointTransactionModelImplFromJson(json);

  @override
  final String transactionId;
  @override
  final String userId;
  @override
  final String storeId;
  @override
  final String storeName;
  @override
  final int amount;
  @override
  final int? paymentAmount;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey()
  final String paymentMethod;
  @override
  @TimestampDateTimeConverter()
  final DateTime createdAt;
  @override
  @TimestampDateTimeConverter()
  final DateTime updatedAt;
  @override
  final String? description;
  @override
  final String? qrCode;
  @override
  final int? usedNormalPoints;
  @override
  final int? usedSpecialPoints;
  @override
  final int? totalUsedPoints;
  @override
  @TimestampNullableDateTimeConverter()
  final DateTime? refundedAt;
  @override
  final String? refundReason;

  @override
  String toString() {
    return 'PointTransactionModel(transactionId: $transactionId, userId: $userId, storeId: $storeId, storeName: $storeName, amount: $amount, paymentAmount: $paymentAmount, status: $status, paymentMethod: $paymentMethod, createdAt: $createdAt, updatedAt: $updatedAt, description: $description, qrCode: $qrCode, usedNormalPoints: $usedNormalPoints, usedSpecialPoints: $usedSpecialPoints, totalUsedPoints: $totalUsedPoints, refundedAt: $refundedAt, refundReason: $refundReason)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PointTransactionModelImpl &&
            (identical(other.transactionId, transactionId) ||
                other.transactionId == transactionId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.storeId, storeId) || other.storeId == storeId) &&
            (identical(other.storeName, storeName) ||
                other.storeName == storeName) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.paymentAmount, paymentAmount) ||
                other.paymentAmount == paymentAmount) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.paymentMethod, paymentMethod) ||
                other.paymentMethod == paymentMethod) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.qrCode, qrCode) || other.qrCode == qrCode) &&
            (identical(other.usedNormalPoints, usedNormalPoints) ||
                other.usedNormalPoints == usedNormalPoints) &&
            (identical(other.usedSpecialPoints, usedSpecialPoints) ||
                other.usedSpecialPoints == usedSpecialPoints) &&
            (identical(other.totalUsedPoints, totalUsedPoints) ||
                other.totalUsedPoints == totalUsedPoints) &&
            (identical(other.refundedAt, refundedAt) ||
                other.refundedAt == refundedAt) &&
            (identical(other.refundReason, refundReason) ||
                other.refundReason == refundReason));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      transactionId,
      userId,
      storeId,
      storeName,
      amount,
      paymentAmount,
      status,
      paymentMethod,
      createdAt,
      updatedAt,
      description,
      qrCode,
      usedNormalPoints,
      usedSpecialPoints,
      totalUsedPoints,
      refundedAt,
      refundReason);

  /// Create a copy of PointTransactionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PointTransactionModelImplCopyWith<_$PointTransactionModelImpl>
      get copyWith => __$$PointTransactionModelImplCopyWithImpl<
          _$PointTransactionModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PointTransactionModelImplToJson(
      this,
    );
  }
}

abstract class _PointTransactionModel implements PointTransactionModel {
  const factory _PointTransactionModel(
      {required final String transactionId,
      required final String userId,
      required final String storeId,
      required final String storeName,
      required final int amount,
      final int? paymentAmount,
      final String status,
      final String paymentMethod,
      @TimestampDateTimeConverter() required final DateTime createdAt,
      @TimestampDateTimeConverter() required final DateTime updatedAt,
      final String? description,
      final String? qrCode,
      final int? usedNormalPoints,
      final int? usedSpecialPoints,
      final int? totalUsedPoints,
      @TimestampNullableDateTimeConverter() final DateTime? refundedAt,
      final String? refundReason}) = _$PointTransactionModelImpl;

  factory _PointTransactionModel.fromJson(Map<String, dynamic> json) =
      _$PointTransactionModelImpl.fromJson;

  @override
  String get transactionId;
  @override
  String get userId;
  @override
  String get storeId;
  @override
  String get storeName;
  @override
  int get amount;
  @override
  int? get paymentAmount;
  @override
  String get status;
  @override
  String get paymentMethod;
  @override
  @TimestampDateTimeConverter()
  DateTime get createdAt;
  @override
  @TimestampDateTimeConverter()
  DateTime get updatedAt;
  @override
  String? get description;
  @override
  String? get qrCode;
  @override
  int? get usedNormalPoints;
  @override
  int? get usedSpecialPoints;
  @override
  int? get totalUsedPoints;
  @override
  @TimestampNullableDateTimeConverter()
  DateTime? get refundedAt;
  @override
  String? get refundReason;

  /// Create a copy of PointTransactionModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PointTransactionModelImplCopyWith<_$PointTransactionModelImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$PointTransactionStatus {
  String get completed => throw _privateConstructorUsedError;
  String get pending => throw _privateConstructorUsedError;
  String get cancelled => throw _privateConstructorUsedError;
  String get refunded => throw _privateConstructorUsedError;

  /// Create a copy of PointTransactionStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PointTransactionStatusCopyWith<PointTransactionStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PointTransactionStatusCopyWith<$Res> {
  factory $PointTransactionStatusCopyWith(PointTransactionStatus value,
          $Res Function(PointTransactionStatus) then) =
      _$PointTransactionStatusCopyWithImpl<$Res, PointTransactionStatus>;
  @useResult
  $Res call(
      {String completed, String pending, String cancelled, String refunded});
}

/// @nodoc
class _$PointTransactionStatusCopyWithImpl<$Res,
        $Val extends PointTransactionStatus>
    implements $PointTransactionStatusCopyWith<$Res> {
  _$PointTransactionStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PointTransactionStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? completed = null,
    Object? pending = null,
    Object? cancelled = null,
    Object? refunded = null,
  }) {
    return _then(_value.copyWith(
      completed: null == completed
          ? _value.completed
          : completed // ignore: cast_nullable_to_non_nullable
              as String,
      pending: null == pending
          ? _value.pending
          : pending // ignore: cast_nullable_to_non_nullable
              as String,
      cancelled: null == cancelled
          ? _value.cancelled
          : cancelled // ignore: cast_nullable_to_non_nullable
              as String,
      refunded: null == refunded
          ? _value.refunded
          : refunded // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PointTransactionStatusImplCopyWith<$Res>
    implements $PointTransactionStatusCopyWith<$Res> {
  factory _$$PointTransactionStatusImplCopyWith(
          _$PointTransactionStatusImpl value,
          $Res Function(_$PointTransactionStatusImpl) then) =
      __$$PointTransactionStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String completed, String pending, String cancelled, String refunded});
}

/// @nodoc
class __$$PointTransactionStatusImplCopyWithImpl<$Res>
    extends _$PointTransactionStatusCopyWithImpl<$Res,
        _$PointTransactionStatusImpl>
    implements _$$PointTransactionStatusImplCopyWith<$Res> {
  __$$PointTransactionStatusImplCopyWithImpl(
      _$PointTransactionStatusImpl _value,
      $Res Function(_$PointTransactionStatusImpl) _then)
      : super(_value, _then);

  /// Create a copy of PointTransactionStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? completed = null,
    Object? pending = null,
    Object? cancelled = null,
    Object? refunded = null,
  }) {
    return _then(_$PointTransactionStatusImpl(
      completed: null == completed
          ? _value.completed
          : completed // ignore: cast_nullable_to_non_nullable
              as String,
      pending: null == pending
          ? _value.pending
          : pending // ignore: cast_nullable_to_non_nullable
              as String,
      cancelled: null == cancelled
          ? _value.cancelled
          : cancelled // ignore: cast_nullable_to_non_nullable
              as String,
      refunded: null == refunded
          ? _value.refunded
          : refunded // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$PointTransactionStatusImpl implements _PointTransactionStatus {
  const _$PointTransactionStatusImpl(
      {this.completed = 'completed',
      this.pending = 'pending',
      this.cancelled = 'cancelled',
      this.refunded = 'refunded'});

  @override
  @JsonKey()
  final String completed;
  @override
  @JsonKey()
  final String pending;
  @override
  @JsonKey()
  final String cancelled;
  @override
  @JsonKey()
  final String refunded;

  @override
  String toString() {
    return 'PointTransactionStatus(completed: $completed, pending: $pending, cancelled: $cancelled, refunded: $refunded)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PointTransactionStatusImpl &&
            (identical(other.completed, completed) ||
                other.completed == completed) &&
            (identical(other.pending, pending) || other.pending == pending) &&
            (identical(other.cancelled, cancelled) ||
                other.cancelled == cancelled) &&
            (identical(other.refunded, refunded) ||
                other.refunded == refunded));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, completed, pending, cancelled, refunded);

  /// Create a copy of PointTransactionStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PointTransactionStatusImplCopyWith<_$PointTransactionStatusImpl>
      get copyWith => __$$PointTransactionStatusImplCopyWithImpl<
          _$PointTransactionStatusImpl>(this, _$identity);
}

abstract class _PointTransactionStatus implements PointTransactionStatus {
  const factory _PointTransactionStatus(
      {final String completed,
      final String pending,
      final String cancelled,
      final String refunded}) = _$PointTransactionStatusImpl;

  @override
  String get completed;
  @override
  String get pending;
  @override
  String get cancelled;
  @override
  String get refunded;

  /// Create a copy of PointTransactionStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PointTransactionStatusImplCopyWith<_$PointTransactionStatusImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$PaymentMethod {
  String get points => throw _privateConstructorUsedError;
  String get cash => throw _privateConstructorUsedError;
  String get card => throw _privateConstructorUsedError;

  /// Create a copy of PaymentMethod
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PaymentMethodCopyWith<PaymentMethod> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaymentMethodCopyWith<$Res> {
  factory $PaymentMethodCopyWith(
          PaymentMethod value, $Res Function(PaymentMethod) then) =
      _$PaymentMethodCopyWithImpl<$Res, PaymentMethod>;
  @useResult
  $Res call({String points, String cash, String card});
}

/// @nodoc
class _$PaymentMethodCopyWithImpl<$Res, $Val extends PaymentMethod>
    implements $PaymentMethodCopyWith<$Res> {
  _$PaymentMethodCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PaymentMethod
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? points = null,
    Object? cash = null,
    Object? card = null,
  }) {
    return _then(_value.copyWith(
      points: null == points
          ? _value.points
          : points // ignore: cast_nullable_to_non_nullable
              as String,
      cash: null == cash
          ? _value.cash
          : cash // ignore: cast_nullable_to_non_nullable
              as String,
      card: null == card
          ? _value.card
          : card // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PaymentMethodImplCopyWith<$Res>
    implements $PaymentMethodCopyWith<$Res> {
  factory _$$PaymentMethodImplCopyWith(
          _$PaymentMethodImpl value, $Res Function(_$PaymentMethodImpl) then) =
      __$$PaymentMethodImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String points, String cash, String card});
}

/// @nodoc
class __$$PaymentMethodImplCopyWithImpl<$Res>
    extends _$PaymentMethodCopyWithImpl<$Res, _$PaymentMethodImpl>
    implements _$$PaymentMethodImplCopyWith<$Res> {
  __$$PaymentMethodImplCopyWithImpl(
      _$PaymentMethodImpl _value, $Res Function(_$PaymentMethodImpl) _then)
      : super(_value, _then);

  /// Create a copy of PaymentMethod
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? points = null,
    Object? cash = null,
    Object? card = null,
  }) {
    return _then(_$PaymentMethodImpl(
      points: null == points
          ? _value.points
          : points // ignore: cast_nullable_to_non_nullable
              as String,
      cash: null == cash
          ? _value.cash
          : cash // ignore: cast_nullable_to_non_nullable
              as String,
      card: null == card
          ? _value.card
          : card // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$PaymentMethodImpl implements _PaymentMethod {
  const _$PaymentMethodImpl(
      {this.points = 'points', this.cash = 'cash', this.card = 'card'});

  @override
  @JsonKey()
  final String points;
  @override
  @JsonKey()
  final String cash;
  @override
  @JsonKey()
  final String card;

  @override
  String toString() {
    return 'PaymentMethod(points: $points, cash: $cash, card: $card)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaymentMethodImpl &&
            (identical(other.points, points) || other.points == points) &&
            (identical(other.cash, cash) || other.cash == cash) &&
            (identical(other.card, card) || other.card == card));
  }

  @override
  int get hashCode => Object.hash(runtimeType, points, cash, card);

  /// Create a copy of PaymentMethod
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PaymentMethodImplCopyWith<_$PaymentMethodImpl> get copyWith =>
      __$$PaymentMethodImplCopyWithImpl<_$PaymentMethodImpl>(this, _$identity);
}

abstract class _PaymentMethod implements PaymentMethod {
  const factory _PaymentMethod(
      {final String points,
      final String cash,
      final String card}) = _$PaymentMethodImpl;

  @override
  String get points;
  @override
  String get cash;
  @override
  String get card;

  /// Create a copy of PaymentMethod
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PaymentMethodImplCopyWith<_$PaymentMethodImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
