import 'dart:convert';

import 'package:counters/state.dart';
import 'package:counters/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateChecker {
  static const String RELEASES_URL =
      'https://api.github.com/repos/youzhiran/counters/releases';
  static const String LATEST_URL =
      'https://github.com/youzhiran/counters/releases/latest';

  String versionExtra = '';

  static Future<String> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version; // 格式如：1.0.0
  }

  static Future<String?> getLatestVersion() async {
    try {
      final response = await http.get(
        Uri.parse(RELEASES_URL),
      );
      if (response.statusCode == 200) {
        final releases = json.decode(response.body) as List;
        if (releases.isEmpty) return null;
        final latestRelease = releases.first; // 假设第一个是最新版本
        return latestRelease['tag_name']
            .toString()
            .replaceAll('v', ''); // 移除可能存在的v前缀
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<String> isUpdateAvailable() async {
    final currentVersion = await getCurrentVersion();
    final latestVersion = await getLatestVersion();
    if (latestVersion == null) return '网络错误';
    var command = _compareVersions(currentVersion, latestVersion);
    switch (command) {
      case 1:
        return 'v$latestVersion';
      case 0:
        return '已是最新版本';
      case -1:
        return '您的版本比远程版本高哦~';
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
    print('Version metadata - v1: ${extra1.isNotEmpty ? extra1 : "stable"}, '
        'v2: ${extra2.isNotEmpty ? extra2 : "stable"}');
    print('v1:$v1  v2:$v2');

    return result;
  }

  static void showUpdateDialog(BuildContext context, String versionInfo) {
    globalState.showCommonDialog(
      child: AlertDialog(
        title: Text('发现新版本'),
        content: Text('可更新到最新版本以获得更好体验：\n'
            '$versionInfo'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('稍后'),
          ),
          TextButton(
            onPressed: () async {
              if (await canLaunchUrl(Uri.parse(RELEASES_URL))) {
                await launchUrl(Uri.parse(LATEST_URL));
              }
              Navigator.pop(context);
            },
            child: Text('立即更新'),
          ),
        ],
      ),
    );
  }

  static void showNoUpdateDialog(BuildContext context, String versionInfo) {
    globalState.showCommonDialog(
      child: AlertDialog(
        title: Text('未发现新版本'),
        content: Text('未检查到新版本\n'
            '$versionInfo'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
            },
            child: Text('确定'),
          ),
        ],
      ),
    );
  }
}

void checkUpdate(BuildContext context) async {
  AppSnackBar.show(context, '检查更新中...');
  final versionInfo = await UpdateChecker.isUpdateAvailable();
  if (versionInfo.startsWith('v')) {
    UpdateChecker.showUpdateDialog(context, versionInfo);
  } else {
    UpdateChecker.showNoUpdateDialog(context, versionInfo);
  }
}
