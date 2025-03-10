import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../db/db_helper.dart';
import '../db/player_info.dart';

class PlayerProvider with ChangeNotifier {
  final dbHelper = DatabaseHelper.instance;
  List<PlayerInfo>? _players;
  String _searchQuery = '';
  Timer? _debounceTimer;

  List<PlayerInfo>? get players => _players;

  String get searchQuery => _searchQuery;

  List<PlayerInfo>? get filteredPlayers {
    if (_players == null) return null;
    if (_searchQuery.isEmpty) return _players;
    return _players!
        .where((player) =>
            player.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  PlayerProvider() {
    _initialize();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('players');
    _players = maps.map((map) => PlayerInfo.fromMap(map)).toList();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    // 取消之前的延迟操作
    _debounceTimer?.cancel();

    // 设置新的延迟操作
    _debounceTimer = Timer(Duration(milliseconds: 300), () {
      if (_searchQuery != query) {
        _searchQuery = query;
        notifyListeners();
      }
    });
  }

  Future<void> addPlayer(PlayerInfo player) async {
    final db = await dbHelper.database;
    await db.insert('players', player.toMap());
    await _loadPlayers();
  }

  Future<void> updatePlayer(PlayerInfo player) async {
    final db = await dbHelper.database;
    await db.update(
      'players',
      player.toMap(),
      where: 'id = ?',
      whereArgs: [player.id],
    );
    await _loadPlayers();
  }

  Future<void> deletePlayer(String id) async {
    final db = await dbHelper.database;
    await db.delete(
      'players',
      where: 'id = ?',
      whereArgs: [id],
    );
    await _loadPlayers();
  }

  Future<void> deleteAllPlayers() async {
    final db = await dbHelper.database;
    await db.delete('players');
    await _loadPlayers();
  }

  /// 获取玩家的游玩次数
  /// 通过统计 player_scores 表中不同 session_id 的数量来计算
  Future<int> getPlayerPlayCount(String playerId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery('''
      SELECT COUNT(DISTINCT session_id) as play_count 
      FROM player_scores 
      WHERE player_id = ?
    ''', [playerId]);

    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 获取所有玩家的游玩次数
  Future<Map<String, int>> getAllPlayersPlayCount() async {
    final db = await dbHelper.database;
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
