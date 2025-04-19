import 'dart:convert';

import '../lan/client.dart';
import '../lan/server.dart';
import '../utils/log.dart';

// 定义回调类型别名，提高可读性
typedef MessageCallback = void Function(String message);
typedef ConnectionCallback = void Function(bool isConnected, String statusMessage);

class ScoreNetworkManager {
  final WsServer? _server;
  final WsClient? _client;
  bool get isHost => _server != null;

  // 保留私有构造函数
  ScoreNetworkManager._({WsServer? server, WsClient? client})
      : _server = server,
        _client = client;

  static Future<ScoreNetworkManager> createHost(int port) async {
    // TODO: 实现 Host 接收消息并回调的机制 (如果需要)
    // 目前 WsServer 的 listen 在内部处理了消息 (_broadcast)
    // 如果 Host 也需要显示收到的消息，需要修改 WsServer 或 Manager
    final server = WsServer(port: port);
    await server.start();
    return ScoreNetworkManager._(server: server);
  }

  static Future<ScoreNetworkManager> createClient(
    String hostIp,
    int port, {
    required MessageCallback onMessageReceived, // 添加消息回调
    required ConnectionCallback onConnectionChanged, // 添加连接状态回调
  }) async {
    final client = WsClient(
      onMessage: onMessageReceived, // 将回调传递给 WsClient
      onConnectionChange: onConnectionChanged, // 将回调传递给 WsClient
    );
    try {
      await client.connect(hostIp, port);
      // 连接成功/失败的状态现在由 WsClient 内部通过 onConnectionChanged 回调处理
    } catch (e) {
       Log.e("连接错误 (Manager): $e");
       onConnectionChanged(false, "连接失败: $e"); // 确保连接失败时也回调
       rethrow; // 仍然向上抛出异常，让调用者知道创建失败
    }
    return ScoreNetworkManager._(client: client);
  }

  // 通用发送消息方法
  void sendMessage(String message) {
    if (isHost) {
      // Host 发送消息给所有客户端
      _server?.broadcast(message); // 假设 WsServer 有 broadcast 方法
    } else {
      // Client 发送消息给 Host
      _client?.send(message);
    }
  }

  // 保留原来的发送分数方法，如果还需要的话
  void sendScoreUpdate(String player, int score) {
    final message = jsonEncode({
      'player': player,
      'score': score,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    sendMessage(message); // 可以复用 sendMessage
  }

  Future<void> dispose() async {
    await _server?.stop();
    _client?.disconnect();
  }
}