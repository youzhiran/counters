import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 主页标签控制器，负责维护当前选中的标签索引
class MainTabController extends StateNotifier<int> {
  MainTabController() : super(0);

  bool _hasInitialized = false;

  /// 首次同步外部指定的初始索引，避免重复写入状态
  void syncInitialIndex(int index) {
    if (_hasInitialized) {
      return;
    }
    _hasInitialized = true;
    state = index;
  }

  /// 切换到指定索引
  void selectTab(int index) {
    _hasInitialized = true;
    state = index;
  }
}

/// 全局提供器，供各模块读取或更新主页标签索引
final mainTabControllerProvider = StateNotifierProvider<MainTabController, int>(
  (ref) => MainTabController(),
);
