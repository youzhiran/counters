// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_messages.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SyncMessage {
  String get type; // 消息类型，用于区分消息内容
  dynamic get data;

  /// Create a copy of SyncMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SyncMessageCopyWith<SyncMessage> get copyWith =>
      _$SyncMessageCopyWithImpl<SyncMessage>(this as SyncMessage, _$identity);

  /// Serializes this SyncMessage to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SyncMessage &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality().equals(other.data, data));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, type, const DeepCollectionEquality().hash(data));

  @override
  String toString() {
    return 'SyncMessage(type: $type, data: $data)';
  }
}

/// @nodoc
abstract mixin class $SyncMessageCopyWith<$Res> {
  factory $SyncMessageCopyWith(
          SyncMessage value, $Res Function(SyncMessage) _then) =
      _$SyncMessageCopyWithImpl;
  @useResult
  $Res call({String type, dynamic data});
}

/// @nodoc
class _$SyncMessageCopyWithImpl<$Res> implements $SyncMessageCopyWith<$Res> {
  _$SyncMessageCopyWithImpl(this._self, this._then);

  final SyncMessage _self;
  final $Res Function(SyncMessage) _then;

  /// Create a copy of SyncMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? data = freezed,
  }) {
    return _then(_self.copyWith(
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      data: freezed == data
          ? _self.data
          : data // ignore: cast_nullable_to_non_nullable
              as dynamic,
    ));
  }
}

/// Adds pattern-matching-related methods to [SyncMessage].
extension SyncMessagePatterns on SyncMessage {
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
    TResult Function(_SyncMessage value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SyncMessage() when $default != null:
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
    TResult Function(_SyncMessage value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SyncMessage():
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
    TResult? Function(_SyncMessage value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SyncMessage() when $default != null:
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
    TResult Function(String type, dynamic data)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SyncMessage() when $default != null:
        return $default(_that.type, _that.data);
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
    TResult Function(String type, dynamic data) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SyncMessage():
        return $default(_that.type, _that.data);
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
    TResult? Function(String type, dynamic data)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SyncMessage() when $default != null:
        return $default(_that.type, _that.data);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _SyncMessage implements SyncMessage {
  const _SyncMessage({required this.type, this.data});
  factory _SyncMessage.fromJson(Map<String, dynamic> json) =>
      _$SyncMessageFromJson(json);

  @override
  final String type;
// 消息类型，用于区分消息内容
  @override
  final dynamic data;

  /// Create a copy of SyncMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SyncMessageCopyWith<_SyncMessage> get copyWith =>
      __$SyncMessageCopyWithImpl<_SyncMessage>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SyncMessageToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SyncMessage &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality().equals(other.data, data));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, type, const DeepCollectionEquality().hash(data));

  @override
  String toString() {
    return 'SyncMessage(type: $type, data: $data)';
  }
}

/// @nodoc
abstract mixin class _$SyncMessageCopyWith<$Res>
    implements $SyncMessageCopyWith<$Res> {
  factory _$SyncMessageCopyWith(
          _SyncMessage value, $Res Function(_SyncMessage) _then) =
      __$SyncMessageCopyWithImpl;
  @override
  @useResult
  $Res call({String type, dynamic data});
}

/// @nodoc
class __$SyncMessageCopyWithImpl<$Res> implements _$SyncMessageCopyWith<$Res> {
  __$SyncMessageCopyWithImpl(this._self, this._then);

  final _SyncMessage _self;
  final $Res Function(_SyncMessage) _then;

  /// Create a copy of SyncMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? type = null,
    Object? data = freezed,
  }) {
    return _then(_SyncMessage(
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      data: freezed == data
          ? _self.data
          : data // ignore: cast_nullable_to_non_nullable
              as dynamic,
    ));
  }
}

/// @nodoc
mixin _$SyncStatePayload {
  GameSession get session;

  /// Create a copy of SyncStatePayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SyncStatePayloadCopyWith<SyncStatePayload> get copyWith =>
      _$SyncStatePayloadCopyWithImpl<SyncStatePayload>(
          this as SyncStatePayload, _$identity);

  /// Serializes this SyncStatePayload to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SyncStatePayload &&
            (identical(other.session, session) || other.session == session));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, session);

  @override
  String toString() {
    return 'SyncStatePayload(session: $session)';
  }
}

/// @nodoc
abstract mixin class $SyncStatePayloadCopyWith<$Res> {
  factory $SyncStatePayloadCopyWith(
          SyncStatePayload value, $Res Function(SyncStatePayload) _then) =
      _$SyncStatePayloadCopyWithImpl;
  @useResult
  $Res call({GameSession session});

  $GameSessionCopyWith<$Res> get session;
}

/// @nodoc
class _$SyncStatePayloadCopyWithImpl<$Res>
    implements $SyncStatePayloadCopyWith<$Res> {
  _$SyncStatePayloadCopyWithImpl(this._self, this._then);

  final SyncStatePayload _self;
  final $Res Function(SyncStatePayload) _then;

  /// Create a copy of SyncStatePayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? session = null,
  }) {
    return _then(_self.copyWith(
      session: null == session
          ? _self.session
          : session // ignore: cast_nullable_to_non_nullable
              as GameSession,
    ));
  }

  /// Create a copy of SyncStatePayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GameSessionCopyWith<$Res> get session {
    return $GameSessionCopyWith<$Res>(_self.session, (value) {
      return _then(_self.copyWith(session: value));
    });
  }
}

/// Adds pattern-matching-related methods to [SyncStatePayload].
extension SyncStatePayloadPatterns on SyncStatePayload {
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
    TResult Function(_SyncStatePayload value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SyncStatePayload() when $default != null:
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
    TResult Function(_SyncStatePayload value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SyncStatePayload():
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
    TResult? Function(_SyncStatePayload value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SyncStatePayload() when $default != null:
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
    TResult Function(GameSession session)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SyncStatePayload() when $default != null:
        return $default(_that.session);
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
    TResult Function(GameSession session) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SyncStatePayload():
        return $default(_that.session);
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
    TResult? Function(GameSession session)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SyncStatePayload() when $default != null:
        return $default(_that.session);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _SyncStatePayload extends SyncStatePayload {
  const _SyncStatePayload({required this.session}) : super._();
  factory _SyncStatePayload.fromJson(Map<String, dynamic> json) =>
      _$SyncStatePayloadFromJson(json);

  @override
  final GameSession session;

  /// Create a copy of SyncStatePayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SyncStatePayloadCopyWith<_SyncStatePayload> get copyWith =>
      __$SyncStatePayloadCopyWithImpl<_SyncStatePayload>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SyncStatePayloadToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SyncStatePayload &&
            (identical(other.session, session) || other.session == session));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, session);

  @override
  String toString() {
    return 'SyncStatePayload(session: $session)';
  }
}

/// @nodoc
abstract mixin class _$SyncStatePayloadCopyWith<$Res>
    implements $SyncStatePayloadCopyWith<$Res> {
  factory _$SyncStatePayloadCopyWith(
          _SyncStatePayload value, $Res Function(_SyncStatePayload) _then) =
      __$SyncStatePayloadCopyWithImpl;
  @override
  @useResult
  $Res call({GameSession session});

  @override
  $GameSessionCopyWith<$Res> get session;
}

/// @nodoc
class __$SyncStatePayloadCopyWithImpl<$Res>
    implements _$SyncStatePayloadCopyWith<$Res> {
  __$SyncStatePayloadCopyWithImpl(this._self, this._then);

  final _SyncStatePayload _self;
  final $Res Function(_SyncStatePayload) _then;

  /// Create a copy of SyncStatePayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? session = null,
  }) {
    return _then(_SyncStatePayload(
      session: null == session
          ? _self.session
          : session // ignore: cast_nullable_to_non_nullable
              as GameSession,
    ));
  }

  /// Create a copy of SyncStatePayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GameSessionCopyWith<$Res> get session {
    return $GameSessionCopyWith<$Res>(_self.session, (value) {
      return _then(_self.copyWith(session: value));
    });
  }
}

/// @nodoc
mixin _$UpdateScorePayload {
  String get playerId; // 玩家ID
  int get roundIndex; // 轮次索引 (0-based, 与 PlayerScore.roundScores 列表索引一致)
  int? get score;

  /// Create a copy of UpdateScorePayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $UpdateScorePayloadCopyWith<UpdateScorePayload> get copyWith =>
      _$UpdateScorePayloadCopyWithImpl<UpdateScorePayload>(
          this as UpdateScorePayload, _$identity);

  /// Serializes this UpdateScorePayload to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is UpdateScorePayload &&
            (identical(other.playerId, playerId) ||
                other.playerId == playerId) &&
            (identical(other.roundIndex, roundIndex) ||
                other.roundIndex == roundIndex) &&
            (identical(other.score, score) || other.score == score));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, playerId, roundIndex, score);

  @override
  String toString() {
    return 'UpdateScorePayload(playerId: $playerId, roundIndex: $roundIndex, score: $score)';
  }
}

/// @nodoc
abstract mixin class $UpdateScorePayloadCopyWith<$Res> {
  factory $UpdateScorePayloadCopyWith(
          UpdateScorePayload value, $Res Function(UpdateScorePayload) _then) =
      _$UpdateScorePayloadCopyWithImpl;
  @useResult
  $Res call({String playerId, int roundIndex, int? score});
}

/// @nodoc
class _$UpdateScorePayloadCopyWithImpl<$Res>
    implements $UpdateScorePayloadCopyWith<$Res> {
  _$UpdateScorePayloadCopyWithImpl(this._self, this._then);

  final UpdateScorePayload _self;
  final $Res Function(UpdateScorePayload) _then;

  /// Create a copy of UpdateScorePayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerId = null,
    Object? roundIndex = null,
    Object? score = freezed,
  }) {
    return _then(_self.copyWith(
      playerId: null == playerId
          ? _self.playerId
          : playerId // ignore: cast_nullable_to_non_nullable
              as String,
      roundIndex: null == roundIndex
          ? _self.roundIndex
          : roundIndex // ignore: cast_nullable_to_non_nullable
              as int,
      score: freezed == score
          ? _self.score
          : score // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// Adds pattern-matching-related methods to [UpdateScorePayload].
extension UpdateScorePayloadPatterns on UpdateScorePayload {
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
    TResult Function(_UpdateScorePayload value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UpdateScorePayload() when $default != null:
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
    TResult Function(_UpdateScorePayload value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UpdateScorePayload():
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
    TResult? Function(_UpdateScorePayload value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UpdateScorePayload() when $default != null:
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
    TResult Function(String playerId, int roundIndex, int? score)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UpdateScorePayload() when $default != null:
        return $default(_that.playerId, _that.roundIndex, _that.score);
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
    TResult Function(String playerId, int roundIndex, int? score) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UpdateScorePayload():
        return $default(_that.playerId, _that.roundIndex, _that.score);
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
    TResult? Function(String playerId, int roundIndex, int? score)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UpdateScorePayload() when $default != null:
        return $default(_that.playerId, _that.roundIndex, _that.score);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _UpdateScorePayload extends UpdateScorePayload {
  const _UpdateScorePayload(
      {required this.playerId, required this.roundIndex, required this.score})
      : super._();
  factory _UpdateScorePayload.fromJson(Map<String, dynamic> json) =>
      _$UpdateScorePayloadFromJson(json);

  @override
  final String playerId;
// 玩家ID
  @override
  final int roundIndex;
// 轮次索引 (0-based, 与 PlayerScore.roundScores 列表索引一致)
  @override
  final int? score;

  /// Create a copy of UpdateScorePayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$UpdateScorePayloadCopyWith<_UpdateScorePayload> get copyWith =>
      __$UpdateScorePayloadCopyWithImpl<_UpdateScorePayload>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$UpdateScorePayloadToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _UpdateScorePayload &&
            (identical(other.playerId, playerId) ||
                other.playerId == playerId) &&
            (identical(other.roundIndex, roundIndex) ||
                other.roundIndex == roundIndex) &&
            (identical(other.score, score) || other.score == score));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, playerId, roundIndex, score);

  @override
  String toString() {
    return 'UpdateScorePayload(playerId: $playerId, roundIndex: $roundIndex, score: $score)';
  }
}

/// @nodoc
abstract mixin class _$UpdateScorePayloadCopyWith<$Res>
    implements $UpdateScorePayloadCopyWith<$Res> {
  factory _$UpdateScorePayloadCopyWith(
          _UpdateScorePayload value, $Res Function(_UpdateScorePayload) _then) =
      __$UpdateScorePayloadCopyWithImpl;
  @override
  @useResult
  $Res call({String playerId, int roundIndex, int? score});
}

/// @nodoc
class __$UpdateScorePayloadCopyWithImpl<$Res>
    implements _$UpdateScorePayloadCopyWith<$Res> {
  __$UpdateScorePayloadCopyWithImpl(this._self, this._then);

  final _UpdateScorePayload _self;
  final $Res Function(_UpdateScorePayload) _then;

  /// Create a copy of UpdateScorePayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? playerId = null,
    Object? roundIndex = null,
    Object? score = freezed,
  }) {
    return _then(_UpdateScorePayload(
      playerId: null == playerId
          ? _self.playerId
          : playerId // ignore: cast_nullable_to_non_nullable
              as String,
      roundIndex: null == roundIndex
          ? _self.roundIndex
          : roundIndex // ignore: cast_nullable_to_non_nullable
              as int,
      score: freezed == score
          ? _self.score
          : score // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
mixin _$NewRoundPayload {
// 可以包含新回合的起始信息，例如新的回合索引 (0-based)
// roundIndex 是指添加新回合后，总的回合数-1，即新回合的索引
  int get newRoundIndex;

  /// Create a copy of NewRoundPayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $NewRoundPayloadCopyWith<NewRoundPayload> get copyWith =>
      _$NewRoundPayloadCopyWithImpl<NewRoundPayload>(
          this as NewRoundPayload, _$identity);

  /// Serializes this NewRoundPayload to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is NewRoundPayload &&
            (identical(other.newRoundIndex, newRoundIndex) ||
                other.newRoundIndex == newRoundIndex));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, newRoundIndex);

  @override
  String toString() {
    return 'NewRoundPayload(newRoundIndex: $newRoundIndex)';
  }
}

/// @nodoc
abstract mixin class $NewRoundPayloadCopyWith<$Res> {
  factory $NewRoundPayloadCopyWith(
          NewRoundPayload value, $Res Function(NewRoundPayload) _then) =
      _$NewRoundPayloadCopyWithImpl;
  @useResult
  $Res call({int newRoundIndex});
}

/// @nodoc
class _$NewRoundPayloadCopyWithImpl<$Res>
    implements $NewRoundPayloadCopyWith<$Res> {
  _$NewRoundPayloadCopyWithImpl(this._self, this._then);

  final NewRoundPayload _self;
  final $Res Function(NewRoundPayload) _then;

  /// Create a copy of NewRoundPayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? newRoundIndex = null,
  }) {
    return _then(_self.copyWith(
      newRoundIndex: null == newRoundIndex
          ? _self.newRoundIndex
          : newRoundIndex // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [NewRoundPayload].
extension NewRoundPayloadPatterns on NewRoundPayload {
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
    TResult Function(_NewRoundPayload value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _NewRoundPayload() when $default != null:
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
    TResult Function(_NewRoundPayload value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NewRoundPayload():
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
    TResult? Function(_NewRoundPayload value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NewRoundPayload() when $default != null:
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
    TResult Function(int newRoundIndex)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _NewRoundPayload() when $default != null:
        return $default(_that.newRoundIndex);
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
    TResult Function(int newRoundIndex) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NewRoundPayload():
        return $default(_that.newRoundIndex);
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
    TResult? Function(int newRoundIndex)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NewRoundPayload() when $default != null:
        return $default(_that.newRoundIndex);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _NewRoundPayload extends NewRoundPayload {
  const _NewRoundPayload({required this.newRoundIndex}) : super._();
  factory _NewRoundPayload.fromJson(Map<String, dynamic> json) =>
      _$NewRoundPayloadFromJson(json);

// 可以包含新回合的起始信息，例如新的回合索引 (0-based)
// roundIndex 是指添加新回合后，总的回合数-1，即新回合的索引
  @override
  final int newRoundIndex;

  /// Create a copy of NewRoundPayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$NewRoundPayloadCopyWith<_NewRoundPayload> get copyWith =>
      __$NewRoundPayloadCopyWithImpl<_NewRoundPayload>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$NewRoundPayloadToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _NewRoundPayload &&
            (identical(other.newRoundIndex, newRoundIndex) ||
                other.newRoundIndex == newRoundIndex));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, newRoundIndex);

  @override
  String toString() {
    return 'NewRoundPayload(newRoundIndex: $newRoundIndex)';
  }
}

/// @nodoc
abstract mixin class _$NewRoundPayloadCopyWith<$Res>
    implements $NewRoundPayloadCopyWith<$Res> {
  factory _$NewRoundPayloadCopyWith(
          _NewRoundPayload value, $Res Function(_NewRoundPayload) _then) =
      __$NewRoundPayloadCopyWithImpl;
  @override
  @useResult
  $Res call({int newRoundIndex});
}

/// @nodoc
class __$NewRoundPayloadCopyWithImpl<$Res>
    implements _$NewRoundPayloadCopyWith<$Res> {
  __$NewRoundPayloadCopyWithImpl(this._self, this._then);

  final _NewRoundPayload _self;
  final $Res Function(_NewRoundPayload) _then;

  /// Create a copy of NewRoundPayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? newRoundIndex = null,
  }) {
    return _then(_NewRoundPayload(
      newRoundIndex: null == newRoundIndex
          ? _self.newRoundIndex
          : newRoundIndex // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
mixin _$ResetGamePayload {
  /// Serializes this ResetGamePayload to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is ResetGamePayload);
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'ResetGamePayload()';
  }
}

/// @nodoc
class $ResetGamePayloadCopyWith<$Res> {
  $ResetGamePayloadCopyWith(
      ResetGamePayload _, $Res Function(ResetGamePayload) __);
}

/// Adds pattern-matching-related methods to [ResetGamePayload].
extension ResetGamePayloadPatterns on ResetGamePayload {
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
    TResult Function(_ResetGamePayload value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ResetGamePayload() when $default != null:
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
    TResult Function(_ResetGamePayload value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ResetGamePayload():
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
    TResult? Function(_ResetGamePayload value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ResetGamePayload() when $default != null:
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
    TResult Function()? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ResetGamePayload() when $default != null:
        return $default();
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
    TResult Function() $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ResetGamePayload():
        return $default();
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
    TResult? Function()? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ResetGamePayload() when $default != null:
        return $default();
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ResetGamePayload extends ResetGamePayload {
  const _ResetGamePayload() : super._();
  factory _ResetGamePayload.fromJson(Map<String, dynamic> json) =>
      _$ResetGamePayloadFromJson(json);

  @override
  Map<String, dynamic> toJson() {
    return _$ResetGamePayloadToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _ResetGamePayload);
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'ResetGamePayload()';
  }
}

/// @nodoc
mixin _$HostDisconnectPayload {
  String? get reason;

  /// Create a copy of HostDisconnectPayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $HostDisconnectPayloadCopyWith<HostDisconnectPayload> get copyWith =>
      _$HostDisconnectPayloadCopyWithImpl<HostDisconnectPayload>(
          this as HostDisconnectPayload, _$identity);

  /// Serializes this HostDisconnectPayload to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is HostDisconnectPayload &&
            (identical(other.reason, reason) || other.reason == reason));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, reason);

  @override
  String toString() {
    return 'HostDisconnectPayload(reason: $reason)';
  }
}

/// @nodoc
abstract mixin class $HostDisconnectPayloadCopyWith<$Res> {
  factory $HostDisconnectPayloadCopyWith(HostDisconnectPayload value,
          $Res Function(HostDisconnectPayload) _then) =
      _$HostDisconnectPayloadCopyWithImpl;
  @useResult
  $Res call({String? reason});
}

/// @nodoc
class _$HostDisconnectPayloadCopyWithImpl<$Res>
    implements $HostDisconnectPayloadCopyWith<$Res> {
  _$HostDisconnectPayloadCopyWithImpl(this._self, this._then);

  final HostDisconnectPayload _self;
  final $Res Function(HostDisconnectPayload) _then;

  /// Create a copy of HostDisconnectPayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reason = freezed,
  }) {
    return _then(_self.copyWith(
      reason: freezed == reason
          ? _self.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [HostDisconnectPayload].
extension HostDisconnectPayloadPatterns on HostDisconnectPayload {
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
    TResult Function(_HostDisconnectPayload value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HostDisconnectPayload() when $default != null:
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
    TResult Function(_HostDisconnectPayload value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HostDisconnectPayload():
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
    TResult? Function(_HostDisconnectPayload value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HostDisconnectPayload() when $default != null:
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
    TResult Function(String? reason)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HostDisconnectPayload() when $default != null:
        return $default(_that.reason);
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
    TResult Function(String? reason) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HostDisconnectPayload():
        return $default(_that.reason);
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
    TResult? Function(String? reason)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HostDisconnectPayload() when $default != null:
        return $default(_that.reason);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _HostDisconnectPayload extends HostDisconnectPayload {
  const _HostDisconnectPayload({this.reason}) : super._();
  factory _HostDisconnectPayload.fromJson(Map<String, dynamic> json) =>
      _$HostDisconnectPayloadFromJson(json);

  @override
  final String? reason;

  /// Create a copy of HostDisconnectPayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$HostDisconnectPayloadCopyWith<_HostDisconnectPayload> get copyWith =>
      __$HostDisconnectPayloadCopyWithImpl<_HostDisconnectPayload>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$HostDisconnectPayloadToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _HostDisconnectPayload &&
            (identical(other.reason, reason) || other.reason == reason));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, reason);

  @override
  String toString() {
    return 'HostDisconnectPayload(reason: $reason)';
  }
}

/// @nodoc
abstract mixin class _$HostDisconnectPayloadCopyWith<$Res>
    implements $HostDisconnectPayloadCopyWith<$Res> {
  factory _$HostDisconnectPayloadCopyWith(_HostDisconnectPayload value,
          $Res Function(_HostDisconnectPayload) _then) =
      __$HostDisconnectPayloadCopyWithImpl;
  @override
  @useResult
  $Res call({String? reason});
}

/// @nodoc
class __$HostDisconnectPayloadCopyWithImpl<$Res>
    implements _$HostDisconnectPayloadCopyWith<$Res> {
  __$HostDisconnectPayloadCopyWithImpl(this._self, this._then);

  final _HostDisconnectPayload _self;
  final $Res Function(_HostDisconnectPayload) _then;

  /// Create a copy of HostDisconnectPayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? reason = freezed,
  }) {
    return _then(_HostDisconnectPayload(
      reason: freezed == reason
          ? _self.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$GameEndPayload {
  /// Serializes this GameEndPayload to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is GameEndPayload);
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'GameEndPayload()';
  }
}

/// @nodoc
class $GameEndPayloadCopyWith<$Res> {
  $GameEndPayloadCopyWith(GameEndPayload _, $Res Function(GameEndPayload) __);
}

/// Adds pattern-matching-related methods to [GameEndPayload].
extension GameEndPayloadPatterns on GameEndPayload {
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
    TResult Function(_GameEndPayload value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _GameEndPayload() when $default != null:
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
    TResult Function(_GameEndPayload value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GameEndPayload():
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
    TResult? Function(_GameEndPayload value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GameEndPayload() when $default != null:
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
    TResult Function()? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _GameEndPayload() when $default != null:
        return $default();
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
    TResult Function() $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GameEndPayload():
        return $default();
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
    TResult? Function()? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GameEndPayload() when $default != null:
        return $default();
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _GameEndPayload extends GameEndPayload {
  const _GameEndPayload() : super._();
  factory _GameEndPayload.fromJson(Map<String, dynamic> json) =>
      _$GameEndPayloadFromJson(json);

  @override
  Map<String, dynamic> toJson() {
    return _$GameEndPayloadToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _GameEndPayload);
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'GameEndPayload()';
  }
}

// dart format on
