import 'dart:io';

import 'package:counters/app/config.dart';
import 'package:counters/app/state.dart';
import 'package:counters/common/db/db_helper.dart';
import 'package:counters/common/utils/error_handler.dart';
import 'package:counters/common/utils/net.dart';
import 'package:counters/common/utils/popup_menu_utils.dart';
import 'package:counters/common/widgets/message_overlay.dart';
import 'package:counters/common/widgets/setting_list_tile.dart';
import 'package:counters/common/widgets/update_dialog.dart';
import 'package:counters/features/backup/backup_page.dart';
import 'package:counters/features/dev/port_test_page.dart';
import 'package:counters/features/setting/about_page.dart'; // 导入新的关于应用页面
import 'package:counters/features/setting/data_manager.dart';
import 'package:counters/features/setting/log_settings_page.dart';
import 'package:counters/features/setting/port_config_provider.dart';
import 'package:counters/features/setting/privacy_debug_page.dart';
import 'package:counters/features/setting/theme_provider.dart';
import 'package:counters/features/setting/update_check_provider.dart';
import 'package:counters/features/setting/analytics_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _enableDesktopMode = false;
  static const String _keyEnableDesktopMode = 'enable_desktop_mode';

  // 添加计数器和显示状态
  int _versionClickCount = 0;
  bool _showDevOptions = false;
  static const String _keyShowDevOptions = 'show_dev_options'; // 添加key常量
  final int _clicksToShowDev = 5; // 需要点击5次才显示开发者选项

  // 保存最后一次点击位置，用于菜单定位
  Offset? _lastTapPosition;

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
    _loadDesktopModeSetting();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 0),
              children: [
                _buildSectionHeader('主题'),
                SettingListTile(
                  icon: Icons.dark_mode,
                  title: '深色模式',
                  subtitle: '自动 / 浅色 / 深色',
                  trailing: Text(
                    _getThemeModeText(ref.watch(themeProvider).themeMode),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 14,
                    ),
                  ),
                  onTap: _showThemeModeMenu,
                ),
                SettingListTile(
                  icon: Icons.palette,
                  title: '主题设置',
                  subtitle: '设置主题颜色和字体',
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
                SettingListTile(
                  icon: Icons.rocket_launch,
                  title: '检查更新',
                  subtitle: '获取新版本或是测试版本',
                  onTap: () => checkUpdate(),
                ),
                // 启动时检查更新设置
                Consumer(
                  builder: (context, ref, child) {
                    final updateCheckState = ref.watch(updateCheckProvider);
                    final updateCheckNotifier =
                        ref.read(updateCheckProvider.notifier);

                    return SettingListTile(
                      icon: Icons.update,
                      title: '启动时检查更新',
                      subtitle: '设置应用启动时的更新检查行为',
                      trailing: updateCheckState.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              updateCheckState.option.displayName,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 14,
                              ),
                            ),
                      onTap: updateCheckState.isLoading
                          ? null
                          : () => _showUpdateCheckDialog(updateCheckNotifier),
                    );
                  },
                ),
                if (Platform.isWindows)
                  SettingListTile(
                    icon: Icons.folder,
                    title: '数据存储位置',
                    subtitle: '更改 ${Config.appName} 数据库存储位置',
                    trailing: Text(
                      _isCustomPath ? '自定义' : '默认',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 14,
                      ),
                    ),
                    onTap: _showStoragePathDialog,
                  ),
                SettingListTile(
                  icon: Icons.backup,
                  title: '数据备份与恢复',
                  subtitle: '导出或导入应用配置和数据',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const BackupPage(),
                      ),
                    );
                  },
                ),
                SettingListTile(
                  icon: Icons.settings_backup_restore,
                  title: '重置设置',
                  subtitle: '恢复 ${Config.appName} 默认设置',
                  onTap: _resetSettings,
                ),
                SettingListTile(
                  icon: Icons.delete_forever,
                  title: '重置数据库',
                  subtitle: '重置 ${Config.appName} 数据库',
                  onTap: _resetDatabase,
                ),

                SettingSwitchListTile(
                  icon: Icons.desktop_windows,
                  title: '启用桌面模式适配',
                  subtitle: '测试中功能，启用并重启后程序支持横屏界面',
                  value: _enableDesktopMode,
                  onChanged: _saveDesktopModeSetting,
                ),
                // 匿名统计设置
                Consumer(
                  builder: (context, ref, child) {
                    final analyticsState = ref.watch(analyticsProvider);
                    final analyticsNotifier = ref.read(analyticsProvider.notifier);

                    return SettingSwitchListTile(
                      icon: Icons.analytics,
                      title: '匿名统计',
                      subtitle: '我们使用 Microsoft Clarity 帮助改进应用体验，不收集个人信息',
                      value: analyticsState.isEnabled,
                      onChanged: analyticsState.isLoading
                          ? null
                          : (value) => _handleAnalyticsToggle(analyticsNotifier, value),
                    );
                  },
                ),
                _buildSectionHeader('高级'),
                SettingListTile(
                  icon: Icons.settings_ethernet,
                  title: '端口配置',
                  subtitle: '配置局域网服务和广播端口',
                  onTap: _showPortConfigDialog,
                ),
                SettingListTile(
                  icon: Icons.network_check,
                  title: '端口测试',
                  subtitle: '测试端口可用性和配置状态',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PortTestPage(),
                      ),
                    );
                  },
                ),
                SettingListTile(
                  icon: Icons.article,
                  title: '程序日志',
                  subtitle: '提供局域网状态和程序日志查看',
                  onTap: () {
                    Navigator.pushNamed(context, '/log_test');
                  },
                ),
                _buildSectionHeader('关于'),
                SettingListTile(
                  icon: Icons.info,
                  title: '关于应用',
                  subtitle: '了解 ${Config.appName}，访问官网和项目地址',
                  onTap: () {
                    AboutPage.showAsSideSheet(context);
                  },
                ),
                SettingListTile(
                  icon: Icons.chat,
                  title: '一起划水',
                  subtitle: '朋友快来玩呀',
                  onTap: _handleJoinChatTap,
                ),
                SettingListTile(
                  icon: Icons.bug_report,
                  title: '问题反馈',
                  subtitle: '反馈bug与建议',
                  onTap: () => globalState.openUrl(
                    Config.urlContact,
                  ),
                ),
                if (_showDevOptions) ...[
                  _buildSectionHeader('开发者选项'),
                  SettingListTile(
                    icon: Icons.visibility_off,
                    title: '隐藏开发者选项',
                    subtitle: '多次点击下方版本信息可再次开启',
                    onTap: _hideDevOptions,
                  ),
                  SettingListTile(
                    icon: Icons.message,
                    title: '消息系统调试',
                    subtitle: '测试消息显示系统',
                    onTap: () {
                      Navigator.pushNamed(context, '/message_debug');
                    },
                  ),
                  SettingListTile(
                    icon: Icons.article,
                    title: '日志设置',
                    subtitle: '配置日志级别和查看程序日志',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LogSettingsPage(),
                        ),
                      );
                    },
                  ),
                  SettingListTile(
                    icon: Icons.privacy_tip,
                    title: '隐私政策调试',
                    subtitle: '查看隐私政策版本状态和手动测试',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PrivacyDebugPage(),
                        ),
                      );
                    },
                  ),
                  SettingListTile(
                    icon: Icons.clear_all,
                    title: '清除忽略的更新',
                    subtitle: '清除所有被忽略的更新版本记录',
                    onTap: _clearIgnoredVersions,
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
            GlobalMsgManager.showMessage('已清空目标目录');
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
            GlobalMsgManager.showMessage('有其他迁移任务正在执行，请稍后再试');
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
        ref.showMessage('所选目录无写入权限，请选择其他目录');
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

        ref.showSuccess('数据迁移完成');
      } else {
        ref.showError('数据迁移失败，请手动迁移数据');
      }
    }
  }

  // 重置为默认存储位置
  Future<void> _resetToDefaultPath() async {
    if (!Platform.isWindows) return;

    final defaultDir = await DataManager.getDefaultBaseDir();

    // 检查是否已经是默认目录
    if (!_isCustomPath || _dataStoragePath == defaultDir) {
      GlobalMsgManager.showMessage('当前已经是默认存储位置');
      return;
    }

    // 检查目录是否可写
    if (!await DataManager.isDirWritable(defaultDir)) {
      GlobalMsgManager.showMessage('所选目录无写入权限，请选择其他目录');
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

      ref.showSuccess('数据迁移完成');
    } else {
      ref.showError('数据迁移失败，请手动迁移数据');
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
            Text('更改存储位置将进行数据迁移，若新目录含有旧版本数据将会被覆盖，旧目录程序数据不会删除。\n\n'
                '设置数据(shared_preferences)一般位于 C:\\Users\\{用户名}\\AppData\\Roaming\\com.devyi\\counters\\shared_preferences.json ，其位置不会变动。\n\n'
                '数据实际存储于选择目录下的 counters-data 目录中。\n\n'
                '本功能目前仅适用于Windows。'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => globalState.navigatorKey.currentState?.pop(),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () {
              globalState.navigatorKey.currentState?.pop();
              _resetToDefaultPath();
            },
            child: Text('恢复默认'),
          ),
          TextButton(
            onPressed: () {
              globalState.navigatorKey.currentState?.pop();
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
            onPressed: () => globalState.navigatorKey.currentState?.pop(),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              globalState.navigatorKey.currentState?.pop();
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
        url = await ApiChecker.fetchApiData('group');
        updateProgress('获取完成', 1.0);
        return url != null && url!.isNotEmpty;
      },
    );

    if (result && url != null) {
      globalState.openUrl(url!, '点击前往唤起群组应用');
    } else {
      GlobalMsgManager.showMessage('获取群组链接失败');
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
        GlobalMsgManager.showMessage('已启用开发者选项。本功能仅限调试使用，请慎重操作！');
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
    GlobalMsgManager.showMessage('已隐藏开发者选项');
  }

  // 添加保存开发者选项状态方法
  Future<void> _saveDevOptions(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowDevOptions, value);
  }

  // 加载桌面模式设置
  Future<void> _loadDesktopModeSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enableDesktopMode = prefs.getBool(_keyEnableDesktopMode) ?? false;
    });
  }

  // 保存桌面模式设置
  Future<void> _saveDesktopModeSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnableDesktopMode, value);
    setState(() {
      _enableDesktopMode = value;
    });
    GlobalMsgManager.showMessage('设置已保存，重启应用后生效');
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
            onPressed: () => globalState.navigatorKey.currentState?.pop(),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              globalState.navigatorKey.currentState?.pop();
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
    // 获取当前主题模式
    final currentThemeMode = ref.read(themeProvider).themeMode;

    // 在显示菜单前获取 themeProvider.notifier
    final themeNotifier = ref.read(themeProvider.notifier);

    // 使用通用工具类显示菜单
    PopupMenuUtils.showSelectionMenu<ThemeMode>(
      context: context,
      items: ThemeMode.values.map((mode) {
        return PopupMenuUtils.createMenuItem<ThemeMode>(
          value: mode,
          text: _getThemeModeText(mode),
          isSelected: currentThemeMode == mode,
          context: context,
        );
      }).toList(),
    ).then((value) {
      if (value != null) {
        // 使用之前获取的 themeNotifier 更新主题模式
        themeNotifier.setThemeMode(value);
      }
    });
  }

  void _showColorPickerDialog() {
    // 在显示对话框前获取 themeProvider.notifier
    final themeNotifier = ref.read(themeProvider.notifier);

    // 获取可用字体列表（带缓存）
    Future<List<String>> getAvailableFonts(List<String> fallbackFonts) async {
      try {
        // 尝试获取系统字体
        final systemFonts = await _getSystemFonts();
        return ['系统推荐', ...systemFonts];
      } catch (e) {
        // 失败时使用Config中的预设字体
        return ['系统推荐', ...Config.chineseFontFallbacks];
      }
    }

    // 显示对话框
    globalState.showCommonDialog(
      child: Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 320),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FutureBuilder<List<String>>(
              future: getAvailableFonts([]), // 异步获取字体列表
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final availableFonts = snapshot.data ?? [];

                // 使用 Consumer 获取当前主题状态
                return Consumer(
                  builder: (context, ref, _) {
                    // 获取当前字体值
                    final themeState = ref.watch(themeProvider);
                    String currentFont = themeState.fontFamily ?? '系统推荐';

                    // 检查当前字体是否在可用字体列表中
                    if (!availableFonts.contains(currentFont)) {
                      currentFont = '系统推荐';
                    }

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '主题设置',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 16),

                        // 字体选择部分
                        Row(
                          children: [
                            Text(
                              '选择字体：',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            Tooltip(
                              message: '选择"系统推荐"将在程序推荐的字体列表中自动选择字体。\n'
                                  '右侧供选择的字体并不代表您的系统安装了该字体，若选择了系统中没有的字体，将自动回滚到其他字体。',
                              child: Icon(
                                Icons.info_outline,
                                size: 22,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButton<String>(
                                value: currentFont,
                                isExpanded: true,
                                items: availableFonts.map((font) {
                                  return DropdownMenuItem<String>(
                                    value: font,
                                    child: Text(
                                      font,
                                      style: TextStyle(
                                        fontFamily:
                                            font == '系统推荐' ? null : font,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newFont) {
                                  // 这里有两个if是为了立即在ui上显示出选择了 系统推荐
                                  if (newFont != null) {
                                    themeNotifier.setFontFamily(newFont);
                                  }
                                  if (newFont == '系统推荐') {
                                    themeNotifier.setFontFamily(null);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Divider(height: 1, color: Colors.grey[300]),
                        const SizedBox(height: 16),

                        // 颜色选择部分
                        Text(
                          '选择主题颜色',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount: 4,
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 18,
                          crossAxisSpacing: 18,
                          children: _themeColors.map((color) {
                            // 获取当前主题颜色
                            final currentThemeColor = themeState.themeColor;
                            return InkWell(
                              onTap: () {
                                // 更新主题颜色
                                themeNotifier.setThemeColor(color);
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () =>
                                  globalState.navigatorKey.currentState?.pop(),
                              child: Text('确定'),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // 获取系统字体列表
  Future<List<String>> _getSystemFonts() async {
    // 由于Flutter没有内置获取系统字体的API，这里使用平台通道
    // 实际项目中需要实现原生代码来获取系统字体列表
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // 使用插件或自定义平台通道
        // 例如: return await SystemFonts.getAvailableFonts();
        // return await SystemFonts().loadAllFonts();
        return [
          // 'Roboto',
          // 'Open Sans',
          // 'Lato',
          // 'Montserrat',
          // 'Oswald',
        ];
      } else if (Platform.isWindows) {
        // Windows系统字体
        return [
          'PingFang SC',
          'HarmonyOS Sans SC',
          'MiSans',
          'MiSans VF',
          'vivo Sans',
          'Microsoft YaHei',
          'Microsoft YaHei UI',
          '等线',
          '楷体',
          '黑体',
          '隶书',
          '幼圆',
          '华文琥珀',
        ];
      } else if (Platform.isMacOS) {
        // macOS系统字体
        return [
          'PingFang SC',
          'San Francisco',
          'Helvetica Neue',
          'Avenir',
          'Menlo',
          'Chalkboard',
        ];
      } else if (Platform.isLinux) {
        // Linux系统字体
        return [
          'WenQuanYi Micro Hei',
          'Ubuntu',
          'DejaVu Sans',
          'Noto Sans CJK SC',
          'FreeSans',
          'Liberation Sans',
        ];
      }
      return [];
    } catch (e) {
      // 获取失败时返回空列表
      return [];
    }
  }

  /// 显示更新检查设置对话框
  void _showUpdateCheckDialog(UpdateCheckNotifier notifier) {
    globalState.showCommonDialog(
      child: AlertDialog(
        title: const Text('启动时检查更新'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('选择应用启动时的更新检查行为：'),
            const SizedBox(height: 16),
            ...UpdateCheckOption.values.map((option) {
              return Consumer(
                builder: (context, ref, child) {
                  final currentOption = ref.watch(updateCheckProvider).option;
                  return RadioListTile<UpdateCheckOption>(
                    title: Text(option.displayName),
                    subtitle: _getUpdateCheckSubtitle(option),
                    value: option,
                    groupValue: currentOption,
                    onChanged: (value) {
                      if (value != null) {
                        notifier.setUpdateCheckOption(value);
                      }
                    },
                  );
                },
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => globalState.navigatorKey.currentState?.pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 获取更新检查选项的描述文字
  Widget? _getUpdateCheckSubtitle(UpdateCheckOption option) {
    switch (option) {
      case UpdateCheckOption.none:
        return const Text('应用启动时不会自动检查更新');
      case UpdateCheckOption.rc:
        return const Text('仅检查稳定版本更新');
      case UpdateCheckOption.beta:
        return const Text('检查包括测试版在内的所有更新');
    }
  }

  /// 清除忽略的更新版本记录
  void _clearIgnoredVersions() {
    globalState.showCommonDialog(
      child: AlertDialog(
        title: const Text('清除忽略的更新'),
        content: const Text('此操作将清除所有被忽略的更新版本记录，下次启动时会重新提示这些版本的更新。\n\n是否继续？'),
        actions: [
          TextButton(
            onPressed: () => globalState.navigatorKey.currentState?.pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              globalState.navigatorKey.currentState?.pop();
              try {
                await UpdateIgnoreManager.clearIgnoredVersions();
                GlobalMsgManager.showMessage('已清除所有忽略的更新版本记录');
              } catch (e) {
                ErrorHandler.handle(e, StackTrace.current,
                    prefix: '清除忽略版本记录失败');
              }
            },
            child: const Text('清除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }

  /// 显示端口配置对话框
  void _showPortConfigDialog() {
    globalState.showCommonDialog(
      child: Consumer(
        builder: (context, ref, child) {
          final portConfig = ref.watch(portConfigProvider);
          final portConfigNotifier = ref.read(portConfigProvider.notifier);

          // 确保配置已初始化
          Future.microtask(() => portConfigNotifier.initialize());

          return AlertDialog(
            title: const Text('端口配置'),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('配置局域网服务使用的端口号：'),
                  const SizedBox(height: 16),

                  // 广播端口配置
                  Text(
                    '局域网广播端口',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: portConfig.isLoading
                        ? null
                        : () {
                            _showDiscoveryPortMenu(context, ref);
                          },
                    onTapDown: (details) {
                      // 保存点击位置用于菜单定位
                      _lastTapPosition = details.globalPosition;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              '${portConfig.discoveryPort}${portConfig.discoveryPort == Config.discoveryPort ? ' (默认)' : ''}'),
                          Icon(Icons.arrow_drop_down,
                              color: Colors.grey.shade600),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 服务端口配置
                  Text(
                    '局域网服务端口',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: portConfig.isLoading
                        ? null
                        : () {
                            _showWebSocketPortMenu(context, ref);
                          },
                    onTapDown: (details) {
                      // 保存点击位置用于菜单定位
                      _lastTapPosition = details.globalPosition;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              '${portConfig.webSocketPort}${portConfig.webSocketPort == Config.webSocketPort ? ' (默认)' : ''}'),
                          Icon(Icons.arrow_drop_down,
                              color: Colors.grey.shade600),
                        ],
                      ),
                    ),
                  ),

                  if (portConfig.error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        portConfig.error!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  Text(
                    '注意：\n①无特殊情况请不要修改端口设置。\n'
                    '②修改端口后需重启局域网服务才能生效。\n'
                    '③修改端口后主机和客户端端口设置需保持一致方可正常联机。',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: portConfig.isLoading
                    ? null
                    : () {
                        portConfigNotifier.resetToDefaults();
                      },
                child: const Text('重置默认'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('关闭'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 显示广播端口选择菜单
  void _showDiscoveryPortMenu(BuildContext context, WidgetRef ref) {
    final portConfig = ref.read(portConfigProvider);
    final portConfigNotifier = ref.read(portConfigProvider.notifier);

    // 使用通用工具类显示端口选择菜单，传递点击位置进行精确定位
    PopupMenuUtils.showSelectionMenu<int>(
      context: context,
      globalPosition: _lastTapPosition,
      items: portConfig.discoveryPortOptions.map((port) {
        return PopupMenuUtils.createPortMenuItem(
          port: port,
          defaultPort: Config.discoveryPort,
          currentPort: portConfig.discoveryPort,
          context: context,
        );
      }).toList(),
    ).then((value) {
      if (value != null) {
        portConfigNotifier.setDiscoveryPort(value);
      }
    });
  }

  /// 显示服务端口选择菜单
  void _showWebSocketPortMenu(BuildContext context, WidgetRef ref) {
    final portConfig = ref.read(portConfigProvider);
    final portConfigNotifier = ref.read(portConfigProvider.notifier);

    // 使用通用工具类显示端口选择菜单，传递点击位置进行精确定位
    PopupMenuUtils.showSelectionMenu<int>(
      context: context,
      globalPosition: _lastTapPosition,
      items: portConfig.webSocketPortOptions.map((port) {
        return PopupMenuUtils.createPortMenuItem(
          port: port,
          defaultPort: Config.webSocketPort,
          currentPort: portConfig.webSocketPort,
          context: context,
        );
      }).toList(),
    ).then((value) {
      if (value != null) {
        portConfigNotifier.setWebSocketPort(value);
      }
    });
  }

  /// 处理匿名统计开关切换
  Future<void> _handleAnalyticsToggle(AnalyticsNotifier notifier, bool value) async {
    // 如果是关闭统计，显示确认弹窗
    if (!value) {
      final confirmed = await _showAnalyticsDisableConfirmDialog();
      if (!confirmed) {
        return; // 用户取消，不执行关闭操作
      }
    }

    try {
      await notifier.setAnalyticsEnabled(value);

      if (mounted) {
        GlobalMsgManager.showMessage(
          '匿名统计已${value ? '启用' : '禁用'}，重启应用后生效',
        );
      }
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '切换匿名统计设置失败');
    }
  }

  /// 显示关闭匿名统计确认弹窗
  Future<bool> _showAnalyticsDisableConfirmDialog() async {
    final result = await globalState.showCommonDialog<bool>(
      child: AlertDialog(
        title: const Text('关闭匿名统计'),
        content: const Text(
          '真的要关闭统计吗？\n\n'
          '我们不收集个人信息，只是想了解用户如何使用应用，从而改进应用使用体验。\n\n'
          '作为一个开源免费的应用，开发者看到没人使用 ${Config.appName}，可能就没动力更新了......😢😭\n\n'
          '如果您觉得 ${Config.appName} 好用，希望能给开发者一个 star ⭐。\n\n'
          '您可以随时在设置中重新开启。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('我再想想'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
            ),
            child: const Text('确定关闭'),
          ),
        ],
      ),
    );

    return result ?? false; // 如果用户点击外部关闭弹窗，默认为取消
  }
}
