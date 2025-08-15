import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

class PlatformUtils {
  static const String _keyTestHarmonyPlatform = 'test_harmony_platform';
  static bool _testHarmonyPlatformCached = false;

  /// 初始化缓存，应用启动时调用一次
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _testHarmonyPlatformCached =
          prefs.getBool(_keyTestHarmonyPlatform) ?? false;
    } catch (_) {
      _testHarmonyPlatformCached = false;
    }
  }

  /// 同步：是否按鸿蒙平台行为处理
  static bool isOhosPlatformSync() {
    if (Platform.operatingSystem == 'ohos') return true;
    return _testHarmonyPlatformCached;
  }

  /// 同步更新缓存（在设置切换时调用）
  static void setTestHarmonyPlatform(bool value) {
    _testHarmonyPlatformCached = value;
  }
}


