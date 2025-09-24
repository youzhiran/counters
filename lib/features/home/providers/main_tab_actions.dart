import 'package:counters/app/state.dart';
import 'package:counters/common/utils/log.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'main_tab_controller.dart';

/// WidgetRef 上的标签页便捷操作
extension MainTabActions on WidgetRef {
  /// 简单切换标签，不改变当前路由栈
  void switchMainTab(int index) {
    read(mainTabControllerProvider.notifier).selectTab(index);
  }

  /// 回到主界面并切换到目标标签
  void popToMainTab(int index) {
    final navigator = globalState.navigatorKey.currentState;
    if (navigator == null) {
      Log.e('未找到全局导航器，无法切换标签');
      return;
    }
    navigator.popUntil((route) => route.isFirst);
    read(mainTabControllerProvider.notifier).selectTab(index);
  }
}
