import 'package:network_info_plus/network_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async'; // 导入 async

import '../utils/log.dart';
import '../manager/network_manager.dart'; // 引入包含类型别名的文件

Future<String?> getLocalIp() async {
  final info = NetworkInfo();
  String? ip;

  try {
    ip = await info.getWifiIP(); // 获取WiFi IP
    if (ip == null || ip.isEmpty) {
      ip = await info.getWifiIP(); // 备用获取方式
    }
  } catch (e) {
    Log.e('获取IP失败: $e');
  }

  return ip;
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

  // 修改构造函数参数类型
  WsClient({required this.onMessage, this.onConnectionChange});

  Future<void> connect(String serverIp, int port) async {
    final uri = Uri.parse('ws://$serverIp:$port');
    Log.i('尝试连接到: $uri');
    onConnectionChange?.call(false, '连接中...'); // 通知正在连接

    try {
      _channel = WebSocketChannel.connect(uri);

      // 等待连接建立 (可选，但可以更早知道连接是否成功)
      await _channel!.ready;
      Log.i('WebSocket 连接已准备就绪');
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
          onConnectionChange?.call(false, '连接错误: $error'); // 通知连接错误
          // 可以在这里添加重连逻辑
          _resetConnection();
        },
        onDone: () {
          Log.i('WebSocket 连接已关闭');
          onConnectionChange?.call(false, '连接已断开'); // 通知连接断开
          _resetConnection();
        },
        cancelOnError: false, // 发生错误时不自动取消监听，以便重连
      );

    } catch (e) {
      Log.e('WebSocket 连接失败: $e');
      onConnectionChange?.call(false, '连接失败: $e'); // 通知连接失败
      _resetConnection();
      rethrow; // 将异常抛出，让 Manager 知道
    }
  }

  void send(dynamic message) {
    if (_channel != null && _channel!.closeCode == null) {
      try {
        _channel!.sink.add(message);
      } catch (e) {
         Log.e("发送消息失败: $e");
         onConnectionChange?.call(false, '发送失败: $e');
      }
    } else {
      Log.w('无法发送消息：连接未建立或已关闭');
      onConnectionChange?.call(false, '连接已断开，无法发送');
    }
  }

  Future<void> disconnect() async {
    await _streamSubscription?.cancel(); // 取消监听
    _channel?.sink.close();
    _resetConnection();
    Log.i('客户端手动断开连接');
    onConnectionChange?.call(false, '已断开连接');
  }

  // 重置连接状态
  void _resetConnection() {
     _channel = null;
     _streamSubscription = null;
  }
}
