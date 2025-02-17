import 'package:flutter/material.dart';

class AppSnackBar {
  // 基础通用样式（蓝色浮动样式）
  static void show(BuildContext context, String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showSnackBar(
      context,
      content: Text(message),
      duration: duration,
      backgroundColor: Colors.blue,
      behavior: SnackBarBehavior.floating,
    );
  }

  // 错误样式（红色固定样式）
  static void error(BuildContext context, String message) {
    _showSnackBar(
      context,
      content: Text(message),
      backgroundColor: Colors.red,
    );
  }

  // 完全自定义样式
  static void custom(BuildContext context, {
    required Widget content,
    Duration duration = const Duration(seconds: 4),
    Color? backgroundColor,
    SnackBarBehavior behavior = SnackBarBehavior.fixed,
  }) {
    _showSnackBar(
      context,
      content: content,
      duration: duration,
      backgroundColor: backgroundColor,
      behavior: behavior,
    );
  }

  // 私有基础方法
  static void _showSnackBar(
      BuildContext context, {
        required Widget content,
        Duration duration = const Duration(seconds: 2),
        Color? backgroundColor,
        SnackBarBehavior? behavior,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: content,
        duration: duration,
        backgroundColor: backgroundColor ?? Colors.blue,
        behavior: behavior ?? SnackBarBehavior.floating,
      ),
    );
  }
}

// // 使用示例
// /* 1. 基础蓝色样式 */
// AppSnackBar.show(context, '已结束当前游戏计分');
//
// /* 2. 带参数的标准蓝色样式 */
// AppSnackBar.show(context, '请填写所有玩家的【第$currentRound轮】后再添加新回合！');
//
// /* 3. 错误红色样式 */
// AppSnackBar.error(context, '打开失败: ${e.toString()}');
//
// /* 4. 完全自定义样式 */
// AppSnackBar.custom(
// context,
// content: Text('请修正输入错误'),
// duration: Duration(seconds: 1),
// behavior: SnackBarBehavior.fixed,
// );