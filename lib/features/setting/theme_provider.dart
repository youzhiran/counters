import 'package:counters/app/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';


// 主题状态类
class ThemeState {
  final ThemeMode themeMode;
  final Color themeColor;

  const ThemeState({
    required this.themeMode,
    required this.themeColor,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    Color? themeColor,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      themeColor: themeColor ?? this.themeColor,
    );
  }
}

// 主题状态提供者
class ThemeNotifier extends Notifier<ThemeState> {
  SharedPreferences? _prefs;

  // 初始化方法
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // 从SharedPreferences加载保存的主题设置
    final themeModeIndex = _prefs?.getInt('themeMode');
    final themeColorValue = _prefs?.getInt('themeColor');

    if (themeModeIndex != null) {
      state = state.copyWith(themeMode: ThemeMode.values[themeModeIndex]);
    }
    if (themeColorValue != null) {
      state = state.copyWith(themeColor: Color(themeColorValue));
    }
  }

  @override
  ThemeState build() {
    // 初始状态使用全局状态中的值
    return ThemeState(
      themeMode: globalState.themeMode,
      themeColor: globalState.themeColor,
    );
  }

  // 确保_prefs已初始化
  Future<SharedPreferences> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // 设置主题模式
  Future<void> setThemeMode(ThemeMode themeMode) async {
    final prefs = await _ensurePrefs();
    await prefs.setInt('themeMode', themeMode.index);
    state = state.copyWith(themeMode: themeMode);
  }

  // 设置主题颜色
  Future<void> setThemeColor(Color color) async {
    final prefs = await _ensurePrefs();
    await prefs.setInt('themeColor', color.value);
    state = state.copyWith(themeColor: color);
  }
}

// 创建主题提供者
final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(() {
  return ThemeNotifier();
});
