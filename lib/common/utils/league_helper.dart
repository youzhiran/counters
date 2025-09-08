import 'dart:math';

import 'package:counters/common/model/league_enums.dart';

/// 根据总玩家数和当前轮次，获取轮次的友好名称
String getRoundName(int totalPlayers, int round, {BracketType? bracketType}) {
  if (bracketType == BracketType.loser) {
    return '败者组第 $round 轮';
  }

  if (bracketType == BracketType.finals) {
    return '总决赛';
  }

  if (bracketType == BracketType.winner) {
    return '胜者组第 $round 轮';
  }

  // 默认视为单败淘汰赛
  if (totalPlayers < 2) return '未知轮次';

  // 找到大于等于总玩家数的最小的2的次方数
  int nextPowerOfTwo = 1;
  while (nextPowerOfTwo < totalPlayers) {
    nextPowerOfTwo *= 2;
  }

  // 总轮次 = log2(修正后的总席位数)
  final totalRounds = (log(nextPowerOfTwo) / log(2)).ceil();

  if (round > totalRounds) {
    // 在双败淘汰赛中，总决赛的轮次可能大于理论上的单败轮次数
    final existingFinals = round - totalRounds;
    if (existingFinals > 0) {
      return '总决赛';
    }
    return '附加赛';
  }

  final remainingRounds = totalRounds - round;

  if (remainingRounds == 0) {
    return '决赛';
  } else if (remainingRounds == 1) {
    return '半决赛';
  } else {
    final teamsInRound = pow(2, totalRounds - round + 1);
    return '1/${teamsInRound ~/ 2}决赛';
  }
}
