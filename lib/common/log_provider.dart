import 'dart:async';

import 'package:counters/common/utils/log.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider 定义
final logProvider = StateNotifierProvider<LogNotifier, List<String>>((ref) {
  return LogNotifier();
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