// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlayerInfo _$PlayerInfoFromJson(Map<String, dynamic> json) => _PlayerInfo(
      pid: json['pid'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String,
    );

Map<String, dynamic> _$PlayerInfoToJson(_PlayerInfo instance) =>
    <String, dynamic>{
      'pid': instance.pid,
      'name': instance.name,
      'avatar': instance.avatar,
    };
