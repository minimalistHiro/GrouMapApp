// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_point_balance_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserPointBalance _$UserPointBalanceFromJson(Map<String, dynamic> json) {
  return _UserPointBalance.fromJson(json);
}

/// @nodoc
mixin _$UserPointBalance {
  String get userId => throw _privateConstructorUsedError;
  int get totalPoints => throw _privateConstructorUsedError;
  int get availablePoints => throw _privateConstructorUsedError;
  int get usedPoints => throw _privateConstructorUsedError;
  DateTime get lastUpdated => throw _privateConstructorUsedError;

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
      DateTime lastUpdated});
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
    Object? lastUpdated = null,
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
      lastUpdated: null == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime,
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
      DateTime lastUpdated});
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
    Object? lastUpdated = null,
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
      lastUpdated: null == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime,
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
      required this.lastUpdated});

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
  final DateTime lastUpdated;

  @override
  String toString() {
    return 'UserPointBalance(userId: $userId, totalPoints: $totalPoints, availablePoints: $availablePoints, usedPoints: $usedPoints, lastUpdated: $lastUpdated)';
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
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, userId, totalPoints,
      availablePoints, usedPoints, lastUpdated);

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
      required final DateTime lastUpdated}) = _$UserPointBalanceImpl;

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
  DateTime get lastUpdated;

  /// Create a copy of UserPointBalance
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserPointBalanceImplCopyWith<_$UserPointBalanceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
