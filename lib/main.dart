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
import 'package:counters/features/score/template_page.dart';
import 'package:counters/features/setting/setting.dart';
import 'package:counters/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:window_manager/window_manager.dart';

import 'app/state.dart';
import 'features/setting/theme_provider.dart';

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

class _MainTabsScreenState extends ConsumerState<MainTabsScreen> {
  late int _selectedIndex;
  late PageController _pageController; // 保持late声明

  final List<Widget> _screens = [
    const HomePage(),
    const PlayerManagementPage(),
    const TemplatePage(),
    const SettingPage(),
  ];

  // 初始化方法
  @override
  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _selectedIndex);
  }

  // 销毁方法
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: _pageController,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '主页',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: '玩家',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_list_outlined),
            selectedIcon: Icon(Icons.view_list),
            label: '模板',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
