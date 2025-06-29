import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:counters/app/config.dart';
import 'package:counters/common/utils/port_manager.dart';
import 'package:counters/common/utils/error_handler.dart';

/// 端口配置状态类
class PortConfigState {
  final int discoveryPort;
  final int webSocketPort;
  final bool isLoading;
  final String? error;

  const PortConfigState({
    this.discoveryPort = Config.discoveryPort,
    this.webSocketPort = Config.webSocketPort,
    this.isLoading = false,
    this.error,
  });

  PortConfigState copyWith({
    int? discoveryPort,
    int? webSocketPort,
    bool? isLoading,
    String? error,
  }) {
    return PortConfigState(
      discoveryPort: discoveryPort ?? this.discoveryPort,
      webSocketPort: webSocketPort ?? this.webSocketPort,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// 是否使用默认广播端口
  bool get isUsingDefaultDiscoveryPort => discoveryPort == Config.discoveryPort;

  /// 是否使用默认服务端口
  bool get isUsingDefaultWebSocketPort => webSocketPort == Config.webSocketPort;

  /// 获取广播端口选项列表
  List<int> get discoveryPortOptions {
    final options = <int>[];
    for (int port = Config.discoveryPortMin; port <= Config.discoveryPortMax; port++) {
      options.add(port);
    }
    return options;
  }

  /// 获取服务端口选项列表
  List<int> get webSocketPortOptions {
    final options = <int>[];
    for (int port = Config.webSocketPortMin; port <= Config.webSocketPortMax; port++) {
      options.add(port);
    }
    return options;
  }
}

/// 端口配置Provider
class PortConfigNotifier extends Notifier<PortConfigState> {
  bool _initialized = false;

  @override
  PortConfigState build() {
    // 返回初始状态
    return const PortConfigState();
  }

  /// 初始化配置（在第一次访问时调用）
  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    await _loadSavedConfig();
  }

  /// 公共初始化方法
  Future<void> initialize() async {
    await _ensureInitialized();
  }

  /// 加载保存的端口配置
  Future<void> _loadSavedConfig() async {
    try {
      state = state.copyWith(isLoading: true);

      final discoveryPort = await PortManager.getCustomDiscoveryPort() ?? Config.discoveryPort;
      final webSocketPort = await PortManager.getCustomWebSocketPort() ?? Config.webSocketPort;

      state = state.copyWith(
        discoveryPort: discoveryPort,
        webSocketPort: webSocketPort,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '加载端口配置失败');
      state = state.copyWith(
        isLoading: false,
        error: '加载端口配置失败: $e',
      );
    }
  }

  /// 设置广播端口
  Future<void> setDiscoveryPort(int port) async {
    await _ensureInitialized();
    try {
      state = state.copyWith(isLoading: true);

      if (!PortManager.isValidPort(port)) {
        throw Exception('无效的端口号: $port');
      }

      // 保存到SharedPreferences
      final success = await PortManager.setCustomDiscoveryPort(
        port == Config.discoveryPort ? null : port
      );

      if (!success) {
        throw Exception('保存广播端口配置失败');
      }

      state = state.copyWith(
        discoveryPort: port,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '设置广播端口失败');
      state = state.copyWith(
        isLoading: false,
        error: '设置广播端口失败: $e',
      );
    }
  }

  /// 设置服务端口
  Future<void> setWebSocketPort(int port) async {
    await _ensureInitialized();
    try {
      state = state.copyWith(isLoading: true);

      if (!PortManager.isValidPort(port)) {
        throw Exception('无效的端口号: $port');
      }

      // 保存到SharedPreferences
      final success = await PortManager.setCustomWebSocketPort(
        port == Config.webSocketPort ? null : port
      );

      if (!success) {
        throw Exception('保存服务端口配置失败');
      }

      state = state.copyWith(
        webSocketPort: port,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '设置服务端口失败');
      state = state.copyWith(
        isLoading: false,
        error: '设置服务端口失败: $e',
      );
    }
  }

  /// 重置为默认端口
  Future<void> resetToDefaults() async {
    await _ensureInitialized();
    try {
      state = state.copyWith(isLoading: true);

      await PortManager.setCustomDiscoveryPort(null);
      await PortManager.setCustomWebSocketPort(null);

      state = state.copyWith(
        discoveryPort: Config.discoveryPort,
        webSocketPort: Config.webSocketPort,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '重置端口配置失败');
      state = state.copyWith(
        isLoading: false,
        error: '重置端口配置失败: $e',
      );
    }
  }

  /// 检查端口可用性
  Future<bool> checkPortAvailability(int port, {bool isWebSocket = false}) async {
    await _ensureInitialized();
    try {
      if (isWebSocket) {
        return !await PortManager.isTcpPortOccupied(port);
      } else {
        return !await PortManager.isUdpPortOccupied(port);
      }
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '检查端口可用性失败');
      return false;
    }
  }

  /// 获取当前配置的广播端口
  Future<int> getCurrentDiscoveryPort() async {
    return await PortManager.getCurrentDiscoveryPort();
  }

  /// 获取当前配置的服务端口
  Future<int> getCurrentWebSocketPort() async {
    return await PortManager.getCurrentWebSocketPort();
  }

}

/// 端口配置Provider实例
final portConfigProvider = NotifierProvider<PortConfigNotifier, PortConfigState>(() {
  return PortConfigNotifier();
});
