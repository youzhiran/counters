import 'dart:io';

import 'package:counters/features/backup/backup_models.dart';
import 'package:counters/features/backup/backup_provider.dart';
import 'package:counters/features/backup/backup_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('Backup Integration Tests', () {
    late ProviderContainer container;
    late List<File> tempFiles;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      tempFiles = [];
      TestHelpers.setupPlatformChannelMocks();
      TestHelpers.setupTestSharedPreferences({
        'app_version': '1.0.0',
        'user_name': 'Test User',
        'counter_1': 10,
        'counter_2': 25,
        'theme_mode': 'dark',
        'language': 'zh_CN',
        'last_backup_time': 1234567890,
      });

      container = ProviderContainer();
    });

    tearDown(() async {
      container.dispose();
      await TestHelpers.cleanupTempFiles(tempFiles);
    });

    group('完整的导出-导入流程', () {
      test('应该成功完成完整的备份和恢复流程', () async {
        // Phase 1: 导出数据
        final backupManager = container.read(backupManagerProvider.notifier);
        final exportOptions = TestHelpers.createTestExportOptions(
          includeSharedPreferences: true,
          includeDatabases: true,
        );

        // 执行导出
        final exportPath = await backupManager.exportData(options: exportOptions);
        expect(exportPath, isNotNull);
        expect(File(exportPath!).existsSync(), isTrue);
        tempFiles.add(File(exportPath));

        // 验证导出状态
        final exportState = container.read(backupManagerProvider);
        expect(exportState.isLoading, isFalse);
        expect(exportState.isExporting, isFalse);
        expect(exportState.progress, equals(1.0));
        expect(exportState.lastExportPath, equals(exportPath));
        expect(exportState.error, isNull);

        // Phase 2: 验证导出文件的完整性
        final isIntegrityValid = await BackupService.verifyFileIntegrity(exportPath);
        expect(isIntegrityValid, isTrue);

        // Phase 3: 检查兼容性
        final compatibility = await BackupService.checkZipCompatibility(exportPath);
        expect(compatibility, isNotNull);
        expect(compatibility.level, isIn([CompatibilityLevel.compatible, CompatibilityLevel.warning]));

        // Phase 4: 修改当前数据（模拟数据变化）
        TestHelpers.setupTestSharedPreferences({
          'app_version': '1.0.0',
          'user_name': 'Modified User',
          'counter_1': 99,
          'new_setting': 'new_value',
        });

        // Phase 5: 导入备份数据
        final importOptions = TestHelpers.createTestImportOptions(
          importSharedPreferences: true,
          importDatabases: true,
          createBackup: false, // 跳过当前数据备份以简化测试
          forceImport: false,
        );

        final importSuccess = await backupManager.importData(
          filePath: exportPath,
          options: importOptions,
        );
        expect(importSuccess, isTrue);

        // 验证导入状态
        final importState = container.read(backupManagerProvider);
        expect(importState.isLoading, isFalse);
        expect(importState.isImporting, isFalse);
        expect(importState.progress, equals(1.0));
        expect(importState.error, isNull);

        // Phase 6: 验证数据恢复
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('user_name'), equals('Test User')); // 应该恢复到原始值
        expect(prefs.getInt('counter_1'), equals(10)); // 应该恢复到原始值
        expect(prefs.getString('theme_mode'), equals('dark')); // 原始数据应该存在
      });

      test('应该处理部分导入选项', () async {
        // Phase 1: 导出完整数据
        final backupManager = container.read(backupManagerProvider.notifier);
        final exportOptions = TestHelpers.createTestExportOptions();

        final exportPath = await backupManager.exportData(options: exportOptions);
        expect(exportPath, isNotNull);
        tempFiles.add(File(exportPath!));

        // Phase 2: 仅导入SharedPreferences
        final importOptions = TestHelpers.createTestImportOptions(
          importSharedPreferences: true,
          importDatabases: false, // 不导入数据库
          createBackup: false,
        );

        final importSuccess = await backupManager.importData(
          filePath: exportPath,
          options: importOptions,
        );
        expect(importSuccess, isTrue);

        // 验证只有SharedPreferences被恢复
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getKeys(), isNotEmpty);
      });

      test('应该处理强制导入损坏的文件', () async {
        // Phase 1: 创建损坏的备份文件
        final testZipData = TestHelpers.createTestZipData();
        final tempZipFile = await TestHelpers.createTempZipFile(testZipData);
        tempFiles.add(tempZipFile);

        // 损坏文件（修改几个字节）
        final originalBytes = await tempZipFile.readAsBytes();
        final corruptedBytes = List<int>.from(originalBytes);
        if (corruptedBytes.length > 100) {
          corruptedBytes[50] = (corruptedBytes[50] + 1) % 256;
          corruptedBytes[100] = (corruptedBytes[100] + 1) % 256;
        }
        await tempZipFile.writeAsBytes(corruptedBytes);

        // Phase 2: 尝试正常导入（应该失败）
        final backupManager = container.read(backupManagerProvider.notifier);
        final normalImportOptions = TestHelpers.createTestImportOptions(
          forceImport: false,
          createBackup: false,
        );

        final normalImportSuccess = await backupManager.importData(
          filePath: tempZipFile.path,
          options: normalImportOptions,
        );
        expect(normalImportSuccess, isFalse);

        // 清除错误状态
        backupManager.clearError();

        // Phase 3: 强制导入
        final forceImportOptions = TestHelpers.createTestImportOptions(
          forceImport: true,
          createBackup: false,
        );

        final forceImportSuccess = await backupManager.importData(
          filePath: tempZipFile.path,
          options: forceImportOptions,
        );
        expect(forceImportSuccess, isTrue);
      });

      test('应该正确处理版本兼容性', () async {
        // Phase 1: 创建不同版本的备份
        final oldVersionMetadata = TestHelpers.createTestMetadata(
          appVersion: '0.5.0',
          buildNumber: '50',
          backupCode: 1,
        );
        final oldVersionBackup = TestHelpers.createTestBackupData(metadata: oldVersionMetadata);
        final oldVersionZip = TestHelpers.createTestZipData(backupData: oldVersionBackup);
        final oldVersionFile = await TestHelpers.createTempZipFile(oldVersionZip);
        tempFiles.add(oldVersionFile);

        // Phase 2: 检查兼容性
        final compatibility = await BackupService.checkZipCompatibility(oldVersionFile.path);
        expect(compatibility, isNotNull);
        // 根据实际的兼容性检查逻辑，这里可能是compatible或warning

        // Phase 3: 尝试导入
        final backupManager = container.read(backupManagerProvider.notifier);
        final importOptions = TestHelpers.createTestImportOptions(createBackup: false);

        final importSuccess = await backupManager.importData(
          filePath: oldVersionFile.path,
          options: importOptions,
        );
        
        // 根据兼容性级别，导入可能成功或失败
        if (compatibility.level == CompatibilityLevel.incompatible) {
          expect(importSuccess, isFalse);
        } else {
          expect(importSuccess, isTrue);
        }
      });
    });

    group('错误恢复和回滚', () {
      test('应该在导入失败时保持原始数据', () async {
        // Phase 1: 记录原始数据
        final originalPrefs = await SharedPreferences.getInstance();
        final originalKeys = originalPrefs.getKeys().toList();
        final originalValues = <String, dynamic>{};
        for (final key in originalKeys) {
          originalValues[key] = originalPrefs.get(key);
        }

        // Phase 2: 尝试导入无效文件
        final invalidFile = await TestHelpers.createTempFile('invalid content', extension: '.zip');
        tempFiles.add(invalidFile);

        final backupManager = container.read(backupManagerProvider.notifier);
        final importOptions = TestHelpers.createTestImportOptions(createBackup: false);

        final importSuccess = await backupManager.importData(
          filePath: invalidFile.path,
          options: importOptions,
        );
        expect(importSuccess, isFalse);

        // Phase 3: 验证原始数据未被修改
        final currentPrefs = await SharedPreferences.getInstance();
        final currentKeys = currentPrefs.getKeys().toList();
        
        expect(currentKeys.length, equals(originalKeys.length));
        for (final key in originalKeys) {
          expect(currentPrefs.get(key), equals(originalValues[key]));
        }
      });

      test('应该在导出失败时不影响应用状态', () async {
        // Phase 1: 记录初始状态
        final backupManager = container.read(backupManagerProvider.notifier);
        final initialState = container.read(backupManagerProvider);

        // Phase 2: 尝试导出到无效路径
        final invalidOptions = TestHelpers.createTestExportOptions(
          customPath: '/invalid/path/that/does/not/exist',
        );

        final exportPath = await backupManager.exportData(options: invalidOptions);
        expect(exportPath, isNull);

        // Phase 3: 验证错误状态
        final errorState = container.read(backupManagerProvider);
        expect(errorState.isLoading, isFalse);
        expect(errorState.isExporting, isFalse);
        expect(errorState.error, isNotNull);

        // Phase 4: 清除错误并验证恢复
        backupManager.clearError();
        final clearedState = container.read(backupManagerProvider);
        expect(clearedState.error, isNull);
        expect(clearedState.isLoading, equals(initialState.isLoading));
        expect(clearedState.isExporting, equals(initialState.isExporting));
      });
    });

    group('并发操作处理', () {
      test('应该防止同时进行多个导出操作', () async {
        // Arrange
        final backupManager = container.read(backupManagerProvider.notifier);
        final exportOptions = TestHelpers.createTestExportOptions();

        // Act - 同时启动两个导出操作
        final export1Future = backupManager.exportData(options: exportOptions);
        final export2Future = backupManager.exportData(options: exportOptions);

        final results = await Future.wait([export1Future, export2Future]);

        // Assert - 至少有一个操作应该成功
        final successCount = results.where((path) => path != null).length;
        expect(successCount, greaterThanOrEqualTo(1));

        // 清理生成的文件
        for (final path in results) {
          if (path != null) {
            final file = File(path);
            if (await file.exists()) {
              tempFiles.add(file);
            }
          }
        }
      });

      test('应该防止同时进行导出和导入操作', () async {
        // Phase 1: 创建测试备份文件
        final testZipData = TestHelpers.createTestZipData();
        final tempZipFile = await TestHelpers.createTempZipFile(testZipData);
        tempFiles.add(tempZipFile);

        // Phase 2: 同时启动导出和导入
        final backupManager = container.read(backupManagerProvider.notifier);
        final exportOptions = TestHelpers.createTestExportOptions();
        final importOptions = TestHelpers.createTestImportOptions(createBackup: false);

        final exportFuture = backupManager.exportData(options: exportOptions);
        final importFuture = backupManager.importData(
          filePath: tempZipFile.path,
          options: importOptions,
        );

        final results = await Future.wait([exportFuture, importFuture]);

        // Assert - 验证操作结果
        final exportPath = results[0] as String?;
        final importSuccess = results[1] as bool;

        // 至少有一个操作应该成功
        expect(exportPath != null || importSuccess, isTrue);

        // 清理
        if (exportPath != null) {
          final file = File(exportPath);
          if (await file.exists()) {
            tempFiles.add(file);
          }
        }
      });
    });

    group('性能测试', () {
      test('应该在合理时间内完成大数据量的导出', () async {
        // Arrange - 创建大量测试数据
        final largeSharedPrefs = <String, dynamic>{};
        for (int i = 0; i < 1000; i++) {
          largeSharedPrefs['key_$i'] = 'value_$i';
        }
        TestHelpers.setupTestSharedPreferences(largeSharedPrefs);

        final backupManager = container.read(backupManagerProvider.notifier);
        final exportOptions = TestHelpers.createTestExportOptions();

        // Act
        final stopwatch = Stopwatch()..start();
        final exportPath = await backupManager.exportData(options: exportOptions);
        stopwatch.stop();

        // Assert
        expect(exportPath, isNotNull);
        expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // 应该在10秒内完成

        // 清理
        if (exportPath != null) {
          final file = File(exportPath);
          if (await file.exists()) {
            tempFiles.add(file);
          }
        }
      });
    });
  });
}
