import 'dart:io';

import 'package:counters/utils/data.dart';
import 'package:counters/version.dart';
import 'package:counters/widgets/snackbar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/db_helper.dart';
import '../providers/theme_provider.dart';
import '../state.dart';
import '../utils/error_handler.dart';
import '../utils/log.dart';
import '../utils/net.dart';

class SettingPage extends ConsumerStatefulWidget {
  const SettingPage({super.key});

  @override
  ConsumerState<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends ConsumerState<SettingPage> {
  String _versionName = '读取失败';
  String _versionCode = '读取失败';
  String _dataStoragePath = '应用默认目录';
  bool _isCustomPath = false;
  static const String _keyDataStoragePath = 'data_storage_path';
  static const String _keyIsCustomPath = 'is_custom_path';
  bool _enableProviderLogger = false;
  static const String _keyEnableProviderLogger = 'enable_provider_logger';

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
    _loadStorageSettings();
    _loadProviderLoggerSetting();
  }

  // 加载存储设置
  Future<void> _loadStorageSettings() async {
    if (!Platform.isWindows) return;

    final prefs = await SharedPreferences.getInstance();
    final defaultDir = await DataManager.getDefaultBaseDir();
    setState(() {
      _isCustomPath = prefs.getBool(_keyIsCustomPath) ?? false;
      _dataStoragePath = prefs.getString(_keyDataStoragePath) ?? defaultDir;
    });
  }

  // 保存存储设置
  Future<void> _saveStorageSettings(bool isCustom, String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsCustomPath, isCustom);
    await prefs.setString(_keyDataStoragePath, path);
  }

  // 检查目标目录是否存在文件并清理
  Future<bool> _checkAndCleanTargetDir(String targetPath,
      {bool needConfirm = false}) async {
    final targetDir = Directory(targetPath);
    if (await targetDir.exists()) {
      bool hasFiles = false;
      try {
        await for (var _ in targetDir.list()) {
          hasFiles = true;
          break;
        }
        if (hasFiles) {
          if (needConfirm) {
            final confirmed = await globalState.showCommonDialog<bool>(
                  child: AlertDialog(
                    title: Text('目标目录不为空'),
                    content:
                        Text('目标目录下 counters-data 内已存在数据文件，继续操作将删除这些文件。是否继续？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('取消'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('继续', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ) ??
                false;

            if (!confirmed) return false;
          }

          try {
            await targetDir.delete(recursive: true);
            await targetDir.create(recursive: true);
            AppSnackBar.show('已清空目标目录');
          } catch (e) {
            ErrorHandler.handle(e, StackTrace.current, prefix: '清空目标目录失败');
            return false;
          }
        }
      } catch (e) {
        ErrorHandler.handle(e, StackTrace.current, prefix: '检查目标目录失败');
        return false;
      }
    }
    return true;
  }

  // 执行数据迁移
  Future<bool> _migrateData(String oldPath, String newPath) async {
    return await globalState.showProgressDialog(
      title: '数据迁移',
      task: (onProgress) => DataManager.migrateData(
        oldPath,
        newPath,
        onProgress: (message, progress) {
          if (message.contains('迁移已在进行中')) {
            Log.i('有其他迁移任务正在执行，请稍后再试');
          }
          onProgress(message, progress);
        },
      ),
    );
  }

  // 选择数据存储位置
  Future<void> _selectStoragePath() async {
    if (!Platform.isWindows) return;

    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择数据存储位置',
      initialDirectory: DataManager.getAppDir(),
    );

    if (selectedDirectory != null) {
      final newDataDir = DataManager.getDataDir(selectedDirectory);

      // 检查目录是否可写
      if (!await DataManager.isDirWritable(selectedDirectory)) {
        AppSnackBar.show('所选目录无写入权限，请选择其他目录');
        return;
      }

      // 检查并清理目标目录
      if (!await _checkAndCleanTargetDir(newDataDir, needConfirm: true)) {
        return;
      }

      // 迁移数据
      final oldDataDir = DataManager.getDataDir(_dataStoragePath);
      final success = await _migrateData(oldDataDir, newDataDir);

      if (success) {
        // 先保存设置，再更新状态
        await _saveStorageSettings(true, selectedDirectory);

        setState(() {
          _isCustomPath = true;
          _dataStoragePath = selectedDirectory;
        });

        AppSnackBar.show('数据迁移完成');
      } else {
        AppSnackBar.error('数据迁移失败，请手动迁移数据');
      }
    }
  }

  // 重置为默认存储位置
  Future<void> _resetToDefaultPath() async {
    if (!Platform.isWindows) return;

    final defaultDir = await DataManager.getDefaultBaseDir();

    // 检查是否已经是默认目录
    if (!_isCustomPath || _dataStoragePath == defaultDir) {
      AppSnackBar.show('当前已经是默认存储位置');
      return;
    }

    // 检查目录是否可写
    if (!await DataManager.isDirWritable(defaultDir)) {
      AppSnackBar.show('所选目录无写入权限，请选择其他目录');
      return;
    }

    final oldDataDir = DataManager.getDataDir(_dataStoragePath);
    final newDataDir = DataManager.getDataDir(defaultDir);

    // 检查并清理目标目录
    if (!await _checkAndCleanTargetDir(newDataDir)) {
      return;
    }

    // 迁移数据
    final success = await _migrateData(oldDataDir, newDataDir);

    if (success) {
      await _saveStorageSettings(false, defaultDir);
      setState(() {
        _isCustomPath = false;
        _dataStoragePath = defaultDir;
      });

      AppSnackBar.show('数据迁移完成');
    } else {
      AppSnackBar.error('数据迁移失败，请手动迁移数据');
    }
  }

  // 显示存储位置设置对话框
  void _showStoragePathDialog() {
    globalState.showCommonDialog(
      child: AlertDialog(
        title: Text('数据存储位置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('当前位置:\n$_dataStoragePath'),
            SizedBox(height: 16),
            Text('更改存储位置将进行数据迁移，若新目录含有旧版本数据将会覆盖。设置数据位置不会变动。\n'
                '数据实际存储于选择目录下的 counters-data 目录中。\n'
                '本功能目前仅适用于Windows。'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetToDefaultPath();
            },
            child: Text('恢复默认'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _selectStoragePath();
            },
            child: Text('选择目录'),
          ),
        ],
      ),
    );
  }

  // 重置设置
  void _resetSettings() {
    globalState.showCommonDialog(
      child: AlertDialog(
        title: Text('重置设置'),
        content: Text('此操作将重置所有设置项到默认值，包括主题、存储位置等。若更改过存储位置，您的计分数据也将丢失。\n'
            '此操作不可恢复，是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (mounted) {
                  globalState.showMessage(
                    title: '成功',
                    message: TextSpan(text: '设置已重置，请重启程序以应用更改'),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ErrorHandler.handle(e, StackTrace.current, prefix: '重置设置失败');
                }
              }
            },
            child: Text('重置', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 处理"一起划水"点击事件
  Future<void> _handleJoinChatTap() async {
    String? url;
    final result = await globalState.showProgressDialog(
      title: '获取群组链接',
      task: (updateProgress) async {
        updateProgress('正在获取链接...', 0.5);
        url = await UpdateChecker.fetchApiData('group');
        updateProgress('获取完成', 1.0);
        return url != null && url!.isNotEmpty;
      },
    );

    if (result && url != null) {
      globalState.openUrl(url!, '点击前往唤起群组应用');
    } else {
      AppSnackBar.show('获取群组链接失败');
    }
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

  // 加载Provider调试设置
  Future<void> _loadProviderLoggerSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enableProviderLogger = prefs.getBool(_keyEnableProviderLogger) ?? false;
    });
  }

  // 保存Provider调试设置
  Future<void> _saveProviderLoggerSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnableProviderLogger, value);
    setState(() {
      _enableProviderLogger = value;
    });
    AppSnackBar.show('设置已保存，重启应用后生效');
  }

  void _resetDatabase() {
    globalState.showCommonDialog(
      child: AlertDialog(
        title: Text('重置数据库'),
        content: Text('此操作将删除所有数据并重新初始化数据库。包括自定义模板、玩家设置、计分历史等。\n'
            '仅在程序出现问题时使用。\n'
            '此操作不可恢复，是否继续？'),
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
                    message: TextSpan(text: '数据库已重置，请重启程序以刷新界面数据'),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ErrorHandler.handle(e, StackTrace.current, prefix: '重置数据库失败');
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

    // 获取当前主题模式
    final currentThemeMode = ref.read(themeProvider).themeMode;

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
                color: currentThemeMode == mode
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
        // 使用Riverpod提供者更新主题模式
        ref.read(themeProvider.notifier).setThemeMode(value);
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
                    // 获取当前主题颜色
                    final currentThemeColor =
                        ref.read(themeProvider).themeColor;
                    return InkWell(
                      onTap: () {
                        // 使用Riverpod提供者更新主题颜色
                        ref.read(themeProvider.notifier).setThemeColor(color);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color == currentThemeColor
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
                    _getThemeModeText(ref.watch(themeProvider).themeMode),
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
                      color: ref.watch(themeProvider).themeColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                  onTap: _showColorPickerDialog,
                ),
                _buildSectionHeader('通用'),
                if (Platform.isWindows) // 只在Windows平台显示
                  _buildListTile(
                    icon: Icons.folder,
                    title: '数据存储位置',
                    trailing: Text(
                      _isCustomPath ? '自定义' : '默认',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    onTap: _showStoragePathDialog,
                  ),
                _buildListTile(
                  icon: Icons.settings_backup_restore,
                  title: '重置设置',
                  onTap: _resetSettings,
                ),
                _buildListTile(
                  icon: Icons.delete_forever,
                  title: '重置数据库',
                  onTap: _resetDatabase,
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
                    icon: Icons.chat, title: '一起划水', onTap: _handleJoinChatTap),
                _buildListTile(
                    icon: Icons.update,
                    title: '检查更新',
                    onTap: () => checkUpdate(context, ref)),
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
                    icon: Icons.visibility_off,
                    title: '隐藏开发者选项',
                    onTap: _hideDevOptions,
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.article),
                    title: const Text('启用 Provider 调试日志'),
                    subtitle: const Text('重启应用后生效'),
                    value: _enableProviderLogger,
                    onChanged: _saveProviderLoggerSetting,
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
                'Tip：1.0版本前程序更新不考虑数据兼容性，若出现异常请清除应用数据/重置应用数据库/重装程序。',
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
