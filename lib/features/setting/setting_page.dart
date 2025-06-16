import 'dart:io';

import 'package:counters/app/config.dart';
import 'package:counters/app/state.dart';
import 'package:counters/common/db/db_helper.dart';
import 'package:counters/common/providers/log_provider.dart';
import 'package:counters/common/utils/error_handler.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/common/utils/net.dart';
import 'package:counters/common/widgets/message_overlay.dart';
import 'package:counters/common/widgets/page_transitions.dart';
import 'package:counters/common/widgets/setting_list_tile.dart';
import 'package:counters/features/dev/animation_demo_page.dart';
import 'package:counters/features/dev/performance_demo.dart';
import 'package:counters/features/setting/about_page.dart'; // 导入新的关于应用页面
import 'package:counters/features/setting/data_manager.dart';
import 'package:counters/features/setting/theme_provider.dart';
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
  bool _enableProviderLogger = false;
  bool _enableDesktopMode = false;
  bool _enableVerboseLog = false;
  static const String _keyEnableProviderLogger = 'enable_provider_logger';
  static const String _keyEnableDesktopMode = 'enable_desktop_mode';
  static const String _keyEnableVerboseLog = 'enable_verbose_log';

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
    _loadDesktopModeSetting();
    _loadVerboseLogSetting();
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
                  subtitle: '选择 自动 ，将根据系统设置自动切换',
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
                SettingListTile(
                  icon: Icons.article,
                  title: '程序日志',
                  subtitle: '提供局域网状态和程序日志查看',
                  onTap: () {
                    Navigator.pushNamed(context, '/lan_test');
                  },
                ),
                SettingSwitchListTile(
                  icon: Icons.desktop_windows,
                  title: '启用桌面模式适配',
                  subtitle: '测试中功能，启用并重启后程序支持横屏界面',
                  value: _enableDesktopMode,
                  onChanged: _saveDesktopModeSetting,
                ),
                _buildSectionHeader('关于'),
                SettingListTile(
                  icon: Icons.info,
                  title: '关于应用',
                  subtitle: '了解 ${Config.appName}',
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
                    Config.urlGithub,
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
                    icon: Icons.animation,
                    title: '页面动画演示',
                    subtitle: '查看各种页面切换动画效果',
                    onTap: () => Navigator.of(context).pushWithSlide(
                      const AnimationDemoPage(),
                      direction: SlideDirection.fromRight,
                      duration: const Duration(milliseconds: 300),
                    ),
                  ),
                  SettingListTile(
                    icon: Icons.speed,
                    title: '性能测试',
                    subtitle: '性能测试',
                    onTap: () => Navigator.of(context).pushWithSlide(
                      const PerformanceDemoPage(),
                      direction: SlideDirection.fromRight,
                      duration: const Duration(milliseconds: 300),
                    ),
                  ),
                  SettingSwitchListTile(
                    icon: Icons.article,
                    title: '启用 Provider 调试日志',
                    subtitle: '重启应用后生效，仅在控制台输出',
                    value: _enableProviderLogger,
                    onChanged: _saveProviderLoggerSetting,
                  ),
                  SettingSwitchListTile(
                    icon: Icons.bug_report,
                    title: '启用 Verbose 级别日志',
                    subtitle: '显示最详细的日志信息，包括UI组件调试信息',
                    value: _enableVerboseLog,
                    onChanged: _saveVerboseLogSetting,
                  ),
                  SettingListTile(
                    icon: Icons.science,
                    title: '测试日志级别',
                    subtitle: '测试各个级别的日志输出',
                    onTap: _testLogLevels,
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
    GlobalMsgManager.showMessage('设置已保存，重启应用后生效');
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

  // 加载Verbose日志设置
  Future<void> _loadVerboseLogSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enableVerboseLog = prefs.getBool(_keyEnableVerboseLog) ?? false;
    });
  }

  // 保存Verbose日志设置
  Future<void> _saveVerboseLogSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnableVerboseLog, value);
    setState(() {
      _enableVerboseLog = value;
    });

    // 同时更新Provider中的状态
    ref.read(verboseLogProvider.notifier).setVerboseLogEnabled(value);

    GlobalMsgManager.showMessage('Verbose日志已${value ? '启用' : '禁用'}');
  }

  // 测试日志级别
  void _testLogLevels() {
    // 先输出当前日志级别信息
    final verboseEnabled = ref.read(verboseLogProvider);
    Log.i('=== 日志级别测试开始 ===');
    Log.i('当前Verbose日志状态: ${verboseEnabled ? '启用' : '禁用'}');
    Log.i('当前日志级别: ${verboseEnabled ? 'Trace (包含Verbose)' : 'Debug (不包含Verbose)'}');

    // 输出各级别日志
    Log.v('这是Verbose级别日志 - 最详细的调试信息 ${verboseEnabled ? '(应该显示)' : '(应该被过滤)'}');
    Log.d('这是Debug级别日志 - 调试信息 (应该显示)');
    Log.i('这是Info级别日志 - 一般信息 (应该显示)');
    Log.w('这是Warning级别日志 - 警告信息 (应该显示)');
    Log.e('这是Error级别日志 - 错误信息 (应该显示)');

    // 也测试带颜色的verbose日志
    Log.verbose('这是带颜色的Verbose日志 ${verboseEnabled ? '(应该显示)' : '(应该被过滤)'}', color: Colors.grey);

    Log.i('=== 日志级别测试结束 ===');

    GlobalMsgManager.showMessage(
        '已输出各级别日志，请查看程序日志页面\n当前Verbose: ${verboseEnabled ? '启用' : '禁用'}');
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

    // 在显示菜单前获取 themeProvider.notifier
    final themeNotifier = ref.read(themeProvider.notifier);

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
}
