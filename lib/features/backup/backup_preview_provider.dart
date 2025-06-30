import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:counters/common/db/db_helper.dart';
import 'package:counters/common/utils/error_handler.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/features/backup/backup_models.dart';
import 'package:counters/features/backup/backup_service.dart';
import 'package:path/path.dart' as path;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

part 'backup_preview_provider.g.dart';

/// 备份预览状态管理
@riverpod
class BackupPreviewManager extends _$BackupPreviewManager {
  @override
  PreviewState build() {
    return const PreviewState();
  }

  /// 分析备份文件并生成预览信息
  Future<void> analyzeBackupFile(String filePath) async {
    try {
      state = state.copyWith(
        isLoading: true,
        isAnalyzing: true,
        isCheckingCompatibility: false,
        error: null,
        selectedFilePath: filePath,
        previewInfo: null,
      );

      Log.v('BackupPreviewManager: 开始分析备份文件 - $filePath');

      // 1. 验证文件存在
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('备份文件不存在');
      }

      // 2. 解析ZIP文件
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // 3. 验证文件完整性
      Log.v('BackupPreviewManager: 验证文件完整性');
      final integrityValid = await BackupService.verifyFileIntegrity(filePath);

      // 4. 检查文件哈希
      bool hasHash = false;
      bool hashValid = false;
      String? hashError;

      try {
        final hashFile = archive.files.where((f) => f.name == 'backup_hash.json').firstOrNull;
        if (hashFile != null) {
          hasHash = true;
          hashValid = integrityValid;
          if (!hashValid) {
            hashError = '文件哈希验证失败，文件可能已被修改';
          }
        }
      } catch (e) {
        hashError = '文件哈希验证时发生错误: $e';
      }

      // 5. 获取实际数据archive
      Log.v('BackupPreviewManager: 提取数据archive');
      final dataArchive = await _extractDataArchive(archive);

      // 6. 解析元数据
      Log.v('BackupPreviewManager: 解析元数据');
      final metadataFile = dataArchive.files.where((f) => f.name == 'backup_metadata.json').firstOrNull;
      if (metadataFile == null) {
        throw Exception('备份文件格式错误：缺少元数据文件');
      }

      final metadataContent = utf8.decode(metadataFile.content as List<int>);
      final metadataJson = jsonDecode(metadataContent) as Map<String, dynamic>;
      final metadata = BackupMetadata.fromJson(metadataJson);

      // 7. 检查版本兼容性
      Log.v('BackupPreviewManager: 检查版本兼容性');
      state = state.copyWith(
        isAnalyzing: false,
        isCheckingCompatibility: true,
      );

      final compatibilityInfo = await BackupService.checkZipCompatibility(filePath);

      // 8. 分析数据统计
      Log.v('BackupPreviewManager: 分析数据统计');
      final dataStatistics = await _analyzeDataStatistics(dataArchive);

      // 9. 获取数据类型列表
      final dataTypes = await _getDataTypes(dataArchive);

      // 10. 创建预览信息
      final previewInfo = BackupPreviewInfo(
        metadata: metadata,
        dataStatistics: dataStatistics,
        dataTypes: dataTypes,
        hasHash: hasHash,
        hashValid: hashValid,
        hashError: hashError,
        compatibilityInfo: compatibilityInfo,
      );

      state = state.copyWith(
        isLoading: false,
        isAnalyzing: false,
        isCheckingCompatibility: false,
        previewInfo: previewInfo,
      );

      Log.i('BackupPreviewManager: 备份文件分析完成');
    } catch (e, stackTrace) {
      Log.e('BackupPreviewManager: 分析备份文件失败 - $e');
      Log.e('StackTrace: $stackTrace');

      state = state.copyWith(
        isLoading: false,
        isAnalyzing: false,
        isCheckingCompatibility: false,
        error: e.toString(),
      );

      ErrorHandler.handle(e, stackTrace, prefix: '分析备份文件失败');
    }
  }

  /// 提取数据archive
  Future<Archive> _extractDataArchive(Archive archive) async {
    try {
      // 查找数据文件
      final dataFile = archive.files.where((f) => f.name == 'backup_data.zip').firstOrNull;

      if (dataFile == null) {
        throw Exception('备份文件格式错误：缺少数据文件');
      }

      Log.v('BackupPreviewManager: 提取原始数据');
      // 从backup_data.zip中提取数据
      final originalZipData = dataFile.content as List<int>;
      final dataArchive = ZipDecoder().decodeBytes(originalZipData);
      return dataArchive;
    } catch (e, stackTrace) {
      Log.e('BackupPreviewManager: 提取数据archive失败 - $e');
      Log.e('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// 分析数据统计信息
  Future<Map<String, dynamic>> _analyzeDataStatistics(Archive archive) async {
    final statistics = <String, dynamic>{};

    try {
      // 调试：打印所有文件名
      Log.v('BackupPreviewManager: Archive中的所有文件:');
      for (final file in archive.files) {
        Log.v('  - ${file.name} (${file.size} bytes)');
      }

      // 分析SharedPreferences数据
      final prefsFile = archive.files.where((f) => f.name == 'shared_preferences.json').firstOrNull;
      if (prefsFile != null) {
        final prefsContent = utf8.decode(prefsFile.content as List<int>);
        final prefsData = jsonDecode(prefsContent) as Map<String, dynamic>;
        statistics['sharedPreferencesCount'] = prefsData.length;

        // 分析具体的配置项
        statistics['hasCounterSettings'] = prefsData.keys.any((key) => key.contains('counter'));
        statistics['hasMahjongSettings'] = prefsData.keys.any((key) => key.contains('mahjong'));
        statistics['hasPoker50Settings'] = prefsData.keys.any((key) => key.contains('poker'));

        Log.v('BackupPreviewManager: SharedPreferences数量: ${statistics['sharedPreferencesCount']}');
      } else {
        statistics['sharedPreferencesCount'] = 0;
        Log.v('BackupPreviewManager: 未找到SharedPreferences文件');
      }

      // 分析数据库文件 - 兼容不同操作系统的路径分隔符
      final dbFiles = archive.files.where((f) =>
        f.name.startsWith('databases/') ||
        f.name.startsWith('databases\\') ||
        f.name.contains('databases${Platform.pathSeparator}')
      ).toList();
      statistics['databaseFilesCount'] = dbFiles.length;

      Log.v('BackupPreviewManager: 数据库文件数量: ${dbFiles.length}');
      for (final dbFile in dbFiles) {
        Log.v('  - 数据库文件: ${dbFile.name}');
      }

      // 额外调试：检查所有可能的数据库相关文件
      final allDbRelatedFiles = archive.files.where((f) =>
        f.name.contains('database') ||
        f.name.contains('.db') ||
        f.name.contains('sqlite')
      ).toList();
      Log.v('BackupPreviewManager: 所有数据库相关文件数量: ${allDbRelatedFiles.length}');
      for (final file in allDbRelatedFiles) {
        Log.v('  - 相关文件: ${file.name}');
      }

      // 分析数据库内容统计
      final dbStatistics = await _analyzeDatabaseContent(dbFiles);
      statistics.addAll(dbStatistics);

      // 计算总文件大小
      int totalSize = 0;
      for (final file in archive.files) {
        totalSize += file.size;
      }
      statistics['totalSize'] = totalSize;

    } catch (e) {
      Log.w('BackupPreviewManager: 分析数据统计时发生错误 - $e');
    }

    return statistics;
  }

  /// 获取数据类型列表
  Future<List<String>> _getDataTypes(Archive archive) async {
    final dataTypes = <String>[];

    // 检查SharedPreferences
    if (archive.files.any((f) => f.name == 'shared_preferences.json')) {
      dataTypes.add('应用设置');
      Log.v('BackupPreviewManager: 找到SharedPreferences数据');
    }

    // 检查数据库文件 - 兼容不同操作系统的路径分隔符
    final dbFiles = archive.files.where((f) =>
      f.name.startsWith('databases/') ||
      f.name.startsWith('databases\\') ||
      f.name.contains('databases${Platform.pathSeparator}')
    ).toList();
    Log.v('BackupPreviewManager: 在数据类型分析中找到数据库文件数量: ${dbFiles.length}');
    for (final dbFile in dbFiles) {
      Log.v('  - 数据类型分析中的数据库文件: ${dbFile.name}');
    }
    if (dbFiles.isNotEmpty) {
      dataTypes.add('数据库文件 (${dbFiles.length}个)');
    }

    // 分析具体的数据库内容类型
    final dbStatistics = await _analyzeDatabaseContent(dbFiles);

    // 根据实际数据库内容添加数据类型
    if (dbStatistics['templatesCount'] > 0) {
      dataTypes.add('游戏模板 (${dbStatistics['templatesCount']}个)');
    }
    if (dbStatistics['playersCount'] > 0) {
      dataTypes.add('玩家信息 (${dbStatistics['playersCount']}个)');
    }
    if (dbStatistics['gameSessionsCount'] > 0) {
      dataTypes.add('游戏记录 (${dbStatistics['gameSessionsCount']}个)');
    }

    // 按模板类型分类显示
    for (final entry in dbStatistics.entries) {
      final key = entry.key;
      final value = entry.value;

      // 检查是否是模板类型统计字段
      if (key.endsWith('TemplatesCount') && value > 0) {
        final templateType = key.replaceAll('TemplatesCount', '');
        dataTypes.add('$templateType ($value个)');
      }
    }

    return dataTypes;
  }

  /// 清除预览状态
  void clearPreview() {
    state = const PreviewState();
  }

  /// 获取当前数据统计（用于对比）
  Future<Map<String, dynamic>> getCurrentDataStatistics() async {
    try {
      final statistics = <String, dynamic>{};

      // 获取当前SharedPreferences数据
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      statistics['currentSharedPreferencesCount'] = allKeys.length;

      // 获取当前数据库统计
      final currentDbStats = await _getCurrentDatabaseStatistics();
      statistics.addAll(currentDbStats);

      return statistics;
    } catch (e) {
      Log.w('BackupPreviewManager: 获取当前数据统计失败 - $e');
      return {};
    }
  }

  /// 获取当前数据库统计信息
  Future<Map<String, dynamic>> _getCurrentDatabaseStatistics() async {
    final statistics = <String, dynamic>{
      'currentTemplatesCount': 0,
      'currentPlayersCount': 0,
      'currentGameSessionsCount': 0,
    };

    try {
      // 使用DatabaseHelper获取当前数据库
      final dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;

      // 查询模板数量
      final templatesCount = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM templates'
      )) ?? 0;
      statistics['currentTemplatesCount'] = templatesCount;

      // 查询玩家数量
      final playersCount = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM players'
      )) ?? 0;
      statistics['currentPlayersCount'] = playersCount;

      // 查询游戏会话总数
      final gameSessionsCount = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM game_sessions'
      )) ?? 0;
      statistics['currentGameSessionsCount'] = gameSessionsCount;

      // 按模板类型统计模板数量
      final templateTypeCounts = await db.rawQuery('''
        SELECT template_type, COUNT(*) as template_count
        FROM templates
        GROUP BY template_type
      ''');

      for (final row in templateTypeCounts) {
        final templateType = row['template_type'] as String;
        final templateCount = row['template_count'] as int;
        statistics['current${templateType}TemplatesCount'] = templateCount;
      }

      Log.v('BackupPreviewManager: 当前数据库统计完成 - 模板:$templatesCount, 玩家:$playersCount, 会话:$gameSessionsCount');

    } catch (e) {
      Log.w('BackupPreviewManager: 获取当前数据库统计失败 - $e');
      // 在测试环境或数据库未初始化时，返回默认值
      if (e.toString().contains('databaseFactory not initialized')) {
        Log.v('BackupPreviewManager: 检测到测试环境，使用默认统计值');
      }
    }

    return statistics;
  }

  /// 分析数据库内容统计
  Future<Map<String, dynamic>> _analyzeDatabaseContent(List<ArchiveFile> dbFiles) async {
    final statistics = <String, dynamic>{
      'templatesCount': 0,
      'playersCount': 0,
      'gameSessionsCount': 0,
    };

    try {
      // 查找主数据库文件 (counters.db)
      final mainDbFile = dbFiles.where((f) =>
        f.name.endsWith('counters.db') ||
        f.name.contains('databases${Platform.pathSeparator}counters.db') ||
        f.name.contains('databases/counters.db')
      ).firstOrNull;

      if (mainDbFile == null) {
        Log.v('BackupPreviewManager: 未找到主数据库文件');
        return statistics;
      }

      Log.v('BackupPreviewManager: 分析数据库文件: ${mainDbFile.name}');

      // 创建临时数据库文件进行查询
      final tempDbStats = await _queryTemporaryDatabase(mainDbFile);
      statistics.addAll(tempDbStats);

    } catch (e) {
      Log.w('BackupPreviewManager: 分析数据库内容失败 - $e');
    }

    return statistics;
  }

  /// 查询临时数据库文件
  Future<Map<String, dynamic>> _queryTemporaryDatabase(ArchiveFile dbFile) async {
    final statistics = <String, dynamic>{
      'templatesCount': 0,
      'playersCount': 0,
      'gameSessionsCount': 0,
    };

    Database? tempDb;
    File? tempFile;

    try {
      // 创建临时文件
      final tempDir = Directory.systemTemp;
      final tempFileName = 'temp_backup_db_${DateTime.now().millisecondsSinceEpoch}.db';
      tempFile = File(path.join(tempDir.path, tempFileName));

      // 写入数据库内容
      await tempFile.writeAsBytes(dbFile.content as List<int>);

      Log.v('BackupPreviewManager: 创建临时数据库文件: ${tempFile.path}');

      // 打开临时数据库（只读模式）
      tempDb = await openDatabase(
        tempFile.path,
        readOnly: true,
        singleInstance: false,
      );

      // 查询模板数量
      final templatesCount = Sqflite.firstIntValue(await tempDb.rawQuery(
        'SELECT COUNT(*) FROM templates'
      )) ?? 0;
      statistics['templatesCount'] = templatesCount;

      // 查询玩家数量
      final playersCount = Sqflite.firstIntValue(await tempDb.rawQuery(
        'SELECT COUNT(*) FROM players'
      )) ?? 0;
      statistics['playersCount'] = playersCount;

      // 查询游戏会话总数
      final gameSessionsCount = Sqflite.firstIntValue(await tempDb.rawQuery(
        'SELECT COUNT(*) FROM game_sessions'
      )) ?? 0;
      statistics['gameSessionsCount'] = gameSessionsCount;

      // 按模板类型统计模板数量
      final templateTypeCounts = await tempDb.rawQuery('''
        SELECT template_type, COUNT(*) as template_count
        FROM templates
        GROUP BY template_type
      ''');

      for (final row in templateTypeCounts) {
        final templateType = row['template_type'] as String;
        final templateCount = row['template_count'] as int;
        statistics['${templateType}TemplatesCount'] = templateCount;
      }

      Log.v('BackupPreviewManager: 数据库统计完成 - 模板:$templatesCount, 玩家:$playersCount, 会话:$gameSessionsCount');

    } catch (e) {
      Log.w('BackupPreviewManager: 查询临时数据库失败 - $e');
    } finally {
      // 清理资源
      try {
        await tempDb?.close();
        if (tempFile != null && await tempFile.exists()) {
          await tempFile.delete();
          Log.v('BackupPreviewManager: 临时数据库文件已清理');
        }
      } catch (e) {
        Log.w('BackupPreviewManager: 清理临时数据库文件失败 - $e');
      }
    }

    return statistics;
  }
}
