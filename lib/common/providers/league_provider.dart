import 'package:counters/common/dao/game_session_dao.dart';
import 'package:counters/common/dao/league_dao.dart';
import 'package:counters/common/db/db_helper.dart';
import 'package:counters/common/model/league.dart';
import 'package:counters/common/model/league_enums.dart';
import 'package:counters/common/model/match.dart';
import 'package:counters/common/utils/error_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'league_provider.g.dart';

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
  }) async {
    try {
      List<Match> matches = _generateFirstRoundMatches(type, playerIds);
      final newLeague = League(
        name: name,
        type: type,
        playerIds: playerIds,
        matches: matches,
        defaultTemplateId: defaultTemplateId,
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

      // 1. 保留该轮次之前的所有比赛
      final preservedMatches =
          league.matches.where((m) => m.round < round).toList();
      var leagueWithPreservedMatches =
          league.copyWith(matches: preservedMatches);

      // 2. 重新生成当前轮次的比赛
      List<Match> newRoundMatches;
      if (round == 1) {
        // 如果重置的是第一轮，则基于初始玩家列表生成
        newRoundMatches =
            _generateKnockoutRound(league.playerIds, 1, league.lid);
      } else {
        // 否则，基于前一轮的结果生成
        // 确保前一轮已完成
        final previousRoundMatches =
            preservedMatches.where((m) => m.round == round - 1);
        if (previousRoundMatches
            .any((m) => m.status != MatchStatus.completed)) {
          throw Exception('无法重置，因为前一轮比赛尚未全部完成。');
        }
        newRoundMatches =
            _generateNextRoundMatches(leagueWithPreservedMatches, round - 1);
      }

      // 3. 组合并保存
      final finalMatches = [...preservedMatches, ...newRoundMatches];
      final updatedLeague = league.copyWith(matches: finalMatches);

      await _leagueDao.saveLeague(updatedLeague);
      await _reloadLeagues();
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

      // 2. 如果是淘汰赛，检查是否需要生成下一轮
      if (league.type == LeagueType.knockout) {
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
      }

      // 3. 保存并刷新状态
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
      final anchorMatch =
          league.matches.firstWhere((m) => m.mid == leagueMatchId);
      final anchorRound = anchorMatch.round;

      // 1. 删除所有后续轮次的比赛
      final preservedMatches =
          league.matches.where((m) => m.round <= anchorRound).toList();
      var updatedLeague = league.copyWith(matches: preservedMatches);

      // 2. 检查锚点轮次是否已全部完成，如果完成则生成下一轮
      if (league.type == LeagueType.knockout) {
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

  List<Match> _generateFirstRoundMatches(
      LeagueType type, List<String> playerIds) {
    if (type == LeagueType.roundRobin) {
      List<Match> matches = [];
      for (int i = 0; i < playerIds.length; i++) {
        for (int j = i + 1; j < playerIds.length; j++) {
          matches.add(Match(
            leagueId: '',
            round: 1,
            player1Id: playerIds[i],
            player2Id: playerIds[j],
          ));
        }
      }
      return matches;
    } else if (type == LeagueType.knockout) {
      return _generateKnockoutRound(playerIds, 1, '');
    }
    return [];
  }

  List<Match> _generateNextRoundMatches(League league, int completedRound) {
    // 获取已完成的上一轮所有比赛
    final completedRoundMatches = league.matches
        .where((m) => m.round == completedRound && m.winnerId != null)
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
    return _generateKnockoutRound(winners, completedRound + 1, league.lid);
  }

  List<Match> _generateKnockoutRound(
      List<String> playerIds, int round, String leagueId) {
    List<Match> matches = [];
    var players = List<String>.from(playerIds);

    // 只在第一轮时进行随机排序，以确定初始对阵。
    if (round == 1) {
      players.shuffle();
    }

    // 计算下一个2的幂次方，以确定本轮需要多少个“席位”
    int nextPowerOfTwo = 1;
    while (nextPowerOfTwo < players.length) {
      nextPowerOfTwo *= 2;
    }

    int byes = nextPowerOfTwo - players.length;

    // 1. 分配轮空名额：列表前面的选手获得轮空
    final byePlayers = players.sublist(0, byes);
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
      ));
    }

    // 2. 为剩余玩家两两配对
    final playingPlayers = players.sublist(byes);
    for (int i = 0; i < playingPlayers.length; i += 2) {
      matches.add(Match(
        leagueId: leagueId,
        round: round,
        player1Id: playingPlayers[i],
        player2Id: playingPlayers[i + 1],
      ));
    }

    return matches;
  }
}
