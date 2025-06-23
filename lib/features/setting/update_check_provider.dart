import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:counters/common/utils/error_handler.dart';

/// 更新检查选项枚举
enum UpdateCheckOption {
  none('不检查', 'none'),
  rc('正式版', 'rc'),
  beta('测试版', 'beta');

  const UpdateCheckOption(this.displayName, this.value);

  final String displayName;
  final String value;

  /// 从字符串值获取枚举
  static UpdateCheckOption fromValue(String value) {
    return UpdateCheckOption.values.firstWhere(
      (option) => option.value == value,
      orElse: () => UpdateCheckOption.rc, // 默认为正式版
    );
  }
}

/// 更新检查设置状态
class UpdateCheckState {
  final UpdateCheckOption option;
  final bool isLoading;

  const UpdateCheckState({
    this.option = UpdateCheckOption.rc, // 默认检查正式版
    this.isLoading = false,
  });

  UpdateCheckState copyWith({
    UpdateCheckOption? option,
    bool? isLoading,
  }) {
    return UpdateCheckState(
      option: option ?? this.option,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UpdateCheckState &&
        other.option == option &&
        other.isLoading == isLoading;
  }

  @override
  int get hashCode => Object.hash(option, isLoading);
}

/// 更新检查设置Provider
class UpdateCheckNotifier extends Notifier<UpdateCheckState> {
  static const String _keyUpdateCheckOption = 'update_check_option';
  SharedPreferences? _prefs;

  @override
  UpdateCheckState build() {
    // 返回初始状态，不在build中修改state
    return const UpdateCheckState();
  }

  /// 确保SharedPreferences已初始化
  Future<SharedPreferences> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// 初始化设置（在外部调用）
  Future<void> initialize() async {
    try {
      state = state.copyWith(isLoading: true);

      final prefs = await _ensurePrefs();
      final savedValue = prefs.getString(_keyUpdateCheckOption);

      if (savedValue != null) {
        final option = UpdateCheckOption.fromValue(savedValue);
        state = state.copyWith(option: option, isLoading: false);
      } else {
        // 首次使用，设置默认值
        await setUpdateCheckOption(UpdateCheckOption.rc);
      }
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '加载更新检查设置失败');
      state = state.copyWith(isLoading: false);
    }
  }

  /// 设置更新检查选项
  Future<void> setUpdateCheckOption(UpdateCheckOption option) async {
    try {
      state = state.copyWith(isLoading: true);
      
      final prefs = await _ensurePrefs();
      await prefs.setString(_keyUpdateCheckOption, option.value);
      
      state = state.copyWith(option: option, isLoading: false);
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '保存更新检查设置失败');
      state = state.copyWith(isLoading: false);
    }
  }

  /// 获取当前设置选项
  UpdateCheckOption get currentOption => state.option;

  /// 是否应该检查更新
  bool get shouldCheckUpdate => state.option != UpdateCheckOption.none;

  /// 是否包含测试版
  bool get includePrereleases => state.option == UpdateCheckOption.beta;
}

/// 更新检查设置Provider实例
final updateCheckProvider = NotifierProvider<UpdateCheckNotifier, UpdateCheckState>(
  () => UpdateCheckNotifier(),
);
