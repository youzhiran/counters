// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player_score.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PlayerScore _$PlayerScoreFromJson(Map<String, dynamic> json) {
  return _PlayerScore.fromJson(json);
}

/// @nodoc
mixin _$PlayerScore {
  String get playerId => throw _privateConstructorUsedError; // 玩家唯一ID
// 回合得分列表。List<int?> 可以被 json_serializable 直接处理为 JSON 数组。
// @Default([]) 表示如果 JSON 中没有这个字段或者为 null，则默认值为 []。
  List<int?> get roundScores =>
      throw _privateConstructorUsedError; // 按回合存储的扩展字段。Map<int, Map<String, dynamic>> 可以被 json_serializable 处理为 JSON 对象。
// 注意：JSON 的 key 必须是字符串，json_serializable 会自动将 int key 转换为字符串。
// @Default({}) 表示如果 JSON 中没有这个字段或者为 null，则默认值为 {}。
  Map<int, Map<String, dynamic>> get roundExtendedFields =>
      throw _privateConstructorUsedError;

  /// Serializes this PlayerScore to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlayerScore
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlayerScoreCopyWith<PlayerScore> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayerScoreCopyWith<$Res> {
  factory $PlayerScoreCopyWith(
          PlayerScore value, $Res Function(PlayerScore) then) =
      _$PlayerScoreCopyWithImpl<$Res, PlayerScore>;

  @useResult
  $Res call(
      {String playerId,
      List<int?> roundScores,
      Map<int, Map<String, dynamic>> roundExtendedFields});
}

/// @nodoc
class _$PlayerScoreCopyWithImpl<$Res, $Val extends PlayerScore>
    implements $PlayerScoreCopyWith<$Res> {
  _$PlayerScoreCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;

  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlayerScore
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerId = null,
    Object? roundScores = null,
    Object? roundExtendedFields = null,
  }) {
    return _then(_value.copyWith(
      playerId: null == playerId
          ? _value.playerId
          : playerId // ignore: cast_nullable_to_non_nullable
              as String,
      roundScores: null == roundScores
          ? _value.roundScores
          : roundScores // ignore: cast_nullable_to_non_nullable
              as List<int?>,
      roundExtendedFields: null == roundExtendedFields
          ? _value.roundExtendedFields
          : roundExtendedFields // ignore: cast_nullable_to_non_nullable
              as Map<int, Map<String, dynamic>>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PlayerScoreImplCopyWith<$Res>
    implements $PlayerScoreCopyWith<$Res> {
  factory _$$PlayerScoreImplCopyWith(
          _$PlayerScoreImpl value, $Res Function(_$PlayerScoreImpl) then) =
      __$$PlayerScoreImplCopyWithImpl<$Res>;

  @override
  @useResult
  $Res call(
      {String playerId,
      List<int?> roundScores,
      Map<int, Map<String, dynamic>> roundExtendedFields});
}

/// @nodoc
class __$$PlayerScoreImplCopyWithImpl<$Res>
    extends _$PlayerScoreCopyWithImpl<$Res, _$PlayerScoreImpl>
    implements _$$PlayerScoreImplCopyWith<$Res> {
  __$$PlayerScoreImplCopyWithImpl(
      _$PlayerScoreImpl _value, $Res Function(_$PlayerScoreImpl) _then)
      : super(_value, _then);

  /// Create a copy of PlayerScore
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerId = null,
    Object? roundScores = null,
    Object? roundExtendedFields = null,
  }) {
    return _then(_$PlayerScoreImpl(
      playerId: null == playerId
          ? _value.playerId
          : playerId // ignore: cast_nullable_to_non_nullable
              as String,
      roundScores: null == roundScores
          ? _value._roundScores
          : roundScores // ignore: cast_nullable_to_non_nullable
              as List<int?>,
      roundExtendedFields: null == roundExtendedFields
          ? _value._roundExtendedFields
          : roundExtendedFields // ignore: cast_nullable_to_non_nullable
              as Map<int, Map<String, dynamic>>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PlayerScoreImpl extends _PlayerScore {
  const _$PlayerScoreImpl(
      {required this.playerId,
      final List<int?> roundScores = const [],
      final Map<int, Map<String, dynamic>> roundExtendedFields = const {}})
      : _roundScores = roundScores,
        _roundExtendedFields = roundExtendedFields,
        super._();

  factory _$PlayerScoreImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayerScoreImplFromJson(json);

  @override
  final String playerId;

// 玩家唯一ID
// 回合得分列表。List<int?> 可以被 json_serializable 直接处理为 JSON 数组。
// @Default([]) 表示如果 JSON 中没有这个字段或者为 null，则默认值为 []。
  final List<int?> _roundScores;

// 玩家唯一ID
// 回合得分列表。List<int?> 可以被 json_serializable 直接处理为 JSON 数组。
// @Default([]) 表示如果 JSON 中没有这个字段或者为 null，则默认值为 []。
  @override
  @JsonKey()
  List<int?> get roundScores {
    if (_roundScores is EqualUnmodifiableListView) return _roundScores;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_roundScores);
  }

// 按回合存储的扩展字段。Map<int, Map<String, dynamic>> 可以被 json_serializable 处理为 JSON 对象。
// 注意：JSON 的 key 必须是字符串，json_serializable 会自动将 int key 转换为字符串。
// @Default({}) 表示如果 JSON 中没有这个字段或者为 null，则默认值为 {}。
  final Map<int, Map<String, dynamic>> _roundExtendedFields;

// 按回合存储的扩展字段。Map<int, Map<String, dynamic>> 可以被 json_serializable 处理为 JSON 对象。
// 注意：JSON 的 key 必须是字符串，json_serializable 会自动将 int key 转换为字符串。
// @Default({}) 表示如果 JSON 中没有这个字段或者为 null，则默认值为 {}。
  @override
  @JsonKey()
  Map<int, Map<String, dynamic>> get roundExtendedFields {
    if (_roundExtendedFields is EqualUnmodifiableMapView)
      return _roundExtendedFields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_roundExtendedFields);
  }

  @override
  String toString() {
    return 'PlayerScore(playerId: $playerId, roundScores: $roundScores, roundExtendedFields: $roundExtendedFields)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerScoreImpl &&
            (identical(other.playerId, playerId) ||
                other.playerId == playerId) &&
            const DeepCollectionEquality()
                .equals(other._roundScores, _roundScores) &&
            const DeepCollectionEquality()
                .equals(other._roundExtendedFields, _roundExtendedFields));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      playerId,
      const DeepCollectionEquality().hash(_roundScores),
      const DeepCollectionEquality().hash(_roundExtendedFields));

  /// Create a copy of PlayerScore
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerScoreImplCopyWith<_$PlayerScoreImpl> get copyWith =>
      __$$PlayerScoreImplCopyWithImpl<_$PlayerScoreImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayerScoreImplToJson(
      this,
    );
  }
}

abstract class _PlayerScore extends PlayerScore {
  const factory _PlayerScore(
          {required final String playerId,
          final List<int?> roundScores,
          final Map<int, Map<String, dynamic>> roundExtendedFields}) =
      _$PlayerScoreImpl;

  const _PlayerScore._() : super._();

  factory _PlayerScore.fromJson(Map<String, dynamic> json) =
      _$PlayerScoreImpl.fromJson;

  @override
  String get playerId; // 玩家唯一ID
// 回合得分列表。List<int?> 可以被 json_serializable 直接处理为 JSON 数组。
// @Default([]) 表示如果 JSON 中没有这个字段或者为 null，则默认值为 []。
  @override
  List<int?>
      get roundScores; // 按回合存储的扩展字段。Map<int, Map<String, dynamic>> 可以被 json_serializable 处理为 JSON 对象。
// 注意：JSON 的 key 必须是字符串，json_serializable 会自动将 int key 转换为字符串。
// @Default({}) 表示如果 JSON 中没有这个字段或者为 null，则默认值为 {}。
  @override
  Map<int, Map<String, dynamic>> get roundExtendedFields;

  /// Create a copy of PlayerScore
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayerScoreImplCopyWith<_$PlayerScoreImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
