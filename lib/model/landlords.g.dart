// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'landlords.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LandlordsTemplateAdapter extends TypeAdapter<LandlordsTemplate> {
  @override
  final int typeId = 10;

  @override
  LandlordsTemplate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LandlordsTemplate(
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
  void write(BinaryWriter writer, LandlordsTemplate obj) {
    writer
      ..writeByte(8)
      ..writeByte(7)
      ..write(obj.isAllowNegative)
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
      ..write(obj.baseTemplateId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LandlordsTemplateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
