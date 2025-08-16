import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/common/widgets/message_overlay.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// 日志导出服务
class LogExportService {
  static final LogExportService _instance = LogExportService._internal();

  factory LogExportService() => _instance;

  LogExportService._internal();

  StreamSubscription<String>? _logSubscription;
  final List<String> _logBuffer = [];
  final int _maxBufferSize = 10000; // 最大缓存日志条数
  bool _isExporting = false;
  Timer? _exportTimer;

  /// 是否正在导出日志
  bool get isExporting => _isExporting;

  /// 启动日志监听器
  void startLogListener() {
    if (_logSubscription != null) return;

    Log.i('启动日志导出监听器');
    _logSubscription = Log.logStream.listen((logMessage) {
      _addLogToBuffer(logMessage);
    });

    // 设置定时导出（每小时导出一次）
    _exportTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      if (_isExporting) return;
      _exportLogs();
    });
  }

  /// 停止日志监听器
  void stopLogListener() {
    Log.i('停止日志导出监听器');
    _logSubscription?.cancel();
    _logSubscription = null;
    _exportTimer?.cancel();
    _exportTimer = null;
  }

  /// 添加日志到缓冲区
  void _addLogToBuffer(String logMessage) {
    _logBuffer.add(logMessage);

    // 如果超过最大缓存大小，移除最旧的日志
    if (_logBuffer.length > _maxBufferSize) {
      _logBuffer.removeAt(0);
    }
  }

  /// 手动导出日志
  Future<String?> exportLogs() async {
    if (_isExporting) {
      Log.w('日志导出正在进行中，请稍后再试');
      return null;
    }

    return await _exportLogs();
  }

  /// 执行日志导出
  Future<String?> _exportLogs() async {
    if (_logBuffer.isEmpty) {
      GlobalMsgManager.showWarn('没有日志可导出');
      return null;
    }

    _isExporting = true;

    try {
      // 获取应用文档目录
      final appDocDir = await getApplicationDocumentsDirectory();
      final logsDir = Directory(path.join(appDocDir.path, 'logs'));

      // 创建日志目录
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }

      // 生成日志文件名
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final logFileName = 'app_logs_$timestamp.txt';
      final logFilePath = path.join(logsDir.path, logFileName);

      // 写入日志文件
      final logFile = File(logFilePath);
      final logContent = _formatLogsForExport();
      await logFile.writeAsString(logContent, encoding: utf8);

      // 创建压缩包
      final zipFileName = 'app_logs_$timestamp.zip';
      final zipFilePath = path.join(logsDir.path, zipFileName);

      await _createZipArchive(logFilePath, zipFilePath);

      // 删除临时文本文件
      await logFile.delete();

      GlobalMsgManager.showSuccess('日志导出完成: $zipFilePath');
      _isExporting = false;

      return zipFilePath;
    } catch (e, stackTrace) {
      Log.e('日志导出失败: $e，stackTrace：$stackTrace');
      GlobalMsgManager.showSuccess('日志导出失败: $e');
      _isExporting = false;
      return null;
    }
  }

  /// 格式化日志用于导出
  String _formatLogsForExport() {
    final buffer = StringBuffer();

    // 添加导出信息头
    buffer.writeln('=== 应用日志导出 ===');
    buffer.writeln('导出时间: ${DateTime.now().toIso8601String()}');
    buffer.writeln('平台: ${Platform.operatingSystem}');
    buffer.writeln('日志条数: ${_logBuffer.length}');
    buffer.writeln('==================');
    buffer.writeln();

    // 添加所有日志
    for (final log in _logBuffer) {
      buffer.writeln(log);
    }

    return buffer.toString();
  }

  /// 创建ZIP压缩包
  Future<void> _createZipArchive(
      String sourceFilePath, String zipFilePath) async {
    final sourceFile = File(sourceFilePath);
    final sourceBytes = await sourceFile.readAsBytes();

    final archive = Archive();
    final archiveFile = ArchiveFile(
      path.basename(sourceFilePath),
      sourceBytes.length,
      sourceBytes,
    );

    archive.addFile(archiveFile);

    final zipData = ZipEncoder().encode(archive);
    final zipFile = File(zipFilePath);
    await zipFile.writeAsBytes(zipData);
  }

  /// 获取日志统计信息
  Map<String, dynamic> getLogStats() {
    return {
      'totalLogs': _logBuffer.length,
      'isExporting': _isExporting,
      'isListening': _logSubscription != null,
      'lastExportTime': _getLastExportTime(),
    };
  }

  /// 获取最后导出时间
  String? _getLastExportTime() {
    // 这里可以从SharedPreferences读取最后导出时间
    // 暂时返回null
    return null;
  }

  /// 清理日志缓冲区
  void clearLogBuffer() {
    _logBuffer.clear();
    Log.i('日志缓冲区已清理');
  }

  /// 获取当前缓冲区大小
  int get bufferSize => _logBuffer.length;
}
