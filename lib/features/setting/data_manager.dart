import 'dart:io';

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
  static Future<String> getCurrentDataDir() async {
    final prefs = await SharedPreferences.getInstance();
    final defaultDir = await getDefaultBaseDir();
    final baseDir = prefs.getString('data_storage_path') ?? defaultDir;
    return getDataDir(baseDir);
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
  /// todo Windows sp 在 C:\Users\yooyi\AppData\Roaming\com.devyi\counters 需要考虑修改
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
}
