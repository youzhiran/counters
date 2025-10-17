import 'package:counters/common/providers/log_provider.dart';
import 'package:counters/common/widgets/ip_display_widget.dart';
import 'package:counters/common/widgets/message_overlay.dart';
import 'package:counters/features/lan/lan_provider.dart';
import 'package:counters/features/lan/widgets/lan_status_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// UI Widget
class LogTestPage extends ConsumerWidget {
  const LogTestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lanState = ref.watch(lanProvider);
    final lanNotifier = ref.read(lanProvider.notifier);
    final appLogs = ref.watch(logProvider);
    final networkLogs = ref.watch(networkLogProvider);
    final logNotifier = ref.read(logProvider.notifier);
    final networkLogNotifier = ref.read(networkLogProvider.notifier);

    String modeText = '未知';
    if (lanState.isHost) {
      modeText = '模式: 主机';
    } else if (lanState.isClientMode) {
      if (lanState.isConnected) {
        modeText = '模式: 客户端（已连接）';
      } else if (lanState.isReconnecting) {
        modeText =
            '模式: 客户端（重连中 ${lanState.reconnectAttempts}/${lanState.maxReconnectAttempts}）';
      } else {
        modeText = '模式: 客户端（已断开连接）';
      }
    } else {
      modeText = '模式: 未连接';
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('程序日志'),
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          bottom: const TabBar(
            tabs: [
              Tab(text: '程序日志'),
              Tab(text: '网络日志'),
            ],
          ),
          actions: [
            // LAN状态显示按钮（显示主机模式、客户端模式、连接状态等）
            const LanStatusButton(),
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: '清空所有日志和消息',
              onPressed: () {
                lanNotifier.clearMessages();
                logNotifier.clearLogs();
                networkLogNotifier.clearLogs();
                GlobalMsgManager.showMessage('日志和消息已清空');
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // --- 顶部控制区域 ---
              if (!lanState.isConnected && !lanState.isHost) ...[
                // IP 显示组件
              IpDisplayWidget(
                localIp: lanState.localIp,
                interfaceName: lanState.interfaceName,
                onRefreshIp: () => lanNotifier.refreshLocalIp(),
              ),
              const Divider(),
            ],

            // --- 连接后的状态和消息发送 ---
            // 当连接有效 (纯客户端连接成功)，或者处于主机模式 (纯主机或HostAndClient)
            if (lanState.isConnected || lanState.isHost) ...[
              // 模式状态显示
              Card(
                color: lanState.isHost
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            lanState.isHost ? Icons.router : Icons.devices,
                            color: lanState.isHost
                                ? Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                : Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            modeText,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: lanState.isHost
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSecondaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '状态: ${lanState.connectionStatus}',
                        style: TextStyle(
                          color: lanState.isHost
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
                        ),
                      ),
                      if (lanState.isHost &&
                          lanState.connectedClientIps.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '已连接客户端: ${lanState.connectedClientIps.length} 个',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (lanState.isClientMode && lanState.hostIp != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '主机IP: ${lanState.hostIp}',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: lanNotifier.getMessageController(),
                      decoration: const InputDecoration(
                        labelText: '输入消息发送',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => lanNotifier.sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 发送按钮只有在连接有效时才启用 (HostAndClient模式下 isConnected 也是 true)
                  ElevatedButton(
                    onPressed: lanState.isLoading ||
                            !lanState.isConnected && !lanState.isHost
                        ? null
                        : lanNotifier.sendMessage, // 调用发送测试消息的方法
                    child: const Text('发送测试消息'),
                  ),
                ],
              ),
              const Divider(),
            ],

            // --- 日志显示区域 (使用 Expanded 填充剩余空间) ---
              Expanded(
                child: TabBarView(
                  children: [
                    _LogListView(
                      logs: appLogs,
                      emptyText: '暂无应用日志',
                    ),
                    _LogListView(
                      logs: networkLogs,
                      emptyText: '暂无网络日志',
                    ),
                  ],
                ),
              ),

              // --- 加载指示器 ---
              if (lanState.isLoading)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogListView extends ConsumerWidget {
  final List<String> logs;
  final String emptyText;

  const _LogListView({
    required this.logs,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (logs.isEmpty) {
      return Center(child: Text(emptyText));
    }

    final spans = <InlineSpan>[];
    for (var i = 0; i < logs.length; i++) {
      final logText = logs[i];
      final textStyle = _resolveLogTextStyle(context, logText);
      spans.add(TextSpan(text: logText, style: textStyle));
      if (i != logs.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return Scrollbar(
      child: SingleChildScrollView(
        primary: true,
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: SelectionArea(
          child: Text.rich(
            TextSpan(children: spans),
            textAlign: TextAlign.left,
          ),
        ),
      ),
    );
  }

  TextStyle _resolveLogTextStyle(BuildContext context, String logText) {
    const double smallFontSize = 11.0;
    Color? logColor;

    if (logText.startsWith('[E]') || logText.startsWith('[WTF]')) {
      logColor = Colors.red;
    } else if (logText.startsWith('[W]')) {
      logColor = Colors.orange;
    } else if (logText.startsWith('[I]')) {
      logColor = Colors.blue;
    } else if (logText.startsWith('[D]')) {
      logColor = Colors.green;
    } else if (logText.startsWith('[V]')) {
      logColor = Colors.grey;
    }

    return TextStyle(
      color: logColor ?? Theme.of(context).colorScheme.onSurface,
      fontSize: smallFontSize,
      height: 1.4,
    );
  }
}
