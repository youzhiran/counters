import 'dart:convert';

import 'package:counters/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 用于剪贴板
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../lan/client.dart'; // 需要 getLocalIp
import '../manager/network_manager.dart';
import '../utils/log.dart';

// 定义一个 Provider 来管理网络状态 (可选，但推荐)
final lanTestProvider =
    StateNotifierProvider<LanTestNotifier, LanTestState>((ref) {
  return LanTestNotifier();
});

// 状态类
@immutable
class LanTestState {
  final bool isLoading;
  final bool isHost; // true: 主要角色是主机
  final bool isConnected; // 活动连接（通常是客户端）是否已连接
  final String localIp;
  final String connectionStatus;
  final List<String> receivedMessages;
  final ScoreNetworkManager? networkManager; // 主管理器 (主机或客户端)
  final ScoreNetworkManager? clientNetworkManager; // 仅在 HostAndClient 模式下使用的客户端管理器
  final bool isHostAndClientMode; // 是否处于主机&客户端模式

  const LanTestState({
    this.isLoading = false,
    this.isHost = true, // 默认是主机模式选择界面
    this.isConnected = false,
    this.localIp = '获取中...',
    this.connectionStatus = '未连接',
    this.receivedMessages = const [],
    this.networkManager,
    this.clientNetworkManager, // 添加
    this.isHostAndClientMode = false, // 添加
  });

  LanTestState copyWith({
    bool? isLoading,
    bool? isHost,
    bool? isConnected,
    String? localIp,
    String? connectionStatus,
    List<String>? receivedMessages,
    ScoreNetworkManager? networkManager,
    ScoreNetworkManager? clientNetworkManager, // 添加
    bool? isHostAndClientMode, // 添加
    bool clearNetworkManager = false,
    bool clearClientNetworkManager = false, // 添加
  }) {
    return LanTestState(
      isLoading: isLoading ?? this.isLoading,
      isHost: isHost ?? this.isHost,
      isConnected: isConnected ?? this.isConnected,
      localIp: localIp ?? this.localIp,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      receivedMessages: receivedMessages ?? this.receivedMessages,
      networkManager:
          clearNetworkManager ? null : networkManager ?? this.networkManager,
      // 添加 clientNetworkManager 的处理逻辑
      clientNetworkManager: clearClientNetworkManager
          ? null
          : clientNetworkManager ?? this.clientNetworkManager,
      isHostAndClientMode: isHostAndClientMode ?? this.isHostAndClientMode, // 添加
    );
  }
}

// StateNotifier 类
class LanTestNotifier extends StateNotifier<LanTestState> {
  LanTestNotifier() : super(const LanTestState()) {
    _fetchLocalIp();
  }

  final TextEditingController hostIpController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  Future<void> _fetchLocalIp() async {
    final ip = await getLocalIp();
    if (mounted) {
      state = state.copyWith(localIp: ip ?? '获取失败');
    }
  }

  // --- 消息和连接状态的通用回调处理 ---
  void _handleMessageReceived(String message) {
    if (mounted) {
      final currentMessages = List<String>.from(state.receivedMessages);
      // 解析 JSON 消息以获取原始文本 (如果适用)
      try {
        final decoded = jsonDecode(message);
        if (decoded is Map && decoded.containsKey('text')) {
           currentMessages.insert(0, "收到: ${decoded['text']}");
        } else {
           currentMessages.insert(0, "收到: $message");
        }
      } catch (_) {
         currentMessages.insert(0, "收到: $message"); // 非 JSON 或格式错误，显示原始消息
      }
      state = state.copyWith(receivedMessages: currentMessages);
    }
  }

  void _handleConnectionChanged(bool isConnected, String statusMessage) {
     if (mounted) {
       state = state.copyWith(
           isConnected: isConnected, connectionStatus: statusMessage);
       // 如果是 HostAndClient 模式下客户端断开连接，可能需要重置模式？(可选)
       // if (state.isHostAndClientMode && !isConnected) {
       //   disposeManager(); // 或者只清理客户端部分
       // }
     }
  }
  // --- 结束通用回调处理 ---


  Future<void> startHost(int port) async {
    await disposeManager(); // 清理所有旧的管理器
    state = state.copyWith(
        isLoading: true, isHost: true, isHostAndClientMode: false, connectionStatus: '启动中...'); // 重置模式
    try {
      final manager = await ScoreNetworkManager.createHost(port);
      state = state.copyWith(
        isLoading: false,
        isConnected: true, // 主机启动即认为 "连接" 成功 (因为它在运行)
        networkManager: manager,
        clientNetworkManager: null, // 确保 client manager 被清除
        connectionStatus: '主机运行中于 ${state.localIp}:$port',
        receivedMessages: [],
      );
      Log.i('主机启动成功');
    } catch (e) {
      Log.e('启动主机失败: $e');
      if (mounted) {
        state = state.copyWith(isLoading: false, isConnected: false, connectionStatus: '启动主机失败: $e');
      }
    }
  }

  Future<void> connectToHost(String hostIp, int port) async {
    await disposeManager(); // 清理所有旧的管理器
    state = state.copyWith(
        isLoading: true, isHost: false, isHostAndClientMode: false, connectionStatus: '连接中...'); // 重置模式
    try {
      // 创建客户端管理器并存储在 networkManager 中
      final manager = await ScoreNetworkManager.createClient(
        hostIp,
        port,
        onMessageReceived: _handleMessageReceived, // 使用通用回调
        onConnectionChanged: _handleConnectionChanged, // 使用通用回调
      );
      // 连接状态由回调处理，这里只设置管理器
      Log.i('客户端实例创建，等待连接状态...');
      state = state.copyWith(
          isLoading: false,
          networkManager: manager,
          clientNetworkManager: null, // 确保 client manager 被清除
          receivedMessages: []);
    } catch (e) {
      Log.e('连接主机失败: $e');
      if (mounted) {
        // 确保回调被调用以更新状态，或者在这里直接更新
        _handleConnectionChanged(false, '连接主机失败: $e');
        state = state.copyWith(isLoading: false); // 移除加载状态
      }
    }
  }

  // --- 新增: 启动主机和客户端 ---
  Future<void> startHostAndClient(int port) async {
    await disposeManager(); // 清理所有旧的管理器
    state = state.copyWith(
        isLoading: true, isHost: true, isHostAndClientMode: true, connectionStatus: '启动主机和客户端...'); // 设置模式

    ScoreNetworkManager? hostManager;
    ScoreNetworkManager? clientManager;

    try {
      // 1. 启动主机
      hostManager = await ScoreNetworkManager.createHost(port);
      Log.i('主机部分启动成功');
      // 更新部分状态，显示主机已运行
      state = state.copyWith(
          networkManager: hostManager,
          connectionStatus: '主机运行中于 ${state.localIp}:$port, 正在连接客户端...');

      // 2. 连接到本机主机 (使用 127.0.0.1 避免依赖 getLocalIp 的结果)
      clientManager = await ScoreNetworkManager.createClient(
        '127.0.0.1', // 连接到本地回环地址
        port,
        onMessageReceived: _handleMessageReceived, // 使用通用回调
        onConnectionChanged: _handleConnectionChanged, // 使用通用回调
      );
      Log.i('客户端部分实例创建，等待连接状态...');
      // 客户端连接状态将由 _handleConnectionChanged 更新
      // 最终状态更新由回调完成，这里只需设置管理器和模式
      state = state.copyWith(
        isLoading: false, // 移除加载状态
        clientNetworkManager: clientManager,
        // isConnected 和 connectionStatus 由回调更新
        receivedMessages: [], // 清空消息
      );

    } catch (e) {
      Log.e('启动主机和客户端失败: $e');
      // 如果出错，清理可能已创建的管理器
      await hostManager?.dispose();
      await clientManager?.dispose();
      if (mounted) {
        state = state.copyWith(
            isLoading: false,
            isConnected: false,
            isHostAndClientMode: false, // 失败则退出此模式
            networkManager: null,
            clientNetworkManager: null,
            connectionStatus: '启动主机&客户端失败: $e');
      }
    }
  }
  // --- 结束新增 ---


  void sendMessage() {
    // 确定使用哪个管理器发送消息
    ScoreNetworkManager? managerToSendVia;
    if (state.isHostAndClientMode) {
      managerToSendVia = state.clientNetworkManager; // 在组合模式下，通过客户端部分发送
    } else {
      managerToSendVia = state.networkManager; // 否则使用主管理器
    }

    if (managerToSendVia != null && state.isConnected) { // 检查 isConnected 确保连接有效
      final message = messageController.text;
      if (message.isNotEmpty) {
        try {
          final messageJson = jsonEncode({
            'type': 'test_message',
            'text': message, // 包含原始文本
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
          managerToSendVia.sendMessage(messageJson);

          // 将自己发送的消息也添加到列表
          final currentMessages = List<String>.from(state.receivedMessages);
          currentMessages.insert(0, "发送: $message");
          state = state.copyWith(receivedMessages: currentMessages);

          messageController.clear();
        } catch (e) {
          Log.e("发送消息失败: $e");
          if (mounted) {
            state = state.copyWith(connectionStatus: '发送失败: $e');
          }
        }
      }
    } else {
      Log.w("无法发送消息：未连接或管理器未初始化");
      // 可以显示提示
      if(mounted) {
         AppSnackBar.show("无法发送消息：未连接");
      }
    }
  }

  Future<void> disposeManager() async {
    // 同时 dispose 两个管理器
    await state.networkManager?.dispose();
    await state.clientNetworkManager?.dispose();
    if (mounted) {
      state = state.copyWith(
          clearNetworkManager: true,
          clearClientNetworkManager: true, // 清理 client manager
          isConnected: false,
          isHostAndClientMode: false, // 退出组合模式
          connectionStatus: '未连接',
          receivedMessages: []);
    }
  }

  // dispose 方法保持不变
  @override
  void dispose() {
    hostIpController.dispose();
    messageController.dispose();
    disposeManager(); // 确保Notifier销毁时清理网络资源
    super.dispose();
  }
}

// UI Widget
class LanTestPage extends ConsumerWidget {
  const LanTestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lanTestProvider);
    final notifier = ref.read(lanTestProvider.notifier);
    const int defaultPort = 8080;

    // --- 更新模式显示文本 ---
    String modeText = '未知';
    if (state.isHostAndClientMode) {
      modeText = '模式: 主机 & 客户端';
    } else if (state.isHost) {
      modeText = '模式: 主机';
    } else {
      modeText = '模式: 客户端';
    }
    // --- 结束更新 ---


    return Scaffold(
      appBar: AppBar(
        title: const Text('局域网通信测试'),
        actions: [
          if (state.isConnected)
            IconButton(
              icon: const Icon(Icons.stop_circle_outlined),
              tooltip: '断开连接/停止主机',
              onPressed: () async {
                await notifier.disposeManager();
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          // 使用 ListView 防止内容溢出
          children: [
            // --- 模式选择和状态显示 ---
            if (!state.isConnected && !state.isHostAndClientMode) ...[ // 调整这里的条件
              Text('你的IP地址: ${state.localIp}',
                  style: Theme.of(context).textTheme.titleMedium),
              if (state.localIp != '获取中...' && state.localIp != '获取失败')
                TextButton.icon(
                  icon: Icon(Icons.copy, size: 16),
                  label: Text('复制IP'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: state.localIp));
                    AppSnackBar.show('IP地址已复制');
                  },
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: state.isLoading
                    ? null
                    : () => notifier.startHost(defaultPort),
                child: const Text('成为主机'),
              ),
              // --- 连接 "成为主机&客户端" 按钮 ---
              ElevatedButton(
                onPressed: state.isLoading
                    ? null
                    : () => notifier.startHostAndClient(defaultPort), // 调用新方法
                child: const Text('成为主机&客户端'),
              ),
              // --- 结束连接 ---
              const SizedBox(height: 10),
              TextField(
                controller: notifier.hostIpController,
                decoration: const InputDecoration(
                  labelText: '输入主机IP地址',
                  hintText: '例如: 192.168.1.100',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: state.isLoading
                    ? null
                    : () {
                        final hostIp = notifier.hostIpController.text.trim();
                        if (hostIp.isNotEmpty) {
                          notifier.connectToHost(hostIp, defaultPort);
                        } else {
                          AppSnackBar.show('请输入主机IP地址');
                        }
                      },
                child: const Text('连接主机'),
              ),
              const SizedBox(height: 20),
            ],

            // --- 连接后的界面 ---
            // 修改条件以包含 isHostAndClientMode
            if (state.isConnected || (state.isHostAndClientMode && state.networkManager != null)) ...[
              Text(modeText, // 使用上面定义的 modeText
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('状态: ${state.connectionStatus}'),
              const SizedBox(height: 20),

              // --- 消息发送区域 (保持不变) ---
              TextField(
                controller: notifier.messageController,
                decoration: const InputDecoration(
                  labelText: '输入消息发送',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => notifier.sendMessage(), // 支持回车发送
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: state.isLoading ? null : notifier.sendMessage,
                child: const Text('发送'),
              ),
              const SizedBox(height: 20),

              // --- 消息接收区域 (保持不变) ---
              Text('消息记录:', style: Theme.of(context).textTheme.titleMedium),
              const Divider(),
              state.receivedMessages.isEmpty
                  ? const Center(child: Text('暂无消息'))
                  : SizedBox(
                      // 限制消息列表高度
                      height: 300, // 可以根据需要调整
                      child: ListView.builder(
                        reverse: true, // 让最新消息显示在顶部
                        itemCount: state.receivedMessages.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(state.receivedMessages[index]),
                            dense: true,
                          );
                        },
                      ),
                    ),
            ],

            // --- 加载指示器 (保持不变) ---
            if (state.isLoading)
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
