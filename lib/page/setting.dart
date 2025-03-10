import 'package:counters/state.dart';
import 'package:counters/version.dart';
import 'package:counters/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/db_helper.dart';
import '../utils/net.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  String _versionName = '读取失败';
  String _versionCode = '读取失败';

  // 添加计数器和显示状态
  int _versionClickCount = 0;
  bool _showDevOptions = false;
  static const String _keyShowDevOptions = 'show_dev_options'; // 添加key常量
  final int _clicksToShowDev = 5; // 需要点击5次才显示开发者选项

  final List<Color> _themeColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.pink,
    Colors.brown,
    Colors.teal,
  ];

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
    _loadDevOptions();
  }

  // 添加加载开发者选项方法
  Future<void> _loadDevOptions() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showDevOptions = prefs.getBool(_keyShowDevOptions) ?? false;
    });
  }

  // 处理版本信息点击
  void _handleVersionTap() {
    setState(() {
      _versionClickCount++;
      if (_versionClickCount >= _clicksToShowDev && !_showDevOptions) {
        _showDevOptions = true;
        _saveDevOptions(true); // 保存状态
        AppSnackBar.show('已启用开发者选项。本功能仅限调试使用，请慎重操作！');
      }
    });

    // 3秒后重置点击计数
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _versionClickCount = 0;
        });
      }
    });
  }

  // 隐藏开发者选项方法
  void _hideDevOptions() async {
    setState(() {
      _showDevOptions = false;
    });
    await _saveDevOptions(false); // 保存状态
    AppSnackBar.show('已隐藏开发者选项');
  }

  // 添加保存开发者选项状态方法
  Future<void> _saveDevOptions(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowDevOptions, value);
  }

  void _resetDatabase() {
    globalState.showCommonDialog(
      child: AlertDialog(
        title: Text('重置数据库'),
        content: Text('此操作将删除所有数据并重新初始化数据库。包括自定义模板、玩家设置、计分历史等。\n此操作不可恢复，是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await DatabaseHelper.instance.resetDatabase();
                if (mounted) {
                  globalState.showMessage(
                    title: '成功',
                    message: TextSpan(text: '数据库已重置'),
                  );
                }
              } catch (e) {
                if (mounted) {
                  globalState.showMessage(
                    title: '错误',
                    message: TextSpan(text: '重置数据库失败：$e'),
                  );
                }
              }
            },
            child: Text('重置', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _loadPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _versionName = packageInfo.version;
      _versionCode = packageInfo.buildNumber;
    });
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return '自动';
      case ThemeMode.light:
        return '浅色';
      case ThemeMode.dark:
        return '深色';
    }
  }

  void _showThemeModeMenu() {
    // 获取当前点击的列表项的位置信息
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    // 计算菜单显示位置，使其显示在列表项的右侧
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    final position = RelativeRect.fromLTRB(
      offset.dx + size.width - 200, // 从右侧200像素处显示
      offset.dy + 50, // 垂直方向稍微偏下
      offset.dx + size.width,
      offset.dy + size.height,
    );

    showMenu<ThemeMode>(
      context: context,
      position: position,
      items: ThemeMode.values.map((mode) {
        return PopupMenuItem<ThemeMode>(
          value: mode,
          child: Row(
            children: [
              Icon(
                Icons.check,
                color: globalState.themeMode == mode
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
              ),
              const SizedBox(width: 12),
              Text(_getThemeModeText(mode)),
            ],
          ),
        );
      }).toList(),
    ).then((value) {
      if (value != null) {
        globalState.setThemeMode(value);
        setState(() {});
      }
    });
  }

  void _showColorPickerDialog() {
    globalState.showCommonDialog(
      child: Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 320),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '选择主题颜色',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 18,
                  children: _themeColors.map((color) {
                    return InkWell(
                      onTap: () {
                        globalState.setThemeColor(color);
                        Navigator.pop(context);
                        setState(() {});
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color == globalState.themeColor
                                ? Colors.white
                                : Colors.grey,
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('取消'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
                _buildSectionHeader('主题'),
                _buildListTile(
                  icon: Icons.dark_mode,
                  title: '深色模式',
                  trailing: Text(
                    _getThemeModeText(globalState.themeMode),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  onTap: _showThemeModeMenu,
                ),
                _buildListTile(
                  icon: Icons.palette,
                  title: '主题色彩',
                  trailing: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: globalState.themeColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                  onTap: _showColorPickerDialog,
                ),
                _buildSectionHeader('关于'),
                _buildListTile(
                  icon: Icons.info,
                  title: '关于应用',
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
                    onTap: () => checkUpdate(context)),
                _buildListTile(
                  icon: Icons.bug_report,
                  title: '问题反馈',
                  onTap: () => globalState.openUrl(
                    'https://github.com/youzhiran/counters/',
                  ),
                ),
                if (_showDevOptions) ...[
                  _buildSectionHeader('开发者选项'),
                  _buildListTile(
                    icon: Icons.delete_forever,
                    title: '重置数据库',
                    onTap: _resetDatabase,
                  ),
                  _buildListTile(
                    icon: Icons.visibility_off,
                    title: '隐藏开发者选项',
                    onTap: _hideDevOptions,
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: _handleVersionTap,
            child: Padding(
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
            ),
          ),
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
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
