import '../db/db_helper.dart';
import '../model/game_session.dart';

class GameSessionDao {
  final dbHelper = DatabaseHelper.instance;

  Future<void> insertGameSession(GameSession session) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      // 插入游戏会话
      await txn.insert('game_sessions', session.toMap());

      // 插入玩家得分
      for (var playerScore in session.scores) {
        for (int i = 0; i < playerScore.roundScores.length; i++) {
          await txn.insert('player_scores',
              playerScore.toMap(session.sid, i, playerScore.roundScores[i]));
        }
      }
    });
  }

// 添加其他必要的CRUD方法...
}
