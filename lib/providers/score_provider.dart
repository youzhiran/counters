import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../db/db_helper.dart';
import '../model/base_template.dart';
import '../model/game_session.dart';
import '../model/player_score.dart';
import '../providers/template_provider.dart';
import '../utils/log.dart';

part 'generated/score_provider.g.dart';

class GameResult {
  final List<PlayerScore> winners;
  final List<PlayerScore> losers;
  final bool hasFailures;

  const GameResult({
    required this.winners,
    required this.losers,
    required this.hasFailures,
  });
}

// 状态数据类
class ScoreState {
  final GameSession? currentSession;
  final int currentRound;
  final bool isInitialized;
  final MapEntry<String, int>? currentHighlight;
  final bool showGameEndDialog;

  const ScoreState({
    this.currentSession,
    this.currentRound = 0,
    this.isInitialized = false,
    this.currentHighlight,
    this.showGameEndDialog = false,
  });

  @override
  String toString() {
    return 'ScoreState{currentSession: $currentSession, currentRound: $currentRound, '
        'isInitialized: $isInitialized, currentHighlight: $currentHighlight, showGameEndDialog: $showGameEndDialog}';
  }

  ScoreState copyWith({
    GameSession? currentSession,
    int? currentRound,
    bool? isInitialized,
    MapEntry<String, int>? currentHighlight,
    bool? showGameEndDialog,
  }) {
    return ScoreState(
      currentSession: currentSession ?? this.currentSession,
      currentRound: currentRound ?? this.currentRound,
      isInitialized: isInitialized ?? this.isInitialized,
      currentHighlight: currentHighlight ?? this.currentHighlight,
      showGameEndDialog: showGameEndDialog ?? this.showGameEndDialog,
    );
  }
}

@riverpod
class Score extends _$Score {
  final _dbHelper = DatabaseHelper.instance;

  @override
  Future<ScoreState> build() async {
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

      return ScoreState(
        currentSession: session,
        currentRound: currentRound,
        isInitialized: true,
      );
    }

    return const ScoreState(isInitialized: true);
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

    state = AsyncData(currentState.copyWith(
      currentSession: session,
      currentRound: _calculateCurrentRound(session),
    ));

    updateHighlight();
    // 务必保持在倒数第二个，前面的方法可能会影响_checkGameEnd
    _checkGameEnd(session);
    _saveSession();
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
    // 务必保持在倒数第二个，前面的方法可能会影响_checkGameEnd
    _checkGameEnd(session);
    _saveSession();
  }

  void updateRoundScores(
      GameSession session, int roundIndex, Map<String, int> playerScores) {
    final currentState = state.valueOrNull;
    if (currentState?.currentSession == null) return;

    // 更新所有玩家的分数
    for (final playerScore in session.scores) {
      final score = playerScores[playerScore.playerId];
      if (score != null) {
        while (playerScore.roundScores.length <= roundIndex) {
          playerScore.roundScores.add(null);
        }
        playerScore.roundScores[roundIndex] = score;
      }
    }

    _updateCurrentRound(session);

    state = AsyncData(currentState!.copyWith(
      currentSession: session,
      currentRound: _calculateCurrentRound(session),
    ));

    updateHighlight();
    _checkGameEnd(session);
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
    // 检查是否所有玩家的当前回合都有有效分数
    final hasIncompleteScores = session.scores
        .any((s) => s.roundScores.isEmpty || s.roundScores.last == null);
    // 检查是否有玩家达到了目标分数
    final isGameEnded = !hasIncompleteScores &&
        session.scores.any((s) => s.totalScore >= targetScore);

    if (isGameEnded) {
      _handleGameEnd(session);
    }
  }

  void resetGameEndDialog() {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    state = AsyncData(currentState.copyWith(
      showGameEndDialog: false,
    ));
  }

  void _handleGameEnd(GameSession session) {
    session.isCompleted = true;
    session.endTime = DateTime.now();
    _saveSession();

    final currentState = state.valueOrNull;
    if (currentState == null) return;

    Log.i("处理游戏结束");

    state = AsyncData(currentState.copyWith(
      showGameEndDialog: true,
    ));
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

    state = AsyncData(state.valueOrNull ??
        ScoreState(
          isInitialized: true,
        ));
  }

  GameResult calculateGameResult(int targetScore) {
    final scores = state.valueOrNull?.currentSession?.scores ?? [];

    // 划分失败玩家（分数>=目标分数）
    final failScores =
        scores.where((s) => s.totalScore >= targetScore).toList();
    final hasFailures = failScores.isNotEmpty;

    // 计算胜利者和失败者
    final List<PlayerScore> winners;
    final List<PlayerScore> losers;

    if (hasFailures) {
      final potentialWins =
          scores.where((s) => s.totalScore < targetScore).toList();
      potentialWins.sort((a, b) => a.totalScore.compareTo(b.totalScore));
      final minWinScore =
          potentialWins.isNotEmpty ? potentialWins.first.totalScore : 0;
      winners =
          potentialWins.where((s) => s.totalScore == minWinScore).toList();
      losers = failScores;
    } else {
      scores.sort((a, b) => a.totalScore.compareTo(b.totalScore));
      final minScore = scores.first.totalScore;
      final maxScore = scores.last.totalScore;
      winners = scores.where((s) => s.totalScore == minScore).toList();
      losers = scores.where((s) => s.totalScore == maxScore).toList();
    }

    return GameResult(
      winners: winners,
      losers: losers,
      hasFailures: hasFailures,
    );
  }
}
