// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_messages.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SyncMessageImpl _$$SyncMessageImplFromJson(Map<String, dynamic> json) =>
    _$SyncMessageImpl(
      type: json['type'] as String,
      data: json['data'],
    );

Map<String, dynamic> _$$SyncMessageImplToJson(_$SyncMessageImpl instance) =>
    <String, dynamic>{
      'type': instance.type,
      'data': instance.data,
    };

_$SyncStatePayloadImpl _$$SyncStatePayloadImplFromJson(
        Map<String, dynamic> json) =>
    _$SyncStatePayloadImpl(
      session: GameSession.fromJson(json['session'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$SyncStatePayloadImplToJson(
        _$SyncStatePayloadImpl instance) =>
    <String, dynamic>{
      'session': instance.session,
    };

_$UpdateScorePayloadImpl _$$UpdateScorePayloadImplFromJson(
        Map<String, dynamic> json) =>
    _$UpdateScorePayloadImpl(
      playerId: json['playerId'] as String,
      roundIndex: (json['roundIndex'] as num).toInt(),
      score: (json['score'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$UpdateScorePayloadImplToJson(
        _$UpdateScorePayloadImpl instance) =>
    <String, dynamic>{
      'playerId': instance.playerId,
      'roundIndex': instance.roundIndex,
      'score': instance.score,
    };

_$NewRoundPayloadImpl _$$NewRoundPayloadImplFromJson(
        Map<String, dynamic> json) =>
    _$NewRoundPayloadImpl(
      newRoundIndex: (json['newRoundIndex'] as num).toInt(),
    );

Map<String, dynamic> _$$NewRoundPayloadImplToJson(
        _$NewRoundPayloadImpl instance) =>
    <String, dynamic>{
      'newRoundIndex': instance.newRoundIndex,
    };

_$ResetGamePayloadImpl _$$ResetGamePayloadImplFromJson(
        Map<String, dynamic> json) =>
    _$ResetGamePayloadImpl();

Map<String, dynamic> _$$ResetGamePayloadImplToJson(
        _$ResetGamePayloadImpl instance) =>
    <String, dynamic>{};

_$HostDisconnectPayloadImpl _$$HostDisconnectPayloadImplFromJson(
        Map<String, dynamic> json) =>
    _$HostDisconnectPayloadImpl(
      reason: json['reason'] as String?,
    );

Map<String, dynamic> _$$HostDisconnectPayloadImplToJson(
        _$HostDisconnectPayloadImpl instance) =>
    <String, dynamic>{
      'reason': instance.reason,
    };

_$GameEndPayloadImpl _$$GameEndPayloadImplFromJson(Map<String, dynamic> json) =>
    _$GameEndPayloadImpl();

Map<String, dynamic> _$$GameEndPayloadImplToJson(
        _$GameEndPayloadImpl instance) =>
    <String, dynamic>{};
