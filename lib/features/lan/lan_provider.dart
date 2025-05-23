import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:counters/app/config.dart';
import 'package:counters/common/model/Counter.dart';
import 'package:counters/common/model/base_template.dart';
import 'package:counters/common/model/landlords.dart';
import 'package:counters/common/model/mahjong.dart';
import 'package:counters/common/model/player_info.dart';
import 'package:counters/common/model/poker50.dart';
import 'package:counters/common/model/sync_messages.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/common/widgets/snackbar.dart';
import 'package:counters/features/lan/client.dart';
import 'package:counters/features/lan/network_manager.dart';
// 引入 Score Provider 和 消息 Payload 类
import 'package:counters/features/score/score_provider.dart';
import 'package:counters/features/template/template_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final lanProvider = StateNotifierProvider<LanNotifier, LanState>((ref) {
  return LanNotifier(ref);
});

// 状态类 (保持不变)
@immutable
class LanState {
  final bool isLoading;
  final bool isHost;
  final bool isConnected;
  final String localIp;
  final String connectionStatus;
  final List<String> receivedMessages;
  final ScoreNetworkManager? networkManager; // 主管理器 (主机或客户端)
  final ScoreNetworkManager?
      clientNetworkManager; // 仅在 HostAndClient 模式下使用的客户端管理器
  final bool isHostAndClientMode;
  final bool isBroadcasting; // 新增：是否正在广播
  final List<String> connectedClientIps; // 新增：存储已连接客户端 IP

  const LanState({
    this.isLoading = false,
    this.isHost = false,
    this.isConnected = false,
    this.localIp = '获取中...',
    this.connectionStatus = '未连接',
    this.receivedMessages = const [],
    this.networkManager,
    this.clientNetworkManager,
    this.isHostAndClientMode = false,
    this.isBroadcasting = false, // 新增：默认不广播
    this.connectedClientIps = const [], // 新增：默认空列表
  });

  LanState copyWith({
    bool? isLoading,
    bool? isHost,
    bool? isConnected,
    String? localIp,
    String? connectionStatus,
    List<String>? receivedMessages,
    ScoreNetworkManager? networkManager,
    ScoreNetworkManager? clientNetworkManager,
    bool? isHostAndClientMode,
    bool? isBroadcasting, // 新增
    List<String>? connectedClientIps, // 新增
    bool clearNetworkManager = false,
    bool clearClientNetworkManager = false,
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
      clientNetworkManager: clearClientNetworkManager
          ? null
          : clientNetworkManager ?? this.clientNetworkManager,
      isHostAndClientMode: isHostAndClientMode ?? this.isHostAndClientMode,
      isBroadcasting: isBroadcasting ?? this.isBroadcasting, // 新增
      connectedClientIps: connectedClientIps ?? this.connectedClientIps, // 新增
    );
  }
}

class LanNotifier extends StateNotifier<LanState> {
  final Ref _ref;

  LanNotifier(this._ref) : super(const LanState()) {
    _fetchLocalIp();
  }

  final TextEditingController hostIpController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  RawDatagramSocket? _udpSocket;
  Timer? _broadcastTimer;
  String _currentBaseTid = '';
  int _currentWsPort = 0;

  @override
  void dispose() {
    hostIpController.dispose();
    messageController.dispose();
    disposeManager();
    Log.d('LanNotifier dispose');
    super.dispose();
  }

  Future<void> _fetchLocalIp() async {
    if (!mounted) return;
    state = state.copyWith(localIp: '获取中...');
    try {
      final ip = await getWlanIp();
      if (mounted) {
        state = state.copyWith(localIp: ip ?? '获取失败');
      }
    } catch (e) {
      Log.e('获取本地 IP 失败: $e');
      if (mounted) {
        state = state.copyWith(localIp: '获取失败');
      }
    }
  }

  Future<void> refreshLocalIp() async {
    Log.i("手动刷新本地 IP 地址...");
    await _fetchLocalIp();
  }

  void _handleMessageReceived(String rawMessage) async {
    Log.d('收到原始网络消息: $rawMessage');
    if (mounted) {
      final currentMessages = List<String>.from(state.receivedMessages);
      currentMessages.insert(0, "原始: $rawMessage");
      if (currentMessages.length > 100) {
        currentMessages.removeRange(100, currentMessages.length);
      }
      state = state.copyWith(receivedMessages: currentMessages);
    }

    try {
      final jsonMap = jsonDecode(rawMessage) as Map<String, dynamic>;
      final receivedMessage = SyncMessage.fromJson(jsonMap);
      final type = receivedMessage.type;
      final data = receivedMessage.data;

      Log.i('收到解析后消息: $type');

      if (!state.isHost || state.isHostAndClientMode) {
        switch (type) {
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
              final scoreStateValue = _ref.read(scoreProvider).value;
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

              BaseTemplate? template;
              if (templateType == 'landlords') {
                template = LandlordsTemplate.fromMap(templateMap, players);
              } else if (templateType == 'poker50') {
                template = Poker50Template.fromMap(templateMap, players);
              } else if (templateType == 'mahjong') {
                template = MahjongTemplate.fromMap(templateMap, players);
              } else if (templateType == 'counter') {
                template = CounterTemplate.fromMap(templateMap, players);
              } else {
                Log.e('未知的模板类型: $templateType');
                break;
              }

              // 使用 templatesProvider.notifier 的新方法来保存或更新模板
              final templatesNotifier = _ref.read(templatesProvider.notifier);
              await templatesNotifier.saveOrUpdateNetworkTemplate(template);
              Log.i("同步网络模板到本地：${template.tid}");

              // 等待模板同步完成 (可以适当缩短或移除?)
              await Future.delayed(const Duration(milliseconds: 200));
            } catch (e, stack) {
              Log.e("解析 template_info 失败: $e");
              Log.e("Stack: $stack");
            }
            break;

          case "sync_state":
            if (data is Map<String, dynamic>) {
              final payload = SyncStatePayload.fromJson(data);
              Log.i('收到全量同步状态');
              _ref.read(scoreProvider.notifier).applySyncState(payload.session);
            } else {
              Log.w('收到无效的 sync_state 消息负载类型: ${data.runtimeType}');
            }
            break;

          case "update_score":
            if (data is Map<String, dynamic>) {
              final payload = UpdateScorePayload.fromJson(data);
              Log.i(
                  '收到单点分数更新: Player ${payload.playerId}, Round ${payload.roundIndex}, Score ${payload.score}');
              _ref.read(scoreProvider.notifier).applyUpdateScore(
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
                _ref.read(scoreProvider.notifier).applyRoundData(sessionId,
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
              _ref
                  .read(scoreProvider.notifier)
                  .applyNewRound(payload.newRoundIndex);
            } else {
              Log.w('收到无效的 new_round 消息负载类型: ${data.runtimeType}');
            }
            break;

          case "reset_game":
            Log.i('收到游戏重置通知');
            _ref.read(scoreProvider.notifier).applyResetGame();
            break;

          case "game_end":
            Log.i('收到游戏结束通知');
            _ref.read(scoreProvider.notifier).applyGameEnd();
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
                _ref.read(scoreProvider.notifier).applyPlayerInfo(players);
              } catch (e) {
                Log.e("解析 player_info 列表失败: $e");
              }
            } else {
              Log.w('收到无效的 player_info 消息负载类型: ${data.runtimeType}');
            }
            break;

          default:
            Log.w('收到未知消息类型: $type');
            break;
        }
      } else {
        Log.d('主机收到来自客户端的消息 (未处理为命令): $type');
      }
    } catch (e) {
      Log.e('解析或处理网络消息失败: $e. 原始消息: $rawMessage');
      if (mounted) {
        final currentMessages = List<String>.from(state.receivedMessages);
        currentMessages.insert(0, "解析失败: $e");
        if (currentMessages.length > 100) {
          currentMessages.removeRange(100, currentMessages.length);
        }
        state = state.copyWith(receivedMessages: currentMessages);
      }
    }
  }

  void _handleConnectionChanged(bool isConnected, String statusMessage) {
    Log.i(
        '_handleConnectionChanged: $statusMessage (isConnected: $isConnected)');
    if (mounted) {
      state = state.copyWith(
          isConnected: isConnected, connectionStatus: statusMessage);
    }
  }

  // 修改：处理客户端连接的回调 - 仅更新状态，不主动发送消息
  void _handleClientConnected(WebSocket client, String clientIp) {
    if (!mounted) return;
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
    if (!mounted) return;
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

  /// 修改 startHost 方法以传递回调
  Future<void> startHost(int port, String baseTid) async {
    Log.i('尝试启动主机模式...');
    disposeManager(); // 确保旧的管理器已清理
    if (!mounted) return;
    state = state.copyWith(isLoading: true, isHost: true, isConnected: false);
    _currentBaseTid = baseTid;
    _currentWsPort = port;
    try {
      final manager = await ScoreNetworkManager.createHost(
        port,
        onMessageReceived: _handleClientMessage, // 处理客户端消息的回调
        onClientConnected: _handleClientConnected, // 新增：传递连接回调
        onClientDisconnected: _handleClientDisconnected, // 新增：传递断开回调
      );
      if (!mounted) {
        await manager.dispose(); // 如果页面已卸载，清理新创建的管理器
        return;
      }
      state = state.copyWith(
        isLoading: false,
        networkManager: manager,
        connectionStatus: '等待连接...',
        // 初始状态
        connectedClientIps: [],
        // 清空客户端列表
        isBroadcasting: true, // 主机启动时默认开启广播
      );
      await _startDiscoveryBroadcast(port, baseTid);
      Log.i('主机模式已成功启动在端口 $port');
    } catch (e) {
      Log.e('启动主机失败: $e');
      if (mounted) {
        state = state.copyWith(
            isLoading: false, isHost: false, connectionStatus: '启动失败: $e');
      }
    }
  }

  /// 处理客户端发送的消息 (例如 request_sync_state)
  void _handleClientMessage(WebSocket client, String message) {
    if (!mounted) return;
    Log.d('主机收到客户端消息: $message');
    try {
      final jsonMap = jsonDecode(message) as Map<String, dynamic>;
      final receivedMessage = SyncMessage.fromJson(jsonMap);

      if (receivedMessage.type == "request_sync_state") {
        final requestedTemplateId =
            receivedMessage.data?['templateId'] as String?;
        Log.i('客户端请求同步状态，请求的模板ID: $requestedTemplateId');

        if (requestedTemplateId == null) {
          Log.w('客户端请求同步状态，但未提供 templateId');
          return; // 或者发送错误消息给客户端？
        }

        // 1. 发送模板信息 (template_info)
        final template = _ref
            .read(templatesProvider.notifier)
            .getTemplate(requestedTemplateId);
        if (template != null) {
          // 注意：我们需要将 BaseTemplate 转换回 Map<String, dynamic>
          // 假设 BaseTemplate 有 toJson 或 toMapWithPlayers 方法
          try {
            // BaseTemplate 需要一个方法来序列化自己和玩家列表
            // 假设有一个 toMap() 方法可以做到这一点
            final templateData = template.toMap();
            final templateMessage =
                SyncMessage(type: "template_info", data: templateData);
            final templateJsonString = jsonEncode(templateMessage.toJson());
            state.networkManager?.sendToClient(client, templateJsonString);
            Log.i('已发送 template_info 给客户端');
          } catch (e) {
            Log.e('序列化或发送 template_info 失败: $e');
            // 即使模板发送失败，也尝试发送状态
          }
        } else {
          Log.w('未找到请求的模板 $requestedTemplateId，无法发送 template_info');
          // 即使找不到模板，仍然尝试发送状态，客户端可能需要处理这种情况
        }

        // 2. 发送会话状态 (sync_state) - 保持原有逻辑
        final currentScoreState = _ref.read(scoreProvider).value;
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
      }
      // 可以添加对其他客户端消息类型的处理
    } catch (e) {
      Log.e('处理客户端消息时出错: $e');
    }
  }

  /// 连接到一个指定 IP 地址和端口的 WebSocket 主机。
  Future<void> connectToHost(String hostIp, int port) async {
    await disposeManager();
    state = state.copyWith(
        isLoading: true,
        isHost: false,
        isHostAndClientMode: false,
        isConnected: false,
        connectionStatus: '连接中...');
    try {
      // === 修复点 2：使用 ScoreNetworkManager.createClient 静态方法创建管理器 ===
      final manager = await ScoreNetworkManager.createClient(
        hostIp,
        port,
        onMessageReceived: _handleMessageReceived,
        onConnectionChanged: _handleConnectionChanged,
      );

      if (mounted) {
        state = state.copyWith(
            isLoading: false,
            networkManager: manager,
            clientNetworkManager: null,
            receivedMessages: []);
      }

      // TODO: Client 连接成功后，通知 ScoreNotifier
      // _ref.read(scoreProvider.notifier).setHostMode(false);
      // _ref.read(scoreProvider.notifier).setLanNotifier(this);
    } catch (e) {
      Log.e('连接主机失败: $e');
      if (mounted) {
        _handleConnectionChanged(false, '连接主机失败: $e'); // 确保状态更新
        state = state.copyWith(isLoading: false);
      }
    }
  }

  /// 同时启动主机和客户端模式。
  Future<void> startHostAndClient(int port, String templateId) async {
    Log.i('清理所有旧的网络管理器...');
    await disposeManager();
    state = state.copyWith(
        isLoading: true,
        isHost: true,
        isHostAndClientMode: true,
        isConnected: false,
        connectionStatus: '启动主机和客户端...');

    ScoreNetworkManager? hostManager;
    ScoreNetworkManager? clientManager;

    try {
      // 1. 启动主机部分 (通过管理器静态方法创建)
      // === 修复点 3：使用 ScoreNetworkManager.createHost 静态方法创建并等待 ===
      hostManager = await ScoreNetworkManager.createHost(port);
      _currentBaseTid = templateId;
      _currentWsPort = port;
      Log.i('主机部分启动成功');
      state = state.copyWith(
          networkManager: hostManager, // 存储主机管理器
          connectionStatus:
              '主机运行中于 ${state.localIp}:$_currentWsPort, 正在连接客户端...');
      Log.i('主机运行中于 ${state.localIp}:$_currentWsPort, 正在连接客户端...');
      await _startDiscoveryBroadcast(_currentWsPort, templateId);

      // TODO: Host 启动成功后，通知 ScoreNotifier 准备同步状态

      // 2. 启动客户端部分并连接到本机主机 (通过管理器静态方法创建并等待)
      // === 修复点 4：使用 ScoreNetworkManager.createClient 静态方法创建并等待 ===
      clientManager = await ScoreNetworkManager.createClient(
        '127.0.0.1',
        port,
        onMessageReceived: _handleMessageReceived,
        onConnectionChanged: _handleConnectionChanged,
      );

      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          clientNetworkManager: clientManager, // 存储客户端管理器
          receivedMessages: [],
        );
      }
      // TODO: Client 连接成功后，通知 ScoreNotifier
      // _ref.read(scoreProvider.notifier).setHostMode(true);
      // _ref.read(scoreProvider.notifier).setLanNotifier(this);
    } catch (e) {
      Log.e('启动主机和客户端失败: $e');
      await hostManager?.dispose();
      await clientManager?.dispose();
      if (mounted) {
        state = state.copyWith(
            isLoading: false,
            isConnected: false,
            isHostAndClientMode: false,
            networkManager: null,
            clientNetworkManager: null,
            connectionStatus: '启动主机&客户端失败: $e');
      }
    }
  }

  /// 发送 JSON 格式的消息。
  void sendJsonMessage(String jsonString) {
    ScoreNetworkManager? manager = state.networkManager;

    // === 修复点 5：通过 ScoreNetworkManager 的 broadcast 方法广播 ===
    if (state.isHost && !state.isHostAndClientMode) {
      // 纯主机模式，使用 networkManager
      if (manager != null && manager.isHost) {
        manager.broadcast(jsonString); // 调用 ScoreNetworkManager 的 broadcast 方法
        Log.i('主机广播消息: $jsonString');
      } else {
        Log.w('无法广播 JSON 消息：不在纯主机模式或管理器未初始化');
      }
    } else if (state.isConnected) {
      // 客户端模式 或 HostAndClient 的客户端部分
      ScoreNetworkManager? clientManager = state.isHostAndClientMode
          ? state.clientNetworkManager
          : state.networkManager;

      if (clientManager != null && !clientManager.isHost) {
        // 确保是客户端管理器
        clientManager.sendMessage(
            jsonString); // 调用 ScoreNetworkManager 的 sendMessage (内部调用 WsClient.send)
        Log.i(
            '${state.isHostAndClientMode ? "组合模式客户端" : "纯客户端"} 发送消息: $jsonString');
      } else {
        Log.w('无法发送 JSON 消息：客户端管理器未初始化或已断开');
      }
    } else {
      Log.w('无法发送 JSON 消息：未连接');
      if (mounted) {
        AppSnackBar.show("无法发送消息：未连接");
      }
    }
  }

  /// 广播消息给所有连接的客户端 (仅 Host 模式可用)
  void broadcastMessage(String jsonString) {
    ScoreNetworkManager? manager = state.networkManager;

    if (manager == null) {
      Log.w('尝试广播消息，但网络管理器未初始化');
      return;
    }

    if (!state.isHost || state.isHostAndClientMode) {
      Log.w('广播消息仅在纯主机模式下可用');
      return;
    }

    try {
      manager.broadcast(jsonString);
      Log.i('广播 JSON 消息: $jsonString');
    } catch (e) {
      Log.e('广播 JSON 消息失败: $e');
    }
  }

  /// 通过当前活动的网络连接发送消息 (用于 LanTestPage 的按钮)。
  void sendMessage() {
    final message = messageController.text;
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

      messageController.clear();
    } else {
      Log.w("发送空消息");
    }
  }

  /// 清理并释放所有网络资源。
  Future<void> disposeManager() async {
    Log.d('Disposing network manager...');
    _stopDiscoveryBroadcast();

    Log.d("正在处理网络管理器...");
    // Dispose the Host manager first if it exists
    if (state.networkManager != null && state.networkManager!.isHost) {
      await state.networkManager?.dispose();
    }
    // Dispose the Client manager if it exists (either main or clientNetworkManager)
    if (state.clientNetworkManager != null &&
        !state.clientNetworkManager!.isHost) {
      await state.clientNetworkManager?.dispose();
    } else if (state.networkManager != null && !state.networkManager!.isHost) {
      await state.networkManager?.dispose();
    }

    Log.d("网络管理器处理完毕。");
    if (mounted) {
      state = state.copyWith(
        clearNetworkManager: true,
        clearClientNetworkManager: true,
        isConnected: false,
        isHostAndClientMode: false,
        isHost: false,
        connectionStatus: '未连接',
        receivedMessages: [],
      );
    }
  }

  void clearMessages() {
    if (mounted) {
      state = state.copyWith(receivedMessages: []);
    }
  }

  Future<void> _startDiscoveryBroadcast(int wsPort, String baseTid) async {
    await _stopDiscoveryBroadcast();

    try {
      if (state.localIp == '获取中...' || state.localIp == '获取失败') {
        Log.e('无法启动 UDP 广播：无效的本地 IP 地址 (${state.localIp})');
        await _stopDiscoveryBroadcast();
        return;
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
    } catch (e) {
      Log.e('启动 UDP 广播失败: $e');
      await _stopDiscoveryBroadcast();
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
      if (mounted) {
        state = state.copyWith(isBroadcasting: true);
      }
    } else {
      _stopDiscoveryBroadcast();
      if (mounted) {
        state = state.copyWith(isBroadcasting: false);
      }
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
      final message =
          '${Config.discoveryMsgPrefix}${state.localIp}|$_currentWsPort|$_currentBaseTid|$hostName';
      final data = utf8.encode(message);
      var send = _udpSocket?.send(
          data, InternetAddress('255.255.255.255'), Config.discoveryPort);
      if (send == 0) {
        Log.w('UDP 广播发送结果:$send');
      }
    } catch (e) {
      Log.e('发送 UDP 广播失败: $e');
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
