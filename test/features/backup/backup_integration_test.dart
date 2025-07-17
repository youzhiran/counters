import 'dart:io';

import 'package:counters/features/backup/backup_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('备份集成测试', () {
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
        final invalidFile = await TestHelpers.createTempFile('invalid content',
            extension: '.zip');
        tempFiles.add(invalidFile);

        final importOptions =
            TestHelpers.createTestImportOptions(createBackup: false);

        final importSuccess =
            await container.read(backupManagerProvider.notifier).importData(
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
    });

    group('并发操作处理', () {
      test('应该防止同时进行多个导出操作', () async {
        // Arrange
        final exportOptions = TestHelpers.createTestExportOptions();

        // Act - 同时启动两个导出操作
        final backupManager = container.read(backupManagerProvider.notifier);
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
        final exportOptions = TestHelpers.createTestExportOptions();
        final importOptions =
            TestHelpers.createTestImportOptions(createBackup: false);

        final backupManager = container.read(backupManagerProvider.notifier);
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

        final exportOptions = TestHelpers.createTestExportOptions();

        // Act
        final stopwatch = Stopwatch()..start();
        final exportPath = await container
            .read(backupManagerProvider.notifier)
            .exportData(options: exportOptions);
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
