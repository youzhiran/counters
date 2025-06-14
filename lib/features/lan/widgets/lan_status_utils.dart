import 'package:flutter/material.dart';
import 'package:counters/features/lan/lan_provider.dart';

/// LAN状态相关的工具类
/// 提供图标、颜色、工具提示等静态方法
class LanStatusUtils {
  LanStatusUtils._(); // 私有构造函数，防止实例化

  /// 根据LAN状态获取对应的图标
  static IconData getLanIcon(LanState lanState) {
    if (lanState.isHost) {
      // 主机模式：根据广播状态显示不同图标
      return lanState.isBroadcasting ? Icons.wifi_tethering : Icons.dns;
    } else if (lanState.isClientMode) {
      if (lanState.isConnected) {
        // 客户端已连接
        return Icons.wifi;
      } else if (lanState.isReconnecting) {
        // 客户端重连中
        return Icons.wifi_find;
      } else {
        // 客户端已断开
        return Icons.wifi_off;
      }
    } else {
      // 默认状态
      return Icons.wifi;
    }
  }

  /// 根据LAN状态获取图标颜色
  static Color getLanIconColor(LanState lanState) {
    if (lanState.isHost) {
      // 主机模式：绿色表示正常，橙色表示等待连接
      return lanState.connectedClientIps.isNotEmpty ? Colors.green : Colors.orange;
    } else if (lanState.isClientMode) {
      if (lanState.isConnected) {
        // 客户端已连接：绿色
        return Colors.green;
      } else if (lanState.isReconnecting) {
        // 客户端重连中：橙色
        return Colors.orange;
      } else {
        // 客户端已断开：红色
        return Colors.red;
      }
    } else {
      // 默认状态：灰色
      return Colors.grey;
    }
  }

  /// 根据LAN状态获取工具提示文本
  static String getLanTooltip(LanState lanState) {
    if (lanState.isHost) {
      return '主机模式: ${lanState.connectionStatus}';
    } else if (lanState.isClientMode) {
      if (lanState.isConnected) {
        return '客户端模式: 已连接';
      } else if (lanState.isReconnecting) {
        return '客户端模式: 重连中 (${lanState.reconnectAttempts}/${lanState.maxReconnectAttempts})';
      } else {
        return '客户端模式: 已断开连接';
      }
    } else {
      return '局域网状态: ${lanState.connectionStatus}';
    }
  }

  /// 判断是否应该显示LAN状态按钮
  static bool shouldShowLanButton(LanState lanState) {
    return lanState.isHost || lanState.isConnected || lanState.isClientMode;
  }

  /// 判断是否需要动画效果
  static bool needsAnimation(LanState lanState) {
    return (lanState.isHost && lanState.isBroadcasting) ||
           (lanState.isClientMode && lanState.isReconnecting);
  }
}
