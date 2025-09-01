import 'package:counters/common/model/base_template.dart';
import 'package:counters/common/model/player_info.dart';

class MahjongTemplate extends BaseTemplate {
  static const String staticTemplateType = 'mahjong';

  MahjongTemplate({
    super.tid,
    required super.templateName,
    required super.playerCount,
    required super.targetScore,
    required super.players,
    required super.isSystemTemplate,
    super.baseTemplateId,
    super.disableVictoryScoreCheck,
    super.reverseWinRule,
    super.checkVictoryOnScoreChange = false,
    int baseScore = 1,
    bool checkMultiplier = false,
    bool bombMultiplyMode = false,
  }) : super(templateType: staticTemplateType) {
    setOtherSet('baseScore', baseScore);
    setOtherSet('checkMultiplier', checkMultiplier);
    setOtherSet('bombMultiplyMode', bombMultiplyMode);
  }

  int get baseScore => getOtherSet<int>('baseScore', defaultValue: 1) ?? 1;

  bool get checkMultiplier =>
      getOtherSet<bool>('checkMultiplier', defaultValue: false) ?? false;

  bool get bombMultiplyMode =>
      getOtherSet<bool>('bombMultiplyMode', defaultValue: false) ?? false;

  @override
  Map<String, dynamic> toMap() {
    return {
      'tid': tid,
      'template_type': templateType,
      'template_name': templateName,
      'player_count': playerCount,
      'target_score': targetScore,
      'is_system_template': isSystemTemplate ? 1 : 0,
      'base_template_id': baseTemplateId,
      'other_set': otherSetToJson(),
      'disable_victory_score_check': disableVictoryScoreCheck ? 1 : 0,
      'reverse_win_rule': reverseWinRule ? 1 : 0,
    };
  }

  @override
  BaseTemplate copyWith({
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
  }) {
    final newOtherSet =
        Map<String, dynamic>.from(otherSet ?? this.otherSet ?? {});

    return MahjongTemplate(
      tid: tid ?? this.tid,
      templateName: templateName ?? this.templateName,
      playerCount: playerCount ?? this.playerCount,
      targetScore: targetScore ?? this.targetScore,
      players: players ?? List.from(this.players),
      isSystemTemplate: isSystemTemplate ?? this.isSystemTemplate,
      baseTemplateId: baseTemplateId ?? this.baseTemplateId,
      disableVictoryScoreCheck:
          disableVictoryScoreCheck ?? this.disableVictoryScoreCheck,
      reverseWinRule: reverseWinRule ?? this.reverseWinRule,
      checkVictoryOnScoreChange:
          checkVictoryOnScoreChange ?? this.checkVictoryOnScoreChange,
      baseScore: newOtherSet['baseScore'] as int? ?? baseScore,
      checkMultiplier:
          newOtherSet['checkMultiplier'] as bool? ?? checkMultiplier,
      bombMultiplyMode:
          newOtherSet['bombMultiplyMode'] as bool? ?? bombMultiplyMode,
    );
  }

  static MahjongTemplate fromMap(
      Map<String, dynamic> map, List<PlayerInfo> players) {
    final template = MahjongTemplate(
      tid: map['tid'] as String,
      templateName: map['template_name'] as String,
      playerCount: map['player_count'] as int,
      targetScore: map['target_score'] as int,
      players: players,
      isSystemTemplate: map['is_system_template'] == 1,
      baseTemplateId: map['base_template_id'] as String?,
      disableVictoryScoreCheck: map['disable_victory_score_check'] == 1,
      reverseWinRule: map['reverse_win_rule'] == 1,
    );

    template.otherSetFromJson(map['other_set']);

    return template;
  }

  factory MahjongTemplate.fromJson(Map<String, dynamic> json) {
    final template = MahjongTemplate(
      tid: json['tid'] as String,
      templateName: json['templateName'] as String,
      playerCount: json['playerCount'] as int,
      targetScore: json['targetScore'] as int,
      players: (json['players'] as List)
          .map((e) => PlayerInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      isSystemTemplate: json['isSystemTemplate'] as bool,
      baseTemplateId: json['baseTemplateId'] as String?,
      disableVictoryScoreCheck:
          json['disableVictoryScoreCheck'] as bool? ?? false,
      reverseWinRule: json['reverseWinRule'] as bool? ?? false,
      baseScore: json['baseScore'] as int? ?? 1,
      checkMultiplier: json['checkMultiplier'] as bool? ?? false,
      bombMultiplyMode: json['bombMultiplyMode'] as bool? ?? false,
    );

    return template;
  }
}
