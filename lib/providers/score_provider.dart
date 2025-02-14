import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models.dart';
import '../providers/template_provider.dart';

/// 游戏得分状态管理类
/// 职责：
/// - 管理当前游戏会话
/// - 跟踪游戏回合状态
/// - 处理得分增减操作
/// - 处理游戏结束逻辑
class ScoreProvider with ChangeNotifier {
  GameSession? _currentSession;
  int _currentRound = 0; //当前轮次索引，从0开始

  int get currentRound => _currentRound;

  GameSession? get currentSession => _currentSession;

  MapEntry<String, int>? _currentHighlight;

  MapEntry<String, int>? get currentHighlight => _currentHighlight;

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
        if (player.roundScores.length <= round || player.roundScores[round] == null) {
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
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
}
