import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:counters/app/config.dart';
import 'package:counters/common/model/base_template.dart';
import 'package:counters/common/model/player_info.dart';
import 'package:counters/common/model/sync_messages.dart';
import 'package:counters/common/utils/error_handler.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/common/utils/port_manager.dart';
import 'package:counters/common/utils/template_utils.dart';
import 'package:counters/common/widgets/message_overlay.dart';
import 'package:counters/features/lan/client.dart';
import 'package:counters/features/lan/lan_discovery_provider.dart';
import 'package:counters/features/lan/network_manager.dart';
import 'package:counters/features/lan/ping_provider.dart';
// 引入 Score Provider 和 消息 Payload 类
import 'package:counters/features/score/score_provider.dart';
import 'package:counters/features/template/template_provider.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lan_provider.g.dart';

// 状态类 (保持不变)
@immutable
class LanState {
  final bool isLoading;
  final bool isHost;
  final bool isConnected;
  final String localIp;
  final String connectionStatus;
  final List<String> receivedMessages;
  final ScoreNetworkManager? networkManager; // 网络管理器 (主机或客户端)
  final bool isBroadcasting; // 新增：是否正在广播
  final List<String> connectedClientIps; // 新增：存储已连接客户端 IP
  final String interfaceName; // 新增：本机网络接口名称
  final int serverPort; // 新增：服务器端口号
  final int discoveryPort; // 新增：广播发现端口号

  // 新增：客户端模式状态管理
  final bool isClientMode; // 是否处于客户端模式（即使断开连接也保持）
  final bool isConnecting; // 是否正在建立连接（用于防止误导性警告）
  final bool isReconnecting; // 是否正在重连
  final int reconnectAttempts; // 当前重连尝试次数
  final int maxReconnectAttempts; // 最大重连次数
  final String? disconnectReason; // 断开连接的原因
  final String? hostIp; // 记录主机IP用于重连

  const LanState({
    this.isLoading = false,
    this.isHost = false,
    this.isConnected = false,
    this.localIp = '获取中...',
    this.connectionStatus = '未连接',
    this.receivedMessages = const [],
    this.networkManager,
    this.isBroadcasting = false, // 新增：默认不广播
    this.connectedClientIps = const [], // 新增：默认空列表
    this.interfaceName = '', // 新增：默认空字符串
    this.serverPort = 0, // 新增：默认端口为0
    this.discoveryPort = 0, // 新增：默认广播端口为0
    // 新增：客户端模式相关状态
    this.isClientMode = false, // 默认不是客户端模式
    this.isConnecting = false, // 默认不在连接建立中
    this.isReconnecting = false, // 默认不在重连
    this.reconnectAttempts = 0, // 默认重连次数为0
    this.maxReconnectAttempts = 5, // 默认最大重连次数为5
    this.disconnectReason, // 默认无断开原因
    this.hostIp, // 默认无主机IP
  });

  LanState copyWith({
    bool? isLoading,
    bool? isHost,
    bool? isConnected,
    String? localIp,
    String? connectionStatus,
    List<String>? receivedMessages,
    ScoreNetworkManager? networkManager,
    bool? isBroadcasting, // 新增
    List<String>? connectedClientIps, // 新增
    bool clearNetworkManager = false,
    String? interfaceName, // 新增
    int? serverPort, // 新增
    int? discoveryPort, // 新增
    // 新增：客户端模式相关参数
    bool? isClientMode,
    bool? isConnecting,
    bool? isReconnecting,
    int? reconnectAttempts,
    int? maxReconnectAttempts,
    String? disconnectReason,
    String? hostIp,
    bool clearDisconnectReason = false,
    bool clearHostIp = false,
  }) {
    return LanState(
      isLoading: isLoading ?? this.isLoading,
      isHost: isHost ?? this.isHost,
      isConnected: isConnected ?? this.isConnected,
      localIp: localIp ?? this.localIp,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      receivedMessages: receivedMessages ?? this.receivedMessages,
      networkManager:
          clearNetworkManager ? null : networkManager ?? this.networkManager,
      isBroadcasting: isBroadcasting ?? this.isBroadcasting,
      // 新增
      connectedClientIps: connectedClientIps ?? this.connectedClientIps,
      // 新增
      interfaceName: interfaceName ?? this.interfaceName,
      // 新增
      serverPort: serverPort ?? this.serverPort,
      // 新增
      discoveryPort: discoveryPort ?? this.discoveryPort,
      // 新增
      // 新增：客户端模式相关状态
      isClientMode: isClientMode ?? this.isClientMode,
      isConnecting: isConnecting ?? this.isConnecting,
      isReconnecting: isReconnecting ?? this.isReconnecting,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
      maxReconnectAttempts: maxReconnectAttempts ?? this.maxReconnectAttempts,
      disconnectReason: clearDisconnectReason
          ? null
          : (disconnectReason ?? this.disconnectReason),
      hostIp: clearHostIp ? null : (hostIp ?? this.hostIp),
    );
  }
}

@Riverpod(keepAlive: true)
class Lan extends _$Lan {
  @override
  LanState build() {
    // 延迟执行IP获取，避免在build中直接修改state
    Future.microtask(() => _fetchLocalIp());
    return const LanState();
  }

  /// 手动重置状态（用于完全退出主机或客户端模式）
  void resetToInitialState() {
    Log.i('手动重置 LAN 状态到初始状态');
    disposeManager();
    state = const LanState();
    Future.microtask(() => _fetchLocalIp());
  }

  late final TextEditingController _hostIpController = TextEditingController();
  late final TextEditingController _messageController = TextEditingController();

  // 提供访问控制器的方法（用于UI）
  TextEditingController getHostIpController() => _hostIpController;

  TextEditingController getMessageController() => _messageController;

  // 使用当前输入的主机IP连接
  Future<void> connectToHostFromInput(int port) async {
    final hostIp = _hostIpController.text.trim();
    if (hostIp.isNotEmpty) {
      await connectToHost(hostIp, port);
    } else {
      GlobalMsgManager.showMessage('请输入主机IP地址');
    }
  }

  RawDatagramSocket? _udpSocket;
  Timer? _broadcastTimer;
  String _currentBaseTid = '';
  int _currentWsPort = 0;
  String _currentTemplateName = '';

  void dispose() {
    _hostIpController.dispose();
    _messageController.dispose();
    disposeManager();
    Log.d('LanNotifier dispose');
  }

  Future<void> _fetchLocalIp() async {
    state = state.copyWith(localIp: '获取中...', interfaceName: ''); // 获取中时清空接口名
    try {
      final ipData = await getWlanIp(); // 获取包含IP和接口名称的Map
      state = state.copyWith(
        localIp: ipData?['ip'] ?? '获取失败',
        interfaceName: ipData?['name'] ?? '',
      );
    } catch (e) {
      // 使用统一的错误处理器
      ErrorHandler.handle(e, StackTrace.current, prefix: '获取本地IP失败');
      state = state.copyWith(localIp: '获取失败', interfaceName: '');
    }
  }

  Future<void> refreshLocalIp() async {
    Log.i("手动刷新本地 IP 地址...");
    await _fetchLocalIp();
  }

  /// 验证IP地址格式是否有效
  bool _isValidIpAddress(String ip) {
    if (ip.isEmpty || ip == '获取中...' || ip == '获取失败') {
      return false;
    }

    try {
      final parts = ip.split('.');
      if (parts.length != 4) return false;

      for (final part in parts) {
        final num = int.tryParse(part);
        if (num == null || num < 0 || num > 255) return false;
      }

      // 排除一些明显无效的IP地址
      if (ip.startsWith('0.') ||
          ip.startsWith('127.') ||
          ip == '255.255.255.255') {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  void _handleMessageReceived(String rawMessage) async {
    Log.v('收到原始网络消息: $rawMessage');
    final currentMessages = List<String>.from(state.receivedMessages);
    currentMessages.insert(0, "原始: $rawMessage");
    if (currentMessages.length > 100) {
      currentMessages.removeRange(100, currentMessages.length);
    }
    state = state.copyWith(receivedMessages: currentMessages);

    try {
      final jsonMap = jsonDecode(rawMessage) as Map<String, dynamic>;
      final receivedMessage = SyncMessage.fromJson(jsonMap);
      final type = receivedMessage.type;
      final data = receivedMessage.data;

      Log.v('收到解析后消息: $type');

      if (!state.isHost) {
        switch (type) {
          case "sync_state":
            if (data is Map<String, dynamic>) {
              final payload = SyncStatePayload.fromJson(data);
              Log.i('收到全量同步状态');

              // 修复：在应用同步状态后，检查是否需要补充玩家信息
              ref.read(scoreProvider.notifier).applySyncState(payload.session);

              // 检查玩家信息是否为空，如果为空则尝试从模板中获取
              final currentState = ref.read(scoreProvider).valueOrNull;
              if (currentState != null && currentState.players.isEmpty) {
                Log.w('同步状态后玩家信息为空，尝试从模板中获取玩家信息');
                final templatesAsync = ref.read(templatesProvider);
                final templates = templatesAsync.valueOrNull;
                if (templates != null) {
                  final template = templates.firstWhereOrNull(
                      (t) => t.tid == payload.session.templateId);
                  if (template != null && template.players.isNotEmpty) {
                    Log.i('从模板中补充玩家信息: ${template.players.length} 个玩家');
                    ref
                        .read(scoreProvider.notifier)
                        .applyPlayerInfo(template.players);
                  }
                }
              }
            } else {
              Log.w('收到无效的 sync_state 消息负载类型: ${data.runtimeType}');
            }
            break;

          case "template_info":
            try {
              final templateMap = data as Map<String, dynamic>;
              final receivedTid = templateMap['tid']?.toString();
              final templateType = templateMap['template_type']?.toString();
              final playersJson =
                  templateMap['players'] as List<dynamic>? ?? [];
              final players = playersJson
                  .map((e) => PlayerInfo.fromJson(e as Map<String, dynamic>))
                  .toList();
              Log.i("解析到玩家数据，players=$players");

              // 获取当前页面需要的templateId（从当前session或_scoreProvider中获取）
              String? requiredTid;
              final scoreStateValue = ref.read(scoreProvider).value;
              if (scoreStateValue != null &&
                  scoreStateValue.currentSession != null) {
                requiredTid = scoreStateValue.currentSession!.templateId;
              }

              Log.i("收到模板，tid=${receivedTid ?? 'null'}");

              // 如果tid不一致，强制修正
              if (requiredTid != null && receivedTid != requiredTid) {
                templateMap['tid'] = requiredTid;
                Log.w('修正模板tid为: $requiredTid');
              }

              // 使用 TemplateUtils 构建模板实例
              if (templateType == null) {
                Log.e('模板数据中缺少 templateType');
                break; // 或者 continue，取决于你希望如何处理缺少类型的情况
              }

              BaseTemplate? template = TemplateUtils.buildTemplateFromType(
                  templateType, templateMap, players);

              if (template == null) {
                // 如果构建模板失败，记录错误并跳出循环
                Log.e('使用 TemplateUtils 构建模板失败: $templateType');
                break;
              }

              // 修复：先应用玩家信息到 ScoreNotifier，确保后续的 sync_state 能正确使用玩家信息
              if (players.isNotEmpty) {
                Log.i("应用模板中的玩家信息到 ScoreNotifier: ${players.length} 个玩家");
                Log.i(
                    "玩家详情: ${players.map((p) => '${p.name}(${p.pid})').join(', ')}");
                ref.read(scoreProvider.notifier).applyPlayerInfo(players);
              } else {
                Log.w("模板中没有玩家信息，这可能导致后续的同步问题");
              }

              // 使用 templatesProvider.notifier 的新方法来保存或更新模板
              final templatesNotifier = ref.read(templatesProvider.notifier);
              await templatesNotifier.saveOrUpdateNetworkTemplate(template);
              Log.i("同步网络模板到本地：${template.tid}");
            } catch (e, stack) {
              // 使用统一的错误处理器
              ErrorHandler.handle(e, stack, prefix: '解析template_info失败');
            }
            break;

          case "update_score":
            if (data is Map<String, dynamic>) {
              final payload = UpdateScorePayload.fromJson(data);
              Log.i(
                  '收到单点分数更新: Player ${payload.playerId}, Round ${payload.roundIndex}, Score ${payload.score}');
              ref.read(scoreProvider.notifier).applyUpdateScore(
                  payload.playerId, payload.roundIndex, payload.score);
            } else {
              Log.w('收到无效的 update_score 消息负载类型: ${data.runtimeType}');
            }
            break;

          case "sync_round_data":
            if (data is Map<String, dynamic>) {
              final sessionId = data['sessionId'] as String?;
              final roundIndex = data['roundIndex'] as int?;
              final playerScoresMap =
                  (data['playerScoresMap'] as Map<String, dynamic>?)
                      ?.cast<String, int?>();
              final playerExtendedDataMap =
                  (data['playerExtendedDataMap'] as Map<String, dynamic>?)
                      ?.cast<String, Map<String, dynamic>?>();

              if (sessionId != null &&
                  roundIndex != null &&
                  playerScoresMap != null &&
                  playerExtendedDataMap != null) {
                Log.i('收到轮次数据同步: Session $sessionId, Round $roundIndex');
                ref.read(scoreProvider.notifier).applyRoundData(sessionId,
                    roundIndex, playerScoresMap, playerExtendedDataMap);
              } else {
                Log.w('收到无效的 sync_round_data 消息负载格式');
              }
            } else {
              Log.w('收到无效的 sync_round_data 消息负载类型: ${data.runtimeType}');
            }
            break;

          case "new_round":
            if (data is Map<String, dynamic>) {
              final payload = NewRoundPayload.fromJson(data);
              Log.i('收到新回合通知: New Round Index ${payload.newRoundIndex}');
              ref
                  .read(scoreProvider.notifier)
                  .applyNewRound(payload.newRoundIndex);
            } else {
              Log.w('收到无效的 new_round 消息负载类型: ${data.runtimeType}');
            }
            break;

          case "reset_game":
            Log.i('收到游戏重置通知');
            ref.read(scoreProvider.notifier).applyResetGame();
            break;

          case "game_end":
            Log.i('收到游戏结束通知');
            ref.read(scoreProvider.notifier).applyGameEnd();
            break;

          case "player_info":
            if (data is List) {
              Log.i('收到玩家信息同步');
              try {
                final players = (data)
                    .map((item) =>
                        PlayerInfo.fromJson(item as Map<String, dynamic>))
                    .toList();
                Log.d("已解析到 ${players.length} 个玩家信息");
                ref.read(scoreProvider.notifier).applyPlayerInfo(players);
              } catch (e) {
                // 使用统一的错误处理器
                ErrorHandler.handle(e, StackTrace.current,
                    prefix: '解析player_info列表失败');
              }
            } else {
              Log.w('收到无效的 player_info 消息负载类型: ${data.runtimeType}');
            }
            break;

          case "host_disconnect":
            Log.i('收到主机断开连接通知');
            String reason = '主机已断开连接';
            if (data is Map<String, dynamic>) {
              final payload = HostDisconnectPayload.fromJson(data);
              if (payload.reason != null && payload.reason!.isNotEmpty) {
                reason = '主机已断开连接: ${payload.reason}';
              }
            }
            _handleHostDisconnect(reason);
            break;

          case "ping":
            // 处理ping消息，发送pong响应
            if (data is Map<String, dynamic>) {
              final pingMessage = PingMessage.fromJson(data);
              final pongMessage = PingMessage(
                type: 'pong',
                timestamp: DateTime.now().millisecondsSinceEpoch,
                id: pingMessage.id,
              );
              state.networkManager
                  ?.sendMessage(jsonEncode(pongMessage.toJson()));
              Log.v('响应ping消息: ${pingMessage.id}');
            }
            break;

          case "pong":
            // 处理pong响应
            if (data is Map<String, dynamic>) {
              ref.read(pingProvider.notifier).handlePingResponse(data);
            }
            break;

          default:
            Log.w('收到未知消息类型: $type');
            break;
        }
      } else {
        // 主机模式下的消息已经在 _handleClientMessage 中处理
        Log.d('主机收到来自客户端的消息，已转发到 _handleClientMessage 处理: $type');
      }
    } catch (e) {
      // 使用统一的错误处理器
      ErrorHandler.handle(e, StackTrace.current, prefix: '解析或处理网络消息失败');
      final currentMessages = List<String>.from(state.receivedMessages);
      currentMessages.insert(0, "解析失败: $e");
      if (currentMessages.length > 100) {
        currentMessages.removeRange(100, currentMessages.length);
      }
      state = state.copyWith(receivedMessages: currentMessages);
    }
  }

  void _handleConnectionChanged(bool isConnected, String statusMessage) {
    Log.i(
        '_handleConnectionChanged: $statusMessage (isConnected: $isConnected)');

    // 检测重连状态和重连次数
    final isReconnecting = statusMessage.contains('重连中') ||
        statusMessage.contains('正在尝试重连') ||
        statusMessage.startsWith('重连尝试:');
    int reconnectAttempts = state.reconnectAttempts;

    // 如果连接成功，重置重连次数
    if (isConnected) {
      reconnectAttempts = 0;
    } else if (statusMessage.startsWith('重连尝试:')) {
      // 修复：从客户端发送的特殊消息中解析重连次数
      final attemptStr = statusMessage.substring('重连尝试:'.length);
      reconnectAttempts = int.tryParse(attemptStr) ?? state.reconnectAttempts;
    }

    // 构建显示用的状态消息，包含正确的重连次数
    String displayStatusMessage = statusMessage;
    if (isReconnecting && state.isClientMode) {
      displayStatusMessage =
          '正在重连... ($reconnectAttempts/${state.maxReconnectAttempts})';
    } else if (statusMessage.startsWith('重连尝试:')) {
      // 将特殊的重连消息转换为用户友好的显示
      displayStatusMessage =
          '正在重连... ($reconnectAttempts/${state.maxReconnectAttempts})';
    }

    state = state.copyWith(
      isConnected: isConnected,
      connectionStatus: displayStatusMessage,
      isReconnecting: isReconnecting,
      reconnectAttempts: reconnectAttempts,
    );

    // 如果连接断开且处于客户端模式，显示相应提示
    // 修复：添加 !state.isConnecting 检查，防止在连接建立过程中显示误导性警告
    if (!isConnected &&
        state.isClientMode &&
        !isReconnecting &&
        !state.isConnecting) {
      if (statusMessage.contains('重连失败')) {
        GlobalMsgManager.showError('连接断开，重连失败。您可以尝试手动重连或退出客户端模式。');
      } else if (!statusMessage.contains('已断开连接')) {
        GlobalMsgManager.showWarn('与主机的连接已断开，正在尝试重连...');
      }
    }
  }

  // 处理主机主动断开连接
  void _handleHostDisconnect(String reason) {
    Log.i('处理主机断开连接: $reason');
    GlobalMsgManager.showError(reason);

    // 清理连接但保持客户端模式状态
    state = state.copyWith(
      isConnected: false,
      connectionStatus: '主机已断开连接',
      disconnectReason: reason,
      isConnecting: false,
      // 修复：清除连接建立中状态
      isReconnecting: false,
      reconnectAttempts: 0,
    );

    // 清理网络管理器
    disposeManager();
  }

  // 修改：处理客户端连接的回调 - 仅更新状态，不主动发送消息
  void _handleClientConnected(WebSocket client, String clientIp) {
    final currentClients = List<String>.from(state.connectedClientIps);
    if (!currentClients.contains(clientIp)) {
      // 防止重复添加
      currentClients.add(clientIp);
      // 更新连接状态和客户端列表
      state = state.copyWith(
        isConnected: currentClients.isNotEmpty, // 如果有客户端连接，则 isConnected 为 true
        connectionStatus: '${currentClients.length} 个客户端已连接', // 更新状态文本
        connectedClientIps: currentClients,
      );
      Log.i('LanNotifier: 客户端 ($clientIp) 已连接，等待客户端请求同步...'); // 修改日志
    }
  }

  // 新增：处理客户端断开的回调
  void _handleClientDisconnected(WebSocket client, String clientIp) {
    final currentClients = List<String>.from(state.connectedClientIps);
    final removed = currentClients.remove(clientIp);
    if (removed) {
      // 更新连接状态和客户端列表
      state = state.copyWith(
        isConnected: currentClients.isNotEmpty, // 更新连接状态
        connectionStatus: currentClients.isEmpty
            ? '等待连接...'
            : '${currentClients.length} 个客户端已连接',
        connectedClientIps: currentClients,
      );
      Log.i('LanNotifier: 客户端 ($clientIp) 已断开连接');
    }
  }

  // 新增：处理服务器错误的回调
  void _handleServerError(String error) {
    // 使用统一的错误处理器
    ErrorHandler.handle(Exception(error), StackTrace.current,
        prefix: 'LAN服务器运行时错误');

    // 更新状态显示错误信息
    state = state.copyWith(
      connectionStatus: '服务器错误',
    );
  }

  // 新增：处理启动失败的回调
  void _handleStartupError(String error) {
    Log.e('LAN服务器启动失败: $error');

    // 检查是否为端口占用错误，提供用户友好的提示
    if (_isPortOccupiedError(error)) {
      // 端口占用错误，显示用户友好的提示
      final port = _currentWsPort > 0 ? _currentWsPort : 8080;
      GlobalMsgManager.showError('端口 $port 已被占用\n\n'
          '解决方案：\n'
          '• 关闭其他可能占用该端口的应用\n'
          '• 重启应用程序\n'
          '• 如果问题持续，请重启设备');

      state = state.copyWith(
        isLoading: false,
        isHost: false,
        connectionStatus: '端口 $port 被占用',
      );
    } else {
      // 其他类型的错误，使用通用错误处理
      ErrorHandler.handle(Exception(error), StackTrace.current,
          prefix: 'LAN服务器启动失败');

      state = state.copyWith(
        isLoading: false,
        isHost: false,
        connectionStatus: '启动失败',
      );
    }
  }

  /// 检查是否为端口占用相关的错误
  bool _isPortOccupiedError(String error) {
    final errorLower = error.toLowerCase();
    return errorLower.contains('端口') && errorLower.contains('占用') ||
        errorLower.contains('errno = 10048') ||
        errorLower.contains('address already in use') ||
        errorLower.contains('bind failed') ||
        errorLower.contains('套接字地址') && errorLower.contains('只允许使用一次');
  }

  /// 修改 startHost 方法以传递回调和模板名称
  Future<void> startHost(int port, String baseTid,
      {String? templateName}) async {
    Log.i('尝试启动主机模式...');
    disposeManager(); // 确保旧的管理器已清理
    state = state.copyWith(isLoading: true, isHost: true, isConnected: false);
    _currentBaseTid = baseTid;
    _currentTemplateName = templateName ?? '';

    // 修复：在启动主机模式前动态获取当前有效的IP地址
    Log.i('动态获取当前IP地址...');
    await _fetchLocalIp();

    // 验证IP地址是否有效
    if (state.localIp == '获取中...' || state.localIp == '获取失败') {
      Log.e('无法启动主机模式：无效的本地IP地址 (${state.localIp})');
      state = state.copyWith(
          isLoading: false, isHost: false, connectionStatus: '启动失败：无法获取有效IP地址');
      GlobalMsgManager.showError('启动失败：无法获取有效的本地IP地址，请检查网络连接');
      return;
    }

    // 获取当前配置的服务端口
    Log.i('获取当前配置的服务端口...');
    final configuredPort = await PortManager.getCurrentWebSocketPort();
    _currentWsPort = configuredPort;
    Log.i('将使用服务端口: $configuredPort');

    // 检查端口是否被占用
    if (await PortManager.isTcpPortOccupied(configuredPort)) {
      Log.e('服务端口 $configuredPort 被占用');
      GlobalMsgManager.showError(PortManager.getPortOccupiedErrorMessage(
          configuredPort,
          isWebSocket: true));
      state = state.copyWith(
        isLoading: false,
        isHost: false,
        connectionStatus: '端口 $configuredPort 被占用',
      );
      return;
    }

    try {
      // 获取当前配置的广播端口
      final configuredDiscoveryPort =
          await PortManager.getCurrentDiscoveryPort();

      final manager = await ScoreNetworkManager.createHost(
        configuredPort,
        onMessageReceived: _handleClientMessage,
        // 处理客户端消息的回调
        onClientConnected: _handleClientConnected,
        // 新增：传递连接回调
        onClientDisconnected: _handleClientDisconnected,
        // 新增：传递断开回调
        onServerError: _handleServerError,
        // 新增：服务器错误回调
        onStartupError: _handleStartupError, // 新增：启动失败回调
      );
      state = state.copyWith(
        isLoading: false,
        networkManager: manager,
        connectionStatus: '等待连接...',
        // 初始状态
        connectedClientIps: [],
        // 清空客户端列表
        isBroadcasting: true,
        // 主机启动时默认开启广播
        serverPort: configuredPort,
        // 新增：设置服务器端口
        discoveryPort: configuredDiscoveryPort, // 新增：设置广播端口
      );
      await _startDiscoveryBroadcast(configuredPort, baseTid);

      Log.i('主机模式已成功启动在端口 $configuredPort');
    } catch (e) {
      Log.e('启动主机失败: $e');

      // 检查是否为端口占用错误
      if (_isPortOccupiedError(e.toString())) {
        GlobalMsgManager.showError(PortManager.getPortOccupiedErrorMessage(
            configuredPort,
            isWebSocket: true));
        state = state.copyWith(
            isLoading: false, isHost: false, connectionStatus: '端口 $port 被占用');
      } else {
        // 其他类型的错误，使用通用处理
        ErrorHandler.handle(e, StackTrace.current, prefix: '启动主机失败');
        state = state.copyWith(
            isLoading: false, isHost: false, connectionStatus: '启动失败');
      }
    }
  }

  /// 处理客户端发送的消息 (例如 request_sync_state)
  void _handleClientMessage(WebSocket client, String message) {
    Log.d('主机收到客户端消息: $message');
    try {
      final jsonMap = jsonDecode(message) as Map<String, dynamic>;
      final receivedMessage = SyncMessage.fromJson(jsonMap);

      switch (receivedMessage.type) {
        case "request_sync_state":
          final requestedTemplateId =
              receivedMessage.data?['templateId'] as String?;
          Log.i('客户端请求同步状态，请求的模板ID: $requestedTemplateId');

          if (requestedTemplateId == null) {
            Log.w('客户端请求同步状态，但未提供 templateId');
            return; // 或者发送错误消息给客户端？
          }

          // 1. 发送模板信息 (template_info)
          final template = ref
              .read(templatesProvider.notifier)
              .getTemplate(requestedTemplateId);
          if (template != null) {
            // 注意：我们需要将 BaseTemplate 转换回 Map<String, dynamic>
            // 修复：确保包含完整的玩家信息
            try {
              // 获取模板的基础数据
              final templateData = template.toMap();

              // 修复：确保玩家信息被正确包含
              templateData['players'] =
                  template.players.map((player) => player.toJson()).toList();

              Log.i(
                  '发送模板信息，包含 ${template.players.length} 个玩家: ${template.players.map((p) => p.name).join(", ")}');

              final templateMessage =
                  SyncMessage(type: "template_info", data: templateData);
              final templateJsonString = jsonEncode(templateMessage.toJson());
              state.networkManager?.sendToClient(client, templateJsonString);
              Log.i('已发送 template_info 给客户端，玩家数量: ${template.players.length}');
            } catch (e) {
              // 使用统一的错误处理器
              ErrorHandler.handle(e, StackTrace.current,
                  prefix: '序列化或发送template_info失败');
              // 即使模板发送失败，也尝试发送状态
            }
          } else {
            Log.w('未找到请求的模板 $requestedTemplateId，无法发送 template_info');
            // 即使找不到模板，仍然尝试发送状态，客户端可能需要处理这种情况
          }

          // 2. 发送会话状态 (sync_state) - 保持原有逻辑
          final currentScoreState = ref.read(scoreProvider).value;
          if (currentScoreState != null &&
              currentScoreState.currentSession != null) {
            // 确保 session 的 templateId 与请求的一致，或者根据情况处理
            if (currentScoreState.currentSession!.templateId ==
                requestedTemplateId) {
              final syncPayload =
                  SyncStatePayload(session: currentScoreState.currentSession!);
              final syncMessage =
                  SyncMessage(type: "sync_state", data: syncPayload.toJson());
              final jsonString = jsonEncode(syncMessage.toJson());
              state.networkManager?.sendToClient(client, jsonString);
              Log.i('已发送 sync_state 给客户端');
            } else {
              Log.w(
                  '当前会话的模板ID (${currentScoreState.currentSession!.templateId}) 与客户端请求的 ($requestedTemplateId) 不匹配，未发送 sync_state');
              // 这里可能需要更复杂的逻辑，比如是否强制同步或者发送错误
            }
          } else {
            Log.w('无法获取当前分数状态以发送 sync_state');
          }
          break;

        case "ping":
          // 主机收到客户端ping，发送pong响应
          if (receivedMessage.data is Map<String, dynamic>) {
            final pingMessage = PingMessage.fromJson(
                receivedMessage.data as Map<String, dynamic>);
            final pongMessage = PingMessage(
              type: 'pong',
              timestamp: DateTime.now().millisecondsSinceEpoch,
              id: pingMessage.id,
            );
            // 包装在SyncMessage中发送
            final syncMessage =
                SyncMessage(type: 'pong', data: pongMessage.toJson());
            state.networkManager
                ?.sendToClient(client, jsonEncode(syncMessage.toJson()));
            Log.v('主机响应客户端ping: ${pingMessage.id}');
          }
          break;

        case "pong":
          // 主机收到客户端pong响应
          if (receivedMessage.data is Map<String, dynamic>) {
            ref.read(pingProvider.notifier).handlePingResponse(
                receivedMessage.data as Map<String, dynamic>);
          }
          break;

        default:
          Log.d('主机收到客户端未知消息类型: ${receivedMessage.type}');
          break;
      }
    } catch (e) {
      // 使用统一的错误处理器
      ErrorHandler.handle(e, StackTrace.current, prefix: '处理客户端消息时出错');
    }
  }

  /// 连接到一个指定 IP 地址和端口的 WebSocket 主机。
  Future<void> connectToHost(String hostIp, int port,
      {int? discoveryPort}) async {
    await disposeManager();
    state = state.copyWith(
      isLoading: true,
      isHost: false,
      isConnected: false,
      isClientMode: true,
      // 设置为客户端模式
      isConnecting: true,
      // 修复：设置连接建立中状态，防止误导性警告
      hostIp: hostIp,
      // 记录主机IP用于重连
      serverPort: port,
      // 记录主机端口用于重连和显示
      discoveryPort: discoveryPort ?? 8099,
      // 记录主机广播端口用于显示
      connectionStatus: '连接中...',
      clearDisconnectReason: true,
      // 清除之前的断开原因
      reconnectAttempts: 0,
      // 重置重连次数
      isReconnecting: false,
    );
    try {
      // === 修复点 2：使用 ScoreNetworkManager.createClient 静态方法创建管理器 ===
      final manager = await ScoreNetworkManager.createClient(
        hostIp,
        port,
        onMessageReceived: _handleMessageReceived,
        onConnectionChanged: _handleConnectionChanged,
      );

      state = state.copyWith(
        isLoading: false,
        networkManager: manager,
        receivedMessages: [],
        isConnecting: false, // 修复：清除连接建立中状态
      );

      // Client 连接成功后，确保 ScoreNotifier 知道当前处于客户端模式
      // 由于 ScoreNotifier 会通过 ref.read(lanProvider) 检查状态，
      // 我们只需要确保状态正确设置即可
      Log.i('客户端连接成功，当前处于客户端模式，ScoreNotifier 将自动识别并限制操作权限');
    } catch (e) {
      // 使用统一的错误处理器
      ErrorHandler.handle(e, StackTrace.current, prefix: '连接主机失败');
      _handleConnectionChanged(false, '连接主机失败: $e'); // 确保状态更新
      state = state.copyWith(
        isLoading: false,
        isConnecting: false, // 修复：确保清除连接建立中状态
      );
    }
  }

  /// 从DiscoveredHost连接到主机
  Future<void> connectToDiscoveredHost(DiscoveredHost host) async {
    await connectToHost(host.ip, host.port, discoveryPort: host.discoveryPort);
  }

  /// 发送 JSON 格式的消息。
  void sendJsonMessage(String jsonString) {
    ScoreNetworkManager? manager = state.networkManager;

    if (state.isHost) {
      // 主机模式，广播消息给所有客户端
      if (manager != null && manager.isHost) {
        manager.broadcast(jsonString);
        Log.i('主机广播消息: $jsonString');
      } else {
        Log.w('无法广播 JSON 消息：主机管理器未初始化');
      }
    } else if (state.isConnected) {
      // 客户端模式，发送消息给主机
      if (manager != null && !manager.isHost) {
        manager.sendMessage(jsonString);
        Log.i('客户端发送消息: $jsonString');
      } else {
        Log.w('无法发送 JSON 消息：客户端管理器未初始化或已断开');
      }
    } else {
      Log.w('无法发送 JSON 消息：未连接');
      GlobalMsgManager.showMessage("无法发送消息：未连接");
    }
  }

  /// 广播消息给所有连接的客户端 (仅 Host 模式可用)
  void broadcastMessage(String jsonString) {
    ScoreNetworkManager? manager = state.networkManager;

    if (manager == null) {
      Log.w('尝试广播消息，但网络管理器未初始化');
      return;
    }

    if (!state.isHost) {
      Log.w('广播消息仅在主机模式下可用');
      return;
    }

    try {
      manager.broadcast(jsonString);
      Log.i('广播 JSON 消息: $jsonString');
    } catch (e) {
      // 使用统一的错误处理器
      ErrorHandler.handle(e, StackTrace.current, prefix: '广播JSON消息失败');
    }
  }

  /// 通过当前活动的网络连接发送消息 (用于 LogTestPage 的按钮)。
  void sendMessage() {
    final message = _messageController.text;
    if (message.isNotEmpty) {
      final testMessage = SyncMessage(
        type: "test_message",
        data: {
          'text': message,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      final jsonString = jsonEncode(testMessage.toJson());

      sendJsonMessage(jsonString);

      final currentMessages = List<String>.from(state.receivedMessages);
      currentMessages.insert(0, "发送: $message");
      if (currentMessages.length > 100) {
        currentMessages.removeRange(100, currentMessages.length);
      }
      state = state.copyWith(receivedMessages: currentMessages);

      _messageController.clear();
    } else {
      Log.w("发送空消息");
    }
  }

  /// 手动重连到主机
  Future<void> manualReconnect() async {
    if (!state.isClientMode || state.hostIp == null) {
      GlobalMsgManager.showWarn('无法重连：不在客户端模式或缺少主机信息');
      return;
    }

    if (state.isConnected) {
      GlobalMsgManager.showMessage('当前已连接，无需重连');
      return;
    }

    Log.i('开始手动重连到主机: ${state.hostIp}');
    GlobalMsgManager.showMessage('正在尝试重连...');

    // 如果有现有的网络管理器，先清理
    if (state.networkManager != null) {
      await state.networkManager?.dispose();
      state = state.copyWith(clearNetworkManager: true);
    }

    // 修复：手动重连时递增重连计数器
    final newAttempts = state.reconnectAttempts + 1;
    state = state.copyWith(
      isConnecting: true, // 修复：设置连接建立中状态
      isReconnecting: true,
      reconnectAttempts: newAttempts,
      connectionStatus: '正在重连... ($newAttempts/${state.maxReconnectAttempts})',
    );

    // 尝试重连
    try {
      final manager = await ScoreNetworkManager.createClient(
        state.hostIp!,
        state.serverPort > 0 ? state.serverPort : 8080, // 使用记录的端口或默认端口
        onMessageReceived: _handleMessageReceived,
        onConnectionChanged: _handleConnectionChanged,
      );

      state = state.copyWith(
        networkManager: manager,
        clearDisconnectReason: true,
        isConnecting: false, // 修复：清除连接建立中状态
      );
    } catch (e) {
      // 使用统一的错误处理器
      ErrorHandler.handle(e, StackTrace.current, prefix: '手动重连失败');
      state = state.copyWith(
        isConnecting: false, // 修复：确保清除连接建立中状态
      );
    }
  }

  /// 退出客户端模式
  Future<void> exitClientMode() async {
    Log.i('退出客户端模式');

    // 清理网络连接
    await disposeManager();

    // 清理客户端模式数据
    ref.read(scoreProvider.notifier).clearClientModeData();
    ref.read(templatesProvider.notifier).clearClientModeTemplates();

    state = state.copyWith(
      isClientMode: false,
      isConnecting: false,
      // 修复：清除连接建立中状态
      isReconnecting: false,
      reconnectAttempts: 0,
      clearDisconnectReason: true,
      clearHostIp: true,
      connectionStatus: '未连接',
    );

    GlobalMsgManager.showMessage('已退出客户端模式');
  }

  /// 清理并释放所有网络资源。
  Future<void> disposeManager() async {
    Log.d('Disposing network manager...');
    _stopDiscoveryBroadcast();

    // 如果是主机模式且有连接的客户端，发送断开通知
    if (state.isHost &&
        state.connectedClientIps.isNotEmpty &&
        state.networkManager != null) {
      Log.i('主机断开连接，向 ${state.connectedClientIps.length} 个客户端发送断开通知');
      try {
        final disconnectMessage = SyncMessage(
          type: "host_disconnect",
          data: HostDisconnectPayload(reason: "主机主动断开连接").toJson(),
        );
        final jsonString = jsonEncode(disconnectMessage.toJson());
        state.networkManager!.broadcast(jsonString);

        // 给客户端一点时间接收消息
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        // 使用统一的错误处理器
        ErrorHandler.handle(e, StackTrace.current, prefix: '发送主机断开通知失败');
      }
    }

    // 修复：如果是客户端模式，清理临时数据（但不退出客户端模式）
    final wasClientModeConnected = state.isConnected && !state.isHost;
    if (wasClientModeConnected) {
      Log.i('客户端断开连接，清理临时数据');
      ref.read(scoreProvider.notifier).clearClientModeData();
      // 同时清理模板中的临时数据
      ref.read(templatesProvider.notifier).clearClientModeTemplates();
    }

    Log.d("正在处理网络管理器...");
    // 释放网络管理器
    if (state.networkManager != null) {
      await state.networkManager?.dispose();
    }

    Log.d("网络管理器处理完毕。");
    // 保存当前状态用于判断
    final wasClientMode = state.isClientMode;
    final wasHost = state.isHost;

    state = state.copyWith(
      clearNetworkManager: true,
      isConnected: false,
      isHost: false,
      connectionStatus: wasClientMode ? '客户端模式（已断开连接）' : '未连接',
      receivedMessages: [],
      serverPort: wasHost ? 0 : state.serverPort,
      // 主机模式重置端口，客户端模式保留端口用于重连
      connectedClientIps: [], // 清空客户端列表
    );
  }

  void clearMessages() {
    state = state.copyWith(receivedMessages: []);
  }

  Future<void> _startDiscoveryBroadcast(int wsPort, String baseTid) async {
    await _stopDiscoveryBroadcast();

    // 修复：添加重试机制，最多重试3次
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        // 修复：每次重试前重新获取IP地址
        if (retryCount > 0) {
          Log.i('第 ${retryCount + 1} 次尝试启动UDP广播，重新获取IP地址...');
          await _fetchLocalIp();
          // 给网络接口一点时间稳定
          await Future.delayed(const Duration(milliseconds: 500));
        }

        if (state.localIp == '获取中...' || state.localIp == '获取失败') {
          Log.e('无法启动 UDP 广播：无效的本地 IP 地址 (${state.localIp})');
          retryCount++;
          if (retryCount >= maxRetries) {
            await _stopDiscoveryBroadcast();
            return;
          }
          continue;
        }

        // 修复：验证IP地址格式是否有效
        if (!_isValidIpAddress(state.localIp)) {
          Log.e('无法启动 UDP 广播：IP地址格式无效 (${state.localIp})');
          retryCount++;
          if (retryCount >= maxRetries) {
            await _stopDiscoveryBroadcast();
            return;
          }
          continue;
        }

        final localBindAddress = InternetAddress(state.localIp);
        Log.i('尝试将 UDP 广播 Socket 绑定到: ${localBindAddress.address}');
        _udpSocket = await RawDatagramSocket.bind(localBindAddress, 0);
        _udpSocket?.broadcastEnabled = true;
        Log.i('UDP 广播 Socket 绑定成功，准备发送发现信息...');

        _broadcastTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
          if (state.isBroadcasting) {
            // 只在广播开启时发送
            _sendDiscoveryBroadcast();
          }
        });

        if (state.isBroadcasting) {
          // 立即发送一次
          _sendDiscoveryBroadcast();
        }

        // 成功启动，退出重试循环
        break;
      } catch (e) {
        retryCount++;
        Log.w('第 $retryCount 次启动UDP广播失败: $e');

        if (retryCount >= maxRetries) {
          // 使用统一的错误处理器
          ErrorHandler.handle(e, StackTrace.current, prefix: '启动UDP广播失败');
          await _stopDiscoveryBroadcast();
          return;
        }

        // 等待一段时间后重试
        await Future.delayed(Duration(milliseconds: 1000 * retryCount));
      }
    }
  }

  // 新增：控制广播开关
  void toggleBroadcast() {
    if (!state.isHost) {
      Log.w('只有主机模式才能控制广播');
      return;
    }

    final newBroadcastingState = !state.isBroadcasting;
    state = state.copyWith(isBroadcasting: newBroadcastingState);

    if (newBroadcastingState) {
      // 如果开启广播，立即发送一次
      _sendDiscoveryBroadcast();
    }

    Log.i('广播状态已${newBroadcastingState ? "开启" : "关闭"}');
  }

  // 新增：设置广播状态
  void setBroadcastState(bool shouldBroadcast) {
    if (!state.isHost) return;
    if (state.isBroadcasting == shouldBroadcast) return;

    if (shouldBroadcast) {
      _startDiscoveryBroadcast(_currentWsPort, _currentBaseTid);
      state = state.copyWith(isBroadcasting: true);
    } else {
      _stopDiscoveryBroadcast();
      state = state.copyWith(isBroadcasting: false);
    }
  }

  void _sendDiscoveryBroadcast() {
    if (!state.isBroadcasting) {
      Log.d('广播已关闭，跳过发送。');
      return;
    }

    if (_broadcastTimer == null || !_broadcastTimer!.isActive) {
      Log.d('广播计时器已停止或为空，跳过发送。');
      return;
    }

    if (_udpSocket == null) {
      Log.w('无法发送广播：UDP 套接字为空。');
      return;
    }
    if (state.localIp == '获取中...' || state.localIp == '获取失败') {
      Log.w('无法发送广播：本地 IP 无效 (${state.localIp}).');
      return;
    }

    try {
      String hostName = Platform.localHostname;
      // 新格式: Prefix<HostIP>|<WebSocketPort>|<DiscoveryPort>|<BaseTID>|<HostName>|<TemplateName>
      final message =
          '${Config.discoveryMsgPrefix}${state.localIp}|$_currentWsPort|${state.discoveryPort}|$_currentBaseTid|$hostName|$_currentTemplateName';
      final data = utf8.encode(message);

      // 修复：只向当前配置的广播端口发送广播，而不是向整个端口范围发送
      final targetPort = state.discoveryPort;

      // 安全检查：确保端口号有效
      if (targetPort <= 0 || targetPort > 65535) {
        Log.e('无效的广播端口: $targetPort，跳过广播发送');
        return;
      }

      try {
        var send = _udpSocket?.send(
            data, InternetAddress('255.255.255.255'), targetPort);
        if (send != null && send > 0) {
          Log.v('成功向配置的广播端口 $targetPort 发送广播');
        } else {
          Log.w('向配置的广播端口 $targetPort 发送广播失败：发送字节数为 $send');
        }
      } catch (e) {
        Log.e('向配置的广播端口 $targetPort 发送广播失败: $e');
        // 使用统一的错误处理器
        ErrorHandler.handle(e, StackTrace.current, prefix: '发送UDP广播失败');
      }
    } catch (e) {
      // 使用统一的错误处理器
      ErrorHandler.handle(e, StackTrace.current, prefix: '发送UDP广播失败');
    }
  }

  Future<void> _stopDiscoveryBroadcast() async {
    Log.i('正在停止 UDP 广播...');
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
    _udpSocket?.close();
    _udpSocket = null;
    Log.i('UDP 广播已停止');
  }
}
