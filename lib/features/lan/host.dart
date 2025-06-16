import 'dart:convert';
import 'dart:io';

import 'package:counters/common/model/sync_messages.dart';
import 'package:counters/common/utils/error_handler.dart';
import 'package:counters/common/utils/log.dart';

// 定义回调类型别名
typedef ClientMessageCallback = void Function(WebSocket client, String message);
typedef ClientConnectionCallback = void Function(
    WebSocket client, String clientIp);

class WsHost {
  final int port;
  HttpServer? _server;
  final List<WebSocket> _clients = [];
  final Map<WebSocket, String> _clientIps = {}; // 新增：存储客户端 IP

  // 修改回调类型
  final ClientMessageCallback? onMessageReceived;
  final ClientConnectionCallback? onClientConnected; // 新增：客户端连接回调
  final ClientConnectionCallback? onClientDisconnected; // 新增：客户端断开回调
  final Function(String error)? onServerError; // 新增：服务器错误回调
  final Function(String error)? onStartupError; // 新增：启动失败回调

  // 修改构造函数，添加回调参数
  WsHost({
    this.port = 8080,
    this.onMessageReceived,
    this.onClientConnected, // 新增
    this.onClientDisconnected, // 新增
    this.onServerError, // 新增：服务器错误回调
    this.onStartupError, // 新增：启动失败回调
  });

  Future<void> start() async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      Log.i('WebSocket 服务器运行在: ${_server?.address.address}:$port');

      _server?.listen((request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          String clientIp = '未知IP'; // 默认值
          try {
            // 尝试从 connectionInfo 获取 IP
            clientIp = request.connectionInfo?.remoteAddress.address ?? '未知IP';
            final socket = await WebSocketTransformer.upgrade(request);
            _handleNewConnection(socket, clientIp); // 传递 IP 地址
          } catch (e) {
            Log.e('处理WebSocket升级请求失败: $e');
            try {
              request.response.statusCode = HttpStatus.internalServerError;
              await request.response.close();
            } catch (_) {}
          }
        } else {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
        }
      }, onError: (e) {
        // 使用统一的错误处理器
        ErrorHandler.handle(e, StackTrace.current, prefix: 'WebSocket 服务器监听错误');
        // 通知 LanNotifier 服务器错误
        onServerError?.call('WebSocket 服务器监听错误: $e');
      });
    } catch (e) {
      // 使用统一的错误处理器
      ErrorHandler.handle(e, StackTrace.current, prefix: '启动 WebSocket 服务器失败');
      // 通知 LanNotifier 启动失败
      onStartupError?.call('启动 WebSocket 服务器失败: $e');
      rethrow;
    }
  }

  void _handleNewConnection(WebSocket socket, String clientIp) {
    // 接收 IP
    _clients.add(socket);
    _clientIps[socket] = clientIp; // 存储 IP
    Log.i('新客户端连接 ($clientIp), 当前客户端数: ${_clients.length}');

    // 调用客户端连接回调
    onClientConnected?.call(socket, clientIp);

    socket.listen(
      (message) {
        // Host 收到客户端消息。在我们的同步方案中，客户端可能发送命令。
        Log.i('收到来自客户端 ($clientIp) 的消息: $message');

        // 将收到的消息转发给 LanNotifier 或 ScoreNotifier 处理客户端命令
        final messageString = message is String ? message : message.toString();

        // 处理客户端消息
        if (message is String) {
          try {
            // 尝试解析 JSON 消息
            final jsonMap = jsonDecode(message) as Map<String, dynamic>;
            final syncMessage = SyncMessage.fromJson(jsonMap);

            // 处理各种类型的客户端消息
            switch (syncMessage.type) {
              case "request_sync_state":
                Log.i('收到客户端 ($clientIp) 请求同步状态: ${syncMessage.data}');
                break;
              case "client_command":
                Log.i('收到客户端 ($clientIp) 命令: ${syncMessage.data}');
                break;
              case "ping":
                Log.v('收到客户端 ($clientIp) ping消息: ${syncMessage.data}');
                break;
              case "pong":
                Log.v('收到客户端 ($clientIp) pong响应: ${syncMessage.data}');
                break;
              default:
                Log.i('收到客户端 ($clientIp) 未知消息类型: ${syncMessage.type}');
                break;
            }

            // 将所有消息传递给回调函数处理
            onMessageReceived?.call(socket, messageString);
          } catch (e) {
            // 使用统一的错误处理器
            ErrorHandler.handle(e, StackTrace.current, prefix: '解析客户端 ($clientIp) 消息失败');
            // 即使解析失败，也尝试转发原始消息
            onMessageReceived?.call(socket, messageString);
          }
        } else {
          // 非字符串消息也转发
          onMessageReceived?.call(socket, messageString);
        }
      },
      onDone: () {
        _handleClientDisconnect(socket); // 调用统一处理方法
      },
      onError: (error) {
        // 使用统一的错误处理器
        ErrorHandler.handle(error, StackTrace.current, prefix: '客户端 ($clientIp) 连接错误');
        _handleClientDisconnect(socket); // 出错也视为断开
      },
    );
  }

  // 新增：统一处理客户端断开逻辑
  void _handleClientDisconnect(WebSocket socket) {
    final clientIp = _clientIps.remove(socket) ?? '未知IP'; // 获取并移除 IP
    _clients.remove(socket);
    Log.i('客户端 ($clientIp) 断开, 剩余客户端数: ${_clients.length}');
    // 调用客户端断开回调
    onClientDisconnected?.call(socket, clientIp);
  }

  /// 广播消息给所有连接的客户端。
  void broadcast(dynamic message, {WebSocket? sender}) {
    Log.i(
        '广播消息给 ${_clients.where((c) => c.readyState == WebSocket.open).length} 个客户端');
    for (var client in List<WebSocket>.from(_clients)) {
      if (client != sender && client.readyState == WebSocket.open) {
        try {
          client.add(message);
        } catch (e) {
          // 使用统一的错误处理器
          ErrorHandler.handle(e, StackTrace.current, prefix: '发送消息到客户端失败');
        }
      }
    }
  }

  /// 停止 WebSocket 服务器并关闭所有客户端连接。
  Future<void> stop() async {
    Log.i('正在停止 WebSocket 服务器...');
    for (final client in List<WebSocket>.from(_clients)) {
      try {
        _handleClientDisconnect(client); // 确保调用回调并清理
        await client.close();
      } catch (_) {}
    }
    // 清理 _clients 和 _clientIps (虽然上面会移除，双重保险)
    _clients.clear();
    _clientIps.clear();
    await _server?.close(force: true);
    _server = null;
    Log.i('WebSocket 服务器已停止');
  }
}
