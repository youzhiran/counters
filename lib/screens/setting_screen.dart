import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../version.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  String _versionName = '1.0.0';
  String _versionCode = '1';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();

    setState(() {
      _versionName = packageInfo.version;
      _versionCode = packageInfo.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('关于应用'),
                  onTap: () => _showAbout(context),
                ),
                ListTile(
                  leading: const Icon(Icons.update),
                  title: const Text('检查更新'),
                  onTap: () async {
                    const url =
                        'https://github.com/youzhiran/counters/releases';
                    try {
                      await launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('打开失败: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bug_report),
                  title: const Text('问题反馈'),
                  onTap: () async {
                    const url =
                        'https://github.com/youzhiran/counters/';
                    try {
                      await launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('打开失败: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '版本 $_versionName($_versionCode)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          )
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('关于'),
        content: Text(
          '一个flutter计分板应用，支持多平台运行。\n'
          'https://github.com/youzhiran/counters\n'
          '欢迎访问我的网站：devyi.com\n'
          '\n'
          '版本 $_versionName($_versionCode)\n'
          'Git版本号: $gitCommit\n'
          '编译时间: $buildTime',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('确认'),
          ),
        ],
      ),
    );
  }
}
