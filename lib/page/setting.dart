import 'package:counters/state.dart';
import 'package:counters/version.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
              padding: const EdgeInsets.symmetric(vertical: 0),
              children: [
                _buildSectionHeader('关于'),
                _buildListTile(
                  icon: Icons.info,
                  title: '关于应用',
                  // onTap: () => _showAbout(context),
                  onTap: () => globalState.showMessage(
                    title: '关于',
                    message: TextSpan(
                      text: '一个flutter计分板应用，支持多平台运行。\n'
                          'https://github.com/youzhiran/counters\n'
                          '欢迎访问我的网站：devyi.com\n\n'
                          '版本 $_versionName($_versionCode)\n'
                          'Git版本号: $gitCommit\n'
                          '编译时间: $buildTime',
                    ),
                  ),
                ),
                _buildListTile(
                  icon: Icons.update,
                  title: '检查更新',
                  onTap: () => globalState.openUrl(
                    'https://github.com/youzhiran/counters/releases/latest',
                  ),
                ),
                _buildListTile(
                  icon: Icons.bug_report,
                  title: '问题反馈',
                  onTap: () => globalState.openUrl(
                    'https://github.com/youzhiran/counters/',
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '版本 $_versionName($_versionCode)\n'
                  'Tip：1.0版本前程序更新不考虑数据兼容性，若出现异常请清除数据或重装程序。',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const Icon(Icons.chevron_right, size: 24),
            ],
          ),
        ),
      ),
    );
  }

}
