import 'dart:io';

import 'package:counters/features/backup/backup_models.dart';
import 'package:counters/features/backup/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('BackupService', () {
    late List<File> tempFiles;

    setUpAll(() {
      // 初始化 Flutter 测试绑定
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      tempFiles = [];
      TestHelpers.setupPlatformChannelMocks();
      TestHelpers.setupTestSharedPreferences({
        'test_key_1': 'test_value_1',
        'test_key_2': 42,
        'test_key_3': true,
        'test_key_4': 3.14,
      });
    });

    tearDown(() async {
      await TestHelpers.cleanupTempFiles(tempFiles);
    });

    group('exportData', () {
      test('应该在导出过程中报告进度', () async {
        // Arrange
        final options = TestHelpers.createTestExportOptions();
        final progressValues = <double>[];

        // Act
        await BackupService.exportData(
          options: options,
          onProgress: (message, progress) {
            progressValues.add(progress);
          },
        );

        // Assert
        expect(progressValues, isNotEmpty);
        expect(progressValues.first, equals(0.0));
        expect(progressValues.last, equals(1.0));

        // 验证进度是递增的
        for (int i = 1; i < progressValues.length; i++) {
          expect(
              progressValues[i], greaterThanOrEqualTo(progressValues[i - 1]));
        }
      });

      test('应该处理导出错误', () async {
        // Arrange - 使用包含无效字符的路径（在Windows上无法创建）
        final options = TestHelpers.createTestExportOptions(
          customPath: 'C:\\invalid<>path|with*invalid?chars',
        );

        // Act & Assert
        expect(
          () => BackupService.exportData(
            options: options,
            onProgress: (message, progress) {},
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('importData', () {
      test('应该成功导入有效的ZIP文件', () async {
        // Arrange
        final testZipData = TestHelpers.createTestZipData();
        final tempZipFile = await TestHelpers.createTempZipFile(testZipData);
        tempFiles.add(tempZipFile);

        final options =
            TestHelpers.createTestImportOptions(createBackup: false);
        final progressMessages = <String>[];

        // Act
        await BackupService.importData(
          zipPath: tempZipFile.path,
          options: options,
          onProgress: (message, progress) {
            progressMessages.add(message);
          },
        );

        // Assert
        expect(progressMessages, isNotEmpty);
        expect(progressMessages.first, equals('开始导入...'));
      });

      test('应该验证ZIP文件格式', () async {
        // Arrange
        final invalidZipFile = await TestHelpers.createTempFile(
            'invalid zip content',
            extension: '.zip');
        tempFiles.add(invalidZipFile);

        final options = TestHelpers.createTestImportOptions();

        // Act & Assert
        expect(
          () => BackupService.importData(
            zipPath: invalidZipFile.path,
            options: options,
            onProgress: (message, progress) {},
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('应该验证文件完整性', () async {
        // Arrange
        final testZipData = TestHelpers.createTestZipData(includeHash: false);
        final tempZipFile = await TestHelpers.createTempZipFile(testZipData);
        tempFiles.add(tempZipFile);

        final options = TestHelpers.createTestImportOptions(forceImport: false);

        // Act & Assert
        expect(
          () => BackupService.importData(
            zipPath: tempZipFile.path,
            options: options,
            onProgress: (message, progress) {},
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('应该支持强制导入', () async {
        // Arrange - 创建包含错误哈希的测试数据来模拟完整性验证失败
        final testZipData =
            TestHelpers.createTestZipData(includeHash: true, corruptHash: true);
        final tempZipFile = await TestHelpers.createTempZipFile(testZipData);
        tempFiles.add(tempZipFile);

        final options = TestHelpers.createTestImportOptions(
          forceImport: true,
          createBackup: false,
        );

        // Act & Assert
        await expectLater(
          BackupService.importData(
            zipPath: tempZipFile.path,
            options: options,
            onProgress: (message, progress) {},
          ),
          completes,
        );
      });

      test('应该处理版本不兼容的情况', () async {
        // Arrange
        final incompatibleMetadata = TestHelpers.createTestMetadata(
          appVersion: '999.0.0', // 假设这是不兼容的版本
          backupCode: 999,
        );
        final testZipData = TestHelpers.createTestZipData(
          backupData:
              TestHelpers.createTestBackupData(metadata: incompatibleMetadata),
        );
        final tempZipFile = await TestHelpers.createTempZipFile(testZipData);
        tempFiles.add(tempZipFile);

        final options = TestHelpers.createTestImportOptions(forceImport: false);

        // Act & Assert
        // 注意：实际的兼容性检查逻辑可能需要根据具体实现调整
        expect(
          () => BackupService.importData(
            zipPath: tempZipFile.path,
            options: options,
            onProgress: (message, progress) {},
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('应该在导入过程中报告进度', () async {
        // Arrange
        final testZipData = TestHelpers.createTestZipData();
        final tempZipFile = await TestHelpers.createTempZipFile(testZipData);
        tempFiles.add(tempZipFile);

        final options =
            TestHelpers.createTestImportOptions(createBackup: false);
        final progressValues = <double>[];

        // Act
        await BackupService.importData(
          zipPath: tempZipFile.path,
          options: options,
          onProgress: (message, progress) {
            progressValues.add(progress);
          },
        );

        // Assert
        expect(progressValues, isNotEmpty);
        expect(progressValues.first, equals(0.0));

        // 验证进度是递增的
        for (int i = 1; i < progressValues.length; i++) {
          expect(
              progressValues[i], greaterThanOrEqualTo(progressValues[i - 1]));
        }
      });
    });

    group('verifyFileIntegrity', () {
      test('应该验证有效的文件完整性', () async {
        // Arrange
        final testZipData = TestHelpers.createTestZipData();
        final tempZipFile = await TestHelpers.createTempZipFile(testZipData);
        tempFiles.add(tempZipFile);

        // Act
        final isValid =
            await BackupService.verifyFileIntegrity(tempZipFile.path);

        // Assert
        expect(isValid, isTrue);
      });

      test('应该拒绝无哈希文件的完整性验证', () async {
        // Arrange
        final testZipData = TestHelpers.createTestZipData(includeHash: false);
        final tempZipFile = await TestHelpers.createTempZipFile(testZipData);
        tempFiles.add(tempZipFile);

        // Act
        final isValid =
            await BackupService.verifyFileIntegrity(tempZipFile.path);

        // Assert
        expect(isValid, isFalse);
      });

      test('应该处理不存在的文件', () async {
        // Act
        final isValid =
            await BackupService.verifyFileIntegrity('/non/existent/file.zip');

        // Assert
        expect(isValid, isFalse);
      });
    });

    group('checkZipCompatibility', () {
      test('应该检查兼容的ZIP文件', () async {
        // Arrange
        final testZipData = TestHelpers.createTestZipData();
        final tempZipFile = await TestHelpers.createTempZipFile(testZipData);
        tempFiles.add(tempZipFile);

        // Act
        final compatibility =
            await BackupService.checkZipCompatibility(tempZipFile.path);

        // Assert
        expect(compatibility, isNotNull);
        expect(compatibility.level, isA<CompatibilityLevel>());
        expect(compatibility.message, isNotEmpty);
      });

      test('应该处理无效的ZIP文件', () async {
        // Arrange
        final invalidZipFile = await TestHelpers.createTempFile(
            'invalid content',
            extension: '.zip');
        tempFiles.add(invalidZipFile);

        // Act
        final compatibility =
            await BackupService.checkZipCompatibility(invalidZipFile.path);

        // Assert
        expect(compatibility.level, CompatibilityLevel.incompatible);
        expect(compatibility.message, '无法读取备份文件或文件已损坏');
        expect(compatibility.errors, contains('文件格式错误或文件损坏'));
      });

      test('应该处理不存在的文件', () async {
        // Act
        final compatibility =
            await BackupService.checkZipCompatibility('/non/existent/file.zip');

        // Assert
        expect(compatibility.level, CompatibilityLevel.incompatible);
        expect(compatibility.message, '无法读取备份文件或文件已损坏');
        expect(compatibility.errors, contains('文件格式错误或文件损坏'));
      });
    });

    group('错误处理', () {
      test('exportData 应该处理权限错误', () async {
        // Arrange - 使用包含无效字符的路径来模拟权限错误
        final options = TestHelpers.createTestExportOptions(
          customPath: 'C:\\Windows\\System32\\restricted<>path',
        );

        // Act & Assert
        expect(
          () => BackupService.exportData(
            options: options,
            onProgress: (message, progress) {},
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('importData 应该处理文件读取错误', () async {
        // Arrange
        final options = TestHelpers.createTestImportOptions();

        // Act & Assert
        expect(
          () => BackupService.importData(
            zipPath: '/non/existent/file.zip',
            options: options,
            onProgress: (message, progress) {},
          ),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
