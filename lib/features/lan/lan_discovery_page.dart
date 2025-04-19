import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:counters/common/model/landlords.dart';
import 'package:counters/common/model/sync_messages.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/common/widgets/snackbar.dart';
import 'package:counters/features/lan/lan_discovery_provider.dart';
import 'package:counters/features/lan/lan_provider.dart';
import 'package:counters/features/player/player_provider.dart';
import 'package:counters/features/score/template_provider.dart';
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
      await lanNotifier.connectToHost(host.ip, host.port);

      // 2. 短暂等待连接建立
      await Future.delayed(const Duration(milliseconds: 500));

      // 检查连接状态
      final lanState = ref.read(lanProvider);
      if (!lanState.isConnected) {
        if (!mounted) return;
        Navigator.of(context).pop(); // 关闭加载对话框
        AppSnackBar.error('连接失败，请重试');
        return;
      }

      // 3.发送状态同步请求
      final requestMessage = SyncMessage(
          type: "request_sync_state", data: {"templateId": host.baseTid});
      final jsonString = jsonEncode(requestMessage.toJson());
      lanNotifier.sendJsonMessage(jsonString);

      // 4. 使用轮询等待模板同步（包含玩家信息）
      const pollInterval = Duration(milliseconds: 2000); // 轮询间隔
      const timeoutDuration = Duration(seconds: 10); // 超时时间
      final stopwatch = Stopwatch()..start();
      bool templateSynced = false;

      while (stopwatch.elapsed < timeoutDuration) {
        final templatesAsync = ref.read(templatesProvider);
        // 记录 Provider 当前状态
        Log.d(
            '_connectToHost 轮询: templatesProvider 状态为 ${templatesAsync.runtimeType}');

        if (templatesAsync is AsyncData) {
          Log.d('_connectToHost 轮询: 发现 AsyncData, 检查内容...');
          final template = templatesAsync.value
              ?.firstWhereOrNull((t) => t.tid == host.baseTid);
          // 检查模板是否存在并且包含玩家信息
          if (template != null && template.players.isNotEmpty) {
            Log.i('_connectToHost 轮询: 模板 ${host.baseTid} 已成功同步（包含玩家）!');
            templateSynced = true;
            break; // 模板已同步，退出循环
          } else {
            Log.d('_connectToHost 轮询: 找到模板但玩家列表为空或模板为 null。');
          }
        } else if (templatesAsync is AsyncError) {
          Log.e(
              '_connectToHost 轮询: templatesProvider 处于 AsyncError 状态: ${templatesAsync.error}');
          // 可选：立即中断循环或处理错误
          // break;
        }

        // 等待下一次轮询
        await Future.delayed(pollInterval);
      }
      stopwatch.stop();

      // 5. 检查同步结果
      if (!templateSynced) {
        if (!mounted) return;
        Navigator.of(context).pop(); // 关闭加载对话框
        AppSnackBar.error('模板同步超时或失败，请重试');
        // 新增：断开连接
        lanNotifier.disposeManager();
        return;
      }

      // 模板已同步，关闭加载对话框并导航
      if (!mounted) return;
      Navigator.of(context).pop();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage.buildSessionPage(null, host.baseTid),
        ),
      );
    } catch (e, s) {
      // 错误处理
      Log.e('连接或同步时出错. Error: $e\nStackTrace: $s'); // 记录错误和堆栈
      if (mounted) {
        Navigator.of(context).pop(); // 确保出错时关闭对话框
        AppSnackBar.error('连接或同步时出错: $e');
      }
    }
  }

  Future<void> _saveTemplate() async {
    final players = ref.read(playerProvider).players ?? [];
    final template = LandlordsTemplate(
      templateName: '斗地主模板',
      playerCount: 3,
      targetScore: 0,
      players: players,
      baseScore: 1,
      checkMultiplier: true,
      bombMultiplyMode: false,
    );

    await ref.read(templatesProvider.notifier).saveUserTemplate(template, null);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('模板保存成功')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final discoveryState = ref.watch(lanDiscoveryProvider);
    final discoveryNotifier = ref.read(lanDiscoveryProvider.notifier);

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
                    subtitle:
                        Text('${host.ip}:${host.port} (模板: ${host.baseTid})'),
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
