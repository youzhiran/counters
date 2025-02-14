import 'package:counters/screens/game_session_screen.dart';
import 'package:counters/screens/home_screen.dart';
import 'package:counters/screens/setting_screen.dart';
import 'package:counters/screens/template_config_screen.dart';
import 'package:counters/screens/template_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models.dart';
import 'providers/score_provider.dart';
import 'providers/template_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化Hive
  await Hive.initFlutter();

  // 注册适配器
  Hive.registerAdapter(ScoreTemplateAdapter());
  Hive.registerAdapter(PlayerInfoAdapter());
  Hive.registerAdapter(GameSessionAdapter());
  Hive.registerAdapter(PlayerScoreAdapter());

  // 打开模板盒子
  final templateBox = await Hive.openBox<ScoreTemplate>('templates');

  runApp(MyApp(templateBox: templateBox)); // 传入Box实例
}

class MyApp extends StatelessWidget {
  final Box<ScoreTemplate> templateBox; // 添加构造函数参数

  const MyApp({
    required this.templateBox,
    super.key, // 添加key参数
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => TemplateProvider(templateBox),
          ),
          ChangeNotifierProvider(create: (_) => ScoreProvider()),
        ],
        child: MaterialApp(
          title: '桌游计分器',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            appBarTheme: const AppBarTheme(
              elevation: 0, // 统一阴影效果
              centerTitle: true, // 标题居中
            ),
          ),
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
        ));
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

  // 新增初始化方法
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  // 新增销毁方法
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        // 选中颜色
        unselectedItemColor: Colors.grey,
        // 未选中颜色
        showUnselectedLabels: true,
        // 始终显示标签
        type: BottomNavigationBarType.fixed,
        // 固定布局
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '主页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: '模板',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
