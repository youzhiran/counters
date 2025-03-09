import 'base_template.dart';
import 'player_info.dart';

class LandlordsTemplate extends BaseTemplate {
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
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'template_name': templateName,
      'player_count': playerCount,
      'target_score': targetScore,
      'is_system_template': isSystemTemplate ? 1 : 0,
      'base_template_id': baseTemplateId,
      'template_type': 'landlords',
      'is_allow_negative': isAllowNegative ? 1 : 0,
    };
  }

  static LandlordsTemplate fromMap(
      Map<String, dynamic> map, List<PlayerInfo> players) {
    return LandlordsTemplate(
      id: map['id'],
      templateName: map['template_name'],
      playerCount: map['player_count'],
      targetScore: map['target_score'],
      isSystemTemplate: map['is_system_template'] == 1,
      baseTemplateId: map['base_template_id'],
      isAllowNegative: map['is_allow_negative'] == 1,
      players: players,
    );
  }

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
