// 模板基类
import 'package:counters/model/player_info.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

@HiveType(typeId: 4)
abstract class BaseTemplate {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String templateName;

  @HiveField(2)
  int playerCount;

  @HiveField(3)
  int targetScore;

  @HiveField(4)
  List<PlayerInfo> players;

  @HiveField(5, defaultValue: false)
  bool isSystemTemplate;

  @HiveField(6, defaultValue: null)
  final String? baseTemplateId; // 来源字段

  BaseTemplate({
    String? id,
    required this.templateName,
    required this.playerCount,
    required this.targetScore,
    required this.players,
    this.isSystemTemplate = false,
    this.baseTemplateId,
  }) : id = id ?? Uuid().v4();

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


