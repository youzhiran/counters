// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MatchImpl _$$MatchImplFromJson(Map<String, dynamic> json) => _$MatchImpl(
      mid: json['mid'] as String,
      leagueId: json['leagueId'] as String,
      round: (json['round'] as num).toInt(),
      player1Id: json['player1Id'] as String,
      player2Id: json['player2Id'] as String?,
      status: $enumDecodeNullable(_$MatchStatusEnumMap, json['status']) ??
          MatchStatus.pending,
      player1Score: (json['player1Score'] as num?)?.toInt(),
      player2Score: (json['player2Score'] as num?)?.toInt(),
      winnerId: json['winnerId'] as String?,
      templateId: json['templateId'] as String?,
      startTime: json['startTime'] == null
          ? null
          : DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      bracketType:
          $enumDecodeNullable(_$BracketTypeEnumMap, json['bracketType']),
    );

Map<String, dynamic> _$$MatchImplToJson(_$MatchImpl instance) =>
    <String, dynamic>{
      'mid': instance.mid,
      'leagueId': instance.leagueId,
      'round': instance.round,
      'player1Id': instance.player1Id,
      'player2Id': instance.player2Id,
      'status': _$MatchStatusEnumMap[instance.status]!,
      'player1Score': instance.player1Score,
      'player2Score': instance.player2Score,
      'winnerId': instance.winnerId,
      'templateId': instance.templateId,
      'startTime': instance.startTime?.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'bracketType': _$BracketTypeEnumMap[instance.bracketType],
    };

const _$MatchStatusEnumMap = {
  MatchStatus.pending: 'pending',
  MatchStatus.inProgress: 'inProgress',
  MatchStatus.completed: 'completed',
};

const _$BracketTypeEnumMap = {
  BracketType.winner: 'winner',
  BracketType.loser: 'loser',
  BracketType.finals: 'finals',
};
