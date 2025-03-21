import 'dart:convert';

class PlayerScore {
  final String playerId;
  final List<int?> roundScores;
  Map<String, dynamic>? extendedFiled;

  PlayerScore({
    required this.playerId,
    List<int?>? roundScores,
  }) : roundScores = roundScores ?? [];

  int get totalScore => roundScores.fold(0, (sum, item) => sum + (item ?? 0));

  Map<String, dynamic> toMap(
      String sessionId, int roundNumber, int? score) {
    return {
      'session_id': sessionId,
      'player_id': playerId,
      'round_number': roundNumber,
      'score': score,
      'extended_filed': extendedFiledToJson()
    };
  }

  // 获取指定类型的值，如果不存在或类型不匹配则返回默认值
  T? getExtendedFiled<T>(String key, {T? defaultValue}) {
    try {
      final value = extendedFiled?[key];
      if (value == null) return defaultValue;
      if (value is T) return value;
      return defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  // 设置值并返回是否成功
  bool setExtendedFiled(String key, dynamic value) {
    try {
      extendedFiled ??= {};
      extendedFiled![key] = value;
      return true;
    } catch (e) {
      return false;
    }
  }

  // 移除指定键值
  bool removeExtendedFiled(String key) {
    try {
      extendedFiled?.remove(key);
      return true;
    } catch (e) {
      return false;
    }
  }

  // 将 extendedFiled 转换为 JSON 字符串
  String? extendedFiledToJson() {
    return extendedFiled == null ? null : jsonEncode(extendedFiled);
  }

  // 从 JSON 字符串解析 extendedFiled
  bool extendedFiledFromJson(String? jsonString) {
    try {
      if (jsonString == null || jsonString.isEmpty) {
        extendedFiled = null;
        return true;
      }
      extendedFiled = jsonDecode(jsonString);
      return true;
    } catch (e) {
      return false;
    }
  }
}
