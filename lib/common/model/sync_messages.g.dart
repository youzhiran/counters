// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_messages.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SyncMessage _$SyncMessageFromJson(Map<String, dynamic> json) => _SyncMessage(
      type: json['type'] as String,
      data: json['data'],
    );

Map<String, dynamic> _$SyncMessageToJson(_SyncMessage instance) =>
    <String, dynamic>{
      'type': instance.type,
      'data': instance.data,
    };

_SyncStatePayload _$SyncStatePayloadFromJson(Map<String, dynamic> json) =>
    _SyncStatePayload(
      session: GameSession.fromJson(json['session'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SyncStatePayloadToJson(_SyncStatePayload instance) =>
    <String, dynamic>{
      'session': instance.session,
    };

_UpdateScorePayload _$UpdateScorePayloadFromJson(Map<String, dynamic> json) =>
    _UpdateScorePayload(
      playerId: json['playerId'] as String,
      roundIndex: (json['roundIndex'] as num).toInt(),
      score: (json['score'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UpdateScorePayloadToJson(_UpdateScorePayload instance) =>
    <String, dynamic>{
      'playerId': instance.playerId,
      'roundIndex': instance.roundIndex,
      'score': instance.score,
    };

_NewRoundPayload _$NewRoundPayloadFromJson(Map<String, dynamic> json) =>
    _NewRoundPayload(
      newRoundIndex: (json['newRoundIndex'] as num).toInt(),
    );

Map<String, dynamic> _$NewRoundPayloadToJson(_NewRoundPayload instance) =>
    <String, dynamic>{
      'newRoundIndex': instance.newRoundIndex,
    };

_ResetGamePayload _$ResetGamePayloadFromJson(Map<String, dynamic> json) =>
    _ResetGamePayload();

Map<String, dynamic> _$ResetGamePayloadToJson(_ResetGamePayload instance) =>
    <String, dynamic>{};

_GameEndPayload _$GameEndPayloadFromJson(Map<String, dynamic> json) =>
    _GameEndPayload();

Map<String, dynamic> _$GameEndPayloadToJson(_GameEndPayload instance) =>
    <String, dynamic>{};
