import 'dart:convert';

import 'package:counters/common/db/db_helper.dart';
import 'package:counters/common/model/league.dart';
import 'package:counters/common/model/match.dart';
import 'package:counters/common/utils/log.dart';
import 'package:sqflite/sqflite.dart';

class LeagueDao {
  final DatabaseHelper dbHelper;

  LeagueDao({required this.dbHelper});

  /// 智能保存或更新联赛及其关联的比赛。
  /// 该方法会插入新比赛，更新现有比赛，并删除不再存在的比赛。
  Future<void> saveLeague(League league) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      // 插入或更新联赛主体信息
      final leagueMap = {
        'lid': league.lid,
        'name': league.name,
        'type': league.type.name, // 使用 .name 来进行正确的枚举序列化
        'player_ids': jsonEncode(league.playerIds),
        'default_template_id': league.defaultTemplateId,
        'points_for_win': league.pointsForWin,
        'points_for_draw': league.pointsForDraw,
        'points_for_loss': league.pointsForLoss,
        'round_robin_rounds': league.roundRobinRounds,
        'current_round': league.currentRound,
      };
      await txn.insert(
        'leagues',
        leagueMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 从数据库中获取现有比赛
      final existingMatchesList = await txn
          .query('matches', where: 'league_id = ?', whereArgs: [league.lid]);
      final existingMatchesMap = {
        for (var m in existingMatchesList) m['mid'] as String: m
      };

      final incomingMatchIds = <String>{};
      final batch = txn.batch();

      // 插入或更新传入的比赛
      for (final match in league.matches) {
        incomingMatchIds.add(match.mid);
        final matchMap = _matchToDbMap(match, league.lid);

        if (existingMatchesMap.containsKey(match.mid)) {
          // 更新现有比赛
          batch.update('matches', matchMap,
              where: 'mid = ?', whereArgs: [match.mid]);
        } else {
          // 插入新比赛
          batch.insert('matches', matchMap);
        }
      }

      // 删除不再联赛中的比赛
      for (final existingMid in existingMatchesMap.keys) {
        if (!incomingMatchIds.contains(existingMid)) {
          batch.delete('matches', where: 'mid = ?', whereArgs: [existingMid]);
        }
      }

      await batch.commit(noResult: true);
    });
    Log.d('联赛id ${league.lid} 和其匹配项已保存到数据库中。');
  }

  /// 根据ID获取单个联赛。
  Future<League?> getLeague(String lid) async {
    final db = await dbHelper.database;

    final leagueMaps = await db.query(
      'leagues',
      where: 'lid = ?',
      whereArgs: [lid],
    );

    if (leagueMaps.isEmpty) {
      Log.w('未找到ID为 $lid 的联赛');
      return null;
    }

    final leagueMap = leagueMaps.first;

    final matchMaps = await db.query(
      'matches',
      where: 'league_id = ?',
      whereArgs: [lid],
      orderBy: 'round ASC',
    );

    final matches = matchMaps.map((m) => _matchFromDbMap(m)).toList();

    return _leagueFromDbMap(leagueMap, matches);
  }

  /// 高效获取所有联赛，避免N+1查询问题。
  Future<List<League>> getAllLeagues() async {
    final db = await dbHelper.database;

    // 1. 获取所有联赛
    final leagueMaps = await db.query('leagues', orderBy: 'name ASC');
    if (leagueMaps.isEmpty) {
      return [];
    }

    // 2. 获取所有比赛
    final allMatchMaps = await db.query('matches', orderBy: 'round ASC');

    // 3. 按 league_id 分组比赛
    final matchesByLeagueId = <String, List<Match>>{};
    for (final matchMap in allMatchMaps) {
      final leagueId = matchMap['league_id'] as String;
      final match = _matchFromDbMap(matchMap);
      (matchesByLeagueId[leagueId] ??= []).add(match);
    }

    // 4. 构建 League 对象
    final List<League> leagues = [];
    for (final leagueMap in leagueMaps) {
      final lid = leagueMap['lid'] as String;
      final matches = matchesByLeagueId[lid] ?? [];
      final league = _leagueFromDbMap(leagueMap, matches);
      leagues.add(league);
    }

    return leagues;
  }

  /// 删除一个联赛及其所有关联的比赛 (级联删除)。
  Future<void> deleteLeague(String lid) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      // 首先删除所有关联的比赛
      await txn.delete(
        'matches',
        where: 'league_id = ?',
        whereArgs: [lid],
      );
      // 然后删除联赛本身
      await txn.delete(
        'leagues',
        where: 'lid = ?',
        whereArgs: [lid],
      );
    });
    Log.i('已删除ID为 $lid 的联赛及其关联比赛。');
  }

  /// 清空 matches 表中的所有记录。
  Future<void> deleteAllMatches() async {
    final db = await dbHelper.database;
    await db.delete('matches');
    Log.i('已清除所有联赛比赛记录');
  }

  /// 清空 leagues 与 matches 表中的所有记录。
  Future<void> deleteAllLeagues() async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('matches');
      await txn.delete('leagues');
    });
    Log.i('已清除所有联赛配置与赛程数据');
  }

  /// 更新联赛中的单场比赛。
  Future<void> updateMatch(Match match) async {
    final db = await dbHelper.database;
    final matchMap = _matchToDbMap(match, match.leagueId);
    await db.update(
      'matches',
      matchMap,
      where: 'mid = ?',
      whereArgs: [match.mid],
    );
    Log.d('已更新ID为 ${match.mid} 的比赛。');
  }

  // 辅助方法：将 Match 对象转换为用于数据库插入的 map。
  Map<String, dynamic> _matchToDbMap(Match match, String leagueId) {
    return {
      'mid': match.mid,
      'league_id': leagueId,
      'round': match.round,
      'player1_id': match.player1Id,
      'player2_id': match.player2Id,
      'status': match.status.name,
      'player1_score': match.player1Score,
      'player2_score': match.player2Score,
      'winner_id': match.winnerId,
      'template_id': match.templateId,
      'start_time': match.startTime?.millisecondsSinceEpoch,
      'end_time': match.endTime?.millisecondsSinceEpoch,
      'bracket_type': match.bracketType?.name,
    };
  }

  // 辅助方法：从数据库 map 创建一个 Match 对象。
  Match _matchFromDbMap(Map<String, dynamic> dbMap) {
    final json = {
      'mid': dbMap['mid'],
      'leagueId': dbMap['league_id'],
      'round': dbMap['round'],
      'player1Id': dbMap['player1_id'],
      'player2Id': dbMap['player2_id'],
      'status': dbMap['status'],
      'player1Score': dbMap['player1_score'],
      'player2Score': dbMap['player2_score'],
      'winnerId': dbMap['winner_id'],
      'templateId': dbMap['template_id'],
      'startTime': dbMap['start_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(dbMap['start_time'] as int)
              .toIso8601String()
          : null,
      'endTime': dbMap['end_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(dbMap['end_time'] as int)
              .toIso8601String()
          : null,
      'bracketType': dbMap['bracket_type'],
    };
    return Match.fromJson(json);
  }

  // 辅助方法：从数据库map和比赛列表创建一个League对象。
  League _leagueFromDbMap(Map<String, dynamic> leagueMap, List<Match> matches) {
    // 手动创建League.fromJson期望的map，将数据库的snake_case列名映射到模型的camelCase字段名。
    final leagueJson = {
      'lid': leagueMap['lid'],
      'name': leagueMap['name'],
      'type': leagueMap['type'],
      'playerIds': jsonDecode(leagueMap['player_ids'] as String),
      'matches': matches.map((m) => m.toJson()).toList(),
      'defaultTemplateId': leagueMap['default_template_id'],
      'pointsForWin': leagueMap['points_for_win'],
      'pointsForDraw': leagueMap['points_for_draw'],
      'pointsForLoss': leagueMap['points_for_loss'],
      'roundRobinRounds': (leagueMap['round_robin_rounds'] as int?) ?? 1,
      'currentRound': leagueMap['current_round'],
    };
    return League.fromJson(leagueJson);
  }
}
