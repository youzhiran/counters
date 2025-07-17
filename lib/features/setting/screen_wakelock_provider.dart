import 'package:counters/common/utils/error_handler.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/common/utils/wakelock_helper.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'screen_wakelock_provider.g.dart';

/// 屏幕常亮设置状态
class ScreenWakelockState {
  final bool isEnabled;
  final bool isLoading;
  final String? error;

  const ScreenWakelockState({
    this.isEnabled = false,
    this.isLoading = false,
    this.error,
  });

  ScreenWakelockState copyWith({
    bool? isEnabled,
    bool? isLoading,
    String? error,
  }) {
    return ScreenWakelockState(
      isEnabled: isEnabled ?? this.isEnabled,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 屏幕常亮设置 Provider
/// 控制计分时是否保持屏幕常亮，支持所有平台
@Riverpod(keepAlive: true)
class ScreenWakelockSetting extends _$ScreenWakelockSetting {
  static const String _keyScreenWakelock = 'screen_wakelock_enabled';

  @override
  ScreenWakelockState build() {
    // 默认关闭屏幕常亮，异步加载设置
    Future.microtask(() => _loadSetting());
    return const ScreenWakelockState(isEnabled: false);
  }

  /// 检查当前平台是否支持屏幕常亮功能
  /// 使用 WakelockHelper 统一管理
  bool get isSupported => WakelockHelper.isSupported;

  /// 从 SharedPreferences 加载设置
  Future<void> _loadSetting() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool(_keyScreenWakelock) ?? false;

      state = state.copyWith(
        isEnabled: isEnabled,
        isLoading: false,
      );

      Log.d('屏幕常亮设置已加载: $isEnabled');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '加载屏幕常亮设置失败',
      );
      ErrorHandler.handle(e, StackTrace.current, prefix: '加载屏幕常亮设置失败');
    }
  }

  /// 设置屏幕常亮开关状态
  Future<void> setEnabled(bool enabled) async {
    final previousState = state;
    try {
      // 立即更新UI状态，提供即时视觉反馈
      state = state.copyWith(isEnabled: enabled, isLoading: true, error: null);

      // 保存到 SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyScreenWakelock, enabled);

      // 完成状态更新
      state = state.copyWith(isLoading: false);

      Log.i('屏幕常亮设置已更新: $enabled');
    } catch (e) {
      // 发生错误时恢复之前的状态
      state = previousState.copyWith(
        isLoading: false,
        error: '保存屏幕常亮设置失败',
      );
      ErrorHandler.handle(e, StackTrace.current, prefix: '保存屏幕常亮设置失败');
      rethrow; // 重新抛出异常，让调用者知道操作失败
    }
  }

  /// 启用屏幕常亮
  /// 根据 wakelock_plus 文档建议，应该在需要时持续调用此方法
  /// 因为 OS 可能随时释放 wakelock
  Future<void> enableWakelock() async {
    if (!state.isEnabled) return;

    try {
      await WakelockHelper.enable();
      Log.i('屏幕常亮已启用');
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '启用屏幕常亮失败');
    }
  }

  /// 禁用屏幕常亮
  Future<void> disableWakelock() async {
    try {
      await WakelockHelper.disable();
      Log.i('屏幕常亮已禁用');
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '禁用屏幕常亮失败');
    }
  }

  /// 检查屏幕常亮是否当前处于启用状态
  /// 使用 WakelockHelper 获取当前实际状态
  Future<bool> isWakelockEnabled() async {
    try {
      return await WakelockHelper.isEnabled();
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '检查屏幕常亮状态失败');
      return false;
    }
  }

  /// 强制启用屏幕常亮（无论设置状态如何）
  /// 用于在特定场景下临时启用，比如视频播放
  Future<void> forceEnableWakelock() async {
    try {
      await WakelockHelper.enable();
      Log.i('屏幕常亮已强制启用');
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '强制启用屏幕常亮失败');
    }
  }

  /// 强制禁用屏幕常亮（无论设置状态如何）
  /// 用于确保在特定场景下禁用，比如应用退出
  Future<void> forceDisableWakelock() async {
    try {
      await WakelockHelper.disable();
      Log.i('屏幕常亮已强制禁用');
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '强制禁用屏幕常亮失败');
    }
  }

  /// 确保屏幕常亮状态与设置一致
  /// 根据文档建议，定期检查并调整状态
  Future<void> ensureWakelockState() async {
    try {
      await WakelockHelper.ensureState(shouldEnable: state.isEnabled);
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '确保屏幕常亮状态失败');
    }
  }

  /// 获取屏幕常亮的调试信息
  Future<Map<String, dynamic>> getWakelockDebugInfo() async {
    try {
      final debugInfo = await WakelockHelper.getDebugInfo();
      return {
        ...debugInfo,
        'settingEnabled': state.isEnabled,
        'settingLoading': state.isLoading,
        'settingError': state.error,
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'settingEnabled': state.isEnabled,
        'settingLoading': state.isLoading,
        'settingError': state.error,
      };
    }
  }
}
