import 'package:counters/model/player_score.dart';
import 'package:uuid/uuid.dart';

class GameSession {
  final String sid;
  final String templateId;
  final DateTime startTime;
  DateTime? endTime;
  bool isCompleted;
  List<PlayerScore> scores;

  GameSession({
    String? sid,
    required this.templateId,
    required this.scores,
    required this.startTime,
    this.endTime,
    this.isCompleted = false,
  }) : sid = sid ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'sid': sid,
      'template_id': templateId,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  static GameSession fromMap(Map<String, dynamic> map, List<PlayerScore> scores) {
    return GameSession(
      sid: map['sid'],
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