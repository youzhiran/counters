import 'package:counters/common/providers/message_provider.dart';
import 'package:counters/common/utils/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 消息覆盖层组件
/// 用于在应用顶层显示消息，不会被 Bottom Sheet 等组件遮挡
class MessageOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const MessageOverlay({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<MessageOverlay> createState() => _MessageOverlayState();
}

class _MessageOverlayState extends ConsumerState<MessageOverlay> {
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _hideMessage();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 确保在依赖变化时重新建立监听
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowCurrentMessage();
    });
  }

  void _checkAndShowCurrentMessage() {
    // 检查是否有当前消息需要显示
    final currentMessage = ref.read(messageManagerProvider).currentMessage;
    if (currentMessage != null && _overlayEntry == null) {
      _showMessage(currentMessage);
    }
  }

  void _showMessage(AppMessage message) {
    try {
      _hideMessage(); // 先移除现有的消息

      _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: SafeArea(
              child: _MessageCard(
                message: message,
                onDismiss: () {
                  ref.read(messageManagerProvider.notifier).clearCurrentMessage();
                },
              ),
            ),
          ),
        ),
      );

      // 使用 Overlay 在最顶层显示消息
      final overlay = Overlay.of(context, rootOverlay: true);
      overlay.insert(_overlayEntry!);

      Log.v('MessageOverlay: 成功显示消息 - ${message.content}');
    } catch (e, stackTrace) {
      Log.e('MessageOverlay: 显示消息失败 - $e');
      Log.e('StackTrace: $stackTrace');
      _overlayEntry = null;
    }
  }

  void _hideMessage() {
    try {
      _overlayEntry?.remove();
      _overlayEntry = null;
      Log.v('MessageOverlay: 成功隐藏消息');
    } catch (e) {
      Log.e('MessageOverlay: 隐藏消息失败 - $e');
      _overlayEntry = null; // 确保清理状态
    }
  }

  @override
  Widget build(BuildContext context) {
    // 监听消息状态变化
    ref.listen<MessageState>(messageManagerProvider, (previous, next) {
      Log.v('MessageOverlay: 监听到消息状态变化');
      Log.v('Previous message: ${previous?.currentMessage?.content}');
      Log.v('Next message: ${next.currentMessage?.content}');

      if (next.currentMessage != null) {
        Log.v('MessageOverlay: 准备显示新消息');
        _showMessage(next.currentMessage!);
      } else {
        Log.v('MessageOverlay: 准备隐藏消息');
        _hideMessage();
      }
    });

    return widget.child;
  }
}

/// 消息卡片组件
class _MessageCard extends StatefulWidget {
  final AppMessage message;
  final VoidCallback onDismiss;

  const _MessageCard({
    required this.message,
    required this.onDismiss,
  });

  @override
  State<_MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<_MessageCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getBackgroundColor(MessageType type) {
    switch (type) {
      case MessageType.success:
        return Colors.green;
      case MessageType.warning:
        return Colors.orange;
      case MessageType.error:
        return Colors.red;
      case MessageType.info:
        return Colors.blue;
    }
  }

  IconData _getIcon(MessageType type) {
    switch (type) {
      case MessageType.success:
        return Icons.check_circle;
      case MessageType.warning:
        return Icons.warning;
      case MessageType.error:
        return Icons.error;
      case MessageType.info:
        return Icons.info;
    }
  }

  void _dismiss() async {
    await _animationController.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getBackgroundColor(widget.message.type),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _getIcon(widget.message.type),
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message.content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _dismiss,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 全局消息显示工具类
class GlobalMessageManager {
  static ProviderContainer? _container;

  /// 设置全局容器
  static void setContainer(ProviderContainer container) {
    _container = container;
  }

  /// 显示成功消息（全局方法，不依赖于特定的 WidgetRef）
  static void showSuccess(String content) {
    try {
      Log.v('GlobalMessageManager: 尝试显示成功消息 - $content');
      if (_container != null) {
        _container!.read(messageManagerProvider.notifier).showSuccess(content);
        Log.v('GlobalMessageManager: 成功消息显示完成');
      } else {
        Log.v('GlobalMessageManager: 容器未设置，无法显示消息');
      }
    } catch (e, stackTrace) {
      Log.v('GlobalMessageManager: 显示消息失败 - $e');
      Log.v('StackTrace: $stackTrace');
    }
  }

  /// 显示错误消息
  static void showError(String content) {
    try {
      Log.v('GlobalMessageManager: 尝试显示错误消息 - $content');
      if (_container != null) {
        _container!.read(messageManagerProvider.notifier).showError(content);
        Log.v('GlobalMessageManager: 错误消息显示完成');
      } else {
        Log.v('GlobalMessageManager: 容器未设置，无法显示消息');
      }
    } catch (e, stackTrace) {
      Log.v('GlobalMessageManager: 显示消息失败 - $e');
      Log.v('StackTrace: $stackTrace');
    }
  }

  /// 显示警告消息
  static void showWarning(String content) {
    try {
      Log.v('GlobalMessageManager: 尝试显示警告消息 - $content');
      if (_container != null) {
        _container!.read(messageManagerProvider.notifier).showWarning(content);
        Log.v('GlobalMessageManager: 警告消息显示完成');
      } else {
        Log.v('GlobalMessageManager: 容器未设置，无法显示消息');
      }
    } catch (e, stackTrace) {
      Log.v('GlobalMessageManager: 显示消息失败 - $e');
      Log.v('StackTrace: $stackTrace');
    }
  }
}

/// 消息管理器的便捷扩展
extension MessageManagerExtension on WidgetRef {
  /// 显示消息
  void showMessage(String content, {MessageType type = MessageType.info}) {
    Log.v('MessageManagerExtension: 显示消息 - $content (类型: $type)');
    try {
      read(messageManagerProvider.notifier).showMessage(content, type: type);
    } catch (e) {
      Log.e('MessageManagerExtension: 显示消息失败，尝试使用全局方法 - $e');
      // 备用方案：使用全局方法
      switch (type) {
        case MessageType.success:
          GlobalMessageManager.showSuccess(content);
          break;
        case MessageType.error:
          GlobalMessageManager.showError(content);
          break;
        case MessageType.warning:
          GlobalMessageManager.showWarning(content);
          break;
        case MessageType.info:
          GlobalMessageManager.showSuccess(content); // 默认使用成功样式
          break;
      }
    }
  }

  /// 显示成功消息
  void showSuccess(String content) {
    Log.i('MessageManagerExtension: 显示成功消息 - $content');
    try {
      read(messageManagerProvider.notifier).showSuccess(content);
    } catch (e) {
      Log.e('MessageManagerExtension: 显示成功消息失败，尝试使用全局方法 - $e');
      GlobalMessageManager.showSuccess(content);
    }
  }

  /// 显示警告消息
  void showWarning(String content) {
    Log.w('MessageManagerExtension: 显示警告消息 - $content');
    try {
      read(messageManagerProvider.notifier).showWarning(content);
    } catch (e) {
      Log.e('MessageManagerExtension: 显示警告消息失败，尝试使用全局方法 - $e');
      GlobalMessageManager.showWarning(content);
    }
  }

  /// 显示错误消息
  void showError(String content) {
    Log.e('MessageManagerExtension: 显示错误消息 - $content');
    try {
      read(messageManagerProvider.notifier).showError(content);
    } catch (e) {
      Log.e('MessageManagerExtension: 显示错误消息失败，尝试使用全局方法 - $e');
      GlobalMessageManager.showError(content);
    }
  }
}
