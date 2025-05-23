import 'package:counters/common/model/base_template.dart';
import 'package:counters/common/model/player_info.dart';

class LandlordsTemplate extends BaseTemplate {
  static const String templateType = 'landlords';

  LandlordsTemplate({
    super.tid,
    required super.templateName,
    required super.playerCount,
    required super.targetScore,
    required super.players,
    super.isSystemTemplate,
    super.baseTemplateId,
    int baseScore = 1,
    bool checkMultiplier = true,
    bool bombMultiplyMode = false,
  }) {
    // 初始化时设置 baseScore
    setOtherSet('baseScore', baseScore);
    setOtherSet('checkMultiplier', checkMultiplier);
    setOtherSet('bombMultiplyMode', bombMultiplyMode);
  }

  // 获取底分，默认为1
  int get baseScore => getOtherSet<int>('baseScore', defaultValue: 1) ?? 1;

  // 获取是否检查翻倍逻辑，默认为true
  bool get checkMultiplier =>
      getOtherSet<bool>('checkMultiplier', defaultValue: true) ?? true;

  // 获取炸弹翻倍方式，默认为false（增加倍数）
  bool get bombMultiplyMode =>
      getOtherSet<bool>('bombMultiplyMode', defaultValue: false) ?? false;

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

  static LandlordsTemplate fromMap(
      Map<String, dynamic> map, List<PlayerInfo> players) {
    final template = LandlordsTemplate(
      tid: map['tid'],
      templateName: map['template_name'],
      playerCount: map['player_count'],
      targetScore: map['target_score'],
      isSystemTemplate: map['is_system_template'] == 1,
      baseTemplateId: map['base_template_id'],
      players: players,
    );

    // 解析 other_set
    template.otherSetFromJson(map['other_set']);
    return template;
  }

  @override
  LandlordsTemplate copyWith({
    String? tid,
    String? templateName,
    int? playerCount,
    int? targetScore,
    List<PlayerInfo>? players,
    bool? isSystemTemplate,
    String? baseTemplateId,
    Map<String, dynamic>? otherSet,
    int? baseScore,
    bool? checkMultiplier,
    bool? bombMultiplyMode,
  }) {
    final template = LandlordsTemplate(
      tid: tid ?? this.tid,
      templateName: templateName ?? this.templateName,
      playerCount: playerCount ?? this.playerCount,
      targetScore: targetScore ?? this.targetScore,
      players: players ?? List.from(this.players),
      isSystemTemplate: isSystemTemplate ?? this.isSystemTemplate,
      baseTemplateId: baseTemplateId ?? this.baseTemplateId,
    );

    // 设置 otherSet
    template.otherSet =
        otherSet ?? Map<String, dynamic>.from(this.otherSet ?? {});
    if (baseScore != null) {
      template.setOtherSet('baseScore', baseScore);
    }
    if (checkMultiplier != null) {
      template.setOtherSet('checkMultiplier', checkMultiplier);
    }
    if (bombMultiplyMode != null) {
      template.setOtherSet('bombMultiplyMode', bombMultiplyMode);
    }

    return template;
  }
}
