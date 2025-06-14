import 'package:counters/common/log_provider.dart';
import 'package:counters/common/utils/error_handler.dart';
import 'package:counters/common/widgets/ip_display_widget.dart';
import 'package:counters/common/widgets/snackbar.dart';
import 'package:counters/features/lan/lan_provider.dart';
import 'package:counters/features/lan/widgets/lan_status_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// UI Widget
class LanTestPage extends ConsumerWidget {
  const LanTestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lanState = ref.watch(lanProvider);
    final lanNotifier = ref.read(lanProvider.notifier);
    final appLogs = ref.watch(logProvider);
    final logNotifier = ref.read(logProvider.notifier);
    const int defaultPort = 8080;

    String modeText = '未知';
    if (lanState.isHost) {
      modeText = '模式: 主机';
    } else if (lanState.isClientMode) {
      if (lanState.isConnected) {
        modeText = '模式: 客户端（已连接）';
      } else if (lanState.isReconnecting) {
        modeText = '模式: 客户端（重连中 ${lanState.reconnectAttempts}/${lanState.maxReconnectAttempts}）';
      } else {
        modeText = '模式: 客户端（已断开连接）';
      }
    } else {
      modeText = '模式: 未连接';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('通信测试&日志'),
        actions: [
          // LAN状态显示按钮（显示主机模式、客户端模式、连接状态等）
          const LanStatusButton(),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: '清空所有日志和消息',
            onPressed: () {
              lanNotifier.clearMessages();
              logNotifier.clearLogs();
              AppSnackBar.show('日志和消息已清空');
            },
          ),
          // 停止/断开连接按钮
          if (lanState.isConnected || lanState.isHost)
            IconButton(
              icon: const Icon(Icons.stop_circle_outlined),
              tooltip: lanState.isHost ? '停止主机' : '断开连接',
              onPressed: () async {
                try {
                  await lanNotifier.disposeManager();
                  AppSnackBar.show(lanState.isHost ? '主机已停止' : '连接已断开');
                } catch (e) {
                  ErrorHandler.handle(e, StackTrace.current, prefix: '停止连接失败');
                }
              },
            ),
          // 重连按钮（客户端模式且未连接且有主机IP时显示）
          if (lanState.isClientMode &&
              !lanState.isConnected &&
              !lanState.isReconnecting &&
              lanState.hostIp != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '重连到主机',
              onPressed: () async {
                try {
                  await lanNotifier.manualReconnect();
                } catch (e) {
                  ErrorHandler.handle(e, StackTrace.current, prefix: '手动重连失败');
                }
              },
            ),
          // 退出客户端模式按钮（客户端模式且未连接时显示）
          if (lanState.isClientMode && !lanState.isConnected && !lanState.isReconnecting)
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              tooltip: '退出客户端模式',
              onPressed: () async {
                try {
                  await lanNotifier.exitClientMode();
                } catch (e) {
                  ErrorHandler.handle(e, StackTrace.current, prefix: '退出客户端模式失败');
                }
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

              // 客户端模式状态显示
              if (lanState.isClientMode) ...[
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.devices,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '客户端模式',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (lanState.hostIp != null) ...[
                          Text('主机IP: ${lanState.hostIp}'),
                          const SizedBox(height: 4),
                        ],
                        Text('状态: ${lanState.connectionStatus}'),
                        if (lanState.disconnectReason != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '断开原因: ${lanState.disconnectReason}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ] else ...[
                // 非客户端模式：显示成为主机按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: lanState.isLoading || lanState.isClientMode
                          ? null
                          : () => lanNotifier.startHost(defaultPort, "poker50", templateName: "扑克50"),
                      child: const Text('成为主机'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // 连接主机输入框（非客户端模式时显示）
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: lanNotifier.getHostIpController(),
                        decoration: const InputDecoration(
                          labelText: '输入主机IP地址',
                          hintText: '例如: 192.168.1.100',
                        ),
                        keyboardType: TextInputType.number,
                        enabled: !lanState.isLoading && !lanState.isClientMode,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: lanState.isLoading || lanState.isClientMode
                          ? null
                          : () => lanNotifier.connectToHostFromInput(defaultPort),
                      child: const Text('连接主机'),
                    ),
                  ],
                ),
              ],
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
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            modeText,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: lanState.isHost
                                  ? Theme.of(context).colorScheme.onPrimaryContainer
                                  : Theme.of(context).colorScheme.onSecondaryContainer,
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
                              : Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                      ),
                      if (lanState.isHost && lanState.connectedClientIps.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '已连接客户端: ${lanState.connectedClientIps.length} 个',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (lanState.isClientMode && lanState.hostIp != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '主机IP: ${lanState.hostIp}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
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
              const SizedBox(height: 20),
              const Divider(),
            ],

            // --- 日志显示区域 (使用 Expanded 填充剩余空间) ---
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('网络消息:',
                            style: Theme.of(context).textTheme.titleMedium),
                        const Divider(),
                        Expanded(
                          child: lanState.receivedMessages.isEmpty
                              ? const Center(child: Text('暂无网络消息'))
                              : ListView.builder(
                                  reverse: true,
                                  itemCount: lanState.receivedMessages.length,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      title: Text(
                                        lanState.receivedMessages[index],
                                        style: TextStyle(fontSize: 12), // 减小字体
                                      ),
                                      dense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                          vertical: 0), // 减小内边距
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(),
                  Expanded(
                    flex: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('应用日志:',
                            style: Theme.of(context).textTheme.titleMedium),
                        const Divider(),
                        Expanded(
                          child: appLogs.isEmpty
                              ? const Center(child: Text('暂无应用日志'))
                              : ListView.builder(
                                  reverse: true,
                                  itemCount: appLogs.length,
                                  itemBuilder: (context, index) {
                                    String logText = appLogs[index];
                                    Color? logColor;
                                    const double smallFontSize = 11.0;
                                    // 判断日志级别并设置颜色，更健壮的方式是 LogHelper 输出时就包含级别标识
                                    // 或者使用正则表达式或startsWith等方式
                                    // 这里简单判断前缀
                                    if (logText.startsWith('[E]') ||
                                        logText.startsWith('[WTF]')) {
                                      logColor = Colors.red;
                                    } else if (logText.startsWith('[W]')) {
                                      logColor = Colors.orange;
                                    } else if (logText.startsWith('[I]')) {
                                      logColor = Colors.blue;
                                    }
                                    TextStyle textStyle = TextStyle(
                                        color: logColor ??
                                            Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                        // 使用主题默认颜色作为 fallback
                                        fontSize: smallFontSize);

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 2.0),
                                      child: Text(
                                        logText,
                                        style: textStyle,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
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
    );
  }
}
