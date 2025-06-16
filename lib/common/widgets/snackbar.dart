import 'package:counters/app/state.dart';
import 'package:counters/common/utils/log.dart';
import 'package:flutter/material.dart';

class AppSnackBar {
  // 使用全局状态中的 key，不再需要自己的 messengerKey
  static GlobalKey<ScaffoldMessengerState> get messengerKey {
    return globalState.scaffoldMessengerKey;
  }

  // 基础通用样式（蓝色）
  static void show(
    String message, {
    BuildContext? context,
    Duration duration = const Duration(seconds: 2),
  }) {
    _showSnackBar(
      context: context,
      content: Text(message),
      duration: duration,
      backgroundColor: Colors.blue,
      behavior: SnackBarBehavior.floating,
    );
    Log.i(message);
  }

  // 警告样式（橙色）
  static void warn(
    String message, {
    BuildContext? context,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnackBar(
      context: context,
      content: Text(message),
      duration: duration,
      backgroundColor: Colors.orange,
    );
    Log.i(message);
  }

  // 错误样式（红色）
  static void error(
    String message, {
    BuildContext? context,
    Duration duration = const Duration(seconds: 5),
  }) {
    _showSnackBar(
      context: context,
      content: Text(message),
      duration: duration,
      backgroundColor: Colors.red,
    );
    Log.e(message);
  }

  // 完全自定义样式
  static void custom({
    required Widget content,
    BuildContext? context,
    Duration duration = const Duration(seconds: 4),
    Color? backgroundColor,
    SnackBarBehavior behavior = SnackBarBehavior.fixed,
  }) {
    _showSnackBar(
      context: context,
      content: content,
      duration: duration,
      backgroundColor: backgroundColor,
      behavior: behavior,
    );
  }

  // 私有基础方法
  static void _showSnackBar({
    BuildContext? context,
    required Widget content,
    Duration duration = const Duration(seconds: 2),
    Color? backgroundColor,
    SnackBarBehavior? behavior,
  }) {
    final SnackBar snackBar = SnackBar(
      content: content,
      duration: duration,
      backgroundColor: backgroundColor ?? Colors.blue,
      behavior: behavior ?? SnackBarBehavior.floating,
    );

    // 优先使用传入的 context，如果没有则使用全局 key
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else if (messengerKey.currentState != null) {
      messengerKey.currentState!.showSnackBar(snackBar);
    }
  }

  // 移除当前显示的 SnackBar
  static void dismiss({BuildContext? context}) {
    if (context != null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    } else if (messengerKey.currentState != null) {
      messengerKey.currentState!.hideCurrentSnackBar();
    }
  }
}

// // 使用示例
// /* 1. 基础蓝色样式 */
// GlobalMsgManager.showMessage('已结束当前游戏计分');
//
// /* 2. 带参数的标准蓝色样式 */
// GlobalMsgManager.showMessage('请填写所有玩家的【第$currentRound轮】后再添加新回合！');
//
// /* 3. 错误红色样式 */
// AppSnackBar.error('打开失败: ${e.toString()}');
//
// /* 4. 完全自定义样式 */
// AppSnackBar.custom(
//   content: Text('请修正输入错误'),
//   duration: Duration(seconds: 1),
//   behavior: SnackBarBehavior.fixed,
// );
