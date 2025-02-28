import 'package:counters/page/game_session.dart';
import 'package:counters/page/home.dart';
import 'package:counters/page/setting.dart';
import 'package:counters/page/template.dart';
import 'package:counters/page/template_config.dart';
import 'package:counters/state.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'model/models.dart';
import 'providers/score_provider.dart';
import 'providers/template_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化Hive
  await Hive.initFlutter();

  // 清除Hive数据，调试使用！！
  // await Hive.deleteBoxFromDisk('gameSessions');
  // await Hive.deleteBoxFromDisk('templates');

  // 注册适配器
  Hive.registerAdapter(ScoreTemplateAdapter());
  Hive.registerAdapter(PlayerInfoAdapter());
  Hive.registerAdapter(GameSessionAdapter());
  Hive.registerAdapter(PlayerScoreAdapter());

  // 会话存储初始化
  await Hive.openBox<GameSession>('gameSessions');

  // 初始化全局状态
  await globalState.initialize();

  // 打开模板盒子
  final templateBox = await Hive.openBox<ScoreTemplate>('templates');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => globalState), // 添加全局状态提供者
        ChangeNotifierProvider(create: (_) => TemplateProvider(templateBox)),
        ChangeNotifierProvider(create: (_) => ScoreProvider()),
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
          title: '桌游计分器',
          theme: _buildTheme(state.themeColor, Brightness.light),
          darkTheme: _buildTheme(state.themeColor, Brightness.dark),
          themeMode: state.themeMode,
          routes: {
            '/': (context) => const MainTabsScreen(),
            '/game_session': (context) => Scaffold(
                  // 为子页面包裹Scaffold
                  appBar: AppBar(
                    title: const Text('游戏进行中'),
                    leading: BackButton(), // 自动显示返回按钮
                  ),
                  body: GameSessionScreen(
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
                  body: TemplateConfigScreen(
                    baseTemplate: ModalRoute.of(context)!.settings.arguments
                        as ScoreTemplate,
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
  const MainTabsScreen({super.key});

  @override
  _MainTabsScreenState createState() => _MainTabsScreenState();
}

class _MainTabsScreenState extends State<MainTabsScreen> {
  int _selectedIndex = 0;
  late PageController _pageController; // 保持late声明

  final List<Widget> _screens = [
    const HomeScreen(),
    const TemplateScreen(),
    const SettingScreen(),
  ];

  // 初始化方法
  @override
  void initState() {
    super.initState();
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
    final List<String> appBarTitles = ['首页', '模板', '设置'];

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitles[_selectedIndex]),
        automaticallyImplyLeading: false, // 隐藏默认返回按钮
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
