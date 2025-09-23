import 'package:counters/app/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 主题状态类
class ThemeState {
  final ThemeMode themeMode;
  final Color themeColor;
  final String? fontFamily; // 添加字体字段

  const ThemeState({
    required this.themeMode,
    required this.themeColor,
    this.fontFamily, // 字体可为空（使用系统默认）
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    Color? themeColor,
    String? fontFamily, // 添加字体支持
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      themeColor: themeColor ?? this.themeColor,
      fontFamily: fontFamily ?? this.fontFamily,
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
    final fontFamily = _prefs?.getString('fontFamily'); // 加载字体设置

    if (themeModeIndex != null) {
      state = state.copyWith(themeMode: ThemeMode.values[themeModeIndex]);
    }
    if (themeColorValue != null) {
      state = state.copyWith(themeColor: Color(themeColorValue));
    }
    if (fontFamily != null) {
      state = state.copyWith(fontFamily: fontFamily);
    }
  }

  @override
  ThemeState build() {
    // 初始状态使用全局状态中的值
    return ThemeState(
      themeMode: globalState.themeMode,
      themeColor: globalState.themeColor,
      fontFamily: globalState.fontFamily, // 添加字体支持
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

  // 设置字体
  Future<void> setFontFamily(String? fontFamily) async {
    final prefs = await _ensurePrefs();
    if (fontFamily == null) {
      await prefs.remove('fontFamily');
    } else {
      await prefs.setString('fontFamily', fontFamily);
    }
    state = state.copyWith(fontFamily: fontFamily);
  }
}

// 创建主题提供者
final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(() {
  return ThemeNotifier();
});