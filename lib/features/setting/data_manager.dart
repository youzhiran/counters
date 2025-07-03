import 'dart:io';

import 'package:counters/common/utils/error_handler.dart';
import 'package:counters/common/utils/log.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataManager {
  static bool _isMigrating = false; // 添加迁移状态锁

  /// 检查是否有迁移任务正在进行
  static bool isMigrating() => _isMigrating;

  /// 获取应用程序所在目录
  static String getAppDir() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return Platform.resolvedExecutable.substring(
        0,
        Platform.resolvedExecutable.lastIndexOf(Platform.pathSeparator),
      );
    }
    return '';
  }

  /// 获取默认数据存储目录的父目录
  static Future<String> getDefaultBaseDir() async {
    return (await getApplicationDocumentsDirectory()).path;
  }

  /// 获取当前实际的数据存储目录
  /// 仅在Windows平台使用SharedPreferences中的设置，其他平台使用默认目录
  static Future<String> getCurrentDataDir() async {
    final defaultDir = await getDefaultBaseDir();

    // 仅在Windows平台使用SharedPreferences设置
    if (Platform.isWindows) {
      final prefs = await SharedPreferences.getInstance();
      final baseDir = prefs.getString('data_storage_path') ?? defaultDir;
      return getDataDir(baseDir);
    } else {
      // 非Windows平台使用默认目录，并清理SharedPreferences中的相关设置
      await _cleanupNonWindowsSettings();
      return getDataDir(defaultDir);
    }
  }

  /// 根据基础目录获取实际数据存储目录
  static String getDataDir(String baseDir) {
    return '$baseDir${Platform.pathSeparator}counters-data';
  }

  /// 确保数据目录存在
  static Future<void> ensureDataDirExists(String baseDir) async {
    final directory = Directory(getDataDir(baseDir));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  /// 迁移程序数据
  /// Windows sp 在 C:\Users\yooyi\AppData\Roaming\com.devyi\counters 需要考虑修改
  static Future<bool> migrateData(
    String oldPath,
    String newPath, {
    void Function(String message, double progress)? onProgress,
  }) async {
    Log.i('开始迁移，当前状态: $_isMigrating');

    if (_isMigrating) {
      Log.e('迁移已在进行中，请勿重复调用');
      onProgress?.call('迁移已在进行中', 1.0);
      return false;
    }

    _isMigrating = true;

    try {
      // 基本检查
      if (oldPath == newPath) {
        onProgress?.call('源目录与目标目录相同，无需迁移', 1.0);
        return false;
      }

      if (newPath.startsWith(oldPath + Platform.pathSeparator)) {
        onProgress?.call('目标目录是源目录的子目录，无法迁移', 1.0);
        return false;
      }

      final sourceDir = Directory(oldPath);
      final targetDir = Directory(newPath);

      if (!await sourceDir.exists()) {
        onProgress?.call('源目录不存在', 1.0);
        return false;
      }

      // 获取文件列表
      final entities = await sourceDir.list(recursive: true).toList();
      final files = <File>[];

      for (final entity in entities) {
        if (entity is File &&
            (await entity.stat()).type == FileSystemEntityType.file) {
          files.add(entity);
        }
      }

      if (files.isEmpty) {
        onProgress?.call('源目录为空', 1.0);
        return false;
      }

      // 确保目标目录存在
      await targetDir.create(recursive: true);

      // 复制文件
      for (var i = 0; i < files.length; i++) {
        final file = files[i];
        final relativePath = file.path.substring(oldPath.length);
        final newFilePath = targetDir.path + relativePath;
        final newFile = File(newFilePath);

        await newFile.parent.create(recursive: true);
        await file.copy(newFilePath);

        onProgress?.call(
          '正在迁移: ${relativePath.substring(1)}',
          (i + 1) / files.length,
        );
      }

      onProgress?.call('迁移完成', 1.0);
      return true;
    } catch (e) {
      Log.e('迁移失败: $e');
      onProgress?.call('迁移失败: $e', 1.0);
      return false;
    } finally {
      _isMigrating = false;
    }
  }

  /// 检查目录是否可写
  static Future<bool> isDirWritable(String path) async {
    try {
      final testFile = File('$path${Platform.pathSeparator}test.tmp');
      await testFile.writeAsString('test');
      await testFile.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 清理非Windows平台的数据目录相关SharedPreferences设置
  /// 这确保非Windows平台不会受到SharedPreferences中数据目录设置的影响
  static Future<void> _cleanupNonWindowsSettings() async {
    if (Platform.isWindows) return; // Windows平台不需要清理

    try {
      final prefs = await SharedPreferences.getInstance();
      bool hasChanges = false;

      // 清理数据存储路径设置
      if (prefs.containsKey('data_storage_path')) {
        await prefs.remove('data_storage_path');
        hasChanges = true;
        Log.i('DataManager: 已清理非Windows平台的data_storage_path设置');
      }

      // 清理自定义路径标记
      if (prefs.containsKey('is_custom_path')) {
        await prefs.remove('is_custom_path');
        hasChanges = true;
        Log.i('DataManager: 已清理非Windows平台的is_custom_path设置');
      }

      if (hasChanges) {
        Log.i('DataManager: 非Windows平台数据目录设置清理完成，将使用默认目录');
      }
    } catch (e, stackTrace) {
      // 使用ErrorHandler处理错误，但不抛出异常，避免影响正常功能
      ErrorHandler.handle(e, stackTrace, prefix: '清理非Windows平台数据目录设置失败');
    }
  }

  /// 初始化数据管理器
  /// 在应用启动时调用，确保非Windows平台使用正确的数据目录设置
  static Future<void> initialize() async {
    try {
      Log.i('DataManager: 开始初始化数据管理器');

      // 非Windows平台清理SharedPreferences中的数据目录设置
      if (!Platform.isWindows) {
        await _cleanupNonWindowsSettings();
      }

      // 确保数据目录存在
      final currentDataDir = await getCurrentDataDir();
      final baseDir = currentDataDir.substring(0,
          currentDataDir.lastIndexOf('${Platform.pathSeparator}counters-data'));
      await ensureDataDirExists(baseDir);

      Log.i('DataManager: 数据管理器初始化完成，当前数据目录: $currentDataDir');
    } catch (e, stackTrace) {
      ErrorHandler.handle(e, stackTrace, prefix: '数据管理器初始化失败');
      rethrow;
    }
  }
}
