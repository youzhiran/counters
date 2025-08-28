import 'package:counters/app/config.dart';
import 'package:counters/app/state.dart';
import 'package:counters/common/utils/platform_utils.dart';
import 'package:counters/features/setting/privacy_policy_page.dart';
import 'package:counters/version.dart'; // 导入版本信息文件
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:side_sheet/side_sheet.dart'; // 导入side_sheet包

class AboutPage extends StatefulWidget {
  // 添加一个参数来控制是否显示AppBar
  final bool showAppBar;

  // 添加一个参数来标识是否正在显示为侧边栏
  final bool isShownAsSideSheet;

  const AboutPage(
      {super.key, this.showAppBar = true, this.isShownAsSideSheet = false});

  // 添加新的静态方法，使用side_sheet从右侧显示
  static void showAsSideSheet(BuildContext context) {
    // 使用统一的桌面模式判断逻辑
    final isDesktopMode = globalState.isDesktopMode(context);

    if (isDesktopMode) {
      // 桌面模式：使用侧边栏
      SideSheet.right(
        context: context,
        width: MediaQuery.of(context).size.width * 0.4,
        // 侧边栏宽度为屏幕宽度的40%
        body: const AboutPage(showAppBar: false, isShownAsSideSheet: true),
        // 在侧边栏中不显示AppBar，并标记为侧边栏模式
        barrierDismissible: true,
        // 点击外部区域可关闭
        sheetBorderRadius: 0, // 无圆角效果
      );
    } else {
      // 非桌面模式：使用全屏导航
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const AboutPage()));
    }
  }

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> with WidgetsBindingObserver {
  String _versionName = '读取失败';
  String _versionCode = '读取失败';
  bool _wasDesktopMode = false; // 记录上次检测到的模式

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
    WidgetsBinding.instance.addObserver(this); // 添加观察者来监听系统变化

    // 初始化时检查一次桌面模式状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndUpdateMode();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 移除观察者
    super.dispose();
  }

  // 监听系统变化，包括窗口大小变化
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _checkAndUpdateMode();
  }

  // 检查并更新显示模式
  void _checkAndUpdateMode() {
    if (!mounted) return;

    // 使用统一的桌面模式判断逻辑
    final isDesktopMode = globalState.isDesktopMode(context);

    // 如果模式发生变化且当前是以侧边栏方式显示
    if (isDesktopMode != _wasDesktopMode && widget.isShownAsSideSheet) {
      _wasDesktopMode = isDesktopMode;

      if (!isDesktopMode) {
        // 从桌面模式切换到移动模式：关闭侧边栏，使用全屏显示
        Navigator.pop(context); // 先关闭侧边栏
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const AboutPage()));
      }
    } else {
      _wasDesktopMode = isDesktopMode;
    }
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
    // 根据showAppBar参数决定是使用Scaffold还是直接返回内容
    return widget.showAppBar
        ? Scaffold(
            appBar: AppBar(
              title: const Text('关于应用'),
            ),
            body: _buildContent(),
          )
        : _buildContent();
  }

  // 提取内容部分为单独的方法，以便在不同模式下复用
  Widget _buildContent() {
    return ListView(
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
            '${Config.appName} v$_versionName',
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
              Text('版本: $_versionName($_versionCode)'),
              if (!PlatformUtils.isOhosPlatformSync())
                Text(
                  'Git版本号: $gitCommit\n'
                  '编译时间: $buildTime',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(height: 12),
              Text(
                '本应用部分图标来自\n'
                'www.freeicons.org\n\n'
                '© 2025 counters.devyi.com',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '\nTip：1.0版本前程序更新不考虑数据兼容性，若出现异常请清除应用数据/重置应用数据库/重装程序。',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 隐私政策列表项
        _buildListTile(
          icon: Icons.privacy_tip_outlined,
          title: '隐私政策',
          onTap: () {
            if (!PlatformUtils.isOhosPlatformSync()) {
              globalState.openUrl(
                Config.urlPrivacyPolicy,
                '点击前往查看隐私政策',
              );
            } else if (globalState.isDesktopMode(context)) {
              // 桌面模式：使用侧边栏显示
              SideSheet.right(
                context: context,
                width: MediaQuery.of(context).size.width * 0.4,
                body: const PrivacyPolicyPage(),
                barrierDismissible: true,
                sheetBorderRadius: 0,
              );
            } else {
              // 移动模式：使用全屏导航
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyPage(),
                ),
              );
            }
          },
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
        // 软件官网列表项
        _buildListTile(
          icon: Icons.language,
          title: '软件官网',
          onTap: () => globalState.openUrl(
            Config.urlApp,
            '点击前往访问 ${Config.appName} 官方网站',
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
              applicationName: '${Config.appName}',
              applicationVersion: '$_versionName($_versionCode)',
              applicationLegalese: '© 2025 counters.devyi.com',
            );
          },
        ),
        const SizedBox(height: 16),
      ],
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
