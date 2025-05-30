import 'package:counters/common/utils/log.dart'; // 确保导入日志库
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

import 'player_score.dart'; // 确保正确导入 PlayerScore 模型

// 这两行是必须的，告诉 build_runner 生成哪些文件
part 'game_session.freezed.dart';
part 'game_session.g.dart'; // json_serializable 生成的文件

/// 游戏会话模型，用于在内存中表示一个完整的计分游戏会话。
/// 使用 freezed 进行不可变性、值比较、copy方法，并结合 json_serializable 进行JSON序列化。
@freezed
sealed class GameSession with _$GameSession {
  // 添加私有的命名构造函数。
  // 虽然当前 GameSession 没有自定义 getter/methods 直接写在类体内，
  // 但养成习惯添加这个，以防将来需要添加。
  const GameSession._();

  // === Freezed 工厂构造函数 - 定义模型的字段 ===
  // 这些字段将被 json_serializable 用于生成 toJson 和 fromJson
  const factory GameSession({
    required String sid, // 会话唯一ID
    required String templateId, // 使用的模板ID
    required DateTime startTime, // 会话开始时间 (将被json_serializable自动处理为ISO 8601字符串)
    DateTime? endTime, // 会话结束时间 (可选)
    required bool isCompleted, // 会话是否已完成 (将被json_serializable自动处理为true/false)
    required List<PlayerScore> scores, // 玩家得分列表 (PlayerScore 也必须是可序列化的)
  }) = _GameSession; // = 后面的名字是生成类的前缀

  // === JSON 序列化/反序列化方法 (由 json_serializable 生成) ===
  // 用于通过 WebSocket 等方式传输完整的 GameSession 对象

  /// 从 JSON Map 反序列化为 GameSession 对象
  factory GameSession.fromJson(Map<String, dynamic> json) =>
      _$GameSessionFromJson(json);

  /// 将 GameSession 对象序列化为 JSON Map (toJson 方法由 json_serializable 生成，无需手动写)
  // Map<String, dynamic> toJson() => _$GameSessionToJson(this); // 这个方法是自动生成的，无需手动声明

  // === 自定义工厂方法 - 方便创建新的会话并生成 SID ===

  /// 创建一个新的游戏会话实例，自动生成 SID
  factory GameSession.newSession({
    required String templateId,
    required List<PlayerScore> scores,
    required DateTime startTime,
    DateTime? endTime,
    bool isCompleted = false,
  }) =>
      GameSession(
        sid: const Uuid().v4(),
        // 在这里生成 Uuid
        templateId: templateId,
        scores: scores,
        startTime: startTime,
        endTime: endTime,
        isCompleted: isCompleted,
      );

  // === 数据库序列化/反序列化方法 (保留原有逻辑，用于数据库交互) ===
  // 这些方法用于将 GameSession 对象的标量字段转换为数据库表的行格式，
  // 以及从数据库表的行格式和单独查询到的 PlayerScore 列表构建 GameSession 对象。

  /// 将 GameSession 的标量字段转换为数据库表 game_sessions 的 Map 格式
  Map<String, dynamic> toDatabaseMap() {
    return {
      'sid': sid,
      'template_id': templateId,
      // 数据库通常存储时间戳
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      // 数据库通常存储整数表示布尔值
      'is_completed': isCompleted ? 1 : 0,
    };
    // 注意：这里不包含 scores 列表，因为 PlayerScore 存储在另一个表中
  }

  /// 从数据库表 game_sessions 的 Map 格式和查询到的 PlayerScore 列表
  /// 组装 GameSession 对象。
  ///
  /// [map] 数据库 game_sessions 表查询到的单行 Map
  ///
  /// [scores] 从 player_scores 表查询并组装好的 PlayerScore 对象列表
  static GameSession fromDatabaseMap(
      Map<String, dynamic> map, List<PlayerScore> scores) {
    try {
      // 确保 map 中包含所有必需的 key 且类型正确
      final sessionSid = map['sid'] as String?;
      final templateId = map['template_id'] as String?;
      final startTimeMillis = map['start_time'];
      final endTimeMillis = map['end_time'];
      final isCompletedInt = map['is_completed'];

      if (sessionSid == null ||
          templateId == null ||
          startTimeMillis == null ||
          isCompletedInt == null) {
        // 数据不完整，抛出异常或返回 null
        throw FormatException("数据库 map 缺少 GameSession 必需字段");
      }

      final startTime = DateTime.fromMillisecondsSinceEpoch(
          startTimeMillis is int
              ? startTimeMillis
              : int.parse(startTimeMillis.toString())); // 更安全的类型转换

      final endTime = endTimeMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(endTimeMillis is int
              ? endTimeMillis
              : int.parse(endTimeMillis.toString())) // 更安全的类型转换
          : null;

      final isCompleted = isCompletedInt == 1;

      return GameSession(
        sid: sessionSid,
        templateId: templateId,
        startTime: startTime,
        endTime: endTime,
        isCompleted: isCompleted,
        scores: scores, // 这里的 scores 是从外部传入的，不是从 map 解析的
      );
    } catch (e) {
      Log.e('解析GameSession失败: $e, 输入数据: $map');
      // 提供更健壮的错误处理或返回一个表示错误的 GameSession 或 null
      // 这里为了兼容性，提供一个带有默认值的 GameSession，但可能会丢失部分数据
      // 更好的做法是抛出异常或返回 null，让调用方处理错误
      // 警告: 这种错误处理方式可能会隐藏问题
      final templateId = map['template_id'] as String? ?? 'error';
      final sid = map['sid'] as String? ?? const Uuid().v4();
      // 尝试从 Map 中恢复 isCompleted 和 endTime
      final isCompleted = (map['is_completed'] as int?) == 1;
      DateTime? endTime;
      try {
        if (map['end_time'] != null) {
          final endTimeMillis = map['end_time'];
          endTime = DateTime.fromMillisecondsSinceEpoch(endTimeMillis is int
              ? endTimeMillis
              : int.parse(endTimeMillis.toString()));
        }
      } catch (e2) {
        Log.e('解析GameSession endTime 失败: $e2');
      }

      return GameSession(
        sid: sid,
        templateId: templateId,
        scores: scores,
        // scores 仍然是外部传入的
        startTime: DateTime.now(),
        // 无法解析开始时间，使用当前时间
        isCompleted: isCompleted,
        endTime: endTime,
      );
    }
  }

// toString() 方法由 freezed 自动生成，无需手动实现
// @override
// String toString() { ... }
}
