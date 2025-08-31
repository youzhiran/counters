import 'package:counters/common/model/league_enums.dart';
import 'package:counters/common/model/match.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'league.freezed.dart';

part 'league.g.dart';

@freezed
abstract class League with _$League {
  const factory League.internal({
    required String lid,
    required String name,
    required LeagueType type,
    required List<String> playerIds,
    required List<Match> matches,
    required String defaultTemplateId,
    // Round-robin specific settings
    @Default(3) int pointsForWin,
    @Default(1) int pointsForDraw,
    @Default(0) int pointsForLoss,
    // Knockout specific settings
    int? currentRound,
  }) = _League;

  factory League({
    String? lid,
    required String name,
    required LeagueType type,
    required List<String> playerIds,
    required List<Match> matches,
    required String defaultTemplateId,
    int? pointsForWin,
    int? pointsForDraw,
    int? pointsForLoss,
    int? currentRound,
  }) {
    return League.internal(
      lid: lid ?? const Uuid().v4(),
      name: name,
      type: type,
      playerIds: playerIds,
      matches: matches,
      defaultTemplateId: defaultTemplateId,
      pointsForWin: pointsForWin ?? 3,
      pointsForDraw: pointsForDraw ?? 1,
      pointsForLoss: pointsForLoss ?? 0,
      currentRound: currentRound,
    );
  }

  factory League.fromJson(Map<String, dynamic> json) => _$LeagueFromJson(json);
}
