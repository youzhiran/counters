import 'dart:io';
import 'dart:ui';

import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:counters/common/db/db_helper.dart';
import 'package:counters/common/model/poker50.dart';
import 'package:counters/common/utils/error_handler.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/common/utils/umeng.dart';
import 'package:counters/features/lan/lan_test_page.dart';
import 'package:counters/features/player/player_page.dart';
import 'package:counters/features/score/poker50/config.dart';
import 'package:counters/features/score/poker50/poker50_page.dart';
import 'package:counters/features/setting/setting.dart';
import 'package:counters/features/template/template_page.dart';
import 'package:counters/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:window_manager/window_manager.dart';

import 'app/state.dart';
import 'features/setting/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 设置屏幕方向
  if (Platform.isAndroid || Platform.isIOS) {
    // 在移动设备上锁定为竖屏
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // 在桌面端允许所有方向
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  // 全局异常捕获
  FlutterError.onError = (FlutterErrorDetails details) {
    ErrorHandler.handle(details.exception, details.stack, prefix: 'Flutter错误');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorHandler.handle(error, stack, prefix: '未捕获错误');
    return true;
  };

  // 按平台初始化
  if (Platform.isAndroid) {
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    sqfliteFfiInit();
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // 初始化窗口管理器
    await windowManager.ensureInitialized();
    await windowManager.setMinimumSize(const Size(396, 594));
    await windowManager.setTitle('桌游计分器');
  }

  try {
    // 初始化数据库
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.database;
  } catch (e) {
    Log.e('数据库初始化失败: $e');
  }

  // 初始化全局状态
  await globalState.init();

  // 创建容器并初始化主题提供者
  final container = ProviderContainer();
  await container.read(themeProvider.notifier).init();

  // 获取Provider调试设置
  final prefs = await SharedPreferences.getInstance();
  final enableProviderLogger = prefs.getBool('enable_provider_logger') ?? false;

  runApp(ProviderScope(
    observers:
        enableProviderLogger ? [PLogger()] : null, // 根据设置决定是否启用Provider调试
    child: const MyApp(),
  ));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听主题状态变化
    final themeState = ref.watch(themeProvider);

    return MaterialApp(
      navigatorKey: globalState.navigatorKey,
      scaffoldMessengerKey: globalState.scaffoldMessengerKey,
      title: '桌游计分器',
      theme: _buildTheme(themeState.themeColor, Brightness.light)
          .useSystemChineseFont(Brightness.light),
      darkTheme: _buildTheme(themeState.themeColor, Brightness.dark)
          .useSystemChineseFont(Brightness.dark),
      themeMode: themeState.themeMode,
      home: Builder(
        builder: (context) {
          // 只在第一次构建时初始化友盟
          WidgetsBinding.instance.addPostFrameCallback((_) {
            UmengUtil.initWithPrivacy(context);
          });
          return const MainTabsScreen();
        },
      ),
      routes: {
        '/templates': (context) => const MainTabsScreen(initialIndex: 2),
        '/lan_test': (context) => const LanTestPage(), // 添加测试页面路由
        '/poker50_session': (context) => Scaffold(
              // 为子页面包裹Scaffold
              appBar: AppBar(
                title: const Text('游戏进行中'),
                leading: BackButton(), // 自动显示返回按钮
              ),
              body: Poker50SessionPage(
                templateId:
                    ModalRoute.of(context)!.settings.arguments as String,
              ),
            ),
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

  /// 显示开发阶段提示对话框
  Future<void> showDevAlert(BuildContext context, WidgetRef ref) async {
    await globalState.showCommonDialog(
      child: AlertDialog(
        title: const Text('提示'),
        content: const Text('本程序仍处于积极开发阶段，程序更新不考虑数据兼容性。'
            '\n\n如遇到异常，请尝试以下方法：'
            '\n1. 在系统设置中清除本程序数据'
            '\n2. 在程序设置中重置数据库'
            '\n3. 重新安装程序'),
        actions: [
          TextButton(
            child: const Text('我知道了'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  ThemeData _buildTheme(Color seedColor, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
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
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

class MainTabsScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainTabsScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainTabsScreen> createState() => _MainTabsScreenState();
}

class _MainTabsScreenState extends ConsumerState<MainTabsScreen>
    with WidgetsBindingObserver {
  late int _selectedIndex;
  late PageController _pageController;

  // 定义导航目标常量
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

  final List<Widget> _screens = [
    const HomePage(),
    const PlayerManagementPage(),
    const TemplatePage(),
    const SettingPage(),
  ];

  // 判断是否为桌面模式
  bool get isDesktopMode {
    // 在使用 MediaQuery 之前确保 context 可用
    if (!mounted) return false; // 或者一个默认值，比如 false
    final width = MediaQuery.of(context).size.width;
    return width >= 600;
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _selectedIndex);

    // 添加屏幕方向变化监听
    WidgetsBinding.instance.addObserver(this);

    // 在第一帧构建完成后，同步 _selectedIndex 和 PageController 的实际页面。
    // 这处理了 PageController 从 PageStorage 恢复页面的情况。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _pageController.hasClients &&
          _pageController.page != null) {
        final currentPageFromController = _pageController.page!.round();
        if (_selectedIndex != currentPageFromController) {
          // 如果 PageController 恢复的页面与当前 _selectedIndex 不同，
          // 更新 _selectedIndex 以保持同步，避免 didChangeMetrics 使用错误的索引。
          setState(() {
            _selectedIndex = currentPageFromController;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    // 移除屏幕方向变化监听
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics(); // 调用父类方法是一个好习惯
    // 当屏幕指标发生变化时（例如旋转），确保 PageView 位于正确的页面。
    // _selectedIndex 此时应该由于 initState 中的 postFrameCallback
    // 或用户通过 _onItemTapped 的交互而保持最新。
    if (mounted && _pageController.hasClients) {
      // 检查控制器的页面是否已经是它应该在的位置。
      // 这可以防止在页面已经正确时进行不必要的跳转。
      // page 可能是 null 或 double，所以取整进行比较。
      final controllerPage = _pageController.page?.round();
      if (controllerPage != _selectedIndex) {
        // 使用 jumpToPage，因为 animateToPage 在方向更改期间可能会有视觉上的突兀感。
        _pageController.jumpToPage(_selectedIndex);
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // 如果 PageView 不允许用户滑动，使用 jumpToPage 进行即时更改，无需动画。
      _pageController.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isDesktopMode) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: MediaQuery.of(context).size.width >= 800,
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              minWidth: 72,
              minExtendedWidth: 130,
              useIndicator: true,
              groupAlignment: -0.85,
              destinations: _navigationItems
                  .map((item) => NavigationRailDestination(
                        icon: item.icon,
                        selectedIcon: item.selectedIcon,
                        label: Text(item.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: PageView(
                physics: const NeverScrollableScrollPhysics(), // 禁止用户滑动切换
                controller: _pageController,
                children: _screens,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: PageView(
        physics: const NeverScrollableScrollPhysics(), // 禁止用户滑动切换
        controller: _pageController,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
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
