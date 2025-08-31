import 'package:counters/common/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'message_provider.g.dart';

/// 消息类型枚举
enum MessageType {
  info,
  success,
  warning,
  error,
}

/// 消息状态枚举
enum MessageStatus {
  active, // 活跃显示中
  exiting, // 正在退出（播放退出动画）
  removed, // 已移除
}

/// 消息数据类
class AppMessage {
  final String id; // 添加唯一标识符
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final Duration duration;
  final MessageStatus status; // 添加消息状态

  const AppMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.timestamp,
    this.duration = const Duration(seconds: 4),
    this.status = MessageStatus.active,
  });

  AppMessage copyWith({
    String? id,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    Duration? duration,
    MessageStatus? status,
  }) {
    return AppMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      duration: duration ?? this.duration,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 消息状态
class MessageState {
  final List<AppMessage> messages; // 历史消息记录
  final List<AppMessage> activeMessages; // 当前活跃显示的消息列表
  final int maxActiveMessages; // 最大同时显示的消息数量

  const MessageState({
    this.messages = const [],
    this.activeMessages = const [],
    this.maxActiveMessages = 5, // 默认最多同时显示5个消息
  });

  MessageState copyWith({
    List<AppMessage>? messages,
    List<AppMessage>? activeMessages,
    int? maxActiveMessages,
  }) {
    return MessageState(
      messages: messages ?? this.messages,
      activeMessages: activeMessages ?? this.activeMessages,
      maxActiveMessages: maxActiveMessages ?? this.maxActiveMessages,
    );
  }
}

/// 消息管理 Provider
@Riverpod(keepAlive: true)
class MessageManager extends _$MessageManager {
  @override
  MessageState build() {
    return const MessageState();
  }

  /// 显示消息
  void showMessage(String content,
      {MessageType type = MessageType.info, Duration? duration}) {
    Log.v('MessageManager: 准备显示消息 - $content (类型: $type)');

    final message = AppMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_${content.hashCode}',
      // 生成唯一ID
      content: content,
      type: type,
      timestamp: DateTime.now(),
      duration: duration ?? _getDefaultDuration(type),
    );

    final newMessages = [...state.messages, message];

    // 限制消息历史数量
    if (newMessages.length > 50) {
      newMessages.removeAt(0);
    }

    // 添加到活跃消息列表
    final newActiveMessages = [...state.activeMessages, message];

    // 如果超过最大显示数量，移除最旧的消息
    if (newActiveMessages.length > state.maxActiveMessages) {
      final removedMessage = newActiveMessages.removeAt(0);
      Log.v('MessageManager: 移除最旧消息 - ${removedMessage.content}');
    }

    state = state.copyWith(
      messages: newMessages,
      activeMessages: newActiveMessages,
    );

    Log.v(
        'MessageManager: 添加消息到活跃列表 - ${message.content} (活跃消息数: ${newActiveMessages.length})');

    // 安排自动清除
    _scheduleMessageClear(message);
  }

  /// 安排消息清除
  void _scheduleMessageClear(AppMessage message) {
    Future.delayed(message.duration, () {
      // 先标记消息为正在退出状态，触发退出动画
      _markMessageExiting(message.id);
    });
  }

  /// 标记消息为正在退出状态
  void _markMessageExiting(String messageId) {
    final messageIndex =
        state.activeMessages.indexWhere((msg) => msg.id == messageId);
    if (messageIndex == -1) return;

    final updatedMessages = [...state.activeMessages];
    updatedMessages[messageIndex] =
        updatedMessages[messageIndex].copyWith(status: MessageStatus.exiting);

    state = state.copyWith(activeMessages: updatedMessages);
    // Log.v('MessageManager: 标记消息为退出状态 - ID: $messageId');

    // 延迟移除消息，给退出动画时间
    Future.delayed(const Duration(milliseconds: 400), () {
      removeMessage(messageId);
    });
  }

  /// 移除指定消息
  void removeMessage(String messageId) {
    final newActiveMessages =
        state.activeMessages.where((msg) => msg.id != messageId).toList();

    if (newActiveMessages.length != state.activeMessages.length) {
      state = state.copyWith(activeMessages: newActiveMessages);
      // Log.v('MessageManager: 移除消息 - ID: $messageId (剩余活跃消息: ${newActiveMessages.length})');
    }
  }

  /// 立即触发消息退出（用于手动关闭）
  void dismissMessage(String messageId) {
    _markMessageExiting(messageId);
  }

  /// 显示成功消息
  void showSuccess(String content, {Duration? duration}) {
    showMessage(content, type: MessageType.success, duration: duration);
  }

  /// 显示警告消息
  void showWarning(String content, {Duration? duration}) {
    showMessage(content, type: MessageType.warning, duration: duration);
  }

  /// 显示错误消息
  void showError(String content, {Duration? duration}) {
    showMessage(content,
        type: MessageType.error,
        duration: duration ?? _getDefaultDuration(MessageType.error));
  }

  /// 清除所有活跃消息
  void clearAllActiveMessages() {
    Log.v('MessageManager: 清除所有活跃消息');
    state = state.copyWith(activeMessages: []);
  }

  /// 清除所有消息
  void clearAllMessages() {
    Log.v('MessageManager: 清除所有消息');
    state = const MessageState();
  }

  /// 获取活跃消息数量
  int get activeMessageCount => state.activeMessages.length;

  /// 设置最大同时显示消息数量
  void setMaxActiveMessages(int maxCount) {
    if (maxCount <= 0) return;

    final newActiveMessages = [...state.activeMessages];

    // 如果当前活跃消息超过新的限制，移除最旧的消息
    while (newActiveMessages.length > maxCount) {
      final removedMessage = newActiveMessages.removeAt(0);
      Log.v('MessageManager: 因限制调整移除消息 - ${removedMessage.content}');
    }

    state = state.copyWith(
      maxActiveMessages: maxCount,
      activeMessages: newActiveMessages,
    );
  }

  /// 获取消息类型对应的默认持续时间
  Duration _getDefaultDuration(MessageType type) {
    switch (type) {
      case MessageType.success:
        return const Duration(seconds: 4);
      case MessageType.warning:
        return const Duration(seconds: 5);
      case MessageType.error:
        return const Duration(seconds: 6);
      case MessageType.info:
        return const Duration(seconds: 4);
    }
  }
}
