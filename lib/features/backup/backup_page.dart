import 'dart:io';

import 'package:counters/app/state.dart';
import 'package:counters/common/utils/error_handler.dart';
import 'package:counters/common/widgets/message_overlay.dart';
import 'package:counters/common/widgets/page_transitions.dart';
import 'package:counters/features/backup/backup_models.dart';
import 'package:counters/features/backup/backup_preview_page.dart';
import 'package:counters/features/backup/backup_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key});

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  @override
  void initState() {
    super.initState();
    // 移除自动扫描，改为按需扫描
  }

  @override
  Widget build(BuildContext context) {
    final backupState = ref.watch(backupManagerProvider);
    final exportOptions = ref.watch(exportOptionsManagerProvider);
    final importOptions = ref.watch(importOptionsManagerProvider);
    final backupFilesState = ref.watch(backupFilesManagerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('数据备份与恢复'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: '使用说明',
            onPressed: _showUsageDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 状态显示区域
            if (backupState.isLoading) _buildProgressCard(backupState),
            if (backupState.error != null) _buildErrorCard(backupState.error!),

            const SizedBox(height: 16),

            // 导出区域
            _buildExportSection(exportOptions),

            const SizedBox(height: 24),

            // 导入区域
            _buildImportSection(importOptions),

            const SizedBox(height: 24),

            // 还原区域
            _buildRestoreSection(backupFilesState),
          ],
        ),
      ),
    );
  }

  /// 构建进度卡片
  Widget _buildProgressCard(BackupState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(
                  state.isExporting ? '正在导出...' : '正在导入...',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: state.progress),
            const SizedBox(height: 8),
            if (state.currentOperation != null)
              Text(
                state.currentOperation!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }

  /// 构建错误卡片
  Widget _buildErrorCard(String error) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                ref.read(backupManagerProvider.notifier).clearError();
              },
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建导出区域
  Widget _buildExportSection(ExportOptions options) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.upload,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '导出数据',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 导出选项
            CheckboxListTile(
              title: const Text('包含配置数据'),
              subtitle: const Text('SharedPreferences中的所有设置'),
              value: options.includeSharedPreferences,
              onChanged: (value) {
                ref.read(exportOptionsManagerProvider.notifier)
                    .toggleSharedPreferences();
              },
            ),
            CheckboxListTile(
              title: const Text('包含数据库'),
              subtitle: const Text('所有SQLite数据库文件'),
              value: options.includeDatabases,
              onChanged: (value) {
                ref.read(exportOptionsManagerProvider.notifier)
                    .toggleDatabases();
              },
            ),

            const SizedBox(height: 16),

            // 导出按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _canExport(options) ? _handleExport : null,
                icon: const Icon(Icons.file_upload_outlined),
                label: const Text('开始导出'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建导入区域
  Widget _buildImportSection(ImportOptions options) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.download,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '导入数据',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 导入选项
            CheckboxListTile(
              title: const Text('恢复配置数据'),
              subtitle: const Text('覆盖当前的应用设置'),
              value: options.importSharedPreferences,
              onChanged: (value) {
                ref.read(importOptionsManagerProvider.notifier)
                    .toggleSharedPreferences();
              },
            ),
            CheckboxListTile(
              title: const Text('恢复数据库'),
              subtitle: const Text('覆盖当前的数据库文件'),
              value: options.importDatabases,
              onChanged: (value) {
                ref.read(importOptionsManagerProvider.notifier)
                    .toggleDatabases();
              },
            ),
            CheckboxListTile(
              title: const Text('备份当前数据'),
              subtitle: const Text('导入前自动备份现有数据，提供安全保障'),
              value: options.createBackup,
              onChanged: (value) {
                ref.read(importOptionsManagerProvider.notifier)
                    .toggleCreateBackup();
              },
            ),
            CheckboxListTile(
              title: const Text('强制导入'),
              subtitle: const Text('忽略版本兼容性警告'),
              value: options.forceImport,
              onChanged: (value) {
                ref.read(importOptionsManagerProvider.notifier)
                    .toggleForceImport();
              },
            ),

            const SizedBox(height: 16),

            // 导入按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _canImport(options) ? _handlePreviewImport : null,
                icon: const Icon(Icons.preview),
                label: const Text('预览并导入'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建还原区域
  Widget _buildRestoreSection(BackupFilesState backupFilesState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.restore,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  '还原备份',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '从已有的自动备份文件中还原数据，不会自动备份当前数据',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // 还原按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showRestoreDialog(),
                icon: const Icon(Icons.restore),
                label: const Text('选择备份文件还原'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示还原对话框
  Future<void> _showRestoreDialog() async {
    // 先扫描备份文件
    await ref.read(backupFilesManagerProvider.notifier).scanBackupFiles();

    if (!mounted) return;

    final backupFilesState = ref.read(backupFilesManagerProvider);

    if (backupFilesState.error != null) {
      ref.showWarning('扫描备份文件失败: ${backupFilesState.error}');
      return;
    }

    if (backupFilesState.backupFiles.isEmpty) {
      ref.showWarning('未找到可用的备份文件');
      return;
    }

    // 使用 showCommonDialog 显示备份文件选择对话框
    await globalState.showCommonDialog<void>(
      child: _RestoreDialog(
        backupFiles: backupFilesState.backupFiles,
        onRestore: _handleRestoreBackup,
        onDelete: _handleDeleteBackup,
        onExport: _handleExportBackup,
      ),
    );
  }



  /// 显示使用说明对话框
  Future<void> _showUsageDialog() async {
    await globalState.showCommonDialog<void>(
      child: AlertDialog(
        title: const Text('使用说明'),
        content: const SingleChildScrollView(
          child: Text(
            '• 导出功能会将您的配置和数据打包成ZIP文件，并生成哈希\n'
            '• 使用"预览并导入"功能，可查看备份详情和验证文件完整性\n'
            '• 导入前会自动验证文件完整性和哈希\n'
            '• 强烈建议在导入前备份当前数据，提供安全保障\n'
            '• "还原备份"功能直接从备份文件还原数据，不会自动备份当前数据\n'
            '• 版本不同的备份文件可能存在兼容性问题\n'
            '• 导入和还原操作会覆盖现有数据，请谨慎操作\n'
            '• 如果操作失败，系统会自动尝试恢复原始数据',
            style: TextStyle(height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => globalState.navigatorKey.currentState?.pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 检查是否可以导出
  bool _canExport(ExportOptions options) {
    final backupState = ref.read(backupManagerProvider);
    return !backupState.isLoading &&
           (options.includeSharedPreferences || options.includeDatabases);
  }

  /// 检查是否可以导入
  bool _canImport(ImportOptions options) {
    final backupState = ref.read(backupManagerProvider);
    return !backupState.isLoading &&
           (options.importSharedPreferences || options.importDatabases);
  }



  /// 处理导出
  Future<void> _handleExport() async {
    try {
      // 显示导出配置对话框
      final exportConfig = await _showExportConfigDialog();
      if (exportConfig == null) {
        // 用户取消
        return;
      }

      // 获取当前导出选项并设置自定义配置
      final currentOptions = ref.read(exportOptionsManagerProvider);
      final exportOptions = currentOptions.copyWith(
        customPath: exportConfig['directory'],
        customFileName: exportConfig['fileName'],
      );

      final result = await ref.read(backupManagerProvider.notifier)
          .exportData(options: exportOptions);

      if (result != null && mounted) {
        ref.showSuccess('数据导出成功！\n文件保存至: $result');
      }
    } catch (e) {
      // 检查是否是权限相关错误
      if (e.toString().contains('权限')) {
        await _handlePermissionError(e.toString());
      } else {
        ErrorHandler.handle(e, StackTrace.current, prefix: '导出操作失败');
      }
    }
  }



  /// 处理预览导入
  Future<void> _handlePreviewImport() async {
    try {
      // 选择备份文件
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        dialogTitle: '选择备份文件',
      );

      if (result == null || result.files.isEmpty) {
        return; // 用户取消选择
      }

      final filePath = result.files.first.path;
      if (filePath == null) {
        ref.showWarning('无法获取文件路径');
        return;
      }

      // 导航到预览页面
      if (mounted) {
        Navigator.of(context).pushWithSlide(
          BackupPreviewPage(
            filePath: filePath,
            onConfirmImport: () => _executeImport(filePath),
            onCancel: () {
              // 预览取消，不执行任何操作
            },
          ),
          direction: SlideDirection.fromRight,
          duration: const Duration(milliseconds: 300),
        );
      }
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '预览导入失败');
    }
  }

  /// 执行导入操作
  Future<void> _executeImport(String filePath) async {
    try {
      final importOptions = ref.read(importOptionsManagerProvider);
      final success = await ref.read(backupManagerProvider.notifier)
          .importDataFromFile(filePath, options: importOptions);

      if (success && mounted) {
        ref.showSuccess('数据导入成功！\n请重启应用以应用所有更改。');
      }
    } catch (e) {
      // 检查是否是权限相关错误
      if (e.toString().contains('权限')) {
        await _handlePermissionError(e.toString());
      } else {
        ErrorHandler.handle(e, StackTrace.current, prefix: '导入操作失败');
      }
    }
  }

  /// 处理还原备份
  Future<void> _handleRestoreBackup(BackupFileInfo backupFile) async {
    try {
      // 导航到预览页面
      if (mounted) {
        Navigator.of(context).pushWithSlide(
          BackupPreviewPage(
            filePath: backupFile.filePath,
            onConfirmImport: () => _executeRestore(backupFile.filePath),
            onCancel: () {
              // 预览取消，不执行任何操作
            },
          ),
          direction: SlideDirection.fromRight,
          duration: const Duration(milliseconds: 300),
        );
      }
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '预览还原失败');
    }
  }

  /// 执行还原操作
  Future<void> _executeRestore(String filePath) async {
    try {
      // 使用默认的还原选项（还原所有数据，不强制还原）
      const restoreOptions = RestoreOptions(
        restoreSharedPreferences: true,
        restoreDatabases: true,
        forceRestore: false,
      );

      final success = await ref.read(backupManagerProvider.notifier)
          .restoreDataFromFile(filePath, options: restoreOptions);

      if (success && mounted) {
        ref.showSuccess('数据还原成功！\n请重启应用以应用所有更改。');
      }
    } catch (e) {
      // 检查是否是权限相关错误
      if (e.toString().contains('权限')) {
        await _handlePermissionError(e.toString());
      } else {
        ErrorHandler.handle(e, StackTrace.current, prefix: '还原操作失败');
      }
    }
  }

  /// 处理删除备份文件
  Future<void> _handleDeleteBackup(BackupFileInfo backupFile) async {
    try {
      // 显示删除确认对话框
      final confirmed = await globalState.showCommonDialog<bool>(
        child: AlertDialog(
          title: const Text('删除备份文件'),
          content: Text('确定要删除备份文件 "${backupFile.fileName}" 吗？\n此操作不可撤销！'),
          actions: [
            TextButton(
              onPressed: () => globalState.navigatorKey.currentState?.pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => globalState.navigatorKey.currentState?.pop(true),
              child: const Text('删除', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // 删除文件
      final file = File(backupFile.filePath);
      if (await file.exists()) {
        await file.delete();
        ref.showSuccess('备份文件删除成功');

        // 重新扫描备份文件列表
        await ref.read(backupFilesManagerProvider.notifier).scanBackupFiles();
      } else {
        ref.showWarning('备份文件不存在');
      }
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '删除备份文件失败');
    }
  }

  /// 处理导出备份文件
  Future<void> _handleExportBackup(BackupFileInfo backupFile) async {
    try {
      // 选择保存位置
      final selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '选择备份文件导出位置',
      );

      if (selectedDirectory == null) {
        return; // 用户取消选择
      }

      // 复制文件到选择的位置
      final sourceFile = File(backupFile.filePath);
      if (!await sourceFile.exists()) {
        ref.showWarning('备份文件不存在');
        return;
      }

      final targetPath = path.join(selectedDirectory, backupFile.fileName);
      final targetFile = File(targetPath);

      // 检查目标文件是否已存在
      if (await targetFile.exists()) {
        final overwrite = await globalState.showCommonDialog<bool>(
          child: AlertDialog(
            title: const Text('文件已存在'),
            content: Text('目标位置已存在文件 "${backupFile.fileName}"，是否覆盖？'),
            actions: [
              TextButton(
                onPressed: () => globalState.navigatorKey.currentState?.pop(false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => globalState.navigatorKey.currentState?.pop(true),
                child: const Text('覆盖', style: TextStyle(color: Colors.orange)),
              ),
            ],
          ),
        );

        if (overwrite != true) return;
      }

      // 复制文件
      await sourceFile.copy(targetPath);
      ref.showSuccess('备份文件导出成功！\n文件保存至: $targetPath');
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '导出备份文件失败');
    }
  }

  /// 显示导出配置对话框
  Future<Map<String, String>?> _showExportConfigDialog() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final defaultFileName = 'counters_backup_$timestamp.zip';

    String? selectedDirectory;
    String fileName = defaultFileName;

    return globalState.showCommonDialog<Map<String, String>>(
      child: StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('导出配置'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 保存位置选择
              const Text('保存位置:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedDirectory ?? '请选择保存位置',
                      style: TextStyle(
                        color: selectedDirectory == null
                            ? Theme.of(context).hintColor
                            : null,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final directory = await FilePicker.platform.getDirectoryPath(
                        dialogTitle: '选择备份文件保存位置',
                      );
                      if (directory != null) {
                        setState(() {
                          selectedDirectory = directory;
                        });
                      }
                    },
                    icon: const Icon(Icons.folder_open),
                    label: const Text('选择'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 文件名输入
              const Text('文件名:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingController(text: fileName.replaceAll('.zip', '')),
                decoration: const InputDecoration(
                  hintText: '输入文件名',
                  suffixText: '.zip',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  final cleanValue = value.trim();
                  if (cleanValue.isEmpty) {
                    fileName = defaultFileName;
                  } else {
                    // 移除可能的.zip后缀，然后重新添加
                    final nameWithoutExtension = cleanValue.replaceAll(RegExp(r'\.zip$', caseSensitive: false), '');
                    fileName = '$nameWithoutExtension.zip';
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => globalState.navigatorKey.currentState?.pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: selectedDirectory == null
                  ? null
                  : () {
                      globalState.navigatorKey.currentState?.pop({
                        'directory': selectedDirectory!,
                        'fileName': fileName,
                      });
                    },
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }






  /// 处理权限错误
  Future<void> _handlePermissionError(String errorMessage) async {
    if (!mounted) return;

    // 显示权限错误对话框
    await globalState.showCommonDialog(
      child: AlertDialog(
        title: const Text('权限不足'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(errorMessage),
              const SizedBox(height: 16),
              const Text(
                '备份功能需要存储权限才能正常工作。请按照以下步骤授权：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                '方法一：授权"所有文件访问权限"（推荐）',
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green),
              ),
              const SizedBox(height: 4),
              const Text('1. 点击"打开设置"按钮'),
              const Text('2. 找到"特殊应用访问权限"或"特殊权限"'),
              const Text('3. 选择"所有文件访问权限"'),
              const Text('4. 开启本应用的权限'),
              const SizedBox(height: 12),
              const Text(
                '方法二：授权存储权限',
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue),
              ),
              const SizedBox(height: 4),
              const Text('1. 点击"打开设置"按钮'),
              const Text('2. 找到"权限"或"应用权限"'),
              const Text('3. 开启"存储"或"文件和媒体"权限'),
              const SizedBox(height: 8),
              const Text('4. 返回应用重试'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // 打开应用设置页面
              await openAppSettings();
            },
            child: const Text('打开设置'),
          ),
        ],
      ),
    );
  }
}

/// 还原对话框组件
class _RestoreDialog extends StatelessWidget {
  final List<BackupFileInfo> backupFiles;
  final Function(BackupFileInfo) onRestore;
  final Function(BackupFileInfo) onDelete;
  final Function(BackupFileInfo) onExport;

  const _RestoreDialog({
    required this.backupFiles,
    required this.onRestore,
    required this.onDelete,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = globalState.isDesktopMode(context);
    final isMobile = !isDesktop;

    // 响应式尺寸计算
    final dialogWidth = isDesktop
        ? screenSize.width * 0.6  // 响应式布局：60% 宽度
        : screenSize.width * 0.9; // 移动布局：90% 宽度

    final dialogHeight = isDesktop
        ? screenSize.height * 0.7  // 响应式布局：70% 高度
        : screenSize.height * 0.8; // 移动布局：80% 高度

    final maxDialogWidth = isDesktop ? 600.0 : double.infinity;

    return AlertDialog(
      title: const Text('管理备份文件'),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxDialogWidth,
          maxHeight: dialogHeight,
        ),
        child: SizedBox(
          width: dialogWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 使用说明
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '点击备份文件可预览并还原，使用下方按钮可删除或导出备份文件',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (backupFiles.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('未找到可用的备份文件'),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: backupFiles.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                    itemBuilder: (context, index) {
                      final backupFile = backupFiles[index];
                      return _buildBackupFileItem(context, backupFile, isMobile);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => globalState.navigatorKey.currentState?.pop(),
          child: const Text('取消'),
        ),
      ],
    );
  }

  Widget _buildBackupFileItem(BuildContext context, BackupFileInfo backupFile, bool isMobile) {
    final fileSize = _formatFileSize(backupFile.fileSize);
    final createdTime = _formatDateTime(backupFile.createdTime);

    if (isMobile) {
      // 手机布局：垂直排列，按钮占满宽度
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 点击区域：文件信息
            InkWell(
              onTap: () {
                globalState.navigatorKey.currentState?.pop();
                onRestore(backupFile);
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.archive,
                          color: Theme.of(context).colorScheme.secondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            backupFile.fileName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 28),
                      child: Text(
                        '$fileSize • $createdTime',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 操作按钮行
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      globalState.navigatorKey.currentState?.pop();
                      onDelete(backupFile);
                    },
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('删除'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      globalState.navigatorKey.currentState?.pop();
                      onExport(backupFile);
                    },
                    icon: const Icon(Icons.file_upload_outlined, size: 16),
                    label: const Text('导出'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      // 平板/桌面布局：水平排列
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        leading: Icon(
          Icons.archive,
          color: Theme.of(context).colorScheme.secondary,
        ),
        title: Text(
          backupFile.fileName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text('$fileSize • $createdTime'),
        onTap: () {
          globalState.navigatorKey.currentState?.pop();
          onRestore(backupFile);
        },
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                globalState.navigatorKey.currentState?.pop();
                onDelete(backupFile);
              },
              icon: const Icon(Icons.delete_outline),
              color: Theme.of(context).colorScheme.error,
              tooltip: '删除',
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () {
                globalState.navigatorKey.currentState?.pop();
                onExport(backupFile);
              },
              icon: const Icon(Icons.file_upload_outlined),
              color: Theme.of(context).colorScheme.primary,
              tooltip: '导出',
            ),
          ],
        ),
      );
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
