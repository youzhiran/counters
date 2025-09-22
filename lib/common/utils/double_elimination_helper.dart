import 'dart:collection';

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

    final generatedMatches = <Match>[];
    var workingMatches = List<Match>.from(league.matches);
    var workingLeague = league.copyWith(matches: workingMatches);

    while (true) {
      final maxCompletedWinnerRound =
          _maxFullyCompletedRound(workingLeague, BracketType.winner);
      final maxCompletedLoserRound =
          _maxFullyCompletedRound(workingLeague, BracketType.loser);

      Log.d(
          '[双败算法] 已完成的最大轮次: 胜者组=$maxCompletedWinnerRound, 败者组=$maxCompletedLoserRound');

      final loserMatches = _tryGenerateNextLoserRound(
        league: workingLeague,
        maxCompletedWinnerRound: maxCompletedWinnerRound,
      );

      if (loserMatches.isNotEmpty) {
        Log.i('[双败算法] 成功为败者组生成了 ${loserMatches.length} 场新比赛。');
        generatedMatches.addAll(loserMatches);
        workingMatches = [...workingMatches, ...loserMatches];
        workingLeague = workingLeague.copyWith(matches: workingMatches);
        // 新增的败者组比赛可能会立即解锁后续阶段，继续循环。
        continue;
      }

      if (maxCompletedWinnerRound == 0) {
        Log.d('[双败算法] 胜者组尚未完成任何一轮，暂不生成新比赛。');
        break;
      }

      final winnerMatches = _generateNextWinnerBracketRound(
          workingLeague, maxCompletedWinnerRound);

      if (winnerMatches.isNotEmpty) {
        Log.i('[双败算法] 成功为胜者组生成了 ${winnerMatches.length} 场新比赛。');
        generatedMatches.addAll(winnerMatches);
        workingMatches = [...workingMatches, ...winnerMatches];
        workingLeague = workingLeague.copyWith(matches: workingMatches);
        continue;
      }

      Log.d('[双败算法] 未能生成新的比赛，锦标赛可能已达到终点。');
      break;
    }

    return generatedMatches;
  }

  /// 为胜者组生成下一轮比赛。
  static List<Match> _generateNextWinnerBracketRound(
      League league, int completedRound) {
    final nextRound = completedRound + 1;
    final hasExistingNextRound = league.matches.any(
        (m) => m.bracketType == BracketType.winner && m.round == nextRound);
    if (hasExistingNextRound) {
      return [];
    }

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

  /// 计算某一胜者组轮次的败者首次出现在败者组中的轮次。
  static int firstLoserRoundAffectedByWinnerRound(int winnerRound) {
    if (winnerRound <= 1) {
      return 1;
    }
    return (winnerRound - 1) * 2;
  }

  /// 根据当前联赛状态判断是否需要生成下一轮败者组比赛。
  static List<Match> _tryGenerateNextLoserRound({
    required League league,
    required int maxCompletedWinnerRound,
  }) {
    final loserRounds = league.matches
        .where((m) => m.bracketType == BracketType.loser)
        .map((m) => m.round)
        .toSet();
    final maxExistingLoserRound =
        loserRounds.isEmpty ? 0 : loserRounds.reduce((a, b) => a > b ? a : b);
    final nextLoserRound = maxExistingLoserRound + 1;

    final maxLoserRounds = totalLoserRoundsForPlayers(league.playerIds.length);

    if (nextLoserRound == 0 || nextLoserRound > maxLoserRounds) {
      return [];
    }

    // 防止重复生成：如果该轮次的比赛已经存在，则不再生成。
    final hasMatchesForNextRound = league.matches.any(
        (m) => m.bracketType == BracketType.loser && m.round == nextLoserRound);
    if (hasMatchesForNextRound) {
      return [];
    }

    if (nextLoserRound == 1) {
      if (!_isRoundCompleted(league, BracketType.winner, 1)) {
        Log.d('[双败算法] 等待胜者组第1轮完成后再生成败者组首轮。');
        return [];
      }

      final initialLosers = _getUnassignedWinnerLosers(league, 1);
      if (initialLosers.isEmpty) {
        Log.w('[双败算法] 胜者组第1轮尚未产生足够的败者来开启败者组。');
        return [];
      }

      Log.d('[双败算法] 生成败者组第1轮（阶段一）比赛。');
      return _pairPlayers(
        players: initialLosers,
        leagueId: league.lid,
        round: nextLoserRound,
        bracketType: BracketType.loser,
      );
    }

    // 从第二轮开始，败者组每个阶段的生成都依赖于前一轮的完成情况。
    final previousRound = nextLoserRound - 1;
    if (!_isRoundCompleted(league, BracketType.loser, previousRound)) {
      Log.d('[双败算法] 败者组第$previousRound轮尚未结束，无法生成下一轮。');
      return [];
    }

    final previousWinners = _getLoserRoundWinners(league, previousRound);

    if (nextLoserRound.isOdd) {
      // 阶段一：败者组内部对决。
      Log.d('[双败算法] 生成败者组第$nextLoserRound轮（阶段一）比赛。');
      return _pairPlayers(
        players: previousWinners,
        leagueId: league.lid,
        round: nextLoserRound,
        bracketType: BracketType.loser,
      );
    } else {
      // 阶段二：接收胜者组刚刚掉落的选手。
      final targetWinnerRound = nextLoserRound ~/ 2 + 1;
      if (targetWinnerRound > maxCompletedWinnerRound ||
          !_isRoundCompleted(league, BracketType.winner, targetWinnerRound)) {
        Log.d('[双败算法] 胜者组第$targetWinnerRound轮尚未完成，等待后再生成败者组阶段二。');
        return [];
      }

      final pendingWinnerLosers =
          _getUnassignedWinnerLosers(league, targetWinnerRound);
      if (previousWinners.isEmpty && pendingWinnerLosers.isEmpty) {
        return [];
      }

      if (pendingWinnerLosers.length != previousWinners.length) {
        Log.w(
            '[双败算法] 阶段二配对人数不匹配：胜者组败者 ${pendingWinnerLosers.length} 人，败者组胜者 ${previousWinners.length} 人，将自动分配轮空。');
      }

      Log.d('[双败算法] 生成败者组第$nextLoserRound轮（阶段二）比赛。');
      final matches = <Match>[];
      final previousQueue = Queue<String>.from(previousWinners);
      final droppingQueue = Queue<String>.from(pendingWinnerLosers);

      while (previousQueue.isNotEmpty || droppingQueue.isNotEmpty) {
        final previous =
            previousQueue.isNotEmpty ? previousQueue.removeFirst() : null;
        final dropping =
            droppingQueue.isNotEmpty ? droppingQueue.removeFirst() : null;

        if (previous != null && dropping != null) {
          matches.add(Match(
            leagueId: league.lid,
            round: nextLoserRound,
            player1Id: previous,
            player2Id: dropping,
            bracketType: BracketType.loser,
          ));
          continue;
        }

        final autoAdvancePlayer = previous ?? dropping;
        if (autoAdvancePlayer == null) {
          break;
        }
        matches.add(_createByeMatch(
          leagueId: league.lid,
          round: nextLoserRound,
          bracketType: BracketType.loser,
          advancingPlayerId: autoAdvancePlayer,
        ));
      }
      return matches;
    }
  }

  static bool _isRoundCompleted(League league, BracketType type, int round) {
    final matches = league.matches
        .where((m) => m.bracketType == type && m.round == round)
        .toList();
    if (matches.isEmpty) return false;
    return matches.every((m) => m.status == MatchStatus.completed);
  }

  static List<String> _getLoserRoundWinners(League league, int round) {
    return league.matches
        .where((m) =>
            m.bracketType == BracketType.loser &&
            m.round == round &&
            m.status == MatchStatus.completed &&
            m.winnerId != null)
        .sortedBy((m) => m.mid)
        .map((m) => m.winnerId!)
        .toList();
  }

  static List<String> _getUnassignedWinnerLosers(League league, int round) {
    final losers = league.matches
        .where((m) =>
            m.bracketType == BracketType.winner &&
            m.round == round &&
            m.status == MatchStatus.completed &&
            m.player2Id != 'bye')
        .sortedBy((m) => m.mid)
        .map((m) => m.winnerId == m.player1Id ? m.player2Id! : m.player1Id)
        .toList();

    if (losers.isEmpty) {
      return [];
    }

    final assignedPlayers = league.matches
        .where((m) => m.bracketType == BracketType.loser)
        .expand((m) => [m.player1Id, m.player2Id])
        .whereType<String>()
        .where((pid) => pid != 'bye')
        .toSet();

    return losers.where((pid) => !assignedPlayers.contains(pid)).toList();
  }

  static int _maxFullyCompletedRound(League league, BracketType bracketType) {
    final rounds = league.matches
        .where((m) => m.bracketType == bracketType)
        .groupListsBy((m) => m.round);

    var maxRound = 0;
    for (final entry in rounds.entries) {
      final round = entry.key;
      final matches = entry.value;
      if (matches.isEmpty) {
        continue;
      }
      final isCompleted =
          matches.every((match) => match.status == MatchStatus.completed);
      if (isCompleted && round > maxRound) {
        maxRound = round;
      }
    }

    return maxRound;
  }

  static int totalWinnerRoundsForPlayers(int playerCount) {
    if (playerCount <= 1) {
      return 1;
    }
    int rounds = 0;
    int size = 1;
    while (size < playerCount) {
      size *= 2;
      rounds++;
    }
    return rounds;
  }

  static int totalLoserRoundsForPlayers(int playerCount) {
    final totalWinnerRounds = totalWinnerRoundsForPlayers(playerCount);
    if (totalWinnerRounds <= 1) {
      return 0;
    }
    return (totalWinnerRounds - 1) * 2;
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
        matches.add(_createByeMatch(
          leagueId: leagueId,
          round: round,
          bracketType: bracketType,
          advancingPlayerId: players[i],
        ));
      }
    }
    return matches;
  }

  static Match _createByeMatch({
    required String leagueId,
    required int round,
    required BracketType? bracketType,
    required String advancingPlayerId,
  }) {
    final now = DateTime.now();
    final bracketLabel =
        bracketType != null ? '${bracketType.name}第$round轮' : '第$round轮';
    Log.i('[双败算法] 为选手 $advancingPlayerId 在$bracketLabel 创建轮空晋级。');
    return Match(
      leagueId: leagueId,
      round: round,
      player1Id: advancingPlayerId,
      player2Id: 'bye',
      status: MatchStatus.completed,
      winnerId: advancingPlayerId,
      startTime: now,
      endTime: now,
      bracketType: bracketType,
    );
  }
}
