import 'dart:io'; // For WebSocket type

import 'package:counters/common/utils/log.dart';
import 'package:counters/features/lan/client.dart';
import 'package:counters/features/lan/host.dart';

// 定义回调类型别名 (如果已在别处定义，这里可省略或确保一致)
typedef MessageCallback = void Function(String message);
typedef ConnectionCallback = void Function(
    bool isConnected, String statusMessage);
// 新增客户端连接回调类型别名
typedef ClientConnectionCallback = void Function(
    WebSocket client, String clientIp);

/// 管理 WebSocket 主机或客户端连接的类。
/// 它是 LanNotifier 和 WsHost/WsClient 之间的桥梁。
class ScoreNetworkManager {
  final WsHost? _server; // WsHost 的实例 (Host 模式)
  final WsClient? _client; // WsClient 的实例 (Client 模式或 HostAndClient 的客户端部分)
  bool get isHost => _server != null; // 判断是否是主机模式的管理器

  // === 修复点 1：使用非私有的命名构造函数 "_" ===
  // LanNotifier 将通过这个命名构造函数来创建 ScoreNetworkManager 实例。
  ScoreNetworkManager._({WsHost? server, WsClient? client})
      : _server = server,
        _client = client;

  /// 创建并启动 Host 模式的网络管理器
  /// Host 模式通常不需要主动接收消息并处理 (除非需要处理客户端命令)
  /// [port] 主机监听的端口
  /// [onMessageReceived] 接收到客户端消息时的回调
  static Future<ScoreNetworkManager> createHost(
    int port, {
    // 使用 WsHost 中定义的类型别名
    ClientMessageCallback? onMessageReceived,
    ClientConnectionCallback? onClientConnected, // 新增回调参数
    ClientConnectionCallback? onClientDisconnected, // 新增回调参数
  }) async {
    // 在内部创建并启动 WsHost，传递所有回调
    final server = WsHost(
      port: port,
      onMessageReceived: onMessageReceived,
      onClientConnected: onClientConnected, // 传递回调
      onClientDisconnected: onClientDisconnected, // 传递回调
    );
    await server.start();
    // === 修复点 1 续：使用修改后的命名构造函数 "_" ===
    return ScoreNetworkManager._(server: server);
  }

  /// 创建并启动 Client 模式的网络管理器
  /// 需要提供消息回调和连接状态回调
  /// [hostIp] 主机 IP
  /// [port] 主机端口
  /// [onMessageReceived] 接收到消息时的回调
  /// [onConnectionChanged] 连接状态变化时的回调
  static Future<ScoreNetworkManager> createClient(
    String hostIp,
    int port, {
    required MessageCallback onMessageReceived,
    required ConnectionCallback onConnectionChanged,
  }) async {
    // 在内部创建 WsClient
    final client = WsClient(
      onMessage: onMessageReceived,
      onConnectionChange: onConnectionChanged,
    );
    try {
      await client.connect(hostIp, port); // 尝试连接
      // 连接成功/失败的状态由 WsClient 内部通过 onConnectionChanged 回调处理
    } catch (e) {
      Log.e("连接错误 (ScoreNetworkManager createClient): $e");
      rethrow; // 将异常重新抛出
    }
    // === 修复点 1 续：使用修改后的命名构造函数 "_" ===
    return ScoreNetworkManager._(client: client);
  }

  /// 发送消息。
  /// 在 Host 模式下，广播消息给所有连接的客户端。
  /// 在 Client 模式下，发送消息给连接的主机。
  /// [message] 要发送的字符串消息 (通常是 JSON 字符串)。
  void sendMessage(String message) {
    if (isHost) {
      _server?.broadcast(message);
    } else if (_client != null) {
      _client!.send(message);
    } else {
      Log.w('ScoreNetworkManager: 尝试发送消息，但管理器未初始化为 Client');
    }
  }

  /// 广播消息给所有连接的客户端 (仅 Host 模式可用)。
  /// 这是 ScoreNetworkManager 暴露给 LanNotifier/ScoreNotifier 调用的广播方法。
  /// === 新增方法 ===
  void broadcast(String message) {
    if (isHost && _server != null) {
      _server!.broadcast(message); // 调用内部 WsHost 的 broadcast
    } else {
      Log.w('ScoreNetworkManager: broadcast 仅在 Host 模式下可用');
    }
  }

  /// 发送消息给特定的客户端 (仅 Host 模式可用)。
  /// 用于 Host 向新连接的客户端发送全量同步状态。
  /// [client] 目标 WebSocket 客户端连接。
  /// [message] 要发送的字符串消息 (通常是 JSON 字符串)。
  /// === 新增方法 ===
  void sendToClient(WebSocket client, String message) {
    if (isHost && _server != null) {
      try {
        if (client.readyState == WebSocket.open) {
          client.add(message);
          // === 修复点 3：移除无法访问的 remoteAddress/remotePort ===
          Log.i('发送消息给特定客户端'); // 修改日志信息
        } else {
          Log.w('尝试发送消息给已关闭或未打开的客户端');
        }
      } catch (e) {
        Log.e('发送消息给特定客户端失败: $e');
      }
    } else {
      Log.w('ScoreNetworkManager: sendToClient 仅在 Host 模式下可用');
    }
  }

  /// 释放管理器及其内部的网络资源。
  Future<void> dispose() async {
    if (isHost) {
      await _server?.stop(); // 停止 Host 服务器
    } else if (_client != null) {
      await _client!.disconnect(); // 断开 Client 连接
    }
    Log.d('ScoreNetworkManager disposed.');
  }
}
