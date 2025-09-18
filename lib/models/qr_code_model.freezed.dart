// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'qr_code_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

QRCodeModel _$QRCodeModelFromJson(Map<String, dynamic> json) {
  return _QRCodeModel.fromJson(json);
}

/// @nodoc
mixin _$QRCodeModel {
  String get qrCodeId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get storeId => throw _privateConstructorUsedError;
  String get qrCodeData => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get expiresAt => throw _privateConstructorUsedError;
  bool get isUsed => throw _privateConstructorUsedError;
  DateTime? get usedAt => throw _privateConstructorUsedError;

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
      String userId,
      String storeId,
      String qrCodeData,
      DateTime createdAt,
      DateTime expiresAt,
      bool isUsed,
      DateTime? usedAt});
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
    Object? userId = null,
    Object? storeId = null,
    Object? qrCodeData = null,
    Object? createdAt = null,
    Object? expiresAt = null,
    Object? isUsed = null,
    Object? usedAt = freezed,
  }) {
    return _then(_value.copyWith(
      qrCodeId: null == qrCodeId
          ? _value.qrCodeId
          : qrCodeId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      storeId: null == storeId
          ? _value.storeId
          : storeId // ignore: cast_nullable_to_non_nullable
              as String,
      qrCodeData: null == qrCodeData
          ? _value.qrCodeData
          : qrCodeData // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      expiresAt: null == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isUsed: null == isUsed
          ? _value.isUsed
          : isUsed // ignore: cast_nullable_to_non_nullable
              as bool,
      usedAt: freezed == usedAt
          ? _value.usedAt
          : usedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
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
      String userId,
      String storeId,
      String qrCodeData,
      DateTime createdAt,
      DateTime expiresAt,
      bool isUsed,
      DateTime? usedAt});
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
    Object? userId = null,
    Object? storeId = null,
    Object? qrCodeData = null,
    Object? createdAt = null,
    Object? expiresAt = null,
    Object? isUsed = null,
    Object? usedAt = freezed,
  }) {
    return _then(_$QRCodeModelImpl(
      qrCodeId: null == qrCodeId
          ? _value.qrCodeId
          : qrCodeId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      storeId: null == storeId
          ? _value.storeId
          : storeId // ignore: cast_nullable_to_non_nullable
              as String,
      qrCodeData: null == qrCodeData
          ? _value.qrCodeData
          : qrCodeData // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      expiresAt: null == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isUsed: null == isUsed
          ? _value.isUsed
          : isUsed // ignore: cast_nullable_to_non_nullable
              as bool,
      usedAt: freezed == usedAt
          ? _value.usedAt
          : usedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$QRCodeModelImpl implements _QRCodeModel {
  const _$QRCodeModelImpl(
      {required this.qrCodeId,
      required this.userId,
      required this.storeId,
      required this.qrCodeData,
      required this.createdAt,
      required this.expiresAt,
      this.isUsed = false,
      this.usedAt});

  factory _$QRCodeModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$QRCodeModelImplFromJson(json);

  @override
  final String qrCodeId;
  @override
  final String userId;
  @override
  final String storeId;
  @override
  final String qrCodeData;
  @override
  final DateTime createdAt;
  @override
  final DateTime expiresAt;
  @override
  @JsonKey()
  final bool isUsed;
  @override
  final DateTime? usedAt;

  @override
  String toString() {
    return 'QRCodeModel(qrCodeId: $qrCodeId, userId: $userId, storeId: $storeId, qrCodeData: $qrCodeData, createdAt: $createdAt, expiresAt: $expiresAt, isUsed: $isUsed, usedAt: $usedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QRCodeModelImpl &&
            (identical(other.qrCodeId, qrCodeId) ||
                other.qrCodeId == qrCodeId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.storeId, storeId) || other.storeId == storeId) &&
            (identical(other.qrCodeData, qrCodeData) ||
                other.qrCodeData == qrCodeData) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.isUsed, isUsed) || other.isUsed == isUsed) &&
            (identical(other.usedAt, usedAt) || other.usedAt == usedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, qrCodeId, userId, storeId,
      qrCodeData, createdAt, expiresAt, isUsed, usedAt);

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
      required final String userId,
      required final String storeId,
      required final String qrCodeData,
      required final DateTime createdAt,
      required final DateTime expiresAt,
      final bool isUsed,
      final DateTime? usedAt}) = _$QRCodeModelImpl;

  factory _QRCodeModel.fromJson(Map<String, dynamic> json) =
      _$QRCodeModelImpl.fromJson;

  @override
  String get qrCodeId;
  @override
  String get userId;
  @override
  String get storeId;
  @override
  String get qrCodeData;
  @override
  DateTime get createdAt;
  @override
  DateTime get expiresAt;
  @override
  bool get isUsed;
  @override
  DateTime? get usedAt;

  /// Create a copy of QRCodeModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QRCodeModelImplCopyWith<_$QRCodeModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
