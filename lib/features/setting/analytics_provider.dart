import 'package:counters/common/utils/error_handler.dart';
import 'package:counters/common/utils/log.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 匿名统计设置状态
class AnalyticsState {
  final bool isEnabled;
  final bool isLoading;
  final String? error;

  const AnalyticsState({
    required this.isEnabled,
    this.isLoading = false,
    this.error,
  });

  AnalyticsState copyWith({
    bool? isEnabled,
    bool? isLoading,
    String? error,
  }) {
    return AnalyticsState(
      isEnabled: isEnabled ?? this.isEnabled,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 匿名统计设置Provider
class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  static const String _keyAnalyticsEnabled = 'analytics_enabled';

  AnalyticsNotifier() : super(const AnalyticsState(isEnabled: true)) {
    _loadSettings();
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool(_keyAnalyticsEnabled) ?? true; // 默认开启
      
      state = state.copyWith(
        isEnabled: isEnabled,
        isLoading: false,
      );
      
      Log.d('匿名统计设置已加载: $isEnabled');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '加载匿名统计设置失败',
      );
      ErrorHandler.handle(e, StackTrace.current, prefix: '加载匿名统计设置失败');
    }
  }

  /// 设置匿名统计开关
  Future<void> setAnalyticsEnabled(bool enabled) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAnalyticsEnabled, enabled);
      
      state = state.copyWith(
        isEnabled: enabled,
        isLoading: false,
      );
      
      Log.i('匿名统计设置已更新: $enabled');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '保存匿名统计设置失败',
      );
      ErrorHandler.handle(e, StackTrace.current, prefix: '保存匿名统计设置失败');
    }
  }

  /// 获取当前设置（静态方法，用于main.dart中的初始化）
  static Future<bool> getAnalyticsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyAnalyticsEnabled) ?? true; // 默认开启
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '获取匿名统计设置失败');
      return true; // 出错时默认开启
    }
  }
}

/// 匿名统计设置Provider
final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AnalyticsState>(
  (ref) => AnalyticsNotifier(),
);
