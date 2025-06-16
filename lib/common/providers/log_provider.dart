import 'dart:async';

import 'package:counters/common/utils/log.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider 定义
final logProvider = StateNotifierProvider<LogNotifier, List<String>>((ref) {
  return LogNotifier();
});

// Verbose级别日志控制Provider
final verboseLogProvider = StateNotifierProvider<VerboseLogNotifier, bool>((ref) {
  return VerboseLogNotifier();
});

// StateNotifier 类
class LogNotifier extends StateNotifier<List<String>> {
  StreamSubscription? _logSubscription;
  final int maxLogCount = 200; // 限制最大日志条数

  LogNotifier() : super([]) {
    // 开始监听全局日志流
    _logSubscription = Log.logStream.listen((logMessage) {
      if (mounted) {
        final currentLogs = List<String>.from(state);
        currentLogs.insert(0, logMessage); // 新日志添加到顶部

        // 如果超过最大条数，移除最旧的日志
        if (currentLogs.length > maxLogCount) {
          currentLogs.removeLast();
        }
        state = currentLogs;
      }
    });
    // 添加一条初始日志，表明监听器已启动
    state = ['[SYSTEM] 日志监听器已启动'];
  }

  // 清理日志列表
  void clearLogs() {
    state = [];
  }

  @override
  void dispose() {
    // 取消监听
    _logSubscription?.cancel();
    super.dispose();
  }
}

// Verbose级别日志控制StateNotifier
class VerboseLogNotifier extends StateNotifier<bool> {
  static const String _keyEnableVerboseLog = 'enable_verbose_log';

  VerboseLogNotifier() : super(false) {
    _loadVerboseLogSetting();
  }

  // 加载Verbose日志设置
  Future<void> _loadVerboseLogSetting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool(_keyEnableVerboseLog) ?? false;
      state = isEnabled;
      _updateLogLevel(isEnabled);
    } catch (e) {
      Log.e('加载Verbose日志设置失败: $e');
    }
  }

  // 保存Verbose日志设置
  Future<void> setVerboseLogEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyEnableVerboseLog, enabled);
      state = enabled;
      _updateLogLevel(enabled);
      Log.i('Verbose日志设置已${enabled ? '启用' : '禁用'}');
    } catch (e) {
      Log.e('保存Verbose日志设置失败: $e');
    }
  }

  // 更新日志级别
  void _updateLogLevel(bool enableVerbose) {
    if (enableVerbose) {
      Log.setLevel(Level.trace); // 启用verbose时使用trace级别
    } else {
      Log.setLevel(Level.debug); // 禁用verbose时使用debug级别
    }
  }
}