import 'dart:math';

/// 根据总玩家数和当前轮次，获取轮次的友好名称
String getRoundName(int totalPlayers, int round) {
  if (totalPlayers < 2) return '未知轮次';

  // 总轮次 = log2(总玩家数)
  final totalRounds = (log(totalPlayers) / log(2)).ceil();

  if (round > totalRounds) return '附加赛';

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
