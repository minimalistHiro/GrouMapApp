// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'level_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

LevelModel _$LevelModelFromJson(Map<String, dynamic> json) {
  return _LevelModel.fromJson(json);
}

/// @nodoc
mixin _$LevelModel {
  int get level => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get requiredPoints => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get iconUrl => throw _privateConstructorUsedError;
  List<String> get rewards => throw _privateConstructorUsedError;
  int get maxPoints => throw _privateConstructorUsedError;

  /// Serializes this LevelModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LevelModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LevelModelCopyWith<LevelModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LevelModelCopyWith<$Res> {
  factory $LevelModelCopyWith(
          LevelModel value, $Res Function(LevelModel) then) =
      _$LevelModelCopyWithImpl<$Res, LevelModel>;
  @useResult
  $Res call(
      {int level,
      String name,
      int requiredPoints,
      String description,
      String iconUrl,
      List<String> rewards,
      int maxPoints});
}

/// @nodoc
class _$LevelModelCopyWithImpl<$Res, $Val extends LevelModel>
    implements $LevelModelCopyWith<$Res> {
  _$LevelModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LevelModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? level = null,
    Object? name = null,
    Object? requiredPoints = null,
    Object? description = null,
    Object? iconUrl = null,
    Object? rewards = null,
    Object? maxPoints = null,
  }) {
    return _then(_value.copyWith(
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      requiredPoints: null == requiredPoints
          ? _value.requiredPoints
          : requiredPoints // ignore: cast_nullable_to_non_nullable
              as int,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      iconUrl: null == iconUrl
          ? _value.iconUrl
          : iconUrl // ignore: cast_nullable_to_non_nullable
              as String,
      rewards: null == rewards
          ? _value.rewards
          : rewards // ignore: cast_nullable_to_non_nullable
              as List<String>,
      maxPoints: null == maxPoints
          ? _value.maxPoints
          : maxPoints // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LevelModelImplCopyWith<$Res>
    implements $LevelModelCopyWith<$Res> {
  factory _$$LevelModelImplCopyWith(
          _$LevelModelImpl value, $Res Function(_$LevelModelImpl) then) =
      __$$LevelModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int level,
      String name,
      int requiredPoints,
      String description,
      String iconUrl,
      List<String> rewards,
      int maxPoints});
}

/// @nodoc
class __$$LevelModelImplCopyWithImpl<$Res>
    extends _$LevelModelCopyWithImpl<$Res, _$LevelModelImpl>
    implements _$$LevelModelImplCopyWith<$Res> {
  __$$LevelModelImplCopyWithImpl(
      _$LevelModelImpl _value, $Res Function(_$LevelModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of LevelModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? level = null,
    Object? name = null,
    Object? requiredPoints = null,
    Object? description = null,
    Object? iconUrl = null,
    Object? rewards = null,
    Object? maxPoints = null,
  }) {
    return _then(_$LevelModelImpl(
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      requiredPoints: null == requiredPoints
          ? _value.requiredPoints
          : requiredPoints // ignore: cast_nullable_to_non_nullable
              as int,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      iconUrl: null == iconUrl
          ? _value.iconUrl
          : iconUrl // ignore: cast_nullable_to_non_nullable
              as String,
      rewards: null == rewards
          ? _value._rewards
          : rewards // ignore: cast_nullable_to_non_nullable
              as List<String>,
      maxPoints: null == maxPoints
          ? _value.maxPoints
          : maxPoints // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LevelModelImpl implements _LevelModel {
  const _$LevelModelImpl(
      {required this.level,
      required this.name,
      required this.requiredPoints,
      required this.description,
      required this.iconUrl,
      required final List<String> rewards,
      this.maxPoints = 0})
      : _rewards = rewards;

  factory _$LevelModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$LevelModelImplFromJson(json);

  @override
  final int level;
  @override
  final String name;
  @override
  final int requiredPoints;
  @override
  final String description;
  @override
  final String iconUrl;
  final List<String> _rewards;
  @override
  List<String> get rewards {
    if (_rewards is EqualUnmodifiableListView) return _rewards;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_rewards);
  }

  @override
  @JsonKey()
  final int maxPoints;

  @override
  String toString() {
    return 'LevelModel(level: $level, name: $name, requiredPoints: $requiredPoints, description: $description, iconUrl: $iconUrl, rewards: $rewards, maxPoints: $maxPoints)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LevelModelImpl &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.requiredPoints, requiredPoints) ||
                other.requiredPoints == requiredPoints) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.iconUrl, iconUrl) || other.iconUrl == iconUrl) &&
            const DeepCollectionEquality().equals(other._rewards, _rewards) &&
            (identical(other.maxPoints, maxPoints) ||
                other.maxPoints == maxPoints));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      level,
      name,
      requiredPoints,
      description,
      iconUrl,
      const DeepCollectionEquality().hash(_rewards),
      maxPoints);

  /// Create a copy of LevelModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LevelModelImplCopyWith<_$LevelModelImpl> get copyWith =>
      __$$LevelModelImplCopyWithImpl<_$LevelModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LevelModelImplToJson(
      this,
    );
  }
}

abstract class _LevelModel implements LevelModel {
  const factory _LevelModel(
      {required final int level,
      required final String name,
      required final int requiredPoints,
      required final String description,
      required final String iconUrl,
      required final List<String> rewards,
      final int maxPoints}) = _$LevelModelImpl;

  factory _LevelModel.fromJson(Map<String, dynamic> json) =
      _$LevelModelImpl.fromJson;

  @override
  int get level;
  @override
  String get name;
  @override
  int get requiredPoints;
  @override
  String get description;
  @override
  String get iconUrl;
  @override
  List<String> get rewards;
  @override
  int get maxPoints;

  /// Create a copy of LevelModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LevelModelImplCopyWith<_$LevelModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserLevelModel _$UserLevelModelFromJson(Map<String, dynamic> json) {
  return _UserLevelModel.fromJson(json);
}

/// @nodoc
mixin _$UserLevelModel {
  String get userId => throw _privateConstructorUsedError;
  int get currentLevel => throw _privateConstructorUsedError;
  int get currentPoints => throw _privateConstructorUsedError;
  int get totalPoints => throw _privateConstructorUsedError;
  DateTime get lastUpdated => throw _privateConstructorUsedError;
  int get experienceMultiplier => throw _privateConstructorUsedError;

  /// Serializes this UserLevelModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserLevelModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserLevelModelCopyWith<UserLevelModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserLevelModelCopyWith<$Res> {
  factory $UserLevelModelCopyWith(
          UserLevelModel value, $Res Function(UserLevelModel) then) =
      _$UserLevelModelCopyWithImpl<$Res, UserLevelModel>;
  @useResult
  $Res call(
      {String userId,
      int currentLevel,
      int currentPoints,
      int totalPoints,
      DateTime lastUpdated,
      int experienceMultiplier});
}

/// @nodoc
class _$UserLevelModelCopyWithImpl<$Res, $Val extends UserLevelModel>
    implements $UserLevelModelCopyWith<$Res> {
  _$UserLevelModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserLevelModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? currentLevel = null,
    Object? currentPoints = null,
    Object? totalPoints = null,
    Object? lastUpdated = null,
    Object? experienceMultiplier = null,
  }) {
    return _then(_value.copyWith(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      currentLevel: null == currentLevel
          ? _value.currentLevel
          : currentLevel // ignore: cast_nullable_to_non_nullable
              as int,
      currentPoints: null == currentPoints
          ? _value.currentPoints
          : currentPoints // ignore: cast_nullable_to_non_nullable
              as int,
      totalPoints: null == totalPoints
          ? _value.totalPoints
          : totalPoints // ignore: cast_nullable_to_non_nullable
              as int,
      lastUpdated: null == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime,
      experienceMultiplier: null == experienceMultiplier
          ? _value.experienceMultiplier
          : experienceMultiplier // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserLevelModelImplCopyWith<$Res>
    implements $UserLevelModelCopyWith<$Res> {
  factory _$$UserLevelModelImplCopyWith(_$UserLevelModelImpl value,
          $Res Function(_$UserLevelModelImpl) then) =
      __$$UserLevelModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String userId,
      int currentLevel,
      int currentPoints,
      int totalPoints,
      DateTime lastUpdated,
      int experienceMultiplier});
}

/// @nodoc
class __$$UserLevelModelImplCopyWithImpl<$Res>
    extends _$UserLevelModelCopyWithImpl<$Res, _$UserLevelModelImpl>
    implements _$$UserLevelModelImplCopyWith<$Res> {
  __$$UserLevelModelImplCopyWithImpl(
      _$UserLevelModelImpl _value, $Res Function(_$UserLevelModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserLevelModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? currentLevel = null,
    Object? currentPoints = null,
    Object? totalPoints = null,
    Object? lastUpdated = null,
    Object? experienceMultiplier = null,
  }) {
    return _then(_$UserLevelModelImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      currentLevel: null == currentLevel
          ? _value.currentLevel
          : currentLevel // ignore: cast_nullable_to_non_nullable
              as int,
      currentPoints: null == currentPoints
          ? _value.currentPoints
          : currentPoints // ignore: cast_nullable_to_non_nullable
              as int,
      totalPoints: null == totalPoints
          ? _value.totalPoints
          : totalPoints // ignore: cast_nullable_to_non_nullable
              as int,
      lastUpdated: null == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime,
      experienceMultiplier: null == experienceMultiplier
          ? _value.experienceMultiplier
          : experienceMultiplier // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserLevelModelImpl implements _UserLevelModel {
  const _$UserLevelModelImpl(
      {required this.userId,
      required this.currentLevel,
      required this.currentPoints,
      required this.totalPoints,
      required this.lastUpdated,
      this.experienceMultiplier = 0});

  factory _$UserLevelModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserLevelModelImplFromJson(json);

  @override
  final String userId;
  @override
  final int currentLevel;
  @override
  final int currentPoints;
  @override
  final int totalPoints;
  @override
  final DateTime lastUpdated;
  @override
  @JsonKey()
  final int experienceMultiplier;

  @override
  String toString() {
    return 'UserLevelModel(userId: $userId, currentLevel: $currentLevel, currentPoints: $currentPoints, totalPoints: $totalPoints, lastUpdated: $lastUpdated, experienceMultiplier: $experienceMultiplier)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserLevelModelImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.currentLevel, currentLevel) ||
                other.currentLevel == currentLevel) &&
            (identical(other.currentPoints, currentPoints) ||
                other.currentPoints == currentPoints) &&
            (identical(other.totalPoints, totalPoints) ||
                other.totalPoints == totalPoints) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated) &&
            (identical(other.experienceMultiplier, experienceMultiplier) ||
                other.experienceMultiplier == experienceMultiplier));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, userId, currentLevel,
      currentPoints, totalPoints, lastUpdated, experienceMultiplier);

  /// Create a copy of UserLevelModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserLevelModelImplCopyWith<_$UserLevelModelImpl> get copyWith =>
      __$$UserLevelModelImplCopyWithImpl<_$UserLevelModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserLevelModelImplToJson(
      this,
    );
  }
}

abstract class _UserLevelModel implements UserLevelModel {
  const factory _UserLevelModel(
      {required final String userId,
      required final int currentLevel,
      required final int currentPoints,
      required final int totalPoints,
      required final DateTime lastUpdated,
      final int experienceMultiplier}) = _$UserLevelModelImpl;

  factory _UserLevelModel.fromJson(Map<String, dynamic> json) =
      _$UserLevelModelImpl.fromJson;

  @override
  String get userId;
  @override
  int get currentLevel;
  @override
  int get currentPoints;
  @override
  int get totalPoints;
  @override
  DateTime get lastUpdated;
  @override
  int get experienceMultiplier;

  /// Create a copy of UserLevelModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserLevelModelImplCopyWith<_$UserLevelModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
