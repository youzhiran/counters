import 'package:counters/common/utils/log.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// 屏幕常亮辅助工具类
/// 基于 wakelock_plus 文档的最佳实践实现
class WakelockHelper {
  /// 私有构造函数，防止实例化
  WakelockHelper._();

  /// 启用屏幕常亮
  /// 根据文档建议，这个方法是幂等的，可以多次调用
  static Future<void> enable() async {
    try {
      await WakelockPlus.enable();
      Log.v('WakelockHelper: 屏幕常亮已启用');
    } catch (e) {
      Log.w('WakelockHelper: 启用屏幕常亮失败 - $e');
    }
  }

  /// 禁用屏幕常亮
  static Future<void> disable() async {
    try {
      await WakelockPlus.disable();
      Log.v('WakelockHelper: 屏幕常亮已禁用');
    } catch (e) {
      Log.w('WakelockHelper: 禁用屏幕常亮失败 - $e');
    }
  }

  /// 切换屏幕常亮状态
  /// 使用 wakelock_plus 推荐的 toggle API
  static Future<void> toggle({required bool enable}) async {
    try {
      await WakelockPlus.toggle(enable: enable);
      Log.v('WakelockHelper: 屏幕常亮已${enable ? '启用' : '禁用'}');
    } catch (e) {
      Log.w('WakelockHelper: 切换屏幕常亮状态失败 - $e');
    }
  }

  /// 检查当前屏幕常亮状态
  /// 返回实际的系统状态，而不是应用设置状态
  static Future<bool> isEnabled() async {
    try {
      final enabled = await WakelockPlus.enabled;
      Log.v('WakelockHelper: 当前屏幕常亮状态 - $enabled');
      return enabled;
    } catch (e) {
      Log.w('WakelockHelper: 检查屏幕常亮状态失败 - $e');
      return false;
    }
  }

  /// 确保屏幕常亮状态与期望一致
  /// 如果当前状态与期望不符，则进行调整
  static Future<void> ensureState({required bool shouldEnable}) async {
    try {
      final currentState = await isEnabled();
      if (currentState != shouldEnable) {
        await toggle(enable: shouldEnable);
        Log.d('WakelockHelper: 屏幕常亮状态已调整为 $shouldEnable');
      }
    } catch (e) {
      Log.w('WakelockHelper: 确保屏幕常亮状态失败 - $e');
    }
  }

  /// 安全地禁用屏幕常亮（用于应用退出或页面销毁）
  /// 不抛出异常，只记录错误
  static void safeDisable() {
    try {
      // 使用同步方式，避免在 dispose 中使用 async
      WakelockPlus.toggle(enable: false);
      Log.v('WakelockHelper: 屏幕常亮已安全禁用');
    } catch (e) {
      Log.w('WakelockHelper: 安全禁用屏幕常亮失败 - $e');
    }
  }

  /// 检查平台是否支持屏幕常亮
  /// wakelock_plus 支持所有主要平台
  static bool get isSupported => true;

  /// 获取屏幕常亮状态的调试信息
  static Future<Map<String, dynamic>> getDebugInfo() async {
    try {
      final enabled = await isEnabled();
      return {
        'isSupported': isSupported,
        'isEnabled': enabled,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'isSupported': isSupported,
        'isEnabled': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
