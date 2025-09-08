// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Match {
  String get mid;
  String get leagueId;
  int get round;
  String get player1Id;
  String? get player2Id; // 在淘汰赛中，选手2可能稍后确定
  MatchStatus get status;
  int? get player1Score;
  int? get player2Score;
  String? get winnerId;
  String? get templateId; // 本场比赛使用的计分模板
  DateTime? get startTime;
  DateTime? get endTime;
  BracketType? get bracketType;

  /// Create a copy of Match
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MatchCopyWith<Match> get copyWith =>
      _$MatchCopyWithImpl<Match>(this as Match, _$identity);

  /// Serializes this Match to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Match &&
            (identical(other.mid, mid) || other.mid == mid) &&
            (identical(other.leagueId, leagueId) ||
                other.leagueId == leagueId) &&
            (identical(other.round, round) || other.round == round) &&
            (identical(other.player1Id, player1Id) ||
                other.player1Id == player1Id) &&
            (identical(other.player2Id, player2Id) ||
                other.player2Id == player2Id) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.player1Score, player1Score) ||
                other.player1Score == player1Score) &&
            (identical(other.player2Score, player2Score) ||
                other.player2Score == player2Score) &&
            (identical(other.winnerId, winnerId) ||
                other.winnerId == winnerId) &&
            (identical(other.templateId, templateId) ||
                other.templateId == templateId) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.bracketType, bracketType) ||
                other.bracketType == bracketType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      mid,
      leagueId,
      round,
      player1Id,
      player2Id,
      status,
      player1Score,
      player2Score,
      winnerId,
      templateId,
      startTime,
      endTime,
      bracketType);

  @override
  String toString() {
    return 'Match(mid: $mid, leagueId: $leagueId, round: $round, player1Id: $player1Id, player2Id: $player2Id, status: $status, player1Score: $player1Score, player2Score: $player2Score, winnerId: $winnerId, templateId: $templateId, startTime: $startTime, endTime: $endTime, bracketType: $bracketType)';
  }
}

/// @nodoc
abstract mixin class $MatchCopyWith<$Res> {
  factory $MatchCopyWith(Match value, $Res Function(Match) _then) =
      _$MatchCopyWithImpl;
  @useResult
  $Res call(
      {String mid,
      String leagueId,
      int round,
      String player1Id,
      String? player2Id,
      MatchStatus status,
      int? player1Score,
      int? player2Score,
      String? winnerId,
      String? templateId,
      DateTime? startTime,
      DateTime? endTime,
      BracketType? bracketType});
}

/// @nodoc
class _$MatchCopyWithImpl<$Res> implements $MatchCopyWith<$Res> {
  _$MatchCopyWithImpl(this._self, this._then);

  final Match _self;
  final $Res Function(Match) _then;

  /// Create a copy of Match
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mid = null,
    Object? leagueId = null,
    Object? round = null,
    Object? player1Id = null,
    Object? player2Id = freezed,
    Object? status = null,
    Object? player1Score = freezed,
    Object? player2Score = freezed,
    Object? winnerId = freezed,
    Object? templateId = freezed,
    Object? startTime = freezed,
    Object? endTime = freezed,
    Object? bracketType = freezed,
  }) {
    return _then(_self.copyWith(
      mid: null == mid
          ? _self.mid
          : mid // ignore: cast_nullable_to_non_nullable
              as String,
      leagueId: null == leagueId
          ? _self.leagueId
          : leagueId // ignore: cast_nullable_to_non_nullable
              as String,
      round: null == round
          ? _self.round
          : round // ignore: cast_nullable_to_non_nullable
              as int,
      player1Id: null == player1Id
          ? _self.player1Id
          : player1Id // ignore: cast_nullable_to_non_nullable
              as String,
      player2Id: freezed == player2Id
          ? _self.player2Id
          : player2Id // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as MatchStatus,
      player1Score: freezed == player1Score
          ? _self.player1Score
          : player1Score // ignore: cast_nullable_to_non_nullable
              as int?,
      player2Score: freezed == player2Score
          ? _self.player2Score
          : player2Score // ignore: cast_nullable_to_non_nullable
              as int?,
      winnerId: freezed == winnerId
          ? _self.winnerId
          : winnerId // ignore: cast_nullable_to_non_nullable
              as String?,
      templateId: freezed == templateId
          ? _self.templateId
          : templateId // ignore: cast_nullable_to_non_nullable
              as String?,
      startTime: freezed == startTime
          ? _self.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endTime: freezed == endTime
          ? _self.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      bracketType: freezed == bracketType
          ? _self.bracketType
          : bracketType // ignore: cast_nullable_to_non_nullable
              as BracketType?,
    ));
  }
}

/// Adds pattern-matching-related methods to [Match].
extension MatchPatterns on Match {
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
    TResult Function(_Match value)? internal,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Match() when internal != null:
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
    required TResult Function(_Match value) internal,
  }) {
    final _that = this;
    switch (_that) {
      case _Match():
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
    TResult? Function(_Match value)? internal,
  }) {
    final _that = this;
    switch (_that) {
      case _Match() when internal != null:
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
            String mid,
            String leagueId,
            int round,
            String player1Id,
            String? player2Id,
            MatchStatus status,
            int? player1Score,
            int? player2Score,
            String? winnerId,
            String? templateId,
            DateTime? startTime,
            DateTime? endTime,
            BracketType? bracketType)?
        internal,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Match() when internal != null:
        return internal(
            _that.mid,
            _that.leagueId,
            _that.round,
            _that.player1Id,
            _that.player2Id,
            _that.status,
            _that.player1Score,
            _that.player2Score,
            _that.winnerId,
            _that.templateId,
            _that.startTime,
            _that.endTime,
            _that.bracketType);
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
            String mid,
            String leagueId,
            int round,
            String player1Id,
            String? player2Id,
            MatchStatus status,
            int? player1Score,
            int? player2Score,
            String? winnerId,
            String? templateId,
            DateTime? startTime,
            DateTime? endTime,
            BracketType? bracketType)
        internal,
  }) {
    final _that = this;
    switch (_that) {
      case _Match():
        return internal(
            _that.mid,
            _that.leagueId,
            _that.round,
            _that.player1Id,
            _that.player2Id,
            _that.status,
            _that.player1Score,
            _that.player2Score,
            _that.winnerId,
            _that.templateId,
            _that.startTime,
            _that.endTime,
            _that.bracketType);
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
            String mid,
            String leagueId,
            int round,
            String player1Id,
            String? player2Id,
            MatchStatus status,
            int? player1Score,
            int? player2Score,
            String? winnerId,
            String? templateId,
            DateTime? startTime,
            DateTime? endTime,
            BracketType? bracketType)?
        internal,
  }) {
    final _that = this;
    switch (_that) {
      case _Match() when internal != null:
        return internal(
            _that.mid,
            _that.leagueId,
            _that.round,
            _that.player1Id,
            _that.player2Id,
            _that.status,
            _that.player1Score,
            _that.player2Score,
            _that.winnerId,
            _that.templateId,
            _that.startTime,
            _that.endTime,
            _that.bracketType);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Match implements Match {
  const _Match(
      {required this.mid,
      required this.leagueId,
      required this.round,
      required this.player1Id,
      this.player2Id,
      this.status = MatchStatus.pending,
      this.player1Score,
      this.player2Score,
      this.winnerId,
      this.templateId,
      this.startTime,
      this.endTime,
      this.bracketType});
  factory _Match.fromJson(Map<String, dynamic> json) => _$MatchFromJson(json);

  @override
  final String mid;
  @override
  final String leagueId;
  @override
  final int round;
  @override
  final String player1Id;
  @override
  final String? player2Id;
// 在淘汰赛中，选手2可能稍后确定
  @override
  @JsonKey()
  final MatchStatus status;
  @override
  final int? player1Score;
  @override
  final int? player2Score;
  @override
  final String? winnerId;
  @override
  final String? templateId;
// 本场比赛使用的计分模板
  @override
  final DateTime? startTime;
  @override
  final DateTime? endTime;
  @override
  final BracketType? bracketType;

  /// Create a copy of Match
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MatchCopyWith<_Match> get copyWith =>
      __$MatchCopyWithImpl<_Match>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$MatchToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Match &&
            (identical(other.mid, mid) || other.mid == mid) &&
            (identical(other.leagueId, leagueId) ||
                other.leagueId == leagueId) &&
            (identical(other.round, round) || other.round == round) &&
            (identical(other.player1Id, player1Id) ||
                other.player1Id == player1Id) &&
            (identical(other.player2Id, player2Id) ||
                other.player2Id == player2Id) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.player1Score, player1Score) ||
                other.player1Score == player1Score) &&
            (identical(other.player2Score, player2Score) ||
                other.player2Score == player2Score) &&
            (identical(other.winnerId, winnerId) ||
                other.winnerId == winnerId) &&
            (identical(other.templateId, templateId) ||
                other.templateId == templateId) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.bracketType, bracketType) ||
                other.bracketType == bracketType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      mid,
      leagueId,
      round,
      player1Id,
      player2Id,
      status,
      player1Score,
      player2Score,
      winnerId,
      templateId,
      startTime,
      endTime,
      bracketType);

  @override
  String toString() {
    return 'Match.internal(mid: $mid, leagueId: $leagueId, round: $round, player1Id: $player1Id, player2Id: $player2Id, status: $status, player1Score: $player1Score, player2Score: $player2Score, winnerId: $winnerId, templateId: $templateId, startTime: $startTime, endTime: $endTime, bracketType: $bracketType)';
  }
}

/// @nodoc
abstract mixin class _$MatchCopyWith<$Res> implements $MatchCopyWith<$Res> {
  factory _$MatchCopyWith(_Match value, $Res Function(_Match) _then) =
      __$MatchCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String mid,
      String leagueId,
      int round,
      String player1Id,
      String? player2Id,
      MatchStatus status,
      int? player1Score,
      int? player2Score,
      String? winnerId,
      String? templateId,
      DateTime? startTime,
      DateTime? endTime,
      BracketType? bracketType});
}

/// @nodoc
class __$MatchCopyWithImpl<$Res> implements _$MatchCopyWith<$Res> {
  __$MatchCopyWithImpl(this._self, this._then);

  final _Match _self;
  final $Res Function(_Match) _then;

  /// Create a copy of Match
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? mid = null,
    Object? leagueId = null,
    Object? round = null,
    Object? player1Id = null,
    Object? player2Id = freezed,
    Object? status = null,
    Object? player1Score = freezed,
    Object? player2Score = freezed,
    Object? winnerId = freezed,
    Object? templateId = freezed,
    Object? startTime = freezed,
    Object? endTime = freezed,
    Object? bracketType = freezed,
  }) {
    return _then(_Match(
      mid: null == mid
          ? _self.mid
          : mid // ignore: cast_nullable_to_non_nullable
              as String,
      leagueId: null == leagueId
          ? _self.leagueId
          : leagueId // ignore: cast_nullable_to_non_nullable
              as String,
      round: null == round
          ? _self.round
          : round // ignore: cast_nullable_to_non_nullable
              as int,
      player1Id: null == player1Id
          ? _self.player1Id
          : player1Id // ignore: cast_nullable_to_non_nullable
              as String,
      player2Id: freezed == player2Id
          ? _self.player2Id
          : player2Id // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as MatchStatus,
      player1Score: freezed == player1Score
          ? _self.player1Score
          : player1Score // ignore: cast_nullable_to_non_nullable
              as int?,
      player2Score: freezed == player2Score
          ? _self.player2Score
          : player2Score // ignore: cast_nullable_to_non_nullable
              as int?,
      winnerId: freezed == winnerId
          ? _self.winnerId
          : winnerId // ignore: cast_nullable_to_non_nullable
              as String?,
      templateId: freezed == templateId
          ? _self.templateId
          : templateId // ignore: cast_nullable_to_non_nullable
              as String?,
      startTime: freezed == startTime
          ? _self.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endTime: freezed == endTime
          ? _self.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      bracketType: freezed == bracketType
          ? _self.bracketType
          : bracketType // ignore: cast_nullable_to_non_nullable
              as BracketType?,
    ));
  }
}

// dart format on
