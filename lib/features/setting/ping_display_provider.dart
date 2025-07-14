import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'ping_display_provider.g.dart';

/// PingWidget 显示设置 Provider
/// 控制是否在计分界面显示 PingWidget
@Riverpod(keepAlive: true)
class PingDisplaySetting extends _$PingDisplaySetting {
  static const String _keyShowPingWidget = 'show_ping_widget';

  @override
  bool build() {
    // 默认显示 PingWidget
    _loadSetting();
    return true;
  }

  /// 从 SharedPreferences 加载设置
  Future<void> _loadSetting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final showPingWidget = prefs.getBool(_keyShowPingWidget) ?? true;
      state = showPingWidget;
    } catch (e) {
      // 加载失败时使用默认值
      state = true;
    }
  }

  /// 设置是否显示 PingWidget
  Future<void> setShowPingWidget(bool show) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyShowPingWidget, show);
      state = show;
    } catch (e) {
      // 保存失败时不更新状态
      rethrow;
    }
  }

  /// 切换显示状态
  Future<void> toggle() async {
    await setShowPingWidget(!state);
  }
}
