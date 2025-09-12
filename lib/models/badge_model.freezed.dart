// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'badge_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

BadgeModel _$BadgeModelFromJson(Map<String, dynamic> json) {
  return _BadgeModel.fromJson(json);
}

/// @nodoc
mixin _$BadgeModel {
  String get badgeId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get iconUrl => throw _privateConstructorUsedError;
  BadgeType get type => throw _privateConstructorUsedError;
  int get requiredValue => throw _privateConstructorUsedError;
  BadgeRarity get rarity => throw _privateConstructorUsedError;
  bool get isUnlocked => throw _privateConstructorUsedError;
  DateTime? get unlockedAt => throw _privateConstructorUsedError;
  String? get category => throw _privateConstructorUsedError;

  /// Serializes this BadgeModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BadgeModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BadgeModelCopyWith<BadgeModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BadgeModelCopyWith<$Res> {
  factory $BadgeModelCopyWith(
          BadgeModel value, $Res Function(BadgeModel) then) =
      _$BadgeModelCopyWithImpl<$Res, BadgeModel>;
  @useResult
  $Res call(
      {String badgeId,
      String name,
      String description,
      String iconUrl,
      BadgeType type,
      int requiredValue,
      BadgeRarity rarity,
      bool isUnlocked,
      DateTime? unlockedAt,
      String? category});
}

/// @nodoc
class _$BadgeModelCopyWithImpl<$Res, $Val extends BadgeModel>
    implements $BadgeModelCopyWith<$Res> {
  _$BadgeModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BadgeModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? badgeId = null,
    Object? name = null,
    Object? description = null,
    Object? iconUrl = null,
    Object? type = null,
    Object? requiredValue = null,
    Object? rarity = null,
    Object? isUnlocked = null,
    Object? unlockedAt = freezed,
    Object? category = freezed,
  }) {
    return _then(_value.copyWith(
      badgeId: null == badgeId
          ? _value.badgeId
          : badgeId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      iconUrl: null == iconUrl
          ? _value.iconUrl
          : iconUrl // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as BadgeType,
      requiredValue: null == requiredValue
          ? _value.requiredValue
          : requiredValue // ignore: cast_nullable_to_non_nullable
              as int,
      rarity: null == rarity
          ? _value.rarity
          : rarity // ignore: cast_nullable_to_non_nullable
              as BadgeRarity,
      isUnlocked: null == isUnlocked
          ? _value.isUnlocked
          : isUnlocked // ignore: cast_nullable_to_non_nullable
              as bool,
      unlockedAt: freezed == unlockedAt
          ? _value.unlockedAt
          : unlockedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BadgeModelImplCopyWith<$Res>
    implements $BadgeModelCopyWith<$Res> {
  factory _$$BadgeModelImplCopyWith(
          _$BadgeModelImpl value, $Res Function(_$BadgeModelImpl) then) =
      __$$BadgeModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String badgeId,
      String name,
      String description,
      String iconUrl,
      BadgeType type,
      int requiredValue,
      BadgeRarity rarity,
      bool isUnlocked,
      DateTime? unlockedAt,
      String? category});
}

/// @nodoc
class __$$BadgeModelImplCopyWithImpl<$Res>
    extends _$BadgeModelCopyWithImpl<$Res, _$BadgeModelImpl>
    implements _$$BadgeModelImplCopyWith<$Res> {
  __$$BadgeModelImplCopyWithImpl(
      _$BadgeModelImpl _value, $Res Function(_$BadgeModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of BadgeModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? badgeId = null,
    Object? name = null,
    Object? description = null,
    Object? iconUrl = null,
    Object? type = null,
    Object? requiredValue = null,
    Object? rarity = null,
    Object? isUnlocked = null,
    Object? unlockedAt = freezed,
    Object? category = freezed,
  }) {
    return _then(_$BadgeModelImpl(
      badgeId: null == badgeId
          ? _value.badgeId
          : badgeId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      iconUrl: null == iconUrl
          ? _value.iconUrl
          : iconUrl // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as BadgeType,
      requiredValue: null == requiredValue
          ? _value.requiredValue
          : requiredValue // ignore: cast_nullable_to_non_nullable
              as int,
      rarity: null == rarity
          ? _value.rarity
          : rarity // ignore: cast_nullable_to_non_nullable
              as BadgeRarity,
      isUnlocked: null == isUnlocked
          ? _value.isUnlocked
          : isUnlocked // ignore: cast_nullable_to_non_nullable
              as bool,
      unlockedAt: freezed == unlockedAt
          ? _value.unlockedAt
          : unlockedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BadgeModelImpl implements _BadgeModel {
  const _$BadgeModelImpl(
      {required this.badgeId,
      required this.name,
      required this.description,
      required this.iconUrl,
      required this.type,
      required this.requiredValue,
      required this.rarity,
      this.isUnlocked = false,
      this.unlockedAt,
      this.category});

  factory _$BadgeModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$BadgeModelImplFromJson(json);

  @override
  final String badgeId;
  @override
  final String name;
  @override
  final String description;
  @override
  final String iconUrl;
  @override
  final BadgeType type;
  @override
  final int requiredValue;
  @override
  final BadgeRarity rarity;
  @override
  @JsonKey()
  final bool isUnlocked;
  @override
  final DateTime? unlockedAt;
  @override
  final String? category;

  @override
  String toString() {
    return 'BadgeModel(badgeId: $badgeId, name: $name, description: $description, iconUrl: $iconUrl, type: $type, requiredValue: $requiredValue, rarity: $rarity, isUnlocked: $isUnlocked, unlockedAt: $unlockedAt, category: $category)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BadgeModelImpl &&
            (identical(other.badgeId, badgeId) || other.badgeId == badgeId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.iconUrl, iconUrl) || other.iconUrl == iconUrl) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.requiredValue, requiredValue) ||
                other.requiredValue == requiredValue) &&
            (identical(other.rarity, rarity) || other.rarity == rarity) &&
            (identical(other.isUnlocked, isUnlocked) ||
                other.isUnlocked == isUnlocked) &&
            (identical(other.unlockedAt, unlockedAt) ||
                other.unlockedAt == unlockedAt) &&
            (identical(other.category, category) ||
                other.category == category));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, badgeId, name, description,
      iconUrl, type, requiredValue, rarity, isUnlocked, unlockedAt, category);

  /// Create a copy of BadgeModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BadgeModelImplCopyWith<_$BadgeModelImpl> get copyWith =>
      __$$BadgeModelImplCopyWithImpl<_$BadgeModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BadgeModelImplToJson(
      this,
    );
  }
}

abstract class _BadgeModel implements BadgeModel {
  const factory _BadgeModel(
      {required final String badgeId,
      required final String name,
      required final String description,
      required final String iconUrl,
      required final BadgeType type,
      required final int requiredValue,
      required final BadgeRarity rarity,
      final bool isUnlocked,
      final DateTime? unlockedAt,
      final String? category}) = _$BadgeModelImpl;

  factory _BadgeModel.fromJson(Map<String, dynamic> json) =
      _$BadgeModelImpl.fromJson;

  @override
  String get badgeId;
  @override
  String get name;
  @override
  String get description;
  @override
  String get iconUrl;
  @override
  BadgeType get type;
  @override
  int get requiredValue;
  @override
  BadgeRarity get rarity;
  @override
  bool get isUnlocked;
  @override
  DateTime? get unlockedAt;
  @override
  String? get category;

  /// Create a copy of BadgeModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BadgeModelImplCopyWith<_$BadgeModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserBadgeModel _$UserBadgeModelFromJson(Map<String, dynamic> json) {
  return _UserBadgeModel.fromJson(json);
}

/// @nodoc
mixin _$UserBadgeModel {
  String get userId => throw _privateConstructorUsedError;
  String get badgeId => throw _privateConstructorUsedError;
  DateTime get unlockedAt => throw _privateConstructorUsedError;
  int get progress => throw _privateConstructorUsedError;
  int get requiredValue => throw _privateConstructorUsedError;
  bool get isNew => throw _privateConstructorUsedError;

  /// Serializes this UserBadgeModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserBadgeModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserBadgeModelCopyWith<UserBadgeModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserBadgeModelCopyWith<$Res> {
  factory $UserBadgeModelCopyWith(
          UserBadgeModel value, $Res Function(UserBadgeModel) then) =
      _$UserBadgeModelCopyWithImpl<$Res, UserBadgeModel>;
  @useResult
  $Res call(
      {String userId,
      String badgeId,
      DateTime unlockedAt,
      int progress,
      int requiredValue,
      bool isNew});
}

/// @nodoc
class _$UserBadgeModelCopyWithImpl<$Res, $Val extends UserBadgeModel>
    implements $UserBadgeModelCopyWith<$Res> {
  _$UserBadgeModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserBadgeModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? badgeId = null,
    Object? unlockedAt = null,
    Object? progress = null,
    Object? requiredValue = null,
    Object? isNew = null,
  }) {
    return _then(_value.copyWith(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      badgeId: null == badgeId
          ? _value.badgeId
          : badgeId // ignore: cast_nullable_to_non_nullable
              as String,
      unlockedAt: null == unlockedAt
          ? _value.unlockedAt
          : unlockedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as int,
      requiredValue: null == requiredValue
          ? _value.requiredValue
          : requiredValue // ignore: cast_nullable_to_non_nullable
              as int,
      isNew: null == isNew
          ? _value.isNew
          : isNew // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserBadgeModelImplCopyWith<$Res>
    implements $UserBadgeModelCopyWith<$Res> {
  factory _$$UserBadgeModelImplCopyWith(_$UserBadgeModelImpl value,
          $Res Function(_$UserBadgeModelImpl) then) =
      __$$UserBadgeModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String userId,
      String badgeId,
      DateTime unlockedAt,
      int progress,
      int requiredValue,
      bool isNew});
}

/// @nodoc
class __$$UserBadgeModelImplCopyWithImpl<$Res>
    extends _$UserBadgeModelCopyWithImpl<$Res, _$UserBadgeModelImpl>
    implements _$$UserBadgeModelImplCopyWith<$Res> {
  __$$UserBadgeModelImplCopyWithImpl(
      _$UserBadgeModelImpl _value, $Res Function(_$UserBadgeModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserBadgeModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? badgeId = null,
    Object? unlockedAt = null,
    Object? progress = null,
    Object? requiredValue = null,
    Object? isNew = null,
  }) {
    return _then(_$UserBadgeModelImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      badgeId: null == badgeId
          ? _value.badgeId
          : badgeId // ignore: cast_nullable_to_non_nullable
              as String,
      unlockedAt: null == unlockedAt
          ? _value.unlockedAt
          : unlockedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as int,
      requiredValue: null == requiredValue
          ? _value.requiredValue
          : requiredValue // ignore: cast_nullable_to_non_nullable
              as int,
      isNew: null == isNew
          ? _value.isNew
          : isNew // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserBadgeModelImpl implements _UserBadgeModel {
  const _$UserBadgeModelImpl(
      {required this.userId,
      required this.badgeId,
      required this.unlockedAt,
      required this.progress,
      required this.requiredValue,
      this.isNew = false});

  factory _$UserBadgeModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserBadgeModelImplFromJson(json);

  @override
  final String userId;
  @override
  final String badgeId;
  @override
  final DateTime unlockedAt;
  @override
  final int progress;
  @override
  final int requiredValue;
  @override
  @JsonKey()
  final bool isNew;

  @override
  String toString() {
    return 'UserBadgeModel(userId: $userId, badgeId: $badgeId, unlockedAt: $unlockedAt, progress: $progress, requiredValue: $requiredValue, isNew: $isNew)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserBadgeModelImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.badgeId, badgeId) || other.badgeId == badgeId) &&
            (identical(other.unlockedAt, unlockedAt) ||
                other.unlockedAt == unlockedAt) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.requiredValue, requiredValue) ||
                other.requiredValue == requiredValue) &&
            (identical(other.isNew, isNew) || other.isNew == isNew));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, userId, badgeId, unlockedAt, progress, requiredValue, isNew);

  /// Create a copy of UserBadgeModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserBadgeModelImplCopyWith<_$UserBadgeModelImpl> get copyWith =>
      __$$UserBadgeModelImplCopyWithImpl<_$UserBadgeModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserBadgeModelImplToJson(
      this,
    );
  }
}

abstract class _UserBadgeModel implements UserBadgeModel {
  const factory _UserBadgeModel(
      {required final String userId,
      required final String badgeId,
      required final DateTime unlockedAt,
      required final int progress,
      required final int requiredValue,
      final bool isNew}) = _$UserBadgeModelImpl;

  factory _UserBadgeModel.fromJson(Map<String, dynamic> json) =
      _$UserBadgeModelImpl.fromJson;

  @override
  String get userId;
  @override
  String get badgeId;
  @override
  DateTime get unlockedAt;
  @override
  int get progress;
  @override
  int get requiredValue;
  @override
  bool get isNew;

  /// Create a copy of UserBadgeModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserBadgeModelImplCopyWith<_$UserBadgeModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
