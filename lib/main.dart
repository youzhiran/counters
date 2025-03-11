import 'dart:io';
import 'dart:ui';

import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:counters/page/home.dart';
import 'package:counters/page/player_management.dart';
import 'package:counters/page/poker50/config.dart';
import 'package:counters/page/poker50/session.dart';
import 'package:counters/page/setting.dart';
import 'package:counters/page/template.dart';
import 'package:counters/state.dart';
import 'package:counters/utils/log.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'db/db_helper.dart';
import 'db/poker50.dart';
import 'providers/player_provider.dart';
import 'providers/score_provider.dart';
import 'providers/template_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 全局异常捕获
  FlutterError.onError = (FlutterErrorDetails details) {
    Log.e('Flutter 错误: ${details.exception}');
    Log.e('Stack: ${details.stack}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    Log.e('未捕获错误: $error');
    Log.e('Stack: $stack');
    return true;
  };

  // 初始化 SQLite
  if (Platform.isAndroid) {
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    sqfliteFfiInit();
  } else if (Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  try {
    // 初始化数据库
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.database;
  } catch (e) {
    Log.e('数据库初始化失败: $e');
  }

  // 初始化全局状态
  await globalState.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => globalState),
        ChangeNotifierProvider(create: (_) => TemplateProvider()),
        ChangeNotifierProvider(create: (_) => ScoreProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GlobalState>(
      // 监听主题变化
      builder: (context, state, child) {
        return MaterialApp(
          navigatorKey: globalState.navigatorKey,
          scaffoldMessengerKey: globalState.scaffoldMessengerKey,
          title: '桌游计分器',
          theme: _buildTheme(state.themeColor, Brightness.light)
              .useSystemChineseFont(Brightness.light),
          darkTheme: _buildTheme(state.themeColor, Brightness.dark)
              .useSystemChineseFont(Brightness.dark),
          themeMode: state.themeMode,
          routes: {
            '/': (context) => const MainTabsScreen(),
            '/templates': (context) => const MainTabsScreen(initialIndex: 2),
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
      },
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

class MainTabsScreen extends StatefulWidget {
  final int initialIndex;

  const MainTabsScreen({super.key, this.initialIndex = 0});

  @override
  State<MainTabsScreen> createState() => _MainTabsScreenState();
}

class _MainTabsScreenState extends State<MainTabsScreen> {
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
    final List<String> appBarTitles = ['首页', '玩家', '模板', '设置'];

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitles[_selectedIndex]),
        automaticallyImplyLeading: false,
        actions: _selectedIndex == 1
            ? [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    showSearch(
                      context: context,
                      delegate: PlayerSearchDelegate(),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  onPressed: () {
                    const PlayerManagementPage().showDeleteAllDialog(context);
                  },
                ),
              ]
            : null,
      ),
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
