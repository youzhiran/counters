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
      // error 时打印 5 层调用方法名
      lineLength: 120,
      colors: true,
      printEmojis: false,
      noBoxingByDefault: true,
    ),
    level: _level,
  );

  /// 设置日志级别
  static void setLevel(Level level) {
    _level = level;
  }

  /// 调试日志
  static void d(String message) => _logger.d(message);

  /// 信息日志
  static void i(String message) => _logger.i(message);

  /// 警告日志
  static void w(String message) => _logger.w(message);

  /// 错误日志
  static void e(String message) => _logger.e(message);

  /// 严重错误日志
  static void wtf(String message) => _logger.f(message);

  /// 带颜色的调试日志（仅控制台支持）
  static void debug(String message, {Color? color}) {
    final colorStr = color != null ? '颜色: ${_colorToString(color)}' : '';
    _logger.d('$message $colorStr');
  }

  /// 带颜色的信息日志（仅控制台支持）
  static void info(String message, {Color? color}) {
    final colorStr = color != null ? '颜色: ${_colorToString(color)}' : '';
    _logger.i('$message $colorStr');
  }

  /// 带颜色的警告日志（仅控制台支持）
  static void warn(String message, {Color? color}) {
    final colorStr = color != null ? '颜色: ${_colorToString(color)}' : '';
    _logger.w('$message $colorStr');
  }

  /// 带颜色的错误日志（仅控制台支持）
  static void error(String message, {Color? color}) {
    final colorStr = color != null ? '颜色: ${_colorToString(color)}' : '';
    _logger.e('$message $colorStr');
  }

  /// 将颜色对象转换为字符串表示
  static String _colorToString(Color color) {
    return 'Color(0x${color.toARGB32().toRadixString(16).padLeft(8, '0')})';
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
    Log.d('Provider "${provider.name ?? provider.runtimeType}" 已修改:');
    Log.d('- Previous value: $previousValue');
    Log.d('- New value: $newValue');
    Log.d('- 修改堆栈:');

    // 拆分堆栈逐行打印
    stackTrace.toString().split('\n').forEach(Log.d); // 每行堆栈单独打印
    Log.d('-----------------------------');
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
