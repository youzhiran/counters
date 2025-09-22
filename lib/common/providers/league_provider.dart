import 'package:counters/common/db/db_helper.dart';
import 'package:counters/common/model/league.dart';
import 'package:counters/common/model/league_enums.dart';
import 'package:counters/common/model/match.dart';
import 'package:counters/common/utils/double_elimination_helper.dart';
import 'package:counters/common/utils/error_handler.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/features/league/league_dao.dart';
import 'package:counters/features/score/game_session_dao.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'league_provider.g.dart';

// 用于存储每个联赛详情页的当前标签页索引
final leagueDetailPageTabIndexProvider =
    StateProvider.family<int, String>((ref, leagueId) => 0);

// 1. 状态类
class LeagueState {
  final List<League> leagues;

  const LeagueState({
    this.leagues = const [],
  });

  LeagueState copyWith({
    List<League>? leagues,
  }) {
    return LeagueState(
      leagues: leagues ?? this.leagues,
    );
  }
}

// 2. Notifier类
@Riverpod(keepAlive: true)
class LeagueNotifier extends _$LeagueNotifier {
  late LeagueDao _leagueDao;

  @override
  Future<LeagueState> build() async {
    final dbHelper = DatabaseHelper.instance;
    _leagueDao = LeagueDao(dbHelper: dbHelper);
    final leagues = await _leagueDao.getAllLeagues();
    return LeagueState(leagues: leagues);
  }

  Future<void> _reloadLeagues() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final leagues = await _leagueDao.getAllLeagues();
      return LeagueState(leagues: leagues);
    });
  }

  Future<void> addLeague({
    required String name,
    required LeagueType type,
    required List<String> playerIds,
    required String defaultTemplateId,
    int roundRobinRounds = 1,
    int pointsForWin = 3,
    int pointsForDraw = 1,
    int pointsForLoss = 0,
  }) async {
    try {
      final sanitizedRounds =
          type == LeagueType.roundRobin ? roundRobinRounds : 1;

      List<Match> matches =
          _generateFirstRoundMatches(type, playerIds, sanitizedRounds);
      final newLeague = League(
        name: name,
        type: type,
        playerIds: playerIds,
        matches: matches,
        defaultTemplateId: defaultTemplateId,
        roundRobinRounds: sanitizedRounds,
        pointsForWin: pointsForWin,
        pointsForDraw: pointsForDraw,
        pointsForLoss: pointsForLoss,
      );

      final finalMatches = newLeague.matches
          .map((m) => m.copyWith(leagueId: newLeague.lid))
          .toList();
      final finalLeague = newLeague.copyWith(matches: finalMatches);

      await _leagueDao.saveLeague(finalLeague);
      await _reloadLeagues();
    } catch (e) {
      // 对于验证性错误（如玩家数量不匹配），不应将整个provider置于错误状态。
      // 而是将异常重新抛出，由调用方（UI层）捕获并以用户友好的方式（如SnackBar）显示。
      rethrow;
    }
  }

  Future<void> addRoundRobinRound(String leagueId) async {
    if (!state.hasValue) return;
    try {
      final league = state.value!.leagues.firstWhere((l) => l.lid == leagueId);
      if (league.type != LeagueType.roundRobin) {
        throw Exception('只有循环赛可以增加轮次');
      }

      // 检查当前最后一轮是否已全部完成
      final currentRoundNumber = league.roundRobinRounds;
      final currentRoundMatches =
          league.matches.where((m) => m.round == currentRoundNumber);

      if (currentRoundMatches.isNotEmpty &&
          currentRoundMatches.any((m) => m.status != MatchStatus.completed)) {
        throw Exception('当前轮次尚有未完成的比赛，无法添加新轮次。');
      }

      final newRoundNumber = league.roundRobinRounds + 1;
      final playerIds = league.playerIds;
      final newMatches = <Match>[];

      // 生成新一轮的对阵
      for (int i = 0; i < playerIds.length; i++) {
        for (int j = i + 1; j < playerIds.length; j++) {
          // 为了让每一轮的先后手顺序可能不同，可以根据轮次的奇偶性来交换
          final player1 = newRoundNumber.isEven ? playerIds[j] : playerIds[i];
          final player2 = newRoundNumber.isEven ? playerIds[i] : playerIds[j];
          newMatches.add(Match(
            leagueId: league.lid,
            round: newRoundNumber,
            player1Id: player1,
            player2Id: player2,
          ));
        }
      }

      final updatedLeague = league.copyWith(
        roundRobinRounds: newRoundNumber,
        matches: [...league.matches, ...newMatches],
      );

      await _leagueDao.saveLeague(updatedLeague);
      await _reloadLeagues();
    } catch (e) {
      // 重新抛出异常，由UI层处理
      rethrow;
    }
  }

  Future<void> deleteLeague(String lid) async {
    try {
      // 在删除联赛前，先获取其所有比赛ID
      final leagueToDelete = await _leagueDao.getLeague(lid);
      if (leagueToDelete != null) {
        final matchIds = leagueToDelete.matches.map((m) => m.mid).toList();

        // 如果有关联的比赛，则删除相关的游戏会话
        if (matchIds.isNotEmpty) {
          final sessionDao = GameSessionDao(dbHelper: DatabaseHelper.instance);
          await sessionDao.deleteSessionsByMatchIds(matchIds);
        }
      }

      // 然后再删除联赛和比赛本身
      await _leagueDao.deleteLeague(lid);
      await _reloadLeagues();
    } catch (e, s) {
      ErrorHandler.handle(e, s);
      state = AsyncError(e, s);
    }
  }

  /// 重置并重新生成指定轮次及其后续所有轮次
  Future<void> resetRound(String leagueId, int round) async {
    if (!state.hasValue) return;
    try {
      final league = state.value!.leagues.firstWhere((l) => l.lid == leagueId);
      Log.d(
          '[Reset] Starting reset for league ${league.lid} at round $round. Initial match count: ${league.matches.length}');

      // --- 核心修复 ---
      // 1. 筛选需要保留的比赛
      final preservedMatches = league.matches.where((m) {
        // 对于双败淘汰赛
        if (league.type == LeagueType.doubleElimination) {
          // 总是保留所有轮次在重置轮次之前的胜者组比赛
          if (m.bracketType == BracketType.winner && m.round < round) {
            return true;
          }
          // 败者组的保留逻辑：同样只保留轮次小于当前重置轮次的比赛。
          // 这是因为胜者组第 N 轮的败者会进入败者组的某个后续轮次（通常是第 N 轮或 N+1 轮）。
          // 重置胜者组第 N 轮意味着其败者未知，因此依赖于此的败者组轮次也必须被删除。
          // 为简化和确保正确性，我们一并删除所有轮次 >= N 的败者组比赛。
          if (m.bracketType == BracketType.loser && m.round < round) {
            return true;
          }
          // 其他所有比赛（当前及后续胜者组、相关及后续败者组、总决赛）都将被移除
          return false;
        }

        // 对于非淘汰赛制，保留所有轮次小于当前重置轮次的比赛
        if (m.round < round) {
          return true;
        }

        return false;
      }).toList();
      Log.d(
          '[Reset] Found ${preservedMatches.length} matches to preserve from previous rounds.');

      var leagueWithPreservedMatches =
          league.copyWith(matches: preservedMatches);

      // 2. 重新生成当前轮次的比赛
      List<Match> newRoundMatches;
      if (round == 1) {
        Log.d('[Reset] Generating round 1 from initial player list.');
        // 如果重置的是第一轮，则基于初始玩家列表生成
        newRoundMatches = _generateKnockoutRound(
          league.playerIds,
          1,
          league.lid,
          bracketType: league.type == LeagueType.doubleElimination
              ? BracketType.winner
              : null,
        );
      } else {
        Log.d(
            '[Reset] Generating round $round based on results of round ${round - 1}.');
        // 否则，基于前一轮的结果生成
        final previousRoundMatches =
            preservedMatches.where((m) => m.round == round - 1);
        if (previousRoundMatches
            .any((m) => m.status != MatchStatus.completed)) {
          Log.w('[Reset] Aborting reset: Previous round is not complete.');
          throw Exception('无法重置，因为前一轮比赛尚未全部完成。');
        }
        // 核心修复：为双败淘汰赛指定要生成的轮次类型
        final bracketTypeForNextRound =
            league.type == LeagueType.doubleElimination
                ? BracketType.winner
                : null;
        newRoundMatches = _generateNextRoundMatches(
          leagueWithPreservedMatches,
          round - 1,
          bracketType: bracketTypeForNextRound,
        );
      }
      Log.d(
          '[Reset] Generated ${newRoundMatches.length} new matches for round $round.');

      // 3. 组合并保存
      final finalMatches = [...preservedMatches, ...newRoundMatches];
      final updatedLeague = league.copyWith(matches: finalMatches);
      Log.d(
          '[Reset] Saving updated league with ${finalMatches.length} total matches.');

      await _leagueDao.saveLeague(updatedLeague);
      await _reloadLeagues();
      Log.i('[Reset] League reset and reload completed successfully.');
    } catch (e, s) {
      ErrorHandler.handle(e, s, prefix: '重置轮次失败');
      // 将错误信息放入状态，以便UI层可以显示
      state = AsyncError(e, s);
      // 重新抛出，以便UI层可以捕获并显示SnackBar等
      rethrow;
    }
  }

  Future<void> updateMatch(Match updatedMatch) async {
    try {
      await _leagueDao.updateMatch(updatedMatch);
      await _reloadLeagues();
    } catch (e, s) {
      ErrorHandler.handle(e, s);
      state = AsyncError(e, s);
    }
  }

  Future<void> updateMatchResult({
    required String leagueMatchId,
    required String? winnerId,
    required Map<String, int> scores,
  }) async {
    if (!state.hasValue) return;
    try {
      final league = state.value!.leagues
          .firstWhere((l) => l.matches.any((m) => m.mid == leagueMatchId));
      final matchIndex =
          league.matches.indexWhere((m) => m.mid == leagueMatchId);
      final oldMatch = league.matches[matchIndex];

      // 1. 更新当前比赛结果
      final updatedMatch = oldMatch.copyWith(
        status: MatchStatus.completed,
        winnerId: winnerId,
        player1Score: scores[oldMatch.player1Id],
        player2Score: scores[oldMatch.player2Id],
        endTime: DateTime.now(),
      );

      var updatedMatches = List<Match>.from(league.matches);
      updatedMatches[matchIndex] = updatedMatch;
      var updatedLeague = league.copyWith(matches: updatedMatches);

      // 2. 如果是淘汰赛，并且比赛状态从未完成变为完成，则检查是否需要生成下一轮
      final bool justCompleted = oldMatch.status != MatchStatus.completed &&
          updatedMatch.status == MatchStatus.completed;
      final bool resultChanged = oldMatch.status == MatchStatus.completed &&
          updatedMatch.status == MatchStatus.completed &&
          oldMatch.winnerId != updatedMatch.winnerId;

      if (league.type == LeagueType.knockout && justCompleted) {
        final currentRound = oldMatch.round;
        final currentRoundMatches = updatedMatches
            .where((m) => m.round == currentRound)
            .toList(growable: false);

        // 检查当前轮次是否全部完成
        final isRoundCompleted =
            currentRoundMatches.every((m) => m.status == MatchStatus.completed);

        if (isRoundCompleted) {
          final nextRoundMatches =
              _generateNextRoundMatches(updatedLeague, currentRound);
          if (nextRoundMatches.isNotEmpty) {
            updatedMatches.addAll(nextRoundMatches);
            updatedLeague = league.copyWith(matches: updatedMatches);
          }
        }
      } else if (league.type == LeagueType.doubleElimination) {
        if (justCompleted) {
          // 对于双败淘汰赛，委托给专门的处理器。
          // 这个处理器会负责保存和刷新状态，所以这里可以直接返回。
          await _handleDoubleEliminationProgress(updatedLeague, updatedMatch);
          return;
        }

        if (resultChanged) {
          await _rebuildDoubleEliminationAfterResultChange(
            updatedLeague: updatedLeague,
            updatedMatch: updatedMatch,
          );
          return;
        }
      }

      // 3. 保存并刷新状态 (对于非双败或非完赛的更新)
      await _leagueDao.saveLeague(updatedLeague);
      // 关键修复：添加一个微任务延迟，以避免在UI重建期间发生布局错误。
      await Future.delayed(Duration.zero);
      await _reloadLeagues();
    } catch (e, s) {
      ErrorHandler.handle(e, s, prefix: '更新比赛结果失败');
      state = AsyncError(e, s);
    }
  }

  Future<void> regenerateMatchesAfter(String leagueMatchId) async {
    if (!state.hasValue) return;

    try {
      final league = state.value!.leagues
          .firstWhere((l) => l.matches.any((m) => m.mid == leagueMatchId));

      // 循环赛与双败淘汰赛不需要重新生成后续赛程，否则会误删比赛
      if (league.type != LeagueType.knockout) {
        Log.i('联赛 ${league.lid} 类型为 ${league.type}，跳过赛程重建。');
        return;
      }

      final anchorMatch =
          league.matches.firstWhere((m) => m.mid == leagueMatchId);
      final anchorRound = anchorMatch.round;

      // 1. 删除所有后续轮次的比赛
      final preservedMatches =
          league.matches.where((m) => m.round <= anchorRound).toList();
      var updatedLeague = league.copyWith(matches: preservedMatches);

      // 2. 检查锚点轮次是否已全部完成，如果完成则生成下一轮
      final anchorRoundMatches =
          preservedMatches.where((m) => m.round == anchorRound);
      final isAnchorRoundCompleted =
          anchorRoundMatches.every((m) => m.status == MatchStatus.completed);

      if (isAnchorRoundCompleted) {
        final nextRoundMatches =
            _generateNextRoundMatches(updatedLeague, anchorRound);
        if (nextRoundMatches.isNotEmpty) {
          final finalMatches = [...preservedMatches, ...nextRoundMatches];
          updatedLeague = updatedLeague.copyWith(matches: finalMatches);
        }
      }

      // 3. 保存并刷新状态
      await _leagueDao.saveLeague(updatedLeague);
      // 关键修复：添加一个微任务延迟，以避免在UI重建期间发生布局错误。
      // 这可以防止因Tooltip等组件在旧UI元素被销毁时尝试访问其布局信息而导致的竞态条件。
      await Future.delayed(Duration.zero);
      await _reloadLeagues();
    } catch (e, s) {
      ErrorHandler.handle(e, s, prefix: '重新生成后续比赛失败');
      rethrow;
    }
  }

  /// 实时更新内存中的比赛分数和状态，不写入数据库
  void updateMatchScore(String leagueMatchId, Map<String, int> scores) {
    if (!state.hasValue) return;

    final leagues = state.value!.leagues;
    final leagueIndex =
        leagues.indexWhere((l) => l.matches.any((m) => m.mid == leagueMatchId));
    if (leagueIndex == -1) return;

    final league = leagues[leagueIndex];
    final matchIndex = league.matches.indexWhere((m) => m.mid == leagueMatchId);
    if (matchIndex == -1) return;

    final oldMatch = league.matches[matchIndex];

    // 只有在比赛未完成时才更新
    if (oldMatch.status == MatchStatus.completed) return;

    final updatedMatch = oldMatch.copyWith(
      status: MatchStatus.inProgress, // 将状态更新为进行中
      player1Score: scores[oldMatch.player1Id],
      player2Score: scores[oldMatch.player2Id],
    );

    final updatedMatches = List<Match>.from(league.matches);
    updatedMatches[matchIndex] = updatedMatch;

    final updatedLeague = league.copyWith(matches: updatedMatches);

    final updatedLeagues = List<League>.from(leagues);
    updatedLeagues[leagueIndex] = updatedLeague;

    // 直接更新状态，触发UI刷新
    state = AsyncData(state.value!.copyWith(leagues: updatedLeagues));
  }

  List<Match> _generateFirstRoundMatches(LeagueType type,
      List<String> playerIds, int roundRobinRounds) {
    if (type == LeagueType.roundRobin) {
      if (playerIds.length < 2) {
        return [];
      }

      final matches = <Match>[];
      for (var cycle = 0; cycle < roundRobinRounds; cycle++) {
        final roundNumber = cycle + 1;
        final reverseOrder = cycle.isOdd;
        for (int i = 0; i < playerIds.length; i++) {
          for (int j = i + 1; j < playerIds.length; j++) {
            final player1 = reverseOrder ? playerIds[j] : playerIds[i];
            final player2 = reverseOrder ? playerIds[i] : playerIds[j];
            matches.add(Match(
              leagueId: '',
              round: roundNumber,
              player1Id: player1,
              player2Id: player2,
            ));
          }
        }
      }

      return matches;
    } else if (type == LeagueType.knockout) {
      return _generateKnockoutRound(playerIds, 1, '');
    } else if (type == LeagueType.doubleElimination) {
      return _generateKnockoutRound(playerIds, 1, '',
          bracketType: BracketType.winner);
    }
    return [];
  }

  List<Match> _generateNextRoundMatches(League league, int completedRound,
      {BracketType? bracketType}) {
    // 获取已完成的上一轮所有比赛
    final completedRoundMatches = league.matches
        .where((m) =>
            m.round == completedRound &&
            m.winnerId != null &&
            m.bracketType == bracketType)
        .toList();

    // 关键修复：对比赛进行排序，确保对阵顺序的稳定性。
    // 我们根据比赛ID（mid）进行排序，它提供了一个唯一的、稳定的排序依据。
    completedRoundMatches.sort((a, b) => a.mid.compareTo(b.mid));

    // 按排序后的顺序提取胜者
    final winners = completedRoundMatches.map((m) => m.winnerId!).toList();

    if (winners.length < 2) {
      return []; // 冠军已产生
    }

    // 将排序好的胜者列表传给下一轮生成函数
    return _generateKnockoutRound(winners, completedRound + 1, league.lid,
        bracketType: bracketType);
  }

  List<Match> _generateKnockoutRound(List<String> playerIds, int round,
      String leagueId,
      {BracketType? bracketType}) {
    if (playerIds.isEmpty) {
      return [];
    }
    var players = List<String>.from(playerIds);

    // 关键修复：显式处理单人情况，直接轮空晋级
    if (players.length == 1) {
      return [
        Match(
          leagueId: leagueId,
          round: round,
          player1Id: players.first,
          player2Id: 'bye',
          status: MatchStatus.completed,
          winnerId: players.first,
          startTime: DateTime.now(),
          endTime: DateTime.now(),
          bracketType: bracketType,
        )
      ];
    }

    // 只在第一轮，且是淘汰赛或胜者组时，才随机排序
    if (round == 1 &&
        (bracketType == null || bracketType == BracketType.winner)) {
      players.shuffle();
    }

    // 计算需要补充多少轮空位，才能达到下一个2的次方数
    int nextPowerOfTwo = 1;
    while (nextPowerOfTwo < players.length) {
      nextPowerOfTwo *= 2;
    }
    int byesCount = nextPowerOfTwo - players.length;

    // 排名靠前的玩家获得轮空资格
    final byePlayers = players.sublist(0, byesCount);
    final playingPlayers = players.sublist(byesCount);

    List<Match> matches = [];

    // 1. 为轮空玩家创建自动晋级的“比赛”
    for (final player in byePlayers) {
      matches.add(Match(
        leagueId: leagueId,
        round: round,
        player1Id: player,
        player2Id: 'bye',
        // 特殊ID表示轮空
        status: MatchStatus.completed,
        winnerId: player,
        // 轮空者直接成为胜者
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        bracketType: bracketType,
      ));
    }

    // 2. 为需要比赛的玩家两两配对
    for (int i = 0; i < playingPlayers.length; i += 2) {
      matches.add(Match(
        leagueId: leagueId,
        round: round,
        player1Id: playingPlayers[i],
        player2Id: playingPlayers[i + 1],
        bracketType: bracketType,
      ));
    }

    return matches;
  }

  /// 处理双败淘汰赛的赛程推进
  Future<void> _handleDoubleEliminationProgress(
      League league, Match justCompletedMatch) async {
    final currentRound = justCompletedMatch.round;
    final bracketType = justCompletedMatch.bracketType;
    Log.d(
        '[赛程推进] 正在处理已完成的比赛 ${justCompletedMatch.mid} (轮次: $currentRound, 分组: $bracketType)');

    // 检查刚刚完成的比赛所在的轮次是否也已经全部完成
    final isRoundCompleted = league.matches
        .where((m) => m.round == currentRound && m.bracketType == bracketType)
        .every((m) => m.status == MatchStatus.completed);

    if (!isRoundCompleted) {
      Log.d('[赛程推进] $bracketType 第 $currentRound 轮尚未完全结束。保存当前比赛结果并等待。');
      await _leagueDao.saveLeague(league);
      await _reloadLeagues();
      return;
    }

    Log.i('[赛程推进] $bracketType 第 $currentRound 轮现已全部完成。尝试推进锦标赛...');

    // --- 核心重构 ---
    // 调用新的、确定性的辅助工具来生成下一轮比赛
    final newMatches = DoubleEliminationHelper.advanceTournament(league);

    // 将新生成的比赛添加到当前联赛状态中，以便进行总决赛检查
    final leagueWithNewMatches =
        league.copyWith(matches: [...league.matches, ...newMatches]);

    // 检查总决赛是否可以生成
    final finalMatches = _generateFinalsIfNeeded(leagueWithNewMatches);
    if (finalMatches.isNotEmpty) {
      Log.i('[赛程推进] 已满足总决赛生成条件。添加 ${finalMatches.length} 场总决赛。');
    }

    final finalLeagueState = league
        .copyWith(matches: [...league.matches, ...newMatches, ...finalMatches]);

    Log.d('[赛程推进] 保存所有更新。当前总比赛数: ${finalLeagueState.matches.length}。');
    await _leagueDao.saveLeague(finalLeagueState);
    await _reloadLeagues();
  }

  Future<void> _rebuildDoubleEliminationAfterResultChange({
    required League updatedLeague,
    required Match updatedMatch,
  }) async {
    Log.w('[赛程推进] 检测到双败淘汰赛比赛结果发生变动，开始重建后续赛程。');

    final trimmedMatches = _trimDoubleEliminationMatches(
      matches: updatedLeague.matches,
      pivotMatch: updatedMatch,
    );

    var rebuildingLeague =
        updatedLeague.copyWith(matches: List<Match>.from(trimmedMatches));

    while (true) {
      final generatedMatches =
          DoubleEliminationHelper.advanceTournament(rebuildingLeague);
      if (generatedMatches.isEmpty) {
        break;
      }
      rebuildingLeague = rebuildingLeague.copyWith(
        matches: [...rebuildingLeague.matches, ...generatedMatches],
      );
    }

    final finals = _generateFinalsIfNeeded(rebuildingLeague);
    if (finals.isNotEmpty) {
      rebuildingLeague = rebuildingLeague.copyWith(
        matches: [...rebuildingLeague.matches, ...finals],
      );
    }

    await _leagueDao.saveLeague(rebuildingLeague);
    await Future.delayed(Duration.zero);
    await _reloadLeagues();
  }

  List<Match> _trimDoubleEliminationMatches({
    required List<Match> matches,
    required Match pivotMatch,
  }) {
    final pivotRound = pivotMatch.round;
    final pivotBracket = pivotMatch.bracketType;
    final loserCutoff = pivotBracket == BracketType.winner
        ? DoubleEliminationHelper.firstLoserRoundAffectedByWinnerRound(
            pivotRound)
        : null;

    final filtered = <Match>[];
    for (final match in matches) {
      if (match.mid == pivotMatch.mid) {
        filtered.add(match);
        continue;
      }

      if (match.bracketType == BracketType.finals) {
        // 总决赛会在重建结束后重新生成。
        continue;
      }

      if (pivotBracket == BracketType.winner) {
        if (match.bracketType == BracketType.winner &&
            match.round > pivotRound) {
          continue;
        }
        if (match.bracketType == BracketType.loser &&
            loserCutoff != null &&
            match.round >= loserCutoff) {
          continue;
        }
      } else if (pivotBracket == BracketType.loser) {
        if (match.bracketType == BracketType.loser &&
            match.round > pivotRound) {
          continue;
        }
      } else if (pivotBracket == BracketType.finals) {
        if (match.bracketType == BracketType.finals &&
            match.round >= pivotRound) {
          continue;
        }
      }

      filtered.add(match);
    }

    return filtered;
  }

  /// 检查并生成总决赛。这是决定性的检查方法。
  List<Match> _generateFinalsIfNeeded(League league) {
    Log.d('[总决赛检查] 开始运行...');
    // 1. 如果总决赛已存在，则无需再生成。
    if (league.matches.any((m) => m.bracketType == BracketType.finals)) {
      Log.d('[总决赛检查] 检查失败: 总决赛已存在。');
      return [];
    }

    // 2. 检查胜者组是否已决出冠军
    final totalPlayers = league.playerIds.length;
    final winnerMatches =
        league.matches.where((m) => m.bracketType == BracketType.winner);
    Log.d('[总决赛检查] 胜者组共有 ${winnerMatches.length} 场比赛。');
    // 如果胜者组没有任何比赛，或者有任何一场未完成，则冠军未决出。
    if (winnerMatches.isEmpty) {
      Log.d('[总决赛检查] 检查失败: 胜者组为空。');
      return [];
    }
    if (winnerMatches.any((m) => m.status != MatchStatus.completed)) {
      Log.d('[总决赛检查] 检查失败: 并非所有胜者组比赛都已完成。');
      return [];
    }

    final expectedWinnerRounds =
        DoubleEliminationHelper.totalWinnerRoundsForPlayers(totalPlayers);
    final finalWinnerRoundMatches =
        winnerMatches.where((m) => m.round == expectedWinnerRounds).toList();
    if (finalWinnerRoundMatches.isEmpty) {
      Log.d('[总决赛检查] 检查失败: 胜者组尚未进入最终轮 ($expectedWinnerRounds)。');
      return [];
    }
    if (finalWinnerRoundMatches.any((m) => m.status != MatchStatus.completed)) {
      Log.d('[总决赛检查] 检查失败: 胜者组最终轮尚未完成。');
      return [];
    }
    String? winnerChampion;
    for (final match in finalWinnerRoundMatches) {
      if (match.winnerId != null) {
        winnerChampion = match.winnerId;
        break;
      }
    }
    if (winnerChampion == null) {
      Log.w('[总决赛检查] 检查失败: 胜者组冠军ID为空。');
      return [];
    }
    Log.i('[总决赛检查] 胜者组冠军已确定: $winnerChampion');

    // 3. 检查败者组是否已决出冠军（逻辑同上）
    final loserMatches =
        league.matches.where((m) => m.bracketType == BracketType.loser);
    Log.d('[总决赛检查] 败者组共有 ${loserMatches.length} 场比赛。');
    if (loserMatches.isEmpty) {
      Log.d('[总决赛检查] 检查失败: 败者组为空。');
      return [];
    }
    if (loserMatches.any((m) => m.status != MatchStatus.completed)) {
      Log.d('[总决赛检查] 检查失败: 并非所有败者组比赛都已完成。');
      return [];
    }
    final expectedLoserRounds =
        DoubleEliminationHelper.totalLoserRoundsForPlayers(totalPlayers);
    if (expectedLoserRounds == 0) {
      Log.d('[总决赛检查] 检查失败: 赛制无需败者组。');
      return [];
    }
    final finalLoserRoundMatches =
        loserMatches.where((m) => m.round == expectedLoserRounds).toList();
    if (finalLoserRoundMatches.isEmpty) {
      Log.d('[总决赛检查] 检查失败: 败者组尚未进入最终阶段 ($expectedLoserRounds)。');
      return [];
    }
    if (finalLoserRoundMatches.any((m) => m.status != MatchStatus.completed)) {
      Log.d('[总决赛检查] 检查失败: 败者组最终阶段尚未完成。');
      return [];
    }
    String? loserChampion;
    for (final match in finalLoserRoundMatches) {
      if (match.winnerId != null) {
        loserChampion = match.winnerId;
        break;
      }
    }
    if (loserChampion == null) {
      Log.w('[总决赛检查] 检查失败: 败者组冠军ID为空。');
      return [];
    }
    Log.i('[总决赛检查] 败者组冠军已确定: $loserChampion');

    // 4. 两个分支的冠军都已决出，生成总决赛！
    final grandFinalRound = expectedWinnerRounds + 1;
    Log.i('[总决赛检查] 所有条件均满足！正在生成总决赛: $winnerChampion vs $loserChampion。');
    return [
      Match(
        leagueId: league.lid,
        round: grandFinalRound,
        player1Id: winnerChampion,
        player2Id: loserChampion,
        bracketType: BracketType.finals,
      )
    ];
  }
}
