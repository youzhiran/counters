// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'league.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_League _$LeagueFromJson(Map<String, dynamic> json) => _League(
      lid: json['lid'] as String,
      name: json['name'] as String,
      type: $enumDecode(_$LeagueTypeEnumMap, json['type']),
      playerIds:
          (json['playerIds'] as List<dynamic>).map((e) => e as String).toList(),
      matches: (json['matches'] as List<dynamic>)
          .map((e) => Match.fromJson(e as Map<String, dynamic>))
          .toList(),
      defaultTemplateId: json['defaultTemplateId'] as String,
      pointsForWin: (json['pointsForWin'] as num?)?.toInt() ?? 3,
      pointsForDraw: (json['pointsForDraw'] as num?)?.toInt() ?? 1,
      pointsForLoss: (json['pointsForLoss'] as num?)?.toInt() ?? 0,
      currentRound: (json['currentRound'] as num?)?.toInt(),
    );

Map<String, dynamic> _$LeagueToJson(_League instance) => <String, dynamic>{
      'lid': instance.lid,
      'name': instance.name,
      'type': _$LeagueTypeEnumMap[instance.type]!,
      'playerIds': instance.playerIds,
      'matches': instance.matches,
      'defaultTemplateId': instance.defaultTemplateId,
      'pointsForWin': instance.pointsForWin,
      'pointsForDraw': instance.pointsForDraw,
      'pointsForLoss': instance.pointsForLoss,
      'currentRound': instance.currentRound,
    };

const _$LeagueTypeEnumMap = {
  LeagueType.roundRobin: 'roundRobin',
  LeagueType.knockout: 'knockout',
  LeagueType.doubleElimination: 'doubleElimination',
};
