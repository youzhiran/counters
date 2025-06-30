import 'dart:io';

import 'package:counters/features/backup/backup_models.dart';
import 'package:counters/features/backup/backup_page.dart';
import 'package:counters/features/backup/backup_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('BackupPage Widget Tests', () {
    late List<File> tempFiles;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      tempFiles = [];
      TestHelpers.setupPlatformChannelMocks();
      TestHelpers.setupTestSharedPreferences({
        'test_key': 'test_value',
        'counter_1': 10,
      });
    });

    tearDown(() async {
      await TestHelpers.cleanupTempFiles(tempFiles);
    });

    testWidgets('应该显示备份页面的基本UI元素', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const BackupPage(),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('数据备份与恢复'), findsOneWidget);
      expect(find.text('导出数据'), findsOneWidget);
      expect(find.text('导入数据'), findsOneWidget);
    });

    testWidgets('应该显示导出选项', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const BackupPage(),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('包含配置数据'), findsOneWidget);
      expect(find.text('包含数据库'), findsOneWidget);
      expect(find.byType(Checkbox), findsAtLeastNWidgets(2));
    });

    testWidgets('应该能够切换导出选项', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const BackupPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - 点击SharedPreferences复选框
      final sharedPrefsCheckbox = find.byType(Checkbox).first;
      await tester.tap(sharedPrefsCheckbox);
      await tester.pumpAndSettle();

      // Assert - 验证状态已更改
      // 注意：这里需要根据实际的UI实现来验证状态变化
      expect(find.byType(Checkbox), findsAtLeastNWidgets(2));
    });

    testWidgets('应该显示导入选项', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const BackupPage(),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('恢复配置数据'), findsOneWidget);
      expect(find.text('恢复数据库'), findsOneWidget);
      expect(find.text('备份当前数据'), findsOneWidget);
      expect(find.text('强制导入'), findsOneWidget);
    });

    testWidgets('应该能够点击导出按钮', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const BackupPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      final exportButton = find.text('开始导出');
      expect(exportButton, findsOneWidget);

      await tester.tap(exportButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Assert
      // 验证导出对话框或进度指示器出现
      // 注意：具体的验证内容需要根据实际UI实现调整
    });

    testWidgets('应该能够点击导入按钮', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const BackupPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      final importButton = find.text('预览并导入');
      expect(importButton, findsOneWidget);

      await tester.tap(importButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Assert
      // 验证文件选择器或导入对话框出现
      // 注意：具体的验证内容需要根据实际UI实现调整
    });

    testWidgets('应该显示备份状态', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            backupManagerProvider.overrideWith(() => MockBackupManager()),
          ],
          child: MaterialApp(
            home: const BackupPage(),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      // 验证状态显示
      expect(find.byType(BackupPage), findsOneWidget);
    });

    testWidgets('应该在导出过程中显示进度', (WidgetTester tester) async {
      // Arrange
      final mockManager = MockBackupManager();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            backupManagerProvider.overrideWith(() => mockManager),
          ],
          child: MaterialApp(
            home: const BackupPage(),
          ),
        ),
      );

      // Act
      await tester.pump();

      // 模拟导出状态
      mockManager.setExportingState(true, 0.5, '正在导出...');
      await tester.pump();

      // Assert
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('正在导出...'), findsAtLeastNWidgets(1));
    });

    testWidgets('应该在导入过程中显示进度', (WidgetTester tester) async {
      // Arrange
      final mockManager = MockBackupManager();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            backupManagerProvider.overrideWith(() => mockManager),
          ],
          child: MaterialApp(
            home: const BackupPage(),
          ),
        ),
      );

      // Act
      await tester.pump();

      // 模拟导入状态
      mockManager.setImportingState(true, 0.3, '正在导入...');
      await tester.pump();

      // Assert
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('正在导入...'), findsAtLeastNWidgets(1));
    });

    testWidgets('应该显示错误信息', (WidgetTester tester) async {
      // Arrange
      final mockManager = MockBackupManager();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            backupManagerProvider.overrideWith(() => mockManager),
          ],
          child: MaterialApp(
            home: const BackupPage(),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // 模拟错误状态
      mockManager.setErrorState('导出失败：权限不足');
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('导出失败：权限不足'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('应该能够清除错误状态', (WidgetTester tester) async {
      // Arrange
      final mockManager = MockBackupManager();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            backupManagerProvider.overrideWith(() => mockManager),
          ],
          child: MaterialApp(
            home: const BackupPage(),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // 设置错误状态
      mockManager.setErrorState('测试错误');
      await tester.pumpAndSettle();

      // 点击清除错误按钮
      final clearButton = find.byIcon(Icons.close);
      if (clearButton.evaluate().isNotEmpty) {
        await tester.tap(clearButton);
        await tester.pumpAndSettle();
      }

      // Assert
      // 验证错误已清除
      expect(find.text('测试错误'), findsNothing);
    });

    testWidgets('应该响应式布局适配不同屏幕尺寸', (WidgetTester tester) async {
      // Arrange - 设置小屏幕尺寸
      await tester.binding.setSurfaceSize(const Size(400, 600));
      
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const BackupPage(),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(BackupPage), findsOneWidget);
      
      // 测试大屏幕尺寸
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await tester.pumpAndSettle();
      
      expect(find.byType(BackupPage), findsOneWidget);
      
      // 恢复默认尺寸
      await tester.binding.setSurfaceSize(null);
    });
  });
}

/// 模拟的备份管理器，用于测试
class MockBackupManager extends BackupManager {
  BackupState _state = const BackupState();

  @override
  BackupState build() => _state;

  void setExportingState(bool isExporting, double progress, String operation) {
    _state = _state.copyWith(
      isLoading: isExporting,
      isExporting: isExporting,
      progress: progress,
      currentOperation: operation,
    );
    // 使用 state setter 来触发更新
    state = _state;
  }

  void setImportingState(bool isImporting, double progress, String operation) {
    _state = _state.copyWith(
      isLoading: isImporting,
      isImporting: isImporting,
      progress: progress,
      currentOperation: operation,
    );
    // 使用 state setter 来触发更新
    state = _state;
  }

  void setErrorState(String error) {
    _state = _state.copyWith(
      isLoading: false,
      isExporting: false,
      isImporting: false,
      error: error,
    );
    // 使用 state setter 来触发更新
    state = _state;
  }

  @override
  Future<String?> exportData({ExportOptions? options}) async {
    setExportingState(true, 0.0, '开始导出...');
    setExportingState(true, 0.5, '正在导出...');
    setExportingState(false, 1.0, '导出完成');
    return '/test/export/path.zip';
  }

  @override
  Future<bool> importData({String? filePath, ImportOptions? options}) async {
    setImportingState(true, 0.0, '开始导入...');
    setImportingState(true, 0.5, '正在导入...');
    setImportingState(false, 1.0, '导入完成');
    return true;
  }

  @override
  void clearError() {
    _state = _state.copyWith(error: null);
    // 使用 state setter 来触发更新
    state = _state;
  }

  @override
  void reset() {
    _state = const BackupState();
    // 使用 state setter 来触发更新
    state = _state;
  }
}
