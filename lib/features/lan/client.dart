import 'dart:async';
import 'dart:io';

import 'package:counters/common/utils/log.dart';
import 'package:counters/features/lan/network_manager.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// 获取本地 WIFI IP 地址和接口名称，优先选择含有WLAN/wifi的接口
/// 返回一个包含 'ip' 和 'name' 的 Map，如果未找到则返回 null
Future<Map<String, String>?> getWlanIp() async {
  try {
    String? firstIpFound;
    String? firstInterfaceNameFound;

    // 遍历所有网络接口
    for (var interface in await NetworkInterface.list(
        includeLoopback: false, type: InternetAddressType.IPv4)) {
      // interface.addresses 包含此接口的所有 IP 地址
      if (interface.addresses.isNotEmpty) {
        final ip = interface.addresses.first.address;
        final interfaceName = interface.name.toLowerCase(); // 转为小写以便比较
        Log.d('找到 IP 地址: $ip 来自接口: ${interface.name}');

        // 记录找到的第一个 IP 地址和名称，作为备选
        if (firstIpFound == null) {
          firstIpFound = ip;
          firstInterfaceNameFound = interface.name;
        }

        // 检查接口名称是否包含 "wlan"或"wifi"
        if (interfaceName.contains('wlan') || interfaceName.contains('wifi')) {
          Log.i('优先选择 WLAN 接口: ${interface.name}，IP: $ip');
          return {'ip': ip, 'name': interface.name}; // 找到 WLAN 接口，立即返回
        }
      }
    }

    // 如果循环结束仍未找到 WLAN 接口，返回找到的第一个 IP (如果有)
    if (firstIpFound != null) {
      Log.w(
          '未找到名称含 "wlan/wifi" 的接口，返回第一个找到的 IP: $firstIpFound (${firstInterfaceNameFound ?? '未知接口'})');
      return {'ip': firstIpFound, 'name': firstInterfaceNameFound ?? '未知接口'};
    }
  } catch (e) {
    Log.e('获取本地 IP 失败: $e');
  }

  Log.w('未能找到合适的本地 IP 地址和接口');
  return null; // 如果没有找到任何合适的 IP，返回 null
}

// 定义回调类型别名
// typedef MessageCallback = void Function(String message);
// typedef ConnectionCallback = void Function(bool isConnected, String statusMessage);

class WsClient {
  WebSocketChannel? _channel; // 改为可空，因为连接可能失败
  // 将 onMessage 的类型修改为 MessageCallback
  final MessageCallback onMessage;
  final ConnectionCallback? onConnectionChange; // 添加连接状态回调
  StreamSubscription? _streamSubscription; // 用于管理监听

  // 新增：重连相关字段
  String? _lastServerIp;
  int? _lastPort;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  final Duration _reconnectInterval = const Duration(seconds: 3);
  bool _isManualDisconnect = false; // 标记是否为手动断开
  bool _isReconnecting = false; // 标记是否正在重连

  // 修改构造函数参数类型
  WsClient({required this.onMessage, this.onConnectionChange});

  Future<void> connect(String serverIp, int port) async {
    // 保存连接信息用于重连
    _lastServerIp = serverIp;
    _lastPort = port;
    _isManualDisconnect = false;

    await _performConnect(serverIp, port);
  }

  Future<void> _performConnect(String serverIp, int port) async {
    final uri = Uri.parse('ws://$serverIp:$port');
    Log.i('尝试连接到: $uri (重连次数: $_reconnectAttempts/$_maxReconnectAttempts)');

    // 修复：简化状态消息，让Provider统一管理重连计数器显示
    final statusMessage = _isReconnecting ? '正在尝试重连' : '连接中...';
    onConnectionChange?.call(false, statusMessage);

    try {
      _channel = WebSocketChannel.connect(uri);

      // 等待连接建立 (可选，但可以更早知道连接是否成功)
      await _channel!.ready;
      Log.i('WebSocket 连接已准备就绪');

      // 连接成功，重置重连状态
      _reconnectAttempts = 0;
      _isReconnecting = false;
      _cancelReconnectTimer();

      onConnectionChange?.call(true, '已连接到 $serverIp:$port'); // 通知连接成功

      // 清理旧的监听（如果存在）
      await _streamSubscription?.cancel();

      _streamSubscription = _channel!.stream.listen(
        (message) {
          // 内部调用 onMessage 时，确保传递的是 String
          try {
            if (message is String) {
              onMessage(message); // 直接调用，类型匹配
            } else {
              Log.w('收到非字符串消息: ${message.runtimeType}');
              onMessage(message.toString()); // 尝试转为字符串
            }
          } catch (e) {
            Log.e('处理消息时出错: $e');
          }
        },
        onError: (error) {
          Log.e('WebSocket 连接错误: $error');
          _handleConnectionLoss('连接错误: $error');
        },
        onDone: () {
          Log.i('WebSocket 连接已关闭');
          _handleConnectionLoss('连接已断开');
        },
        cancelOnError: false, // 发生错误时不自动取消监听，以便重连
      );
    } catch (e) {
      Log.e('WebSocket 连接失败: $e');
      _handleConnectionLoss('连接失败: $e');
      if (!_isReconnecting) {
        rethrow; // 首次连接失败时抛出异常
      }
    }
  }

  void send(dynamic message) {
    if (_channel != null && _channel!.closeCode == null) {
      try {
        _channel!.sink.add(message);
      } catch (e) {
        Log.e("发送消息失败: $e");
        _handleConnectionLoss('发送失败: $e');
      }
    } else {
      Log.w('无法发送消息：连接未建立或已关闭');
      if (!_isReconnecting) {
        onConnectionChange?.call(false, '连接已断开，无法发送');
      }
    }
  }

  Future<void> disconnect() async {
    _isManualDisconnect = true; // 标记为手动断开
    _cancelReconnectTimer(); // 取消重连定时器
    await _streamSubscription?.cancel(); // 取消监听
    _channel?.sink.close();
    _resetConnection();
    Log.i('客户端手动断开连接');
    onConnectionChange?.call(false, '已断开连接');
  }

  // 处理连接丢失，启动自动重连
  void _handleConnectionLoss(String reason) {
    _resetConnection();

    // 如果是手动断开，不进行重连
    if (_isManualDisconnect) {
      onConnectionChange?.call(false, reason);
      return;
    }

    // 如果已达到最大重连次数，停止重连
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      Log.w('已达到最大重连次数 ($_maxReconnectAttempts)，停止重连');
      onConnectionChange?.call(false, '连接断开，重连失败');
      return;
    }

    // 启动重连
    _startReconnect(reason);
  }

  void _startReconnect(String reason) {
    if (_lastServerIp == null || _lastPort == null) {
      Log.w('无法重连：缺少服务器信息');
      onConnectionChange?.call(false, reason);
      return;
    }

    _isReconnecting = true;
    _reconnectAttempts++;

    Log.i('连接断开，将在 ${_reconnectInterval.inSeconds} 秒后尝试第 $_reconnectAttempts 次重连');
    // 修复：发送包含重连次数的状态消息，让Provider知道当前重连次数
    onConnectionChange?.call(false, '重连尝试:$_reconnectAttempts');

    _cancelReconnectTimer();
    _reconnectTimer = Timer(_reconnectInterval, () {
      if (!_isManualDisconnect) {
        _performConnect(_lastServerIp!, _lastPort!);
      }
    });
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  // 手动重连方法
  Future<void> manualReconnect() async {
    if (_lastServerIp == null || _lastPort == null) {
      Log.w('无法手动重连：缺少服务器信息');
      return;
    }

    _isManualDisconnect = false;
    // 修复：手动重连时不重置重连次数，让Provider层面管理
    _isReconnecting = false;
    _cancelReconnectTimer();

    await _performConnect(_lastServerIp!, _lastPort!);
  }

  // 重置连接状态
  void _resetConnection() {
    _channel = null;
    _streamSubscription = null;
  }
}
