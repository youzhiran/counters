import 'dart:async';

import 'package:counters/common/services/log_export_service.dart';
import 'package:counters/common/utils/log.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 日志导出状态
class LogExportState {
  final bool isEnabled;
  final bool isListening;
  final bool isExporting;
  final int bufferSize;
  final String? lastExportPath;
  final DateTime? lastExportTime;

  const LogExportState({
    this.isEnabled = false,
    this.isListening = false,
    this.isExporting = false,
    this.bufferSize = 0,
    this.lastExportPath,
    this.lastExportTime,
  });

  LogExportState copyWith({
    bool? isEnabled,
    bool? isListening,
    bool? isExporting,
    int? bufferSize,
    String? lastExportPath,
    DateTime? lastExportTime,
  }) {
    return LogExportState(
      isEnabled: isEnabled ?? this.isEnabled,
      isListening: isListening ?? this.isListening,
      isExporting: isExporting ?? this.isExporting,
      bufferSize: bufferSize ?? this.bufferSize,
      lastExportPath: lastExportPath ?? this.lastExportPath,
      lastExportTime: lastExportTime ?? this.lastExportTime,
    );
  }
}

/// 日志导出Provider
final logExportProvider =
    StateNotifierProvider<LogExportNotifier, LogExportState>((ref) {
  return LogExportNotifier();
});

/// 日志导出状态管理器
class LogExportNotifier extends StateNotifier<LogExportState> {
  static const String _keyEnableLogExport = 'enable_log_export';
  static const String _keyLastExportPath = 'last_export_path';
  static const String _keyLastExportTime = 'last_export_time';

  Timer? _updateTimer;
  final LogExportService _logExportService = LogExportService();

  LogExportNotifier() : super(const LogExportState()) {
    _loadSettings();
    _startUpdateTimer();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool(_keyEnableLogExport) ?? false;
      final lastExportPath = prefs.getString(_keyLastExportPath);
      final lastExportTimeStr = prefs.getString(_keyLastExportTime);

      DateTime? lastExportTime;
      if (lastExportTimeStr != null) {
        try {
          lastExportTime = DateTime.parse(lastExportTimeStr);
        } catch (e) {
          Log.w('解析最后导出时间失败: $e');
        }
      }

      state = state.copyWith(
        isEnabled: isEnabled,
        lastExportPath: lastExportPath,
        lastExportTime: lastExportTime,
      );

      // 如果启用了日志导出，启动监听器
      if (isEnabled) {
        _startLogListener();
      }
    } catch (e) {
      Log.e('加载日志导出设置失败: $e');
    }
  }

  /// 启动更新定时器
  void _startUpdateTimer() {
    _updateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateState();
    });
  }

  /// 更新状态
  void _updateState() {
    final stats = _logExportService.getLogStats();
    state = state.copyWith(
      isListening: stats['isListening'] ?? false,
      isExporting: stats['isExporting'] ?? false,
      bufferSize: stats['totalLogs'] ?? 0,
    );
  }

  /// 启用/禁用日志导出
  Future<void> toggleLogExport(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyEnableLogExport, enabled);

      state = state.copyWith(isEnabled: enabled);

      if (enabled) {
        _startLogListener();
        Log.i('日志导出功能已启用');
      } else {
        _stopLogListener();
        Log.i('日志导出功能已禁用');
      }
    } catch (e) {
      Log.e('切换日志导出状态失败: $e');
    }
  }

  /// 启动日志监听器
  void _startLogListener() {
    _logExportService.startLogListener();
    _updateState();
  }

  /// 停止日志监听器
  void _stopLogListener() {
    _logExportService.stopLogListener();
    _updateState();
  }

  /// 手动导出日志
  Future<void> exportLogs() async {
    if (state.isExporting) {
      Log.w('日志导出正在进行中，请稍后再试');
      return;
    }

    try {
      state = state.copyWith(isExporting: true);

      final exportPath = await _logExportService.exportLogs();

      if (exportPath != null) {
        // 保存导出信息
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyLastExportPath, exportPath);
        await prefs.setString(
            _keyLastExportTime, DateTime.now().toIso8601String());

        state = state.copyWith(
          lastExportPath: exportPath,
          lastExportTime: DateTime.now(),
        );

        Log.i('日志导出成功: $exportPath');
      }
    } catch (e) {
      Log.e('手动导出日志失败: $e');
    } finally {
      _updateState();
    }
  }

  /// 清理日志缓冲区
  void clearLogBuffer() {
    _logExportService.clearLogBuffer();
    _updateState();
    Log.i('日志缓冲区已清理');
  }

  /// 获取日志统计信息
  Map<String, dynamic> getLogStats() {
    return _logExportService.getLogStats();
  }
}
