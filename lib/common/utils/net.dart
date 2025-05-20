import 'dart:convert';

import 'package:counters/app/config.dart';
import 'package:counters/app/state.dart';
import 'package:counters/common/utils/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'error_handler.dart';
import 'log.dart';

class UpdateChecker {
  static String latestReleaseUrl = '';
  static String latestReleaseBody = '';

  String versionExtra = '';

  static Future<String> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version; // 格式如：1.0.0
  }

  static Future<String?> getLatestVersion(
      {bool includePrereleases = false}) async {
    try {
      final response = await http.get(Uri.parse(Config.urlReleases));
      if (response.statusCode == 200) {
        final releases = json.decode(response.body) as List;
        if (releases.isEmpty) return null;
        final filtered = includePrereleases
            ? releases
            : releases.where((r) => r['name'].toString().contains('rc'));
        if (filtered.isEmpty) return null;
        final latestRelease = filtered.first;
        latestReleaseUrl = latestRelease['html_url'].toString();
        latestReleaseBody = latestRelease['body'].toString();
        return latestRelease['name'].toString().replaceAll('v', '');
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<String> isUpdateAvailable(
      {bool includePrereleases = false}) async {
    final currentVersion = await getCurrentVersion();
    final latestVersion =
        await getLatestVersion(includePrereleases: includePrereleases);
    if (latestVersion == null) return '网络错误';
    var command = _compareVersions(currentVersion, latestVersion);
    // 处理 Markdown 格式的更新说明
    latestReleaseBody = StrUtil.md2Str(latestReleaseBody);
    switch (command) {
      case 1:
        return 'v$latestVersion\n(当前: $currentVersion)\n\n'
            '$latestReleaseBody';
      case 0:
        return '已是最新版本 \n当前: $currentVersion, 远程: $latestVersion';
      case -1:
        return '您的版本比远程版本高哦~ \n当前: $currentVersion, 远程: $latestVersion';
      default:
        return '检查失败';
    }
  }

  // 有更新返回1，一样返回0，本地版本（v1）更高返回-1
  static int _compareVersions(String v1, String v2) {
    // 分割主版本号和其他部分
    final v1Parts = v1.split('-');
    final v2Parts = v2.split('-');

    final core1 = v1Parts[0];
    final extra1 = v1Parts.length > 1 ? v1Parts.sublist(1).join('-') : '';
    final core2 = v2Parts[0];
    final extra2 = v2Parts.length > 1 ? v2Parts.sublist(1).join('-') : '';

    // 解析数字部分
    parseVersionPart(String part) {
      final match = RegExp(r'^\d+').firstMatch(part);
      return match != null ? int.parse(match.group(0)!) : 0;
    }

    final v1Nums = core1.split('.').map(parseVersionPart).toList();
    final v2Nums = core2.split('.').map(parseVersionPart).toList();

    // 比较数字部分
    int result = 0;
    for (int i = 0; i < v1Nums.length || i < v2Nums.length; i++) {
      final num1 = i < v1Nums.length ? v1Nums[i] : 0;
      final num2 = i < v2Nums.length ? v2Nums[i] : 0;

      if (num1 != num2) {
        result = num1 > num2 ? -1 : 1;
        break;
      }
    }

    // 打印额外信息
    Log.i('Version metadata - v1: ${extra1.isNotEmpty ? extra1 : "stable"}, '
        'v2: ${extra2.isNotEmpty ? extra2 : "stable"}');
    Log.i('v1:$v1  v2:$v2');

    return result;
  }

  static void showUpdateResultDialog(
      BuildContext context, WidgetRef ref, String versionInfo, bool hasUpdate) {
    globalState.showCommonDialog(
      child: AlertDialog(
        title: Text(hasUpdate ? '发现新版本' : '未发现新版本'),
        content: Text(hasUpdate
            ? '可更新到最新版本以获得更好体验：\n$versionInfo'
            : '未检查到新版本\n$versionInfo'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(hasUpdate ? '稍后' : '确定'),
          ),
          if (hasUpdate)
            TextButton(
              onPressed: () async {
                final navigatorState = Navigator.of(context);
                if (await canLaunchUrl(
                    Uri.parse(UpdateChecker.latestReleaseUrl))) {
                  await launchUrl(Uri.parse(UpdateChecker.latestReleaseUrl));
                }
                if (navigatorState.mounted) {
                  navigatorState.pop();
                }
              },
              child: Text('立即更新'),
            ),
        ],
      ),
    );
  }
}

void checkUpdate(
  BuildContext context,
  WidgetRef ref,
) {
  globalState.showCommonDialog(
    child: UpdateCheckerDialog(),
  );
}

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
      title: Text('检查更新'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CheckboxListTile(
            title: Text('包含测试版本'),
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(),
            )
          else
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasUpdate) ...[
                      SizedBox(height: 16),
                      Text(
                        '发现新版本',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(12),
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
                      SizedBox(height: 16),
                      Text(
                        '更新日志',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(12),
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
                    ] else
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          versionInfo,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
      actions: [
        if (!isLoading)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(hasUpdate ? '稍后再说' : '关闭'),
          ),
        if (hasUpdate)
          TextButton(
            onPressed: () async {
              final navigatorState = Navigator.of(context);
              if (await canLaunchUrl(
                  Uri.parse(UpdateChecker.latestReleaseUrl))) {
                await launchUrl(Uri.parse(UpdateChecker.latestReleaseUrl));
              }
              if (mounted) {
                navigatorState.pop();
              }
            },
            child: Text('立即更新'),
          ),
      ],
    );
  }
}

class ApiChecker {
  /// 通过key获取API数据
  static Future<String?> fetchApiData(String key) async {
    try {
      final response =
          await http.get(Uri.parse('https://counters.devyi.com/api/$key'));
      Log.i(response.body);
      if (response.statusCode == 200) {
        return response.body;
      }
      return null;
    } catch (e) {
      ErrorHandler.handle(e, null, prefix: '网络错误');
      return null;
    }
  }
}
