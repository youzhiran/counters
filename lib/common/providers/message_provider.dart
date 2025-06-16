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

/// 消息数据类
class AppMessage {
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final Duration duration;

  const AppMessage({
    required this.content,
    required this.type,
    required this.timestamp,
    this.duration = const Duration(seconds: 4),
  });

  AppMessage copyWith({
    String? content,
    MessageType? type,
    DateTime? timestamp,
    Duration? duration,
  }) {
    return AppMessage(
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      duration: duration ?? this.duration,
    );
  }
}

/// 消息状态
class MessageState {
  final List<AppMessage> messages;
  final AppMessage? currentMessage;

  const MessageState({
    this.messages = const [],
    this.currentMessage,
  });

  MessageState copyWith({
    List<AppMessage>? messages,
    AppMessage? currentMessage,
  }) {
    return MessageState(
      messages: messages ?? this.messages,
      currentMessage: currentMessage,
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
  void showMessage(String content, {MessageType type = MessageType.info, Duration? duration}) {
    Log.v('MessageManager: 准备显示消息 - $content (类型: $type)');

    final message = AppMessage(
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

    state = state.copyWith(
      messages: newMessages,
      currentMessage: message,
    );

    Log.v('MessageManager: 消息状态已更新，当前消息: ${state.currentMessage?.content}');

    // 自动清除当前消息
    Future.delayed(message.duration, () {
      if (state.currentMessage == message) {
        Log.v('MessageManager: 自动清除消息 - ${message.content}');
        state = state.copyWith(currentMessage: null);
      }
    });
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
    showMessage(content, type: MessageType.error, duration: duration ?? _getDefaultDuration(MessageType.error));
  }

  /// 清除当前消息
  void clearCurrentMessage() {
    state = state.copyWith(currentMessage: null);
  }

  /// 清除所有消息
  void clearAllMessages() {
    state = const MessageState();
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
