import 'dart:async';

import 'package:counters/common/db/db_helper.dart';
import 'package:counters/common/model/player_info.dart';
import 'package:counters/common/utils/error_handler.dart';
import 'package:counters/common/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';

part 'player_provider.g.dart';

class PlayerState {
  final List<PlayerInfo> players;
  final String searchQuery;
  final Map<String, int> playCountCache;

  PlayerState({
    this.players = const [],
    this.searchQuery = '',
    Map<String, int>? playCountCache,
  }) : playCountCache = playCountCache ?? {};

  List<PlayerInfo> get filteredPlayers {
    if (searchQuery.isEmpty) return players;
    return players
        .where((player) =>
            player.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  PlayerState copyWith({
    List<PlayerInfo>? players,
    String? searchQuery,
    Map<String, int>? playCountCache,
  }) {
    return PlayerState(
      players: players ?? this.players,
      searchQuery: searchQuery ?? this.searchQuery,
      playCountCache: playCountCache ?? this.playCountCache,
    );
  }
}

@Riverpod(keepAlive: true)
class Player extends _$Player {
  final _dbHelper = DatabaseHelper.instance;
  Timer? _searchDebounceTimer;
  String _lastSearchQuery = '';

  @override
  Future<PlayerState> build() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('players');
    final players = maps.map((map) => PlayerInfo.fromJson(map)).toList();
    final playCountCache = await _getAllPlayersPlayCount();

    return PlayerState(
      players: players,
      playCountCache: playCountCache,
    );
  }

  void setSearchQuery(String query) {
    if (!state.hasValue) return;
    // 如果查询内容未变化，则不更新
    if (_lastSearchQuery == query) return;
    _lastSearchQuery = query;

    // 取消之前的延迟操作
    _searchDebounceTimer?.cancel();

    // 设置新的延迟操作
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      state = AsyncData(state.value!.copyWith(searchQuery: query));
    });
  }

  Future<void> addPlayer(PlayerInfo player) async {
    if (!state.hasValue) return;
    final db = await _dbHelper.database;
    await db.insert('players', player.toJson());

    final newPlayers = List<PlayerInfo>.from(state.value!.players)..add(player);
    final newCache = Map<String, int>.from(state.value!.playCountCache);
    newCache[player.pid] = 0; // 新玩家游玩次数为0

    state = AsyncData(state.value!.copyWith(
      players: newPlayers,
      playCountCache: newCache,
    ));
  }

  Future<void> updatePlayer(PlayerInfo player) async {
    if (!state.hasValue) return;
    final db = await _dbHelper.database;
    await db.update(
      'players',
      player.toJson(),
      where: 'pid = ?',
      whereArgs: [player.pid],
    );

    final index = state.value!.players.indexWhere((p) => p.pid == player.pid);
    if (index != -1) {
      final newPlayers = List<PlayerInfo>.from(state.value!.players);
      newPlayers[index] = player;
      state = AsyncData(state.value!.copyWith(players: newPlayers));
    }
  }

  Future<void> deletePlayer(String pid) async {
    if (!state.hasValue) return;
    final db = await _dbHelper.database;
    await db.delete(
      'players',
      where: 'pid = ?',
      whereArgs: [pid],
    );

    final newPlayers = state.value!.players.where((p) => p.pid != pid).toList();
    final newCache = Map<String, int>.from(state.value!.playCountCache);
    newCache.remove(pid);

    state = AsyncData(state.value!.copyWith(
      players: newPlayers,
      playCountCache: newCache,
    ));
  }

  Future<int> getPlayerPlayCount(String playerId) async {
    if (!state.hasValue) return 0;
    // 优先使用缓存
    if (state.value!.playCountCache.containsKey(playerId)) {
      return state.value!.playCountCache[playerId]!;
    }

    // 缓存未命中时查询数据库
    final count = await _queryPlayerPlayCount(playerId);
    final newCache = Map<String, int>.from(state.value!.playCountCache);
    newCache[playerId] = count;
    state = AsyncData(state.value!.copyWith(playCountCache: newCache));
    return count;
  }

  Future<int> _queryPlayerPlayCount(String playerId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT COUNT(DISTINCT session_id) as play_count 
      FROM player_scores 
      WHERE player_id = ?
    ''', [playerId]);
    Log.i("获取玩家的游玩次数");

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<bool> isPlayerInUse(String playerId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT EXISTS(
        SELECT 1 FROM player_scores WHERE player_id = ?
        UNION
        SELECT 1 FROM template_players WHERE player_id = ?
      ) as is_used
    ''', [playerId, playerId]);

    return (result.first['is_used'] as int) == 1;
  }

  Future<int> cleanUnusedPlayers() async {
    if (!state.hasValue) return 0;
    try {
      final db = await _dbHelper.database;

      // 先获取要删除的玩家ID列表
      final toDeleteResult = await db.rawQuery('''
        SELECT pid FROM players
        WHERE pid NOT IN (
          SELECT DISTINCT player_id FROM player_scores
          UNION
          SELECT DISTINCT player_id FROM template_players
        )
      ''');

      final toDeleteIds =
          toDeleteResult.map((row) => row['pid'] as String).toSet();

      if (toDeleteIds.isNotEmpty) {
        // 执行删除操作
        await db.rawDelete('''
          DELETE FROM players
          WHERE pid NOT IN (
            SELECT DISTINCT player_id FROM player_scores
            UNION
            SELECT DISTINCT player_id FROM template_players
          )
        ''');

        final newPlayers =
            state.value!.players.where((p) => !toDeleteIds.contains(p.pid)).toList();
        final newCache = Map<String, int>.from(state.value!.playCountCache);
        for (final id in toDeleteIds) {
          newCache.remove(id);
        }

        state = AsyncData(state.value!.copyWith(
          players: newPlayers,
          playCountCache: newCache,
        ));
      }

      return toDeleteIds.length;
    } catch (e) {
      // 使用统一的错误处理器
      ErrorHandler.handle(e, StackTrace.current, prefix: '清理未使用玩家失败');
      return 0;
    }
  }

  Future<Map<String, int>> _getAllPlayersPlayCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT player_id, COUNT(DISTINCT session_id) as play_count
      FROM player_scores
      GROUP BY player_id
    ''');

    return Map.fromEntries(
      result.map((row) => MapEntry(
            row['player_id'] as String,
            row['play_count'] as int,
          )),
    );
  }

  /// 增量更新特定玩家的游玩次数
  /// 当游戏会话保存后调用此方法更新相关玩家的缓存
  Future<void> updatePlayerPlayCounts(List<String> playerIds) async {
    if (playerIds.isEmpty || !state.hasValue) return;

    final db = await _dbHelper.database;
    final newCache = Map<String, int>.from(state.value!.playCountCache);

    for (final playerId in playerIds) {
      final result = await db.rawQuery('''
        SELECT COUNT(DISTINCT session_id) as play_count
        FROM player_scores
        WHERE player_id = ?
      ''', [playerId]);

      final count = Sqflite.firstIntValue(result) ?? 0;
      newCache[playerId] = count;
    }

    state = AsyncData(state.value!.copyWith(playCountCache: newCache));
    Log.i('已更新 ${playerIds.length} 个玩家的游玩次数缓存');
  }

  /// 批量获取多个玩家的游玩次数（优化版本）
  Future<Map<String, int>> getMultiplePlayerPlayCounts(
      List<String> playerIds) async {
    if (playerIds.isEmpty || !state.hasValue) return {};

    final result = <String, int>{};
    final uncachedIds = <String>[];

    // 先从缓存中获取
    for (final playerId in playerIds) {
      if (state.value!.playCountCache.containsKey(playerId)) {
        result[playerId] = state.value!.playCountCache[playerId]!;
      } else {
        uncachedIds.add(playerId);
      }
    }

    // 批量查询未缓存的玩家
    if (uncachedIds.isNotEmpty) {
      final db = await _dbHelper.database;
      final placeholders = uncachedIds.map((_) => '?').join(',');
      final dbResult = await db.rawQuery('''
        SELECT player_id, COUNT(DISTINCT session_id) as play_count
        FROM player_scores
        WHERE player_id IN ($placeholders)
        GROUP BY player_id
      ''', uncachedIds);

      final newCache = Map<String, int>.from(state.value!.playCountCache);
      for (final row in dbResult) {
        final playerId = row['player_id'] as String;
        final count = row['play_count'] as int;
        result[playerId] = count;
        newCache[playerId] = count;
      }

      // 为未找到记录的玩家设置0
      for (final playerId in uncachedIds) {
        if (!result.containsKey(playerId)) {
          result[playerId] = 0;
          newCache[playerId] = 0;
        }
      }

      state = AsyncData(state.value!.copyWith(playCountCache: newCache));
    }

    return result;
  }
}


