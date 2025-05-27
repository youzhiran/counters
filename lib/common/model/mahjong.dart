import 'package:counters/common/model/base_template.dart';
import 'package:counters/common/model/player_info.dart';

class MahjongTemplate extends BaseTemplate {
  static const String templateType = 'mahjong';

  MahjongTemplate({
    super.tid,
    required super.templateName,
    required super.playerCount,
    required super.targetScore,
    required super.players,
    required super.isSystemTemplate,
    super.baseTemplateId,
    int baseScore = 1,
    bool checkMultiplier = false,
    bool bombMultiplyMode = false,
  }) : super(
          otherSet: {
            'baseScore': baseScore,
            'checkMultiplier': checkMultiplier,
            'bombMultiplyMode': bombMultiplyMode,
          },
        );

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
    };
  }

  @override
  BaseTemplate copyWith({
    String? tid,
    String? templateName,
    int? playerCount,
    int? targetScore,
    List<PlayerInfo>? players,
    bool? isSystemTemplate,
    String? baseTemplateId,
    Map<String, dynamic>? otherSet,
  }) {
    final newOtherSet =
        Map<String, dynamic>.from(otherSet ?? this.otherSet ?? {});
    if (tid != null) newOtherSet['tid'] = tid;
    if (templateName != null) newOtherSet['templateName'] = templateName;
    if (playerCount != null) newOtherSet['playerCount'] = playerCount;
    if (targetScore != null) newOtherSet['targetScore'] = targetScore;
    if (players != null) newOtherSet['players'] = players;
    if (isSystemTemplate != null)
      newOtherSet['isSystemTemplate'] = isSystemTemplate;
    if (baseTemplateId != null) newOtherSet['baseTemplateId'] = baseTemplateId;

    return MahjongTemplate(
      tid: tid ?? this.tid,
      templateName: templateName ?? this.templateName,
      playerCount: playerCount ?? this.playerCount,
      targetScore: targetScore ?? this.targetScore,
      players: players ?? this.players,
      isSystemTemplate: isSystemTemplate ?? this.isSystemTemplate,
      baseTemplateId: baseTemplateId ?? this.baseTemplateId,
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
      baseScore: json['baseScore'] as int? ?? 1,
      checkMultiplier: json['checkMultiplier'] as bool? ?? false,
      bombMultiplyMode: json['bombMultiplyMode'] as bool? ?? false,
    );

    return template;
  }
}
