import 'package:counters/common/model/base_template.dart';
import 'package:counters/common/model/player_info.dart';

class Poker50Template extends BaseTemplate {
  static const String staticTemplateType = 'poker50';

  Poker50Template({
    super.tid,
    required super.templateName,
    required super.playerCount,
    required super.targetScore,
    required super.players,
    super.isSystemTemplate,
    super.baseTemplateId,
    bool isAllowNegative = false,
  }) : super(templateType: staticTemplateType) {
    setOtherSet('isAllowNegative', isAllowNegative);
  }

  bool get isAllowNegative =>
      getOtherSet<bool>('isAllowNegative', defaultValue: false) ?? false;

  @override
  Map<String, dynamic> toMap() {
    return {
      'tid': tid,
      'template_name': templateName,
      'player_count': playerCount,
      'target_score': targetScore,
      'is_system_template': isSystemTemplate ? 1 : 0,
      'base_template_id': baseTemplateId,
      'template_type': templateType,
      'other_set': otherSetToJson(),
      'players': players.map((p) => p.toJson()).toList(),
    };
  }

  static Poker50Template fromMap(
      Map<String, dynamic> map, List<PlayerInfo> players) {
    final template = Poker50Template(
      tid: map['tid'],
      templateName: map['template_name'],
      playerCount: map['player_count'],
      targetScore: map['target_score'],
      isSystemTemplate: map['is_system_template'] == 1,
      baseTemplateId: map['base_template_id'],
      players: players,
    );
    template.otherSetFromJson(map['other_set']);
    return template;
  }

  @override
  Poker50Template copyWith({
    String? tid,
    String? templateType,
    String? templateName,
    int? playerCount,
    int? targetScore,
    List<PlayerInfo>? players,
    bool? isSystemTemplate,
    String? baseTemplateId,
    Map<String, dynamic>? otherSet,
    bool? isAllowNegative,
  }) {
    final template = Poker50Template(
      tid: tid ?? this.tid,
      templateName: templateName ?? this.templateName,
      playerCount: playerCount ?? this.playerCount,
      targetScore: targetScore ?? this.targetScore,
      players: players ?? List.from(this.players),
      isAllowNegative: isAllowNegative ?? this.isAllowNegative,
      isSystemTemplate: isSystemTemplate ?? this.isSystemTemplate,
      baseTemplateId: baseTemplateId ?? this.baseTemplateId,
    );

    // 设置 otherSet
    template.otherSet =
        otherSet ?? Map<String, dynamic>.from(this.otherSet ?? {});
    if (isAllowNegative != null) {
      template.setOtherSet('isAllowNegative', isAllowNegative);
    }

    return template;
  }
}
