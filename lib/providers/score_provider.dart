import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models.dart';
import '../providers/template_provider.dart';
import '../state.dart';

/// 游戏得分状态管理类
/// 职责：
/// - 管理当前游戏会话
/// - 跟踪游戏回合状态
/// - 处理得分增减操作
/// - 处理游戏结束逻辑
class ScoreProvider with ChangeNotifier {
  late final Box<GameSession> _sessionBox;
  GameSession? _currentSession;
  int _currentRound = 0; //当前轮次索引，从0开始

  GameSession? get currentSession => _currentSession;
  int get currentRound => _currentRound;

  MapEntry<String, int>? _currentHighlight;

  MapEntry<String, int>? get currentHighlight => _currentHighlight;

  ScoreProvider() {
    _initialize();
    _loadActiveSession();
  }

  Future<void> _initialize() async {
    try {
      if (!Hive.isBoxOpen('gameSessions')) {
        _sessionBox = await Hive.openBox<GameSession>('gameSessions');
      } else {
        _sessionBox = Hive.box<GameSession>('gameSessions');
      }
      _loadActiveSession();
    } catch (e) {
      print('Hive初始化失败: $e');
      _sessionBox = await Hive.openBox<GameSession>('gameSessions');
    }
  }

  // 加载未完成的会话
  void _loadActiveSession() {
    final sessions = _sessionBox.values.where((s) => !s.isCompleted).toList();
    if (sessions.isNotEmpty) {
      _currentSession = sessions.last;
      _currentRound = _calculateCurrentRound();
      updateHighlight();
    }
  }

  int _calculateCurrentRound() {
    return _currentSession?.scores
        .map((s) => s.roundScores.length)
        .reduce((a, b) => a > b ? a : b) ?? 0;
  }

  // 保存会话到Hive
  void _saveSession() {
    if (_currentSession != null) {
      _sessionBox.put(_currentSession!.id, _currentSession!);
    }
  }

  // 加载会话的公共方法
  void loadSession(GameSession session) {
    _currentSession = session;
    _currentRound = session.scores
        .map((s) => s.roundScores.length)
        .reduce((a, b) => a > b ? a : b);
    notifyListeners();
  }

  void startNewGame(ScoreTemplate template) {
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

  void deleteSession(String sessionId) {
    _sessionBox.delete(sessionId);
    notifyListeners();
  }

  void _updateCurrentRound() {
    if (_currentSession == null) return;

    // 计算当前最大回合数
    _currentRound = _currentSession!.scores
        .map((s) => s.roundScores.length)
        .reduce((a, b) => a > b ? a : b);

    // 新增同步逻辑：保证所有玩家回合数相同
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
    _currentSession = null;
    _currentRound = 0;
    notifyListeners();
  }

  // 获取所有会话
  List<GameSession> getAllSessions() {
    // 添加类型转换和空值保护
    try {
      return _sessionBox.values
          .whereType<GameSession>() // 类型过滤
          .toList()
          .reversed // 按时间倒序
          .toList();
    } catch (e) {
      debugPrint('获取会话列表失败: $e');
      return [];
    }
  }
}
