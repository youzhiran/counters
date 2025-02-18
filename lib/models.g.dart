// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScoreTemplateAdapter extends TypeAdapter<ScoreTemplate> {
  @override
  final int typeId = 0;

  @override
  ScoreTemplate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScoreTemplate(
      id: fields[0] as String?,
      templateName: fields[1] as String,
      playerCount: fields[2] as int,
      targetScore: fields[3] as int,
      players: (fields[4] as List).cast<PlayerInfo>(),
      isSystemTemplate: fields[5] == null ? false : fields[5] as bool,
      baseTemplateId: fields[6] as String?,
      isAllowNegative: fields[7] == null ? false : fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ScoreTemplate obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.templateName)
      ..writeByte(2)
      ..write(obj.playerCount)
      ..writeByte(3)
      ..write(obj.targetScore)
      ..writeByte(4)
      ..write(obj.players)
      ..writeByte(5)
      ..write(obj.isSystemTemplate)
      ..writeByte(6)
      ..write(obj.baseTemplateId)
      ..writeByte(7)
      ..write(obj.isAllowNegative);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScoreTemplateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PlayerInfoAdapter extends TypeAdapter<PlayerInfo> {
  @override
  final int typeId = 1;

  @override
  PlayerInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlayerInfo(
      id: fields[0] as String?,
      name: fields[1] == null ? '未知玩家' : fields[1] as String,
      avatar: fields[2] == null ? 'default_avatar.png' : fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PlayerInfo obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.avatar);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GameSessionAdapter extends TypeAdapter<GameSession> {
  @override
  final int typeId = 2;

  @override
  GameSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GameSession(
      templateId: fields[0] as String,
      scores: (fields[1] as List).cast<PlayerScore>(),
      startTime: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, GameSession obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.templateId)
      ..writeByte(1)
      ..write(obj.scores)
      ..writeByte(2)
      ..write(obj.startTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PlayerScoreAdapter extends TypeAdapter<PlayerScore> {
  @override
  final int typeId = 3;

  @override
  PlayerScore read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlayerScore(
      playerId: fields[0] as String,
      roundScores: (fields[1] as List?)?.cast<int?>(),
    );
  }

  @override
  void write(BinaryWriter writer, PlayerScore obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.playerId)
      ..writeByte(1)
      ..write(obj.roundScores);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerScoreAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
