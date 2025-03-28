import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:counters/state.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../db/db_helper.dart';
import '../model/base_template.dart';
import '../model/game_session.dart';
import '../model/player_score.dart';
import '../providers/template_provider.dart';
import '../utils/log.dart';

part 'score_provider.g.dart';

// 状态数据类
class ScoreState {
  final GameSession? currentSession;
  final int currentRound;
  final bool isInitialized;
  final MapEntry<String, int>? currentHighlight;

  const ScoreState({
    this.currentSession,
    this.currentRound = 0,
    this.isInitialized = false,
    this.currentHighlight,
  });

  ScoreState copyWith({
    GameSession? currentSession,
    int? currentRound,
    bool? isInitialized,
    MapEntry<String, int>? currentHighlight,
  }) {
    return ScoreState(
      currentSession: currentSession ?? this.currentSession,
      currentRound: currentRound ?? this.currentRound,
      isInitialized: isInitialized ?? this.isInitialized,
      currentHighlight: currentHighlight ?? this.currentHighlight,
    );
  }
}

@riverpod
class Score extends _$Score {
  final _dbHelper = DatabaseHelper.instance;

  @override
  Future<ScoreState> build() async {
    await _loadActiveSession();
    return ScoreState(isInitialized: true);
  }

  Future<List<PlayerScore>> _loadSessionScores(String sessionId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'player_scores',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );

    final scoresByPlayer = <String, PlayerScore>{};

    for (var map in maps) {
      final playerId = map['player_id'] as String;
      final roundNumber = map['round_number'] as int;
      final score = map['score'] as int?;
      final extendedField = map['extended_field'] as String?;

      final playerScore = scoresByPlayer.putIfAbsent(
        playerId,
        () => PlayerScore(playerId: playerId),
      );

      while (playerScore.roundScores.length <= roundNumber) {
        playerScore.roundScores.add(null);
      }
      playerScore.roundScores[roundNumber] = score;

      if (extendedField != null) {
        try {
          final decodedData = jsonDecode(extendedField) as Map<String, dynamic>;
          for (var entry in decodedData.entries) {
            playerScore.setRoundExtendedField(
              roundNumber,
              entry.key,
              entry.value,
            );
          }
        } catch (e) {
          Log.w('解析扩展字段失败: $e');
        }
      }
    }

    return scoresByPlayer.values.toList();
  }

  Future<void> clearAllHistory() async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('game_sessions');
      await txn.delete('player_scores');
    });

    state = AsyncData(ScoreState(
      currentSession: null,
      currentRound: 0,
      isInitialized: true,
    ));
  }

  Future<void> _saveSession() async {
    final currentState = state.valueOrNull;
    if (currentState?.currentSession == null) return;

    final session = currentState!.currentSession!;
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.insert(
        'game_sessions',
        session.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (var playerScore in session.scores) {
        for (int i = 0; i < playerScore.roundScores.length; i++) {
          await txn.insert(
            'player_scores',
            playerScore.toMap(session.sid, i, playerScore.roundScores[i]),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }

  Future<void> loadRoundExtendedData(String sessionId, int roundIndex) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'player_scores',
      where: 'session_id = ? AND round_number = ?',
      whereArgs: [sessionId, roundIndex],
    );

    final currentState = state.valueOrNull;
    if (currentState?.currentSession == null) return;

    final updatedSession = currentState!.currentSession!;
    for (var map in maps) {
      final playerId = map['player_id'] as String;
      final extendedField = map['extended_field'] as String?;

      if (extendedField != null) {
        final playerScore = updatedSession.scores.firstWhere(
          (score) => score.playerId == playerId,
          orElse: () => PlayerScore(playerId: playerId),
        );

        playerScore.extendedFiledFromJson(extendedField, roundIndex);
      }
    }

    state = AsyncData(currentState.copyWith(currentSession: updatedSession));
  }

  Future<void> _loadActiveSession() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'game_sessions',
      where: 'is_completed = ?',
      whereArgs: [0],
      orderBy: 'start_time DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      final scores = await _loadSessionScores(maps.first['sid']);
      final session = GameSession.fromMap(maps.first, scores);
      final currentRound = _calculateCurrentRound(session);

      state = AsyncData(ScoreState(
        currentSession: session,
        currentRound: currentRound,
        isInitialized: true,
      ));

      updateHighlight();
    }
  }

  int _calculateCurrentRound(GameSession? session) {
    return session?.scores
            .map((s) => s.roundScores.length)
            .reduce((a, b) => a > b ? a : b) ??
        0;
  }

  void startNewGame(BaseTemplate template) {
    final validatedPlayers = template.players
        .map((p) => p.pid.isEmpty ? p.copyWith(pid: const Uuid().v4()) : p)
        .toList();

    final newSession = GameSession(
      templateId: template.tid,
      scores: validatedPlayers
          .map((p) => PlayerScore(
                playerId: p.pid,
                roundScores: [],
              ))
          .toList(),
      startTime: DateTime.now(),
    );

    state = AsyncData(ScoreState(
      currentSession: newSession,
      currentRound: 0,
      isInitialized: true,
    ));

    updateHighlight();
  }

  void updateHighlight() {
    final currentState = state.valueOrNull;
    if (currentState?.currentSession == null) return;

    final session = currentState!.currentSession!;
    final round = currentState.currentRound;

    for (int r = 0; r < round + 1; r++) {
      for (var player in session.scores) {
        if (player.roundScores.length <= r || player.roundScores[r] == null) {
          state = AsyncData(currentState.copyWith(
            currentHighlight: MapEntry(player.playerId, r),
          ));
          return;
        }
      }
    }

    state = AsyncData(currentState.copyWith(currentHighlight: null));
  }

  void addScore(String playerId, int score) {
    final currentState = state.valueOrNull;
    if (currentState?.currentSession == null) return;

    final session = currentState!.currentSession!;
    final playerScore = session.scores.firstWhere(
      (s) => s.playerId == playerId,
      orElse: () => throw Exception('Player not found'),
    );

    playerScore.roundScores.add(score);
    _updateCurrentRound(session);
    _checkGameEnd(session);

    state = AsyncData(currentState.copyWith(
      currentSession: session,
      currentRound: _calculateCurrentRound(session),
    ));

    updateHighlight();
    _saveSession();
  }

  void _updateCurrentRound(GameSession session) {
    final currentRound = _calculateCurrentRound(session);

    for (var playerScore in session.scores) {
      while (playerScore.roundScores.length < currentRound) {
        playerScore.roundScores.add(null);
      }
    }
  }

  void _checkGameEnd(GameSession session) {
    final template = ref
        .read(templatesProvider)
        .valueOrNull
        ?.firstWhereOrNull((t) => t.tid == session.templateId);
    if (template == null) return;

    final targetScore = template.targetScore;
    final isGameEnded = session.scores.any((s) => s.totalScore >= targetScore);

    if (isGameEnded) {
      _handleGameEnd(session);
    }
  }

  void _handleGameEnd(GameSession session) {
    session.isCompleted = true;
    session.endTime = DateTime.now();
    _saveSession();

    state = AsyncData(ScoreState(
      currentSession: null,
      currentRound: 0,
      isInitialized: true,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      globalState.showCommonDialog(
        child: AlertDialog(
          title: const Text('游戏结束'),
          content: const Text('已有玩家达到目标分数！'),
          actions: [
            TextButton(
              onPressed: () => globalState..navigatorKey.currentState?.pop(),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    });
  }

  void updateScore(String playerId, int roundIndex, int newScore) {
    final currentState = state.valueOrNull;
    if (currentState?.currentSession == null) return;

    final session = currentState!.currentSession!;
    final playerScore =
        session.scores.firstWhere((s) => s.playerId == playerId);

    while (playerScore.roundScores.length <= roundIndex) {
      playerScore.roundScores.add(null);
    }

    playerScore.roundScores[roundIndex] = newScore;
    _updateCurrentRound(session);

    state = AsyncData(currentState.copyWith(
      currentSession: session,
      currentRound: _calculateCurrentRound(session),
    ));

    updateHighlight();
    _saveSession();
  }

  void addNewRound() {
    final currentState = state.valueOrNull;
    if (currentState?.currentSession == null) return;

    final session = currentState!.currentSession!;
    for (var playerScore in session.scores) {
      playerScore.roundScores.add(null);
    }

    state = AsyncData(currentState.copyWith(
      currentSession: session,
      currentRound: currentState.currentRound + 1,
    ));

    updateHighlight();
  }

  Future<void> resetGame(bool saveToHistory) async {
    final currentState = state.valueOrNull;
    if (saveToHistory && currentState?.currentSession != null) {
      final session = currentState!.currentSession!;
      session.isCompleted = true;
      session.endTime = DateTime.now();
      await _saveSession();
    }

    state = AsyncData(ScoreState(
      currentSession: null,
      currentRound: 0,
      isInitialized: true,
    ));
  }

  void loadSession(GameSession session) {
    state = AsyncData(ScoreState(
      currentSession: session,
      currentRound: _calculateCurrentRound(session),
      isInitialized: true,
    ));
    updateHighlight();
  }

  Future<List<GameSession>> getAllSessions() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'game_sessions',
        orderBy: 'start_time DESC',
      );

      final sessions = <GameSession>[];
      for (var map in maps) {
        final scores = await _loadSessionScores(map['sid']);
        sessions.add(GameSession.fromMap(map, scores));
      }
      return sessions;
    } catch (e) {
      Log.w('获取会话列表失败: $e');
      return [];
    }
  }

  Future<bool> checkSessionExists(String sessionId) async {
    final db = await _dbHelper.database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM game_sessions WHERE template_id = ?',
      [sessionId],
    ));
    return count! > 0;
  }

  Future<void> clearSessionsByTemplate(String templateId) async {
    final db = await _dbHelper.database;
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

    state = AsyncData(state.valueOrNull ?? ScoreState(isInitialized: true));
  }

  Future<void> deleteSession(String sessionId) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete(
        'player_scores',
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
      await txn.delete(
        'game_sessions',
        where: 'sid = ?',
        whereArgs: [sessionId],
      );
    });

    state = AsyncData(state.valueOrNull ?? ScoreState(isInitialized: true));
  }
}
