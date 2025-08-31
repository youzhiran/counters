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
      await _leagueDao.deleteLeague(lid);
      await _reloadLeagues();
    } catch (e, s) {
      ErrorHandler.handle(e, s);
      state = AsyncError(e, s);
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
      await _reloadLeagues();
    } catch (e, s) {
      ErrorHandler.handle(e, s, prefix: '更新比赛结果失败');
      state = AsyncError(e, s);
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
    final winners = league.matches
        .where((m) => m.round == completedRound && m.winnerId != null)
        .map((m) => m.winnerId!)
        .toList();

    if (winners.length < 2) {
      return []; // 冠军已产生
    }

    return _generateKnockoutRound(winners, completedRound + 1, league.lid);
  }

  List<Match> _generateKnockoutRound(
      List<String> playerIds, int round, String leagueId) {
    List<Match> matches = [];
    var players = List<String>.from(playerIds)..shuffle();

    // 计算下一个2的幂次方
    int nextPowerOfTwo = 1;
    while (nextPowerOfTwo < players.length) {
      nextPowerOfTwo *= 2;
    }

    int byes = nextPowerOfTwo - players.length;
    int matchesInRound = (players.length - byes) ~/ 2;

    // 分配轮空名额
    for (int i = 0; i < byes; i++) {
      String byePlayer = players.removeAt(0);
      matches.add(Match(
        leagueId: leagueId,
        round: round,
        player1Id: byePlayer,
        player2Id: 'bye',
        // 特殊ID表示轮空
        status: MatchStatus.completed,
        winnerId: byePlayer,
        startTime: DateTime.now(),
        endTime: DateTime.now(),
      ));
    }

    // 为剩余玩家配对
    for (int i = 0; i < matchesInRound; i++) {
      matches.add(Match(
        leagueId: leagueId,
        round: round,
        player1Id: players.removeAt(0),
        player2Id: players.removeAt(0),
      ));
    }

    return matches;
  }
}
