import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/common/utils/platform_utils.dart';
import 'package:counters/common/widgets/export_config_dialog.dart';
import 'package:counters/common/widgets/message_overlay.dart';
import 'package:file_picker/file_picker.dart';
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
      _exportLogs(); // 自动导出时不带UI交互
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

  /// 手动导出日志 (UI调用此方法)
  Future<String?> exportLogs() async {
    if (_isExporting) {
      Log.w('日志导出正在进行中，请稍后再试');
      return null;
    }
    // 调用内部方法，并传入 true 表示这是一个需要UI交互的手动导出
    return await _exportLogs(isManualExport: true);
  }

  /// 执行日志导出 (内部实现，包含平台逻辑)
  Future<String?> _exportLogs({bool isManualExport = false}) async {
    if (_logBuffer.isEmpty) {
      // 只有手动导出时才提示用户
      if (isManualExport) {
        GlobalMsgManager.showWarn('没有日志可导出');
      }
      return null;
    }

    _isExporting = true;
    File? tempZipFile; // 用于鸿蒙平台的临时文件
    File? tempLogFile; // 用于所有平台的临时日志文件

    try {
      // 步骤 1: 准备日志内容和ZIP数据 (所有平台通用)
      final logContent = _formatLogsForExport();
      final tempDir = await getApplicationDocumentsDirectory();

      // a. 创建一个临时的 txt 日志文件
      final tempLogFilePath = path.join(tempDir.path,
          'temp_log_${DateTime.now().millisecondsSinceEpoch}.txt');
      tempLogFile = File(tempLogFilePath);
      await tempLogFile.writeAsString(logContent, encoding: utf8);

      // b. 将 txt 文件压缩成 ZIP 数据
      final sourceBytes = await tempLogFile.readAsBytes();
      final archive = Archive();
      archive.addFile(
          ArchiveFile('app_logs.txt', sourceBytes.length, sourceBytes));
      final zipData = ZipEncoder().encode(archive);

      // 生成默认文件名
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final defaultFileName = 'app_logs_$timestamp.zip';

      // 步骤 2: 根据平台执行不同的保存策略
      if (PlatformUtils.isOhosPlatformSync()) {
        // --- 鸿蒙平台专属逻辑 ---
        // a. 将 ZIP 数据写入内部临时文件
        final tempZipFilePath = path.join(tempDir.path, defaultFileName);
        tempZipFile = File(tempZipFilePath);
        await tempZipFile.writeAsBytes(zipData, flush: true);

        // b. 调用 file picker 将临时文件“导出”
        final String? resultPath = await FilePicker.platform.saveFile(
          dialogTitle: '选择保存位置',
          fileName: defaultFileName,
          initialDirectory: tempZipFilePath,
          type: FileType.custom,
          allowedExtensions: ['zip'],
        );

        if (resultPath != null) {
          GlobalMsgManager.showSuccess('日志导出完成: $resultPath');
          return resultPath;
        } else {
          return null; // 用户取消
        }
      } else {
        // --- 其他平台逻辑 ---
        String? saveDir, fileName;

        if (isManualExport) {
          // a. 如果是手动导出，弹窗让用户选择保存位置
          final exportConfig = await GlobalExportConfigDialog.show(
            title: '导出日志',
            defaultFileName: defaultFileName,
            allowedExtensions: ['zip'],
            dialogTitle: '选择日志文件保存位置',
          );

          if (exportConfig == null) return null; // 用户取消
          saveDir = exportConfig['directory'];
          fileName = exportConfig['fileName'];
        } else {
          // b. 如果是自动导出，保存到应用内部的默认位置
          saveDir = path.join(tempDir.path, 'logs');
          fileName = defaultFileName;
          await Directory(saveDir).create(recursive: true);
        }

        // c. 写入用户选择或默认的文件路径
        final finalFileName =
            fileName!.endsWith('.zip') ? fileName : '$fileName.zip';
        final zipFilePath = path.join(saveDir!, finalFileName);
        final zipFile = File(zipFilePath);
        await zipFile.writeAsBytes(zipData);

        if (isManualExport) {
          GlobalMsgManager.showSuccess('日志导出完成: $zipFilePath');
        }
        return zipFilePath;
      }
    } catch (e, stackTrace) {
      Log.e('日志导出失败: $e，stackTrace：$stackTrace');
      if (isManualExport) {
        GlobalMsgManager.showError('日志导出失败: $e');
      }
      return null;
    } finally {
      _isExporting = false;
      // 清理所有临时文件
      try {
        if (await tempZipFile?.exists() ?? false) {
          await tempZipFile?.delete();
        }
        if (await tempLogFile?.exists() ?? false) {
          await tempLogFile?.delete();
        }
      } catch (e) {
        Log.w('删除临时日志文件失败: $e');
      }
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
