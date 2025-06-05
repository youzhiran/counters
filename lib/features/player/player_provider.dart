import 'dart:async';

import 'package:counters/common/db/db_helper.dart';
import 'package:counters/common/model/player_info.dart';
import 'package:counters/common/utils/log.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';


class PlayerState {
  final List<PlayerInfo>? players;
  final String searchQuery;
  final Map<String, int> playCountCache;

  PlayerState({
    this.players,
    this.searchQuery = '',
    Map<String, int>? playCountCache,
  }) : playCountCache = playCountCache ?? {};

  List<PlayerInfo>? get filteredPlayers {
    if (players == null) return null;
    if (searchQuery.isEmpty) return players;
    return players!
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

class PlayerNotifier extends Notifier<PlayerState> {
  final _dbHelper = DatabaseHelper.instance;
  Timer? _searchDebounceTimer;
  String _lastSearchQuery = '';

  @override
  PlayerState build() {
    // 初始化时加载玩家数据
    loadPlayers();
    return PlayerState();
  }

  Future<void> loadPlayers() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('players');
    final players = maps.map((map) => PlayerInfo.fromJson(map)).toList();

    // 优化：只在缓存为空或玩家数量变化时重新加载游玩次数
    Map<String, int> playCountCache = state.playCountCache;
    if (playCountCache.isEmpty ||
        players.length != playCountCache.length ||
        !players.every((p) => playCountCache.containsKey(p.pid))) {
      Log.i('重新加载玩家游玩次数缓存');
      playCountCache = await _getAllPlayersPlayCount();
    }

    state = state.copyWith(
      players: players,
      playCountCache: playCountCache,
    );
  }

  void setSearchQuery(String query) {
    // 如果查询内容未变化，则不更新
    if (_lastSearchQuery == query) return;
    _lastSearchQuery = query;

    // 取消之前的延迟操作
    _searchDebounceTimer?.cancel();

    // 设置新的延迟操作
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      state = state.copyWith(searchQuery: query);
    });
  }

  Future<void> addPlayer(PlayerInfo player) async {
    final db = await _dbHelper.database;
    await db.insert('players', player.toJson());

    // 优化：增量更新而不是重新加载所有数据
    if (state.players != null) {
      final newPlayers = List<PlayerInfo>.from(state.players!)..add(player);
      final newCache = Map<String, int>.from(state.playCountCache);
      newCache[player.pid] = 0; // 新玩家游玩次数为0

      state = state.copyWith(
        players: newPlayers,
        playCountCache: newCache,
      );
    } else {
      await loadPlayers();
    }
  }

  Future<void> updatePlayer(PlayerInfo player) async {
    final db = await _dbHelper.database;
    await db.update(
      'players',
      player.toJson(),
      where: 'pid = ?',
      whereArgs: [player.pid],
    );

    // 优化：保留游玩次数缓存，只更新玩家信息
    if (state.players != null) {
      final index = state.players!.indexWhere((p) => p.pid == player.pid);
      if (index != -1) {
        final newPlayers = List<PlayerInfo>.from(state.players!);
        newPlayers[index] = player;
        state = state.copyWith(players: newPlayers);
      }
    }
  }

  Future<void> deletePlayer(String pid) async {
    final db = await _dbHelper.database;
    await db.delete(
      'players',
      where: 'pid = ?',
      whereArgs: [pid],
    );

    // 优化：增量更新而不是重新加载
    if (state.players != null) {
      final newPlayers = state.players!.where((p) => p.pid != pid).toList();
      final newCache = Map<String, int>.from(state.playCountCache);
      newCache.remove(pid);

      state = state.copyWith(
        players: newPlayers,
        playCountCache: newCache,
      );
    } else {
      await loadPlayers();
    }
  }

  Future<int> getPlayerPlayCount(String playerId) async {
    // 优先使用缓存
    if (state.playCountCache.containsKey(playerId)) {
      return state.playCountCache[playerId]!;
    }

    // 缓存未命中时查询数据库
    final count = await _queryPlayerPlayCount(playerId);
    final newCache = Map<String, int>.from(state.playCountCache);
    newCache[playerId] = count;
    state = state.copyWith(playCountCache: newCache);
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

  Future<void> cleanUnusedPlayers() async {
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

      // 优化：只清除被删除玩家的缓存
      if (state.players != null) {
        final newPlayers =
            state.players!.where((p) => !toDeleteIds.contains(p.pid)).toList();
        final newCache = Map<String, int>.from(state.playCountCache);
        for (final id in toDeleteIds) {
          newCache.remove(id);
        }

        state = state.copyWith(
          players: newPlayers,
          playCountCache: newCache,
        );
      } else {
        await loadPlayers();
      }
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
    if (playerIds.isEmpty) return;

    final db = await _dbHelper.database;
    final newCache = Map<String, int>.from(state.playCountCache);

    for (final playerId in playerIds) {
      final result = await db.rawQuery('''
        SELECT COUNT(DISTINCT session_id) as play_count
        FROM player_scores
        WHERE player_id = ?
      ''', [playerId]);

      final count = Sqflite.firstIntValue(result) ?? 0;
      newCache[playerId] = count;
    }

    state = state.copyWith(playCountCache: newCache);
    Log.i('已更新 ${playerIds.length} 个玩家的游玩次数缓存');
  }

  /// 批量获取多个玩家的游玩次数（优化版本）
  Future<Map<String, int>> getMultiplePlayerPlayCounts(
      List<String> playerIds) async {
    if (playerIds.isEmpty) return {};

    final result = <String, int>{};
    final uncachedIds = <String>[];

    // 先从缓存中获取
    for (final playerId in playerIds) {
      if (state.playCountCache.containsKey(playerId)) {
        result[playerId] = state.playCountCache[playerId]!;
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

      final newCache = Map<String, int>.from(state.playCountCache);
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

      state = state.copyWith(playCountCache: newCache);
    }

    return result;
  }
}

// 创建 provider
final playerProvider = NotifierProvider<PlayerNotifier, PlayerState>(() {
  return PlayerNotifier();
});
