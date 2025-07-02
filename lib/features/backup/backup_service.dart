import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:counters/common/utils/error_handler.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/common/widgets/message_overlay.dart';
import 'package:counters/features/backup/backup_models.dart';
import 'package:counters/features/backup/import_transaction.dart';
import 'package:counters/features/backup/services/hash_service.dart';
import 'package:counters/features/setting/data_manager.dart';
import 'package:crypto/crypto.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 备份服务类
class BackupService {
  static const int _backupCode = 1;
  static const String _metadataFileName = 'backup_metadata.json';
  static const String _preferencesFileName = 'shared_preferences.json';
  static const String _hashFileName = 'backup_hash.json';
  static const String _dataFileName = 'backup_data.zip';

  /// 导出数据到ZIP文件
  static Future<String> exportData({
    required ExportOptions options,
    required Function(String message, double progress) onProgress,
  }) async {
    try {
      onProgress('开始导出...', 0.0);

      // 1. 收集备份数据
      final collectedData = await _collectBackupData(
        options: options,
        onProgress: onProgress,
      );
      final backupData = collectedData['backupData'] as BackupData;
      final databaseData =
          collectedData['databaseData'] as Map<String, Uint8List>;

      // 2. 创建ZIP文件
      onProgress('生成ZIP文件...', 0.8);
      final zipPath = await _createZipFile(
        backupData: backupData,
        databaseData: databaseData,
        options: options,
      );

      onProgress('导出完成', 1.0);
      Log.i('数据导出成功: $zipPath');
      return zipPath;
    } catch (e, stackTrace) {
      Log.e('导出数据失败: $e');
      Log.e('StackTrace: $stackTrace');
      ErrorHandler.handle(e, stackTrace, prefix: '导出数据失败');
      rethrow;
    }
  }

  /// 导入数据从ZIP文件（带原子性保证和回滚机制）
  static Future<void> importData({
    required String zipPath,
    required ImportOptions options,
    required Function(String message, double progress) onProgress,
  }) async {
    ImportTransaction? transaction;

    try {
      onProgress('开始导入...', 0.0);

      // 1. 验证ZIP文件基本格式
      onProgress('验证文件格式...', 0.05);
      final archive = await _validateZipFile(zipPath);

      // 2. 验证文件完整性
      onProgress('验证文件完整性...', 0.1);
      final integrityValid = await verifyFileIntegrity(zipPath);
      if (!integrityValid && !options.forceImport) {
        throw Exception('文件完整性验证失败，文件可能已被修改或损坏');
      }

      // 3. 获取实际数据archive
      onProgress('提取备份数据...', 0.15);
      final dataArchive = await _extractDataArchive(archive);

      // 4. 解析元数据
      onProgress('解析备份信息...', 0.2);
      final metadata = await _parseMetadata(dataArchive);

      // 5. 检查版本兼容性
      onProgress('检查版本兼容性...', 0.3);
      final compatibility = await _checkCompatibility(metadata);

      if (compatibility.level == CompatibilityLevel.incompatible &&
          !options.forceImport) {
        throw Exception('版本不兼容: ${compatibility.message}');
      }

      // 6. 创建导入事务，开始原子性操作
      onProgress('准备导入事务...', 0.35);
      transaction = await ImportTransaction.begin(options);

      // 7. 创建当前数据备份（如果启用）
      if (options.createBackup) {
        onProgress('自动备份当前数据...', 0.4);
        await transaction.createCurrentDataBackup();
      }

      // 8. 执行原子性导入操作
      onProgress('执行原子性导入...', 0.5);
      await transaction.executeImport(
        dataArchive: dataArchive,
        onProgress: (message, progress) {
          // 将事务内部进度映射到总体进度 (0.5-0.9)
          final mappedProgress = 0.5 + (progress * 0.4);
          onProgress(message, mappedProgress);
        },
      );

      // 9. 提交事务
      onProgress('提交导入事务...', 0.95);
      await transaction.commit();

      onProgress('导入完成', 1.0);
      Log.i('数据导入成功');
      GlobalMsgManager.showSuccess('数据导入成功');
    } catch (e, stackTrace) {
      Log.e('导入数据失败: $e');

      // 执行回滚操作
      if (transaction != null) {
        try {
          onProgress('回滚导入操作...', 0.0);
          await transaction.rollback();
          Log.i('导入失败，已成功回滚到原始状态');
          GlobalMsgManager.showWarn('导入失败，已恢复到原始状态');
        } catch (rollbackError, rollbackStack) {
          Log.e('回滚操作失败: $rollbackError');
          ErrorHandler.handle(rollbackError, rollbackStack, prefix: '回滚操作失败');
          GlobalMsgManager.showError('导入失败且回滚失败，数据可能处于不一致状态');
        }
      }

      ErrorHandler.handle(e, stackTrace, prefix: '数据导入失败');
      rethrow;
    }
  }

  /// 检查ZIP文件兼容性
  static Future<CompatibilityInfo> checkZipCompatibility(String zipPath) async {
    try {
      // 1. 验证外层ZIP文件基本存在性和格式
      final file = File(zipPath);
      if (!await file.exists()) {
        throw Exception('备份文件不存在');
      }

      final bytes = await file.readAsBytes();
      final outerArchive = ZipDecoder().decodeBytes(bytes);

      // 2. 提取内层数据archive
      final dataArchive = await _extractDataArchive(outerArchive);

      // 3. 解析元数据
      final metadata = await _parseMetadata(dataArchive);

      // 4. 检查版本兼容性
      return await _checkCompatibility(metadata);
    } catch (e) {
      Log.e('BackupService: 检查ZIP文件兼容性失败 - $e');
      return const CompatibilityInfo(
        level: CompatibilityLevel.incompatible,
        message: '无法读取备份文件或文件已损坏',
        errors: ['文件格式错误或文件损坏'],
      );
    }
  }

  /// 收集应用元数据
  static Future<BackupMetadata> _collectMetadata() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return BackupMetadata(
      appVersion: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      platform: Platform.operatingSystem,
      backupCode: _backupCode,
    );
  }

  /// 导出SharedPreferences数据
  static Future<Map<String, dynamic>> _exportSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final data = <String, dynamic>{};

    for (final key in keys) {
      final value = prefs.get(key);
      if (value != null) {
        data[key] = value;
      }
    }

    Log.i('导出SharedPreferences数据，键数量: ${data.length}');
    return data;
  }

  /// 导出数据库文件
  static Future<Map<String, dynamic>> _exportDatabases() async {
    final dataDir = await DataManager.getCurrentDataDir();
    final dbDir = Directory(path.join(dataDir, 'databases'));

    Log.v('BackupService: 开始导出数据库文件');
    Log.v('BackupService: 数据目录: $dataDir');
    Log.v('BackupService: 数据库目录: ${dbDir.path}');

    if (!await dbDir.exists()) {
      Log.w('数据库目录不存在: ${dbDir.path}');
      return {'files': <DatabaseFile>[], 'data': <String, Uint8List>{}};
    }

    final files = <DatabaseFile>[];
    final data = <String, Uint8List>{};

    Log.v('BackupService: 开始扫描数据库目录...');
    await for (final entity in dbDir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = path.relative(entity.path, from: dataDir);
        // 使用path包将路径转换为POSIX格式（用于ZIP存储）
        final posixPath = path.posix.joinAll(path.split(relativePath));
        final fileData = await entity.readAsBytes();
        final checksum = sha256.convert(fileData).toString();

        Log.v('BackupService: 导出数据库文件 - 绝对路径: ${entity.path}');
        Log.v('BackupService: 导出数据库文件 - 相对路径: $relativePath');
        Log.v('BackupService: 导出数据库文件 - POSIX路径: $posixPath');
        Log.v('BackupService: 导出数据库文件 - 文件大小: ${fileData.length} bytes');
        Log.v('BackupService: 导出数据库文件 - 校验和: $checksum');

        final dbFile = DatabaseFile(
          name: path.basename(entity.path),
          relativePath: posixPath, // 使用POSIX格式路径
          size: fileData.length,
          checksum: checksum,
        );

        files.add(dbFile);
        data[posixPath] = fileData; // 使用POSIX格式路径作为key

        Log.v('BackupService: 添加到导出数据 - Key: $posixPath');
      }
    }

    Log.i('导出数据库文件数量: ${files.length}');
    Log.v('BackupService: 导出的数据库文件路径列表:');
    for (final key in data.keys) {
      Log.v('BackupService: - $key (${data[key]!.length} bytes)');
    }

    return {'files': files, 'data': data};
  }

  /// 收集备份数据（公开方法，供ImportTransaction使用）
  static Future<Map<String, dynamic>> collectBackupData({
    required ExportOptions options,
    Function(String message, double progress)? onProgress,
  }) async {
    return await _collectBackupData(options: options, onProgress: onProgress);
  }

  /// 收集备份数据（内部实现）
  static Future<Map<String, dynamic>> _collectBackupData({
    required ExportOptions options,
    Function(String message, double progress)? onProgress,
  }) async {
    // 1. 收集元数据
    onProgress?.call('收集应用信息...', 0.1);
    final metadata = await _collectMetadata();

    // 2. 收集SharedPreferences数据
    Map<String, dynamic>? prefsData;
    if (options.includeSharedPreferences) {
      onProgress?.call('导出配置数据...', 0.2);
      prefsData = await _exportSharedPreferences();
    }

    // 3. 收集数据库文件
    List<DatabaseFile>? dbFiles;
    Map<String, Uint8List>? dbData;
    if (options.includeDatabases) {
      onProgress?.call('导出数据库...', 0.4);
      final dbResult = await _exportDatabases();
      dbFiles = dbResult['files'] as List<DatabaseFile>;
      dbData = dbResult['data'] as Map<String, Uint8List>;
    }

    // 4. 创建备份数据结构
    onProgress?.call('打包数据...', 0.7);
    final backupData = BackupData(
      metadata: metadata,
      sharedPreferences: prefsData ?? {},
      databases: dbFiles ?? [],
    );

    return {
      'backupData': backupData,
      'databaseData': dbData ?? <String, Uint8List>{},
    };
  }

  /// 创建标准格式的ZIP备份数据（公开方法，供ImportTransaction使用）
  static List<int> createStandardZipData({
    required BackupData backupData,
    required Map<String, Uint8List> databaseData,
    required ExportOptions options,
    String logPrefix = 'BackupService',
  }) {
    return _createStandardZipData(
      backupData: backupData,
      databaseData: databaseData,
      options: options,
      logPrefix: logPrefix,
    );
  }

  /// 创建标准格式的ZIP备份数据（内部实现）
  static List<int> _createStandardZipData({
    required BackupData backupData,
    required Map<String, Uint8List> databaseData,
    required ExportOptions options,
    String logPrefix = 'BackupService',
  }) {
    final archive = Archive();

    // 添加元数据文件
    final metadataJson = jsonEncode(backupData.metadata.toJson());
    archive.addFile(ArchiveFile(
      _metadataFileName,
      metadataJson.length,
      utf8.encode(metadataJson),
    ));

    // 添加SharedPreferences文件
    if (options.includeSharedPreferences &&
        backupData.sharedPreferences.isNotEmpty) {
      final prefsJson = jsonEncode(backupData.sharedPreferences);
      archive.addFile(ArchiveFile(
        _preferencesFileName,
        prefsJson.length,
        utf8.encode(prefsJson),
      ));
    }

    // 添加数据库文件
    if (options.includeDatabases) {
      Log.v('$logPrefix: 添加数据库文件到ZIP，数量: ${databaseData.length}');
      if (databaseData.isEmpty) {
        Log.w('$logPrefix: 警告 - 数据库数据为空，但选项要求包含数据库');
      }
      for (final entry in databaseData.entries) {
        Log.v(
            '$logPrefix: 添加数据库文件到ZIP - 路径: ${entry.key}, 大小: ${entry.value.length} bytes');
        archive.addFile(ArchiveFile(
          entry.key,
          entry.value.length,
          entry.value,
        ));
      }
      Log.v('$logPrefix: 数据库文件添加完成，Archive中总文件数: ${archive.files.length}');
    } else {
      Log.v('$logPrefix: 跳过数据库文件导出');
    }

    // 生成原始数据ZIP文件
    final originalZipData = ZipEncoder().encode(archive);
    if (originalZipData.isEmpty) {
      throw Exception('创建原始数据ZIP文件失败');
    }
    Log.v('$logPrefix: 原始ZIP数据长度: ${originalZipData.length} 字节');

    // 生成文件哈希（基于原始ZIP数据）
    Log.v('$logPrefix: 生成文件哈希');
    final hashInfo =
        HashService.generateHash(Uint8List.fromList(originalZipData));

    // 创建最终的archive，包含原始数据和哈希
    final finalArchive = Archive();

    // 添加原始ZIP数据
    finalArchive.addFile(ArchiveFile(
      _dataFileName,
      originalZipData.length,
      originalZipData,
    ));

    // 添加哈希信息
    final hashJson = jsonEncode(hashInfo.toJson());
    finalArchive.addFile(ArchiveFile(
      _hashFileName,
      hashJson.length,
      utf8.encode(hashJson),
    ));

    // 生成包含原始数据和哈希的最终ZIP文件
    final finalZipData = ZipEncoder().encode(finalArchive);
    if (finalZipData.isEmpty) {
      throw Exception('创建最终ZIP文件失败');
    }

    return finalZipData;
  }

  /// 创建ZIP文件
  static Future<String> _createZipFile({
    required BackupData backupData,
    required Map<String, Uint8List> databaseData,
    required ExportOptions options,
  }) async {
    // 使用公共方法创建ZIP数据
    final finalZipData = _createStandardZipData(
      backupData: backupData,
      databaseData: databaseData,
      options: options,
      logPrefix: 'BackupService',
    );

    // 确定保存路径
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = options.customFileName ?? 'counters_backup_$timestamp.zip';
    final savePath = options.customPath ?? await _getDefaultExportPath();
    final fullPath = path.join(savePath, fileName);

    // 确保目录存在
    await Directory(savePath).create(recursive: true);

    // 写入文件
    final file = File(fullPath);
    await file.writeAsBytes(finalZipData);

    return fullPath;
  }

  /// 获取默认导出路径
  static Future<String> _getDefaultExportPath() async {
    if (Platform.isWindows) {
      final documentsDir = await DataManager.getDefaultBaseDir();
      return path.join(documentsDir, 'counters_backups');
    } else if (Platform.isAndroid) {
      // Android平台使用外部存储的Downloads目录
      try {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          return path.join(externalDir.path, 'Download', 'counters_backups');
        }
      } catch (e) {
        Log.w('无法获取外部存储目录: $e');
      }
      // 如果外部存储不可用，使用应用文档目录
      final documentsDir = await DataManager.getDefaultBaseDir();
      return path.join(documentsDir, 'counters_backups');
    } else {
      final documentsDir = await DataManager.getDefaultBaseDir();
      return path.join(documentsDir, 'counters_backups');
    }
  }

  /// 验证ZIP文件
  static Future<Archive> _validateZipFile(String zipPath) async {
    final file = File(zipPath);
    if (!await file.exists()) {
      throw Exception('备份文件不存在');
    }

    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // 检查外层ZIP文件必要文件是否存在
    final hasDataFile = archive.files.any((f) => f.name == _dataFileName);
    final hasHashFile = archive.files.any((f) => f.name == _hashFileName);

    if (!hasDataFile) {
      throw Exception('备份文件格式错误：缺少数据文件');
    }

    if (!hasHashFile) {
      throw Exception('备份文件格式错误：缺少哈希信息文件');
    }

    // 验证内层ZIP文件中是否包含元数据文件
    try {
      final dataArchive = await _extractDataArchive(archive);
      final hasMetadata =
          dataArchive.files.any((f) => f.name == _metadataFileName);
      if (!hasMetadata) {
        throw Exception('备份文件格式错误：缺少元数据文件');
      }
    } catch (e) {
      throw Exception('备份文件格式错误：无法读取内层数据文件 - $e');
    }

    return archive;
  }

  /// 验证文件完整性
  static Future<bool> verifyFileIntegrity(String zipPath) async {
    try {
      Log.v('BackupService: 开始验证文件完整性');

      final file = File(zipPath);
      if (!await file.exists()) {
        Log.w('BackupService: 备份文件不存在');
        return false;
      }

      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // 检查是否有哈希文件和数据文件
      final hashFile =
          archive.files.where((f) => f.name == _hashFileName).firstOrNull;
      final dataFile =
          archive.files.where((f) => f.name == _dataFileName).firstOrNull;

      if (hashFile == null) {
        throw Exception('备份文件格式错误：缺少哈希信息文件');
      }

      if (dataFile == null) {
        throw Exception('备份文件格式错误：缺少数据文件');
      }

      // 解析哈希信息
      final hashContent = utf8.decode(hashFile.content as List<int>);
      final hashJson = jsonDecode(hashContent) as Map<String, dynamic>;
      final hashInfo = HashInfo.fromJson(hashJson);

      // 获取存储的原始ZIP数据
      final originalZipData = dataFile.content as List<int>;
      Log.v('BackupService: 存储的原始ZIP数据长度: ${originalZipData.length} 字节');

      // 验证文件哈希
      final isValid =
          HashService.verifyHash(Uint8List.fromList(originalZipData), hashInfo);

      if (isValid) {
        Log.i('BackupService: 文件完整性验证成功');
      } else {
        Log.w('BackupService: 文件完整性验证失败');
      }

      return isValid;
    } catch (e, stackTrace) {
      Log.e('BackupService: 验证文件完整性时发生错误 - $e');
      Log.e('StackTrace: $stackTrace');
      return false;
    }
  }

  /// 提取数据archive
  static Future<Archive> _extractDataArchive(Archive archive) async {
    try {
      Log.v('BackupService: 开始提取数据archive');
      Log.v('BackupService: 外层Archive文件数量: ${archive.files.length}');

      // 打印外层archive中的所有文件
      for (int i = 0; i < archive.files.length; i++) {
        final file = archive.files[i];
        Log.v('BackupService: 外层文件[$i]: ${file.name} (${file.size} bytes)');
      }

      // 查找数据文件
      final dataFile =
          archive.files.where((f) => f.name == _dataFileName).firstOrNull;

      if (dataFile == null) {
        Log.e('BackupService: 未找到数据文件: $_dataFileName');
        throw Exception('备份文件格式错误：缺少数据文件');
      }

      Log.v(
          'BackupService: 找到数据文件: ${dataFile.name}, 大小: ${dataFile.size} bytes');
      Log.v('BackupService: 提取原始数据');

      // 从backup_data.zip中提取数据
      final originalZipData = dataFile.content as List<int>;
      Log.v('BackupService: 原始ZIP数据长度: ${originalZipData.length} bytes');

      final dataArchive = ZipDecoder().decodeBytes(originalZipData);
      Log.v('BackupService: 内层Archive文件数量: ${dataArchive.files.length}');

      // 打印内层archive中的所有文件
      for (int i = 0; i < dataArchive.files.length; i++) {
        final file = dataArchive.files[i];
        Log.v('BackupService: 内层文件[$i]: ${file.name} (${file.size} bytes)');
      }

      return dataArchive;
    } catch (e, stackTrace) {
      Log.e('BackupService: 提取数据archive失败 - $e');
      Log.e('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// 解析元数据
  static Future<BackupMetadata> _parseMetadata(Archive archive) async {
    final metadataFile = archive.files.firstWhere(
      (f) => f.name == _metadataFileName,
    );

    final content = utf8.decode(metadataFile.content as List<int>);
    final json = jsonDecode(content) as Map<String, dynamic>;
    return BackupMetadata.fromJson(json);
  }

  /// 检查版本兼容性
  static Future<CompatibilityInfo> _checkCompatibility(
      BackupMetadata metadata) async {
    final currentPackageInfo = await PackageInfo.fromPlatform();
    final currentVersion = currentPackageInfo.version;
    final zipAppVersion = metadata.appVersion;
    final zipBackupCode = metadata.backupCode;

    // 检查备份版本
    if (zipBackupCode > _backupCode) {
      return CompatibilityInfo(
        level: CompatibilityLevel.incompatible,
        message: '备份版本不匹配（当前: $_backupCode，备份: $zipBackupCode）',
        errors: ['备份文件版本更高，可能导致数据不兼容'],
      );
    }

    // 简单的版本比较逻辑
    if (currentVersion == zipAppVersion) {
      return const CompatibilityInfo(
        level: CompatibilityLevel.compatible,
        message: '版本完全匹配，可以安全导入',
      );
    }

    // 检查主版本号
    final currentMajor = _getMajorVersion(currentVersion);
    final backupMajor = _getMajorVersion(zipAppVersion);

    if (currentMajor != backupMajor) {
      return CompatibilityInfo(
        level: CompatibilityLevel.incompatible,
        message: '应用主版本不匹配（当前: $currentVersion，备份: $zipAppVersion）',
        errors: ['主版本差异可能导致数据不兼容'],
      );
    }

    return CompatibilityInfo(
      level: CompatibilityLevel.warning,
      message: '版本不同但可能兼容（当前: $currentVersion，备份: $zipAppVersion）',
      warnings: ['版本差异可能导致部分功能异常'],
    );
  }

  /// 获取主版本号
  static String _getMajorVersion(String version) {
    final parts = version.split('.');
    return parts.isNotEmpty ? parts[0] : '0';
  }
}
