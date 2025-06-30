import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:counters/features/backup/backup_models.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 测试辅助工具类
class TestHelpers {
  /// 创建测试用的备份元数据
  static BackupMetadata createTestMetadata({
    String appVersion = '1.0.0',
    String buildNumber = '1',
    int? timestamp,
    String platform = 'test',
    int backupCode = 1,
  }) {
    return BackupMetadata(
      appVersion: appVersion,
      buildNumber: buildNumber,
      timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch,
      platform: platform,
      backupCode: backupCode,
    );
  }

  /// 创建测试用的数据库文件信息
  static DatabaseFile createTestDatabaseFile({
    String name = 'test.db',
    String relativePath = 'databases/test.db',
    int size = 1024,
    String? checksum,
  }) {
    return DatabaseFile(
      name: name,
      relativePath: relativePath,
      size: size,
      checksum: checksum ?? 'test_checksum',
    );
  }

  /// 创建测试用的备份数据
  static BackupData createTestBackupData({
    BackupMetadata? metadata,
    Map<String, dynamic>? sharedPreferences,
    List<DatabaseFile>? databases,
  }) {
    return BackupData(
      metadata: metadata ?? createTestMetadata(),
      sharedPreferences: sharedPreferences ?? {'test_key': 'test_value'},
      databases: databases ?? [createTestDatabaseFile()],
    );
  }

  /// 创建测试用的ZIP文件数据
  static Uint8List createTestZipData({
    BackupData? backupData,
    Map<String, Uint8List>? databaseData,
    bool includeHash = true,
    bool corruptHash = false,
  }) {
    final testBackupData = backupData ?? createTestBackupData();

    // 创建内部数据ZIP (backup_data.zip)
    final dataArchive = Archive();

    // 添加元数据文件 (backup_metadata.json)
    final metadataJson = jsonEncode(testBackupData.metadata.toJson());
    dataArchive.addFile(ArchiveFile(
      'backup_metadata.json',
      metadataJson.length,
      Uint8List.fromList(utf8.encode(metadataJson)),
    ));

    // 添加SharedPreferences数据
    final prefsJson = jsonEncode(testBackupData.sharedPreferences);
    dataArchive.addFile(ArchiveFile(
      'shared_preferences.json',
      prefsJson.length,
      Uint8List.fromList(utf8.encode(prefsJson)),
    ));

    // 添加数据库文件
    if (databaseData != null) {
      // 使用提供的数据库数据
      for (final entry in databaseData.entries) {
        dataArchive.addFile(ArchiveFile(
          'databases/${entry.key}',
          entry.value.length,
          entry.value,
        ));
      }
    } else {
      // 根据 backupData.databases 创建数据库文件
      for (final dbFile in testBackupData.databases) {
        final dbData = Uint8List.fromList([1, 2, 3, 4]); // 模拟数据库内容
        dataArchive.addFile(ArchiveFile(
          dbFile.relativePath,
          dbData.length,
          dbData,
        ));
      }
    }

    // 编码内部数据ZIP
    final dataZipData = ZipEncoder().encode(dataArchive);

    // 创建外层ZIP
    final outerArchive = Archive();

    // 添加内层数据ZIP
    outerArchive.addFile(ArchiveFile(
      'backup_data.zip',
      dataZipData.length,
      Uint8List.fromList(dataZipData),
    ));

    // 如果需要，添加哈希文件
    if (includeHash) {
      final correctHash = sha256.convert(dataZipData).toString();
      final hashValue = corruptHash ? 'corrupted_hash_value_for_testing' : correctHash;

      final hashInfo = {
        'algorithm': 'SHA-256',
        'hash': hashValue,
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      };
      final hashJson = jsonEncode(hashInfo);
      outerArchive.addFile(ArchiveFile(
        'backup_hash.json',
        hashJson.length,
        Uint8List.fromList(utf8.encode(hashJson)),
      ));
    }

    return Uint8List.fromList(ZipEncoder().encode(outerArchive));
  }

  /// 创建测试用的兼容性信息
  static CompatibilityInfo createTestCompatibilityInfo({
    CompatibilityLevel level = CompatibilityLevel.compatible,
    String message = '完全兼容',
    List<String>? warnings,
    List<String>? errors,
  }) {
    return CompatibilityInfo(
      level: level,
      message: message,
      warnings: warnings,
      errors: errors,
    );
  }

  /// 创建测试用的哈希信息
  static HashInfo createTestHashInfo({
    String algorithm = 'SHA-256',
    String? hash,
    String? timestamp,
  }) {
    return HashInfo(
      algorithm: algorithm,
      hash: hash ?? 'test_hash_value',
      timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  /// 创建测试用的预览信息
  static BackupPreviewInfo createTestPreviewInfo({
    BackupMetadata? metadata,
    Map<String, dynamic>? dataStatistics,
    List<String>? dataTypes,
    bool hasHash = true,
    bool hashValid = true,
    String? hashError,
    CompatibilityInfo? compatibilityInfo,
  }) {
    return BackupPreviewInfo(
      metadata: metadata ?? createTestMetadata(),
      dataStatistics: dataStatistics ?? {
        'sharedPreferencesCount': 5,
        'databaseFilesCount': 2,
        'countersCount': 10,
      },
      dataTypes: dataTypes ?? ['配置数据', '计数器数据'],
      hasHash: hasHash,
      hashValid: hashValid,
      hashError: hashError,
      compatibilityInfo: compatibilityInfo ?? createTestCompatibilityInfo(),
    );
  }

  /// 设置测试用的SharedPreferences
  static void setupTestSharedPreferences(Map<String, dynamic> values) {
    // 转换为 Map<String, Object> 以符合 SharedPreferences 的要求
    final Map<String, Object> convertedValues = {};
    for (final entry in values.entries) {
      if (entry.value != null) {
        convertedValues[entry.key] = entry.value;
      }
    }
    SharedPreferences.setMockInitialValues(convertedValues);
  }

  /// 创建临时测试文件
  static Future<File> createTempFile(String content, {String? extension}) async {
    final tempDir = Directory.systemTemp;
    final fileName = 'test_${DateTime.now().millisecondsSinceEpoch}${extension ?? '.tmp'}';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(content);
    return file;
  }

  /// 创建临时测试ZIP文件
  static Future<File> createTempZipFile(Uint8List zipData) async {
    final tempDir = Directory.systemTemp;
    final fileName = 'test_backup_${DateTime.now().millisecondsSinceEpoch}.zip';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(zipData);
    return file;
  }

  /// 清理临时文件
  static Future<void> cleanupTempFiles(List<File> files) async {
    for (final file in files) {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // 忽略删除错误
      }
    }
  }

  /// 模拟平台方法调用
  static void setupPlatformChannelMocks() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getApplicationDocumentsDirectory':
            return '/test/documents';
          case 'getTemporaryDirectory':
            return '/test/temp';
          default:
            return null;
        }
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/package_info'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getAll':
            return {
              'appName': 'Test App',
              'packageName': 'com.test.app',
              'version': '1.0.0',
              'buildNumber': '1',
            };
          default:
            return null;
        }
      },
    );

    // 模拟权限检查
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'checkPermissionStatus':
          case 'requestPermissions':
            // 在测试环境中，总是返回已授权状态
            return 1; // PermissionStatus.granted
          default:
            return null;
        }
      },
    );
  }

  /// 验证错误处理调用
  static void verifyErrorHandling(Function testFunction) {
    expect(testFunction, throwsA(isA<Exception>()));
  }

  /// 创建测试用的导出选项
  static ExportOptions createTestExportOptions({
    bool includeSharedPreferences = true,
    bool includeDatabases = true,
    String? customPath,
    String? customFileName,
  }) {
    return ExportOptions(
      includeSharedPreferences: includeSharedPreferences,
      includeDatabases: includeDatabases,
      customPath: customPath,
      customFileName: customFileName,
    );
  }

  /// 创建测试用的导入选项
  static ImportOptions createTestImportOptions({
    bool importSharedPreferences = true,
    bool importDatabases = true,
    bool createBackup = true,
    bool forceImport = false,
  }) {
    return ImportOptions(
      importSharedPreferences: importSharedPreferences,
      importDatabases: importDatabases,
      createBackup: createBackup,
      forceImport: forceImport,
    );
  }
}
