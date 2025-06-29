import 'dart:async';
import 'dart:convert';

import 'package:counters/app/state.dart';
import 'package:counters/common/model/sync_messages.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/common/widgets/ip_display_widget.dart';
import 'package:counters/common/widgets/message_overlay.dart';
import 'package:counters/common/widgets/page_transitions.dart';
import 'package:counters/features/lan/lan_discovery_provider.dart';
import 'package:counters/features/lan/lan_provider.dart';
import 'package:counters/features/score/score_provider.dart';
import 'package:counters/features/template/template_provider.dart';
import 'package:counters/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LanDiscoveryPage extends ConsumerStatefulWidget {
  const LanDiscoveryPage({super.key});

  @override
  ConsumerState<LanDiscoveryPage> createState() => _LanDiscoveryPageState();
}

class _LanDiscoveryPageState extends ConsumerState<LanDiscoveryPage> {
  @override
  void initState() {
    super.initState();
    // 页面加载时开始扫描
    // 使用 Future.microtask 确保在 build 完成后执行
    Future.microtask(
        () => ref.read(lanDiscoveryProvider.notifier).startDiscovery());
  }

  @override
  void dispose() {
    // Notifier 是 autoDispose ，页面销毁时会停止扫描
    // ref.read(lanDiscoveryProvider.notifier).stopDiscovery();
    super.dispose();
  }

  /// 获取模板显示名称，优先使用广播中的模板名称，否则查询本地数据库
  String _getTemplateName(DiscoveredHost host) {
    // 优先使用广播消息中的模板名称
    if (host.templateName != null && host.templateName!.isNotEmpty) {
      return host.templateName!;
    }

    // 如果广播消息中没有模板名称，则查询本地数据库（向后兼容）
    final templatesAsync = ref.read(templatesProvider);
    if (templatesAsync.hasValue && templatesAsync.value != null) {
      try {
        final template = templatesAsync.value!.firstWhere(
          (t) => t.tid == host.baseTid,
        );
        return template.templateName;
      } catch (e) {
        // 如果找不到匹配的模板，firstWhere 会抛出异常
      }
    }
    // 如果找不到模板或模板数据未加载，返回ID
    return host.baseTid;
  }

  Future<void> _connectToHost(DiscoveredHost host) async {
    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final lanNotifier = ref.read(lanProvider.notifier);

      // 1. 连接到主机
      await lanNotifier.connectToDiscoveredHost(host);

      // 2. 短暂等待连接建立
      await Future.delayed(const Duration(milliseconds: 500));

      // 检查连接状态
      final lanState = ref.read(lanProvider);
      if (!lanState.isConnected) {
        if (!mounted) return;
        globalState.navigatorKey.currentState?.pop(); // 关闭加载对话框
        ref.showError('连接失败，请重试');
        return;
      }

      // 3.发送状态同步请求
      final requestMessage = SyncMessage(
          type: "request_sync_state", data: {"templateId": host.baseTid});
      final jsonString = jsonEncode(requestMessage.toJson());
      lanNotifier.sendJsonMessage(jsonString);

      // 4. 修复：使用轮询等待会话状态和玩家信息同步
      const pollInterval = Duration(milliseconds: 500); // 轮询间隔
      const timeoutDuration = Duration(seconds: 15); // 增加超时时间到15秒
      final stopwatch = Stopwatch()..start();
      bool sessionSynced = false;

      while (stopwatch.elapsed < timeoutDuration) {
        final scoreAsync = ref.read(scoreProvider);
        // 记录 Provider 当前状态
        Log.d('_connectToHost 轮询: scoreProvider 状态为 ${scoreAsync.runtimeType}');

        if (scoreAsync is AsyncData) {
          final scoreState = scoreAsync.value;
          // 修复：更详细的同步状态检查
          if (scoreState != null) {
            final hasSession = scoreState.currentSession != null;
            final templateMatches = hasSession &&
                scoreState.currentSession!.templateId == host.baseTid;
            final hasPlayers = scoreState.players.isNotEmpty;
            final hasScores =
                hasSession && scoreState.currentSession!.scores.isNotEmpty;

            Log.d(
                '_connectToHost 轮询详情: hasSession=$hasSession, templateMatches=$templateMatches, hasPlayers=$hasPlayers, hasScores=$hasScores');
            Log.d(
                '_connectToHost 轮询详情: 玩家数量=${scoreState.players.length}, 分数数量=${scoreState.currentSession?.scores.length ?? 0}');

            // 检查是否有会话状态、模板ID匹配、且有玩家信息
            if (hasSession && templateMatches && hasPlayers && hasScores) {
              Log.i('_connectToHost 轮询: 会话状态和玩家信息已成功同步（模板: ${host.baseTid}）!');
              sessionSynced = true;
              break; // 会话已同步，退出循环
            } else {
              Log.d(
                  '_connectToHost 轮询: 同步尚未完成 - 会话:$hasSession, 模板匹配:$templateMatches, 玩家:$hasPlayers, 分数:$hasScores');
            }
          } else {
            Log.d('_connectToHost 轮询: scoreState 为空');
          }
        } else if (scoreAsync is AsyncError) {
          Log.e(
              '_connectToHost 轮询: scoreProvider 处于 AsyncError 状态: ${scoreAsync.error}');
          // 可选：立即中断循环或处理错误
          // break;
        }

        // 等待下一次轮询
        await Future.delayed(pollInterval);
      }
      stopwatch.stop();

      // 5. 检查同步结果
      if (!sessionSynced) {
        if (!mounted) return;
        globalState.navigatorKey.currentState?.pop(); // 关闭加载对话框
        ref.showError('会话状态同步超时或失败，请重试');
        // 新增：断开连接
        lanNotifier.disposeManager();
        return;
      }

      // 模板已同步，关闭加载对话框并导航
      if (!mounted) return;
      globalState.navigatorKey.currentState?.pop();

      // 修复：等待一小段时间确保模板状态完全稳定后再导航
      await Future.delayed(Duration(milliseconds: 100));

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        CustomPageTransitions.slideFromRight(
          HomePage.buildSessionPage(null, host.baseTid),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ),
      );
    } catch (e, s) {
      // 错误处理
      Log.e('连接或同步时出错. Error: $e\nStackTrace: $s'); // 记录错误和堆栈
      if (mounted) {
        globalState.navigatorKey.currentState?.pop(); // 确保出错时关闭对话框
        ref.showError('连接或同步时出错: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final discoveryState = ref.watch(lanDiscoveryProvider);
    final discoveryNotifier = ref.read(lanDiscoveryProvider.notifier);
    final lanState = ref.watch(lanProvider);
    final lanNotifier = ref.read(lanProvider.notifier);

    // 检查是否处于客户端模式
    if (lanState.isClientMode) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('发现局域网游戏'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.block,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                '客户端模式下无法发现局域网游戏',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '请先退出客户端模式或断开当前连接',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('返回'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('发现局域网游戏'),
        actions: [
          // 添加刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重新扫描',
            onPressed: discoveryState.isScanning
                ? null // 扫描中禁用
                : () => discoveryNotifier.startDiscovery(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 显示错误信息
          if (discoveryState.error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '错误: ${discoveryState.error}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          // 新增：显示本机IP地址和操作按钮
          IpDisplayWidget(
            localIp: lanState.localIp,
            interfaceName: lanState.interfaceName,
            onRefreshIp: () => lanNotifier.refreshLocalIp(),
          ),
          // 结束新增
          // 显示扫描状态或无主机提示
          if (discoveryState.isScanning && discoveryState.hosts.isEmpty)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (!discoveryState.isScanning &&
              discoveryState.hosts.isEmpty &&
              discoveryState.error == null)
            const Expanded(
              child: Center(child: Text('未发现局域网中的主机\n请确保主机已启动并发送广播')),
            )
          // 显示主机列表
          else
            Expanded(
              child: ListView.builder(
                itemCount: discoveryState.hosts.length,
                itemBuilder: (context, index) {
                  final host = discoveryState.hosts[index];
                  return ListTile(
                    leading: const Icon(Icons.dns_outlined),
                    // 主机图标
                    title: Text(host.hostName),
                    // 显示主机名
                    subtitle: Text(
                        '${host.ip}:${host.port} (模板: ${_getTemplateName(host)})'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _connectToHost(host), // 点击连接
                  );
                },
              ),
            ),

          // 显示扫描状态指示器 (可选，如果列表不为空时也想显示)
          if (discoveryState.isScanning)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('正在扫描...'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
