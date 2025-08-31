// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GameSession {
  String get sid; // 会话唯一ID
  String get templateId; // 使用的模板ID
  DateTime get startTime; // 会话开始时间 (将被json_serializable自动处理为ISO 8601字符串)
  DateTime? get endTime; // 会话结束时间 (可选)
  bool get isCompleted; // 会话是否已完成 (将被json_serializable自动处理为true/false)
  List<PlayerScore> get scores; // 玩家得分列表 (PlayerScore 也必须是可序列化的)
  String? get leagueMatchId;

  /// Create a copy of GameSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $GameSessionCopyWith<GameSession> get copyWith =>
      _$GameSessionCopyWithImpl<GameSession>(this as GameSession, _$identity);

  /// Serializes this GameSession to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is GameSession &&
            (identical(other.sid, sid) || other.sid == sid) &&
            (identical(other.templateId, templateId) ||
                other.templateId == templateId) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            const DeepCollectionEquality().equals(other.scores, scores) &&
            (identical(other.leagueMatchId, leagueMatchId) ||
                other.leagueMatchId == leagueMatchId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      sid,
      templateId,
      startTime,
      endTime,
      isCompleted,
      const DeepCollectionEquality().hash(scores),
      leagueMatchId);

  @override
  String toString() {
    return 'GameSession(sid: $sid, templateId: $templateId, startTime: $startTime, endTime: $endTime, isCompleted: $isCompleted, scores: $scores, leagueMatchId: $leagueMatchId)';
  }
}

/// @nodoc
abstract mixin class $GameSessionCopyWith<$Res> {
  factory $GameSessionCopyWith(
          GameSession value, $Res Function(GameSession) _then) =
      _$GameSessionCopyWithImpl;
  @useResult
  $Res call(
      {String sid,
      String templateId,
      DateTime startTime,
      DateTime? endTime,
      bool isCompleted,
      List<PlayerScore> scores,
      String? leagueMatchId});
}

/// @nodoc
class _$GameSessionCopyWithImpl<$Res> implements $GameSessionCopyWith<$Res> {
  _$GameSessionCopyWithImpl(this._self, this._then);

  final GameSession _self;
  final $Res Function(GameSession) _then;

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
    Object? leagueMatchId = freezed,
  }) {
    return _then(_self.copyWith(
      sid: null == sid
          ? _self.sid
          : sid // ignore: cast_nullable_to_non_nullable
              as String,
      templateId: null == templateId
          ? _self.templateId
          : templateId // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _self.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endTime: freezed == endTime
          ? _self.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isCompleted: null == isCompleted
          ? _self.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      scores: null == scores
          ? _self.scores
          : scores // ignore: cast_nullable_to_non_nullable
              as List<PlayerScore>,
      leagueMatchId: freezed == leagueMatchId
          ? _self.leagueMatchId
          : leagueMatchId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [GameSession].
extension GameSessionPatterns on GameSession {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_GameSession value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _GameSession() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_GameSession value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GameSession():
        return $default(_that);
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_GameSession value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GameSession() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String sid,
            String templateId,
            DateTime startTime,
            DateTime? endTime,
            bool isCompleted,
            List<PlayerScore> scores,
            String? leagueMatchId)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _GameSession() when $default != null:
        return $default(
            _that.sid,
            _that.templateId,
            _that.startTime,
            _that.endTime,
            _that.isCompleted,
            _that.scores,
            _that.leagueMatchId);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String sid,
            String templateId,
            DateTime startTime,
            DateTime? endTime,
            bool isCompleted,
            List<PlayerScore> scores,
            String? leagueMatchId)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GameSession():
        return $default(
            _that.sid,
            _that.templateId,
            _that.startTime,
            _that.endTime,
            _that.isCompleted,
            _that.scores,
            _that.leagueMatchId);
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String sid,
            String templateId,
            DateTime startTime,
            DateTime? endTime,
            bool isCompleted,
            List<PlayerScore> scores,
            String? leagueMatchId)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GameSession() when $default != null:
        return $default(
            _that.sid,
            _that.templateId,
            _that.startTime,
            _that.endTime,
            _that.isCompleted,
            _that.scores,
            _that.leagueMatchId);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _GameSession extends GameSession {
  const _GameSession(
      {required this.sid,
      required this.templateId,
      required this.startTime,
      this.endTime,
      required this.isCompleted,
      required final List<PlayerScore> scores,
      this.leagueMatchId})
      : _scores = scores,
        super._();
  factory _GameSession.fromJson(Map<String, dynamic> json) =>
      _$GameSessionFromJson(json);

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

// 玩家得分列表 (PlayerScore 也必须是可序列化的)
  @override
  final String? leagueMatchId;

  /// Create a copy of GameSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$GameSessionCopyWith<_GameSession> get copyWith =>
      __$GameSessionCopyWithImpl<_GameSession>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$GameSessionToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _GameSession &&
            (identical(other.sid, sid) || other.sid == sid) &&
            (identical(other.templateId, templateId) ||
                other.templateId == templateId) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            const DeepCollectionEquality().equals(other._scores, _scores) &&
            (identical(other.leagueMatchId, leagueMatchId) ||
                other.leagueMatchId == leagueMatchId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      sid,
      templateId,
      startTime,
      endTime,
      isCompleted,
      const DeepCollectionEquality().hash(_scores),
      leagueMatchId);

  @override
  String toString() {
    return 'GameSession(sid: $sid, templateId: $templateId, startTime: $startTime, endTime: $endTime, isCompleted: $isCompleted, scores: $scores, leagueMatchId: $leagueMatchId)';
  }
}

/// @nodoc
abstract mixin class _$GameSessionCopyWith<$Res>
    implements $GameSessionCopyWith<$Res> {
  factory _$GameSessionCopyWith(
          _GameSession value, $Res Function(_GameSession) _then) =
      __$GameSessionCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String sid,
      String templateId,
      DateTime startTime,
      DateTime? endTime,
      bool isCompleted,
      List<PlayerScore> scores,
      String? leagueMatchId});
}

/// @nodoc
class __$GameSessionCopyWithImpl<$Res> implements _$GameSessionCopyWith<$Res> {
  __$GameSessionCopyWithImpl(this._self, this._then);

  final _GameSession _self;
  final $Res Function(_GameSession) _then;

  /// Create a copy of GameSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? sid = null,
    Object? templateId = null,
    Object? startTime = null,
    Object? endTime = freezed,
    Object? isCompleted = null,
    Object? scores = null,
    Object? leagueMatchId = freezed,
  }) {
    return _then(_GameSession(
      sid: null == sid
          ? _self.sid
          : sid // ignore: cast_nullable_to_non_nullable
              as String,
      templateId: null == templateId
          ? _self.templateId
          : templateId // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _self.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endTime: freezed == endTime
          ? _self.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isCompleted: null == isCompleted
          ? _self.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      scores: null == scores
          ? _self._scores
          : scores // ignore: cast_nullable_to_non_nullable
              as List<PlayerScore>,
      leagueMatchId: freezed == leagueMatchId
          ? _self.leagueMatchId
          : leagueMatchId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
