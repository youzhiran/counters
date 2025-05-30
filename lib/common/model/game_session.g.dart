// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GameSession _$GameSessionFromJson(Map<String, dynamic> json) => _GameSession(
      sid: json['sid'] as String,
      templateId: json['templateId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      isCompleted: json['isCompleted'] as bool,
      scores: (json['scores'] as List<dynamic>)
          .map((e) => PlayerScore.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GameSessionToJson(_GameSession instance) =>
    <String, dynamic>{
      'sid': instance.sid,
      'templateId': instance.templateId,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'isCompleted': instance.isCompleted,
      'scores': instance.scores,
    };
