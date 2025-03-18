class PlayerScore {
  final String playerId;
  final List<int?> roundScores;

  PlayerScore({
    required this.playerId,
    List<int?>? roundScores,
  }) : roundScores = roundScores ?? [];

  int get totalScore => roundScores.fold(0, (sum, item) => sum + (item ?? 0));

  Map<String, dynamic> toMap(String sessionId, int roundNumber, int? score) {
    return {
      'session_id': sessionId,
      'player_id': playerId,
      'round_number': roundNumber,
      'score': score,
    };
  }
}
