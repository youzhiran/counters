import 'package:uuid/uuid.dart';

import 'player_info.dart';

abstract class BaseTemplate {
  final String id;
  String templateName;
  int playerCount;
  int targetScore;
  List<PlayerInfo> players;
  bool isSystemTemplate;
  final String? baseTemplateId;

  BaseTemplate({
    String? id,
    required this.templateName,
    required this.playerCount,
    required this.targetScore,
    required this.players,
    this.isSystemTemplate = false,
    this.baseTemplateId,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap();

  // 抽象复制方法
  BaseTemplate copyWith({
    String? id,
    String? templateName,
    int? playerCount,
    int? targetScore,
    List<PlayerInfo>? players,
    bool? isSystemTemplate,
    String? baseTemplateId,
  });
}
