import 'dart:convert';

class PlayerScore {
  final String playerId;
  final List<int?> roundScores;
  final Map<int, Map<String, dynamic>> roundExtendedFields = {}; // 按回合存储扩展字段
  // Map<String, dynamic>? extendedFiled; //ScoreProvider中scores内的extendedFiled

  PlayerScore({
    required this.playerId,
    List<int?>? roundScores,
    Map<String, dynamic>? extendedFiled,
  }) : roundScores = roundScores ?? [];

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
      'extended_filed': extendedFiledToJson(roundNumber)
    };
  }

  // /// 指定回合，玩家的map数据
  // Map<String, dynamic> toMap(String sessionId, int roundNumber, int? score) {
  //   return {
  //     'session_id': sessionId,
  //     'player_id': playerId,
  //     'round_number': roundNumber,
  //     'score': score,
  //     'extended_filed': extendedFiledToJson()
  //   };
  // }

  // // 获取指定类型的值，如果不存在或类型不匹配则返回默认值
  // T? getExtendedFiled<T>(String key, {T? defaultValue}) {
  //   try {
  //     final value = extendedFiled?[key];
  //     if (value == null) return defaultValue;
  //     if (value is T) return value;
  //     return defaultValue;
  //   } catch (e) {
  //     return defaultValue;
  //   }
  // }
  //
  // // 设置值并返回是否成功
  // bool setExtendedFiled(String key, dynamic value) {
  //   try {
  //     extendedFiled ??= {};
  //     extendedFiled![key] = value;
  //     return true;
  //   } catch (e) {
  //     return false;
  //   }
  // }
  //
  // // 移除指定键值
  // bool removeExtendedFiled(String key) {
  //   try {
  //     extendedFiled?.remove(key);
  //     return true;
  //   } catch (e) {
  //     return false;
  //   }
  // }

  // // 设置指定回合的扩展字段
  // bool setRoundExtendedField(String key, dynamic value) {
  //   try {
  //     extendedFiled ??= {};
  //     extendedFiled![key] = value;
  //     return true;
  //   } catch (e) {
  //     return false;
  //   }
  // }

  // // 将 extendedFiled 转换为 JSON 字符串
  // String? extendedFiledToJson() {
  //   return extendedFiled == null ? null : jsonEncode(extendedFiled);
  // }

  // // 从 JSON 字符串解析并合并回合扩展字段
  // bool extendedFiledFromJson(String? jsonString, int? roundNumber) {
  //   try {
  //     if (jsonString == null || jsonString.isEmpty) {
  //       return true;
  //     }

  //     // 解析JSON数据
  //     final decodedData = jsonDecode(jsonString) as Map<String, dynamic>;

  //     extendedFiled = decodedData;

  //     return true;
  //   } catch (e) {
  //     return false;
  //   }
  // }
}
