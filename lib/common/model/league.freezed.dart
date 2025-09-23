// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'league.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

League _$LeagueFromJson(Map<String, dynamic> json) {
  return _League.fromJson(json);
}

/// @nodoc
mixin _$League {
  String get lid => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  LeagueType get type => throw _privateConstructorUsedError;
  List<String> get playerIds => throw _privateConstructorUsedError;
  List<Match> get matches => throw _privateConstructorUsedError;
  String get defaultTemplateId =>
      throw _privateConstructorUsedError; // Round-robin specific settings
  int get roundRobinRounds => throw _privateConstructorUsedError;
  int get pointsForWin => throw _privateConstructorUsedError;
  int get pointsForDraw => throw _privateConstructorUsedError;
  int get pointsForLoss =>
      throw _privateConstructorUsedError; // Knockout specific settings
  int? get currentRound => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String lid,
            String name,
            LeagueType type,
            List<String> playerIds,
            List<Match> matches,
            String defaultTemplateId,
            int roundRobinRounds,
            int pointsForWin,
            int pointsForDraw,
            int pointsForLoss,
            int? currentRound)
        internal,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String lid,
            String name,
            LeagueType type,
            List<String> playerIds,
            List<Match> matches,
            String defaultTemplateId,
            int roundRobinRounds,
            int pointsForWin,
            int pointsForDraw,
            int pointsForLoss,
            int? currentRound)?
        internal,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String lid,
            String name,
            LeagueType type,
            List<String> playerIds,
            List<Match> matches,
            String defaultTemplateId,
            int roundRobinRounds,
            int pointsForWin,
            int pointsForDraw,
            int pointsForLoss,
            int? currentRound)?
        internal,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_League value) internal,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_League value)? internal,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_League value)? internal,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LeagueCopyWith<League> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LeagueCopyWith<$Res> {
  factory $LeagueCopyWith(League value, $Res Function(League) then) =
      _$LeagueCopyWithImpl<$Res, League>;
  @useResult
  $Res call(
      {String lid,
      String name,
      LeagueType type,
      List<String> playerIds,
      List<Match> matches,
      String defaultTemplateId,
      int roundRobinRounds,
      int pointsForWin,
      int pointsForDraw,
      int pointsForLoss,
      int? currentRound});
}

/// @nodoc
class _$LeagueCopyWithImpl<$Res, $Val extends League>
    implements $LeagueCopyWith<$Res> {
  _$LeagueCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lid = null,
    Object? name = null,
    Object? type = null,
    Object? playerIds = null,
    Object? matches = null,
    Object? defaultTemplateId = null,
    Object? roundRobinRounds = null,
    Object? pointsForWin = null,
    Object? pointsForDraw = null,
    Object? pointsForLoss = null,
    Object? currentRound = freezed,
  }) {
    return _then(_value.copyWith(
      lid: null == lid
          ? _value.lid
          : lid // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as LeagueType,
      playerIds: null == playerIds
          ? _value.playerIds
          : playerIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      matches: null == matches
          ? _value.matches
          : matches // ignore: cast_nullable_to_non_nullable
              as List<Match>,
      defaultTemplateId: null == defaultTemplateId
          ? _value.defaultTemplateId
          : defaultTemplateId // ignore: cast_nullable_to_non_nullable
              as String,
      roundRobinRounds: null == roundRobinRounds
          ? _value.roundRobinRounds
          : roundRobinRounds // ignore: cast_nullable_to_non_nullable
              as int,
      pointsForWin: null == pointsForWin
          ? _value.pointsForWin
          : pointsForWin // ignore: cast_nullable_to_non_nullable
              as int,
      pointsForDraw: null == pointsForDraw
          ? _value.pointsForDraw
          : pointsForDraw // ignore: cast_nullable_to_non_nullable
              as int,
      pointsForLoss: null == pointsForLoss
          ? _value.pointsForLoss
          : pointsForLoss // ignore: cast_nullable_to_non_nullable
              as int,
      currentRound: freezed == currentRound
          ? _value.currentRound
          : currentRound // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LeagueImplCopyWith<$Res> implements $LeagueCopyWith<$Res> {
  factory _$$LeagueImplCopyWith(
          _$LeagueImpl value, $Res Function(_$LeagueImpl) then) =
      __$$LeagueImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String lid,
      String name,
      LeagueType type,
      List<String> playerIds,
      List<Match> matches,
      String defaultTemplateId,
      int roundRobinRounds,
      int pointsForWin,
      int pointsForDraw,
      int pointsForLoss,
      int? currentRound});
}

/// @nodoc
class __$$LeagueImplCopyWithImpl<$Res>
    extends _$LeagueCopyWithImpl<$Res, _$LeagueImpl>
    implements _$$LeagueImplCopyWith<$Res> {
  __$$LeagueImplCopyWithImpl(
      _$LeagueImpl _value, $Res Function(_$LeagueImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lid = null,
    Object? name = null,
    Object? type = null,
    Object? playerIds = null,
    Object? matches = null,
    Object? defaultTemplateId = null,
    Object? roundRobinRounds = null,
    Object? pointsForWin = null,
    Object? pointsForDraw = null,
    Object? pointsForLoss = null,
    Object? currentRound = freezed,
  }) {
    return _then(_$LeagueImpl(
      lid: null == lid
          ? _value.lid
          : lid // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as LeagueType,
      playerIds: null == playerIds
          ? _value._playerIds
          : playerIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      matches: null == matches
          ? _value._matches
          : matches // ignore: cast_nullable_to_non_nullable
              as List<Match>,
      defaultTemplateId: null == defaultTemplateId
          ? _value.defaultTemplateId
          : defaultTemplateId // ignore: cast_nullable_to_non_nullable
              as String,
      roundRobinRounds: null == roundRobinRounds
          ? _value.roundRobinRounds
          : roundRobinRounds // ignore: cast_nullable_to_non_nullable
              as int,
      pointsForWin: null == pointsForWin
          ? _value.pointsForWin
          : pointsForWin // ignore: cast_nullable_to_non_nullable
              as int,
      pointsForDraw: null == pointsForDraw
          ? _value.pointsForDraw
          : pointsForDraw // ignore: cast_nullable_to_non_nullable
              as int,
      pointsForLoss: null == pointsForLoss
          ? _value.pointsForLoss
          : pointsForLoss // ignore: cast_nullable_to_non_nullable
              as int,
      currentRound: freezed == currentRound
          ? _value.currentRound
          : currentRound // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LeagueImpl implements _League {
  const _$LeagueImpl(
      {required this.lid,
      required this.name,
      required this.type,
      required final List<String> playerIds,
      required final List<Match> matches,
      required this.defaultTemplateId,
      this.roundRobinRounds = 1,
      this.pointsForWin = 3,
      this.pointsForDraw = 1,
      this.pointsForLoss = 0,
      this.currentRound})
      : _playerIds = playerIds,
        _matches = matches;

  factory _$LeagueImpl.fromJson(Map<String, dynamic> json) =>
      _$$LeagueImplFromJson(json);

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
  final int roundRobinRounds;
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

  @override
  String toString() {
    return 'League.internal(lid: $lid, name: $name, type: $type, playerIds: $playerIds, matches: $matches, defaultTemplateId: $defaultTemplateId, roundRobinRounds: $roundRobinRounds, pointsForWin: $pointsForWin, pointsForDraw: $pointsForDraw, pointsForLoss: $pointsForLoss, currentRound: $currentRound)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LeagueImpl &&
            (identical(other.lid, lid) || other.lid == lid) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality()
                .equals(other._playerIds, _playerIds) &&
            const DeepCollectionEquality().equals(other._matches, _matches) &&
            (identical(other.defaultTemplateId, defaultTemplateId) ||
                other.defaultTemplateId == defaultTemplateId) &&
            (identical(other.roundRobinRounds, roundRobinRounds) ||
                other.roundRobinRounds == roundRobinRounds) &&
            (identical(other.pointsForWin, pointsForWin) ||
                other.pointsForWin == pointsForWin) &&
            (identical(other.pointsForDraw, pointsForDraw) ||
                other.pointsForDraw == pointsForDraw) &&
            (identical(other.pointsForLoss, pointsForLoss) ||
                other.pointsForLoss == pointsForLoss) &&
            (identical(other.currentRound, currentRound) ||
                other.currentRound == currentRound));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      lid,
      name,
      type,
      const DeepCollectionEquality().hash(_playerIds),
      const DeepCollectionEquality().hash(_matches),
      defaultTemplateId,
      roundRobinRounds,
      pointsForWin,
      pointsForDraw,
      pointsForLoss,
      currentRound);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LeagueImplCopyWith<_$LeagueImpl> get copyWith =>
      __$$LeagueImplCopyWithImpl<_$LeagueImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String lid,
            String name,
            LeagueType type,
            List<String> playerIds,
            List<Match> matches,
            String defaultTemplateId,
            int roundRobinRounds,
            int pointsForWin,
            int pointsForDraw,
            int pointsForLoss,
            int? currentRound)
        internal,
  }) {
    return internal(
        lid,
        name,
        type,
        playerIds,
        matches,
        defaultTemplateId,
        roundRobinRounds,
        pointsForWin,
        pointsForDraw,
        pointsForLoss,
        currentRound);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String lid,
            String name,
            LeagueType type,
            List<String> playerIds,
            List<Match> matches,
            String defaultTemplateId,
            int roundRobinRounds,
            int pointsForWin,
            int pointsForDraw,
            int pointsForLoss,
            int? currentRound)?
        internal,
  }) {
    return internal?.call(
        lid,
        name,
        type,
        playerIds,
        matches,
        defaultTemplateId,
        roundRobinRounds,
        pointsForWin,
        pointsForDraw,
        pointsForLoss,
        currentRound);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String lid,
            String name,
            LeagueType type,
            List<String> playerIds,
            List<Match> matches,
            String defaultTemplateId,
            int roundRobinRounds,
            int pointsForWin,
            int pointsForDraw,
            int pointsForLoss,
            int? currentRound)?
        internal,
    required TResult orElse(),
  }) {
    if (internal != null) {
      return internal(
          lid,
          name,
          type,
          playerIds,
          matches,
          defaultTemplateId,
          roundRobinRounds,
          pointsForWin,
          pointsForDraw,
          pointsForLoss,
          currentRound);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_League value) internal,
  }) {
    return internal(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_League value)? internal,
  }) {
    return internal?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_League value)? internal,
    required TResult orElse(),
  }) {
    if (internal != null) {
      return internal(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$LeagueImplToJson(
      this,
    );
  }
}

abstract class _League implements League {
  const factory _League(
      {required final String lid,
      required final String name,
      required final LeagueType type,
      required final List<String> playerIds,
      required final List<Match> matches,
      required final String defaultTemplateId,
      final int roundRobinRounds,
      final int pointsForWin,
      final int pointsForDraw,
      final int pointsForLoss,
      final int? currentRound}) = _$LeagueImpl;

  factory _League.fromJson(Map<String, dynamic> json) = _$LeagueImpl.fromJson;

  @override
  String get lid;
  @override
  String get name;
  @override
  LeagueType get type;
  @override
  List<String> get playerIds;
  @override
  List<Match> get matches;
  @override
  String get defaultTemplateId;
  @override // Round-robin specific settings
  int get roundRobinRounds;
  @override
  int get pointsForWin;
  @override
  int get pointsForDraw;
  @override
  int get pointsForLoss;
  @override // Knockout specific settings
  int? get currentRound;
  @override
  @JsonKey(ignore: true)
  _$$LeagueImplCopyWith<_$LeagueImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
