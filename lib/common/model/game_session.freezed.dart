// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GameSession _$GameSessionFromJson(Map<String, dynamic> json) {
  return _GameSession.fromJson(json);
}

/// @nodoc
mixin _$GameSession {
  String get sid => throw _privateConstructorUsedError; // 会话唯一ID
  String get templateId => throw _privateConstructorUsedError; // 使用的模板ID
  DateTime get startTime =>
      throw _privateConstructorUsedError; // 会话开始时间 (将被json_serializable自动处理为ISO 8601字符串)
  DateTime? get endTime => throw _privateConstructorUsedError; // 会话结束时间 (可选)
  bool get isCompleted =>
      throw _privateConstructorUsedError; // 会话是否已完成 (将被json_serializable自动处理为true/false)
  List<PlayerScore> get scores => throw _privateConstructorUsedError;

  /// Serializes this GameSession to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GameSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GameSessionCopyWith<GameSession> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameSessionCopyWith<$Res> {
  factory $GameSessionCopyWith(
          GameSession value, $Res Function(GameSession) then) =
      _$GameSessionCopyWithImpl<$Res, GameSession>;
  @useResult
  $Res call(
      {String sid,
      String templateId,
      DateTime startTime,
      DateTime? endTime,
      bool isCompleted,
      List<PlayerScore> scores});
}

/// @nodoc
class _$GameSessionCopyWithImpl<$Res, $Val extends GameSession>
    implements $GameSessionCopyWith<$Res> {
  _$GameSessionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GameSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sid = null,
    Object? templateId = null,
    Object? startTime = null,
    Object? endTime = freezed,
    Object? isCompleted = null,
    Object? scores = null,
  }) {
    return _then(_value.copyWith(
      sid: null == sid
          ? _value.sid
          : sid // ignore: cast_nullable_to_non_nullable
              as String,
      templateId: null == templateId
          ? _value.templateId
          : templateId // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endTime: freezed == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      scores: null == scores
          ? _value.scores
          : scores // ignore: cast_nullable_to_non_nullable
              as List<PlayerScore>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GameSessionImplCopyWith<$Res>
    implements $GameSessionCopyWith<$Res> {
  factory _$$GameSessionImplCopyWith(
          _$GameSessionImpl value, $Res Function(_$GameSessionImpl) then) =
      __$$GameSessionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String sid,
      String templateId,
      DateTime startTime,
      DateTime? endTime,
      bool isCompleted,
      List<PlayerScore> scores});
}

/// @nodoc
class __$$GameSessionImplCopyWithImpl<$Res>
    extends _$GameSessionCopyWithImpl<$Res, _$GameSessionImpl>
    implements _$$GameSessionImplCopyWith<$Res> {
  __$$GameSessionImplCopyWithImpl(
      _$GameSessionImpl _value, $Res Function(_$GameSessionImpl) _then)
      : super(_value, _then);

  /// Create a copy of GameSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sid = null,
    Object? templateId = null,
    Object? startTime = null,
    Object? endTime = freezed,
    Object? isCompleted = null,
    Object? scores = null,
  }) {
    return _then(_$GameSessionImpl(
      sid: null == sid
          ? _value.sid
          : sid // ignore: cast_nullable_to_non_nullable
              as String,
      templateId: null == templateId
          ? _value.templateId
          : templateId // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endTime: freezed == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      scores: null == scores
          ? _value._scores
          : scores // ignore: cast_nullable_to_non_nullable
              as List<PlayerScore>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GameSessionImpl extends _GameSession {
  const _$GameSessionImpl(
      {required this.sid,
      required this.templateId,
      required this.startTime,
      this.endTime,
      required this.isCompleted,
      required final List<PlayerScore> scores})
      : _scores = scores,
        super._();

  factory _$GameSessionImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameSessionImplFromJson(json);

  @override
  final String sid;
// 会话唯一ID
  @override
  final String templateId;
// 使用的模板ID
  @override
  final DateTime startTime;
// 会话开始时间 (将被json_serializable自动处理为ISO 8601字符串)
  @override
  final DateTime? endTime;
// 会话结束时间 (可选)
  @override
  final bool isCompleted;
// 会话是否已完成 (将被json_serializable自动处理为true/false)
  final List<PlayerScore> _scores;
// 会话是否已完成 (将被json_serializable自动处理为true/false)
  @override
  List<PlayerScore> get scores {
    if (_scores is EqualUnmodifiableListView) return _scores;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_scores);
  }

  @override
  String toString() {
    return 'GameSession(sid: $sid, templateId: $templateId, startTime: $startTime, endTime: $endTime, isCompleted: $isCompleted, scores: $scores)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameSessionImpl &&
            (identical(other.sid, sid) || other.sid == sid) &&
            (identical(other.templateId, templateId) ||
                other.templateId == templateId) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            const DeepCollectionEquality().equals(other._scores, _scores));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, sid, templateId, startTime,
      endTime, isCompleted, const DeepCollectionEquality().hash(_scores));

  /// Create a copy of GameSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GameSessionImplCopyWith<_$GameSessionImpl> get copyWith =>
      __$$GameSessionImplCopyWithImpl<_$GameSessionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GameSessionImplToJson(
      this,
    );
  }
}

abstract class _GameSession extends GameSession {
  const factory _GameSession(
      {required final String sid,
      required final String templateId,
      required final DateTime startTime,
      final DateTime? endTime,
      required final bool isCompleted,
      required final List<PlayerScore> scores}) = _$GameSessionImpl;
  const _GameSession._() : super._();

  factory _GameSession.fromJson(Map<String, dynamic> json) =
      _$GameSessionImpl.fromJson;

  @override
  String get sid; // 会话唯一ID
  @override
  String get templateId; // 使用的模板ID
  @override
  DateTime get startTime; // 会话开始时间 (将被json_serializable自动处理为ISO 8601字符串)
  @override
  DateTime? get endTime; // 会话结束时间 (可选)
  @override
  bool get isCompleted; // 会话是否已完成 (将被json_serializable自动处理为true/false)
  @override
  List<PlayerScore> get scores;

  /// Create a copy of GameSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameSessionImplCopyWith<_$GameSessionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
