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
  int get points => throw _privateConstructorUsedError;
  PointTransactionType get type => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;
  String? get qrCodeId => throw _privateConstructorUsedError;
  String? get referenceId => throw _privateConstructorUsedError;
  bool get isProcessed => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

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
      int points,
      PointTransactionType type,
      String description,
      DateTime timestamp,
      String? qrCodeId,
      String? referenceId,
      bool isProcessed,
      String? notes});

  $PointTransactionTypeCopyWith<$Res> get type;
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
    Object? points = null,
    Object? type = null,
    Object? description = null,
    Object? timestamp = null,
    Object? qrCodeId = freezed,
    Object? referenceId = freezed,
    Object? isProcessed = null,
    Object? notes = freezed,
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
      points: null == points
          ? _value.points
          : points // ignore: cast_nullable_to_non_nullable
              as int,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as PointTransactionType,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      qrCodeId: freezed == qrCodeId
          ? _value.qrCodeId
          : qrCodeId // ignore: cast_nullable_to_non_nullable
              as String?,
      referenceId: freezed == referenceId
          ? _value.referenceId
          : referenceId // ignore: cast_nullable_to_non_nullable
              as String?,
      isProcessed: null == isProcessed
          ? _value.isProcessed
          : isProcessed // ignore: cast_nullable_to_non_nullable
              as bool,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of PointTransactionModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PointTransactionTypeCopyWith<$Res> get type {
    return $PointTransactionTypeCopyWith<$Res>(_value.type, (value) {
      return _then(_value.copyWith(type: value) as $Val);
    });
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
      int points,
      PointTransactionType type,
      String description,
      DateTime timestamp,
      String? qrCodeId,
      String? referenceId,
      bool isProcessed,
      String? notes});

  @override
  $PointTransactionTypeCopyWith<$Res> get type;
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
    Object? points = null,
    Object? type = null,
    Object? description = null,
    Object? timestamp = null,
    Object? qrCodeId = freezed,
    Object? referenceId = freezed,
    Object? isProcessed = null,
    Object? notes = freezed,
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
      points: null == points
          ? _value.points
          : points // ignore: cast_nullable_to_non_nullable
              as int,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as PointTransactionType,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      qrCodeId: freezed == qrCodeId
          ? _value.qrCodeId
          : qrCodeId // ignore: cast_nullable_to_non_nullable
              as String?,
      referenceId: freezed == referenceId
          ? _value.referenceId
          : referenceId // ignore: cast_nullable_to_non_nullable
              as String?,
      isProcessed: null == isProcessed
          ? _value.isProcessed
          : isProcessed // ignore: cast_nullable_to_non_nullable
              as bool,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
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
      required this.points,
      required this.type,
      required this.description,
      required this.timestamp,
      this.qrCodeId,
      this.referenceId,
      this.isProcessed = false,
      this.notes});

  factory _$PointTransactionModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PointTransactionModelImplFromJson(json);

  @override
  final String transactionId;
  @override
  final String userId;
  @override
  final String storeId;
  @override
  final int points;
  @override
  final PointTransactionType type;
  @override
  final String description;
  @override
  final DateTime timestamp;
  @override
  final String? qrCodeId;
  @override
  final String? referenceId;
  @override
  @JsonKey()
  final bool isProcessed;
  @override
  final String? notes;

  @override
  String toString() {
    return 'PointTransactionModel(transactionId: $transactionId, userId: $userId, storeId: $storeId, points: $points, type: $type, description: $description, timestamp: $timestamp, qrCodeId: $qrCodeId, referenceId: $referenceId, isProcessed: $isProcessed, notes: $notes)';
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
            (identical(other.points, points) || other.points == points) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.qrCodeId, qrCodeId) ||
                other.qrCodeId == qrCodeId) &&
            (identical(other.referenceId, referenceId) ||
                other.referenceId == referenceId) &&
            (identical(other.isProcessed, isProcessed) ||
                other.isProcessed == isProcessed) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      transactionId,
      userId,
      storeId,
      points,
      type,
      description,
      timestamp,
      qrCodeId,
      referenceId,
      isProcessed,
      notes);

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
      required final int points,
      required final PointTransactionType type,
      required final String description,
      required final DateTime timestamp,
      final String? qrCodeId,
      final String? referenceId,
      final bool isProcessed,
      final String? notes}) = _$PointTransactionModelImpl;

  factory _PointTransactionModel.fromJson(Map<String, dynamic> json) =
      _$PointTransactionModelImpl.fromJson;

  @override
  String get transactionId;
  @override
  String get userId;
  @override
  String get storeId;
  @override
  int get points;
  @override
  PointTransactionType get type;
  @override
  String get description;
  @override
  DateTime get timestamp;
  @override
  String? get qrCodeId;
  @override
  String? get referenceId;
  @override
  bool get isProcessed;
  @override
  String? get notes;

  /// Create a copy of PointTransactionModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PointTransactionModelImplCopyWith<_$PointTransactionModelImpl>
      get copyWith => throw _privateConstructorUsedError;
}

PointTransactionType _$PointTransactionTypeFromJson(Map<String, dynamic> json) {
  switch (json['runtimeType']) {
    case 'earned':
      return PointEarned.fromJson(json);
    case 'used':
      return PointUsed.fromJson(json);
    case 'expired':
      return PointExpired.fromJson(json);
    case 'refunded':
      return PointRefunded.fromJson(json);

    default:
      throw CheckedFromJsonException(
          json,
          'runtimeType',
          'PointTransactionType',
          'Invalid union type "${json['runtimeType']}"!');
  }
}

/// @nodoc
mixin _$PointTransactionType {
  String get reason => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String reason, double multiplier) earned,
    required TResult Function(String reason, int amountUsed) used,
    required TResult Function(String reason, int expiredAmount) expired,
    required TResult Function(String reason, int refundedAmount) refunded,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String reason, double multiplier)? earned,
    TResult? Function(String reason, int amountUsed)? used,
    TResult? Function(String reason, int expiredAmount)? expired,
    TResult? Function(String reason, int refundedAmount)? refunded,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String reason, double multiplier)? earned,
    TResult Function(String reason, int amountUsed)? used,
    TResult Function(String reason, int expiredAmount)? expired,
    TResult Function(String reason, int refundedAmount)? refunded,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PointEarned value) earned,
    required TResult Function(PointUsed value) used,
    required TResult Function(PointExpired value) expired,
    required TResult Function(PointRefunded value) refunded,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PointEarned value)? earned,
    TResult? Function(PointUsed value)? used,
    TResult? Function(PointExpired value)? expired,
    TResult? Function(PointRefunded value)? refunded,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PointEarned value)? earned,
    TResult Function(PointUsed value)? used,
    TResult Function(PointExpired value)? expired,
    TResult Function(PointRefunded value)? refunded,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this PointTransactionType to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PointTransactionType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PointTransactionTypeCopyWith<PointTransactionType> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PointTransactionTypeCopyWith<$Res> {
  factory $PointTransactionTypeCopyWith(PointTransactionType value,
          $Res Function(PointTransactionType) then) =
      _$PointTransactionTypeCopyWithImpl<$Res, PointTransactionType>;
  @useResult
  $Res call({String reason});
}

/// @nodoc
class _$PointTransactionTypeCopyWithImpl<$Res,
        $Val extends PointTransactionType>
    implements $PointTransactionTypeCopyWith<$Res> {
  _$PointTransactionTypeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PointTransactionType
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reason = null,
  }) {
    return _then(_value.copyWith(
      reason: null == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PointEarnedImplCopyWith<$Res>
    implements $PointTransactionTypeCopyWith<$Res> {
  factory _$$PointEarnedImplCopyWith(
          _$PointEarnedImpl value, $Res Function(_$PointEarnedImpl) then) =
      __$$PointEarnedImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String reason, double multiplier});
}

/// @nodoc
class __$$PointEarnedImplCopyWithImpl<$Res>
    extends _$PointTransactionTypeCopyWithImpl<$Res, _$PointEarnedImpl>
    implements _$$PointEarnedImplCopyWith<$Res> {
  __$$PointEarnedImplCopyWithImpl(
      _$PointEarnedImpl _value, $Res Function(_$PointEarnedImpl) _then)
      : super(_value, _then);

  /// Create a copy of PointTransactionType
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reason = null,
    Object? multiplier = null,
  }) {
    return _then(_$PointEarnedImpl(
      reason: null == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
      multiplier: null == multiplier
          ? _value.multiplier
          : multiplier // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PointEarnedImpl implements PointEarned {
  const _$PointEarnedImpl(
      {required this.reason, this.multiplier = 1.0, final String? $type})
      : $type = $type ?? 'earned';

  factory _$PointEarnedImpl.fromJson(Map<String, dynamic> json) =>
      _$$PointEarnedImplFromJson(json);

  @override
  final String reason;
  @override
  @JsonKey()
  final double multiplier;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'PointTransactionType.earned(reason: $reason, multiplier: $multiplier)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PointEarnedImpl &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.multiplier, multiplier) ||
                other.multiplier == multiplier));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, reason, multiplier);

  /// Create a copy of PointTransactionType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PointEarnedImplCopyWith<_$PointEarnedImpl> get copyWith =>
      __$$PointEarnedImplCopyWithImpl<_$PointEarnedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String reason, double multiplier) earned,
    required TResult Function(String reason, int amountUsed) used,
    required TResult Function(String reason, int expiredAmount) expired,
    required TResult Function(String reason, int refundedAmount) refunded,
  }) {
    return earned(reason, multiplier);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String reason, double multiplier)? earned,
    TResult? Function(String reason, int amountUsed)? used,
    TResult? Function(String reason, int expiredAmount)? expired,
    TResult? Function(String reason, int refundedAmount)? refunded,
  }) {
    return earned?.call(reason, multiplier);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String reason, double multiplier)? earned,
    TResult Function(String reason, int amountUsed)? used,
    TResult Function(String reason, int expiredAmount)? expired,
    TResult Function(String reason, int refundedAmount)? refunded,
    required TResult orElse(),
  }) {
    if (earned != null) {
      return earned(reason, multiplier);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PointEarned value) earned,
    required TResult Function(PointUsed value) used,
    required TResult Function(PointExpired value) expired,
    required TResult Function(PointRefunded value) refunded,
  }) {
    return earned(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PointEarned value)? earned,
    TResult? Function(PointUsed value)? used,
    TResult? Function(PointExpired value)? expired,
    TResult? Function(PointRefunded value)? refunded,
  }) {
    return earned?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PointEarned value)? earned,
    TResult Function(PointUsed value)? used,
    TResult Function(PointExpired value)? expired,
    TResult Function(PointRefunded value)? refunded,
    required TResult orElse(),
  }) {
    if (earned != null) {
      return earned(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PointEarnedImplToJson(
      this,
    );
  }
}

abstract class PointEarned implements PointTransactionType {
  const factory PointEarned(
      {required final String reason,
      final double multiplier}) = _$PointEarnedImpl;

  factory PointEarned.fromJson(Map<String, dynamic> json) =
      _$PointEarnedImpl.fromJson;

  @override
  String get reason;
  double get multiplier;

  /// Create a copy of PointTransactionType
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PointEarnedImplCopyWith<_$PointEarnedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PointUsedImplCopyWith<$Res>
    implements $PointTransactionTypeCopyWith<$Res> {
  factory _$$PointUsedImplCopyWith(
          _$PointUsedImpl value, $Res Function(_$PointUsedImpl) then) =
      __$$PointUsedImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String reason, int amountUsed});
}

/// @nodoc
class __$$PointUsedImplCopyWithImpl<$Res>
    extends _$PointTransactionTypeCopyWithImpl<$Res, _$PointUsedImpl>
    implements _$$PointUsedImplCopyWith<$Res> {
  __$$PointUsedImplCopyWithImpl(
      _$PointUsedImpl _value, $Res Function(_$PointUsedImpl) _then)
      : super(_value, _then);

  /// Create a copy of PointTransactionType
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reason = null,
    Object? amountUsed = null,
  }) {
    return _then(_$PointUsedImpl(
      reason: null == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
      amountUsed: null == amountUsed
          ? _value.amountUsed
          : amountUsed // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PointUsedImpl implements PointUsed {
  const _$PointUsedImpl(
      {required this.reason, required this.amountUsed, final String? $type})
      : $type = $type ?? 'used';

  factory _$PointUsedImpl.fromJson(Map<String, dynamic> json) =>
      _$$PointUsedImplFromJson(json);

  @override
  final String reason;
  @override
  final int amountUsed;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'PointTransactionType.used(reason: $reason, amountUsed: $amountUsed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PointUsedImpl &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.amountUsed, amountUsed) ||
                other.amountUsed == amountUsed));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, reason, amountUsed);

  /// Create a copy of PointTransactionType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PointUsedImplCopyWith<_$PointUsedImpl> get copyWith =>
      __$$PointUsedImplCopyWithImpl<_$PointUsedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String reason, double multiplier) earned,
    required TResult Function(String reason, int amountUsed) used,
    required TResult Function(String reason, int expiredAmount) expired,
    required TResult Function(String reason, int refundedAmount) refunded,
  }) {
    return used(reason, amountUsed);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String reason, double multiplier)? earned,
    TResult? Function(String reason, int amountUsed)? used,
    TResult? Function(String reason, int expiredAmount)? expired,
    TResult? Function(String reason, int refundedAmount)? refunded,
  }) {
    return used?.call(reason, amountUsed);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String reason, double multiplier)? earned,
    TResult Function(String reason, int amountUsed)? used,
    TResult Function(String reason, int expiredAmount)? expired,
    TResult Function(String reason, int refundedAmount)? refunded,
    required TResult orElse(),
  }) {
    if (used != null) {
      return used(reason, amountUsed);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PointEarned value) earned,
    required TResult Function(PointUsed value) used,
    required TResult Function(PointExpired value) expired,
    required TResult Function(PointRefunded value) refunded,
  }) {
    return used(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PointEarned value)? earned,
    TResult? Function(PointUsed value)? used,
    TResult? Function(PointExpired value)? expired,
    TResult? Function(PointRefunded value)? refunded,
  }) {
    return used?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PointEarned value)? earned,
    TResult Function(PointUsed value)? used,
    TResult Function(PointExpired value)? expired,
    TResult Function(PointRefunded value)? refunded,
    required TResult orElse(),
  }) {
    if (used != null) {
      return used(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PointUsedImplToJson(
      this,
    );
  }
}

abstract class PointUsed implements PointTransactionType {
  const factory PointUsed(
      {required final String reason,
      required final int amountUsed}) = _$PointUsedImpl;

  factory PointUsed.fromJson(Map<String, dynamic> json) =
      _$PointUsedImpl.fromJson;

  @override
  String get reason;
  int get amountUsed;

  /// Create a copy of PointTransactionType
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PointUsedImplCopyWith<_$PointUsedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PointExpiredImplCopyWith<$Res>
    implements $PointTransactionTypeCopyWith<$Res> {
  factory _$$PointExpiredImplCopyWith(
          _$PointExpiredImpl value, $Res Function(_$PointExpiredImpl) then) =
      __$$PointExpiredImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String reason, int expiredAmount});
}

/// @nodoc
class __$$PointExpiredImplCopyWithImpl<$Res>
    extends _$PointTransactionTypeCopyWithImpl<$Res, _$PointExpiredImpl>
    implements _$$PointExpiredImplCopyWith<$Res> {
  __$$PointExpiredImplCopyWithImpl(
      _$PointExpiredImpl _value, $Res Function(_$PointExpiredImpl) _then)
      : super(_value, _then);

  /// Create a copy of PointTransactionType
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reason = null,
    Object? expiredAmount = null,
  }) {
    return _then(_$PointExpiredImpl(
      reason: null == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
      expiredAmount: null == expiredAmount
          ? _value.expiredAmount
          : expiredAmount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PointExpiredImpl implements PointExpired {
  const _$PointExpiredImpl(
      {required this.reason, required this.expiredAmount, final String? $type})
      : $type = $type ?? 'expired';

  factory _$PointExpiredImpl.fromJson(Map<String, dynamic> json) =>
      _$$PointExpiredImplFromJson(json);

  @override
  final String reason;
  @override
  final int expiredAmount;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'PointTransactionType.expired(reason: $reason, expiredAmount: $expiredAmount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PointExpiredImpl &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.expiredAmount, expiredAmount) ||
                other.expiredAmount == expiredAmount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, reason, expiredAmount);

  /// Create a copy of PointTransactionType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PointExpiredImplCopyWith<_$PointExpiredImpl> get copyWith =>
      __$$PointExpiredImplCopyWithImpl<_$PointExpiredImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String reason, double multiplier) earned,
    required TResult Function(String reason, int amountUsed) used,
    required TResult Function(String reason, int expiredAmount) expired,
    required TResult Function(String reason, int refundedAmount) refunded,
  }) {
    return expired(reason, expiredAmount);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String reason, double multiplier)? earned,
    TResult? Function(String reason, int amountUsed)? used,
    TResult? Function(String reason, int expiredAmount)? expired,
    TResult? Function(String reason, int refundedAmount)? refunded,
  }) {
    return expired?.call(reason, expiredAmount);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String reason, double multiplier)? earned,
    TResult Function(String reason, int amountUsed)? used,
    TResult Function(String reason, int expiredAmount)? expired,
    TResult Function(String reason, int refundedAmount)? refunded,
    required TResult orElse(),
  }) {
    if (expired != null) {
      return expired(reason, expiredAmount);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PointEarned value) earned,
    required TResult Function(PointUsed value) used,
    required TResult Function(PointExpired value) expired,
    required TResult Function(PointRefunded value) refunded,
  }) {
    return expired(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PointEarned value)? earned,
    TResult? Function(PointUsed value)? used,
    TResult? Function(PointExpired value)? expired,
    TResult? Function(PointRefunded value)? refunded,
  }) {
    return expired?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PointEarned value)? earned,
    TResult Function(PointUsed value)? used,
    TResult Function(PointExpired value)? expired,
    TResult Function(PointRefunded value)? refunded,
    required TResult orElse(),
  }) {
    if (expired != null) {
      return expired(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PointExpiredImplToJson(
      this,
    );
  }
}

abstract class PointExpired implements PointTransactionType {
  const factory PointExpired(
      {required final String reason,
      required final int expiredAmount}) = _$PointExpiredImpl;

  factory PointExpired.fromJson(Map<String, dynamic> json) =
      _$PointExpiredImpl.fromJson;

  @override
  String get reason;
  int get expiredAmount;

  /// Create a copy of PointTransactionType
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PointExpiredImplCopyWith<_$PointExpiredImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PointRefundedImplCopyWith<$Res>
    implements $PointTransactionTypeCopyWith<$Res> {
  factory _$$PointRefundedImplCopyWith(
          _$PointRefundedImpl value, $Res Function(_$PointRefundedImpl) then) =
      __$$PointRefundedImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String reason, int refundedAmount});
}

/// @nodoc
class __$$PointRefundedImplCopyWithImpl<$Res>
    extends _$PointTransactionTypeCopyWithImpl<$Res, _$PointRefundedImpl>
    implements _$$PointRefundedImplCopyWith<$Res> {
  __$$PointRefundedImplCopyWithImpl(
      _$PointRefundedImpl _value, $Res Function(_$PointRefundedImpl) _then)
      : super(_value, _then);

  /// Create a copy of PointTransactionType
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reason = null,
    Object? refundedAmount = null,
  }) {
    return _then(_$PointRefundedImpl(
      reason: null == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
      refundedAmount: null == refundedAmount
          ? _value.refundedAmount
          : refundedAmount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PointRefundedImpl implements PointRefunded {
  const _$PointRefundedImpl(
      {required this.reason, required this.refundedAmount, final String? $type})
      : $type = $type ?? 'refunded';

  factory _$PointRefundedImpl.fromJson(Map<String, dynamic> json) =>
      _$$PointRefundedImplFromJson(json);

  @override
  final String reason;
  @override
  final int refundedAmount;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'PointTransactionType.refunded(reason: $reason, refundedAmount: $refundedAmount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PointRefundedImpl &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.refundedAmount, refundedAmount) ||
                other.refundedAmount == refundedAmount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, reason, refundedAmount);

  /// Create a copy of PointTransactionType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PointRefundedImplCopyWith<_$PointRefundedImpl> get copyWith =>
      __$$PointRefundedImplCopyWithImpl<_$PointRefundedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String reason, double multiplier) earned,
    required TResult Function(String reason, int amountUsed) used,
    required TResult Function(String reason, int expiredAmount) expired,
    required TResult Function(String reason, int refundedAmount) refunded,
  }) {
    return refunded(reason, refundedAmount);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String reason, double multiplier)? earned,
    TResult? Function(String reason, int amountUsed)? used,
    TResult? Function(String reason, int expiredAmount)? expired,
    TResult? Function(String reason, int refundedAmount)? refunded,
  }) {
    return refunded?.call(reason, refundedAmount);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String reason, double multiplier)? earned,
    TResult Function(String reason, int amountUsed)? used,
    TResult Function(String reason, int expiredAmount)? expired,
    TResult Function(String reason, int refundedAmount)? refunded,
    required TResult orElse(),
  }) {
    if (refunded != null) {
      return refunded(reason, refundedAmount);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PointEarned value) earned,
    required TResult Function(PointUsed value) used,
    required TResult Function(PointExpired value) expired,
    required TResult Function(PointRefunded value) refunded,
  }) {
    return refunded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PointEarned value)? earned,
    TResult? Function(PointUsed value)? used,
    TResult? Function(PointExpired value)? expired,
    TResult? Function(PointRefunded value)? refunded,
  }) {
    return refunded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PointEarned value)? earned,
    TResult Function(PointUsed value)? used,
    TResult Function(PointExpired value)? expired,
    TResult Function(PointRefunded value)? refunded,
    required TResult orElse(),
  }) {
    if (refunded != null) {
      return refunded(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PointRefundedImplToJson(
      this,
    );
  }
}

abstract class PointRefunded implements PointTransactionType {
  const factory PointRefunded(
      {required final String reason,
      required final int refundedAmount}) = _$PointRefundedImpl;

  factory PointRefunded.fromJson(Map<String, dynamic> json) =
      _$PointRefundedImpl.fromJson;

  @override
  String get reason;
  int get refundedAmount;

  /// Create a copy of PointTransactionType
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PointRefundedImplCopyWith<_$PointRefundedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserPointBalance _$UserPointBalanceFromJson(Map<String, dynamic> json) {
  return _UserPointBalance.fromJson(json);
}

/// @nodoc
mixin _$UserPointBalance {
  String get userId => throw _privateConstructorUsedError;
  int get totalPoints => throw _privateConstructorUsedError;
  int get availablePoints => throw _privateConstructorUsedError;
  int get usedPoints => throw _privateConstructorUsedError;
  int get expiredPoints => throw _privateConstructorUsedError;
  DateTime get lastUpdated => throw _privateConstructorUsedError;
  List<PointTransactionModel> get recentTransactions =>
      throw _privateConstructorUsedError;

  /// Serializes this UserPointBalance to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserPointBalance
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserPointBalanceCopyWith<UserPointBalance> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserPointBalanceCopyWith<$Res> {
  factory $UserPointBalanceCopyWith(
          UserPointBalance value, $Res Function(UserPointBalance) then) =
      _$UserPointBalanceCopyWithImpl<$Res, UserPointBalance>;
  @useResult
  $Res call(
      {String userId,
      int totalPoints,
      int availablePoints,
      int usedPoints,
      int expiredPoints,
      DateTime lastUpdated,
      List<PointTransactionModel> recentTransactions});
}

/// @nodoc
class _$UserPointBalanceCopyWithImpl<$Res, $Val extends UserPointBalance>
    implements $UserPointBalanceCopyWith<$Res> {
  _$UserPointBalanceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserPointBalance
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? totalPoints = null,
    Object? availablePoints = null,
    Object? usedPoints = null,
    Object? expiredPoints = null,
    Object? lastUpdated = null,
    Object? recentTransactions = null,
  }) {
    return _then(_value.copyWith(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      totalPoints: null == totalPoints
          ? _value.totalPoints
          : totalPoints // ignore: cast_nullable_to_non_nullable
              as int,
      availablePoints: null == availablePoints
          ? _value.availablePoints
          : availablePoints // ignore: cast_nullable_to_non_nullable
              as int,
      usedPoints: null == usedPoints
          ? _value.usedPoints
          : usedPoints // ignore: cast_nullable_to_non_nullable
              as int,
      expiredPoints: null == expiredPoints
          ? _value.expiredPoints
          : expiredPoints // ignore: cast_nullable_to_non_nullable
              as int,
      lastUpdated: null == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime,
      recentTransactions: null == recentTransactions
          ? _value.recentTransactions
          : recentTransactions // ignore: cast_nullable_to_non_nullable
              as List<PointTransactionModel>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserPointBalanceImplCopyWith<$Res>
    implements $UserPointBalanceCopyWith<$Res> {
  factory _$$UserPointBalanceImplCopyWith(_$UserPointBalanceImpl value,
          $Res Function(_$UserPointBalanceImpl) then) =
      __$$UserPointBalanceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String userId,
      int totalPoints,
      int availablePoints,
      int usedPoints,
      int expiredPoints,
      DateTime lastUpdated,
      List<PointTransactionModel> recentTransactions});
}

/// @nodoc
class __$$UserPointBalanceImplCopyWithImpl<$Res>
    extends _$UserPointBalanceCopyWithImpl<$Res, _$UserPointBalanceImpl>
    implements _$$UserPointBalanceImplCopyWith<$Res> {
  __$$UserPointBalanceImplCopyWithImpl(_$UserPointBalanceImpl _value,
      $Res Function(_$UserPointBalanceImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserPointBalance
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? totalPoints = null,
    Object? availablePoints = null,
    Object? usedPoints = null,
    Object? expiredPoints = null,
    Object? lastUpdated = null,
    Object? recentTransactions = null,
  }) {
    return _then(_$UserPointBalanceImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      totalPoints: null == totalPoints
          ? _value.totalPoints
          : totalPoints // ignore: cast_nullable_to_non_nullable
              as int,
      availablePoints: null == availablePoints
          ? _value.availablePoints
          : availablePoints // ignore: cast_nullable_to_non_nullable
              as int,
      usedPoints: null == usedPoints
          ? _value.usedPoints
          : usedPoints // ignore: cast_nullable_to_non_nullable
              as int,
      expiredPoints: null == expiredPoints
          ? _value.expiredPoints
          : expiredPoints // ignore: cast_nullable_to_non_nullable
              as int,
      lastUpdated: null == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime,
      recentTransactions: null == recentTransactions
          ? _value._recentTransactions
          : recentTransactions // ignore: cast_nullable_to_non_nullable
              as List<PointTransactionModel>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserPointBalanceImpl implements _UserPointBalance {
  const _$UserPointBalanceImpl(
      {required this.userId,
      required this.totalPoints,
      required this.availablePoints,
      required this.usedPoints,
      required this.expiredPoints,
      required this.lastUpdated,
      final List<PointTransactionModel> recentTransactions = const []})
      : _recentTransactions = recentTransactions;

  factory _$UserPointBalanceImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserPointBalanceImplFromJson(json);

  @override
  final String userId;
  @override
  final int totalPoints;
  @override
  final int availablePoints;
  @override
  final int usedPoints;
  @override
  final int expiredPoints;
  @override
  final DateTime lastUpdated;
  final List<PointTransactionModel> _recentTransactions;
  @override
  @JsonKey()
  List<PointTransactionModel> get recentTransactions {
    if (_recentTransactions is EqualUnmodifiableListView)
      return _recentTransactions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recentTransactions);
  }

  @override
  String toString() {
    return 'UserPointBalance(userId: $userId, totalPoints: $totalPoints, availablePoints: $availablePoints, usedPoints: $usedPoints, expiredPoints: $expiredPoints, lastUpdated: $lastUpdated, recentTransactions: $recentTransactions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserPointBalanceImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.totalPoints, totalPoints) ||
                other.totalPoints == totalPoints) &&
            (identical(other.availablePoints, availablePoints) ||
                other.availablePoints == availablePoints) &&
            (identical(other.usedPoints, usedPoints) ||
                other.usedPoints == usedPoints) &&
            (identical(other.expiredPoints, expiredPoints) ||
                other.expiredPoints == expiredPoints) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated) &&
            const DeepCollectionEquality()
                .equals(other._recentTransactions, _recentTransactions));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      userId,
      totalPoints,
      availablePoints,
      usedPoints,
      expiredPoints,
      lastUpdated,
      const DeepCollectionEquality().hash(_recentTransactions));

  /// Create a copy of UserPointBalance
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserPointBalanceImplCopyWith<_$UserPointBalanceImpl> get copyWith =>
      __$$UserPointBalanceImplCopyWithImpl<_$UserPointBalanceImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserPointBalanceImplToJson(
      this,
    );
  }
}

abstract class _UserPointBalance implements UserPointBalance {
  const factory _UserPointBalance(
          {required final String userId,
          required final int totalPoints,
          required final int availablePoints,
          required final int usedPoints,
          required final int expiredPoints,
          required final DateTime lastUpdated,
          final List<PointTransactionModel> recentTransactions}) =
      _$UserPointBalanceImpl;

  factory _UserPointBalance.fromJson(Map<String, dynamic> json) =
      _$UserPointBalanceImpl.fromJson;

  @override
  String get userId;
  @override
  int get totalPoints;
  @override
  int get availablePoints;
  @override
  int get usedPoints;
  @override
  int get expiredPoints;
  @override
  DateTime get lastUpdated;
  @override
  List<PointTransactionModel> get recentTransactions;

  /// Create a copy of UserPointBalance
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserPointBalanceImplCopyWith<_$UserPointBalanceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

QRCodeModel _$QRCodeModelFromJson(Map<String, dynamic> json) {
  return _QRCodeModel.fromJson(json);
}

/// @nodoc
mixin _$QRCodeModel {
  String get qrCodeId => throw _privateConstructorUsedError;
  String get storeId => throw _privateConstructorUsedError;
  int get points => throw _privateConstructorUsedError;
  DateTime get expiresAt => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  String get createdBy => throw _privateConstructorUsedError;
  bool get isUsed => throw _privateConstructorUsedError;
  String? get usedBy => throw _privateConstructorUsedError;
  DateTime? get usedAt => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;

  /// Serializes this QRCodeModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of QRCodeModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QRCodeModelCopyWith<QRCodeModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QRCodeModelCopyWith<$Res> {
  factory $QRCodeModelCopyWith(
          QRCodeModel value, $Res Function(QRCodeModel) then) =
      _$QRCodeModelCopyWithImpl<$Res, QRCodeModel>;
  @useResult
  $Res call(
      {String qrCodeId,
      String storeId,
      int points,
      DateTime expiresAt,
      DateTime createdAt,
      String createdBy,
      bool isUsed,
      String? usedBy,
      DateTime? usedAt,
      String? description});
}

/// @nodoc
class _$QRCodeModelCopyWithImpl<$Res, $Val extends QRCodeModel>
    implements $QRCodeModelCopyWith<$Res> {
  _$QRCodeModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QRCodeModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? qrCodeId = null,
    Object? storeId = null,
    Object? points = null,
    Object? expiresAt = null,
    Object? createdAt = null,
    Object? createdBy = null,
    Object? isUsed = null,
    Object? usedBy = freezed,
    Object? usedAt = freezed,
    Object? description = freezed,
  }) {
    return _then(_value.copyWith(
      qrCodeId: null == qrCodeId
          ? _value.qrCodeId
          : qrCodeId // ignore: cast_nullable_to_non_nullable
              as String,
      storeId: null == storeId
          ? _value.storeId
          : storeId // ignore: cast_nullable_to_non_nullable
              as String,
      points: null == points
          ? _value.points
          : points // ignore: cast_nullable_to_non_nullable
              as int,
      expiresAt: null == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
      isUsed: null == isUsed
          ? _value.isUsed
          : isUsed // ignore: cast_nullable_to_non_nullable
              as bool,
      usedBy: freezed == usedBy
          ? _value.usedBy
          : usedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      usedAt: freezed == usedAt
          ? _value.usedAt
          : usedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$QRCodeModelImplCopyWith<$Res>
    implements $QRCodeModelCopyWith<$Res> {
  factory _$$QRCodeModelImplCopyWith(
          _$QRCodeModelImpl value, $Res Function(_$QRCodeModelImpl) then) =
      __$$QRCodeModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String qrCodeId,
      String storeId,
      int points,
      DateTime expiresAt,
      DateTime createdAt,
      String createdBy,
      bool isUsed,
      String? usedBy,
      DateTime? usedAt,
      String? description});
}

/// @nodoc
class __$$QRCodeModelImplCopyWithImpl<$Res>
    extends _$QRCodeModelCopyWithImpl<$Res, _$QRCodeModelImpl>
    implements _$$QRCodeModelImplCopyWith<$Res> {
  __$$QRCodeModelImplCopyWithImpl(
      _$QRCodeModelImpl _value, $Res Function(_$QRCodeModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of QRCodeModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? qrCodeId = null,
    Object? storeId = null,
    Object? points = null,
    Object? expiresAt = null,
    Object? createdAt = null,
    Object? createdBy = null,
    Object? isUsed = null,
    Object? usedBy = freezed,
    Object? usedAt = freezed,
    Object? description = freezed,
  }) {
    return _then(_$QRCodeModelImpl(
      qrCodeId: null == qrCodeId
          ? _value.qrCodeId
          : qrCodeId // ignore: cast_nullable_to_non_nullable
              as String,
      storeId: null == storeId
          ? _value.storeId
          : storeId // ignore: cast_nullable_to_non_nullable
              as String,
      points: null == points
          ? _value.points
          : points // ignore: cast_nullable_to_non_nullable
              as int,
      expiresAt: null == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
      isUsed: null == isUsed
          ? _value.isUsed
          : isUsed // ignore: cast_nullable_to_non_nullable
              as bool,
      usedBy: freezed == usedBy
          ? _value.usedBy
          : usedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      usedAt: freezed == usedAt
          ? _value.usedAt
          : usedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$QRCodeModelImpl implements _QRCodeModel {
  const _$QRCodeModelImpl(
      {required this.qrCodeId,
      required this.storeId,
      required this.points,
      required this.expiresAt,
      required this.createdAt,
      required this.createdBy,
      this.isUsed = false,
      this.usedBy,
      this.usedAt,
      this.description});

  factory _$QRCodeModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$QRCodeModelImplFromJson(json);

  @override
  final String qrCodeId;
  @override
  final String storeId;
  @override
  final int points;
  @override
  final DateTime expiresAt;
  @override
  final DateTime createdAt;
  @override
  final String createdBy;
  @override
  @JsonKey()
  final bool isUsed;
  @override
  final String? usedBy;
  @override
  final DateTime? usedAt;
  @override
  final String? description;

  @override
  String toString() {
    return 'QRCodeModel(qrCodeId: $qrCodeId, storeId: $storeId, points: $points, expiresAt: $expiresAt, createdAt: $createdAt, createdBy: $createdBy, isUsed: $isUsed, usedBy: $usedBy, usedAt: $usedAt, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QRCodeModelImpl &&
            (identical(other.qrCodeId, qrCodeId) ||
                other.qrCodeId == qrCodeId) &&
            (identical(other.storeId, storeId) || other.storeId == storeId) &&
            (identical(other.points, points) || other.points == points) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.isUsed, isUsed) || other.isUsed == isUsed) &&
            (identical(other.usedBy, usedBy) || other.usedBy == usedBy) &&
            (identical(other.usedAt, usedAt) || other.usedAt == usedAt) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, qrCodeId, storeId, points,
      expiresAt, createdAt, createdBy, isUsed, usedBy, usedAt, description);

  /// Create a copy of QRCodeModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QRCodeModelImplCopyWith<_$QRCodeModelImpl> get copyWith =>
      __$$QRCodeModelImplCopyWithImpl<_$QRCodeModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QRCodeModelImplToJson(
      this,
    );
  }
}

abstract class _QRCodeModel implements QRCodeModel {
  const factory _QRCodeModel(
      {required final String qrCodeId,
      required final String storeId,
      required final int points,
      required final DateTime expiresAt,
      required final DateTime createdAt,
      required final String createdBy,
      final bool isUsed,
      final String? usedBy,
      final DateTime? usedAt,
      final String? description}) = _$QRCodeModelImpl;

  factory _QRCodeModel.fromJson(Map<String, dynamic> json) =
      _$QRCodeModelImpl.fromJson;

  @override
  String get qrCodeId;
  @override
  String get storeId;
  @override
  int get points;
  @override
  DateTime get expiresAt;
  @override
  DateTime get createdAt;
  @override
  String get createdBy;
  @override
  bool get isUsed;
  @override
  String? get usedBy;
  @override
  DateTime? get usedAt;
  @override
  String? get description;

  /// Create a copy of QRCodeModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QRCodeModelImplCopyWith<_$QRCodeModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
