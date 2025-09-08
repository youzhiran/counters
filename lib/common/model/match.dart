import 'package:counters/common/model/league_enums.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'match.freezed.dart';
part 'match.g.dart';

@freezed
abstract class Match with _$Match {
  const factory Match.internal({
    required String mid,
    required String leagueId,
    required int round,
    required String player1Id,
    String? player2Id, // 在淘汰赛中，选手2可能稍后确定
    @Default(MatchStatus.pending) MatchStatus status,
    int? player1Score,
    int? player2Score,
    String? winnerId,
    String? templateId, // 本场比赛使用的计分模板
    DateTime? startTime,
    DateTime? endTime,
    BracketType? bracketType,
  }) = _Match;

  factory Match({
    String? mid,
    required String leagueId,
    required int round,
    required String player1Id,
    String? player2Id,
    MatchStatus? status,
    int? player1Score,
    int? player2Score,
    String? winnerId,
    String? templateId,
    DateTime? startTime,
    DateTime? endTime,
    BracketType? bracketType,
  }) {
    return Match.internal(
      mid: mid ?? const Uuid().v4(),
      leagueId: leagueId,
      round: round,
      player1Id: player1Id,
      player2Id: player2Id,
      status: status ?? MatchStatus.pending,
      player1Score: player1Score,
      player2Score: player2Score,
      winnerId: winnerId,
      templateId: templateId,
      startTime: startTime,
      endTime: endTime,
      bracketType: bracketType,
    );
  }

  factory Match.fromJson(Map<String, dynamic> json) => _$MatchFromJson(json);

  static Match empty = const Match.internal(
    mid: '',
    leagueId: '',
    round: 0,
    player1Id: '',
  );
}
