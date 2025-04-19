import 'dart:convert'; // 用于 jsonEncode

import 'package:freezed_annotation/freezed_annotation.dart';

// 这两行是必须的，告诉 build_runner 生成哪些文件
part 'player_score.freezed.dart';
part 'player_score.g.dart'; // json_serializable 生成的文件

/// 玩家在一次游戏会话中的得分模型。
/// 使用 freezed 进行不可变性、值比较、copy方法，并结合 json_serializable 进行JSON序列化。
@freezed
class PlayerScore with _$PlayerScore {
  // === 必须的私有命名构造函数 ===
  // 当你添加了自定义的 getter 或方法时，freezed 需要这个构造函数来混合生成的代码。
  const PlayerScore._();

  // === Freezed 工厂构造函数 - 定义模型的字段 ===
  // 这些字段将被 json_serializable 用于生成 toJson 和 fromJson
  const factory PlayerScore({
    required String playerId, // 玩家唯一ID
    // 回合得分列表。List<int?> 可以被 json_serializable 直接处理为 JSON 数组。
    // @Default([]) 表示如果 JSON 中没有这个字段或者为 null，则默认值为 []。
    @Default([]) List<int?> roundScores,
    // 按回合存储的扩展字段。Map<int, Map<String, dynamic>> 可以被 json_serializable 处理为 JSON 对象。
    // 注意：JSON 的 key 必须是字符串，json_serializable 会自动将 int key 转换为字符串。
    // @Default({}) 表示如果 JSON 中没有这个字段或者为 null，则默认值为 {}。
    @Default({}) Map<int, Map<String, dynamic>> roundExtendedFields,
  }) = _PlayerScore; // = 后面的名字是生成类的前缀

  // === JSON 序列化/反序列化方法 (由 json_serializable 生成) ===
  // 用于通过 WebSocket 等方式传输完整的 PlayerScore 对象

  /// 从 JSON Map 反序列化为 PlayerScore 对象
  factory PlayerScore.fromJson(Map<String, dynamic> json) =>
      _$PlayerScoreFromJson(json);

  /// 将 PlayerScore 对象序列化为 JSON Map (toJson 方法由 json_serializable 生成，无需手动写)
  // Map<String, dynamic> toJson() => _$PlayerScoreToJson(this); // 这个方法是自动生成的，无需手动声明

  // === 自定义计算属性和方法 (不参与 JSON 序列化，但依赖模型状态) ===

  /// 计算总得分
  int get totalScore => roundScores.fold(0, (sum, item) => sum + (item ?? 0));

  /// 获取指定回合的扩展字段
  /// [roundNumber]  回合号 (通常从1开始，与数据库存储一致；如果roundScores从0开始，需要调整逻辑)
  Map<String, dynamic>? getExtendedField(int roundNumber) {
    // Freezed 模型是不可变的，这里只是获取值，是安全的。
    return roundExtendedFields[roundNumber + 1];
  }

  /// 设置指定回合的扩展字段。由于 PlayerScore 是不可变的，此方法返回一个新的 PlayerScore 实例。
  /// [roundNumber]  回合号
  /// [key]  要设置的扩展字段的 key
  /// [value]  要设置的扩展字段的值
  PlayerScore setRoundExtendedField(
      int roundNumber, String key, dynamic value) {
    // 创建一个新的 roundExtendedFields map 的深拷贝副本，避免修改原始 map
    final newExtendedFields = Map<int, Map<String, dynamic>>.fromEntries(
        roundExtendedFields.entries.map((entry) {
      // 深拷贝内层的 Map<String, dynamic>
      return MapEntry(entry.key, Map<String, dynamic>.from(entry.value));
    }));
    newExtendedFields[roundNumber] ??= {}; // 如果该回合的 map 不存在，创建一个
    newExtendedFields[roundNumber]![key] = value; // 设置或更新值

    // 使用 copyWith 创建一个新的 PlayerScore 实例，替换 roundExtendedFields
    return copyWith(roundExtendedFields: newExtendedFields);
  }

  /// 将指定回合的扩展字段转换为 JSON 字符串。
  /// [roundNumber]  回合号
  String? extendedFieldToJsonString(int roundNumber) {
    final data = roundExtendedFields[roundNumber];
    return data == null ? null : jsonEncode(data);
  }

  // === 数据库序列化方法 (保留原有逻辑，用于数据库单行存储) ===
  // 这个方法用于将玩家在一个特定会话的特定回合得分信息转换为数据库表 player_scores 的 Map 格式。
  // 它不是整个 PlayerScore 对象的序列化。

  /// 将特定回合的得分信息转换为数据库表 player_scores 的 Map 格式
  /// [sessionId] 游戏会话 ID
  /// [roundNumber]  回合号 (与数据库存储一致)
  /// [score]  该回合的得分
  Map<String, dynamic> toSingleScoreDatabaseMap(
      String sessionId, int roundNumber, int? score) {
    // 这个方法是基于传入参数和 PlayerScore 实例的 playerId 以及指定回合的 extendedField 生成 Map
    // 注意：这里的 score 和 roundNumber 来自参数，而不是 PlayerScore 实例的 roundScores 列表
    // 但 extendedField 来自 PlayerScore 实例的状态
    return {
      'session_id': sessionId, // 游戏会话 ID (外部传入)
      'player_id': playerId, // 玩家 ID (来自 PlayerScore 实例)
      'round_number': roundNumber, // 回合号 (外部传入)
      'score': score, // 得分 (外部传入)
      // 使用自定义方法将指定回合的扩展字段转换为 JSON 字符串
      'extended_field': extendedFieldToJsonString(roundNumber)
    };
  }

// toString() 方法由 freezed 自动生成，无需手动实现
// @override
// String toString() { ... }
}
