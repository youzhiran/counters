import 'package:counters/model/player_info.dart';
import 'package:hive/hive.dart';

import 'base_template.dart';

part 'landlords.g.dart';

@HiveType(typeId: 10)
class LandlordsTemplate extends BaseTemplate {
  @HiveField(7, defaultValue: false)
  bool isAllowNegative;

  LandlordsTemplate({
    super.id,
    required super.templateName,
    required super.playerCount,
    required super.targetScore,
    required super.players,
    super.isSystemTemplate,
    super.baseTemplateId,
    required this.isAllowNegative,
  });

  @override
  LandlordsTemplate copyWith({
    String? id,
    String? templateName,
    int? playerCount,
    int? targetScore,
    List<PlayerInfo>? players,
    bool? isAllowNegative,
    bool? isSystemTemplate,
    String? baseTemplateId,
  }) {
    return LandlordsTemplate(
      id: id ?? this.id,
      templateName: templateName ?? this.templateName,
      playerCount: playerCount ?? this.playerCount,
      targetScore: targetScore ?? this.targetScore,
      players: players ?? List.from(this.players),
      isAllowNegative: isAllowNegative ?? this.isAllowNegative,
      isSystemTemplate: isSystemTemplate ?? this.isSystemTemplate,
      baseTemplateId: baseTemplateId ?? this.baseTemplateId,
    );
  }
}
