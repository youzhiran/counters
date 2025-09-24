import 'dart:io';
import 'dart:ui';

import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:counters/app/config.dart';
import 'package:counters/app/state.dart';
import 'package:counters/common/db/db_helper.dart';
import 'package:counters/common/model/poker50.dart';
import 'package:counters/common/providers/log_export_provider.dart';
import 'package:counters/common/providers/log_provider.dart';
import 'package:counters/common/utils/error_handler.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/common/utils/net.dart';
import 'package:counters/common/utils/platform_utils.dart';
import 'package:counters/common/utils/privacy.dart';
import 'package:counters/common/widgets/message_overlay.dart';
import 'package:counters/common/widgets/update_dialog.dart';
import 'package:counters/features/dev/message_debug_page.dart';
import 'package:counters/features/lan/log_test_page.dart';
import 'package:counters/features/player/player_page.dart';
import 'package:counters/features/score/poker50/config.dart';
import 'package:counters/features/setting/analytics_provider.dart';
import 'package:counters/features/setting/data_manager.dart';
import 'package:counters/features/setting/log_settings_page.dart';
import 'package:counters/features/setting/setting_page.dart';
import 'package:counters/features/setting/theme_provider.dart';
import 'package:counters/features/setting/update_check_provider.dart';
import 'package:counters/features/template/template_page.dart';
import 'package:counters/home_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 全局异常捕获
  FlutterError.onError = (FlutterErrorDetails details) {
    ErrorHandler.handle(details.exception, details.stack, prefix: 'Flutter错误');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorHandler.handle(error, stack, prefix: '未捕获错误');
    return true;
  };

  // 按平台初始化
  if (Platform.operatingSystem == 'ohos') {
    // await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    sqfliteFfiInit();
    Log.i('=====初始化:鸿蒙平台=====');
  } else if (Platform.isAndroid) {
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    sqfliteFfiInit();
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // 初始化窗口管理器
    await windowManager.ensureInitialized();
    await windowManager.setMinimumSize(const Size(396, 594));
    await windowManager.setTitle('得益计分');
  }

  try {
    // 初始化数据库
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.database;
  } catch (e) {
    Log.e('数据库初始化失败: $e');
  }

  // 初始化数据管理器
  try {
    await DataManager.initialize();
  } catch (e) {
    Log.e('数据管理器初始化失败: $e');
  }

  // 初始化全局状态
  await globalState.init();

  // 初始化平台工具缓存（用于同步判断是否按鸿蒙平台行为处理）
  await PlatformUtils.init();

  // 获取Provider调试设置、Verbose日志设置、Clarity调试设置和匿名统计设置
  final prefs = await SharedPreferences.getInstance();
  final enableProviderLogger = prefs.getBool('enable_provider_logger') ?? false;
  final enableVerboseLog = prefs.getBool('enable_verbose_log') ?? false;
  final enableClarityDebug = prefs.getBool('enable_clarity_debug') ?? false;
  final enableAnalytics = await AnalyticsNotifier.getAnalyticsEnabled();

  // 根据设置初始化日志级别
  if (enableVerboseLog) {
    Log.setLevel(Level.trace); // 启用verbose时使用trace级别
    Log.i('应用启动: Verbose日志已启用');
    Log.v('这是一条测试Verbose日志');
  } else {
    Log.setLevel(Level.debug); // 禁用verbose时使用debug级别
    Log.i('应用启动: Verbose日志已禁用');
  }

  // 输出匿名统计和Clarity初始化信息
  Log.i('匿名统计设置: ${enableAnalytics ? '启用' : '禁用'}');
  Log.i(
      'Clarity 初始化: 项目ID=r8m6tk8tfr, 调试模式=${enableClarityDebug ? '启用' : '禁用'}');

  // 创建应用Widget
  Widget app = const MyApp();

  // 根据匿名统计设置决定是否包装ClarityWidget
  if (Platform.operatingSystem == 'ohos') {
    Log.i('Clarity已禁用（鸿蒙平台匿名统计关闭）');
  } else if (enableAnalytics) {
    final clarityConfig = ClarityConfig(
      projectId: "r8m6tk8tfr",
      logLevel: enableClarityDebug ? LogLevel.Debug : LogLevel.None,
    );

    app = ClarityWidget(
      clarityConfig: clarityConfig,
      app: app,
    );
    Log.i('Clarity已启用');
  } else {
    Log.i('Clarity已禁用（匿名统计关闭）');
  }

  // 创建 ProviderScope，不再使用废弃的 parent 参数
  runApp(
    ProviderScope(
      observers: enableProviderLogger ? [PLogger()] : null,
      // 根据设置决定是否启用Provider调试
      child: app,
    ),
  );
}

/// 在应用启动时根据设置检查更新
Future<void> _checkUpdateOnStartup(ProviderContainer container) async {
  if (PlatformUtils.isOhosPlatformSync()) {
    Log.d('鸿蒙平台不检查更新');
    return;
  }
  try {
    // 延迟一段时间，确保应用完全启动
    await Future.delayed(const Duration(seconds: 2));

    final updateCheckNotifier = container.read(updateCheckProvider.notifier);

    // 检查是否应该检查更新
    if (!updateCheckNotifier.shouldCheckUpdate) {
      Log.d('启动时更新检查已禁用');
      return;
    }

    Log.i('启动时检查更新: 包含测试版=${updateCheckNotifier.includePrereleases}');

    // 执行更新检查
    final result = await UpdateChecker.isUpdateAvailable(
      includePrereleases: updateCheckNotifier.includePrereleases,
    );

    // 如果有更新，检查是否被忽略
    if (result.startsWith('v')) {
      // 检查版本是否被忽略
      final isIgnored = await UpdateIgnoreManager.isVersionIgnored(result);
      if (isIgnored) {
        Log.d('启动时更新检查: 版本已被忽略，跳过提示');
        return;
      }

      Log.i('发现新版本，显示更新提示');
      // 在主线程中显示启动时更新对话框
      WidgetsBinding.instance.addPostFrameCallback((_) {
        globalState.showCommonDialog(
          child: StartupUpdateDialog(
            versionInfo: result,
            hasUpdate: true,
          ),
        );
      });
    } else {
      Log.d('启动时更新检查完成，无新版本');
    }
  } catch (e) {
    ErrorHandler.handle(e, StackTrace.current, prefix: '启动时检查更新失败');
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _isInitialized = false;
  bool _privacyInitialized = false; // 添加隐私政策初始化标志

  @override
  void initState() {
    super.initState();
    // 在应用启动后初始化主题提供者和全局消息管理器
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_isInitialized) {
        _isInitialized = true;
        try {
          // 获取 ProviderScope 的容器
          final container = ProviderScope.containerOf(context);

          // 初始化主题提供者
          await container.read(themeProvider.notifier).init();

          // 初始化verbose日志Provider（这会加载设置并应用日志级别）
          container.read(verboseLogProvider);

          // 初始化日志导出Provider（这会检查设置并自动启动监听器）
          container.read(logExportProvider);

          // 初始化更新检查设置Provider
          await container.read(updateCheckProvider.notifier).initialize();

          // 设置全局消息管理器容器
          GlobalMsgManager.setContainer(container);

          // 根据设置检查更新
          _checkUpdateOnStartup(container);
        } catch (e) {
          ErrorHandler.handle(e, StackTrace.current, prefix: '主题初始化失败');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 监听主题状态变化
    final themeState = ref.watch(themeProvider);

    return MaterialApp(
      navigatorKey: globalState.navigatorKey,
      scaffoldMessengerKey: globalState.scaffoldMessengerKey,
      title: '得益计分',
      theme: _buildTheme(themeState.themeColor, Brightness.light, ref),
      darkTheme: _buildTheme(themeState.themeColor, Brightness.dark, ref),
      themeMode: themeState.themeMode,
      home: Builder(
        builder: (context) {
          // 隐私政策弹窗初始化
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_privacyInitialized) {
              _privacyInitialized = true;
              PrivacyUtil.initWithPrivacy(context);
            }
          });
          return const MessageOverlay(
            child: MainTabsScreen(),
          );
        },
      ),
      routes: {
        '/templates': (context) =>
            const MessageOverlay(child: MainTabsScreen(initialIndex: 2)),
        // 添加主页面路由
        '/main': (context) => const MessageOverlay(child: MainTabsScreen()),
        // 添加测试页面路由
        '/log_test': (context) => const LogTestPage(),
        // 添加消息调试页面
        '/message_debug': (context) => const MessageDebugPage(),
        // 添加日志设置页面路由
        '/log_settings': (context) => const LogSettingsPage(),
        '/template/config': (context) => Scaffold(
              appBar: AppBar(
                title: const Text('模板配置'),
                leading: BackButton(),
                actions: [
                  /* 原有保存按钮 */
                ],
              ),
              body: Poker50ConfigPage(
                oriTemplate: ModalRoute.of(context)!.settings.arguments
                    as Poker50Template,
              ),
            ),
      },
    );
  }

  ThemeData _buildTheme(Color seedColor, Brightness brightness, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final String? selectedFontFamily = themeState.fontFamily;

    return ThemeData(
      useMaterial3: true,
      // 如果用户选择了特定的字体，则使用该字体，否则（系统推荐）使用 fallback 列表
      fontFamily: selectedFontFamily,
      fontFamilyFallback: Config.chineseFontFallbacks,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 1000), // 设置延迟1秒
        showDuration: const Duration(milliseconds: 2000), // 设置显示2秒
      ),
      appBarTheme: const AppBarTheme(
        elevation: 1,
        scrolledUnderElevation: 3,
      ),
      filledButtonTheme: FilledButtonThemeData(style: ButtonStyle()),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      navigationRailTheme: NavigationRailThemeData(
        // 禁用侧边导航栏图标高亮的过渡动画
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        useIndicator: true,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

// MainTabsScreen 是应用程序的主界面，包含主要的 Tab。
// 它根据屏幕尺寸和用户设置切换使用底部导航栏或侧边导航栏。
class MainTabsScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainTabsScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainTabsScreen> createState() => _MainTabsScreenState();
}

// _MainTabsScreenState 管理 MainTabsScreen 的状态，包括当前选中的 Tab 索引和 PageController。
class _MainTabsScreenState extends ConsumerState<MainTabsScreen>
    with WidgetsBindingObserver {
  late int _selectedIndex;
  late PageController _pageController;
  bool _isAnimating = false; // 标记是否正在执行页面切换动画

  // 定义导航目标常量列表，包含每个 Tab 的图标和标签文本。
  static const List<({Icon icon, Icon selectedIcon, String label})>
      _navigationItems = [
    (
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: '主页',
    ),
    (
      icon: Icon(Icons.people_outline),
      selectedIcon: Icon(Icons.people),
      label: '玩家',
    ),
    (
      icon: Icon(Icons.view_list_outlined),
      selectedIcon: Icon(Icons.view_list),
      label: '模板',
    ),
    (
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: '设置',
    ),
  ];

  // 定义与导航目标对应的屏幕 Widget 列表。
  final List<Widget> _screens = [
    const HomePage(),
    const PlayerManagementPage(),
    const TemplatePage(),
    const SettingPage(),
  ];

  // 判断当前是否处于桌面模式
  // 使用统一的桌面模式判断逻辑
  bool get isDesktopMode {
    if (!mounted) return false;
    return globalState.isDesktopMode(context);
  }

  @override
  void initState() {
    super.initState();
    // 尝试从 PageStorage 中恢复保存的页面索引，或者使用初始索引。
    final initialPage = PageStorage.of(context)
            .readState(context, identifier: 'mainTabsPage') as int? ??
        widget.initialIndex; // 使用 widget.initialIndex 作为默认值
    _selectedIndex = initialPage; // 初始化 _selectedIndex 为恢复的或初始的页面索引

    // 初始化 PageController，使用恢复的或初始的页面索引。
    _pageController = PageController(initialPage: _selectedIndex);

    // 添加屏幕指标变化的监听器，用于处理屏幕旋转等情况。
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // 销毁 PageController。
    _pageController.dispose();
    // 移除屏幕指标变化的监听器。
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 当屏幕指标发生变化时调用（例如屏幕旋转或进入分屏模式）。
  @override
  void didChangeMetrics() {
    super.didChangeMetrics(); // 调用父类方法是一个好习惯
    // 当屏幕指标发生变化时（如旋转），确保 PageView 显示当前选中的页面。
    // 使用 WidgetsBinding.instance.addPostFrameCallback 确保在布局完成后执行跳转。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients &&
          _pageController.page?.round() != _selectedIndex) {
        _pageController.jumpToPage(_selectedIndex);
      }
    });
  }

  // 处理底部或侧边导航栏项目点击事件。
  void _onItemTapped(int index) {
    // 只有当点击的项目不是当前选中项且不在动画中时才进行更新和跳转。
    if (_selectedIndex != index && !_isAnimating) {
      final shouldAnimate = (_selectedIndex - index).abs() == 1;

      // 立即更新导航栏状态，避免图标跟随页面滑动
      setState(() {
        _selectedIndex = index;
        _isAnimating = shouldAnimate;
        // 保存当前的页面索引到 PageStorage，以便应用重启后恢复。
        PageStorage.of(context)
            .writeState(context, index, identifier: 'mainTabsPage');
      });

      if (!_pageController.hasClients) {
        if (shouldAnimate && mounted) {
          setState(() {
            _isAnimating = false;
          });
        } else {
          _isAnimating = false;
        }
        return;
      }

      if (shouldAnimate) {
        // 相邻页面保持平滑动画
        _pageController
            .animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        )
            .then((_) {
          if (mounted) {
            setState(() {
              _isAnimating = false;
            });
          }
        });
      } else {
        // 跨多个标签时直接跳转以避免明显的滚动痕迹
        _pageController.jumpToPage(index);
        _isAnimating = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 根据是否处于桌面模式来构建不同的布局。
    if (isDesktopMode) {
      // 桌面模式：使用 Scaffold + Row + NavigationRail + Expanded(PageView)
      return Scaffold(
        body: Row(
          children: [
            // 侧边导航栏 NavigationRail。
            NavigationRail(
              // 使用统一的 NavigationRail 扩展判断逻辑
              extended: globalState.shouldExtendNavigationRail(context),
              selectedIndex: _selectedIndex,
              // 使用 _selectedIndex
              onDestinationSelected: _onItemTapped,
              minWidth: 72,
              minExtendedWidth: 120,
              useIndicator: true,
              groupAlignment: -0.85,
              // 生成 NavigationRailDestination 列表。
              destinations: _navigationItems
                  .map((item) => NavigationRailDestination(
                        icon: item.icon,
                        selectedIcon: item.selectedIcon,
                        label: Text(item.label),
                      ))
                  .toList(),
            ),
            // 分隔线。
            const VerticalDivider(thickness: 1, width: 1),
            // PageView 占据剩余空间，显示当前选中的页面。
            Expanded(
              child: PageView(
                // 添加 PageStorageKey 来保存和恢复页面位置。
                key: const PageStorageKey<String>('mainTabsPageView'),
                physics: const ClampingScrollPhysics(),
                // 启用滑动切换，添加滑动动画
                controller: _pageController,
                onPageChanged: (index) {
                  // 只有在非动画状态下（用户手动滑动）才更新导航栏状态
                  if (!_isAnimating) {
                    setState(() {
                      _selectedIndex = index;
                      PageStorage.of(context).writeState(context, index,
                          identifier: 'mainTabsPage');
                    });
                  }
                },
                children: _screens,
              ),
            ),
          ],
        ),
      );
    } else {
      // 非桌面模式（移动设备）：使用 Scaffold + PageView + BottomNavigationBar
      return Scaffold(
        body: PageView(
          // 添加 PageStorageKey 来保存和恢复页面位置。
          key: const PageStorageKey<String>('mainTabsPageView'),
          physics: const ClampingScrollPhysics(),
          // 启用滑动切换，添加滑动动画
          controller: _pageController,
          onPageChanged: (index) {
            // 只有在非动画状态下（用户手动滑动）才更新导航栏状态
            if (!_isAnimating) {
              setState(() {
                _selectedIndex = index;
                PageStorage.of(context)
                    .writeState(context, index, identifier: 'mainTabsPage');
              });
            }
          },
          children: _screens,
        ),
        // 底部导航栏 NavigationBar。
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex, // 使用 _selectedIndex
          onDestinationSelected: _onItemTapped,
          // 生成 NavigationDestination 列表。
          destinations: _navigationItems
              .map((item) => NavigationDestination(
                    icon: item.icon,
                    selectedIcon: item.selectedIcon,
                    label: item.label,
                  ))
              .toList(),
        ),
      );
    }
  }
}
