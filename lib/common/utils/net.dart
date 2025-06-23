import 'dart:convert';

import 'package:counters/app/config.dart';
import 'package:counters/app/state.dart';
import 'package:counters/common/utils/error_handler.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/common/utils/util.dart';
import 'package:counters/common/widgets/update_dialog.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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

  static void showUpdateResultDialog(String versionInfo, bool hasUpdate) {
    globalState.showCommonDialog(
      child: AlertDialog(
        title: Text(hasUpdate ? '发现新版本' : '未发现新版本'),
        content: Text(hasUpdate
            ? '可更新到最新版本以获得更好体验：\n$versionInfo'
            : '未检查到新版本\n$versionInfo'),
        actions: [
          TextButton(
            onPressed: () => globalState.navigatorKey.currentState?.pop(),
            child: Text(hasUpdate ? '稍后' : '确定'),
          ),
          if (hasUpdate)
            TextButton(
              onPressed: () async {
                if (await canLaunchUrl(
                    Uri.parse(UpdateChecker.latestReleaseUrl))) {
                  await launchUrl(Uri.parse(UpdateChecker.latestReleaseUrl));
                }
                globalState.navigatorKey.currentState?.pop();
              },
              child: Text('立即更新'),
            ),
        ],
      ),
    );
  }
}

/// 显示手动检查更新对话框
void checkUpdate() {
  globalState.showCommonDialog(
    child: const UpdateCheckerDialog(),
  );
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
