import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:counters/common/db/db_helper.dart';
import 'package:counters/common/utils/error_handler.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/common/widgets/message_overlay.dart';
import 'package:counters/features/backup/backup_models.dart';
import 'package:counters/features/backup/backup_service.dart';
import 'package:counters/features/setting/data_manager.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

/// 导入事务类，提供原子性操作和回滚机制
class ImportTransaction {
  final ImportOptions _options;
  final String _transactionId;
  final DateTime _startTime;

  // 备份数据
  String? _currentDataBackupPath;
  Map<String, dynamic>? _originalPreferences;
  Map<String, File>? _originalDatabaseFiles;

  // 事务状态
  bool _isCommitted = false;
  bool _isRolledBack = false;

  ImportTransaction._(this._options, this._transactionId, this._startTime);

  /// 开始导入事务
  static Future<ImportTransaction> begin(ImportOptions options) async {
    final transactionId = 'import_${DateTime.now().millisecondsSinceEpoch}';
    final startTime = DateTime.now();

    Log.i('ImportTransaction: 开始导入事务 [$transactionId]');

    final transaction = ImportTransaction._(options, transactionId, startTime);
    await transaction._initialize();

    return transaction;
  }

  /// 初始化事务
  Future<void> _initialize() async {
    Log.v('ImportTransaction: 初始化事务 [$_transactionId]');

    // 备份当前SharedPreferences
    if (_options.importSharedPreferences) {
      await _backupCurrentPreferences();
    }

    // 备份当前数据库文件
    if (_options.importDatabases) {
      await _backupCurrentDatabases();
    }
  }

  /// 备份当前SharedPreferences
  Future<void> _backupCurrentPreferences() async {
    try {
      Log.v('ImportTransaction: 备份当前SharedPreferences');
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final data = <String, dynamic>{};

      for (final key in keys) {
        final value = prefs.get(key);
        if (value != null) {
          data[key] = value;
        }
      }

      _originalPreferences = data;
      Log.v('ImportTransaction: SharedPreferences备份完成，键数量: ${data.length}');
    } catch (e, stackTrace) {
      Log.e('ImportTransaction: 备份SharedPreferences失败: $e');
      ErrorHandler.handle(e, stackTrace, prefix: '备份SharedPreferences失败');
      rethrow;
    }
  }

  /// 备份当前数据库文件
  Future<void> _backupCurrentDatabases() async {
    try {
      Log.v('ImportTransaction: 备份当前数据库文件');
      final dataDir = await DataManager.getCurrentDataDir();
      final dbDir = Directory(path.join(dataDir, 'databases'));

      if (!await dbDir.exists()) {
        Log.v('ImportTransaction: 数据库目录不存在，跳过备份');
        _originalDatabaseFiles = {};
        return;
      }

      final backupFiles = <String, File>{};

      await for (final entity in dbDir.list(recursive: true)) {
        if (entity is File) {
          final relativePath = path.relative(entity.path, from: dataDir);
          final backupPath = await _createTempBackupFile(entity);
          backupFiles[relativePath] = File(backupPath);
        }
      }

      _originalDatabaseFiles = backupFiles;
      Log.v('ImportTransaction: 数据库文件备份完成，文件数量: ${backupFiles.length}');
    } catch (e, stackTrace) {
      Log.e('ImportTransaction: 备份数据库文件失败: $e');
      ErrorHandler.handle(e, stackTrace, prefix: '备份数据库文件失败');
      rethrow;
    }
  }

  /// 创建临时备份文件
  Future<String> _createTempBackupFile(File originalFile) async {
    final tempDir = Directory.systemTemp;
    final tempFileName =
        'backup_${_transactionId}_${path.basename(originalFile.path)}';
    final tempFile = File(path.join(tempDir.path, tempFileName));

    await originalFile.copy(tempFile.path);
    return tempFile.path;
  }

  /// 创建当前数据的完整备份
  Future<void> createCurrentDataBackup() async {
    try {
      Log.i('ImportTransaction: 创建当前数据完整备份');

      // 使用BackupService创建完整备份
      const options = ExportOptions(
        includeSharedPreferences: true,
        includeDatabases: true,
      );

      final collectedData =
          await BackupService.collectBackupData(options: options);
      final backupData = collectedData['backupData'] as BackupData;
      final databaseData =
          collectedData['databaseData'] as Map<String, Uint8List>;

      // 创建备份文件
      final finalZipData = BackupService.createStandardZipData(
        backupData: backupData,
        databaseData: databaseData,
        options: options,
        logPrefix: 'ImportTransaction',
      );

      // 保存备份文件
      final backupDir = await _getTransactionBackupDir();
      final backupFileName = 'pre_import_backup_$_transactionId.zip';
      final backupPath = path.join(backupDir, backupFileName);

      await Directory(backupDir).create(recursive: true);
      await File(backupPath).writeAsBytes(finalZipData);

      _currentDataBackupPath = backupPath;
      Log.i('ImportTransaction: 当前数据备份完成: $backupPath');
      GlobalMsgManager.showSuccess('当前数据备份完成，位置: $backupPath');
    } catch (e, stackTrace) {
      Log.e('ImportTransaction: 创建当前数据备份失败: $e');
      ErrorHandler.handle(e, stackTrace, prefix: '创建当前数据备份失败');
      rethrow;
    }
  }

  /// 获取事务备份目录
  Future<String> _getTransactionBackupDir() async {
    final dataDir = await DataManager.getCurrentDataDir();
    return path.join(dataDir, 'transaction_backups');
  }

  /// 执行原子性导入操作
  Future<void> executeImport({
    required Archive dataArchive,
    required Function(String message, double progress) onProgress,
  }) async {
    try {
      Log.i('ImportTransaction: 开始执行原子性导入');

      // 导入SharedPreferences
      if (_options.importSharedPreferences) {
        onProgress('恢复配置数据...', 0.3);
        await _atomicImportSharedPreferences(dataArchive);
      }

      // 导入数据库
      if (_options.importDatabases) {
        onProgress('恢复数据库...', 0.7);
        await _atomicImportDatabases(dataArchive);
      }

      onProgress('导入操作完成', 1.0);
      Log.i('ImportTransaction: 原子性导入执行完成');
    } catch (e, stackTrace) {
      Log.e('ImportTransaction: 执行导入失败: $e');
      ErrorHandler.handle(e, stackTrace, prefix: '执行导入失败');
      rethrow;
    }
  }

  /// 原子性导入SharedPreferences
  Future<void> _atomicImportSharedPreferences(Archive archive) async {
    const preferencesFileName = 'shared_preferences.json';
    final prefsFile =
        archive.files.where((f) => f.name == preferencesFileName).firstOrNull;

    if (prefsFile == null) {
      Log.w('ImportTransaction: 备份中未找到SharedPreferences数据');
      return;
    }

    try {
      final content = utf8.decode(prefsFile.content as List<int>);
      final data = jsonDecode(content) as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();

      // 原子性操作：先清除，再批量设置
      await prefs.clear();

      for (final entry in data.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is String) {
          await prefs.setString(key, value);
        } else if (value is List<String>) {
          await prefs.setStringList(key, value);
        }
      }

      Log.i('ImportTransaction: SharedPreferences原子性导入完成，键数量: ${data.length}');
    } catch (e) {
      Log.e('ImportTransaction: SharedPreferences原子性导入失败: $e');
      // 恢复原始数据
      await _restoreOriginalPreferences();
      rethrow;
    }
  }

  /// 原子性导入数据库
  Future<void> _atomicImportDatabases(Archive archive) async {
    try {
      final dataDir = await DataManager.getCurrentDataDir();
      final dbDir = Directory(path.join(dataDir, 'databases'));

      // 确保数据库目录存在
      await dbDir.create(recursive: true);

      // 查找数据库文件
      final dbFiles = archive.files.where((f) {
        final posixPath = path.posix.joinAll(path.split(f.name));
        final databasesPath = path.posix.join('databases');
        return posixPath.startsWith(databasesPath + path.posix.separator);
      }).toList();

      if (dbFiles.isEmpty) {
        Log.w('ImportTransaction: 备份中未找到数据库文件');
        return;
      }

      // 关键修复：在删除数据库文件前强制关闭所有数据库连接
      Log.v('ImportTransaction: 强制关闭数据库连接以释放文件锁');
      await DatabaseHelper.instance.resetConnection();

      // 等待一小段时间确保连接完全关闭
      await Future.delayed(const Duration(milliseconds: 100));

      // 原子性操作：先删除现有文件，再恢复新文件
      await _clearCurrentDatabases(dbDir);
      await _restoreDatabaseFiles(dbFiles, dataDir);

      Log.i('ImportTransaction: 数据库原子性导入完成，文件数量: ${dbFiles.length}');
    } catch (e) {
      Log.e('ImportTransaction: 数据库原子性导入失败: $e');
      // 恢复原始数据库文件
      await _restoreOriginalDatabases();
      rethrow;
    }
  }

  /// 清除当前数据库文件
  Future<void> _clearCurrentDatabases(Directory dbDir) async {
    if (await dbDir.exists()) {
      await for (final entity in dbDir.list(recursive: true)) {
        if (entity is File) {
          // 使用重试机制删除文件，处理文件被占用的情况
          await _deleteFileWithRetry(entity);
        }
      }
    }
  }

  /// 带重试机制的文件删除方法
  Future<void> _deleteFileWithRetry(File file, {int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        Log.v('ImportTransaction: 尝试删除文件 ${file.path} (第 $attempt 次)');
        await file.delete();
        Log.v('ImportTransaction: 文件删除成功 ${file.path}');
        return; // 删除成功，退出重试循环
      } catch (e) {
        Log.w('ImportTransaction: 删除文件失败 ${file.path} (第 $attempt 次): $e');

        if (attempt == maxRetries) {
          // 最后一次尝试失败，抛出异常
          throw Exception('无法删除数据库文件 ${file.path}: $e\n'
              '可能原因：\n'
              '1. 文件正在被其他程序使用\n'
              '2. 权限不足\n'
              '3. 文件被锁定\n'
              '建议：关闭所有可能使用该数据库的程序后重试');
        }

        // 等待一段时间后重试
        final waitTime = Duration(milliseconds: 200 * attempt);
        Log.v('ImportTransaction: 等待 ${waitTime.inMilliseconds}ms 后重试');
        await Future.delayed(waitTime);

        // 在重试前再次尝试关闭数据库连接
        await DatabaseHelper.instance.resetConnection();
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
  }

  /// 恢复数据库文件
  Future<void> _restoreDatabaseFiles(
      List<ArchiveFile> dbFiles, String dataDir) async {
    for (final file in dbFiles) {
      final originalPath = file.name;
      final pathParts = path.split(originalPath);
      final platformPath = path.joinAll(pathParts);
      final targetPath = path.join(dataDir, platformPath);
      final targetFile = File(targetPath);

      await targetFile.parent.create(recursive: true);
      await targetFile.writeAsBytes(file.content as List<int>);
    }
  }

  /// 提交事务
  Future<void> commit() async {
    if (_isCommitted || _isRolledBack) {
      throw Exception('事务已经提交或回滚');
    }

    try {
      Log.i('ImportTransaction: 提交事务 [$_transactionId]');

      // 重置数据库连接以确保使用新的数据库文件
      await _resetDatabaseConnection();

      // 清理临时备份文件
      await _cleanupTempBackups();

      _isCommitted = true;
      Log.i('ImportTransaction: 事务提交成功 [$_transactionId]');
    } catch (e, stackTrace) {
      Log.e('ImportTransaction: 提交事务失败: $e');
      ErrorHandler.handle(e, stackTrace, prefix: '提交事务失败');
      rethrow;
    }
  }

  /// 回滚事务
  Future<void> rollback() async {
    if (_isCommitted || _isRolledBack) {
      throw Exception('事务已经提交或回滚');
    }

    try {
      Log.i('ImportTransaction: 开始回滚事务 [$_transactionId]');

      // 恢复SharedPreferences
      if (_options.importSharedPreferences && _originalPreferences != null) {
        await _restoreOriginalPreferences();
      }

      // 恢复数据库文件
      if (_options.importDatabases && _originalDatabaseFiles != null) {
        await _restoreOriginalDatabases();
      }

      // 重置数据库连接以确保使用恢复的数据库文件
      await _resetDatabaseConnection();

      // 清理临时文件
      await _cleanupTempBackups();

      _isRolledBack = true;
      Log.i('ImportTransaction: 事务回滚成功 [$_transactionId]');
    } catch (e, stackTrace) {
      Log.e('ImportTransaction: 回滚事务失败: $e');
      ErrorHandler.handle(e, stackTrace, prefix: '回滚事务失败');
      rethrow;
    }
  }

  /// 恢复原始SharedPreferences
  Future<void> _restoreOriginalPreferences() async {
    if (_originalPreferences == null) return;

    try {
      Log.v('ImportTransaction: 恢复原始SharedPreferences');
      final prefs = await SharedPreferences.getInstance();

      await prefs.clear();

      for (final entry in _originalPreferences!.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is String) {
          await prefs.setString(key, value);
        } else if (value is List<String>) {
          await prefs.setStringList(key, value);
        }
      }

      Log.v('ImportTransaction: SharedPreferences恢复完成');
    } catch (e, stackTrace) {
      Log.e('ImportTransaction: 恢复SharedPreferences失败: $e');
      ErrorHandler.handle(e, stackTrace, prefix: '恢复SharedPreferences失败');
      rethrow;
    }
  }

  /// 恢复原始数据库文件
  Future<void> _restoreOriginalDatabases() async {
    if (_originalDatabaseFiles == null) return;

    try {
      Log.v('ImportTransaction: 恢复原始数据库文件');
      final dataDir = await DataManager.getCurrentDataDir();
      final dbDir = Directory(path.join(dataDir, 'databases'));

      // 关键修复：在删除数据库文件前强制关闭所有数据库连接
      Log.v('ImportTransaction: 强制关闭数据库连接以释放文件锁（回滚操作）');
      await DatabaseHelper.instance.resetConnection();

      // 等待一小段时间确保连接完全关闭
      await Future.delayed(const Duration(milliseconds: 100));

      // 清除当前数据库文件
      await _clearCurrentDatabases(dbDir);

      // 恢复原始文件
      for (final entry in _originalDatabaseFiles!.entries) {
        final relativePath = entry.key;
        final backupFile = entry.value;
        final targetPath = path.join(dataDir, relativePath);
        final targetFile = File(targetPath);

        await targetFile.parent.create(recursive: true);
        await backupFile.copy(targetPath);
      }

      Log.v('ImportTransaction: 数据库文件恢复完成');
    } catch (e, stackTrace) {
      Log.e('ImportTransaction: 恢复数据库文件失败: $e');
      ErrorHandler.handle(e, stackTrace, prefix: '恢复数据库文件失败');
      rethrow;
    }
  }

  /// 清理临时备份文件
  Future<void> _cleanupTempBackups() async {
    try {
      Log.v('ImportTransaction: 清理临时备份文件');

      // 清理数据库备份文件
      if (_originalDatabaseFiles != null) {
        for (final backupFile in _originalDatabaseFiles!.values) {
          if (await backupFile.exists()) {
            await backupFile.delete();
          }
        }
      }

      // 清理完整数据备份文件（可选，用户可能需要保留）
      if (_currentDataBackupPath != null) {
        final backupFile = File(_currentDataBackupPath!);
        if (await backupFile.exists()) {
          // 不删除完整备份，让用户决定是否保留
          Log.i('ImportTransaction: 保留完整数据备份: $_currentDataBackupPath');
        }
      }

      Log.v('ImportTransaction: 临时文件清理完成');
    } catch (e) {
      Log.w('ImportTransaction: 清理临时文件失败: $e');
      // 清理失败不影响主要操作
    }
  }

  /// 重置数据库连接
  /// 在数据库文件被替换后调用，确保使用新的数据库文件
  Future<void> _resetDatabaseConnection() async {
    try {
      Log.v('ImportTransaction: 重置数据库连接');

      // 重置DatabaseHelper的数据库连接
      // 这将强制下次访问时重新初始化数据库连接
      await DatabaseHelper.instance.resetConnection();

      Log.v('ImportTransaction: 数据库连接重置完成');
    } catch (e, stackTrace) {
      Log.e('ImportTransaction: 重置数据库连接失败: $e');
      ErrorHandler.handle(e, stackTrace, prefix: '重置数据库连接失败');
      // 不重新抛出异常，因为这不应该阻止事务提交
      // 但记录错误以便调试
    }
  }
}
