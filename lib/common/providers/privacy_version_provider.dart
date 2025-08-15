import 'package:counters/app/config.dart';
import 'package:counters/common/model/privacy_version_info.dart';
import 'package:counters/common/utils/error_handler.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/common/utils/platform_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// 隐私政策版本状态
class PrivacyVersionState {
  final PrivacyVersionInfo? remoteVersion;
  final int? localTimestamp;
  final bool isLoading;
  final String? error;
  final bool hasUpdate;

  const PrivacyVersionState({
    this.remoteVersion,
    this.localTimestamp,
    this.isLoading = false,
    this.error,
    this.hasUpdate = false,
  });

  PrivacyVersionState copyWith({
    PrivacyVersionInfo? remoteVersion,
    int? localTimestamp,
    bool? isLoading,
    String? error,
    bool? hasUpdate,
  }) {
    return PrivacyVersionState(
      remoteVersion: remoteVersion ?? this.remoteVersion,
      localTimestamp: localTimestamp ?? this.localTimestamp,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasUpdate: hasUpdate ?? this.hasUpdate,
    );
  }
}

/// 隐私政策版本检查Provider
class PrivacyVersionNotifier extends StateNotifier<PrivacyVersionState> {
  PrivacyVersionNotifier() : super(const PrivacyVersionState());

  static const String _privacyAgreedKey = 'privacy_agreed';
  static const String _privacyTimeKey = 'privacy_time';

  /// 获取本地存储的隐私政策同意时间戳
  Future<int?> getLocalTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_privacyTimeKey);
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '获取本地隐私政策时间戳失败');
      return null;
    }
  }

  /// 检查用户是否已同意隐私政策
  Future<bool> hasAgreedPrivacy() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_privacyAgreedKey) ?? false;
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '获取隐私政策同意状态失败');
      return false;
    }
  }

  /// 保存隐私政策同意状态和时间戳
  Future<void> savePrivacyAgreement(int timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_privacyAgreedKey, true);
      await prefs.setInt(_privacyTimeKey, timestamp);
      Log.i('已保存隐私政策同意状态和时间戳: $timestamp');

      // 更新本地状态
      state = state.copyWith(
        localTimestamp: timestamp,
        hasUpdate: false,
      );
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '保存隐私政策同意信息失败');
    }
  }

  /// 获取远程隐私政策版本信息
  Future<PrivacyVersionInfo?> fetchRemoteVersion() async {
    if (PlatformUtils.isOhosPlatformSync()) {
      Log.i('鸿蒙平台：不获取远程隐私政策版本）');
      return null;
    }
    try {
      Log.d('开始获取远程隐私政策版本信息');
      final response = await http.get(Uri.parse(Config.jsonPrivacyVersion));

      if (response.statusCode == 200) {
        final versionInfo = PrivacyVersionInfo.fromJsonString(response.body);
        Log.i(
            '成功获取远程隐私政策版本: ${versionInfo.version} (${versionInfo.timestamp})');
        return versionInfo;
      } else {
        Log.w('获取隐私政策版本失败，HTTP状态码: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      Log.w('获取远程隐私政策版本失败，: $e');
      return null;
    }
  }

  /// 检查隐私政策版本更新
  Future<bool> checkForUpdate() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 首先检查用户是否已同意隐私政策
      final hasAgreed = await hasAgreedPrivacy();
      if (!hasAgreed) {
        // 用户从未同意过，需要显示隐私政策
        state = state.copyWith(
          isLoading: false,
          localTimestamp: null,
          hasUpdate: true, // 设为true以触发显示弹窗
          error: null,
        );
        return true;
      }

      // 获取本地时间戳
      final localTimestamp = await getLocalTimestamp();

      // 获取远程版本信息
      final remoteVersion = await fetchRemoteVersion();

      if (remoteVersion == null) {
        // 网络请求失败，但不阻止应用启动
        state = state.copyWith(
          isLoading: false,
          error: '无法获取隐私政策版本信息',
          localTimestamp: localTimestamp,
          hasUpdate: false,
        );
        return false;
      }

      // 比较版本：如果本地没有时间戳或远程时间戳更新，则需要更新
      final hasUpdate =
          localTimestamp == null || remoteVersion.timestamp > localTimestamp;

      Log.i(
          '隐私政策版本检查结果: 已同意=$hasAgreed, 本地时间戳=$localTimestamp, 远程时间戳=${remoteVersion.timestamp}, 需要更新=$hasUpdate');

      state = state.copyWith(
        isLoading: false,
        remoteVersion: remoteVersion,
        localTimestamp: localTimestamp,
        hasUpdate: hasUpdate,
        error: null,
      );

      return hasUpdate;
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '检查隐私政策版本更新失败');
      state = state.copyWith(
        isLoading: false,
        error: '检查版本更新失败',
      );
      return false;
    }
  }

  /// 重置状态
  void reset() {
    state = const PrivacyVersionState();
  }
}

/// 隐私政策版本Provider
final privacyVersionProvider =
    StateNotifierProvider<PrivacyVersionNotifier, PrivacyVersionState>(
  (ref) => PrivacyVersionNotifier(),
);
