import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:counters/app/config.dart';
import 'package:counters/common/utils/error_handler.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/common/utils/port_manager.dart';
import 'package:counters/common/widgets/message_overlay.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- 状态定义 ---

@immutable
class DiscoveredHost {
  final String ip;
  final int port; // WebSocket 端口
  final int discoveryPort; // 广播端口
  final String baseTid;
  final String hostName; // 可以是设备名或自定义名称
  final String? templateName; // 模板名称，可能为空（向后兼容）
  final DateTime lastSeen;

  const DiscoveredHost({
    required this.ip,
    required this.port,
    required this.discoveryPort,
    required this.baseTid,
    required this.hostName,
    this.templateName,
    required this.lastSeen,
  });

  // 重写 == 和 hashCode 以便在 Set 或 Map 中正确处理
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveredHost &&
          runtimeType == other.runtimeType &&
          ip == other.ip &&
          port == other.port &&
          discoveryPort == other.discoveryPort &&
          baseTid == other.baseTid;

  @override
  int get hashCode => ip.hashCode ^ port.hashCode ^ baseTid.hashCode;

  @override
  String toString() {
    return 'DiscoveredHost{ipAddress: $ip, port: $port, baseTid: $baseTid, hostName: $hostName, templateName: $templateName, lastSeen: $lastSeen}';
  }
}

@immutable
class LanDiscoveryState {
  final bool isScanning;
  final List<DiscoveredHost> hosts;
  final String? error;

  const LanDiscoveryState({
    this.isScanning = false,
    this.hosts = const [],
    this.error,
  });

  LanDiscoveryState copyWith({
    bool? isScanning,
    List<DiscoveredHost>? hosts,
    String? error,
    bool clearError = false,
  }) {
    return LanDiscoveryState(
      isScanning: isScanning ?? this.isScanning,
      hosts: hosts ?? this.hosts,
      error: clearError ? null : error ?? this.error,
    );
  }
}

// --- Provider ---

final lanDiscoveryProvider =
    StateNotifierProvider.autoDispose<LanDiscoveryNotifier, LanDiscoveryState>(
        (ref) {
  return LanDiscoveryNotifier();
});

// --- Notifier ---

class LanDiscoveryNotifier extends StateNotifier<LanDiscoveryState> {
  RawDatagramSocket? _socket;
  Timer? _cleanupTimer;

  // 使用 Set 存储 host key (ip:port:templateId) 来快速检查重复
  final Set<String> _knownHostKeys = {};

  LanDiscoveryNotifier() : super(const LanDiscoveryState());

  Future<void> startDiscovery() async {
    if (state.isScanning) return; // 防止重复启动

    state = state.copyWith(
        isScanning: true,
        error: null,
        clearError: true,
        hosts: []); // 开始扫描时清空列表和错误
    _knownHostKeys.clear();

    try {
      // 获取当前配置的广播端口
      final configuredPort = await PortManager.getCurrentDiscoveryPort();
      Log.i('尝试使用广播端口: $configuredPort');

      // 检查端口是否被占用
      if (await PortManager.isUdpPortOccupied(configuredPort)) {
        Log.e('广播端口 $configuredPort 被占用');
        if (mounted) {
          state = state.copyWith(
            isScanning: false,
            error: '端口 $configuredPort 被占用'
          );
        }
        GlobalMsgManager.showError(
          PortManager.getPortOccupiedErrorMessage(configuredPort)
        );
        return;
      }

      _socket = await RawDatagramSocket.bind(
          InternetAddress.anyIPv4, configuredPort);
      _socket?.broadcastEnabled = true; // 允许接收广播
      Log.i('开始监听 UDP 广播端口: $configuredPort');

      _socket?.listen(
        _handleDatagram,
        onError: (error) {
          Log.e('UDP 监听错误: $error');
          if (mounted) {
            state = state.copyWith(isScanning: false, error: '监听失败: $error');
          }
          stopDiscovery(); // 出错时停止
        },
        onDone: () {
          Log.i('UDP 监听结束');
          if (mounted) {
            state = state.copyWith(isScanning: false);
          }
        },
      );

      // 启动定时器定期清理过时的主机
      _cleanupTimer?.cancel();
      _cleanupTimer =
          Timer.periodic(const Duration(seconds: 15), _cleanupHosts);
    } catch (e) {
      Log.e('绑定 UDP 广播端口失败: $e');
      ErrorHandler.handle(e, StackTrace.current, prefix: '启动发现服务失败');
      if (mounted) {
        state = state.copyWith(isScanning: false, error: '绑定端口失败: $e');
      }
      await stopDiscovery(); // 确保清理
    }
  }

  void _handleDatagram(RawSocketEvent event) {
    if (event == RawSocketEvent.read) {
      Datagram? datagram = _socket?.receive();
      if (datagram != null) {
        try {
          final message = utf8.decode(datagram.data);
          // Log.d('收到 UDP 消息 from ${datagram.address.address}:${datagram.port}: $message');

          if (message.startsWith(Config.discoveryMsgPrefix)) {
            final parts =
                message.substring(Config.discoveryMsgPrefix.length).split('|');
            // 新格式: Prefix<HostIP>|<WebSocketPort>|<DiscoveryPort>|<BaseTID>|<HostName>|<TemplateName>
            // 兼容旧格式: Prefix<HostIP>|<WebSocketPort>|<BaseTID>|<HostName>|<TemplateName>
            if (parts.length >= 4) {
              final hostIp = parts[0];
              final wsPort = int.tryParse(parts[1]);

              // 检查是否为新格式（包含广播端口）
              int? discoveryPort;
              String baseTid;
              String hostName;
              String? templateName;

              if (parts.length >= 6) {
                // 新格式: IP|WSPort|DiscoveryPort|BaseTID|HostName|TemplateName
                discoveryPort = int.tryParse(parts[2]);
                baseTid = parts[3];
                hostName = parts[4];
                templateName = parts.length >= 6 ? parts[5] : null;
              } else {
                // 旧格式: IP|WSPort|BaseTID|HostName|TemplateName（向后兼容）
                discoveryPort = null; // 旧格式没有广播端口信息
                baseTid = parts[2];
                hostName = parts[3];
                templateName = parts.length >= 5 ? parts[4] : null;
              }

              if (wsPort != null) {
                final hostKey = '$hostIp:$wsPort:$baseTid';
                final now = DateTime.now();
                final newHost = DiscoveredHost(
                  ip: hostIp,
                  port: wsPort,
                  discoveryPort: discoveryPort ?? 8099, // 使用默认广播端口作为后备
                  baseTid: baseTid,
                  hostName: hostName,
                  templateName: templateName,
                  lastSeen: now,
                );

                Log.d("解析到主机: $newHost");

                final currentHosts = List<DiscoveredHost>.from(state.hosts);
                bool updated = false;

                // 检查是否已知，如果已知则更新 lastSeen
                if (_knownHostKeys.contains(hostKey)) {
                  final index = currentHosts.indexWhere((h) =>
                      h.ip == hostIp &&
                      h.port == wsPort &&
                      h.baseTid == baseTid);
                  if (index != -1) {
                    currentHosts[index] = newHost; // 更新信息，特别是 lastSeen
                    updated = true;
                  }
                } else {
                  // 添加新主机
                  _knownHostKeys.add(hostKey);
                  currentHosts.add(newHost);
                  updated = true;
                }

                if (updated && mounted) {
                  // 按 HostName 排序 (可选)
                  currentHosts.sort((a, b) => a.hostName.compareTo(b.hostName));
                  state = state.copyWith(hosts: currentHosts);
                }
              } else {
                Log.w('无效的端口号: ${parts[1]} in message: $message');
              }
            } else {
              Log.w('无效的发现消息格式: $message');
            }
          }
        } catch (e) {
          Log.e('处理 UDP 消息失败: $e');
        }
      }
    }
  }

  // 定期清理超过一定时间未收到消息的主机
  void _cleanupHosts(Timer timer) {
    if (!mounted) return;
    final now = DateTime.now();
    final timeout = const Duration(seconds: 30); // 例如，30秒没收到消息就移除
    final currentHosts = List<DiscoveredHost>.from(state.hosts);
    final Set<String> currentKeys = Set.from(_knownHostKeys); // 创建副本以修改

    bool changed = false;
    currentHosts.removeWhere((host) {
      if (now.difference(host.lastSeen) > timeout) {
        final hostKey = '${host.ip}:${host.port}:${host.baseTid}';
        currentKeys.remove(hostKey); // 从 Set 中移除
        changed = true;
        Log.i("移除超时主机: ${host.hostName} (${host.ip})");
        return true; // 从 List 中移除
      }
      return false;
    });

    if (changed && mounted) {
      _knownHostKeys.clear();
      _knownHostKeys.addAll(currentKeys); // 更新 Set
      state = state.copyWith(hosts: currentHosts);
    }
  }

  Future<void> stopDiscovery() async {
    Log.i('停止 UDP 发现');
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _socket?.close();
    _socket = null;
    if (mounted) {
      state = state.copyWith(isScanning: false); // 确保状态更新
    }
  }

  @override
  void dispose() {
    Log.d('LanDiscoveryNotifier dispose');
    stopDiscovery();
    super.dispose();
  }
}
