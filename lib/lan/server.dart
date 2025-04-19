import 'dart:io';

import '../utils/log.dart';

class WsServer {
  final int port;
  HttpServer? _server;
  final List<WebSocket> _clients = [];

  WsServer({this.port = 8080});

  Future<void> start() async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      // 修复日志记录，使用 .address.address 获取 IP 字符串
      Log.i('服务器运行在: ${_server?.address.address}:$port');

      // 使用 listen 异步处理请求，不再阻塞 start 方法
      _server?.listen((request) async {
        // 添加 async
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          try {
            // 添加 try-catch 处理 upgrade 可能的错误
            final socket = await WebSocketTransformer.upgrade(request);
            _handleNewConnection(socket);
          } catch (e) {
            Log.e('处理WebSocket升级请求失败: $e');
            // 可以选择关闭请求或发送错误响应
            try {
              request.response.statusCode = HttpStatus.internalServerError;
              await request.response.close();
            } catch (_) {} // 忽略关闭响应时的错误
          }
        } else {
          // 处理非 WebSocket 请求 (可选，例如返回 404)
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
        }
      }, onError: (e) {
        // 添加服务器级别的错误处理
        Log.e('服务器监听错误: $e');
        // 可以考虑在这里停止服务器或进行其他错误处理
      });
    } catch (e) {
      Log.e('启动服务器失败: $e');
      rethrow; // 将异常重新抛出，以便上层调用者可以捕获
    }
  }

  void _handleNewConnection(WebSocket socket) {
    _clients.add(socket);
    Log.i('新客户端连接, 当前客户端数: ${_clients.length}');

    socket.listen(
      (message) {
        Log.i('收到消息: $message');
        // 注意：这里调用的是 _broadcast，确保方法名正确
        broadcast(message, sender: socket);
      },
      onDone: () {
        _clients.remove(socket);
        Log.i('客户端断开, 剩余客户端数: ${_clients.length}');
      },
      onError: (error) {
        _clients.remove(socket);
        Log.e('客户端错误: $error');
      },
      // cancelOnError: true, // 默认是 true，发生错误时取消监听
    );
  }

  // 将 _broadcast 改为 broadcast (如果 network_manager.dart 中调用的是 broadcast)
  // 或者保持 _broadcast，并在 network_manager.dart 中调用 _server?._broadcast
  void broadcast(dynamic message, {WebSocket? sender}) {
    Log.i(
        '广播消息给 ${_clients.where((c) => c != sender && c.readyState == WebSocket.open).length} 个客户端');
    for (var client in _clients) {
      if (client != sender && client.readyState == WebSocket.open) {
        try {
          client.add(message);
        } catch (e) {
          Log.e('发送消息到客户端失败: $e');
          // 可以考虑在这里移除发送失败的客户端
          // _clients.remove(client); // 注意：在遍历时修改列表可能导致问题，需要小心处理
        }
      }
    }
  }

  Future<void> stop() async {
    // 关闭所有客户端连接
    for (final client in List<WebSocket>.from(_clients)) {
      // 创建副本以安全移除
      await client.close();
    }
    _clients.clear();
    // 关闭服务器
    await _server?.close(force: true); // 添加 force: true 确保关闭
    _server = null;
    Log.i('服务器已停止');
  }
}
