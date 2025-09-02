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
import 'package:counters/common/providers/league_provider.dart';
import 'package:counters/common/utils/error_handler.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/common/widgets/message_overlay.dart';
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
import 'package:uuid/uuid.dart';

part 'score_provider.g.dart';

// GameResult 和 ScoreState 类保持不变

class GameResult {
  final List<PlayerScore> winners;
  final List<PlayerScore> losers;
  final bool havTargetScore;

  const GameResult({
    required this.winners,
    required this.losers,
    required this.havTargetScore,
  });
}

@immutable
class ScoreState {
  final GameSession? currentSession;
  final List<GameSession> ongoingSessions; // 新增：进行中的会话列表
  final BaseTemplate? template; // 当前会话使用的模板
  final int currentRound;
  final bool isInitialized;
  final MapEntry<String, int>? currentHighlight;
  final bool showGameEndDialog;
  final List<PlayerInfo> players;
  final bool isTempMode; // 是否为临时计分模式

  const ScoreState({
    this.currentSession,
    this.ongoingSessions = const [], // 默认值
    this.template,
    this.currentRound = 0,
    this.isInitialized = false,
    this.currentHighlight,
    this.showGameEndDialog = false,
    this.players = const [],
    this.isTempMode = false,
  });

  ScoreState copyWith({
    GameSession? currentSession,
    List<GameSession>? ongoingSessions,
    BaseTemplate? template,
    int? currentRound,
    bool? isInitialized,
    MapEntry<String, int>? currentHighlight,
    bool? showGameEndDialog,
    List<PlayerInfo>? players,
    bool? isTempMode,
  }) {
    return ScoreState(
      currentSession: currentSession ?? this.currentSession,
      ongoingSessions: ongoingSessions ?? this.ongoingSessions,
      template: template ?? this.template,
      currentRound: currentRound ?? this.currentRound,
      isInitialized: isInitialized ?? this.isInitialized,
      currentHighlight: currentHighlight ?? this.currentHighlight,
      showGameEndDialog: showGameEndDialog ?? this.showGameEndDialog,
      players: players ?? this.players,
      isTempMode: isTempMode ?? this.isTempMode,
    );
  }

  @override
  String toString() {
    return 'ScoreState{currentSession: $currentSession, ongoingSessions: ${ongoingSessions.length}, template: ${template?.templateName}, currentRound: $currentRound, '
        'isInitialized: $isInitialized, currentHighlight: $currentHighlight, showGameEndDialog: $showGameEndDialog, players: ${players.length} players, isTempMode: $isTempMode}';
  }
}

@Riverpod(keepAlive: true)
class Score extends _$Score {
  late final GameSessionDao _sessionDao = ref.read(gameSessionDaoProvider);

  @override
  Future<ScoreState> build() async {
    Log.d('ScoreNotifier: build() called.');

    // 修复：如果状态已经初始化，直接返回当前状态，防止不必要的重建
    final currentState = state.valueOrNull;
    if (currentState != null && currentState.isInitialized) {
      Log.d(
          'ScoreNotifier: State already initialized, returning current state.');
      return currentState;
    }

    // 依赖的其他Provider，等待它们加载完成
    // 修复：使用 ref.read 替代 ref.watch，避免不必要的重建
    final initialTemplates = await ref.read(templatesProvider.future);
    final allLeagues = (await ref.read(leagueNotifierProvider.future)).leagues;
    final allPlayers = (await ref.read(playerProvider.future)).players;

    // 当 provider 被销毁时清理回调
    ref.onDispose(() {
      _sessionDao.onPlayerPlayCountUpdate = null;
    });

    // 修复：检查是否在联机模式下且已有状态，如果是则保持当前状态
    final lanState = ref.read(lanProvider);
    if ((lanState.isConnected || lanState.isHost) &&
        currentState != null &&
        currentState.isInitialized &&
        currentState.currentSession != null) {
      Log.d('ScoreNotifier: 联机模式下保持当前状态，避免重新加载');
      return currentState;
    }

    final ongoingSessions = await _sessionDao.getAllIncompleteGameSessions();
    final session = ongoingSessions.firstOrNull;

    Log.d(
        'ScoreNotifier: Session from DAO: ${session?.sid}, templateId: ${session?.templateId}');
    BaseTemplate? initialTemplate;
    List<PlayerInfo> initialPlayers = [];

    if (session != null) {
      // 检查是否为联赛对局
      if (session.leagueMatchId != null) {
        Log.d('ScoreNotifier: 为联赛重建状态...');
        // 1. 找到基础系统模板
        final baseTemplate = initialTemplates
            .firstWhereOrNull((t) => t.tid == session.templateId);

        // 2. 找到联赛和比赛信息
        final league = allLeagues.firstWhereOrNull(
            (l) => l.matches.any((m) => m.mid == session.leagueMatchId));
        final match = league?.matches
            .firstWhereOrNull((m) => m.mid == session.leagueMatchId);

        // 3. 找到比赛玩家
        final player1 =
            allPlayers.firstWhereOrNull((p) => p.pid == match?.player1Id);
        final player2 =
            allPlayers.firstWhereOrNull((p) => p.pid == match?.player2Id);

        if (baseTemplate != null &&
            league != null &&
            match != null &&
            player1 != null &&
            player2 != null) {
          // 4. 重新创建临时比赛模板
          initialTemplate = baseTemplate.copyWith(
            tid: 'temp_league_${match.mid}',
            // 临时的、唯一的ID
            templateName: '${league.name}: ${player1.name} vs ${player2.name}',
            playerCount: 2,
            players: [player1, player2],
            isSystemTemplate: false,
          );
          initialPlayers = initialTemplate.players;
          Log.i('[联赛]重建的临时模板: ${initialTemplate.templateName}');
        } else {
          Log.e('[联赛]无法重建状态：缺少一些信息。');
          Log.e(
              'baseTemplate=$baseTemplate;league=$league,match=$match,player1=$player1,player2=$player2');
        }
      } else {
        // 普通对局的状态重建
        initialTemplate = initialTemplates
            .firstWhereOrNull((t) => t.tid == session.templateId);
        if (initialTemplate != null) {
          initialPlayers = initialTemplate.players;
        }
      }

      final currentRound = _calculateCurrentRound(session);
      return ScoreState(
        currentSession: session,
        ongoingSessions: ongoingSessions,
        template: initialTemplate,
        currentRound: currentRound,
        isInitialized: true,
        players: initialPlayers,
        isTempMode: false,
      );
    }

    Log.d('ScoreNotifier: 未找到活动会话。返回默认 ScoreState。');
    // 修复：即使没有当前活动会话，也要确保加载了所有进行中的会话
    final allOngoing = await _sessionDao.getAllIncompleteGameSessions();
    return ScoreState(
        ongoingSessions: allOngoing,
        isInitialized: true,
        players: [],
        isTempMode: false);
  }

  Future<void> clearAllHistory() async {
    await _sessionDao.deleteAllGameSessions();
    state = AsyncData(const ScoreState(
      currentSession: null,
      ongoingSessions: [],
      template: null,
      currentRound: 0,
      isInitialized: true,
      currentHighlight: null,
      showGameEndDialog: false,
      players: [],
      isTempMode: false,
    ));
    _broadcastResetGame();
  }

  /// 检查当前是否为客户端模式（连接到主机但不是主机，或处于客户端模式状态）
  bool _isClientMode() {
    final lanState = ref.read(lanProvider);
    // 客户端模式：处于客户端模式状态（无论是否连接）
    return lanState.isClientMode;
  }

  /// 统一的客户端限制检查
  /// 如果是客户端模式，显示错误提示并返回true（表示操作被阻止）
  /// 如果不是客户端模式，返回false（表示可以继续操作）
  bool _checkAndHandleClientRestriction() {
    if (_isClientMode()) {
      GlobalMsgManager.showMessage('仅主机可以进行计分操作');
      return true;
    }
    return false;
  }

  /// 清理客户端模式下的临时数据（当断开连接时调用）
  void clearClientModeData() {
    if (!_isClientMode()) {
      Log.d('非客户端模式，跳过临时数据清理');
      return;
    }

    Log.i('客户端模式：清理临时数据（会话、玩家信息等）');
    state = AsyncData(const ScoreState(
      currentSession: null,
      ongoingSessions: [],
      currentRound: 0,
      isInitialized: true,
      currentHighlight: null,
      showGameEndDialog: false,
      players: [],
      // 清空玩家信息
      isTempMode: false,
    ));
  }

  Future<void> _saveSession() async {
    final currentState = state.valueOrNull;

    // 临时模式下不保存会话到本地数据库
    if (currentState?.isTempMode == true) {
      Log.i('临时计分模式：跳过会话保存，数据仅保存在内存中');
      return;
    }

    // 修复：客户端模式下不保存会话到本地数据库
    if (_isClientMode()) {
      Log.i('客户端模式：跳过会话保存，数据仅保存在内存中');
      return;
    }

    if (currentState?.currentSession == null) return;
    final sessionToSave = currentState!.currentSession!;
    await _sessionDao.saveGameSession(sessionToSave);
    Log.d('主机模式：会话已保存到本地数据库');
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
        template: null,
        currentRound: 0,
        currentHighlight: null,
        showGameEndDialog: false,
        players: [],
      ));
      _broadcastResetGame();
    } else {
      state = AsyncData(currentState ??
          const ScoreState(
              isInitialized: true, players: [], isTempMode: false));
    }
  }

  Future<void> deleteSession(String sessionId) async {
    await _sessionDao.deleteGameSession(sessionId);

    final currentState = state.valueOrNull;
    if (currentState != null && currentState.currentSession?.sid == sessionId) {
      state = AsyncData(currentState.copyWith(
        currentSession: null,
        template: null,
        currentRound: 0,
        currentHighlight: null,
        showGameEndDialog: false,
        players: [],
      ));
      _broadcastResetGame();
    } else {
      state = AsyncData(currentState ??
          const ScoreState(
              isInitialized: true, players: [], isTempMode: false));
    }
  }

  int _calculateCurrentRound(GameSession session) {
    if (session.scores.isEmpty) return 0;
    return session.scores.map((s) => s.roundScores.length).fold(0, math.max);
  }

  Future<void> startNewGame(
    BaseTemplate template, {
    String? leagueMatchId,
    String? persistentTemplateId, // 用于持久化的模板ID
  }) async {
    Log.d(
        '[ScoreProvider] startNewGame called with template: ${template.templateName} (ID: ${template.tid}, Type: ${template.runtimeType}) and leagueMatchId: $leagueMatchId');

    // 修复联赛计分：检查是否已有该比赛的会话
    if (leagueMatchId != null) {
      final existingSession =
          await _sessionDao.getSessionByLeagueMatchId(leagueMatchId);
      if (existingSession != null) {
        Log.i(
            '[联赛] 发现已存在的未完成会话: ${existingSession.sid} for match: $leagueMatchId. 正在恢复...');
        // 如果找到，直接加载这个会话状态
        final validatedPlayers = template.players
            .map((p) => p.pid.isEmpty ? p.copyWith(pid: const Uuid().v4()) : p)
            .toList();

        final scoreState = ScoreState(
          currentSession: existingSession,
          template: template,
          // 使用新的临时模板，因为它包含正确的玩家信息
          currentRound: _calculateCurrentRound(existingSession),
          isInitialized: true,
          players: validatedPlayers,
          isTempMode: false,
        );
        state = AsyncData(scoreState);
        updateHighlight();
        // 可选：广播状态
        final lanState = ref.read(lanProvider);
        if (lanState.isHost) {
          broadcastTemplateInfo(template);
          _broadcastPlayerInfo(validatedPlayers);
          _broadcastSyncState(existingSession);
        }
        return; // 结束方法，不再创建新会话
      }
    }

    final validatedPlayers = template.players
        .map((p) => p.pid.isEmpty ? p.copyWith(pid: const Uuid().v4()) : p)
        .toList();

    final newSession = GameSession.newSession(
      // Session中保存的ID应该是持久化的ID，而不是临时ID
      templateId: persistentTemplateId ?? template.tid,
      scores: validatedPlayers
          .map((p) => PlayerScore(
                playerId: p.pid,
                roundScores: [],
              ))
          .toList(),
      startTime: DateTime.now(),
      leagueMatchId: leagueMatchId, // Pass the league match ID
    );
    Log.d(
        '[ScoreProvider] Created new GameSession: ${newSession.sid} for template: ${newSession.templateId}');

    final currentOngoing = state.value?.ongoingSessions ?? [];
    final updatedOngoing = [newSession, ...currentOngoing];

    final newScoreState = ScoreState(
      currentSession: newSession,
      ongoingSessions: updatedOngoing,
      template: template,
      // 状态中持有的是临时的、包含具体玩家的模板
      currentRound: 0,
      isInitialized: true,
      players: validatedPlayers,
      isTempMode: false,
    );
    Log.d('[ScoreProvider] Setting new ScoreState: $newScoreState');
    state = AsyncData(newScoreState);

    updateHighlight();
    final lanState = ref.read(lanProvider);
    if (lanState.isHost) {
      Log.d('[ScoreProvider] Broadcasting state for host.');
      broadcastTemplateInfo(template); // 广播模板信息
      _broadcastPlayerInfo(validatedPlayers);
      _broadcastSyncState(newSession);
    }
  }

  /// 开始临时计分计分（快速体验模式）
  void startTempGame(BaseTemplate template) {
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
      template: template,
      currentRound: 0,
      isInitialized: true,
      players: validatedPlayers,
      isTempMode: true, // 标记为临时模式
    ));

    updateHighlight();
    // 临时模式下不进行网络广播
    Log.i('临时计分模式：已开始，数据不会保存到本地存储');
  }

  /// 清理临时模板
  Future<void> _cleanupTempTemplate(String templateId) async {
    try {
      await ref.read(templatesProvider.notifier).removeTempTemplate(templateId);
      Log.i('临时模板已清理: $templateId');
    } catch (e) {
      Log.w('清理临时模板失败: $templateId, 错误: $e');
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
    // 统一的客户端限制检查
    if (_checkAndHandleClientRestriction()) {
      return;
    }

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
      GlobalMsgManager.showWarn('分数过大，已限制为最大值');
    } else if (newScore < -2147483648) {
      Log.w('分数过小，已限制为最小值: $playerId');
      newScore = -2147483648; // 限制为 int 的最小值
      GlobalMsgManager.showWarn('分数过小，已限制为最小值');
    }

    final playerScoresMap = {playerId: newScore};
    final playerExtendedDataMap = <String, Map<String, dynamic>?>{};

    updateRoundData(roundIndex, playerScoresMap, playerExtendedDataMap);
  }

  Future<void> updateRoundData(
      int roundIndex,
      Map<String, int?> playerScoresMap,
      Map<String, Map<String, dynamic>?> playerExtendedDataMap) async {
    // 统一的客户端限制检查
    if (_checkAndHandleClientRestriction()) {
      return;
    }

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

    // 检查是否显示计分结束对话框
    final currentScoreState = state.value;
    if (currentScoreState != null && currentScoreState.currentSession != null) {
      final sessionAfterUpdate = currentScoreState.currentSession!;

      bool roundJustCompleted = sessionAfterUpdate.scores.every((ps) =>
          ps.roundScores.length > roundIndex &&
          ps.roundScores[roundIndex] != null);

      // 检查计分结束的条件：
      // 1. 整个回合刚刚完成。
      // 2. 或者，模板被标记为“每次分数变化都检查胜利条件”。
      final template = ref
          .read(templatesProvider)
          .valueOrNull
          ?.firstWhereOrNull((t) => t.tid == sessionAfterUpdate.templateId);

      if (template != null) {
        final shouldCheckVictory =
            roundJustCompleted || (template.checkVictoryOnScoreChange);

        if (shouldCheckVictory) {
          final disableVictoryScoreCheck = template.getOtherSet<bool>(
                  'disableVictoryScoreCheck',
                  defaultValue: false) ??
              false;
          if (!disableVictoryScoreCheck) {
            final gameResult = calculateGameResult(template);
            if (gameResult.havTargetScore) {
              state = AsyncData(currentScoreState.copyWith(
                showGameEndDialog: true,
                currentHighlight: null,
              ));
            }
          }
        }
      }
    }

    final lanState = ref.read(lanProvider);
    if (lanState.isHost) {
      _broadcastSyncRoundData(updatedSession.sid, roundIndex, playerScoresMap,
          playerExtendedDataMap);
      _broadcastSyncState(updatedSession);
    }

    // 根据模式决定是否保存会话到本地数据库
    await _saveSession();

    // 如果是联赛对局，实时更新联赛提供者中的比分
    final session = state.value?.currentSession;
    if (session != null && session.leagueMatchId != null) {
      final scores = Map.fromEntries(
          session.scores.map((s) => MapEntry(s.playerId, s.totalScore)));
      ref
          .read(leagueNotifierProvider.notifier)
          .updateMatchScore(session.leagueMatchId!, scores);
    }
  }

  void resetGameEndDialog() {
    final currentState = state.valueOrNull;
    if (currentState == null || !currentState.showGameEndDialog) return;
    state = AsyncData(currentState.copyWith(
      showGameEndDialog: false,
    ));
  }

  void addNewRound() {
    // 统一的客户端限制检查
    if (_checkAndHandleClientRestriction()) {
      return;
    }

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
        GlobalMsgManager.showWarn('无法开始新回合，请先完成当前轮计分');
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
    // 根据模式决定是否保存会话到本地数据库
    _saveSession();
  }

  Future<void> resetGame(bool saveToHistory) async {
    // 统一的客户端限制检查
    if (_checkAndHandleClientRestriction()) {
      return;
    }

    final currentState = state.valueOrNull;

    // 临时模式下不保存历史记录
    if (saveToHistory && currentState?.isTempMode == true) {
      Log.i('临时计分模式：跳过计分历史保存，数据仅在内存中');
    }
    // 修复：客户端模式下不保存历史记录到本地数据库
    else if (saveToHistory &&
        currentState?.currentSession != null &&
        !_isClientMode() &&
        currentState?.isTempMode != true) {
      final sessionToSave = currentState!.currentSession!;
      final completedSession = sessionToSave.copyWith(
        isCompleted: true,
        endTime: DateTime.now(),
      );
      await _sessionDao.saveGameSession(completedSession);
      Log.d('主机模式：计分历史已保存到本地数据库');

      // 检查是否为联赛对局，并更新联赛提供者
      if (completedSession.leagueMatchId != null) {
        final template = ref
            .read(templatesProvider)
            .valueOrNull
            ?.firstWhereOrNull((t) => t.tid == completedSession.templateId);
        if (template != null) {
          final gameResult = calculateGameResult(template);
          final winnerId = gameResult.winners.isNotEmpty
              ? gameResult.winners.first.playerId
              : null;
          final scores = Map.fromEntries(completedSession.scores
              .map((s) => MapEntry(s.playerId, s.totalScore)));

          await ref.read(leagueNotifierProvider.notifier).updateMatchResult(
                leagueMatchId: completedSession.leagueMatchId!,
                winnerId: winnerId,
                scores: scores,
              );
          Log.i(
              'League match result updated for match ID: ${completedSession.leagueMatchId}');
        }
      }
    } else if (saveToHistory && _isClientMode()) {
      Log.i('客户端模式：跳过计分历史保存，数据仅在内存中');
    }

    // 如果是临时模式，清理临时模板
    if (currentState?.isTempMode == true &&
        currentState?.currentSession != null) {
      final templateId = currentState!.currentSession!.templateId;
      if (templateId.startsWith('temp_')) {
        await _cleanupTempTemplate(templateId);
      }
    }

    final ongoingSessions = currentState?.ongoingSessions ?? [];
    final sessionToRemoveId = currentState?.currentSession?.sid;
    final updatedOngoing =
        ongoingSessions.where((s) => s.sid != sessionToRemoveId).toList();

    state = AsyncData(ScoreState(
      currentSession: null,
      ongoingSessions: updatedOngoing,
      template: null,
      currentRound: 0,
      isInitialized: true,
      currentHighlight: null,
      showGameEndDialog: false,
      players: [],
      isTempMode: false,
    ));

    _broadcastResetGame();
  }

  /// 确认联赛比赛结果
  ///
  /// 记录比赛结果，如果胜负方发生变化，则重新生成后续比赛。
  /// 返回一个可选的字符串消息，用于通知用户后续比赛的更新情况。
  Future<String?> confirmLeagueMatchResult() async {
    if (_checkAndHandleClientRestriction()) return null;

    final currentState = state.valueOrNull;
    if (currentState?.currentSession == null ||
        currentState?.template == null ||
        currentState?.currentSession?.leagueMatchId == null) {
      Log.w('确认联赛结果失败：缺少会话、模板或联赛比赛ID');
      return null;
    }

    final sessionToEnd = currentState!.currentSession!;
    final template = currentState.template!;
    final leagueMatchId = sessionToEnd.leagueMatchId!;

    // 1. 获取原始胜负方
    // 在比赛被确认为“完成”之前，其在联赛中的胜者ID应该是null
    final leagueState = await ref.read(leagueNotifierProvider.future);
    final league = leagueState.leagues
        .firstWhere((l) => l.matches.any((m) => m.mid == leagueMatchId));
    final originalMatch =
        league.matches.firstWhere((m) => m.mid == leagueMatchId);
    final originalWinnerId = originalMatch.winnerId;

    // 2. 将会话标记为已完成并保存
    final completedSession = sessionToEnd.copyWith(
      isCompleted: true,
      endTime: DateTime.now(),
    );
    await _sessionDao.saveGameSession(completedSession);
    Log.d('联赛比赛会话 ${sessionToEnd.sid} 已标记为完成');

    // 3. 计算新的比赛结果并更新联赛数据
    final gameResult = calculateGameResult(template);
    final newWinnerId = gameResult.winners.isNotEmpty
        ? gameResult.winners.first.playerId
        : null;
    final scores = Map.fromEntries(
        completedSession.scores.map((s) => MapEntry(s.playerId, s.totalScore)));

    await ref.read(leagueNotifierProvider.notifier).updateMatchResult(
          leagueMatchId: leagueMatchId,
          winnerId: newWinnerId,
          scores: scores,
        );
    Log.i('联赛比赛结果已更新，比赛ID: $leagueMatchId');

    // 4. 比较胜负方是否变化，并决定是否重新生成比赛
    String? returnMessage;
    // 只有当旧的胜者和新的胜者不同时，才触发重新生成
    if (originalWinnerId != newWinnerId) {
      Log.i(
          '胜负方发生变化 (from ${originalWinnerId} to ${newWinnerId})，正在重新生成后续比赛...');
      try {
        await ref
            .read(leagueNotifierProvider.notifier)
            .regenerateMatchesAfter(leagueMatchId);
        returnMessage = '比赛结果已记录，后续赛程已自动更新。';
        Log.i('后续比赛已成功重新生成。');
      } catch (e, s) {
        ErrorHandler.handle(e, s, prefix: '重新生成后续比赛失败');
        returnMessage = '比赛结果已记录，但更新后续赛程时出错。';
      }
    } else {
      // 即使胜负方没变，也可能有下一轮比赛生成（例如，这是本轮最后一场比赛）
      // updateMatchResult 内部会处理这个逻辑，所以这里不需要额外操作
      // 但我们可以给一个通用提示
      GlobalMsgManager.showSuccess('比赛结果已记录');
    }

    // 5. 不重置状态，由UI层负责
    return returnMessage;
  }

  /// 重置计分状态
  void resetScoreState() {
    state = AsyncData(const ScoreState(
      currentSession: null,
      template: null,
      currentRound: 0,
      isInitialized: true,
      currentHighlight: null,
      showGameEndDialog: false,
      players: [],
      isTempMode: false,
    ));
    _broadcastResetGame();
  }

  /// 更新已完成的联赛比赛结果
  ///
  /// 如果分数修改，将删除并重新生成后续所有比赛。
  /// 返回一个可选的字符串消息，用于通知用户后续比赛的更新情况。
  Future<String?> updateCompletedLeagueMatchResult(
      GameSession originalSession) async {
    if (_checkAndHandleClientRestriction()) return null;

    final currentState = state.valueOrNull;
    if (currentState?.currentSession == null ||
        currentState?.template == null ||
        currentState?.currentSession?.leagueMatchId == null) {
      Log.w('更新已完成的联赛结果失败：缺少会话、模板或联赛比赛ID');
      return null;
    }

    final sessionToUpdate = currentState!.currentSession!;
    final template = currentState.template!;
    final leagueMatchId = sessionToUpdate.leagueMatchId!;

    // 1. 保存对计分会话的修改
    final updatedSession = sessionToUpdate.copyWith(endTime: DateTime.now());
    await _sessionDao.saveGameSession(updatedSession);
    Log.d('已完成的联赛比赛会话 ${sessionToUpdate.sid} 的分数已更新');

    // 2. 重新计算新的比赛结果并更新联赛数据
    final newResult = calculateGameResult(template);
    final newWinnerId =
        newResult.winners.isNotEmpty ? newResult.winners.first.playerId : null;
    final scores = Map.fromEntries(
        updatedSession.scores.map((s) => MapEntry(s.playerId, s.totalScore)));

    await ref.read(leagueNotifierProvider.notifier).updateMatchResult(
          leagueMatchId: leagueMatchId,
          winnerId: newWinnerId,
          scores: scores,
        );
    Log.i('已完成的联赛比赛结果已更新，比赛ID: $leagueMatchId');

    // 3. 若已经生成之后轮次，则删除这些已经生成的轮次match，并重新生成
    String? returnMessage;
    Log.i('修改已完成的比赛，尝试删除并重新生成后续轮次...');
    try {
      await ref
          .read(leagueNotifierProvider.notifier)
          .regenerateMatchesAfter(leagueMatchId);
      returnMessage = '计分已更新，后续赛程已自动刷新。';
      Log.i('后续比赛刷新完成。');
    } catch (e, s) {
      ErrorHandler.handle(e, s, prefix: '重新生成后续比赛失败');
      returnMessage = '计分已更新，但刷新后续赛程时出错，请手动检查。';
    }

    GlobalMsgManager.showSuccess('比赛结果已更新');
    return returnMessage;
  }

  /// 确认普通比赛结果（提前结束）
  Future<void> confirmGameResult() async {
    if (_checkAndHandleClientRestriction()) return;

    final currentState = state.valueOrNull;
    if (currentState?.currentSession == null ||
        currentState?.template == null) {
      Log.w('确认比赛结果失败：缺少会话或模板');
      return;
    }

    final sessionToEnd = currentState!.currentSession!;
    final template = currentState.template!;

    // 1. 将会话标记为已完成
    final completedSession = sessionToEnd.copyWith(
      isCompleted: true,
      endTime: DateTime.now(),
    );
    await _sessionDao.saveGameSession(completedSession);
    Log.d('比赛会话 ${sessionToEnd.sid} 已通过确认胜负标记为完成');

    // 2. 更新联赛数据（如果有关联）
    if (completedSession.leagueMatchId != null) {
      final gameResult = calculateGameResult(template);
      final winnerId = gameResult.winners.isNotEmpty
          ? gameResult.winners.first.playerId
          : null;
      final scores = Map.fromEntries(completedSession.scores
          .map((s) => MapEntry(s.playerId, s.totalScore)));

      await ref.read(leagueNotifierProvider.notifier).updateMatchResult(
            leagueMatchId: completedSession.leagueMatchId!,
            winnerId: winnerId,
            scores: scores,
          );
      Log.i('关联的联赛比赛结果已更新，比赛ID: ${completedSession.leagueMatchId}');
    }

    // 3. 重置计分状态
    final ongoingSessions = currentState.ongoingSessions;
    final updatedOngoing =
        ongoingSessions.where((s) => s.sid != sessionToEnd.sid).toList();

    state = AsyncData(currentState.copyWith(
      currentSession: null,
      ongoingSessions: updatedOngoing,
      template: null,
      currentRound: 0,
      isInitialized: true,
      currentHighlight: null,
      showGameEndDialog: false,
      players: [],
      isTempMode: false,
    ));

    _broadcastResetGame();
  }

  void loadSession(GameSession session) {
    BaseTemplate? sessionTemplate;
    List<PlayerInfo> sessionPlayers = [];
    if (session.templateId.isNotEmpty) {
      final template = ref
          .read(templatesProvider)
          .valueOrNull
          ?.firstWhereOrNull((t) => t.tid == session.templateId);
      if (template != null) {
        sessionTemplate = template;
        sessionPlayers = template.players;
        Log.i(
            'ScoreNotifier loadSession: 从模板 "${template.templateName}" (TID: ${template.tid}) 加载了 ${sessionPlayers.length} 个玩家信息');
      } else {
        Log.w(
            'ScoreNotifier loadSession: 未找到模板 ID: ${session.templateId} 对应的模板，无法加载玩家列表');
      }
    }

    // 从历史记录加载会话时，将其标记为未完成并清除结束时间。
    final updatedSession = session.copyWith(
      isCompleted: false,
      endTime: null,
    );

    state = AsyncData(ScoreState(
      currentSession: updatedSession,
      template: sessionTemplate,
      currentRound: _calculateCurrentRound(updatedSession),
      isInitialized: true,
      currentHighlight: null,
      showGameEndDialog: false,
      players: sessionPlayers,
      isTempMode: false,
    ));
    updateHighlight();
    final lanState = ref.read(lanProvider);
    if (lanState.isHost) {
      if (sessionTemplate != null) broadcastTemplateInfo(sessionTemplate);
      _broadcastPlayerInfo(sessionPlayers);
      _broadcastSyncState(updatedSession);
    }
  }

  void switchToSession(String sessionId) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final sessionToSwitch = currentState.ongoingSessions
        .firstWhereOrNull((s) => s.sid == sessionId);
    if (sessionToSwitch == null) {
      Log.w('切换会话失败: 未在 ongoingSessions 中找到 ID 为 $sessionId 的会话');
      return;
    }

    // 与 loadSession 类似，我们需要找到模板和玩家信息
    BaseTemplate? sessionTemplate;
    List<PlayerInfo> sessionPlayers = [];
    if (sessionToSwitch.templateId.isNotEmpty) {
      final template = ref
          .read(templatesProvider)
          .valueOrNull
          ?.firstWhereOrNull((t) => t.tid == sessionToSwitch.templateId);
      if (template != null) {
        sessionTemplate = template;
        sessionPlayers = template.players;
      } else {
        Log.w(
            'ScoreNotifier switchToSession: 未找到模板 ID: ${sessionToSwitch.templateId} 对应的模板');
      }
    }

    state = AsyncData(currentState.copyWith(
      currentSession: sessionToSwitch,
      template: sessionTemplate,
      currentRound: _calculateCurrentRound(sessionToSwitch),
      players: sessionPlayers,
    ));

    updateHighlight();
    // 可以在这里添加广播逻辑，如果需要的话
  }

  GameResult calculateGameResult(BaseTemplate template) {
    final scores = state.valueOrNull?.currentSession?.scores ?? [];
    if (scores.isEmpty ||
        scores.every((s) => s.roundScores.every((score) => score == null))) {
      return const GameResult(winners: [], losers: [], havTargetScore: false);
    }

    final disableVictoryScoreCheck = template.getOtherSet<bool>(
            'disableVictoryScoreCheck',
            defaultValue: false) ??
        false;

    // 如果不检查胜利分数，直接返回空结果（不判断胜负）
    if (disableVictoryScoreCheck) {
      return const GameResult(winners: [], losers: [], havTargetScore: false);
    }

    final targetScore = template.targetScore;
    final reverseWinRule = template.reverseWinRule;

    final failScores =
        scores.where((s) => s.totalScore >= targetScore).toList();
    final hasFailures = failScores.isNotEmpty;

    final List<PlayerScore> winners;
    final List<PlayerScore> losers;

    if (hasFailures) {
      if (reverseWinRule) {
        // 反转规则：先达到目标分数的获胜
        failScores.sort((a, b) => a.totalScore.compareTo(b.totalScore));
        final minFailScore = failScores.first.totalScore;
        winners =
            failScores.where((s) => s.totalScore == minFailScore).toList();
        losers = scores.where((s) => s.totalScore < targetScore).toList();
        losers.sort((a, b) => b.totalScore.compareTo(a.totalScore));
      } else {
        // 默认规则：先达到目标分数的失败
        final potentialWins =
            scores.where((s) => s.totalScore < targetScore).toList();
        if (potentialWins.isEmpty) {
          winners = [];
          losers =
              scores.sorted((a, b) => b.totalScore.compareTo(a.totalScore));
        } else {
          potentialWins.sort((a, b) => a.totalScore.compareTo(b.totalScore));
          final minWinScore = potentialWins.first.totalScore;
          winners =
              potentialWins.where((s) => s.totalScore == minWinScore).toList();
          losers = scores.where((s) => s.totalScore >= targetScore).toList();
          losers.sort((a, b) => b.totalScore.compareTo(a.totalScore));
        }
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
        if (reverseWinRule) {
          // 反转规则：分数高者暂时领先
          winners =
              sortedScores.where((s) => s.totalScore == maxScore).toList();
          losers = sortedScores.where((s) => s.totalScore == minScore).toList();
        } else {
          // 默认规则：分数低者暂时领先
          winners =
              sortedScores.where((s) => s.totalScore == minScore).toList();
          losers = sortedScores.where((s) => s.totalScore == maxScore).toList();
        }
      }
    }

    return GameResult(
      winners: winners,
      losers: losers,
      havTargetScore: hasFailures,
    );
  }

  void _broadcastSyncState(GameSession session) {
    final lanNotifier = ref.read(lanProvider.notifier);
    final lanState = ref.read(lanProvider);
    if (!lanState.isHost) {
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
    if (!lanState.isHost) return;

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
    if (!lanState.isHost) return;

    Log.i('ScoreNotifier 广播新回合开始: ${payload.newRoundIndex}');
    final message = SyncMessage(type: "new_round", data: payload.toJson());
    final jsonString = jsonEncode(message.toJson());
    lanNotifier.sendJsonMessage(jsonString);
  }

  void _broadcastResetGame() {
    final lanNotifier = ref.read(lanProvider.notifier);
    final lanState = ref.read(lanProvider);
    if (!lanState.isHost) return;

    Log.i('ScoreNotifier 广播计分重置');
    final payload = ResetGamePayload();
    final message = SyncMessage(type: "reset_game", data: payload.toJson());
    final jsonString = jsonEncode(message.toJson());
    lanNotifier.sendJsonMessage(jsonString);
  }

  void _broadcastPlayerInfo(List<PlayerInfo> players) {
    final lanNotifier = ref.read(lanProvider.notifier);
    final lanState = ref.read(lanProvider);
    if (!lanState.isHost) return;

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
      // 修复：直接更新状态，避免触发重建
      final newState = currentState.copyWith(players: players);
      state = AsyncData(newState);
    } else {
      Log.w('ScoreNotifier applyPlayerInfo: 当前状态为空，将创建一个仅包含玩家信息的新状态');
      state = AsyncData(
          ScoreState(players: players, isInitialized: true, isTempMode: false));
    }
  }

  /// 应用接收到的全量同步状态
  void applySyncState(GameSession session) {
    Log.i('ScoreNotifier 应用全量同步状态 (会话ID: ${session.sid})');
    final currentState = state.valueOrNull;

    // 尝试从provider中找到模板
    final template = ref
        .read(templatesProvider)
        .valueOrNull
        ?.firstWhereOrNull((t) => t.tid == session.templateId);

    final playersToUse =
        template?.players ?? currentState?.players ?? []; // 优先使用新模板的玩家，否则保留现有玩家

    Log.i(
        'applySyncState: 当前玩家数量: ${playersToUse.length}, 会话中分数数量: ${session.scores.length}');

    final newState = currentState?.copyWith(
          currentSession: session,
          template: template ?? currentState.template,
          // 如果没找到新模板，保留旧的
          currentRound: _calculateCurrentRound(session),
          isInitialized: true,
          currentHighlight: null,
          showGameEndDialog: false,
          players: playersToUse,
        ) ??
        ScoreState(
          currentSession: session,
          template: template,
          currentRound: _calculateCurrentRound(session),
          isInitialized: true,
          players: playersToUse,
          showGameEndDialog: false,
          currentHighlight: null,
          isTempMode: false,
        );

    state = AsyncData(newState);

    Log.i('applySyncState 完成: 最终玩家数量: ${newState.players.length}');
    updateHighlight();

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

  /// 应用接收到的计分重置通知
  void applyResetGame() {
    Log.i('ScoreNotifier 应用计分重置');
    state = AsyncData(const ScoreState(
      currentSession: null,
      template: null,
      currentRound: 0,
      isInitialized: true,
      currentHighlight: null,
      showGameEndDialog: false,
      players: [],
      // 重置时清空玩家列表
      isTempMode: false,
    ));
  }

  /// 应用接收到的计分结束通知
  void applyGameEnd(/* GameEndPayload? payload */) {
    Log.i('ScoreNotifier 应用计分结束');
    final currentState = state.valueOrNull;
    if (currentState?.currentSession == null) {
      Log.w('应用计分结束失败: 无当前会话');
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
    if (!lanState.isHost) return;
    final map = template.toJson();
    map['players'] = template.players.map((e) => e.toJson()).toList();
    final message = SyncMessage(type: "template_info", data: map);
    final jsonString = jsonEncode(message.toJson());
    lanNotifier.sendJsonMessage(jsonString);
    Log.i('ScoreNotifier 广播模板信息');
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
        round: roundIndex + 1,
        // 修复轮次显示：从1开始计数而不是0开始
        onConfirm: (newValue) {
          ref
              .read(scoreProvider.notifier)
              .updateScore(player.pid, roundIndex, newValue);
        },
      ),
    );
  }

  /// 显示总分编辑弹窗（适用于Counter等累计分数的计分）
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
