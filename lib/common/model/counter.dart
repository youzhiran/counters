import 'package:counters/common/model/base_template.dart';
import 'package:counters/common/model/player_info.dart';

class CounterTemplate extends BaseTemplate {
  static const String staticTemplateType = 'counter';

  CounterTemplate({
    super.tid,
    required super.templateName,
    required super.playerCount,
    required super.targetScore,
    required super.players,
    super.isSystemTemplate,
    super.baseTemplateId,
    super.disableVictoryScoreCheck,
    super.reverseWinRule,
    super.checkVictoryOnScoreChange = true,
    bool isAllowNegative = false,
  }) : super(templateType: staticTemplateType) {
    setOtherSet('isAllowNegative', isAllowNegative);
  }

  bool get isAllowNegative =>
      getOtherSet<bool>('isAllowNegative', defaultValue: false) ?? false;

  @override
  List<String> getValidOtherSetKeys() {
    return ['isAllowNegative'];
  }

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
      'disable_victory_score_check': disableVictoryScoreCheck ? 1 : 0,
      'reverse_win_rule': reverseWinRule ? 1 : 0,
      'players': players.map((p) => p.toJson()).toList(),
    };
  }

  static CounterTemplate fromMap(
      Map<String, dynamic> map, List<PlayerInfo> players) {
    final template = CounterTemplate(
      tid: map['tid'],
      templateName: map['template_name'],
      playerCount: map['player_count'],
      targetScore: map['target_score'],
      isSystemTemplate: map['is_system_template'] == 1,
      baseTemplateId: map['base_template_id'],
      disableVictoryScoreCheck: map['disable_victory_score_check'] == 1,
      reverseWinRule: map['reverse_win_rule'] == 1,
      players: players,
    );
    template.otherSetFromJson(map['other_set']);
    return template;
  }

  @override
  CounterTemplate copyWith({
    String? tid,
    String? templateType,
    String? templateName,
    int? playerCount,
    int? targetScore,
    List<PlayerInfo>? players,
    bool? isSystemTemplate,
    String? baseTemplateId,
    Map<String, dynamic>? otherSet,
    bool? disableVictoryScoreCheck,
    bool? reverseWinRule,
    bool? checkVictoryOnScoreChange,
    bool? isAllowNegative,
  }) {
    final template = CounterTemplate(
      tid: tid ?? this.tid,
      templateName: templateName ?? this.templateName,
      playerCount: playerCount ?? this.playerCount,
      targetScore: targetScore ?? this.targetScore,
      players: players ?? List.from(this.players),
      isAllowNegative: isAllowNegative ?? this.isAllowNegative,
      isSystemTemplate: isSystemTemplate ?? this.isSystemTemplate,
      baseTemplateId: baseTemplateId ?? this.baseTemplateId,
      disableVictoryScoreCheck:
          disableVictoryScoreCheck ?? this.disableVictoryScoreCheck,
      reverseWinRule: reverseWinRule ?? this.reverseWinRule,
      checkVictoryOnScoreChange:
          checkVictoryOnScoreChange ?? this.checkVictoryOnScoreChange,
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
