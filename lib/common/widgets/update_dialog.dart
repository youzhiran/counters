import 'package:counters/app/state.dart';
import 'package:counters/common/utils/error_handler.dart';
import 'package:counters/common/utils/net.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// 手动检查更新对话框（从设置页面调用）
class UpdateCheckerDialog extends StatefulWidget {
  const UpdateCheckerDialog({super.key});

  @override
  State<UpdateCheckerDialog> createState() => _UpdateCheckerDialogState();
}

class _UpdateCheckerDialogState extends State<UpdateCheckerDialog> {
  bool checkBeta = false;
  bool isLoading = true;
  String versionInfo = '';
  bool hasUpdate = false;

  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    final result =
        await UpdateChecker.isUpdateAvailable(includePrereleases: checkBeta);
    if (mounted) {
      setState(() {
        isLoading = false;
        versionInfo = result;
        hasUpdate = result.startsWith('v');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('检查更新'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CheckboxListTile(
            title: const Text('包含测试版本'),
            value: checkBeta,
            onChanged: isLoading
                ? null
                : (v) {
                    setState(() {
                      checkBeta = v ?? false;
                      isLoading = true;
                      versionInfo = '';
                    });
                    _checkForUpdates();
                  },
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(),
            )
          else
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: SingleChildScrollView(
                child: _buildUpdateContent(theme),
              ),
            ),
        ],
      ),
      actions: [
        if (!isLoading)
          TextButton(
            onPressed: () => globalState.navigatorKey.currentState?.pop(),
            child: Text(hasUpdate ? '稍后再说' : '关闭'),
          ),
        if (hasUpdate)
          TextButton(
            onPressed: () => _launchUpdate(),
            child: const Text('立即更新'),
          ),
      ],
    );
  }

  /// 构建更新内容UI
  Widget _buildUpdateContent(ThemeData theme) {
    if (hasUpdate) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            '发现新版本',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  versionInfo.split('\n')[0],
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  versionInfo.split('\n')[1],
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer
                        .withAlpha((0.8 * 255).toInt()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '更新日志',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              versionInfo.split('\n\n').last,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
          ),
        ],
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          versionInfo,
          style: theme.textTheme.bodyMedium,
        ),
      );
    }
  }

  /// 启动更新
  Future<void> _launchUpdate() async {
    try {
      final navigatorState = Navigator.of(context);
      if (await canLaunchUrl(Uri.parse(UpdateChecker.latestReleaseUrl))) {
        await launchUrl(Uri.parse(UpdateChecker.latestReleaseUrl));
      }
      if (mounted) {
        navigatorState.pop();
      }
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '启动更新失败');
    }
  }
}

/// 更新版本忽略管理工具类
class UpdateIgnoreManager {
  static const String _keyIgnoredVersions = 'ignored_update_versions';

  /// 检查版本是否被忽略
  static Future<bool> isVersionIgnored(String versionInfo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ignoredVersions = prefs.getStringList(_keyIgnoredVersions) ?? [];
      final currentVersion = versionInfo.split('\n')[0]; // 获取版本号
      return ignoredVersions.contains(currentVersion);
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '检查忽略版本失败');
      return false;
    }
  }

  /// 添加版本到忽略列表
  static Future<void> addIgnoredVersion(String versionInfo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentVersion = versionInfo.split('\n')[0]; // 获取版本号

      // 获取已忽略的版本列表
      final ignoredVersions = prefs.getStringList(_keyIgnoredVersions) ?? [];

      // 添加当前版本到忽略列表
      if (!ignoredVersions.contains(currentVersion)) {
        ignoredVersions.add(currentVersion);
        await prefs.setStringList(_keyIgnoredVersions, ignoredVersions);
      }
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '保存忽略版本失败');
    }
  }

  /// 清除所有忽略的版本记录
  static Future<void> clearIgnoredVersions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyIgnoredVersions);
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '清除忽略版本记录失败');
    }
  }
}

/// 启动时更新检查对话框
class StartupUpdateDialog extends StatefulWidget {
  final String versionInfo;
  final bool hasUpdate;

  const StartupUpdateDialog({
    super.key,
    required this.versionInfo,
    required this.hasUpdate,
  });

  @override
  State<StartupUpdateDialog> createState() => _StartupUpdateDialogState();
}

class _StartupUpdateDialogState extends State<StartupUpdateDialog> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('发现新版本'),
      content: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.4,
        ),
        child: SingleChildScrollView(
          child: _buildUpdateContent(theme),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _ignoreThisVersion(),
          child: const Text('忽略本次更新'),
        ),
        TextButton(
          onPressed: () => globalState.navigatorKey.currentState?.pop(),
          child: const Text('稍后再说'),
        ),
        TextButton(
          onPressed: () => _launchUpdate(),
          child: const Text('立即更新'),
        ),
      ],
    );
  }

  /// 构建更新内容UI（与手动检查对话框保持一致）
  Widget _buildUpdateContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.versionInfo.split('\n')[0],
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              Text(
                widget.versionInfo.split('\n')[1],
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer
                      .withAlpha((0.8 * 255).toInt()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '更新日志',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.versionInfo.split('\n\n').last,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  /// 忽略本次更新
  Future<void> _ignoreThisVersion() async {
    await UpdateIgnoreManager.addIgnoredVersion(widget.versionInfo);
    if (mounted) {
      globalState.navigatorKey.currentState?.pop();
    }
  }

  /// 启动更新
  Future<void> _launchUpdate() async {
    try {
      final navigatorState = Navigator.of(context);
      if (await canLaunchUrl(Uri.parse(UpdateChecker.latestReleaseUrl))) {
        await launchUrl(Uri.parse(UpdateChecker.latestReleaseUrl));
      }
      if (mounted) {
        navigatorState.pop();
      }
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '启动更新失败');
    }
  }


}
