// lib/data/dao/game_session_dao.dart
import 'dart:convert';

import 'package:counters/common/db/db_helper.dart';
import 'package:counters/common/model/game_session.dart';
import 'package:counters/common/model/player_score.dart';
import 'package:counters/common/utils/log.dart';
import 'package:sqflite/sqflite.dart';

class GameSessionDao {
  final DatabaseHelper dbHelper; // 通过构造函数接收 DatabaseHelper

  // 构造函数
  GameSessionDao({required this.dbHelper});

  /// 保存完整的 GameSession 对象到数据库
  Future<void> saveGameSession(GameSession session) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      // 使用你的 toDatabaseMap 方法
      final sessionMap = session.toDatabaseMap();
      await txn.insert(
        'game_sessions',
        sessionMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 先删除旧的得分数据，确保同步
      await txn.delete(
        'player_scores',
        where: 'session_id = ?',
        whereArgs: [session.sid],
      );

      // 插入新的得分数据
      for (final playerScore in session.scores) {
        // 注意 PlayerScore 的 roundScores 列表长度决定了有多少回合有分数
        // 遍历这个列表来保存每一条得分记录
        for (int i = 0; i < playerScore.roundScores.length; i++) {
          final roundNumber = i + 1; // SQFLite 回合号通常从1开始，List索引从0开始
          final score = playerScore.roundScores[i];
          // 使用 PlayerScore 为数据库单行设计的 toSingleScoreDatabaseMap 方法
          final scoreMap = playerScore.toSingleScoreDatabaseMap(
              session.sid, roundNumber, score);

          await txn.insert(
            'player_scores',
            scoreMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        // roundExtendedFields 已经在 toSingleScoreDatabaseMap 中处理，无需额外保存
      }
    });
    Log.d('游戏会话 ${session.sid} 已保存到数据库');
  }

  /// 从数据库加载完整的 GameSession 对象
  // 包括 session 元信息和所有 player scores
  Future<GameSession?> getGameSession(String sid) async {
    final db = await dbHelper.database;

    // 1. 查询 GameSession 的元信息
    final sessionMaps = await db.query(
      'game_sessions',
      where: 'sid = ?',
      whereArgs: [sid],
    );

    if (sessionMaps.isEmpty) {
      Log.w('未找到会话ID为 $sid 的游戏会话');
      return null; // 未找到该会话
    }

    final sessionMap = sessionMaps.first;

    // 2. 查询所有相关的 PlayerScore 条目
    final scoreMaps = await db.query(
      'player_scores',
      where: 'session_id = ?',
      whereArgs: [sid],
      orderBy: 'player_id ASC, round_number ASC', // 按玩家和回合排序方便处理
    );

    // 3. 组装 PlayerScore 对象列表
    final Map<String, List<Map<String, dynamic>>> scoresByPlayer = {};
    for (final scoreMap in scoreMaps) {
      final playerId = scoreMap['player_id'] as String;
      scoresByPlayer.putIfAbsent(playerId, () => []).add(scoreMap);
    }

    final List<PlayerScore> scores = [];
    for (final playerId in scoresByPlayer.keys) {
      final playerEntries = scoresByPlayer[playerId]!;
      final List<int?> roundScores = [];
      final Map<int, Map<String, dynamic>> roundExtendedFields = {};

      // 组装 roundScores 和 roundExtendedFields
      for (final entry in playerEntries) {
        final roundNumber = entry['round_number'] as int;
        final score = entry['score'] as int?;
        final extendedFieldJson = entry['extended_field'] as String?;

        // 确保 roundScores 列表有足够的空间
        // 注意：SQFLite 的 round_number 从1开始，List 索引从0开始
        while (roundScores.length <= roundNumber - 1) {
          roundScores.add(null); // 用 null 填充缺失的回合
        }
        roundScores[roundNumber - 1] = score;

        if (extendedFieldJson != null && extendedFieldJson.isNotEmpty) {
          try {
            // roundExtendedFields 的 key 仍然使用数据库的 roundNumber (通常从1开始)
            roundExtendedFields[roundNumber] =
                jsonDecode(extendedFieldJson) as Map<String, dynamic>;
          } catch (e) {
            Log.e('解析 player_scores extended_field 失败: $e');
            // 忽略解析错误
          }
        }
      }
      // 创建 PlayerScore 对象
      scores.add(PlayerScore(
        playerId: playerId,
        roundScores: roundScores,
        roundExtendedFields: roundExtendedFields, // 传入组装好的 Map
      ));
    }

    // 4. 使用 GameSession 的 fromDatabaseMap 方法构建 GameSession 对象
    return GameSession.fromDatabaseMap(sessionMap, scores);
  }

  /// DAO 方法：获取最近一个未完成的游戏会话
  Future<GameSession?> getLastIncompleteGameSession() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'game_sessions',
      where: 'is_completed = ?',
      whereArgs: [0],
      orderBy: 'start_time DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      final sessionSid = maps.first['sid'] as String;
      return getGameSession(sessionSid); // 调用上面的方法加载完整的会话
    }
    return null; // 未找到未完成的会话
  }

  /// DAO 方法：获取所有游戏会话
  Future<List<GameSession>> getAllGameSessions() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> sessionMaps = await db.query(
      'game_sessions',
      orderBy: 'start_time DESC',
    );

    final sessions = <GameSession>[];
    for (final sessionMap in sessionMaps) {
      final sessionSid = sessionMap['sid'] as String;
      // 为每个会话调用 getGameSession 来加载完整的会话数据
      final session = await getGameSession(sessionSid);
      if (session != null) {
        sessions.add(session);
      }
    }
    return sessions;
  }

  /// DAO 方法：删除所有游戏会话和得分数据
  Future<void> deleteAllGameSessions() async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('game_sessions');
      await txn.delete('player_scores');
    });
    Log.i('已删除所有游戏会话及其得分数据');
  }

  /// DAO 方法：统计某个模板下的游戏会话数量
  Future<int> countSessionsByTemplate(String templateId) async {
    final db = await dbHelper.database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM game_sessions WHERE template_id = ?',
      [templateId],
    ));
    return count ?? 0;
  }

  /// DAO 方法：删除某个模板下的所有游戏会话和得分数据
  Future<void> deleteSessionsByTemplate(String templateId) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      final List<Map<String, dynamic>> sessions = await txn.query(
        'game_sessions',
        columns: ['sid'],
        where: 'template_id = ?',
        whereArgs: [templateId],
      );

      for (var session in sessions) {
        final sessionId = session['sid'];
        await txn.delete(
          'player_scores',
          where: 'session_id = ?',
          whereArgs: [sessionId],
        );
      }

      await txn.delete(
        'game_sessions',
        where: 'template_id = ?',
        whereArgs: [templateId],
      );
    });
    Log.i('已删除模板 $templateId 下的所有游戏会话及其得分数据');
  }

  /// DAO 方法：删除指定游戏会话及其得分数据
  Future<void> deleteGameSession(String sid) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete(
        'player_scores',
        where: 'session_id = ?',
        whereArgs: [sid],
      );
      await txn.delete(
        'game_sessions',
        where: 'sid = ?',
        whereArgs: [sid],
      );
    });
    Log.i('已删除会话ID为 $sid 的游戏会话及其得分数据');
  }

// 注意：单独更新某个回合得分或扩展字段的方法可以添加到这里，
// 但为了保持简单和与当前 Provider 逻辑一致，
// Score Provider 中的更新逻辑将继续在内存中修改 PlayerScore 对象（通过 copyWith），
// 然后调用 DAO 的 saveGameSession 方法保存整个会话。
// 如果单点更新性能非常关键，可以在 DAO 中添加更细粒度的方法。
}
