import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'models.g.dart'; // 生成文件引用

@HiveType(typeId: 0)
class ScoreTemplate {
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
  final String? baseTemplateId;

  @HiveField(7, defaultValue: false)
  bool isAllowNegative;

  ScoreTemplate({
    String? id,
    required this.templateName,
    required this.playerCount,
    required this.targetScore,
    required this.players,
    this.isSystemTemplate = false,  // 是否系统模板
    this.baseTemplateId,  // 来源字段
    required this.isAllowNegative,
  }) : id = id ?? Uuid().v4();

  // 复制方法
  ScoreTemplate copyWith({
    String? id,
    String? templateName,
    int? playerCount,
    int? targetScore,
    List<PlayerInfo>? players,
    bool? isAllowNegative,
    bool? isSystemTemplate,
    String? baseTemplateId,
  }) {
    return ScoreTemplate(
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

@HiveType(typeId: 1)
class PlayerInfo {
  @HiveField(0)
  final String id;

  @HiveField(1, defaultValue: '未知玩家')
  String name;

  @HiveField(2, defaultValue: 'default_avatar.png')
  String avatar;

  PlayerInfo({
    String? id,
    required this.name,
    required this.avatar,
  }) : id = id ?? Uuid().v4();

  // 修复 copyWith 方法
  PlayerInfo copyWith({
    String? id, // 添加 id 参数
    String? name,
    String? avatar,
  }) {
    return PlayerInfo(
      id: id ?? this.id, // 允许覆盖 ID
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
    );
  }
}



@HiveType(typeId: 2)
class GameSession {
  @HiveField(0)
  final String templateId;

  @HiveField(1)
  final List<PlayerScore> scores;

  @HiveField(2)
  final DateTime startTime;

  GameSession({
    required this.templateId,
    required this.scores,
    required this.startTime,
  });
}

@HiveType(typeId: 3)
class PlayerScore {
  @HiveField(0)
  final String playerId;

  @HiveField(1)
  final List<int?> roundScores; // 修改为可空列表

  PlayerScore({
    required this.playerId,
    List<int?>? roundScores,
  }) : roundScores = roundScores ?? [];

  // 修改总分计算逻辑（处理null值）
  int get totalScore => roundScores.fold(0, (sum, item) => sum + (item ?? 0));
}