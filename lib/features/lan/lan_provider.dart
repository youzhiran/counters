import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:counters/app/config.dart';
import 'package:counters/common/model/base_template.dart';
import 'package:counters/common/model/player_info.dart';
import 'package:counters/common/model/sync_messages.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/common/utils/template_utils.dart';
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
  final ScoreNetworkManager? networkManager; // 网络管理器 (主机或客户端)
  final bool isBroadcasting; // 新增：是否正在广播
  final List<String> connectedClientIps; // 新增：存储已连接客户端 IP
  final String interfaceName; // 新增：本机网络接口名称
  final int serverPort; // 新增：服务器端口号

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
      connectedClientIps: connectedClientIps ?? this.connectedClientIps, // 新增
      interfaceName: interfaceName ?? this.interfaceName, // 新增
      serverPort: serverPort ?? this.serverPort, // 新增
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
  String _currentTemplateName = '';

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
    state = state.copyWith(localIp: '获取中...', interfaceName: ''); // 获取中时清空接口名
    try {
      final ipData = await getWlanIp(); // 获取包含IP和接口名称的Map
      if (mounted) {
        state = state.copyWith(
          localIp: ipData?['ip'] ?? '获取失败',
          interfaceName: ipData?['name'] ?? '',
        );
      }
    } catch (e) {
      Log.e('获取本地 IP 失败: $e');
      if (mounted) {
        state = state.copyWith(localIp: '获取失败', interfaceName: '');
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

      if (!state.isHost) {
        switch (type) {
          case "sync_state":
            if (data is Map<String, dynamic>) {
              final payload = SyncStatePayload.fromJson(data);
              Log.i('收到全量同步状态');

              // 修复：在应用同步状态后，检查是否需要补充玩家信息
              _ref.read(scoreProvider.notifier).applySyncState(payload.session);

              // 检查玩家信息是否为空，如果为空则尝试从模板中获取
              final currentState = _ref.read(scoreProvider).valueOrNull;
              if (currentState != null && currentState.players.isEmpty) {
                Log.w('同步状态后玩家信息为空，尝试从模板中获取玩家信息');
                final templatesAsync = _ref.read(templatesProvider);
                final templates = templatesAsync.valueOrNull;
                if (templates != null) {
                  final template = templates.firstWhereOrNull((t) => t.tid == payload.session.templateId);
                  if (template != null && template.players.isNotEmpty) {
                    Log.i('从模板中补充玩家信息: ${template.players.length} 个玩家');
                    _ref.read(scoreProvider.notifier).applyPlayerInfo(template.players);
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
                Log.i("玩家详情: ${players.map((p) => '${p.name}(${p.pid})').join(', ')}");
                _ref.read(scoreProvider.notifier).applyPlayerInfo(players);
              } else {
                Log.w("模板中没有玩家信息，这可能导致后续的同步问题");
              }

              // 使用 templatesProvider.notifier 的新方法来保存或更新模板
              final templatesNotifier = _ref.read(templatesProvider.notifier);
              await templatesNotifier.saveOrUpdateNetworkTemplate(template);
              Log.i("同步网络模板到本地：${template.tid}");
            } catch (e, stack) {
              Log.e("解析 template_info 失败: $e");
              Log.e("Stack: $stack");
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

  /// 修改 startHost 方法以传递回调和模板名称
  Future<void> startHost(int port, String baseTid, {String? templateName}) async {
    Log.i('尝试启动主机模式...');
    disposeManager(); // 确保旧的管理器已清理
    if (!mounted) return;
    state = state.copyWith(isLoading: true, isHost: true, isConnected: false);
    _currentBaseTid = baseTid;
    _currentWsPort = port;
    _currentTemplateName = templateName ?? '';
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
        serverPort: port, // 新增：设置服务器端口
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
          // 修复：确保包含完整的玩家信息
          try {
            // 获取模板的基础数据
            final templateData = template.toMap();

            // 修复：确保玩家信息被正确包含
            templateData['players'] = template.players.map((player) => player.toJson()).toList();

            Log.i('发送模板信息，包含 ${template.players.length} 个玩家: ${template.players.map((p) => p.name).join(", ")}');

            final templateMessage =
                SyncMessage(type: "template_info", data: templateData);
            final templateJsonString = jsonEncode(templateMessage.toJson());
            state.networkManager?.sendToClient(client, templateJsonString);
            Log.i('已发送 template_info 给客户端，玩家数量: ${template.players.length}');
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

    if (!state.isHost) {
      Log.w('广播消息仅在主机模式下可用');
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

    // 修复：如果是客户端模式，清理临时数据
    final wasClientMode = state.isConnected && !state.isHost;
    if (wasClientMode) {
      Log.i('客户端断开连接，清理临时数据');
      _ref.read(scoreProvider.notifier).clearClientModeData();
      // 同时清理模板中的临时数据
      _ref.read(templatesProvider.notifier).clearClientModeTemplates();
    }

    Log.d("正在处理网络管理器...");
    // 释放网络管理器
    if (state.networkManager != null) {
      await state.networkManager?.dispose();
    }

    Log.d("网络管理器处理完毕。");
    if (mounted) {
      state = state.copyWith(
        clearNetworkManager: true,
        isConnected: false,
        isHost: false,
        connectionStatus: '未连接',
        receivedMessages: [],
        serverPort: 0, // 重置端口
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
      // 新格式: Prefix<HostIP>|<WebSocketPort>|<BaseTID>|<HostName>|<TemplateName>
      final message =
          '${Config.discoveryMsgPrefix}${state.localIp}|$_currentWsPort|$_currentBaseTid|$hostName|$_currentTemplateName';
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
