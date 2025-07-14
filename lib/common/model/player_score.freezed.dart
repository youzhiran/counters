// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player_score.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlayerScore {
  String get playerId; // 玩家唯一ID
// 回合得分列表。List<int?> 可以被 json_serializable 直接处理为 JSON 数组。
// @Default([]) 表示如果 JSON 中没有这个字段或者为 null，则默认值为 []。
  List<int?>
      get roundScores; // 按回合存储的扩展字段。Map<int, Map<String, dynamic>> 可以被 json_serializable 处理为 JSON 对象。
// 注意：JSON 的 key 必须是字符串，json_serializable 会自动将 int key 转换为字符串。
// @Default({}) 表示如果 JSON 中没有这个字段或者为 null，则默认值为 {}。
  Map<int, Map<String, dynamic>> get roundExtendedFields;

  /// Create a copy of PlayerScore
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PlayerScoreCopyWith<PlayerScore> get copyWith =>
      _$PlayerScoreCopyWithImpl<PlayerScore>(this as PlayerScore, _$identity);

  /// Serializes this PlayerScore to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PlayerScore &&
            (identical(other.playerId, playerId) ||
                other.playerId == playerId) &&
            const DeepCollectionEquality()
                .equals(other.roundScores, roundScores) &&
            const DeepCollectionEquality()
                .equals(other.roundExtendedFields, roundExtendedFields));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      playerId,
      const DeepCollectionEquality().hash(roundScores),
      const DeepCollectionEquality().hash(roundExtendedFields));

  @override
  String toString() {
    return 'PlayerScore(playerId: $playerId, roundScores: $roundScores, roundExtendedFields: $roundExtendedFields)';
  }
}

/// @nodoc
abstract mixin class $PlayerScoreCopyWith<$Res> {
  factory $PlayerScoreCopyWith(
          PlayerScore value, $Res Function(PlayerScore) _then) =
      _$PlayerScoreCopyWithImpl;
  @useResult
  $Res call(
      {String playerId,
      List<int?> roundScores,
      Map<int, Map<String, dynamic>> roundExtendedFields});
}

/// @nodoc
class _$PlayerScoreCopyWithImpl<$Res> implements $PlayerScoreCopyWith<$Res> {
  _$PlayerScoreCopyWithImpl(this._self, this._then);

  final PlayerScore _self;
  final $Res Function(PlayerScore) _then;

  /// Create a copy of PlayerScore
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerId = null,
    Object? roundScores = null,
    Object? roundExtendedFields = null,
  }) {
    return _then(_self.copyWith(
      playerId: null == playerId
          ? _self.playerId
          : playerId // ignore: cast_nullable_to_non_nullable
              as String,
      roundScores: null == roundScores
          ? _self.roundScores
          : roundScores // ignore: cast_nullable_to_non_nullable
              as List<int?>,
      roundExtendedFields: null == roundExtendedFields
          ? _self.roundExtendedFields
          : roundExtendedFields // ignore: cast_nullable_to_non_nullable
              as Map<int, Map<String, dynamic>>,
    ));
  }
}

/// Adds pattern-matching-related methods to [PlayerScore].
extension PlayerScorePatterns on PlayerScore {
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
    TResult Function(_PlayerScore value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PlayerScore() when $default != null:
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
    TResult Function(_PlayerScore value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlayerScore():
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
    TResult? Function(_PlayerScore value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlayerScore() when $default != null:
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
    TResult Function(String playerId, List<int?> roundScores,
            Map<int, Map<String, dynamic>> roundExtendedFields)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PlayerScore() when $default != null:
        return $default(
            _that.playerId, _that.roundScores, _that.roundExtendedFields);
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
    TResult Function(String playerId, List<int?> roundScores,
            Map<int, Map<String, dynamic>> roundExtendedFields)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlayerScore():
        return $default(
            _that.playerId, _that.roundScores, _that.roundExtendedFields);
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
    TResult? Function(String playerId, List<int?> roundScores,
            Map<int, Map<String, dynamic>> roundExtendedFields)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlayerScore() when $default != null:
        return $default(
            _that.playerId, _that.roundScores, _that.roundExtendedFields);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _PlayerScore extends PlayerScore {
  const _PlayerScore(
      {required this.playerId,
      final List<int?> roundScores = const [],
      final Map<int, Map<String, dynamic>> roundExtendedFields = const {}})
      : _roundScores = roundScores,
        _roundExtendedFields = roundExtendedFields,
        super._();
  factory _PlayerScore.fromJson(Map<String, dynamic> json) =>
      _$PlayerScoreFromJson(json);

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

  /// Create a copy of PlayerScore
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PlayerScoreCopyWith<_PlayerScore> get copyWith =>
      __$PlayerScoreCopyWithImpl<_PlayerScore>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PlayerScoreToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PlayerScore &&
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

  @override
  String toString() {
    return 'PlayerScore(playerId: $playerId, roundScores: $roundScores, roundExtendedFields: $roundExtendedFields)';
  }
}

/// @nodoc
abstract mixin class _$PlayerScoreCopyWith<$Res>
    implements $PlayerScoreCopyWith<$Res> {
  factory _$PlayerScoreCopyWith(
          _PlayerScore value, $Res Function(_PlayerScore) _then) =
      __$PlayerScoreCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String playerId,
      List<int?> roundScores,
      Map<int, Map<String, dynamic>> roundExtendedFields});
}

/// @nodoc
class __$PlayerScoreCopyWithImpl<$Res> implements _$PlayerScoreCopyWith<$Res> {
  __$PlayerScoreCopyWithImpl(this._self, this._then);

  final _PlayerScore _self;
  final $Res Function(_PlayerScore) _then;

  /// Create a copy of PlayerScore
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? playerId = null,
    Object? roundScores = null,
    Object? roundExtendedFields = null,
  }) {
    return _then(_PlayerScore(
      playerId: null == playerId
          ? _self.playerId
          : playerId // ignore: cast_nullable_to_non_nullable
              as String,
      roundScores: null == roundScores
          ? _self._roundScores
          : roundScores // ignore: cast_nullable_to_non_nullable
              as List<int?>,
      roundExtendedFields: null == roundExtendedFields
          ? _self._roundExtendedFields
          : roundExtendedFields // ignore: cast_nullable_to_non_nullable
              as Map<int, Map<String, dynamic>>,
    ));
  }
}

// dart format on
