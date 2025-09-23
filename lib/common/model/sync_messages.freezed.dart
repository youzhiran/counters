// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_messages.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SyncMessage _$SyncMessageFromJson(Map<String, dynamic> json) {
  return _SyncMessage.fromJson(json);
}

/// @nodoc
mixin _$SyncMessage {
  String get type => throw _privateConstructorUsedError; // 消息类型，用于区分消息内容
  dynamic get data => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SyncMessageCopyWith<SyncMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SyncMessageCopyWith<$Res> {
  factory $SyncMessageCopyWith(
          SyncMessage value, $Res Function(SyncMessage) then) =
      _$SyncMessageCopyWithImpl<$Res, SyncMessage>;
  @useResult
  $Res call({String type, dynamic data});
}

/// @nodoc
class _$SyncMessageCopyWithImpl<$Res, $Val extends SyncMessage>
    implements $SyncMessageCopyWith<$Res> {
  _$SyncMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? data = freezed,
  }) {
    return _then(_value.copyWith(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      data: freezed == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as dynamic,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SyncMessageImplCopyWith<$Res>
    implements $SyncMessageCopyWith<$Res> {
  factory _$$SyncMessageImplCopyWith(
          _$SyncMessageImpl value, $Res Function(_$SyncMessageImpl) then) =
      __$$SyncMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String type, dynamic data});
}

/// @nodoc
class __$$SyncMessageImplCopyWithImpl<$Res>
    extends _$SyncMessageCopyWithImpl<$Res, _$SyncMessageImpl>
    implements _$$SyncMessageImplCopyWith<$Res> {
  __$$SyncMessageImplCopyWithImpl(
      _$SyncMessageImpl _value, $Res Function(_$SyncMessageImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? data = freezed,
  }) {
    return _then(_$SyncMessageImpl(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      data: freezed == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as dynamic,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SyncMessageImpl implements _SyncMessage {
  const _$SyncMessageImpl({required this.type, this.data});

  factory _$SyncMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$SyncMessageImplFromJson(json);

  @override
  final String type;
// 消息类型，用于区分消息内容
  @override
  final dynamic data;

  @override
  String toString() {
    return 'SyncMessage(type: $type, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncMessageImpl &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality().equals(other.data, data));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, type, const DeepCollectionEquality().hash(data));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SyncMessageImplCopyWith<_$SyncMessageImpl> get copyWith =>
      __$$SyncMessageImplCopyWithImpl<_$SyncMessageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SyncMessageImplToJson(
      this,
    );
  }
}

abstract class _SyncMessage implements SyncMessage {
  const factory _SyncMessage({required final String type, final dynamic data}) =
      _$SyncMessageImpl;

  factory _SyncMessage.fromJson(Map<String, dynamic> json) =
      _$SyncMessageImpl.fromJson;

  @override
  String get type;
  @override // 消息类型，用于区分消息内容
  dynamic get data;
  @override
  @JsonKey(ignore: true)
  _$$SyncMessageImplCopyWith<_$SyncMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SyncStatePayload _$SyncStatePayloadFromJson(Map<String, dynamic> json) {
  return _SyncStatePayload.fromJson(json);
}

/// @nodoc
mixin _$SyncStatePayload {
  GameSession get session => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SyncStatePayloadCopyWith<SyncStatePayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SyncStatePayloadCopyWith<$Res> {
  factory $SyncStatePayloadCopyWith(
          SyncStatePayload value, $Res Function(SyncStatePayload) then) =
      _$SyncStatePayloadCopyWithImpl<$Res, SyncStatePayload>;
  @useResult
  $Res call({GameSession session});

  $GameSessionCopyWith<$Res> get session;
}

/// @nodoc
class _$SyncStatePayloadCopyWithImpl<$Res, $Val extends SyncStatePayload>
    implements $SyncStatePayloadCopyWith<$Res> {
  _$SyncStatePayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? session = null,
  }) {
    return _then(_value.copyWith(
      session: null == session
          ? _value.session
          : session // ignore: cast_nullable_to_non_nullable
              as GameSession,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $GameSessionCopyWith<$Res> get session {
    return $GameSessionCopyWith<$Res>(_value.session, (value) {
      return _then(_value.copyWith(session: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SyncStatePayloadImplCopyWith<$Res>
    implements $SyncStatePayloadCopyWith<$Res> {
  factory _$$SyncStatePayloadImplCopyWith(_$SyncStatePayloadImpl value,
          $Res Function(_$SyncStatePayloadImpl) then) =
      __$$SyncStatePayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({GameSession session});

  @override
  $GameSessionCopyWith<$Res> get session;
}

/// @nodoc
class __$$SyncStatePayloadImplCopyWithImpl<$Res>
    extends _$SyncStatePayloadCopyWithImpl<$Res, _$SyncStatePayloadImpl>
    implements _$$SyncStatePayloadImplCopyWith<$Res> {
  __$$SyncStatePayloadImplCopyWithImpl(_$SyncStatePayloadImpl _value,
      $Res Function(_$SyncStatePayloadImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? session = null,
  }) {
    return _then(_$SyncStatePayloadImpl(
      session: null == session
          ? _value.session
          : session // ignore: cast_nullable_to_non_nullable
              as GameSession,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SyncStatePayloadImpl extends _SyncStatePayload {
  const _$SyncStatePayloadImpl({required this.session}) : super._();

  factory _$SyncStatePayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$SyncStatePayloadImplFromJson(json);

  @override
  final GameSession session;

  @override
  String toString() {
    return 'SyncStatePayload(session: $session)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncStatePayloadImpl &&
            (identical(other.session, session) || other.session == session));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, session);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SyncStatePayloadImplCopyWith<_$SyncStatePayloadImpl> get copyWith =>
      __$$SyncStatePayloadImplCopyWithImpl<_$SyncStatePayloadImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SyncStatePayloadImplToJson(
      this,
    );
  }
}

abstract class _SyncStatePayload extends SyncStatePayload {
  const factory _SyncStatePayload({required final GameSession session}) =
      _$SyncStatePayloadImpl;
  const _SyncStatePayload._() : super._();

  factory _SyncStatePayload.fromJson(Map<String, dynamic> json) =
      _$SyncStatePayloadImpl.fromJson;

  @override
  GameSession get session;
  @override
  @JsonKey(ignore: true)
  _$$SyncStatePayloadImplCopyWith<_$SyncStatePayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UpdateScorePayload _$UpdateScorePayloadFromJson(Map<String, dynamic> json) {
  return _UpdateScorePayload.fromJson(json);
}

/// @nodoc
mixin _$UpdateScorePayload {
  String get playerId => throw _privateConstructorUsedError; // 玩家ID
  int get roundIndex =>
      throw _privateConstructorUsedError; // 轮次索引 (0-based, 与 PlayerScore.roundScores 列表索引一致)
  int? get score => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UpdateScorePayloadCopyWith<UpdateScorePayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UpdateScorePayloadCopyWith<$Res> {
  factory $UpdateScorePayloadCopyWith(
          UpdateScorePayload value, $Res Function(UpdateScorePayload) then) =
      _$UpdateScorePayloadCopyWithImpl<$Res, UpdateScorePayload>;
  @useResult
  $Res call({String playerId, int roundIndex, int? score});
}

/// @nodoc
class _$UpdateScorePayloadCopyWithImpl<$Res, $Val extends UpdateScorePayload>
    implements $UpdateScorePayloadCopyWith<$Res> {
  _$UpdateScorePayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerId = null,
    Object? roundIndex = null,
    Object? score = freezed,
  }) {
    return _then(_value.copyWith(
      playerId: null == playerId
          ? _value.playerId
          : playerId // ignore: cast_nullable_to_non_nullable
              as String,
      roundIndex: null == roundIndex
          ? _value.roundIndex
          : roundIndex // ignore: cast_nullable_to_non_nullable
              as int,
      score: freezed == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UpdateScorePayloadImplCopyWith<$Res>
    implements $UpdateScorePayloadCopyWith<$Res> {
  factory _$$UpdateScorePayloadImplCopyWith(_$UpdateScorePayloadImpl value,
          $Res Function(_$UpdateScorePayloadImpl) then) =
      __$$UpdateScorePayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String playerId, int roundIndex, int? score});
}

/// @nodoc
class __$$UpdateScorePayloadImplCopyWithImpl<$Res>
    extends _$UpdateScorePayloadCopyWithImpl<$Res, _$UpdateScorePayloadImpl>
    implements _$$UpdateScorePayloadImplCopyWith<$Res> {
  __$$UpdateScorePayloadImplCopyWithImpl(_$UpdateScorePayloadImpl _value,
      $Res Function(_$UpdateScorePayloadImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerId = null,
    Object? roundIndex = null,
    Object? score = freezed,
  }) {
    return _then(_$UpdateScorePayloadImpl(
      playerId: null == playerId
          ? _value.playerId
          : playerId // ignore: cast_nullable_to_non_nullable
              as String,
      roundIndex: null == roundIndex
          ? _value.roundIndex
          : roundIndex // ignore: cast_nullable_to_non_nullable
              as int,
      score: freezed == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UpdateScorePayloadImpl extends _UpdateScorePayload {
  const _$UpdateScorePayloadImpl(
      {required this.playerId, required this.roundIndex, required this.score})
      : super._();

  factory _$UpdateScorePayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$UpdateScorePayloadImplFromJson(json);

  @override
  final String playerId;
// 玩家ID
  @override
  final int roundIndex;
// 轮次索引 (0-based, 与 PlayerScore.roundScores 列表索引一致)
  @override
  final int? score;

  @override
  String toString() {
    return 'UpdateScorePayload(playerId: $playerId, roundIndex: $roundIndex, score: $score)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdateScorePayloadImpl &&
            (identical(other.playerId, playerId) ||
                other.playerId == playerId) &&
            (identical(other.roundIndex, roundIndex) ||
                other.roundIndex == roundIndex) &&
            (identical(other.score, score) || other.score == score));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, playerId, roundIndex, score);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdateScorePayloadImplCopyWith<_$UpdateScorePayloadImpl> get copyWith =>
      __$$UpdateScorePayloadImplCopyWithImpl<_$UpdateScorePayloadImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UpdateScorePayloadImplToJson(
      this,
    );
  }
}

abstract class _UpdateScorePayload extends UpdateScorePayload {
  const factory _UpdateScorePayload(
      {required final String playerId,
      required final int roundIndex,
      required final int? score}) = _$UpdateScorePayloadImpl;
  const _UpdateScorePayload._() : super._();

  factory _UpdateScorePayload.fromJson(Map<String, dynamic> json) =
      _$UpdateScorePayloadImpl.fromJson;

  @override
  String get playerId;
  @override // 玩家ID
  int get roundIndex;
  @override // 轮次索引 (0-based, 与 PlayerScore.roundScores 列表索引一致)
  int? get score;
  @override
  @JsonKey(ignore: true)
  _$$UpdateScorePayloadImplCopyWith<_$UpdateScorePayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

NewRoundPayload _$NewRoundPayloadFromJson(Map<String, dynamic> json) {
  return _NewRoundPayload.fromJson(json);
}

/// @nodoc
mixin _$NewRoundPayload {
// 可以包含新回合的起始信息，例如新的回合索引 (0-based)
// roundIndex 是指添加新回合后，总的回合数-1，即新回合的索引
  int get newRoundIndex => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $NewRoundPayloadCopyWith<NewRoundPayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NewRoundPayloadCopyWith<$Res> {
  factory $NewRoundPayloadCopyWith(
          NewRoundPayload value, $Res Function(NewRoundPayload) then) =
      _$NewRoundPayloadCopyWithImpl<$Res, NewRoundPayload>;
  @useResult
  $Res call({int newRoundIndex});
}

/// @nodoc
class _$NewRoundPayloadCopyWithImpl<$Res, $Val extends NewRoundPayload>
    implements $NewRoundPayloadCopyWith<$Res> {
  _$NewRoundPayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? newRoundIndex = null,
  }) {
    return _then(_value.copyWith(
      newRoundIndex: null == newRoundIndex
          ? _value.newRoundIndex
          : newRoundIndex // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NewRoundPayloadImplCopyWith<$Res>
    implements $NewRoundPayloadCopyWith<$Res> {
  factory _$$NewRoundPayloadImplCopyWith(_$NewRoundPayloadImpl value,
          $Res Function(_$NewRoundPayloadImpl) then) =
      __$$NewRoundPayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int newRoundIndex});
}

/// @nodoc
class __$$NewRoundPayloadImplCopyWithImpl<$Res>
    extends _$NewRoundPayloadCopyWithImpl<$Res, _$NewRoundPayloadImpl>
    implements _$$NewRoundPayloadImplCopyWith<$Res> {
  __$$NewRoundPayloadImplCopyWithImpl(
      _$NewRoundPayloadImpl _value, $Res Function(_$NewRoundPayloadImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? newRoundIndex = null,
  }) {
    return _then(_$NewRoundPayloadImpl(
      newRoundIndex: null == newRoundIndex
          ? _value.newRoundIndex
          : newRoundIndex // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NewRoundPayloadImpl extends _NewRoundPayload {
  const _$NewRoundPayloadImpl({required this.newRoundIndex}) : super._();

  factory _$NewRoundPayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$NewRoundPayloadImplFromJson(json);

// 可以包含新回合的起始信息，例如新的回合索引 (0-based)
// roundIndex 是指添加新回合后，总的回合数-1，即新回合的索引
  @override
  final int newRoundIndex;

  @override
  String toString() {
    return 'NewRoundPayload(newRoundIndex: $newRoundIndex)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NewRoundPayloadImpl &&
            (identical(other.newRoundIndex, newRoundIndex) ||
                other.newRoundIndex == newRoundIndex));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, newRoundIndex);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$NewRoundPayloadImplCopyWith<_$NewRoundPayloadImpl> get copyWith =>
      __$$NewRoundPayloadImplCopyWithImpl<_$NewRoundPayloadImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NewRoundPayloadImplToJson(
      this,
    );
  }
}

abstract class _NewRoundPayload extends NewRoundPayload {
  const factory _NewRoundPayload({required final int newRoundIndex}) =
      _$NewRoundPayloadImpl;
  const _NewRoundPayload._() : super._();

  factory _NewRoundPayload.fromJson(Map<String, dynamic> json) =
      _$NewRoundPayloadImpl.fromJson;

  @override // 可以包含新回合的起始信息，例如新的回合索引 (0-based)
// roundIndex 是指添加新回合后，总的回合数-1，即新回合的索引
  int get newRoundIndex;
  @override
  @JsonKey(ignore: true)
  _$$NewRoundPayloadImplCopyWith<_$NewRoundPayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ResetGamePayload _$ResetGamePayloadFromJson(Map<String, dynamic> json) {
  return _ResetGamePayload.fromJson(json);
}

/// @nodoc
mixin _$ResetGamePayload {
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ResetGamePayloadCopyWith<$Res> {
  factory $ResetGamePayloadCopyWith(
          ResetGamePayload value, $Res Function(ResetGamePayload) then) =
      _$ResetGamePayloadCopyWithImpl<$Res, ResetGamePayload>;
}

/// @nodoc
class _$ResetGamePayloadCopyWithImpl<$Res, $Val extends ResetGamePayload>
    implements $ResetGamePayloadCopyWith<$Res> {
  _$ResetGamePayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$ResetGamePayloadImplCopyWith<$Res> {
  factory _$$ResetGamePayloadImplCopyWith(_$ResetGamePayloadImpl value,
          $Res Function(_$ResetGamePayloadImpl) then) =
      __$$ResetGamePayloadImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$ResetGamePayloadImplCopyWithImpl<$Res>
    extends _$ResetGamePayloadCopyWithImpl<$Res, _$ResetGamePayloadImpl>
    implements _$$ResetGamePayloadImplCopyWith<$Res> {
  __$$ResetGamePayloadImplCopyWithImpl(_$ResetGamePayloadImpl _value,
      $Res Function(_$ResetGamePayloadImpl) _then)
      : super(_value, _then);
}

/// @nodoc
@JsonSerializable()
class _$ResetGamePayloadImpl extends _ResetGamePayload {
  const _$ResetGamePayloadImpl() : super._();

  factory _$ResetGamePayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$ResetGamePayloadImplFromJson(json);

  @override
  String toString() {
    return 'ResetGamePayload()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$ResetGamePayloadImpl);
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  Map<String, dynamic> toJson() {
    return _$$ResetGamePayloadImplToJson(
      this,
    );
  }
}

abstract class _ResetGamePayload extends ResetGamePayload {
  const factory _ResetGamePayload() = _$ResetGamePayloadImpl;
  const _ResetGamePayload._() : super._();

  factory _ResetGamePayload.fromJson(Map<String, dynamic> json) =
      _$ResetGamePayloadImpl.fromJson;
}

HostDisconnectPayload _$HostDisconnectPayloadFromJson(
    Map<String, dynamic> json) {
  return _HostDisconnectPayload.fromJson(json);
}

/// @nodoc
mixin _$HostDisconnectPayload {
  String? get reason => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $HostDisconnectPayloadCopyWith<HostDisconnectPayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HostDisconnectPayloadCopyWith<$Res> {
  factory $HostDisconnectPayloadCopyWith(HostDisconnectPayload value,
          $Res Function(HostDisconnectPayload) then) =
      _$HostDisconnectPayloadCopyWithImpl<$Res, HostDisconnectPayload>;
  @useResult
  $Res call({String? reason});
}

/// @nodoc
class _$HostDisconnectPayloadCopyWithImpl<$Res,
        $Val extends HostDisconnectPayload>
    implements $HostDisconnectPayloadCopyWith<$Res> {
  _$HostDisconnectPayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reason = freezed,
  }) {
    return _then(_value.copyWith(
      reason: freezed == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HostDisconnectPayloadImplCopyWith<$Res>
    implements $HostDisconnectPayloadCopyWith<$Res> {
  factory _$$HostDisconnectPayloadImplCopyWith(
          _$HostDisconnectPayloadImpl value,
          $Res Function(_$HostDisconnectPayloadImpl) then) =
      __$$HostDisconnectPayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? reason});
}

/// @nodoc
class __$$HostDisconnectPayloadImplCopyWithImpl<$Res>
    extends _$HostDisconnectPayloadCopyWithImpl<$Res,
        _$HostDisconnectPayloadImpl>
    implements _$$HostDisconnectPayloadImplCopyWith<$Res> {
  __$$HostDisconnectPayloadImplCopyWithImpl(_$HostDisconnectPayloadImpl _value,
      $Res Function(_$HostDisconnectPayloadImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reason = freezed,
  }) {
    return _then(_$HostDisconnectPayloadImpl(
      reason: freezed == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HostDisconnectPayloadImpl extends _HostDisconnectPayload {
  const _$HostDisconnectPayloadImpl({this.reason}) : super._();

  factory _$HostDisconnectPayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$HostDisconnectPayloadImplFromJson(json);

  @override
  final String? reason;

  @override
  String toString() {
    return 'HostDisconnectPayload(reason: $reason)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HostDisconnectPayloadImpl &&
            (identical(other.reason, reason) || other.reason == reason));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, reason);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$HostDisconnectPayloadImplCopyWith<_$HostDisconnectPayloadImpl>
      get copyWith => __$$HostDisconnectPayloadImplCopyWithImpl<
          _$HostDisconnectPayloadImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HostDisconnectPayloadImplToJson(
      this,
    );
  }
}

abstract class _HostDisconnectPayload extends HostDisconnectPayload {
  const factory _HostDisconnectPayload({final String? reason}) =
      _$HostDisconnectPayloadImpl;
  const _HostDisconnectPayload._() : super._();

  factory _HostDisconnectPayload.fromJson(Map<String, dynamic> json) =
      _$HostDisconnectPayloadImpl.fromJson;

  @override
  String? get reason;
  @override
  @JsonKey(ignore: true)
  _$$HostDisconnectPayloadImplCopyWith<_$HostDisconnectPayloadImpl>
      get copyWith => throw _privateConstructorUsedError;
}

GameEndPayload _$GameEndPayloadFromJson(Map<String, dynamic> json) {
  return _GameEndPayload.fromJson(json);
}

/// @nodoc
mixin _$GameEndPayload {
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameEndPayloadCopyWith<$Res> {
  factory $GameEndPayloadCopyWith(
          GameEndPayload value, $Res Function(GameEndPayload) then) =
      _$GameEndPayloadCopyWithImpl<$Res, GameEndPayload>;
}

/// @nodoc
class _$GameEndPayloadCopyWithImpl<$Res, $Val extends GameEndPayload>
    implements $GameEndPayloadCopyWith<$Res> {
  _$GameEndPayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$GameEndPayloadImplCopyWith<$Res> {
  factory _$$GameEndPayloadImplCopyWith(_$GameEndPayloadImpl value,
          $Res Function(_$GameEndPayloadImpl) then) =
      __$$GameEndPayloadImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$GameEndPayloadImplCopyWithImpl<$Res>
    extends _$GameEndPayloadCopyWithImpl<$Res, _$GameEndPayloadImpl>
    implements _$$GameEndPayloadImplCopyWith<$Res> {
  __$$GameEndPayloadImplCopyWithImpl(
      _$GameEndPayloadImpl _value, $Res Function(_$GameEndPayloadImpl) _then)
      : super(_value, _then);
}

/// @nodoc
@JsonSerializable()
class _$GameEndPayloadImpl extends _GameEndPayload {
  const _$GameEndPayloadImpl() : super._();

  factory _$GameEndPayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameEndPayloadImplFromJson(json);

  @override
  String toString() {
    return 'GameEndPayload()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$GameEndPayloadImpl);
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  Map<String, dynamic> toJson() {
    return _$$GameEndPayloadImplToJson(
      this,
    );
  }
}

abstract class _GameEndPayload extends GameEndPayload {
  const factory _GameEndPayload() = _$GameEndPayloadImpl;
  const _GameEndPayload._() : super._();

  factory _GameEndPayload.fromJson(Map<String, dynamic> json) =
      _$GameEndPayloadImpl.fromJson;
}
