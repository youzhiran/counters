// common/utils/port_manager.dart

import 'dart:io';
import 'package:counters/app/config.dart';
import 'package:counters/common/utils/log.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 端口管理器，负责端口占用检测和自动端口选择
class PortManager {
  static const String _keyCustomDiscoveryPort = 'custom_discovery_port';
  static const String _keyCustomWebSocketPort = 'custom_websocket_port';
  
  /// 检测端口是否被占用 (UDP)
  static Future<bool> isUdpPortOccupied(int port) async {
    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
      socket.close();
      return false; // 端口可用
    } catch (e) {
      Log.d('UDP端口 $port 被占用: $e');
      return true; // 端口被占用
    }
  }

  /// 检测端口是否被占用 (TCP)
  static Future<bool> isTcpPortOccupied(int port) async {
    try {
      final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      await server.close(force: true);
      return false; // 端口可用
    } catch (e) {
      Log.d('TCP端口 $port 被占用: $e');
      return true; // 端口被占用
    }
  }

  /// 获取当前配置的广播端口
  /// 优先使用用户自定义端口，否则使用默认端口
  static Future<int> getCurrentDiscoveryPort() async {
    try {
      final customPort = await getCustomDiscoveryPort();
      return customPort ?? Config.discoveryPort;
    } catch (e) {
      Log.e('获取当前广播端口失败: $e');
      return Config.discoveryPort;
    }
  }

  /// 获取当前配置的服务端口
  /// 优先使用用户自定义端口，否则使用默认端口
  static Future<int> getCurrentWebSocketPort() async {
    try {
      final customPort = await getCustomWebSocketPort();
      return customPort ?? Config.webSocketPort;
    } catch (e) {
      Log.e('获取当前服务端口失败: $e');
      return Config.webSocketPort;
    }
  }

  /// 获取用户自定义的广播端口
  static Future<int?> getCustomDiscoveryPort() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final port = prefs.getInt(_keyCustomDiscoveryPort);
      if (port != null && port > 0 && port <= 65535) {
        return port;
      }
      return null;
    } catch (e) {
      Log.e('获取自定义广播端口失败: $e');
      return null;
    }
  }

  /// 获取用户自定义的服务端口
  static Future<int?> getCustomWebSocketPort() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final port = prefs.getInt(_keyCustomWebSocketPort);
      if (port != null && port > 0 && port <= 65535) {
        return port;
      }
      return null;
    } catch (e) {
      Log.e('获取自定义服务端口失败: $e');
      return null;
    }
  }

  /// 设置用户自定义的广播端口
  static Future<bool> setCustomDiscoveryPort(int? port) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (port == null) {
        await prefs.remove(_keyCustomDiscoveryPort);
        Log.i('已清除自定义广播端口设置');
      } else {
        if (port <= 0 || port > 65535) {
          Log.e('无效的端口号: $port');
          return false;
        }
        await prefs.setInt(_keyCustomDiscoveryPort, port);
        Log.i('已设置自定义广播端口: $port');
      }
      return true;
    } catch (e) {
      Log.e('设置自定义广播端口失败: $e');
      return false;
    }
  }

  /// 设置用户自定义的服务端口
  static Future<bool> setCustomWebSocketPort(int? port) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (port == null) {
        await prefs.remove(_keyCustomWebSocketPort);
        Log.i('已清除自定义服务端口设置');
      } else {
        if (port <= 0 || port > 65535) {
          Log.e('无效的端口号: $port');
          return false;
        }
        await prefs.setInt(_keyCustomWebSocketPort, port);
        Log.i('已设置自定义服务端口: $port');
      }
      return true;
    } catch (e) {
      Log.e('设置自定义服务端口失败: $e');
      return false;
    }
  }

  /// 验证端口号是否有效
  static bool isValidPort(int port) {
    return port > 0 && port <= 65535;
  }

  /// 检查广播端口是否在推荐范围内
  static bool isDiscoveryPortInRecommendedRange(int port) {
    return port >= Config.discoveryPortMin && port <= Config.discoveryPortMax;
  }

  /// 检查服务端口是否在推荐范围内
  static bool isWebSocketPortInRecommendedRange(int port) {
    return port >= Config.webSocketPortMin && port <= Config.webSocketPortMax;
  }

  /// 获取端口占用错误的用户友好描述
  static String getPortOccupiedErrorMessage(int port, {bool isWebSocket = false}) {
    final portType = isWebSocket ? '局域网服务端口' : '局域网广播端口';
    return '端口 $port 已被其他程序占用\n\n'
        '解决方案：\n'
        '• 关闭可能占用该端口的其他应用程序\n'
        '• 在设置-高级中更改 【$portType】 端口\n'
        '• 重启设备释放端口资源';
  }
}
