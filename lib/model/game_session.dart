import 'package:counters/model/player_score.dart';
import 'package:uuid/uuid.dart';

import '../utils/log.dart';

/// ScoreProvider中存游戏计分的模型
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

  @override
  String toString() {
    return 'GameSession{sid: $sid, templateId: $templateId, startTime: $startTime, '
        'endTime: $endTime, isCompleted: $isCompleted, scores: $scores}';
  }

  /// 从数据库中读取数据，将数据转换为GameSession对象
  static GameSession fromMap(
      Map<String, dynamic> map, List<PlayerScore> scores) {
    try {
      return GameSession(
        sid: map['sid'],
        templateId: map['template_id'],
        startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time'] is int
            ? map['start_time']
            : int.parse(map['start_time'])),
        endTime: map['end_time'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['end_time'] is int
                ? map['end_time']
                : int.parse(map['end_time']))
            : null,
        isCompleted: map['is_completed'] == 1,
        scores: scores,
      );
    } catch (e) {
      Log.e('解析GameSession失败: $e');
      return GameSession(
        templateId: map['template_id'] ?? 'error',
        scores: scores,
        startTime: DateTime.now(),
      );
    }
  }
}
