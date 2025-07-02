import 'package:counters/app/state.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/common/widgets/message_overlay.dart';
import 'package:counters/features/backup/backup_models.dart';
import 'package:counters/features/backup/backup_preview_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 备份预览页面
class BackupPreviewPage extends ConsumerStatefulWidget {
  final String filePath;
  final VoidCallback? onConfirmImport;
  final VoidCallback? onCancel;

  const BackupPreviewPage({
    super.key,
    required this.filePath,
    this.onConfirmImport,
    this.onCancel,
  });

  @override
  ConsumerState<BackupPreviewPage> createState() => _BackupPreviewPageState();
}

class _BackupPreviewPageState extends ConsumerState<BackupPreviewPage> {
  @override
  void initState() {
    super.initState();
    // 开始分析备份文件
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(backupPreviewManagerProvider.notifier)
          .analyzeBackupFile(widget.filePath);
    });
  }

  @override
  Widget build(BuildContext context) {
    final previewState = ref.watch(backupPreviewManagerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('备份预览'),
        leading: IconButton(
          onPressed: () {
            widget.onCancel?.call();
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 内容区域
            Expanded(
              child: _buildContent(previewState),
            ),
            
            const SizedBox(height: 16),
            
            // 按钮区域
            _buildActionButtons(previewState),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(PreviewState state) {
    if (state.isLoading || state.isAnalyzing || state.isCheckingCompatibility) {
      String loadingText = '正在分析备份文件...';
      if (state.isCheckingCompatibility) {
        loadingText = '正在检查版本兼容性...';
      } else if (state.isAnalyzing) {
        loadingText = '正在分析备份文件...';
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(loadingText),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '分析失败',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      );
    }

    if (state.previewInfo == null) {
      return const Center(
        child: Text('无法获取预览信息'),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 警告信息
          _buildWarningSection(state.previewInfo!),

          // 兼容性检查结果
          if (state.previewInfo!.compatibilityInfo != null)
            _buildCompatibilitySection(state.previewInfo!.compatibilityInfo!),
          if (state.previewInfo!.compatibilityInfo != null)

            // 文件完整性状态
            _buildIntegritySection(state.previewInfo!),

          // 备份基本信息
          _buildBasicInfoSection(state.previewInfo!),

          // 数据统计
          _buildDataStatisticsSection(state.previewInfo!),

          // 数据类型
          _buildDataTypesSection(state.previewInfo!),
        ],
      ),
    );
  }

  Widget _buildCompatibilitySection(CompatibilityInfo compatibilityInfo) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color getColorForLevel(CompatibilityLevel level) {
      switch (level) {
        case CompatibilityLevel.compatible:
          return isDark ? Colors.green.shade300 : Colors.green.shade700;
        case CompatibilityLevel.warning:
          return isDark ? Colors.orange.shade300 : Colors.orange.shade700;
        case CompatibilityLevel.incompatible:
          return isDark ? Colors.red.shade300 : Colors.red.shade700;
      }
    }

    Color getBackgroundColorForLevel(CompatibilityLevel level) {
      if (isDark) {
        switch (level) {
          case CompatibilityLevel.compatible:
            return Colors.green.shade900.withValues(alpha: 0.3);
          case CompatibilityLevel.warning:
            return Colors.orange.shade900.withValues(alpha: 0.3);
          case CompatibilityLevel.incompatible:
            return Colors.red.shade900.withValues(alpha: 0.3);
        }
      } else {
        switch (level) {
          case CompatibilityLevel.compatible:
            return Colors.green.shade50;
          case CompatibilityLevel.warning:
            return Colors.orange.shade50;
          case CompatibilityLevel.incompatible:
            return Colors.red.shade50;
        }
      }
    }

    Color getWarningTextColor() {
      return isDark ? Colors.orange.shade300 : Colors.orange.shade800;
    }

    Color getErrorTextColor() {
      return isDark ? Colors.red.shade300 : Colors.red.shade800;
    }

    IconData getIconForLevel(CompatibilityLevel level) {
      switch (level) {
        case CompatibilityLevel.compatible:
          return Icons.check_circle;
        case CompatibilityLevel.warning:
          return Icons.warning;
        case CompatibilityLevel.incompatible:
          return Icons.error;
      }
    }

    String getTitleForLevel(CompatibilityLevel level) {
      switch (level) {
        case CompatibilityLevel.compatible:
          return '版本兼容';
        case CompatibilityLevel.warning:
          return '兼容性警告';
        case CompatibilityLevel.incompatible:
          return '版本不兼容';
      }
    }

    return Card(
      color: getBackgroundColorForLevel(compatibilityInfo.level),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  getIconForLevel(compatibilityInfo.level),
                  color: getColorForLevel(compatibilityInfo.level),
                ),
                const SizedBox(width: 8),
                Text(
                  getTitleForLevel(compatibilityInfo.level),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: getColorForLevel(compatibilityInfo.level),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              compatibilityInfo.message,
              style: TextStyle(
                color: getColorForLevel(compatibilityInfo.level),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (compatibilityInfo.warnings?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(
                '警告:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: getWarningTextColor(),
                ),
              ),
              ...compatibilityInfo.warnings!.map(
                (warning) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Text(
                    '• $warning',
                    style: TextStyle(color: getWarningTextColor()),
                  ),
                ),
              ),
            ],
            if (compatibilityInfo.errors?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(
                '错误:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: getErrorTextColor(),
                ),
              ),
              ...compatibilityInfo.errors!.map(
                (error) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Text(
                    '• $error',
                    style: TextStyle(color: getErrorTextColor()),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIntegritySection(BackupPreviewInfo previewInfo) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final successColor = isDark ? Colors.green.shade300 : Colors.green.shade700;
    final errorColor = isDark ? Colors.red.shade300 : Colors.red.shade700;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  previewInfo.hashValid ? Icons.verified : Icons.warning,
                  color: previewInfo.hashValid ? successColor : errorColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '文件完整性',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  previewInfo.hashValid ? Icons.check_circle : Icons.error,
                  size: 16,
                  color: previewInfo.hashValid ? successColor : errorColor,
                ),
                const SizedBox(width: 4),
                Text(
                  previewInfo.hashValid ? '文件哈希验证通过' : '文件哈希验证失败',
                  style: TextStyle(
                    color: previewInfo.hashValid ? successColor : errorColor,
                  ),
                ),
              ],
            ),
            if (!previewInfo.hashValid) ...[
              const SizedBox(height: 4),
              Text(
                previewInfo.hashError ?? '此备份文件没有哈希或哈希验证失败',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection(BackupPreviewInfo previewInfo) {
    final metadata = previewInfo.metadata;
    final createTime = DateTime.fromMillisecondsSinceEpoch(metadata.timestamp);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '备份信息',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildInfoRow('创建时间',
                '${createTime.year}-${createTime.month.toString().padLeft(2, '0')}-${createTime.day.toString().padLeft(2, '0')} ${createTime.hour.toString().padLeft(2, '0')}:${createTime.minute.toString().padLeft(2, '0')}'),
            _buildInfoRow('应用版本', metadata.appVersion),
            _buildInfoRow('构建号', metadata.buildNumber),
            _buildInfoRow('平台', metadata.platform),
            _buildInfoRow('备份版本', metadata.backupCode.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildDataStatisticsSection(BackupPreviewInfo previewInfo) {
    final stats = previewInfo.dataStatistics;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '数据统计',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildInfoRow('配置项数量', '${stats['sharedPreferencesCount'] ?? 0} 项'),
            _buildInfoRow('数据库文件', '${stats['databaseFilesCount'] ?? 0} 个'),
            if (stats['totalSize'] != null)
              _buildInfoRow('总大小', _formatFileSize(stats['totalSize'] as int)),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTypesSection(BackupPreviewInfo previewInfo) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '包含的数据类型',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...previewInfo.dataTypes.map((type) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(type),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningSection(BackupPreviewInfo previewInfo) {
    final warnings = <String>[];

    // 基本警告
    warnings.add('导入操作将覆盖现有的所有数据');
    warnings.add('建议在导入前备份当前数据');

    // 根据完整性状态添加警告
    if (!previewInfo.hashValid) {
      warnings.add('文件完整性验证失败，请谨慎操作');
    }

    // 根据兼容性状态添加警告
    if (previewInfo.compatibilityInfo != null) {
      final compatibility = previewInfo.compatibilityInfo!;
      if (compatibility.level == CompatibilityLevel.warning) {
        warnings.add('版本差异可能导致部分功能异常');
      } else if (compatibility.level == CompatibilityLevel.incompatible) {
        warnings.add('版本不兼容，强制导入可能导致严重问题');
      }
    } else {
      warnings.add('无法检查版本兼容性，请谨慎操作');
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final warningColor = isDark ? Colors.orange.shade300 : Colors.orange.shade700;
    final warningTextColor = isDark ? Colors.orange.shade300 : Colors.orange.shade800;
    final warningBackgroundColor = isDark
        ? Colors.orange.shade900.withValues(alpha: 0.3)
        : Colors.orange.shade50;

    return Card(
      color: warningBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning,
                  color: warningColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '重要提醒',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: warningTextColor,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              warnings.map((warning) => '• $warning').join('\n'),
              style: TextStyle(
                color: warningTextColor,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(PreviewState state) {
    final canImport = state.previewInfo != null && state.error == null;
    final hasIntegrityIssue = state.previewInfo?.hashValid == false;
    final compatibilityInfo = state.previewInfo?.compatibilityInfo;
    final hasCompatibilityIssue =
        compatibilityInfo?.level == CompatibilityLevel.warning ||
            compatibilityInfo?.level == CompatibilityLevel.incompatible;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              widget.onCancel?.call();
              Navigator.of(context).pop();
            },
            child: const Text('取消'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: canImport
                ? () {
                    if (hasIntegrityIssue || hasCompatibilityIssue) {
                      // 显示综合警告对话框
                      _showRiskWarningDialog(
                          hasIntegrityIssue, compatibilityInfo);
                    } else {
                      _confirmImport();
                    }
                  }
                : null,
            child: const Text('确认导入'),
          ),
        ),
      ],
    );
  }

  void _showRiskWarningDialog(
      bool hasIntegrityIssue, CompatibilityInfo? compatibilityInfo) {
    final warnings = <String>[];

    if (hasIntegrityIssue) {
      warnings.add('文件完整性验证失败，文件可能已被修改或损坏');
    }

    if (compatibilityInfo != null) {
      if (compatibilityInfo.level == CompatibilityLevel.warning) {
        warnings.add('版本差异可能导致部分功能异常');
      } else if (compatibilityInfo.level == CompatibilityLevel.incompatible) {
        warnings.add('版本不兼容，可能导致严重问题');
      }
    }

    String title = '导入风险警告';
    if (hasIntegrityIssue &&
        compatibilityInfo?.level == CompatibilityLevel.incompatible) {
      title = '严重风险警告';
    } else if (hasIntegrityIssue) {
      title = '文件完整性警告';
    } else if (compatibilityInfo?.level == CompatibilityLevel.incompatible) {
      title = '版本兼容性警告';
    }

    globalState.showCommonDialog(
      child: AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '检测到以下风险：',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            ...warnings.map((warning) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $warning'),
                )),
            const SizedBox(height: 12),
            const Text(
              '继续导入可能会导致数据损坏或应用异常。\n\n'
              '您确定要继续吗？',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmImport();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('继续导入'),
          ),
        ],
      ),
    );
  }

  void _confirmImport() {
    Log.i('BackupPreviewPage: 用户确认导入备份文件');
    ref.showMessage('开始导入备份数据...');
    widget.onConfirmImport?.call();
    Navigator.of(context).pop();
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
