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
  static Logger? _logger;

  // 获取Logger实例，如果未初始化则先初始化
  static Logger get logger {
    if (_logger == null) {
      _initLogger();
    }
    return _logger!;
  }

  // 初始化Logger
  static void _initLogger() {
    _logger = Logger(
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
  }

  // 日志流控制器
  static final _logStreamController = StreamController<String>.broadcast();

  // 公开日志流
  static Stream<String> get logStream => _logStreamController.stream;

  /// 设置日志级别
  static void setLevel(Level level) {
    _level = level;
    // 重新初始化Logger以应用新的级别
    _initLogger();
  }

  /// 辅助方法：获取调用者的位置信息
  /// 返回格式如 "(package:counters/features/lan/lan_provider.dart:131:9)"
  static String _getCallerLocation() {
    // 定义需要从堆栈跟踪中忽略的文件路径
    const List<String> ignoredPaths = [
      'package:counters/common/utils/log.dart',
      'package:counters/common/widgets/message_overlay.dart',
    ];

    final stackTrace = StackTrace.current;
    final lines = stackTrace.toString().split('\n');

    // 从堆栈的第二帧开始查找 (索引 1)，因为第零帧是 Log 方法本身
    // 找到第一个不包含在 ignoredPaths 列表中的帧
    String callerLine = '';
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i];
      if (!ignoredPaths.any((path) => line.contains(path))) {
        callerLine = line;
        break;
      }
    }

    // 如果循环结束后仍然没有找到，可能是因为调用链条比预想的要深
    // 作为备用方案，我们取最后一个非空的行
    if (callerLine.isEmpty) {
      callerLine = lines.lastWhere((line) => line.isNotEmpty, orElse: () => '');
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

  /// 检查当前日志级别是否允许输出指定级别的日志
  static bool _shouldLog(Level level) {
    return level.index >= _level.index;
  }

  /// 通用日志处理方法
  static void _log(Level level, String message, String streamPrefix, {Color? color}) {
    if (!_shouldLog(level)) return;

    final location = _getCallerLocation();
    final colorStr = color != null ? ' 颜色: ${_colorToString(color)}' : '';
    final logMessage = '$message $location$colorStr';

    // 根据级别调用相应的logger方法
    switch (level) {
      case Level.trace:
        logger.t(logMessage);
        break;
      case Level.debug:
        logger.d(logMessage);
        break;
      case Level.info:
        logger.i(logMessage);
        break;
      case Level.warning:
        logger.w(logMessage);
        break;
      case Level.error:
        logger.e(logMessage);
        break;
      case Level.fatal:
        logger.f(logMessage);
        break;
      default:
        logger.d(logMessage);
    }

    // 添加到流（不包含颜色信息）
    _logStreamController.add('[$streamPrefix] $message $location');
  }

  /// Verbose日志（最详细级别）
  static void v(String message) {
    _log(Level.trace, message, 'V'); // 使用trace级别作为verbose
  }

  /// 调试日志
  static void d(String message) {
    _log(Level.debug, message, 'D');
  }

  /// 信息日志
  static void i(String message) {
    _log(Level.info, message, 'I');
  }

  /// 警告日志
  static void w(String message) {
    _log(Level.warning, message, 'W');
  }

  /// 错误日志
  static void e(String message) {
    _log(Level.error, message, 'E');
  }

  /// 严重错误日志
  static void wtf(String message) {
    _log(Level.fatal, message, 'WTF');
  }

  // --- 带颜色的日志方法 ---

  /// 带颜色的Verbose日志（仅控制台支持）
  static void verbose(String message, {Color? color}) {
    _log(Level.trace, message, 'V', color: color); // 使用trace级别作为verbose
  }

  /// 带颜色的调试日志（仅控制台支持）
  static void debug(String message, {Color? color}) {
    _log(Level.debug, message, 'D', color: color);
  }

  /// 带颜色的信息日志（仅控制台支持）
  static void info(String message, {Color? color}) {
    _log(Level.info, message, 'I', color: color);
  }

  /// 带颜色的警告日志（仅控制台支持）
  static void warn(String message, {Color? color}) {
    _log(Level.warning, message, 'W', color: color);
  }

  /// 带颜色的错误日志（仅控制台支持）
  static void error(String message, {Color? color}) {
    _log(Level.error, message, 'E', color: color);
  }

  /// 将颜色对象转换为字符串表示
  static String _colorToString(Color color) {
    return 'Color(0x${color.toARGB32().toRadixString(16).padLeft(8, '0')})';
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
    final providerName = provider.name ?? provider.runtimeType;

    // 使用 Log.logger 实例直接打印，避免通过 Log.d() 等方法触发 _logStreamController
    Log.logger.d('---------------START--------------');
    Log.logger.d('Provider "$providerName" 已修改:');
    Log.logger.d('- Previous value: $previousValue');
    Log.logger.d('- New value: $newValue');
    Log.logger.d('- 修改堆栈:');

    // 拆分堆栈逐行打印
    stackTrace.toString().split('\n').forEach((line) {
      Log.logger.d(line); // 直接使用 logger 实例打印每一行
    });
    Log.logger.d('---------------END--------------');
  }
}

// 使用示例:
// Log.v('详细信息'); // Verbose级别（最详细）
// Log.verbose('详细信息', color: Colors.grey);
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
// Log.setLevel(Level.trace); // 显示所有级别的日志（包括verbose）
// Log.setLevel(Level.debug); // 显示debug及以上级别的日志
// Log.setLevel(Level.warning); // 只显示警告及以上级别的日志
