import 'package:counters/common/log_provider.dart';
import 'package:counters/common/widgets/snackbar.dart';
import 'package:counters/features/lan/lan_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    if (lanState.isHostAndClientMode) {
      modeText = '模式: 主机 & 客户端';
    } else if (lanState.isHost) {
      modeText = '模式: 主机';
    } else {
      modeText = '模式: 客户端';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('通信测试&日志'),
        actions: [
          // 新增：广播控制按钮（仅主机模式显示）
          if (lanState.isHost)
            IconButton(
              icon: Icon(
                lanState.isBroadcasting
                    ? Icons.wifi_tethering
                    : Icons.wifi_tethering_off,
              ),
              tooltip: lanState.isBroadcasting ? '关闭广播' : '开启广播',
              onPressed: () {
                lanNotifier.toggleBroadcast();
                AppSnackBar.show(
                  lanState.isBroadcasting ? '广播已开启' : '广播已关闭',
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: '清空所有日志和消息',
            onPressed: () {
              lanNotifier.clearMessages();
              logNotifier.clearLogs();
              AppSnackBar.show('日志和消息已清空');
            },
          ),
          if (lanState.isConnected || lanState.isHost)
            IconButton(
              icon: const Icon(Icons.stop_circle_outlined),
              tooltip: lanState.isHost ? '停止主机' : '断开连接',
              onPressed: () async {
                await lanNotifier.disposeManager();
                AppSnackBar.show(lanState.isHost ? '主机已停止' : '连接已断开');
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // --- 顶部控制区域 (如果连接未建立) ---
            // 如果是 HostAndClient 模式，也隐藏连接控制，因为它自动连接
            if (!lanState.isConnected &&
                !lanState.isHost &&
                !lanState.isHostAndClientMode) ...[
              Text('你的IP地址: ${lanState.localIp}',
                  style: Theme.of(context).textTheme.titleMedium),
              if (lanState.localIp != '获取中...' && lanState.localIp != '获取失败')
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('复制IP'),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: lanState.localIp));
                        AppSnackBar.show('IP地址已复制');
                      },
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('刷新IP'),
                      onPressed: () {
                        lanNotifier.refreshLocalIp();
                      },
                    ),
                  ],
                ),
              Row(
                // 将成为主机和成为主机&客户端按钮分开，避免重复
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: lanState.isLoading
                        ? null
                        : () => lanNotifier.startHost(defaultPort, "poker50"),
                    child: const Text('成为主机'),
                  ),
                  ElevatedButton(
                    onPressed: lanState.isLoading
                        ? null
                        : () => lanNotifier.startHostAndClient(
                            defaultPort, "poker50"),
                    child: const Text('成为主机&客户端'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: lanNotifier.hostIpController,
                      decoration: const InputDecoration(
                        labelText: '输入主机IP地址',
                        hintText: '例如: 192.168.1.100',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: lanState.isLoading
                        ? null
                        : () {
                            final hostIp =
                                lanNotifier.hostIpController.text.trim();
                            if (hostIp.isNotEmpty) {
                              lanNotifier.connectToHost(hostIp, defaultPort);
                            } else {
                              AppSnackBar.show('请输入主机IP地址');
                            }
                          },
                    child: const Text('连接主机'),
                  ),
                ],
              ),
              const Divider(),
            ],

            // --- 连接后的状态和消息发送 ---
            // 当连接有效 (纯客户端连接成功)，或者处于主机模式 (纯主机或HostAndClient)
            if (lanState.isConnected || lanState.isHost) ...[
              Text(modeText, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              // 显示更详细的状态，包括是否已连接 (如果是客户端)
              Text(
                  '状态: ${lanState.connectionStatus} ${lanState.isConnected ? '(客户端已连接)' : (lanState.isHost ? '(主机运行中)' : '')}'),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: lanNotifier.messageController,
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
