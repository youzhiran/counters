import 'package:flutter/material.dart';

import '../db/db_helper.dart';
import '../db/player_info.dart';

class PlayerProvider with ChangeNotifier {
  final dbHelper = DatabaseHelper.instance;
  List<PlayerInfo>? _players;
  String _searchQuery = '';

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
    _searchQuery = query;
    notifyListeners();
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
}
