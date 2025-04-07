import 'dart:convert';

class PlayerScore {
  final String playerId;
  final List<int?> roundScores;
  final Map<int, Map<String, dynamic>> roundExtendedFields = {}; // 按回合存储扩展字段

  PlayerScore({
    required this.playerId,
    List<int?>? roundScores,
    Map<String, dynamic>? extendedFiled,
  }) : roundScores = roundScores ?? [];


  @override
  String toString() {
    return 'PlayerScore{playerId: $playerId, roundScores: $roundScores, roundExtendedFields: $roundExtendedFields}';
  }

  int get totalScore => roundScores.fold(0, (sum, item) => sum + (item ?? 0));

  // 获取指定回合的扩展字段
  Map<String, dynamic>? getExtendedField(int roundNumber) {
    return roundExtendedFields[roundNumber];
  }

  // 设置指定回合的扩展字段
  bool setRoundExtendedField(int roundNumber, String key, dynamic value) {
    try {
      roundExtendedFields[roundNumber] ??= {};
      roundExtendedFields[roundNumber]![key] = value;
      return true;
    } catch (e) {
      return false;
    }
  }

  // 将指定回合的扩展字段转换为JSON
  String? extendedFiledToJson(int roundNumber) {
    final data = roundExtendedFields[roundNumber];
    return data == null ? null : jsonEncode(data);
  }

  // 从JSON解析指定回合的扩展字段
  bool extendedFiledFromJson(String? jsonString, int roundNumber) {
    try {
      if (jsonString == null || jsonString.isEmpty) {
        return true;
      }
      final decodedData = jsonDecode(jsonString) as Map<String, dynamic>;
      roundExtendedFields[roundNumber] = decodedData;
      return true;
    } catch (e) {
      return false;
    }
  }

  set extendedFiled(Map<String, dynamic>? value) {
    if (value != null) {
      final currentRound = roundScores.length - 1;
      if (currentRound >= 0) {
        roundExtendedFields[currentRound] = value;
      }
    }
  }

  /// 指定回合，玩家的map数据
  Map<String, dynamic> toMap(String sessionId, int roundNumber, int? score) {
    return {
      'session_id': sessionId,
      'player_id': playerId,
      'round_number': roundNumber,
      'score': score,
      'extended_field': extendedFiledToJson(roundNumber)
    };
  }
}
