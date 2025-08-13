import 'package:counters/common/providers/message_provider.dart';
import 'package:counters/common/utils/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Toast样式的消息显示组件
/// 作为MessageOverlay的备用方案，在特殊场景下使用
class ToastMessage {
  static OverlayEntry? _currentToast;
  static bool _isShowing = false;

  /// 显示Toast消息
  static void show(
    BuildContext context,
    String message, {
    MessageType type = MessageType.info,
    Duration duration = const Duration(seconds: 2),
    bool forceShow = false,
  }) {
    // 如果已经在显示且不是强制显示，则忽略
    if (_isShowing && !forceShow) {
      Log.d('ToastMessage: 已有Toast在显示，忽略新消息');
      return;
    }

    hide(); // 先隐藏当前Toast

    _isShowing = true;
    
    _currentToast = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        type: type,
        onDismiss: hide,
      ),
    );

    try {
      final overlay = Overlay.of(context, rootOverlay: true);
      overlay.insert(_currentToast!);
      
      Log.d('ToastMessage: 显示Toast消息 - $message');

      // 自动隐藏
      Future.delayed(duration, () {
        hide();
      });
    } catch (e) {
      Log.e('ToastMessage: 显示Toast失败 - $e');
      _currentToast = null;
      _isShowing = false;
    }
  }

  /// 隐藏当前Toast
  static void hide() {
    if (_currentToast != null) {
      try {
        _currentToast!.remove();
        Log.d('ToastMessage: 隐藏Toast消息');
      } catch (e) {
        Log.e('ToastMessage: 隐藏Toast失败 - $e');
      }
      _currentToast = null;
    }
    _isShowing = false;
  }

  /// 显示成功消息
  static void showSuccess(BuildContext context, String message) {
    show(context, message, type: MessageType.success);
  }

  /// 显示错误消息
  static void showError(BuildContext context, String message) {
    show(context, message, 
         type: MessageType.error, 
         duration: const Duration(seconds: 4));
  }

  /// 显示警告消息
  static void showWarning(BuildContext context, String message) {
    show(context, message, 
         type: MessageType.warning, 
         duration: const Duration(seconds: 3));
  }
}

/// Toast Widget实现
class _ToastWidget extends StatefulWidget {
  final String message;
  final MessageType type;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case MessageType.success:
        return Colors.green.shade600;
      case MessageType.warning:
        return Colors.orange.shade600;
      case MessageType.error:
        return Colors.red.shade600;
      case MessageType.info:
        return Colors.blue.shade600;
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case MessageType.success:
        return Icons.check_circle_outline;
      case MessageType.warning:
        return Icons.warning_amber_outlined;
      case MessageType.error:
        return Icons.error_outline;
      case MessageType.info:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            elevation: 1500, // 极高的elevation
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _getBackgroundColor(),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getIcon(),
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Toast消息管理器的Riverpod扩展
extension ToastMessageExtension on WidgetRef {
  /// 显示Toast消息
  void showToast(BuildContext context, String content, {MessageType type = MessageType.info}) {
    try {
      ToastMessage.show(context, content, type: type);
    } catch (e) {
      Log.e('ToastMessageExtension: 显示Toast失败 - $e');
    }
  }
}

/// 全局Toast管理器
class GlobalToastManager {
  static BuildContext? _context;

  /// 设置全局上下文
  static void setContext(BuildContext context) {
    _context = context;
  }

  /// 显示成功Toast
  static void showSuccess(String content) {
    if (_context != null) {
      ToastMessage.showSuccess(_context!, content);
    } else {
      Log.w('GlobalToastManager: 上下文未设置，无法显示Toast');
    }
  }

  /// 显示错误Toast
  static void showError(String content) {
    if (_context != null) {
      ToastMessage.showError(_context!, content);
    } else {
      Log.w('GlobalToastManager: 上下文未设置，无法显示Toast');
    }
  }

  /// 显示警告Toast
  static void showWarning(String content) {
    if (_context != null) {
      ToastMessage.showWarning(_context!, content);
    } else {
      Log.w('GlobalToastManager: 上下文未设置，无法显示Toast');
    }
  }

  /// 显示信息Toast
  static void showInfo(String content) {
    if (_context != null) {
      ToastMessage.show(_context!, content, type: MessageType.info);
    } else {
      Log.w('GlobalToastManager: 上下文未设置，无法显示Toast');
    }
  }
}
