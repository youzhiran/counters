// common/utils/error_handler.dart

import 'package:counters/app/state.dart';
import 'package:counters/common/providers/message_provider.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/common/widgets/message_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ErrorHandler {
  static void handle(
    Object error,
    StackTrace? stack, {
    String prefix = '',
  }) {
    if (error is BusinessException) {
      final levelName = error.level.name;
      final detailText = error.detail == null ? '' : '，详情: ${error.detail}';
      final sourcePrefix = prefix.isEmpty ? '' : '$prefix - ';
      Log.v('业务异常($levelName)已捕获: $sourcePrefix${error.message}$detailText');
      return;
    }

    Log.e('$prefix错误: $error');
    if (stack != null) Log.e('Stack: $stack');

    // 使用 addPostFrameCallback 确保 UI 已经完成当前帧的布局和绘制。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 引入一个微小的额外延迟，以确保在 ScaffoldMessengerState 内部
      // 完成 Scaffold 的注册/注销过程，避免在切换时出现空列表。
      // 这是一个对时序竞争的妥协性解决方案。
      Future.delayed(const Duration(milliseconds: 50), () {
        // 尝试 50ms 延迟
        try {
          if (globalState.scaffoldMessengerKey.currentState != null) {
            final message = '$prefix: ${error.toString().split('\n').first}';
            globalState.scaffoldMessengerKey.currentState!.showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: '详情',
                  textColor: Colors.white,
                  onPressed: () {
                    // 在这里使用 currentContext 是安全的，因为 SnackBar 已经显示，
                    // 并且通常在用户点击时上下文是稳定的。
                    if (globalState.navigatorKey.currentContext != null) {
                      globalState.showCommonDialog(
                        child: Builder(
                          builder: (context) => AlertDialog(
                            title: Text('$prefix 详情'),
                            content: SingleChildScrollView(
                              child: SelectableText('$error\n\n${stack ?? ''}'),
                            ),
                            actions: [
                              TextButton(
                                child: const Text('复制'),
                                onPressed: () {
                                  final errorText = '$error\n\n${stack ?? ''}';
                                  Clipboard.setData(
                                      ClipboardData(text: errorText));
                                  globalState.navigatorKey.currentState?.pop();
                                  // 使用全局消息管理器显示成功消息
                                  GlobalMsgManager.showSuccess('已复制到剪贴板');
                                },
                              ),
                              TextButton(
                                child: const Text('关闭'),
                                onPressed: () => globalState
                                    .navigatorKey.currentState
                                    ?.pop(),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            );
          } else {
            Log.w(
                'ErrorHandler: 无法显示SnackBar，globalState.scaffoldMessengerKey.currentState 为空。');
          }
        } catch (eForSnackBar) {
          // 捕获尝试显示 SnackBar 时可能发生的任何二次错误
          Log.e(
              'ErrorHandler: 尝试显示SnackBar时发生二次错误，可能是Scaffold未就绪: $eForSnackBar');
          // 此时，如果 SnackBar 失败，可以考虑一个更简单、不依赖 Scaffold 的错误提示，
          // 例如只将错误信息记录到日志，或者如果应用程序允许，显示一个纯文本对话框。
        }
      });
    });
  }

  ///
  /// 业务错误快速失败：通过 GMM 展示提示后抛出业务异常。
  static Never failBusiness(
    String message, {
    MessageType level = MessageType.error,
    Object? detail,
  }) {
    final displayText = detail == null ? message : '$message：$detail';

    switch (level) {
      case MessageType.success:
        GlobalMsgManager.showSuccess(displayText);
        break;
      case MessageType.warning:
        GlobalMsgManager.showWarn(displayText);
        break;
      case MessageType.info:
        GlobalMsgManager.showMessage(displayText);
        break;
      case MessageType.error:
        GlobalMsgManager.showError(displayText);
        Log.e('业务错误: $displayText');
        break;
    }

    throw BusinessException(
      message: message,
      level: level,
      detail: detail,
    );
  }
}

/// 业务异常类型，确保上层可区分业务异常与系统异常。
class BusinessException implements Exception {
  final String message;
  final MessageType level;
  final Object? detail;

  const BusinessException({
    required this.message,
    this.level = MessageType.error,
    this.detail,
  });

  @override
  String toString() {
    final suffix = detail == null ? '' : '，详情: $detail';
    return 'BusinessException(${level.name}): $message$suffix';
  }
}
