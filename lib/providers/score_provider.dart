import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../db/base_template.dart';
import '../db/db_helper.dart';
import '../db/poker50.dart';
import '../providers/template_provider.dart';
import '../state.dart';
import '../utils/log.dart';

class ScoreProvider with ChangeNotifier {
  final dbHelper = DatabaseHelper.instance;
  GameSession? _currentSession;
  int _currentRound = 0;

  GameSession? get currentSession => _currentSession;
  int get currentRound => _currentRound;
  MapEntry<String, int>? _currentHighlight;
  MapEntry<String, int>? get currentHighlight => _currentHighlight;

  ScoreProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadActiveSession();
  }

  Future<void> _loadActiveSession() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'game_sessions',
      where: 'is_completed = ?',
      whereArgs: [0],
      orderBy: 'start_time DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      final scores = await _loadSessionScores(maps.first['id']);
      _currentSession = GameSession.fromMap(maps.first, scores);
      _currentRound = _calculateCurrentRound();
      updateHighlight();
    }
  }

  Future<List<PlayerScore>> _loadSessionScores(String sessionId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'player_scores',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );

    // 按玩家ID分组
    final scoresByPlayer = <String, List<int?>>{};
    for (var map in maps) {
      final playerId = map['player_id'] as String;
      scoresByPlayer.putIfAbsent(playerId, () => []);
      final roundNumber = map['round_number'] as int;
      final score = map['score'] as int?;

      // 确保列表长度足够
      while (scoresByPlayer[playerId]!.length <= roundNumber) {
        scoresByPlayer[playerId]!.add(null);
      }
      scoresByPlayer[playerId]![roundNumber] = score;
    }

    return scoresByPlayer.entries
        .map((entry) => PlayerScore(
              playerId: entry.key,
              roundScores: entry.value,
            ))
        .toList();
  }

  int _calculateCurrentRound() {
    return _currentSession?.scores
            .map((s) => s.roundScores.length)
            .reduce((a, b) => a > b ? a : b) ??
        0;
  }

  Future<void> clearAllHistory() async {
    // 清除内存中的状态
    _currentSession = null;
    _currentRound = 0;

    // 清除持久化存储
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('game_sessions');
      await txn.delete('player_scores');
    });

    notifyListeners();
  }

  // 保存会话
  Future<void> _saveSession() async {
    if (_currentSession == null) return;

    final db = await dbHelper.database;
    await db.transaction((txn) async {
      // 保存会话信息
      await txn.insert(
        'game_sessions',
        _currentSession!.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 保存玩家得分
      for (var playerScore in _currentSession!.scores) {
        for (int i = 0; i < playerScore.roundScores.length; i++) {
          await txn.insert(
            'player_scores',
            playerScore.toMap(
                _currentSession!.id, i, playerScore.roundScores[i]),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }

  // 加载会话的公共方法
  void loadSession(GameSession session) {
    _currentSession = session;
    _currentRound = session.scores
        .map((s) => s.roundScores.length)
        .reduce((a, b) => a > b ? a : b);
    notifyListeners();
  }

  void startNewGame(BaseTemplate template) {
    final validatedPlayers = template.players
        .map((p) => p.id.isEmpty ? p.copyWith(id: const Uuid().v4()) : p)
        .toList();

    _currentSession = GameSession(
      templateId: template.id,
      scores: validatedPlayers
          .map((p) => PlayerScore(
                playerId: p.id,
                roundScores: [],
              ))
          .toList(),
      startTime: DateTime.now(),
    );

    _currentRound = 0; // 初始化回合数
    updateHighlight();
    notifyListeners();
  }

  // 查找第一个未填写的回合
  void updateHighlight() {
    if (_currentSession == null) return;

    for (int round = 0; round < _currentRound + 1; round++) {
      for (var player in _currentSession!.scores) {
        if (player.roundScores.length <= round ||
            player.roundScores[round] == null) {
          _currentHighlight = MapEntry(player.playerId, round);
          notifyListeners();
          return;
        }
      }
    }
    _currentHighlight = null;
  }

  void addScore(String playerId, int score, BuildContext context) {
    if (_currentSession == null) return;

    final playerScore = _currentSession!.scores.firstWhere(
      (s) => s.playerId == playerId,
      orElse: () => throw Exception('Player not found'),
    );

    playerScore.roundScores.add(score);
    _updateCurrentRound(); // 更新回合数
    _checkGameEnd(context);
    notifyListeners();
    updateHighlight();
    _saveSession();
  }

  // 删除单个会话
  Future<void> deleteSession(String sessionId) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete(
        'player_scores',
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
      await txn.delete(
        'game_sessions',
        where: 'id = ?',
        whereArgs: [sessionId],
      );
    });
    notifyListeners();
  }

  void _updateCurrentRound() {
    if (_currentSession == null) return;

    // 计算当前最大回合数
    _currentRound = _currentSession!.scores
        .map((s) => s.roundScores.length)
        .reduce((a, b) => a > b ? a : b);

    // 同步逻辑：保证所有玩家回合数相同
    for (var playerScore in _currentSession!.scores) {
      while (playerScore.roundScores.length < _currentRound) {
        playerScore.roundScores.add(null);
      }
    }
  }

  /// 检查并处理游戏结束逻辑
  /// [context]: 构建上下文
  /// 触发条件：任意玩家达到目标分数
  void _checkGameEnd(BuildContext context) {
    if (_currentSession == null) return;

    final template = context
        .read<TemplateProvider>()
        .getTemplate(_currentSession!.templateId);
    if (template == null) return;

    final targetScore = template.targetScore;
    final isGameEnded =
        _currentSession!.scores.any((s) => s.totalScore >= targetScore);

    if (isGameEnded) {
      _handleGameEnd(context);
    }
  }

  void _handleGameEnd(BuildContext context) {
    if (_currentSession == null) return;

    _currentSession = null;
    notifyListeners();

    // 标记为已完成
    _currentSession!.isCompleted = true;
    _currentSession!.endTime = DateTime.now();
    _saveSession();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      globalState.showCommonDialog(
        child: AlertDialog(
          title: const Text('游戏结束'),
          content: const Text('已有玩家达到目标分数！'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    });
  }

  /// 更新指定玩家的特定回合得分
  /// [playerId]: 玩家ID
  /// [roundIndex]: 回合索引
  /// [newScore]: 新分数值
  void updateScore(String playerId, int roundIndex, int newScore) {
    final playerScore =
        currentSession!.scores.firstWhere((s) => s.playerId == playerId);

    // 新增数组扩展逻辑
    while (playerScore.roundScores.length <= roundIndex) {
      playerScore.roundScores.add(null);
    }

    playerScore.roundScores[roundIndex] = newScore;
    _updateCurrentRound();
    notifyListeners();
    updateHighlight();
    _saveSession();
  }

  // 为所有玩家添加新回合
  void addNewRound() {
    for (var playerScore in currentSession!.scores) {
      playerScore.roundScores.add(null);
    }
    _currentRound++; // 手动更新回合数
    updateHighlight();
    notifyListeners();
  }

  void resetGame() {
    if (_currentSession != null) {
      // 标记会话为已完成
      _currentSession!.isCompleted = true;
      _currentSession!.endTime = DateTime.now();
      _saveSession(); // 保存修改到Hive
    }

    _currentSession = null;
    _currentRound = 0;
    notifyListeners();
  }

  // 获取所有会话
  Future<List<GameSession>> getAllSessions() async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'game_sessions',
        orderBy: 'start_time DESC',
      );

      final sessions = <GameSession>[];
      for (var map in maps) {
        final scores = await _loadSessionScores(map['id']);
        sessions.add(GameSession.fromMap(map, scores));
      }
      return sessions;
    } catch (e) {
      Log.w('获取会话列表失败: $e');
      return [];
    }
  }

  // 检查指定ID的会话是否存在
  Future<bool> checkSessionExists(String sessionId) async {
    final db = await dbHelper.database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM game_sessions WHERE template_id = ?',
      [sessionId],
    ));
    return count! > 0;
  }

  // 清除指定templateId关联的历史记录
  Future<void> clearSessionsByTemplate(String templateId) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      // 获取相关的会话ID
      final List<Map<String, dynamic>> sessions = await txn.query(
        'game_sessions',
        columns: ['id'],
        where: 'template_id = ?',
        whereArgs: [templateId],
      );

      for (var session in sessions) {
        final sessionId = session['id'];
        // 删除相关的得分记录
        await txn.delete(
          'player_scores',
          where: 'session_id = ?',
          whereArgs: [sessionId],
        );
      }

      // 删除会话记录
      await txn.delete(
        'game_sessions',
        where: 'template_id = ?',
        whereArgs: [templateId],
      );
    });
    notifyListeners();
  }
}
