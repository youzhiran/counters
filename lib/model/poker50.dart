import 'package:counters/model/player_info.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import 'base_template.dart';

part 'poker50.g.dart';

@HiveType(typeId: 0)
class Poker50Template extends BaseTemplate {
  @HiveField(7, defaultValue: false)
  bool isAllowNegative;

  Poker50Template({
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
  Poker50Template copyWith({
    String? id,
    String? templateName,
    int? playerCount,
    int? targetScore,
    List<PlayerInfo>? players,
    bool? isAllowNegative,
    bool? isSystemTemplate,
    String? baseTemplateId,
  }) {
    return Poker50Template(
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

@HiveType(typeId: 2)
class GameSession {
  @HiveField(0)
  final String id; // 唯一ID

  @HiveField(1)
  final String templateId;

  @HiveField(2)
  final List<PlayerScore> scores;

  @HiveField(3)
  final DateTime startTime;

  @HiveField(4)
  DateTime? endTime; // 结束时间

  @HiveField(5, defaultValue: false)
  bool isCompleted; // 是否已完成

  GameSession({
    String? id,
    required this.templateId,
    required this.scores,
    required this.startTime,
    this.endTime,
    this.isCompleted = false,
  }) : id = id ?? Uuid().v4();
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
