import 'dart:async';
import 'dart:convert';

import 'package:counters/common/model/sync_messages.dart';
import 'package:counters/common/utils/error_handler.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/features/lan/lan_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ping_provider.g.dart';

/// Ping状态数据类
@immutable
class PingState {
  final int? pingMs;
  final bool isActive;
  final String? error;
  final DateTime? lastUpdate;

  const PingState({
    this.pingMs,
    this.isActive = false,
    this.error,
    this.lastUpdate,
  });

  PingState copyWith({
    int? pingMs,
    bool? isActive,
    String? error,
    DateTime? lastUpdate,
    bool clearError = false,
    bool clearPing = false,
  }) {
    return PingState(
      pingMs: clearPing ? null : (pingMs ?? this.pingMs),
      isActive: isActive ?? this.isActive,
      error: clearError ? null : (error ?? this.error),
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }

  /// 获取格式化的ping显示文本
  String get displayText {
    if (error != null) return 'Ping: 错误';
    if (pingMs == null) return 'Ping: --ms';
    return 'Ping: ${pingMs}ms';
  }

  /// 根据ping值获取颜色状态
  PingStatus get status {
    if (error != null) return PingStatus.error;
    if (pingMs == null) return PingStatus.unknown;
    if (pingMs! <= 50) return PingStatus.excellent;
    if (pingMs! <= 100) return PingStatus.good;
    if (pingMs! <= 200) return PingStatus.fair;
    return PingStatus.poor;
  }
}

/// Ping状态枚举
enum PingStatus {
  excellent, // 优秀 (<=50ms)
  good,      // 良好 (51-100ms)
  fair,      // 一般 (101-200ms)
  poor,      // 较差 (>200ms)
  error,     // 错误
  unknown,   // 未知
}

/// Ping消息类型
class PingMessage {
  final String type;
  final int timestamp;
  final String? id;

  const PingMessage({
    required this.type,
    required this.timestamp,
    this.id,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'timestamp': timestamp,
    if (id != null) 'id': id,
  };

  factory PingMessage.fromJson(Map<String, dynamic> json) => PingMessage(
    type: json['type'] as String,
    timestamp: json['timestamp'] as int,
    id: json['id'] as String?,
  );
}

@Riverpod(keepAlive: true)
class Ping extends _$Ping {
  Timer? _pingTimer;
  final Map<String, int> _pendingPings = {};
  static const Duration _pingInterval = Duration(seconds: 3);
  static const Duration _pingTimeout = Duration(seconds: 5);

  @override
  PingState build() {
    // 监听LAN状态变化
    ref.listen(lanProvider, (previous, next) {
      _handleLanStateChange(previous, next);
    });

    // 清理资源
    ref.onDispose(() {
      _stopPing();
    });

    return const PingState();
  }

  /// 处理LAN状态变化
  void _handleLanStateChange(LanState? previous, LanState current) {
    // 修复：只在客户端模式且已连接时激活ping，主机端隐藏ping显示
    final shouldBeActive = current.isConnected && !current.isHost;

    if (shouldBeActive && !state.isActive) {
      // 开始ping测量
      _startPing();
    } else if (!shouldBeActive && state.isActive) {
      // 停止ping测量
      _stopPing();
    }
  }

  /// 开始ping测量
  void _startPing() {
    if (state.isActive) return;
    
    Log.i('开始ping测量');
    state = state.copyWith(isActive: true, clearError: true);
    
    // 立即执行一次ping
    _performPing();
    
    // 设置定时器
    _pingTimer = Timer.periodic(_pingInterval, (_) => _performPing());
  }

  /// 停止ping测量
  void _stopPing() {
    if (!state.isActive) return;
    
    Log.i('停止ping测量');
    _pingTimer?.cancel();
    _pingTimer = null;
    _pendingPings.clear();
    
    state = state.copyWith(
      isActive: false,
      clearPing: true,
      clearError: true,
    );
  }

  /// 执行ping测量
  void _performPing() {
    try {
      final lanState = ref.read(lanProvider);
      final networkManager = lanState.networkManager;
      
      if (networkManager == null) {
        _handlePingError('网络管理器未初始化');
        return;
      }

      final pingId = DateTime.now().millisecondsSinceEpoch.toString();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // 记录发送时间
      _pendingPings[pingId] = timestamp;
      
      // 发送ping消息，需要包装在SyncMessage中
      final pingMessage = PingMessage(
        type: 'ping',
        timestamp: timestamp,
        id: pingId,
      );

      // 包装在SyncMessage中发送
      final syncMessage = SyncMessage(type: 'ping', data: pingMessage.toJson());
      networkManager.sendMessage(jsonEncode(syncMessage.toJson()));
      
      // 设置超时处理
      Timer(_pingTimeout, () {
        if (_pendingPings.containsKey(pingId)) {
          _pendingPings.remove(pingId);
          _handlePingError('Ping超时');
        }
      });
      
    } catch (e, stackTrace) {
      ErrorHandler.handle(e, stackTrace, prefix: 'Ping测量失败');
      _handlePingError('Ping测量异常: $e');
    }
  }

  /// 处理ping响应
  void handlePingResponse(Map<String, dynamic> data) {
    try {
      final message = PingMessage.fromJson(data);
      
      if (message.type == 'pong' && message.id != null) {
        final sendTime = _pendingPings.remove(message.id!);
        if (sendTime != null) {
          final currentTime = DateTime.now().millisecondsSinceEpoch;
          final pingMs = currentTime - sendTime;
          
          state = state.copyWith(
            pingMs: pingMs,
            lastUpdate: DateTime.now(),
            clearError: true,
          );
          
          Log.v('Ping响应: ${pingMs}ms');
        }
      }
    } catch (e, stackTrace) {
      ErrorHandler.handle(e, stackTrace, prefix: '处理Ping响应失败');
    }
  }

  /// 处理ping错误
  void _handlePingError(String error) {
    state = state.copyWith(error: error, lastUpdate: DateTime.now());
    Log.w('Ping错误: $error');
  }

  /// 手动触发ping测量
  void triggerPing() {
    if (state.isActive) {
      _performPing();
    }
  }
}
