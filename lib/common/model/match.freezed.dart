// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Match _$MatchFromJson(Map<String, dynamic> json) {
  return _Match.fromJson(json);
}

/// @nodoc
mixin _$Match {
  String get mid => throw _privateConstructorUsedError;
  String get leagueId => throw _privateConstructorUsedError;
  int get round => throw _privateConstructorUsedError;
  String get player1Id => throw _privateConstructorUsedError;
  String? get player2Id =>
      throw _privateConstructorUsedError; // 在淘汰赛中，选手2可能稍后确定
  MatchStatus get status => throw _privateConstructorUsedError;
  int? get player1Score => throw _privateConstructorUsedError;
  int? get player2Score => throw _privateConstructorUsedError;
  String? get winnerId => throw _privateConstructorUsedError;
  String? get templateId => throw _privateConstructorUsedError; // 本场比赛使用的计分模板
  DateTime? get startTime => throw _privateConstructorUsedError;
  DateTime? get endTime => throw _privateConstructorUsedError;
  BracketType? get bracketType => throw _privateConstructorUsedError;
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
  }) =>
      throw _privateConstructorUsedError;
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
  }) =>
      throw _privateConstructorUsedError;
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
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Match value) internal,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Match value)? internal,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Match value)? internal,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MatchCopyWith<Match> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MatchCopyWith<$Res> {
  factory $MatchCopyWith(Match value, $Res Function(Match) then) =
      _$MatchCopyWithImpl<$Res, Match>;
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
class _$MatchCopyWithImpl<$Res, $Val extends Match>
    implements $MatchCopyWith<$Res> {
  _$MatchCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

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
    return _then(_value.copyWith(
      mid: null == mid
          ? _value.mid
          : mid // ignore: cast_nullable_to_non_nullable
              as String,
      leagueId: null == leagueId
          ? _value.leagueId
          : leagueId // ignore: cast_nullable_to_non_nullable
              as String,
      round: null == round
          ? _value.round
          : round // ignore: cast_nullable_to_non_nullable
              as int,
      player1Id: null == player1Id
          ? _value.player1Id
          : player1Id // ignore: cast_nullable_to_non_nullable
              as String,
      player2Id: freezed == player2Id
          ? _value.player2Id
          : player2Id // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as MatchStatus,
      player1Score: freezed == player1Score
          ? _value.player1Score
          : player1Score // ignore: cast_nullable_to_non_nullable
              as int?,
      player2Score: freezed == player2Score
          ? _value.player2Score
          : player2Score // ignore: cast_nullable_to_non_nullable
              as int?,
      winnerId: freezed == winnerId
          ? _value.winnerId
          : winnerId // ignore: cast_nullable_to_non_nullable
              as String?,
      templateId: freezed == templateId
          ? _value.templateId
          : templateId // ignore: cast_nullable_to_non_nullable
              as String?,
      startTime: freezed == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endTime: freezed == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      bracketType: freezed == bracketType
          ? _value.bracketType
          : bracketType // ignore: cast_nullable_to_non_nullable
              as BracketType?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MatchImplCopyWith<$Res> implements $MatchCopyWith<$Res> {
  factory _$$MatchImplCopyWith(
          _$MatchImpl value, $Res Function(_$MatchImpl) then) =
      __$$MatchImplCopyWithImpl<$Res>;
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
class __$$MatchImplCopyWithImpl<$Res>
    extends _$MatchCopyWithImpl<$Res, _$MatchImpl>
    implements _$$MatchImplCopyWith<$Res> {
  __$$MatchImplCopyWithImpl(
      _$MatchImpl _value, $Res Function(_$MatchImpl) _then)
      : super(_value, _then);

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
    return _then(_$MatchImpl(
      mid: null == mid
          ? _value.mid
          : mid // ignore: cast_nullable_to_non_nullable
              as String,
      leagueId: null == leagueId
          ? _value.leagueId
          : leagueId // ignore: cast_nullable_to_non_nullable
              as String,
      round: null == round
          ? _value.round
          : round // ignore: cast_nullable_to_non_nullable
              as int,
      player1Id: null == player1Id
          ? _value.player1Id
          : player1Id // ignore: cast_nullable_to_non_nullable
              as String,
      player2Id: freezed == player2Id
          ? _value.player2Id
          : player2Id // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as MatchStatus,
      player1Score: freezed == player1Score
          ? _value.player1Score
          : player1Score // ignore: cast_nullable_to_non_nullable
              as int?,
      player2Score: freezed == player2Score
          ? _value.player2Score
          : player2Score // ignore: cast_nullable_to_non_nullable
              as int?,
      winnerId: freezed == winnerId
          ? _value.winnerId
          : winnerId // ignore: cast_nullable_to_non_nullable
              as String?,
      templateId: freezed == templateId
          ? _value.templateId
          : templateId // ignore: cast_nullable_to_non_nullable
              as String?,
      startTime: freezed == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endTime: freezed == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      bracketType: freezed == bracketType
          ? _value.bracketType
          : bracketType // ignore: cast_nullable_to_non_nullable
              as BracketType?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MatchImpl implements _Match {
  const _$MatchImpl(
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

  factory _$MatchImpl.fromJson(Map<String, dynamic> json) =>
      _$$MatchImplFromJson(json);

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

  @override
  String toString() {
    return 'Match.internal(mid: $mid, leagueId: $leagueId, round: $round, player1Id: $player1Id, player2Id: $player2Id, status: $status, player1Score: $player1Score, player2Score: $player2Score, winnerId: $winnerId, templateId: $templateId, startTime: $startTime, endTime: $endTime, bracketType: $bracketType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MatchImpl &&
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

  @JsonKey(ignore: true)
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

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MatchImplCopyWith<_$MatchImpl> get copyWith =>
      __$$MatchImplCopyWithImpl<_$MatchImpl>(this, _$identity);

  @override
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
    return internal(
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
  }

  @override
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
    return internal?.call(
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
  }

  @override
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
    if (internal != null) {
      return internal(
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
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Match value) internal,
  }) {
    return internal(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Match value)? internal,
  }) {
    return internal?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Match value)? internal,
    required TResult orElse(),
  }) {
    if (internal != null) {
      return internal(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$MatchImplToJson(
      this,
    );
  }
}

abstract class _Match implements Match {
  const factory _Match(
      {required final String mid,
      required final String leagueId,
      required final int round,
      required final String player1Id,
      final String? player2Id,
      final MatchStatus status,
      final int? player1Score,
      final int? player2Score,
      final String? winnerId,
      final String? templateId,
      final DateTime? startTime,
      final DateTime? endTime,
      final BracketType? bracketType}) = _$MatchImpl;

  factory _Match.fromJson(Map<String, dynamic> json) = _$MatchImpl.fromJson;

  @override
  String get mid;
  @override
  String get leagueId;
  @override
  int get round;
  @override
  String get player1Id;
  @override
  String? get player2Id;
  @override // 在淘汰赛中，选手2可能稍后确定
  MatchStatus get status;
  @override
  int? get player1Score;
  @override
  int? get player2Score;
  @override
  String? get winnerId;
  @override
  String? get templateId;
  @override // 本场比赛使用的计分模板
  DateTime? get startTime;
  @override
  DateTime? get endTime;
  @override
  BracketType? get bracketType;
  @override
  @JsonKey(ignore: true)
  _$$MatchImplCopyWith<_$MatchImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
