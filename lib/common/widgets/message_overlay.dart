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
  bool _isHiding = false;

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
      // 如果正在隐藏，等待完成后再显示新消息
      if (_isHiding) {
        Future.delayed(const Duration(milliseconds: 450), () {
          if (mounted) {
            _showMessage(message);
          }
        });
        return;
      }

      _hideMessage(); // 先移除现有的消息

      // 稍微延迟以确保前一个消息完全移除
      Future.delayed(const Duration(milliseconds: 50), () {
        if (!mounted) return;

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

        try {
          // 使用 Overlay 在最顶层显示消息
          final overlay = Overlay.of(context, rootOverlay: true);
          overlay.insert(_overlayEntry!);
          Log.v('MessageOverlay: 成功显示消息 - ${message.content}');
        } catch (e) {
          Log.e('MessageOverlay: 插入Overlay失败 - $e');
          _overlayEntry = null;
        }
      });
    } catch (e, stackTrace) {
      Log.e('MessageOverlay: 显示消息失败 - $e');
      Log.e('StackTrace: $stackTrace');
      _overlayEntry = null;
    }
  }

  void _hideMessage() {
    if (_isHiding || _overlayEntry == null) return;

    try {
      _isHiding = true;
      // 延迟移除，给退出动画时间
      Future.delayed(const Duration(milliseconds: 400), () {
        try {
          _overlayEntry?.remove();
          _overlayEntry = null;
          _isHiding = false;
          Log.v('MessageOverlay: 成功隐藏消息');
        } catch (e) {
          Log.e('MessageOverlay: 延迟隐藏消息失败 - $e');
          _overlayEntry = null;
          _isHiding = false;
        }
      });
    } catch (e) {
      Log.e('MessageOverlay: 隐藏消息失败 - $e');
      _overlayEntry = null;
      _isHiding = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 监听消息状态变化
    ref.listen<MessageState>(messageManagerProvider, (previous, next) {
      Log.v('MessageOverlay: 状态变化 ${previous?.currentMessage?.content} -> ${next.currentMessage?.content}');

      if (next.currentMessage != null) {
        _showMessage(next.currentMessage!);
      } else {
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
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.0, 1.0, curve: _isExiting ? Curves.easeInBack : Curves.easeOutBack),
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.0, 1.0, curve: _isExiting ? Curves.easeIn : Curves.easeOut),
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
    if (_isExiting) return; // 防止重复调用

    setState(() {
      _isExiting = true;
    });

    // 重新创建退出动画
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    // 重置动画控制器并播放退出动画
    _animationController.reset();
    await _animationController.forward();

    if (mounted) {
      widget.onDismiss();
    }
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
class GlobalMsgManager {
  static ProviderContainer? _container;

  /// 设置全局容器
  static void setContainer(ProviderContainer container) {
    _container = container;
  }

  /// 通用消息显示方法
  static void _showMessage(String content, MessageType type, String typeName) {
    try {
      if (_container != null) {
        switch (type) {
          case MessageType.success:
            _container!.read(messageManagerProvider.notifier).showSuccess(content);
            Log.i('GlobalMsgManager: 显示$typeName消息 - $content');
            break;
          case MessageType.error:
            _container!.read(messageManagerProvider.notifier).showError(content);
            Log.e('GlobalMsgManager: 显示$typeName消息 - $content');
            break;
          case MessageType.warning:
            _container!.read(messageManagerProvider.notifier).showWarning(content);
            Log.w('GlobalMsgManager: 显示$typeName消息 - $content');
            break;
          case MessageType.info:
            _container!.read(messageManagerProvider.notifier).showMessage(content, type: type);
            Log.i('GlobalMsgManager: 显示$typeName消息 - $content');
            break;
        }
      } else {
        Log.w('GlobalMsgManager: 容器未设置，无法显示消息');
      }
    } catch (e, stackTrace) {
      Log.e('GlobalMsgManager: 显示消息失败 - $e');
      Log.e('StackTrace: $stackTrace');
    }
  }

  ///
  static void showMessage(String content) {
    _showMessage(content, MessageType.info, '信息');
  }


  /// 显示成功消息
  static void showSuccess(String content) {
    _showMessage(content, MessageType.success, '成功');
  }

  /// 显示错误消息
  static void showError(String content) {
    _showMessage(content, MessageType.error, '错误');
  }

  /// 显示警告消息
  static void showWarn(String content) {
    _showMessage(content, MessageType.warning, '警告');
  }
}

/// 消息管理器的便捷扩展
extension MessageManagerExtension on WidgetRef {
  /// 通用消息显示方法
  void _showMessageWithFallback(String content, MessageType type, String typeName) {
    try {
      read(messageManagerProvider.notifier).showMessage(content, type: type);
      // 根据消息类型使用相应的日志级别
      switch (type) {
        case MessageType.success:
          Log.i('Extension: 显示$typeName消息 - $content');
          break;
        case MessageType.error:
          Log.e('Extension: 显示$typeName消息 - $content');
          break;
        case MessageType.warning:
          Log.w('Extension: 显示$typeName消息 - $content');
          break;
        case MessageType.info:
          Log.i('Extension: 显示$typeName消息 - $content');
          break;
      }
    } catch (e) {
      Log.e('Extension: 显示$typeName消息失败，使用全局方法 - $e');
      // 备用方案：使用全局方法
      switch (type) {
        case MessageType.success:
          GlobalMsgManager.showSuccess(content);
          break;
        case MessageType.error:
          GlobalMsgManager.showError(content);
          break;
        case MessageType.warning:
          GlobalMsgManager.showWarn(content);
          break;
        case MessageType.info:
          GlobalMsgManager.showSuccess(content); // 默认使用成功样式
          break;
      }
    }
  }

  /// 显示消息
  void showMessage(String content, {MessageType type = MessageType.info}) {
    _showMessageWithFallback(content, type, '信息');
  }

  /// 显示成功消息
  void showSuccess(String content) {
    _showMessageWithFallback(content, MessageType.success, '成功');
  }

  /// 显示警告消息
  void showWarning(String content) {
    _showMessageWithFallback(content, MessageType.warning, '警告');
  }

  /// 显示错误消息
  void showError(String content) {
    _showMessageWithFallback(content, MessageType.error, '错误');
  }
}
