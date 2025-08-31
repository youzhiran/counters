// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'league.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$League {
  String get lid;
  String get name;
  LeagueType get type;
  List<String> get playerIds;
  List<Match> get matches;
  String get defaultTemplateId; // Round-robin specific settings
  int get pointsForWin;
  int get pointsForDraw;
  int get pointsForLoss; // Knockout specific settings
  int? get currentRound;

  /// Create a copy of League
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LeagueCopyWith<League> get copyWith =>
      _$LeagueCopyWithImpl<League>(this as League, _$identity);

  /// Serializes this League to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is League &&
            (identical(other.lid, lid) || other.lid == lid) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality().equals(other.playerIds, playerIds) &&
            const DeepCollectionEquality().equals(other.matches, matches) &&
            (identical(other.defaultTemplateId, defaultTemplateId) ||
                other.defaultTemplateId == defaultTemplateId) &&
            (identical(other.pointsForWin, pointsForWin) ||
                other.pointsForWin == pointsForWin) &&
            (identical(other.pointsForDraw, pointsForDraw) ||
                other.pointsForDraw == pointsForDraw) &&
            (identical(other.pointsForLoss, pointsForLoss) ||
                other.pointsForLoss == pointsForLoss) &&
            (identical(other.currentRound, currentRound) ||
                other.currentRound == currentRound));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      lid,
      name,
      type,
      const DeepCollectionEquality().hash(playerIds),
      const DeepCollectionEquality().hash(matches),
      defaultTemplateId,
      pointsForWin,
      pointsForDraw,
      pointsForLoss,
      currentRound);

  @override
  String toString() {
    return 'League(lid: $lid, name: $name, type: $type, playerIds: $playerIds, matches: $matches, defaultTemplateId: $defaultTemplateId, pointsForWin: $pointsForWin, pointsForDraw: $pointsForDraw, pointsForLoss: $pointsForLoss, currentRound: $currentRound)';
  }
}

/// @nodoc
abstract mixin class $LeagueCopyWith<$Res> {
  factory $LeagueCopyWith(League value, $Res Function(League) _then) =
      _$LeagueCopyWithImpl;
  @useResult
  $Res call(
      {String lid,
      String name,
      LeagueType type,
      List<String> playerIds,
      List<Match> matches,
      String defaultTemplateId,
      int pointsForWin,
      int pointsForDraw,
      int pointsForLoss,
      int? currentRound});
}

/// @nodoc
class _$LeagueCopyWithImpl<$Res> implements $LeagueCopyWith<$Res> {
  _$LeagueCopyWithImpl(this._self, this._then);

  final League _self;
  final $Res Function(League) _then;

  /// Create a copy of League
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lid = null,
    Object? name = null,
    Object? type = null,
    Object? playerIds = null,
    Object? matches = null,
    Object? defaultTemplateId = null,
    Object? pointsForWin = null,
    Object? pointsForDraw = null,
    Object? pointsForLoss = null,
    Object? currentRound = freezed,
  }) {
    return _then(_self.copyWith(
      lid: null == lid
          ? _self.lid
          : lid // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as LeagueType,
      playerIds: null == playerIds
          ? _self.playerIds
          : playerIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      matches: null == matches
          ? _self.matches
          : matches // ignore: cast_nullable_to_non_nullable
              as List<Match>,
      defaultTemplateId: null == defaultTemplateId
          ? _self.defaultTemplateId
          : defaultTemplateId // ignore: cast_nullable_to_non_nullable
              as String,
      pointsForWin: null == pointsForWin
          ? _self.pointsForWin
          : pointsForWin // ignore: cast_nullable_to_non_nullable
              as int,
      pointsForDraw: null == pointsForDraw
          ? _self.pointsForDraw
          : pointsForDraw // ignore: cast_nullable_to_non_nullable
              as int,
      pointsForLoss: null == pointsForLoss
          ? _self.pointsForLoss
          : pointsForLoss // ignore: cast_nullable_to_non_nullable
              as int,
      currentRound: freezed == currentRound
          ? _self.currentRound
          : currentRound // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// Adds pattern-matching-related methods to [League].
extension LeaguePatterns on League {
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
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_League value)? internal,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _League() when internal != null:
        return internal(_that);
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
  TResult map<TResult extends Object?>({
    required TResult Function(_League value) internal,
  }) {
    final _that = this;
    switch (_that) {
      case _League():
        return internal(_that);
      case _:
        throw StateError('Unexpected subclass');
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
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_League value)? internal,
  }) {
    final _that = this;
    switch (_that) {
      case _League() when internal != null:
        return internal(_that);
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
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String lid,
            String name,
            LeagueType type,
            List<String> playerIds,
            List<Match> matches,
            String defaultTemplateId,
            int pointsForWin,
            int pointsForDraw,
            int pointsForLoss,
            int? currentRound)?
        internal,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _League() when internal != null:
        return internal(
            _that.lid,
            _that.name,
            _that.type,
            _that.playerIds,
            _that.matches,
            _that.defaultTemplateId,
            _that.pointsForWin,
            _that.pointsForDraw,
            _that.pointsForLoss,
            _that.currentRound);
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
  TResult when<TResult extends Object?>({
    required TResult Function(
            String lid,
            String name,
            LeagueType type,
            List<String> playerIds,
            List<Match> matches,
            String defaultTemplateId,
            int pointsForWin,
            int pointsForDraw,
            int pointsForLoss,
            int? currentRound)
        internal,
  }) {
    final _that = this;
    switch (_that) {
      case _League():
        return internal(
            _that.lid,
            _that.name,
            _that.type,
            _that.playerIds,
            _that.matches,
            _that.defaultTemplateId,
            _that.pointsForWin,
            _that.pointsForDraw,
            _that.pointsForLoss,
            _that.currentRound);
      case _:
        throw StateError('Unexpected subclass');
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
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String lid,
            String name,
            LeagueType type,
            List<String> playerIds,
            List<Match> matches,
            String defaultTemplateId,
            int pointsForWin,
            int pointsForDraw,
            int pointsForLoss,
            int? currentRound)?
        internal,
  }) {
    final _that = this;
    switch (_that) {
      case _League() when internal != null:
        return internal(
            _that.lid,
            _that.name,
            _that.type,
            _that.playerIds,
            _that.matches,
            _that.defaultTemplateId,
            _that.pointsForWin,
            _that.pointsForDraw,
            _that.pointsForLoss,
            _that.currentRound);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _League implements League {
  const _League(
      {required this.lid,
      required this.name,
      required this.type,
      required final List<String> playerIds,
      required final List<Match> matches,
      required this.defaultTemplateId,
      this.pointsForWin = 3,
      this.pointsForDraw = 1,
      this.pointsForLoss = 0,
      this.currentRound})
      : _playerIds = playerIds,
        _matches = matches;
  factory _League.fromJson(Map<String, dynamic> json) => _$LeagueFromJson(json);

  @override
  final String lid;
  @override
  final String name;
  @override
  final LeagueType type;
  final List<String> _playerIds;
  @override
  List<String> get playerIds {
    if (_playerIds is EqualUnmodifiableListView) return _playerIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_playerIds);
  }

  final List<Match> _matches;
  @override
  List<Match> get matches {
    if (_matches is EqualUnmodifiableListView) return _matches;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_matches);
  }

  @override
  final String defaultTemplateId;
// Round-robin specific settings
  @override
  @JsonKey()
  final int pointsForWin;
  @override
  @JsonKey()
  final int pointsForDraw;
  @override
  @JsonKey()
  final int pointsForLoss;
// Knockout specific settings
  @override
  final int? currentRound;

  /// Create a copy of League
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$LeagueCopyWith<_League> get copyWith =>
      __$LeagueCopyWithImpl<_League>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$LeagueToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _League &&
            (identical(other.lid, lid) || other.lid == lid) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality()
                .equals(other._playerIds, _playerIds) &&
            const DeepCollectionEquality().equals(other._matches, _matches) &&
            (identical(other.defaultTemplateId, defaultTemplateId) ||
                other.defaultTemplateId == defaultTemplateId) &&
            (identical(other.pointsForWin, pointsForWin) ||
                other.pointsForWin == pointsForWin) &&
            (identical(other.pointsForDraw, pointsForDraw) ||
                other.pointsForDraw == pointsForDraw) &&
            (identical(other.pointsForLoss, pointsForLoss) ||
                other.pointsForLoss == pointsForLoss) &&
            (identical(other.currentRound, currentRound) ||
                other.currentRound == currentRound));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      lid,
      name,
      type,
      const DeepCollectionEquality().hash(_playerIds),
      const DeepCollectionEquality().hash(_matches),
      defaultTemplateId,
      pointsForWin,
      pointsForDraw,
      pointsForLoss,
      currentRound);

  @override
  String toString() {
    return 'League.internal(lid: $lid, name: $name, type: $type, playerIds: $playerIds, matches: $matches, defaultTemplateId: $defaultTemplateId, pointsForWin: $pointsForWin, pointsForDraw: $pointsForDraw, pointsForLoss: $pointsForLoss, currentRound: $currentRound)';
  }
}

/// @nodoc
abstract mixin class _$LeagueCopyWith<$Res> implements $LeagueCopyWith<$Res> {
  factory _$LeagueCopyWith(_League value, $Res Function(_League) _then) =
      __$LeagueCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String lid,
      String name,
      LeagueType type,
      List<String> playerIds,
      List<Match> matches,
      String defaultTemplateId,
      int pointsForWin,
      int pointsForDraw,
      int pointsForLoss,
      int? currentRound});
}

/// @nodoc
class __$LeagueCopyWithImpl<$Res> implements _$LeagueCopyWith<$Res> {
  __$LeagueCopyWithImpl(this._self, this._then);

  final _League _self;
  final $Res Function(_League) _then;

  /// Create a copy of League
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? lid = null,
    Object? name = null,
    Object? type = null,
    Object? playerIds = null,
    Object? matches = null,
    Object? defaultTemplateId = null,
    Object? pointsForWin = null,
    Object? pointsForDraw = null,
    Object? pointsForLoss = null,
    Object? currentRound = freezed,
  }) {
    return _then(_League(
      lid: null == lid
          ? _self.lid
          : lid // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as LeagueType,
      playerIds: null == playerIds
          ? _self._playerIds
          : playerIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      matches: null == matches
          ? _self._matches
          : matches // ignore: cast_nullable_to_non_nullable
              as List<Match>,
      defaultTemplateId: null == defaultTemplateId
          ? _self.defaultTemplateId
          : defaultTemplateId // ignore: cast_nullable_to_non_nullable
              as String,
      pointsForWin: null == pointsForWin
          ? _self.pointsForWin
          : pointsForWin // ignore: cast_nullable_to_non_nullable
              as int,
      pointsForDraw: null == pointsForDraw
          ? _self.pointsForDraw
          : pointsForDraw // ignore: cast_nullable_to_non_nullable
              as int,
      pointsForLoss: null == pointsForLoss
          ? _self.pointsForLoss
          : pointsForLoss // ignore: cast_nullable_to_non_nullable
              as int,
      currentRound: freezed == currentRound
          ? _self.currentRound
          : currentRound // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

// dart format on
