import 'package:counters/features/setting/screen_wakelock_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ScreenWakelockProvider Tests', () {
    late ProviderContainer container;

    setUp(() {
      // 清理 SharedPreferences
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('初始状态应该是关闭的', () {
      final state = container.read(screenWakelockSettingProvider);
      expect(state.isEnabled, false);
      expect(state.isLoading, false);
      expect(state.error, null);
    });

    test('平台支持检查', () {
      final notifier = container.read(screenWakelockSettingProvider.notifier);

      // 现在所有平台都支持屏幕常亮功能
      expect(notifier.isSupported, true);
    });

    test('设置启用状态', () async {
      final notifier = container.read(screenWakelockSettingProvider.notifier);

      // 测试启用功能
      await notifier.setEnabled(true);
      var state = container.read(screenWakelockSettingProvider);
      expect(state.isEnabled, true);
      expect(state.isLoading, false);

      // 测试禁用功能
      await notifier.setEnabled(false);
      state = container.read(screenWakelockSettingProvider);
      expect(state.isEnabled, false);
      expect(state.isLoading, false);
    });

    test('SharedPreferences 持久化', () async {
      final notifier = container.read(screenWakelockSettingProvider.notifier);

      // 设置为启用
      await notifier.setEnabled(true);

      // 创建新的容器来模拟应用重启
      final newContainer = ProviderContainer();

      // 触发Provider初始化
      newContainer.read(screenWakelockSettingProvider);

      // 等待异步加载完成
      await Future.delayed(const Duration(milliseconds: 200));

      final state = newContainer.read(screenWakelockSettingProvider);
      expect(state.isEnabled, true);

      newContainer.dispose();
    });

    test('状态复制功能', () {
      const initialState = ScreenWakelockState(
        isEnabled: false,
        isLoading: false,
        error: null,
      );

      final newState = initialState.copyWith(
        isEnabled: true,
        isLoading: true,
        error: '测试错误',
      );

      expect(newState.isEnabled, true);
      expect(newState.isLoading, true);
      expect(newState.error, '测试错误');
    });

    test('状态复制时保持原值', () {
      const initialState = ScreenWakelockState(
        isEnabled: true,
        isLoading: false,
        error: '原始错误',
      );

      final newState = initialState.copyWith(isLoading: true);

      expect(newState.isEnabled, true); // 保持原值
      expect(newState.isLoading, true); // 新值
      expect(newState.error, null); // error 被重置为 null（copyWith 的默认行为）
    });
  });
}
