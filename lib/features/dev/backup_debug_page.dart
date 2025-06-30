import 'dart:io';

import 'package:counters/common/utils/log.dart';
import 'package:counters/common/widgets/page_transitions.dart';
import 'package:counters/features/backup/backup_models.dart';
import 'package:counters/features/backup/backup_preview_page.dart';
import 'package:counters/features/backup/backup_provider.dart';
import 'package:counters/features/setting/data_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

/// 备份调试页面
class BackupDebugPage extends ConsumerStatefulWidget {
  const BackupDebugPage({super.key});

  @override
  ConsumerState<BackupDebugPage> createState() => _BackupDebugPageState();
}

class _BackupDebugPageState extends ConsumerState<BackupDebugPage> {
  String? _lastBackupPath;
  final List<String> _debugLogs = [];

  @override
  Widget build(BuildContext context) {
    final backupState = ref.watch(backupManagerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('备份调试'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 数据库状态检查
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '数据库状态检查',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _checkDatabaseStatus,
                      child: const Text('检查数据库文件'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 备份操作
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '备份操作',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: backupState.isLoading ? null : _performBackup,
                          child: const Text('执行备份'),
                        ),
                        const SizedBox(width: 8),
                        if (_lastBackupPath != null)
                          ElevatedButton(
                            onPressed: _previewBackup,
                            child: const Text('预览备份'),
                          ),
                      ],
                    ),
                    if (backupState.isLoading)
                      Column(
                        children: [
                          const SizedBox(height: 8),
                          LinearProgressIndicator(value: backupState.progress),
                          const SizedBox(height: 4),
                          Text(backupState.currentOperation ?? '处理中...'),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 调试日志
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '调试日志',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _debugLogs.clear();
                              });
                            },
                            child: const Text('清除'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              _debugLogs.join('\n'),
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addLog(String message) {
    setState(() {
      final timestamp = DateTime.now().toString().substring(11, 19);
      _debugLogs.add('[$timestamp] $message');
    });
    Log.d('BackupDebug: $message');
  }

  Future<void> _checkDatabaseStatus() async {
    try {
      _addLog('开始检查数据库状态...');
      
      final dataDir = await DataManager.getCurrentDataDir();
      _addLog('数据目录: $dataDir');
      
      final dbDir = Directory(path.join(dataDir, 'databases'));
      _addLog('数据库目录: ${dbDir.path}');
      
      if (await dbDir.exists()) {
        _addLog('数据库目录存在');
        
        final files = await dbDir.list().toList();
        _addLog('数据库目录中的文件数量: ${files.length}');
        
        for (final file in files) {
          if (file is File) {
            final stat = await file.stat();
            _addLog('文件: ${path.basename(file.path)} (${stat.size} bytes)');
          }
        }
      } else {
        _addLog('数据库目录不存在');
      }
    } catch (e) {
      _addLog('检查数据库状态失败: $e');
    }
  }

  Future<void> _performBackup() async {
    try {
      _addLog('开始执行备份...');
      
      final backupPath = await ref.read(backupManagerProvider.notifier).exportData(
        options: const ExportOptions(
          includeSharedPreferences: true,
          includeDatabases: true,
        ),
      );
      
      if (backupPath != null) {
        _addLog('备份成功: $backupPath');
        setState(() {
          _lastBackupPath = backupPath;
        });
        
        // 检查备份文件大小
        final file = File(backupPath);
        final stat = await file.stat();
        _addLog('备份文件大小: ${stat.size} bytes');
      } else {
        _addLog('备份失败');
      }
    } catch (e) {
      _addLog('备份过程中发生错误: $e');
    }
  }

  Future<void> _previewBackup() async {
    if (_lastBackupPath == null) return;
    
    try {
      _addLog('开始预览备份文件...');
      
      if (!mounted) return;
      
      Navigator.of(context).pushWithSlide(
        BackupPreviewPage(
          filePath: _lastBackupPath!,
          onConfirmImport: () {
            _addLog('用户确认导入');
          },
          onCancel: () {
            _addLog('用户取消导入');
          },
        ),
        direction: SlideDirection.fromRight,
        duration: const Duration(milliseconds: 300),
      );
    } catch (e) {
      _addLog('预览备份文件失败: $e');
    }
  }
}
