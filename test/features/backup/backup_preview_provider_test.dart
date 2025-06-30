import 'dart:io';

import 'package:counters/features/backup/backup_models.dart';
import 'package:counters/features/backup/backup_preview_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('BackupPreviewProvider', () {
    late ProviderContainer container;
    late List<File> tempFiles;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      tempFiles = [];
      TestHelpers.setupPlatformChannelMocks();
      TestHelpers.setupTestSharedPreferences({
        'test_key_1': 'test_value_1',
        'test_key_2': 42,
        'counter_data': 'some_counter_data',
        'mahjong_settings': 'mahjong_config',
        'poker_preferences': 'poker_config',
      });

      container = ProviderContainer();
    });

    tearDown(() async {
      container.dispose();
      await TestHelpers.cleanupTempFiles(tempFiles);
    });

    group('BackupPreviewManager', () {
      test('应该有正确的初始状态', () {
        // Act
        final notifier = container.read(backupPreviewManagerProvider.notifier);
        final state = notifier.state;

        // Assert
        expect(state.isLoading, isFalse);
        expect(state.isAnalyzing, isFalse);
        expect(state.isCheckingCompatibility, isFalse);
        expect(state.previewInfo, isNull);
        expect(state.error, isNull);
        expect(state.selectedFilePath, isNull);
      });

      test('analyzeBackupFile 应该成功分析有效的备份文件', () async {
        // Arrange
        final testZipData = TestHelpers.createTestZipData();
        final tempZipFile = await TestHelpers.createTempZipFile(testZipData);
        tempFiles.add(tempZipFile);

        final notifier = container.read(backupPreviewManagerProvider.notifier);

        // Act
        await notifier.analyzeBackupFile(tempZipFile.path);

        // Assert
        final state = notifier.state;
        expect(state.isLoading, isFalse);
        expect(state.isAnalyzing, isFalse);
        expect(state.isCheckingCompatibility, isFalse);
        expect(state.previewInfo, isNotNull);
        expect(state.error, isNull);
        expect(state.selectedFilePath, equals(tempZipFile.path));

        // 验证预览信息
        final previewInfo = state.previewInfo!;
        expect(previewInfo.metadata, isNotNull);
        expect(previewInfo.dataStatistics, isNotEmpty);
        expect(previewInfo.dataTypes, isNotEmpty);
        expect(previewInfo.hasHash, isTrue);
        expect(previewInfo.hashValid, isTrue);
        expect(previewInfo.compatibilityInfo, isNotNull);
      });

      test('analyzeBackupFile 应该在分析过程中更新状态', () async {
        // Arrange
        final testZipData = TestHelpers.createTestZipData();
        final tempZipFile = await TestHelpers.createTempZipFile(testZipData);
        tempFiles.add(tempZipFile);

        final notifier = container.read(backupPreviewManagerProvider.notifier);
        final stateChanges = <PreviewState>[];

        // 监听状态变化
        container.listen(backupPreviewManagerProvider, (previous, next) {
          stateChanges.add(next);
        });

        // Act
        await notifier.analyzeBackupFile(tempZipFile.path);

        // Assert
        expect(stateChanges, isNotEmpty);

        // 检查是否有加载状态
        final hasLoadingState = stateChanges.any((state) => state.isLoading);
        expect(hasLoadingState, isTrue);

        // 检查是否有分析状态
        final hasAnalyzingState =
            stateChanges.any((state) => state.isAnalyzing);
        expect(hasAnalyzingState, isTrue);

        // 检查最终状态
        final finalState = stateChanges.last;
        expect(finalState.isLoading, isFalse);
        expect(finalState.isAnalyzing, isFalse);
        expect(finalState.previewInfo, isNotNull);
      });

      test('analyzeBackupFile 应该处理无效的ZIP文件', () async {
        // Arrange
        final invalidFile = await TestHelpers.createTempFile(
            'invalid zip content',
            extension: '.zip');
        tempFiles.add(invalidFile);

        final notifier = container.read(backupPreviewManagerProvider.notifier);

        // Act
        await notifier.analyzeBackupFile(invalidFile.path);

        // Assert
        final state = notifier.state;
        expect(state.isLoading, isFalse);
        expect(state.isAnalyzing, isFalse);
        expect(state.error, isNotNull);
        expect(state.previewInfo, isNull);
      });

      test('analyzeBackupFile 应该处理不存在的文件', () async {
        // Arrange
        final notifier = container.read(backupPreviewManagerProvider.notifier);

        // Act
        await notifier.analyzeBackupFile('/non/existent/file.zip');

        // Assert
        final state = notifier.state;
        expect(state.isLoading, isFalse);
        expect(state.error, isNotNull);
        expect(state.previewInfo, isNull);
      });

      test('analyzeBackupFile 应该正确检测哈希完整性', () async {
        // Arrange - 创建没有哈希的ZIP文件
        final testZipDataNoHash =
            TestHelpers.createTestZipData(includeHash: false);
        final tempZipFileNoHash =
            await TestHelpers.createTempZipFile(testZipDataNoHash);
        tempFiles.add(tempZipFileNoHash);

        final notifier = container.read(backupPreviewManagerProvider.notifier);

        // Act
        await notifier.analyzeBackupFile(tempZipFileNoHash.path);

        // Assert
        final state = notifier.state;
        expect(state.previewInfo, isNotNull);
        expect(state.previewInfo!.hasHash, isFalse);
        expect(state.previewInfo!.hashValid, isFalse);
      });

      test('analyzeBackupFile 应该正确识别数据类型', () async {
        // Arrange - 创建包含特定数据库文件的备份
        final dbFiles = [
          TestHelpers.createTestDatabaseFile(name: 'counter.db'),
          TestHelpers.createTestDatabaseFile(name: 'mahjong_sessions.db'),
          TestHelpers.createTestDatabaseFile(name: 'poker50_games.db'),
        ];
        final backupData = TestHelpers.createTestBackupData(databases: dbFiles);
        final testZipData =
            TestHelpers.createTestZipData(backupData: backupData);
        final tempZipFile = await TestHelpers.createTempZipFile(testZipData);
        tempFiles.add(tempZipFile);

        final notifier = container.read(backupPreviewManagerProvider.notifier);

        // Act
        await notifier.analyzeBackupFile(tempZipFile.path);

        // Assert
        final state = notifier.state;
        expect(state.previewInfo, isNotNull);

        final dataTypes = state.previewInfo!.dataTypes;
        expect(dataTypes, contains('应用设置')); // SharedPreferences
        expect(dataTypes, contains('数据库文件 (1个)')); // database files
      });

      test('analyzeBackupFile 应该正确统计数据', () async {
        // Arrange
        final sharedPrefs = {
          'key1': 'value1',
          'key2': 'value2',
          'key3': 'value3',
        };
        final dbFiles = [
          TestHelpers.createTestDatabaseFile(name: 'db1.db'),
          TestHelpers.createTestDatabaseFile(name: 'db2.db'),
        ];
        final backupData = TestHelpers.createTestBackupData(
          sharedPreferences: sharedPrefs,
          databases: dbFiles,
        );
        final testZipData =
            TestHelpers.createTestZipData(backupData: backupData);
        final tempZipFile = await TestHelpers.createTempZipFile(testZipData);
        tempFiles.add(tempZipFile);

        final notifier = container.read(backupPreviewManagerProvider.notifier);

        // Act
        await notifier.analyzeBackupFile(tempZipFile.path);

        // Assert
        final state = notifier.state;
        expect(state.previewInfo, isNotNull);

        final statistics = state.previewInfo!.dataStatistics;
        expect(statistics['sharedPreferencesCount'], equals(3));
        expect(statistics['databaseFilesCount'], equals(1));
      });

      test('clearPreview 应该清除预览状态', () async {
        // Arrange
        final testZipData = TestHelpers.createTestZipData();
        final tempZipFile = await TestHelpers.createTempZipFile(testZipData);
        tempFiles.add(tempZipFile);

        final notifier = container.read(backupPreviewManagerProvider.notifier);

        // 先分析文件
        await notifier.analyzeBackupFile(tempZipFile.path);
        expect(notifier.state.previewInfo, isNotNull);

        // Act
        notifier.clearPreview();

        // Assert
        final state = notifier.state;
        expect(state.isLoading, isFalse);
        expect(state.isAnalyzing, isFalse);
        expect(state.isCheckingCompatibility, isFalse);
        expect(state.previewInfo, isNull);
        expect(state.error, isNull);
        expect(state.selectedFilePath, isNull);
      });

      test('getCurrentDataStatistics 应该返回当前数据统计', () async {
        // Arrange
        final notifier = container.read(backupPreviewManagerProvider.notifier);

        // Act
        final statistics = await notifier.getCurrentDataStatistics();

        // Assert
        expect(statistics, isNotNull);
        expect(statistics, isA<Map<String, dynamic>>());
        expect(statistics['currentSharedPreferencesCount'], isA<int>());
        expect(statistics['currentCountersCount'], isA<int>());
        expect(statistics['currentMahjongSessionsCount'], isA<int>());
        expect(statistics['currentPoker50SessionsCount'], isA<int>());
        expect(statistics['currentTemplatesCount'], isA<int>());
      });

      test('getCurrentDataStatistics 应该正确统计SharedPreferences数量', () async {
        // Arrange
        final notifier = container.read(backupPreviewManagerProvider.notifier);

        // Act
        final statistics = await notifier.getCurrentDataStatistics();

        // Assert
        // 我们在setUp中设置了5个SharedPreferences键
        expect(statistics['currentSharedPreferencesCount'], equals(5));
      });

      test('analyzeBackupFile 应该处理兼容性检查', () async {
        // Arrange
        final testZipData = TestHelpers.createTestZipData();
        final tempZipFile = await TestHelpers.createTempZipFile(testZipData);
        tempFiles.add(tempZipFile);

        final notifier = container.read(backupPreviewManagerProvider.notifier);

        // Act
        await notifier.analyzeBackupFile(tempZipFile.path);

        // Assert
        final state = notifier.state;
        expect(state.previewInfo, isNotNull);
        expect(state.previewInfo!.compatibilityInfo, isNotNull);

        final compatibility = state.previewInfo!.compatibilityInfo!;
        expect(compatibility.level, isA<CompatibilityLevel>());
        expect(compatibility.message, isNotEmpty);
      });

      test('analyzeBackupFile 应该处理损坏的哈希', () async {
        // Arrange - 使用 corruptHash 参数创建损坏哈希的测试数据
        final testZipData = TestHelpers.createTestZipData(corruptHash: true);
        final tempZipFile = await TestHelpers.createTempZipFile(testZipData);
        tempFiles.add(tempZipFile);

        final notifier = container.read(backupPreviewManagerProvider.notifier);

        // Act
        await notifier.analyzeBackupFile(tempZipFile.path);

        // Assert
        final state = notifier.state;
        expect(state.previewInfo, isNotNull);
        expect(state.previewInfo!.hasHash, isTrue);
        expect(state.previewInfo!.hashValid, isFalse);
        expect(state.previewInfo!.hashError, isNotNull);
      });
    });

    group('错误处理', () {
      test('应该处理文件读取权限错误', () async {
        // Arrange
        final notifier = container.read(backupPreviewManagerProvider.notifier);

        // Act
        await notifier.analyzeBackupFile('/root/restricted_file.zip');

        // Assert
        final state = notifier.state;
        expect(state.error, isNotNull);
        expect(state.previewInfo, isNull);
      });

      test('应该处理JSON解析错误', () async {
        // Arrange - 创建包含无效JSON的ZIP文件
        final invalidJsonFile = await TestHelpers.createTempFile(
            'invalid json content',
            extension: '.zip');
        tempFiles.add(invalidJsonFile);

        final notifier = container.read(backupPreviewManagerProvider.notifier);

        // Act
        await notifier.analyzeBackupFile(invalidJsonFile.path);

        // Assert
        final state = notifier.state;
        expect(state.error, isNotNull);
        expect(state.previewInfo, isNull);
      });
    });
  });
}
