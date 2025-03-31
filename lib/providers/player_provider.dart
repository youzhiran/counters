import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../db/db_helper.dart';
import '../model/player_info.dart';
import '../utils/log.dart';

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

    // 一次性加载所有玩家的游玩次数
    final playCountCache = await _getAllPlayersPlayCount();

    state = state.copyWith(
      players: players,
      playCountCache: playCountCache,
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> addPlayer(PlayerInfo player) async {
    final db = await _dbHelper.database;
    await db.insert('players', player.toJson());
    await loadPlayers();
  }

  Future<void> updatePlayer(PlayerInfo player) async {
    final db = await _dbHelper.database;
    await db.update(
      'players',
      player.toJson(),
      where: 'pid = ?',
      whereArgs: [player.pid],
    );

    final newCache = Map<String, int>.from(state.playCountCache);
    newCache.remove(player.pid);

    if (state.players != null) {
      final index = state.players!.indexWhere((p) => p.pid == player.pid);
      if (index != -1) {
        final newPlayers = List<PlayerInfo>.from(state.players!);
        newPlayers[index] = player;
        state = state.copyWith(players: newPlayers, playCountCache: newCache);
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
    final newCache = Map<String, int>.from(state.playCountCache);
    newCache.remove(pid);
    state = state.copyWith(playCountCache: newCache);
    await loadPlayers();
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
    await db.rawDelete('''
      DELETE FROM players 
      WHERE pid NOT IN (
        SELECT DISTINCT player_id FROM player_scores
        UNION
        SELECT DISTINCT player_id FROM template_players
      )
    ''');
    // 清除所有缓存
    state = state.copyWith(playCountCache: {});
    await loadPlayers();
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
}

// 创建 provider
final playerProvider = NotifierProvider<PlayerNotifier, PlayerState>(() {
  return PlayerNotifier();
});
