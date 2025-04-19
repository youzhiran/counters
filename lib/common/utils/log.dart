import 'dart:async'; // 导入 async

import 'package:flutter/material.dart' show Color;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

/// 全局日志工具类
class Log {
  // 单例模式
  static final Log _instance = Log._internal();

  factory Log() => _instance;

  Log._internal();

  // 默认日志级别
  static Level _level = Level.debug;

  // 日志实例
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 120,
      colors: true,
      printEmojis: false,
      noBoxingByDefault: true,
    ),
    level: _level,
  );

  // 日志流控制器
  static final _logStreamController = StreamController<String>.broadcast();

  // 公开日志流
  static Stream<String> get logStream => _logStreamController.stream;

  /// 设置日志级别
  static void setLevel(Level level) {
    _level = level;
    // 注意: logger 本身可能需要重新配置或提供方法来更新级别，
    // 这里的 _level 变量可能只影响了 logger 初始化时的级别。
    // 如果 logger 包支持动态修改级别，需要调用相应方法。
  }

  /// 辅助方法：获取调用者的位置信息
  /// 返回格式如 "(package:counters/features/lan/lan_provider.dart:131:9)"
  static String _getCallerLocation() {
    final stackTrace = StackTrace.current;
    final lines = stackTrace.toString().split('\n');

    // 从堆栈的第二帧开始查找 (索引 1)，因为第零帧是 Log 方法本身
    // 找到第一个不包含 log.dart 的帧
    String callerLine = '';
    for (int i = 1; i < lines.length; i++) {
      if (!lines[i].contains('package:counters/common/utils/log.dart')) {
        callerLine = lines[i];
        break;
      }
    }

    // 解析调用行以提取括号内的部分
    // 示例: #1      LanNotifier._handleMessageReceived (package:counters/features/lan/lan_provider.dart:131:9)
    final openParenIndex = callerLine.indexOf('(');
    final closeParenIndex = callerLine.lastIndexOf(')');

    if (openParenIndex != -1 &&
        closeParenIndex != -1 &&
        closeParenIndex > openParenIndex) {
      // +1 和不变量是为了去掉括号本身
      return callerLine.substring(openParenIndex, closeParenIndex + 1);
    } else {
      // 如果解析失败，返回一个通用标记
      return '(未知位置)';
    }
  }

  // --- 修改日志方法以包含位置信息 ---

  /// 调试日志
  static void d(String message) {
    final location = _getCallerLocation();
    final logMessage = '$message $location'; // 将位置信息添加到消息后
    _logger.d(logMessage);
    _logStreamController.add('[D] $logMessage'); // 流信息也包含位置
  }

  /// 信息日志
  static void i(String message) {
    final location = _getCallerLocation();
    final logMessage = '$message $location';
    _logger.i(logMessage);
    _logStreamController.add('[I] $logMessage');
  }

  /// 警告日志
  static void w(String message) {
    final location = _getCallerLocation();
    final logMessage = '$message $location';
    _logger.w(logMessage);
    _logStreamController.add('[W] $logMessage');
  }

  /// 错误日志
  static void e(String message) {
    final location = _getCallerLocation();
    final logMessage = '$message $location';
    _logger.e(logMessage);
    _logStreamController.add('[E] $logMessage');
  }

  /// 严重错误日志
  static void wtf(String message) {
    final location = _getCallerLocation();
    final logMessage = '$message $location';
    _logger.f(logMessage); // logger 的 fatal 对应 wtf
    _logStreamController.add('[WTF] $logMessage');
  }

  // --- 带颜色的日志方法也需要修改 ---

  /// 带颜色的调试日志（仅控制台支持）
  static void debug(String message, {Color? color}) {
    final location = _getCallerLocation();
    final colorStr = color != null ? '颜色: ${_colorToString(color)}' : '';
    // 注意：logger 的 d 方法只接受一个参数，我们将位置信息合并到消息中
    _logger.d('$message $location $colorStr');
    _logStreamController.add('[D] $message $location'); // 流中不带颜色信息
  }

  /// 带颜色的信息日志（仅控制台支持）
  static void info(String message, {Color? color}) {
    final location = _getCallerLocation();
    final colorStr = color != null ? '颜色: ${_colorToString(color)}' : '';
    _logger.i('$message $location $colorStr');
    _logStreamController.add('[I] $message $location');
  }

  /// 带颜色的警告日志（仅控制台支持）
  static void warn(String message, {Color? color}) {
    final location = _getCallerLocation();
    final colorStr = color != null ? '颜色: ${_colorToString(color)}' : '';
    _logger.w('$message $location $colorStr');
    _logStreamController.add('[W] $message $location');
  }

  /// 带颜色的错误日志（仅控制台支持）
  static void error(String message, {Color? color}) {
    final location = _getCallerLocation();
    final colorStr = color != null ? '颜色: ${_colorToString(color)}' : '';
    _logger.e('$message $location $colorStr');
    _logStreamController.add('[E] $message $location');
  }

  /// 将颜色对象转换为字符串表示
  static String _colorToString(Color color) {
    return 'Color(0x${color.value.toRadixString(16).padLeft(8, '0')})';
  }

  // 新增: 关闭流的方法 (在应用退出时调用，可选)
  static void disposeStream() {
    _logStreamController.close();
  }
}

class PLogger extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase<dynamic> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    final stackTrace = StackTrace.current;

    // 先打印基础信息
    Log.d('-------- Provider "${provider.name ?? provider.runtimeType}" 已修改:');
    Log.d('- Previous value: $previousValue');
    Log.d('- New value: $newValue');
    Log.d('- 修改堆栈:');

    // 拆分堆栈逐行打印
    stackTrace.toString().split('\n').forEach(Log.d); // 每行堆栈单独打印
    Log.d('---------------END--------------');
  }
}

// 使用示例:
// Log.d('调试信息');
// Log.debug('调试信息', color: Colors.blue);
// Log.i('信息消息');
// Log.info('信息消息', color: Colors.green);
// Log.w('警告信息');
// Log.warn('警告信息', color: Colors.yellow);
// Log.e('错误信息');
// Log.error('错误信息', color: Colors.red);
//
// 设置日志级别:
// Log.setLevel(Level.warning); // 只显示警告及以上级别的日志
