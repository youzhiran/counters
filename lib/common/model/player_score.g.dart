// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_score.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlayerScoreImpl _$$PlayerScoreImplFromJson(Map<String, dynamic> json) =>
    _$PlayerScoreImpl(
      playerId: json['playerId'] as String,
      roundScores: (json['roundScores'] as List<dynamic>?)
              ?.map((e) => (e as num?)?.toInt())
              .toList() ??
          const [],
      roundExtendedFields:
          (json['roundExtendedFields'] as Map<String, dynamic>?)?.map(
                (k, e) => MapEntry(int.parse(k), e as Map<String, dynamic>),
              ) ??
              const {},
    );

Map<String, dynamic> _$$PlayerScoreImplToJson(_$PlayerScoreImpl instance) =>
    <String, dynamic>{
      'playerId': instance.playerId,
      'roundScores': instance.roundScores,
      'roundExtendedFields':
          instance.roundExtendedFields.map((k, e) => MapEntry(k.toString(), e)),
    };
