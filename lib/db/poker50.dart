import 'package:uuid/uuid.dart';
import 'base_template.dart';
import 'player_info.dart';

class Poker50Template extends BaseTemplate {
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
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'template_name': templateName,
      'player_count': playerCount,
      'target_score': targetScore,
      'is_system_template': isSystemTemplate ? 1 : 0,
      'base_template_id': baseTemplateId,
      'template_type': 'poker50',
      'is_allow_negative': isAllowNegative ? 1 : 0,
    };
  }

  static Poker50Template fromMap(Map<String, dynamic> map, List<PlayerInfo> players) {
    return Poker50Template(
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

class GameSession {
  final String id;
  final String templateId;
  final DateTime startTime;
  DateTime? endTime;
  bool isCompleted;
  List<PlayerScore> scores;

  GameSession({
    String? id,
    required this.templateId,
    required this.scores,
    required this.startTime,
    this.endTime,
    this.isCompleted = false,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'template_id': templateId,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  static GameSession fromMap(Map<String, dynamic> map, List<PlayerScore> scores) {
    return GameSession(
      id: map['id'],
      templateId: map['template_id'],
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time']),
      endTime: map['end_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['end_time'])
          : null,
      isCompleted: map['is_completed'] == 1,
      scores: scores,
    );
  }
}

class PlayerScore {
  final String playerId;
  final List<int?> roundScores;

  PlayerScore({
    required this.playerId,
    List<int?>? roundScores,
  }) : roundScores = roundScores ?? [];

  int get totalScore => roundScores.fold(0, (sum, item) => sum + (item ?? 0));

  Map<String, dynamic> toMap(String sessionId, int roundNumber, int? score) {
    return {
      'session_id': sessionId,
      'player_id': playerId,
      'round_number': roundNumber,
      'score': score,
    };
  }
}