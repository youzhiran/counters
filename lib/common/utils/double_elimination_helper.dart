import 'package:collection/collection.dart';
import 'package:counters/common/model/league.dart';
import 'package:counters/common/model/league_enums.dart';
import 'package:counters/common/model/match.dart';
import 'package:counters/common/utils/log.dart';

/// 一个用于管理双败淘汰赛逻辑的辅助类。
class DoubleEliminationHelper {
  /// 分析双败淘汰赛联赛的当前状态，并基于一个确定性的、标准的对阵结构来生成下一轮的比赛。
  ///
  /// 此方法包含了重构后的、确定性的双败淘汰赛推进算法。
  ///
  /// [league] 当前的联赛对象，包含所有已完成和待定的比赛。
  ///
  /// 返回一个需要被添加到联赛中的新 [Match] 对象列表。
  static List<Match> advanceTournament(League league) {
    Log.d('[双败算法] 开始为联赛推进赛程: ${league.name} (${league.lid})');

    // 1. 分析胜者组和败者组的当前状态
    final completedWinnerRounds = league.matches
        .where((m) =>
            m.bracketType == BracketType.winner &&
            m.status == MatchStatus.completed)
        .map((m) => m.round)
        .toSet();
    final maxCompletedWinnerRound =
        completedWinnerRounds.isEmpty ? 0 : completedWinnerRounds.reduce(max);

    final completedLoserRounds = league.matches
        .where((m) =>
            m.bracketType == BracketType.loser &&
            m.status == MatchStatus.completed)
        .map((m) => m.round)
        .toSet();
    final maxCompletedLoserRound =
        completedLoserRounds.isEmpty ? 0 : completedLoserRounds.reduce(max);

    Log.d(
        '[双败算法] 已完成的最大轮次: 胜者组=$maxCompletedWinnerRound, 败者组=$maxCompletedLoserRound');

    List<Match> newMatches = [];

    // 规则A: 胜者组进度领先，此时应生成败者组比赛。
    if (maxCompletedWinnerRound > maxCompletedLoserRound) {
      Log.d('[双败算法] 规则A触发: 胜者组领先，开始生成下一轮败者组比赛。');
      newMatches =
          _generateLoserBracketMatches(league, maxCompletedWinnerRound);
    }
    // 规则B: 两组进度持平，此时应生成胜者组的下一轮比赛。
    else if (maxCompletedWinnerRound == maxCompletedLoserRound &&
        maxCompletedWinnerRound > 0) {
      Log.d('[双败算法] 规则B触发: 两组持平，开始生成下一轮胜者组比赛。');
      newMatches =
          _generateNextWinnerBracketRound(league, maxCompletedWinnerRound);
    } else {
      Log.d('[双败算法] 未触发任何推进规则，不生成新比赛。');
    }

    if (newMatches.isNotEmpty) {
      Log.i('[双败算法] 成功生成了 ${newMatches.length} 场新比赛。');
    }

    return newMatches;
  }

  /// 为胜者组生成下一轮比赛。
  static List<Match> _generateNextWinnerBracketRound(
      League league, int completedRound) {
    final winners = league.matches
        .where((m) =>
            m.bracketType == BracketType.winner &&
            m.round == completedRound &&
            m.status == MatchStatus.completed &&
            m.winnerId != null)
        .sortedBy((m) => m.mid) // 通过排序确保配对的稳定性
        .map((m) => m.winnerId!)
        .toList();

    if (winners.length < 2) {
      return []; // 胜者组冠军已决出
    }

    return _pairPlayers(
      players: winners,
      leagueId: league.lid,
      round: completedRound + 1,
      bracketType: BracketType.winner,
    );
  }

  /// 根据已完成的胜者组轮次结果，为败者组生成比赛。
  static List<Match> _generateLoserBracketMatches(
      League league, int completedWinnerRound) {
    // 获取刚刚结束的胜者组轮次的败者，并排序以确保对阵确定性。
    final wbLosers = league.matches
        .where((m) =>
                m.bracketType == BracketType.winner &&
                m.round == completedWinnerRound &&
                m.status == MatchStatus.completed &&
                m.player2Id != 'bye' // 排除轮空
            )
        .sortedBy((m) => m.mid)
        .map((m) => m.winnerId == m.player1Id ? m.player2Id! : m.player1Id)
        .toList();

    // 获取当前败者组的最大轮次
    final existingLoserRounds = league.matches
        .where((m) => m.bracketType == BracketType.loser)
        .map((m) => m.round)
        .toSet();
    final maxLoserRound =
        existingLoserRounds.isEmpty ? 0 : existingLoserRounds.reduce(max);

    // 在败者组中，配对逻辑是交替的。
    if (completedWinnerRound == 1) {
      // WB R1之后，败者们直接相互配对，构成 LB R1。
      final nextLoserRound = maxLoserRound + 1;
      Log.d('[双败算法] 正在从胜者组第1轮的败者生成败者组第 $nextLoserRound 轮...');
      return _pairPlayers(
        players: wbLosers,
        leagueId: league.lid,
        round: nextLoserRound,
        bracketType: BracketType.loser,
      );
    } else {
      // 后续轮次：需要判断是“内部轮次”还是“接收轮次”。
      final lbWinners = league.matches
          .where((m) =>
              m.bracketType == BracketType.loser &&
              m.round == maxLoserRound &&
              m.status == MatchStatus.completed &&
              m.winnerId != null)
          .sortedBy((m) => m.mid)
          .map((m) => m.winnerId!)
          .toList();

      // 如果等待的败者组胜者比新掉下来的胜者组败者多，说明是“内部轮次”。
      if (lbWinners.length > wbLosers.length) {
        final nextLoserRound = maxLoserRound + 1;
        Log.d(
            '[双败算法] 识别为内部轮次。正在通过配对败者组第 $maxLoserRound 轮的胜者，生成败者组第 $nextLoserRound 轮...');
        return _pairPlayers(
          players: lbWinners,
          leagueId: league.lid,
          round: nextLoserRound,
          bracketType: BracketType.loser,
        );
      } else {
        // 否则，是“接收轮次”，配对胜者组败者和败者组胜者。
        final nextLoserRound = maxLoserRound + 1;
        Log.d(
            '[双败算法] 识别为接收轮次。正在通过配对胜者组第 $completedWinnerRound 轮的败者和败者组第 $maxLoserRound 轮的胜者，生成败者组第 $nextLoserRound 轮...');

        if (wbLosers.length != lbWinners.length) {
          Log.e(
              '[双败算法] 为接收轮次 LB R$nextLoserRound 配对时发生人数不匹配错误。胜者组败者: ${wbLosers.length}, 败者组胜者: ${lbWinners.length}。无法生成比赛。');
          return [];
        }

        // 将败者组胜者列表反转以实现交叉配对。
        final reversedLbWinners = lbWinners.reversed.toList();

        // 进行配对: 第1个胜者组败者 vs (反转后的)第1个败者组胜者, 依此类推。
        List<Match> newMatches = [];
        for (int i = 0; i < wbLosers.length; i++) {
          newMatches.add(Match(
            leagueId: league.lid,
            round: nextLoserRound,
            player1Id: wbLosers[i],
            player2Id: reversedLbWinners[i],
            bracketType: BracketType.loser,
          ));
        }
        return newMatches;
      }
    }
  }

  /// 一个通用的配对函数，按顺序将选手两两配对。
  static List<Match> _pairPlayers({
    required List<String> players,
    required String leagueId,
    required int round,
    required BracketType bracketType,
  }) {
    List<Match> matches = [];
    for (int i = 0; i < players.length; i += 2) {
      if (i + 1 < players.length) {
        matches.add(Match(
          leagueId: leagueId,
          round: round,
          player1Id: players[i],
          player2Id: players[i + 1],
          bracketType: bracketType,
        ));
      } else {
        // 在2的次方参赛人数的比赛中，理论上不应出现轮空，保留作为安全措施。
        Log.w('[双败算法] 在一个2的次方人数的锦标赛中为选手 ${players[i]} 生成了一场轮空赛，这不符合预期。');
        matches.add(Match(
          leagueId: leagueId,
          round: round,
          player1Id: players[i],
          player2Id: 'bye',
          status: MatchStatus.completed,
          winnerId: players[i],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
          bracketType: bracketType,
        ));
      }
    }
    return matches;
  }
}

int max(int a, int b) => a > b ? a : b;
