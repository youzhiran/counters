import 'package:counters/app/config.dart';
import 'package:counters/app/state.dart';
import 'package:counters/version.dart'; // 导入版本信息文件
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _versionName = '读取失败';
  String _versionCode = '读取失败';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  // 加载应用包信息
  Future<void> _loadPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      // 确保组件仍然挂载
      setState(() {
        _versionName = packageInfo.version;
        _versionCode = packageInfo.buildNumber;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于应用'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16), // 保持外部内边距
        children: [
          const SizedBox(height: 16), // 图标下方添加间距

          // 应用图标
          Center(
            child: Image.asset(
              'assets/images/app_icon.png',
              width: 80,
              height: 80,
            ),
          ),
          const SizedBox(height: 16),

          // 应用名称和版本信息 (可选，可以在图标下方显示)
          Center(
            child: Text(
              'Counters v$_versionName',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 16),

          // 应用信息文本
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '一个flutter计分板应用，支持多平台运行。',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  '版本 $_versionName($_versionCode)\n'
                  'Git版本号: $gitCommit\n'
                  '编译时间: $buildTime',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  '本应用部分图标来自 iconscout.com\n\n'
                  '© 2025 counters.devyi.com',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 隐私政策列表项
          _buildListTile(
            icon: Icons.privacy_tip_outlined,
            title: '隐私政策',
            onTap: () => globalState.openUrl(
              Config.urlPrivacyPolicy,
              '点击前往查看隐私政策',
            ),
          ),

          // 开发者网站列表项
          _buildListTile(
            icon: Icons.web,
            title: '开发者网站',
            onTap: () => globalState.openUrl(
              Config.urlDevyi,
              '点击前往访问开发者网站',
            ),
          ),

          // 项目地址列表项
          _buildListTile(
            icon: Icons.code,
            title: '项目地址',
            onTap: () => globalState.openUrl(
              Config.urlGithub,
              '点击前往访问GitHub',
            ),
          ),

          // 软件许可列表项
          _buildListTile(
            icon: Icons.description,
            title: '软件许可',
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: 'Counters',
                applicationVersion: '$_versionName($_versionCode)',
                applicationLegalese: '© 2025 counters.devyi.com',
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // 复制_buildListTile方法以在新文件中使用，或者考虑将其重构为通用组件
  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                trailing,
                const SizedBox(width: 8),
              ],
              const Icon(Icons.chevron_right, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
