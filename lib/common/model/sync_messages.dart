import 'package:freezed_annotation/freezed_annotation.dart';

import 'game_session.dart'; // Assuming GameSession is in this directory

part 'sync_messages.freezed.dart';
part 'sync_messages.g.dart';

/// 通用的 WebSocket 消息包装类
/// 所有通过 WebSocket 传输的消息都应遵循此格式
/// { "type": "消息类型字符串", "data": "消息负载" }
@freezed
sealed class SyncMessage with _$SyncMessage {
  // 不需要私有构造函数，因为这个类没有自定义方法或 getter
  // const SyncMessage._();

  // 工厂构造函数定义消息的结构
  // data 字段的实际类型取决于 type 字段的值
  // 在传输时，data 会被序列化成 JSON；接收时，data 是解析后的 Map 或 List
  const factory SyncMessage({
    required String type, // 消息类型，用于区分消息内容
    dynamic data, // 消息负载，可以是任何 JSON 支持的类型 (Map, List, String, int, bool, null)
  }) = _SyncMessage;

  // 用于从 JSON Map 反序列化 SyncMessage 对象的工厂构造函数
  // 这个 fromJson 方法只解析顶层的 type 和 data 字段
  // 如何解释 data 字段（将其反序列化为具体的 Payload 类）取决于 type 字段的值，
  // 这个逻辑需要在接收到消息后的处理代码中实现。
  factory SyncMessage.fromJson(Map<String, dynamic> json) =>
      _$SyncMessageFromJson(json);

// toJson 方法由 json_serializable 生成，用于将对象序列化为 JSON Map
// Map<String, dynamic> toJson() => _$SyncMessageToJson(this); // 无需手动声明
}

// === 定义各种消息类型的 Payload 数据结构 (data 字段的内容) ===
// 这些类也是用 freezed 和 json_serializable 定义的

/// "sync_state" 消息的负载
/// 包含一个完整的 GameSession 对象，用于全量同步状态
@freezed
sealed class SyncStatePayload with _$SyncStatePayload {
  const SyncStatePayload._(); // 需要私有构造函数，因为我们可能添加方法/getter

  const factory SyncStatePayload({
    required GameSession session, // 完整的游戏会话数据
  }) = _SyncStatePayload;

  factory SyncStatePayload.fromJson(Map<String, dynamic> json) =>
      _$SyncStatePayloadFromJson(json);
}

/// "update_score" 消息的负载
/// 用于单点分数更新 (某个玩家在某个轮次的得分)
@freezed
sealed class UpdateScorePayload with _$UpdateScorePayload {
  const UpdateScorePayload._(); // 需要私有构造函数

  const factory UpdateScorePayload({
    required String playerId, // 玩家ID
    required int roundIndex, // 轮次索引 (0-based, 与 PlayerScore.roundScores 列表索引一致)
    required int? score, // 更新后的分数 (可以是 null)
    // 如果单点更新需要包含扩展字段，可以在这里添加，例如:
    // Map<String, dynamic>? extendedField, // 该轮次的扩展字段 (例如炸弹数、春天状态等)
  }) = _UpdateScorePayload;

  factory UpdateScorePayload.fromJson(Map<String, dynamic> json) =>
      _$UpdateScorePayloadFromJson(json);
}

/// "new_round" 消息的负载
/// 通知新回合开始
@freezed
sealed class NewRoundPayload with _$NewRoundPayload {
  const NewRoundPayload._(); // 需要私有构造函数

  const factory NewRoundPayload({
    // 可以包含新回合的起始信息，例如新的回合索引 (0-based)
    // roundIndex 是指添加新回合后，总的回合数-1，即新回合的索引
    required int newRoundIndex, // 例如，如果从第0轮开始，添加新回合后是第1轮，索引是1
  }) = _NewRoundPayload;

  factory NewRoundPayload.fromJson(Map<String, dynamic> json) =>
      _$NewRoundPayloadFromJson(json);
}

/// "reset_game" 消息的负载
/// 通知游戏重置。负载可以是空的。
@freezed
sealed class ResetGamePayload with _$ResetGamePayload {
  const ResetGamePayload._();

  const factory ResetGamePayload() = _ResetGamePayload;

  factory ResetGamePayload.fromJson(Map<String, dynamic> json) =>
      _$ResetGamePayloadFromJson(json);
}

/// "host_disconnect" 消息的负载
/// 通知主机主动断开连接
@freezed
sealed class HostDisconnectPayload with _$HostDisconnectPayload {
  const HostDisconnectPayload._();

  const factory HostDisconnectPayload({
    String? reason, // 断开原因（可选）
  }) = _HostDisconnectPayload;

  factory HostDisconnectPayload.fromJson(Map<String, dynamic> json) =>
      _$HostDisconnectPayloadFromJson(json);
}

/// "game_end" 消息的负载
/// 通知游戏结束。负载可以包含游戏结果信息。
@freezed
sealed class GameEndPayload with _$GameEndPayload {
  const GameEndPayload._();

  const factory GameEndPayload() = _GameEndPayload;

  factory GameEndPayload.fromJson(Map<String, dynamic> json) =>
      _$GameEndPayloadFromJson(json);
}

/// "player_info" 消息的负载
/// 用于同步玩家信息列表。
// 注意：原始格式是 {"type": "player_info", "data": <List<PlayerInfo> JSON>}
// 这意味着 SyncMessage 的 data 字段直接就是 List<PlayerInfo> 的 JSON 数组
// 所以这里不需要一个包装类 PlayerInfoPayload { List<PlayerInfo> players; }
// SyncMessage { type: "player_info", data: [...] }
// 我们可以直接在接收端将 SyncMessage.data 反序列化为 List<PlayerInfo>
// 但是，我们仍然需要 PlayerInfo 类本身是可序列化的。
// 假设 PlayerInfo 已经定义并且使用了 freezed/json_serializable
// 例如：
/*
@freezed
class PlayerInfo with _$PlayerInfo {
  const PlayerInfo._();
  const factory PlayerInfo({
    required String pid,
    required String name,
    required String avatar, // Maybe avatar is just a path or identifier
  }) = _PlayerInfo;
  factory PlayerInfo.fromJson(Map<String, dynamic> json) => _$PlayerInfoFromJson(json);
}
*/

// 如果 PlayerInfo 不使用 freezed/json_serializable，你需要手动实现它的 toJson/fromJson
// 并确保 List<PlayerInfo> 也能被正确处理。但推荐 PlayerInfo 也使用 freezed。
