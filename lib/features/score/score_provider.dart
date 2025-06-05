import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:counters/app/state.dart';
import 'package:counters/common/dao/game_session_dao.dart';
import 'package:counters/common/model/base_template.dart';
import 'package:counters/common/model/game_session.dart';
import 'package:counters/common/model/player_info.dart';
import 'package:counters/common/model/player_score.dart';
import 'package:counters/common/model/sync_messages.dart';
import 'package:counters/common/utils/error_handler.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/common/widgets/snackbar.dart';
// 引入 LAN Provider 和 消息 Payload 类
import 'package:counters/features/lan/lan_provider.dart';
import 'package:counters/features/player/player_provider.dart';
import 'package:counters/features/score/game_session_dao_provider.dart';
import 'package:counters/features/score/widgets/base_score_edit_dialog.dart';
import 'package:counters/features/template/template_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart'; // 确保导入 PlayerInfo 用于 applySyncState

part 'score_provider.g.dart';

// GameResult 和 ScoreState 类保持不变

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

@immutable
class ScoreState {
  final GameSession? currentSession;
  final int currentRound;
  final bool isInitialized;
  final MapEntry<String, int>? currentHighlight;
  final bool showGameEndDialog;
  final List<PlayerInfo> players;

  const ScoreState({
    this.currentSession,
    this.currentRound = 0,
    this.isInitialized = false,
    this.currentHighlight,
    this.showGameEndDialog = false,
    this.players = const [],
  });

  ScoreState copyWith({
    GameSession? currentSession,
    int? currentRound,
    bool? isInitialized,
    MapEntry<String, int>? currentHighlight,
    bool? showGameEndDialog,
    List<PlayerInfo>? players,
  }) {
    return ScoreState(
      currentSession: currentSession ?? this.currentSession,
      currentRound: currentRound ?? this.currentRound,
      isInitialized: isInitialized ?? this.isInitialized,
      currentHighlight: currentHighlight ?? this.currentHighlight,
      showGameEndDialog: showGameEndDialog ?? this.showGameEndDialog,
      players: players ?? this.players,
    );
  }

  @override
  String toString() {
    return 'ScoreState{currentSession: $currentSession, currentRound: $currentRound, '
        'isInitialized: $isInitialized, currentHighlight: $currentHighlight, showGameEndDialog: $showGameEndDialog, players: ${players.length} players}';
  }
}

@riverpod
class Score extends _$Score {
  late final GameSessionDao _sessionDao = ref.read(gameSessionDaoProvider);

  @override
  Future<ScoreState> build() async {
    Log.d('ScoreNotifier: build() called.');

    // 设置玩家游玩次数更新回调
    _sessionDao.onPlayerPlayCountUpdate = (playerIds) {
      try {
        final playerNotifier = ref.read(playerProvider.notifier);
        playerNotifier.updatePlayerPlayCounts(playerIds);
      } catch (e) {
        Log.e('更新玩家游玩次数缓存失败: $e');
      }
    };

    // 当 provider 被销毁时清理回调
    ref.onDispose(() {
      _sessionDao.onPlayerPlayCountUpdate = null;
    });

    // 优化：并行加载模板和会话数据，避免阻塞
    final futures = await Future.wait([
      _loadTemplatesWithCache(),
      _sessionDao.getLastIncompleteGameSession(),
    ]);

    final initialTemplates = futures[0] as List<BaseTemplate>?;
    final session = futures[1] as GameSession?;

    Log.d(
        'ScoreNotifier: Session from DAO: ${session?.sid}, templateId: ${session?.templateId}');
    List<PlayerInfo> initialPlayers = [];

    if (session != null) {
      final currentRound = _calculateCurrentRound(session);
      if (session.templateId.isNotEmpty) {
        final List<BaseTemplate>? templatesList =
            initialTemplates; // 使用已经 await 过的结果

        if (templatesList != null) {
          Log.d(
              'ScoreNotifier：等待的将来的可用模板 ID：${templatesList.map((t) => t.tid).join(", ")}');
          final template = templatesList
              .firstWhereOrNull((t) => t.tid == session.templateId);
          if (template != null) {
            initialPlayers = template.players;
            Log.i(
                'ScoreNotifier build: 从模板 "${template.templateName}" (TID: ${template.tid}) 加载了 ${initialPlayers.length} 个玩家信息');
          } else {
            Log.w(
                'ScoreNotifier build: 未找到模板 ID: ${session.templateId} (模板已加载，但在列表中找不到 ID).');
          }
        } else {
          Log.w(
              'ScoreNotifier build: templatesList 为 null（initialTemplates 在 await 后为 null）。找不到模板 ID：${session.templateId}.');
        }
      }
      return ScoreState(
        currentSession: session,
        currentRound: currentRound,
        isInitialized: true,
        players: initialPlayers, // initialPlayers 可能为空
      );
    }

    Log.d('ScoreNotifier: 未找到活动会话。返回默认 ScoreState。');
    return const ScoreState(isInitialized: true, players: []);
  }

  Future<void> clearAllHistory() async {
    await _sessionDao.deleteAllGameSessions();
    state = AsyncData(const ScoreState(
      currentSession: null,
      currentRound: 0,
      isInitialized: true,
      currentHighlight: null,
      showGameEndDialog: false,
      players: [],
    ));
    _broadcastResetGame();
  }

  Future<void> _saveSession() async {
    final currentState = state.valueOrNull;
    if (currentState?.currentSession == null) return;
    final sessionToSave = currentState!.currentSession!;
    await _sessionDao.saveGameSession(sessionToSave);
  }

  Future<List<GameSession>> getAllSessions() async {
    try {
      return await _sessionDao.getAllGameSessions();
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '获取会话列表失败');
      return [];
    }
  }

  Future<bool> checkSessionExists(String templateId) async {
    final count = await _sessionDao.countSessionsByTemplate(templateId);
    return count > 0;
  }

  Future<void> clearSessionsByTemplate(String templateId) async {
    await _sessionDao.deleteSessionsByTemplate(templateId);

    final currentState = state.valueOrNull;
    if (currentState != null &&
        currentState.currentSession?.templateId == templateId) {
      state = AsyncData(currentState.copyWith(
        currentSession: null,
        currentRound: 0,
        currentHighlight: null,
        showGameEndDialog: false,
        players: [],
      ));
      _broadcastResetGame();
    } else {
      state = AsyncData(
          currentState ?? const ScoreState(isInitialized: true, players: []));
    }
  }

  Future<void> deleteSession(String sessionId) async {
    await _sessionDao.deleteGameSession(sessionId);

    final currentState = state.valueOrNull;
    if (currentState != null && currentState.currentSession?.sid == sessionId) {
      state = AsyncData(currentState.copyWith(
        currentSession: null,
        currentRound: 0,
        currentHighlight: null,
        showGameEndDialog: false,
        players: [],
      ));
      _broadcastResetGame();
    } else {
      state = AsyncData(
          currentState ?? const ScoreState(isInitialized: true, players: []));
    }
  }

  int _calculateCurrentRound(GameSession session) {
    if (session.scores.isEmpty) return 0;
    return session.scores.map((s) => s.roundScores.length).fold(0, math.max);
  }

  void startNewGame(BaseTemplate template) {
    final validatedPlayers = template.players
        .map((p) => p.pid.isEmpty ? p.copyWith(pid: const Uuid().v4()) : p)
        .toList();

    final newSession = GameSession.newSession(
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
      players: validatedPlayers,
    ));

    updateHighlight();
    final lanState = ref.read(lanProvider);
    if (lanState.isHost && !lanState.isHostAndClientMode) {
      _broadcastPlayerInfo(validatedPlayers);
      _broadcastSyncState(newSession);
    }
  }

  void updateHighlight() {
    final currentState = state.valueOrNull;
    if (currentState?.currentSession == null) {
      if (currentState?.currentHighlight != null) {
        state = AsyncData(currentState!.copyWith(currentHighlight: null));
      }
      return;
    }

    final session = currentState!.currentSession!;
    final round = currentState.currentRound;

    // 遍历所有回合和玩家
    for (int r = 0; r <= round; r++) {
      for (var player in session.scores) {
        if (player.roundScores.length <= r || player.roundScores[r] == null) {
          if (currentState.currentHighlight?.key != player.playerId ||
              currentState.currentHighlight?.value != r) {
            state = AsyncData(currentState.copyWith(
              currentHighlight: MapEntry(player.playerId, r),
            ));
          }
          return;
        }
      }
    }

    if (currentState.currentHighlight != null) {
      state = AsyncData(currentState.copyWith(currentHighlight: null));
    }
  }

  void updateScore(String playerId, int roundIndex, int newScore) {
    Log.d(
        'ScoreNotifier 更新分数: Player $playerId, 第 ${roundIndex + 1} 轮, Score $newScore');
    final currentState = state.valueOrNull;
    if (currentState?.currentSession == null) {
      Log.w('updateScore 失败: 无当前会话');
      return;
    }

    // 检查分数是否超出整数范围
    if (newScore > 2147483647) {
      Log.w('分数过大，已限制为最大值: $playerId');
      newScore = 2147483647; // 限制为 int 的最大值
      AppSnackBar.warn('分数过大，已限制为最大值');
    } else if (newScore < -2147483648) {
      Log.w('分数过小，已限制为最小值: $playerId');
      newScore = -2147483648; // 限制为 int 的最小值
      AppSnackBar.warn('分数过小，已限制为最小值');
    }

    final playerScoresMap = {playerId: newScore};
    final playerExtendedDataMap = <String, Map<String, dynamic>?>{};

    updateRoundData(roundIndex, playerScoresMap, playerExtendedDataMap);
  }

  Future<void> updateRoundData(
      int roundIndex,
      Map<String, int?> playerScoresMap,
      Map<String, Map<String, dynamic>?> playerExtendedDataMap) async {
    Log.d('ScoreNotifier 更新扩展数据: 第 ${roundIndex + 1} 轮');
    final currentStateBeforeUpdate = state.valueOrNull;
    if (currentStateBeforeUpdate?.currentSession == null) {
      Log.w('updateRoundData 失败: 无当前会话');
      return;
    }

    final sessionToUpdate = currentStateBeforeUpdate!.currentSession!;

    final updatedScores = sessionToUpdate.scores.map((playerScore) {
      final scoreUpdate = playerScoresMap[playerScore.playerId];
      final extendedDataUpdate = playerExtendedDataMap[playerScore.playerId];

      if (playerScoresMap.containsKey(playerScore.playerId) ||
          playerExtendedDataMap.containsKey(playerScore.playerId)) {
        final newRoundScores = List<int?>.from(playerScore.roundScores);
        while (newRoundScores.length <= roundIndex) {
          newRoundScores.add(null);
        }
        if (playerScoresMap.containsKey(playerScore.playerId)) {
          newRoundScores[roundIndex] = scoreUpdate;
        }

        final databaseRoundNumber = roundIndex + 1;
        final newRoundExtendedFields = Map<int, Map<String, dynamic>>.from(
            playerScore.roundExtendedFields);

        if (playerExtendedDataMap.containsKey(playerScore.playerId)) {
          if (extendedDataUpdate == null) {
            newRoundExtendedFields.remove(databaseRoundNumber);
          } else {
            newRoundExtendedFields[databaseRoundNumber] = extendedDataUpdate;
          }
        }

        return playerScore.copyWith(
          roundScores: newRoundScores,
          roundExtendedFields: newRoundExtendedFields,
        );
      }
      return playerScore;
    }).toList();

    final updatedSession = sessionToUpdate.copyWith(scores: updatedScores);

    state = AsyncData(currentStateBeforeUpdate.copyWith(
      currentSession: updatedSession,
      currentRound: _calculateCurrentRound(updatedSession),
    ));

    // 检查是否显示游戏结束对话框
    final currentScoreState = state.value;
    if (currentScoreState != null && currentScoreState.currentSession != null) {
      final sessionAfterUpdate = currentScoreState.currentSession!;

      bool roundJustCompleted = sessionAfterUpdate.scores.every((ps) =>
          ps.roundScores.length > roundIndex &&
          ps.roundScores[roundIndex] != null);

      if (roundJustCompleted) {
        final template = ref
            .read(templatesProvider)
            .valueOrNull
            ?.firstWhereOrNull((t) => t.tid == sessionAfterUpdate.templateId);

        if (template != null && template.targetScore > 0) {
          final gameResult = calculateGameResult(template.targetScore);
          if (gameResult.hasFailures) {
            state = AsyncData(currentScoreState.copyWith(
              showGameEndDialog: true,
              currentHighlight: null,
            ));
          }
        }
      }
    }

    final lanState = ref.read(lanProvider);
    if (lanState.isHost && !lanState.isHostAndClientMode) {
      _broadcastSyncRoundData(updatedSession.sid, roundIndex, playerScoresMap,
          playerExtendedDataMap);
      _broadcastSyncState(updatedSession);
    }

    await _saveSession();
  }

  void resetGameEndDialog() {
    final currentState = state.valueOrNull;
    if (currentState == null || !currentState.showGameEndDialog) return;
    state = AsyncData(currentState.copyWith(
      showGameEndDialog: false,
    ));
  }

  void addNewRound() {
    final currentState = state.valueOrNull;
    if (currentState?.currentSession == null) return;

    final session = currentState!.currentSession!;
    final currentRoundIndex = _calculateCurrentRound(session);

    if (currentRoundIndex > 0) {
      final previousRoundIndex = currentRoundIndex - 1;
      final isPreviousRoundComplete = !session.scores.any((s) =>
          s.roundScores.length <= previousRoundIndex ||
          s.roundScores[previousRoundIndex] == null);

      if (!isPreviousRoundComplete) {
        Log.w('无法开始新回合，前一个回合尚未填写完整分数');
        AppSnackBar.warn('无法开始新回合，请先完成当前轮计分');
        return;
      }
    }

    final updatedScores = session.scores.map((playerScore) {
      final newRoundScores = List<int?>.from(playerScore.roundScores);
      while (newRoundScores.length < currentRoundIndex) {
        newRoundScores.add(null);
      }
      newRoundScores.add(null);

      return playerScore.copyWith(roundScores: newRoundScores);
    }).toList();

    final updatedSession = session.copyWith(scores: updatedScores);

    state = AsyncData(currentState.copyWith(
      currentSession: updatedSession,
      currentRound: currentRoundIndex + 1,
    ));

    _broadcastNewRoundPayload(
        NewRoundPayload(newRoundIndex: currentRoundIndex + 1));
    updateHighlight();
    _saveSession();
  }

  Future<void> resetGame(bool saveToHistory) async {
    final currentState = state.valueOrNull;

    if (saveToHistory && currentState?.currentSession != null) {
      final sessionToSave = currentState!.currentSession!;
      final completedSession = sessionToSave.copyWith(
        isCompleted: true,
        endTime: DateTime.now(),
      );
      await _sessionDao.saveGameSession(completedSession);
    }

    state = AsyncData(const ScoreState(
      currentSession: null,
      currentRound: 0,
      isInitialized: true,
      currentHighlight: null,
      showGameEndDialog: false,
      players: [],
    ));

    _broadcastResetGame();
  }

  void loadSession(GameSession session) {
    List<PlayerInfo> sessionPlayers = [];
    if (session.templateId.isNotEmpty) {
      final template = ref
          .read(templatesProvider)
          .valueOrNull
          ?.firstWhereOrNull((t) => t.tid == session.templateId);
      if (template != null) {
        sessionPlayers = template.players;
        Log.i(
            'ScoreNotifier loadSession: 从模板 "${template.templateName}" (TID: ${template.tid}) 加载了 ${sessionPlayers.length} 个玩家信息');
      } else {
        Log.w(
            'ScoreNotifier loadSession: 未找到模板 ID: ${session.templateId} 对应的模板，无法加载玩家列表');
      }
    }

    state = AsyncData(ScoreState(
      currentSession: session,
      currentRound: _calculateCurrentRound(session),
      isInitialized: true,
      currentHighlight: null,
      showGameEndDialog: false,
      players: sessionPlayers,
    ));
    updateHighlight();
    final lanState = ref.read(lanProvider);
    if (lanState.isHost && !lanState.isHostAndClientMode) {
      _broadcastPlayerInfo(sessionPlayers);
      _broadcastSyncState(session);
    }
  }

  GameResult calculateGameResult(int targetScore) {
    final scores = state.valueOrNull?.currentSession?.scores ?? [];
    if (scores.isEmpty ||
        scores.every((s) => s.roundScores.every((score) => score == null))) {
      return const GameResult(winners: [], losers: [], hasFailures: false);
    }

    final failScores =
        scores.where((s) => s.totalScore >= targetScore).toList();
    final hasFailures = failScores.isNotEmpty;

    final List<PlayerScore> winners;
    final List<PlayerScore> losers;

    if (hasFailures) {
      final potentialWins =
          scores.where((s) => s.totalScore < targetScore).toList();
      if (potentialWins.isEmpty) {
        winners = [];
        losers = scores.sorted((a, b) => b.totalScore.compareTo(a.totalScore));
      } else {
        potentialWins.sort((a, b) => a.totalScore.compareTo(b.totalScore));
        final minWinScore = potentialWins.first.totalScore;
        winners =
            potentialWins.where((s) => s.totalScore == minWinScore).toList();
        losers = scores.where((s) => s.totalScore >= targetScore).toList();
        losers.sort((a, b) => b.totalScore.compareTo(a.totalScore));
      }
    } else {
      final sortedScores = List<PlayerScore>.from(scores);
      sortedScores.sort((a, b) => a.totalScore.compareTo(b.totalScore));
      final minScore = sortedScores.first.totalScore;
      final maxScore = sortedScores.last.totalScore;

      if (minScore == maxScore) {
        winners = List.from(sortedScores);
        losers = [];
      } else {
        winners = sortedScores.where((s) => s.totalScore == minScore).toList();
        losers = sortedScores.where((s) => s.totalScore == maxScore).toList();
      }
    }

    return GameResult(
      winners: winners,
      losers: losers,
      hasFailures: hasFailures,
    );
  }

  void _broadcastSyncState(GameSession session) {
    final lanNotifier = ref.read(lanProvider.notifier);
    final lanState = ref.read(lanProvider);
    if (!lanState.isHost || lanState.isHostAndClientMode) {
      return;
    }

    Log.i('ScoreNotifier 广播全量同步状态');
    final payload = SyncStatePayload(session: session);
    final message = SyncMessage(type: "sync_state", data: payload.toJson());
    final jsonString = jsonEncode(message.toJson());
    lanNotifier.sendJsonMessage(jsonString);
  }

  void _broadcastSyncRoundData(
      String sessionId,
      int roundIndex,
      Map<String, int?> playerScoresMap,
      Map<String, Map<String, dynamic>?> playerExtendedDataMap) {
    final lanNotifier = ref.read(lanProvider.notifier);
    final lanState = ref.read(lanProvider);
    if (!lanState.isHost || lanState.isHostAndClientMode) return;

    Log.i('ScoreNotifier 广播轮次数据同步: Session $sessionId, Round $roundIndex');
    final data = {
      'sessionId': sessionId,
      'roundIndex': roundIndex,
      'playerScoresMap': playerScoresMap,
      'playerExtendedDataMap': playerExtendedDataMap,
    };
    final message = SyncMessage(type: "sync_round_data", data: data);
    final jsonString = jsonEncode(message.toJson());
    lanNotifier.sendJsonMessage(jsonString);
  }

  void _broadcastNewRoundPayload(NewRoundPayload payload) {
    final lanNotifier = ref.read(lanProvider.notifier);
    final lanState = ref.read(lanProvider);
    if (!lanState.isHost || lanState.isHostAndClientMode) return;

    Log.i('ScoreNotifier 广播新回合开始: ${payload.newRoundIndex}');
    final message = SyncMessage(type: "new_round", data: payload.toJson());
    final jsonString = jsonEncode(message.toJson());
    lanNotifier.sendJsonMessage(jsonString);
  }

  void _broadcastResetGame() {
    final lanNotifier = ref.read(lanProvider.notifier);
    final lanState = ref.read(lanProvider);
    if (!lanState.isHost || lanState.isHostAndClientMode) return;

    Log.i('ScoreNotifier 广播游戏重置');
    final payload = ResetGamePayload();
    final message = SyncMessage(type: "reset_game", data: payload.toJson());
    final jsonString = jsonEncode(message.toJson());
    lanNotifier.sendJsonMessage(jsonString);
  }

  void _broadcastPlayerInfo(List<PlayerInfo> players) {
    final lanNotifier = ref.read(lanProvider.notifier);
    final lanState = ref.read(lanProvider);
    if (!lanState.isHost || lanState.isHostAndClientMode) return;

    Log.i('ScoreNotifier 广播玩家信息: ${players.length} 个玩家');

    final playersJson = players.map((player) => player.toJson()).toList();

    final message = SyncMessage(type: "player_info", data: playersJson);
    final jsonString = jsonEncode(message.toJson());

    lanNotifier.sendJsonMessage(jsonString);
  }

  void broadcastInitialPlayerInfo(String templateId) {
    final currentState = state.valueOrNull;
    if (currentState?.players.isNotEmpty ?? false) {
      Log.i(
          'ScoreNotifier broadcastInitialPlayerInfo: 使用当前状态中的 ${currentState!.players.length} 个玩家信息进行广播');
      _broadcastPlayerInfo(currentState.players);
    } else {
      final template =
          ref.read(templatesProvider.notifier).getTemplate(templateId);
      if (template == null) {
        Log.w('无法广播玩家信息：找不到模板 $templateId 且当前状态无玩家');
        return;
      }
      Log.i(
          'ScoreNotifier broadcastInitialPlayerInfo: 从模板 "${template.templateName}" (TID: ${template.tid}) 获取玩家信息进行广播');
      _broadcastPlayerInfo(template.players);
    }
  }

  void applyPlayerInfo(List<PlayerInfo> players) {
    Log.i('ScoreNotifier 应用玩家信息: ${players.length} 个玩家');
    final currentState = state.valueOrNull;
    if (currentState != null) {
      state = AsyncData(currentState.copyWith(players: players));
    } else {
      Log.w('ScoreNotifier applyPlayerInfo: 当前状态为空，将创建一个仅包含玩家信息的新状态');
      state = AsyncData(ScoreState(players: players, isInitialized: true));
    }
  }

  /// 应用接收到的全量同步状态
  void applySyncState(GameSession session) {
    Log.i('ScoreNotifier 应用全量同步状态 (会话ID: ${session.sid})');
    final currentState = state.valueOrNull;
    final existingPlayers = currentState?.players ?? [];

    state = AsyncData(
      currentState?.copyWith(
            currentSession: session,
            currentRound: _calculateCurrentRound(session),
            isInitialized: true,
            currentHighlight: null,
            showGameEndDialog: false,
            // players 列表通过 copyWith 保留，或在 currentState 为 null 时使用 existingPlayers
          ) ??
          ScoreState(
            currentSession: session,
            currentRound: _calculateCurrentRound(session),
            isInitialized: true,
            players: existingPlayers,
            // 确保在初始状态时也设置
            showGameEndDialog: false,
            currentHighlight: null,
          ),
    );
    updateHighlight();

    // 客户端收到同步状态后，保存会话到本地 DAO，以便后续启动或重建时能加载
    _saveSession();
  }

  /// 应用接收到的单点分数更新 (例如 Poker50)
  void applyUpdateScore(String playerId, int roundIndex, int? score) {
    Log.i(
        'ScoreNotifier 应用单点分数更新: Player $playerId, Round $roundIndex, Score $score');
    final currentState = state.valueOrNull;
    if (currentState?.currentSession == null) {
      Log.w('应用单点分数更新失败: 无当前会话');
      return;
    }

    final sessionToUpdate = currentState!.currentSession!;
    final updatedScores = sessionToUpdate.scores.map((playerScore) {
      if (playerScore.playerId == playerId) {
        final newRoundScores = List<int?>.from(playerScore.roundScores);
        while (newRoundScores.length <= roundIndex) {
          newRoundScores.add(null);
        }
        newRoundScores[roundIndex] = score;
        return playerScore.copyWith(roundScores: newRoundScores);
      }
      return playerScore;
    }).toList();

    final updatedSession = sessionToUpdate.copyWith(scores: updatedScores);

    state = AsyncData(currentState.copyWith(
      currentSession: updatedSession,
      currentRound: _calculateCurrentRound(updatedSession),
    ));
    updateHighlight();
  }

  /// 应用接收到的轮次数据同步 (例如 Landlords)
  void applyRoundData(
      String sessionId,
      int roundIndex,
      Map<String, int?> playerScoresMap,
      Map<String, Map<String, dynamic>?> playerExtendedDataMap) {
    Log.i('ScoreNotifier 应用轮次数据同步: Session $sessionId, Round $roundIndex');
    final currentState = state.valueOrNull;
    if (currentState?.currentSession?.sid != sessionId) {
      Log.w(
          '应用轮次数据同步失败: 会话ID不匹配 (${currentState?.currentSession?.sid} != $sessionId) 或无当前会话.');
      return;
    }

    final sessionToUpdate = currentState!.currentSession!;
    final updatedScores = sessionToUpdate.scores.map((playerScore) {
      final scoreUpdate = playerScoresMap[playerScore.playerId];
      final extendedDataUpdate = playerExtendedDataMap[playerScore.playerId];

      if (playerScoresMap.containsKey(playerScore.playerId) ||
          playerExtendedDataMap.containsKey(playerScore.playerId)) {
        final newRoundScores = List<int?>.from(playerScore.roundScores);
        while (newRoundScores.length <= roundIndex) {
          newRoundScores.add(null);
        }
        if (playerScoresMap.containsKey(playerScore.playerId)) {
          newRoundScores[roundIndex] = scoreUpdate;
        }

        final databaseRoundNumber = roundIndex + 1;
        final newRoundExtendedFields = Map<int, Map<String, dynamic>>.from(
            playerScore.roundExtendedFields);

        if (playerExtendedDataMap.containsKey(playerScore.playerId)) {
          if (extendedDataUpdate == null) {
            newRoundExtendedFields.remove(databaseRoundNumber);
          } else {
            newRoundExtendedFields[databaseRoundNumber] = extendedDataUpdate;
          }
        }
        return playerScore.copyWith(
          roundScores: newRoundScores,
          roundExtendedFields: newRoundExtendedFields,
        );
      }
      return playerScore;
    }).toList();

    final updatedSession = sessionToUpdate.copyWith(scores: updatedScores);

    state = AsyncData(currentState.copyWith(
      currentSession: updatedSession,
      currentRound: _calculateCurrentRound(updatedSession),
    ));
    updateHighlight();
  }

  /// 应用接收到的新回合通知
  /// newRoundIndexFromPayload 是从网络负载中获取的，代表新的当前回合数 (1-based)
  void applyNewRound(int newRoundIndexFromPayload) {
    Log.i('ScoreNotifier 应用新回合通知: 新回合目标数量 $newRoundIndexFromPayload');
    final currentState = state.valueOrNull;
    if (currentState?.currentSession == null) {
      Log.w('应用新回合失败: 无当前会话');
      return;
    }

    // newRoundIndexFromPayload 是新的总回合数 (1-based), roundScores 列表长度应为此值
    // 列表中最后一个元素的索引是 newRoundIndexFromPayload - 1
    final targetRoundScoresLength = newRoundIndexFromPayload;

    final sessionToUpdate = currentState!.currentSession!;
    final updatedScores = sessionToUpdate.scores.map((playerScore) {
      final newRoundScores = List<int?>.from(playerScore.roundScores);
      while (newRoundScores.length < targetRoundScoresLength) {
        newRoundScores.add(null); // 为新回合添加占位符
      }
      // 如果长度超出，则截断 (理论上不应发生，但作为保护)
      // while (newRoundScores.length > targetRoundScoresLength) {
      //   newRoundScores.removeLast();
      // }
      return playerScore.copyWith(roundScores: newRoundScores);
    }).toList();

    final updatedSession = sessionToUpdate.copyWith(scores: updatedScores);

    state = AsyncData(currentState.copyWith(
      currentSession: updatedSession,
      currentRound: _calculateCurrentRound(updatedSession), // 重新计算当前回合数
    ));
    updateHighlight();
  }

  /// 应用接收到的游戏重置通知
  void applyResetGame() {
    Log.i('ScoreNotifier 应用游戏重置');
    state = AsyncData(const ScoreState(
      currentSession: null,
      currentRound: 0,
      isInitialized: true,
      currentHighlight: null,
      showGameEndDialog: false,
      players: [], // 重置时清空玩家列表
    ));
  }

  /// 应用接收到的游戏结束通知
  void applyGameEnd(/* GameEndPayload? payload */) {
    Log.i('ScoreNotifier 应用游戏结束');
    final currentState = state.valueOrNull;
    if (currentState?.currentSession == null) {
      Log.w('应用游戏结束失败: 无当前会话');
      return;
    }

    final completedSession = currentState!.currentSession!.copyWith(
      isCompleted: true,
      endTime: DateTime.now(),
    );

    state = AsyncData(currentState.copyWith(
      currentSession: completedSession,
      showGameEndDialog: true,
    ));
  }

  void broadcastTemplateInfo(BaseTemplate template) {
    final lanNotifier = ref.read(lanProvider.notifier);
    final lanState = ref.read(lanProvider);
    if (!lanState.isHost || lanState.isHostAndClientMode) return;
    final map = template.toJson();
    map['players'] = template.players.map((e) => e.toJson()).toList();
    final message = SyncMessage(type: "template_info", data: map);
    final jsonString = jsonEncode(message.toJson());
    lanNotifier.sendJsonMessage(jsonString);
    Log.i('ScoreNotifier 广播模板信息');
  }

  /// 优化：带缓存的模板加载
  Future<List<BaseTemplate>?> _loadTemplatesWithCache() async {
    try {
      Log.d('ScoreNotifier: 正在加载模板（带缓存）...');

      // 直接从Provider获取（简化版本，移除缓存依赖）
      final templates = await ref.watch(templatesProvider.future);

      Log.d('ScoreNotifier: 从Provider获取到 ${templates.length} 个模板');
      return templates;
    } catch (e, s) {
      Log.e('ScoreNotifier: 加载模板时出错： $e\nStack: $s');
      return null;
    }
  }
}

/// 分数编辑服务的 Provider
final scoreEditServiceProvider = Provider<ScoreEditService>((ref) {
  return ScoreEditService(ref);
});

/// 分数编辑服务类
class ScoreEditService {
  final Ref ref;

  ScoreEditService(this.ref);

  /// 显示轮次分数编辑弹窗
  void showRoundScoreEditDialog({
    required PlayerInfo player,
    required int roundIndex,
    required List<int?> scores,
    bool supportDecimal = false,
    int decimalMultiplier = 100,
  }) {
    final currentScore =
        roundIndex < scores.length ? scores[roundIndex] ?? 0 : 0;

    globalState.showCommonDialog(
      child: BaseScoreEditDialog(
        templateId: '',
        // 从当前会话获取
        player: player,
        initialValue: currentScore,
        supportDecimal: supportDecimal,
        decimalMultiplier: decimalMultiplier,
        round: roundIndex,
        onConfirm: (newValue) {
          ref
              .read(scoreProvider.notifier)
              .updateScore(player.pid, roundIndex, newValue);
        },
      ),
    );
  }

  /// 显示总分编辑弹窗（适用于Counter等累计分数的游戏）
  void showTotalScoreEditDialog({
    required String templateId,
    required PlayerInfo player,
    required int currentScore,
    String? title,
    String? inputLabel,
  }) {
    final scoreNotifier = ref.read(scoreProvider.notifier);

    _showScoreEditDialog(
      templateId: templateId,
      player: player,
      initialValue: currentScore,
      title: title ?? '修改总分数',
      inputLabel: inputLabel ?? '输入总分数',
      supportDecimal: false,
      onConfirm: (newValue) {
        // 更新玩家的总分数
        // 临时方案：模拟更新第一个回合的分数，以影响总分
        scoreNotifier.updateScore(player.pid, 0, newValue);
        ref.read(scoreProvider.notifier).updateHighlight();
      },
    );
  }

  /// 内部方法：显示通用的分数编辑弹窗
  void _showScoreEditDialog({
    required String templateId,
    required PlayerInfo player,
    required int initialValue,
    required ValueChanged<int> onConfirm,
    String? title,
    String? subtitle,
    String? inputLabel,
    int? round,
    bool supportDecimal = false,
    int decimalMultiplier = 100,
    bool? allowNegative,
  }) {
    globalState.showCommonDialog(
      child: BaseScoreEditDialog(
        templateId: templateId,
        player: player,
        initialValue: initialValue,
        onConfirm: onConfirm,
        title: title,
        subtitle: subtitle,
        inputLabel: inputLabel,
        round: round,
        supportDecimal: supportDecimal,
        decimalMultiplier: decimalMultiplier,
        allowNegative: allowNegative,
      ),
    );
  }
}
