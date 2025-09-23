import 'package:counters/app/state.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/common/widgets/message_overlay.dart';
import 'package:counters/features/home/providers/main_tab_actions.dart';
import 'package:counters/features/lan/lan_provider.dart';
import 'package:counters/features/lan/ping_provider.dart';
import 'package:counters/features/setting/ping_display_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 显示LAN状态Bottom Sheet
void showLanStatusSheet() {
  final context = globalState.navigatorKey.currentContext;
  if (context == null) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    // 确保不遮挡状态栏区域
    builder: (BuildContext context) {
      return const LanStatusBottomSheet();
    },
  );
}

class LanStatusBottomSheet extends ConsumerWidget {
  const LanStatusBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lanState = ref.watch(lanProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          // 拖拽手柄
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 标题区域
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.wifi_tethering,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  '局域网状态',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  tooltip: '关闭',
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 内容区域
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 连接状态卡片
                  _StatusCard(lanState: lanState),
                  const SizedBox(height: 12),

                  // 网络信息卡片
                  _NetworkInfoCard(lanState: lanState),
                  const SizedBox(height: 12),

                  // 主机模式特有信息
                  if (lanState.isHost) ...[
                    _HostInfoCard(lanState: lanState),
                    const SizedBox(height: 12),
                  ],

                  // 操作按钮
                  _ActionButtons(lanState: lanState),

                  // 底部安全区域
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final LanState lanState;

  const _StatusCard({required this.lanState});

  @override
  Widget build(BuildContext context) {
    final (statusIcon, statusColor, statusText, statusDescription) =
        _getStatusInfo();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusDescription,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color, String, String) _getStatusInfo() {
    if (lanState.isHost) {
      return (
        Icons.dns,
        Colors.green,
        '主机模式',
        lanState.connectionStatus,
      );
    } else if (lanState.isClientMode) {
      if (lanState.isConnected) {
        return (
          Icons.wifi,
          Colors.blue,
          '客户端模式',
          '已连接到主机',
        );
      } else if (lanState.isReconnecting) {
        return (
          Icons.wifi_tethering,
          Colors.orange,
          '客户端模式',
          '正在重连... (${lanState.reconnectAttempts}/${lanState.maxReconnectAttempts})',
        );
      } else {
        String statusText = '客户端模式（已断开）';
        String description = lanState.disconnectReason ?? '与主机的连接已断开';
        return (
          Icons.wifi_off,
          Colors.red,
          statusText,
          description,
        );
      }
    } else {
      return (
        Icons.wifi_off,
        Colors.grey,
        '未连接',
        '当前未建立局域网连接',
      );
    }
  }
}

class _NetworkInfoCard extends ConsumerWidget {
  final LanState lanState;

  const _NetworkInfoCard({required this.lanState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary, size: 16),
              const SizedBox(width: 6),
              Text(
                '网络信息',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.computer,
            label: '本机IP地址',
            value: lanState.localIp,
            canCopy: true,
          ),
          if (lanState.interfaceName.isNotEmpty)
            _InfoRow(
              icon: Icons.network_check,
              label: '网络接口',
              value: lanState.interfaceName,
            ),
          if (lanState.isHost) ...[
            _InfoRow(
              icon: Icons.router,
              label: '服务端口',
              value: lanState.serverPort > 0
                  ? lanState.serverPort.toString()
                  : '8080',
            ),
            _InfoRow(
              icon: Icons.broadcast_on_personal,
              label: '广播端口',
              value: lanState.discoveryPort > 0
                  ? lanState.discoveryPort.toString()
                  : '8099',
            ),
          ],
          // 客户端模式显示主机信息
          if (lanState.isClientMode && !lanState.isHost) ...[
            // 展示分割线
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            if (lanState.hostIp != null)
              _InfoRow(
                icon: Icons.dns,
                label: '主机地址',
                value: lanState.hostIp!,
                canCopy: true,
              ),
            if (lanState.serverPort > 0)
              _InfoRow(
                icon: Icons.router,
                label: '服务端口',
                value: lanState.serverPort.toString(),
              ),
            if (lanState.discoveryPort > 0)
              _InfoRow(
                icon: Icons.broadcast_on_personal,
                label: '广播端口',
                value: lanState.discoveryPort.toString(),
              ),
            if (lanState.disconnectReason != null)
              _InfoRow(
                icon: Icons.error_outline,
                label: '断开原因',
                value: lanState.disconnectReason!,
              ),
          ],

          // Ping 显示设置（仅在客户端模式下显示）
          if (lanState.isClientMode && !lanState.isHost) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            _buildPingDisplaySetting(context, ref),
          ],
        ],
      ),
    );
  }

  /// 构建 Ping 显示设置
  Widget _buildPingDisplaySetting(BuildContext context, WidgetRef ref) {
    final showPingWidget = ref.watch(pingDisplaySettingProvider);
    final pingState = ref.watch(pingProvider);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            Icons.network_ping,
            size: 16,
            color: showPingWidget
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ping 显示',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.none,
                      ),
                ),
                Text(
                  showPingWidget ? '在计分界面显示网络延迟信息' : '已隐藏 Ping 显示',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        decoration: TextDecoration.none,
                      ),
                ),
                // 显示当前 ping 值（如果可用）
                if (showPingWidget &&
                    pingState.isActive &&
                    pingState.pingMs != null)
                  Text(
                    '当前延迟: ${pingState.pingMs}ms',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getPingStatusColor(pingState.status, context),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.none,
                        ),
                  ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: showPingWidget,
              onChanged: (value) async {
                try {
                  await ref
                      .read(pingDisplaySettingProvider.notifier)
                      .setShowPingWidget(value);
                  ref.showSuccess(value ? 'Ping 显示已开启' : 'Ping 显示已关闭');
                } catch (e) {
                  ref.showError('设置失败: $e');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 根据 ping 状态获取颜色
  Color _getPingStatusColor(PingStatus status, BuildContext context) {
    switch (status) {
      case PingStatus.excellent:
        return Colors.green;
      case PingStatus.good:
        return Colors.lightGreen;
      case PingStatus.fair:
        return Colors.orange;
      case PingStatus.poor:
      case PingStatus.error:
        return Colors.red;
      case PingStatus.unknown:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }
}

class _InfoRow extends ConsumerWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool canCopy;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.canCopy = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon,
              size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          if (canCopy && _canCopyValue(value))
            InkWell(
              onTap: () => _copyToClipboard(context, value, ref),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.copy,
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _canCopyValue(String value) {
    return value.isNotEmpty &&
        value != '获取中...' &&
        value != '获取失败' &&
        value != '未知';
  }

  void _copyToClipboard(BuildContext context, String text, WidgetRef ref) {
    try {
      Log.d('LAN Status Sheet: 准备复制文本到剪贴板 - $text');
      Clipboard.setData(ClipboardData(text: text));
      Log.d('LAN Status Sheet: 剪贴板设置成功，准备显示成功消息');

      // 使用 Riverpod 消息系统，不会被 Bottom Sheet 遮挡
      ref.showSuccess('已复制: $text');
    } catch (e, stackTrace) {
      Log.d('LAN Status Sheet: 复制到剪贴板失败 - $e');
      Log.d('StackTrace: $stackTrace');

      // 备用方案：使用 ScaffoldMessenger
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已复制: $text')),
        );
      } catch (e2) {
        Log.d('LAN Status Sheet: ScaffoldMessenger 也失败了 - $e2');
      }
    }
  }
}

class _HostInfoCard extends ConsumerWidget {
  final LanState lanState;

  const _HostInfoCard({required this.lanState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people_outline,
                  color: Theme.of(context).colorScheme.primary, size: 16),
              const SizedBox(width: 6),
              Text(
                '连接管理',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 已连接客户端
          Row(
            children: [
              Icon(Icons.devices,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                '已连接客户端: ',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              Text(
                '${lanState.connectedClientIps.length}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: lanState.connectedClientIps.isEmpty
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),

          if (lanState.connectedClientIps.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: lanState.connectedClientIps
                    .map((ip) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Row(
                            children: [
                              Icon(Icons.smartphone,
                                  size: 12,
                                  color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 6),
                              Text(ip,
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],

          const SizedBox(height: 10),

          // 广播控制
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withOpacity(0.2),
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.broadcast_on_personal,
                    size: 16,
                    color: lanState.isBroadcasting
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '服务发现广播',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      Text(
                        lanState.isBroadcasting ? '正在广播，其他设备可发现此主机' : '已停止广播',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 12,
                            ),
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: lanState.isBroadcasting,
                    onChanged: (value) {
                      ref.read(lanProvider.notifier).setBroadcastState(value);
                      // 使用 Riverpod 消息系统，不会被 Bottom Sheet 遮挡
                      try {
                        Log.d('LAN Status Sheet: 准备显示广播状态消息');
                        ref.showSuccess(value ? '广播已开启' : '广播已关闭');
                        Log.d('LAN Status Sheet: 广播状态消息显示完成');
                      } catch (e) {
                        Log.d('LAN Status Sheet: 显示广播状态消息失败 - $e');
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends ConsumerWidget {
  final LanState lanState;

  const _ActionButtons({required this.lanState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 显示操作按钮的条件：主机模式、已连接的客户端、或处于客户端模式（即使断开）
    if (!lanState.isHost && !lanState.isConnected && !lanState.isClientMode) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // 主机模式：停止主机按钮
        if (lanState.isHost) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ref.read(lanProvider.notifier).disposeManager();
                // 使用 Riverpod 消息系统，不会被 Bottom Sheet 遮挡
                try {
                  Log.d('LAN Status Sheet: 准备显示停止主机消息');
                  ref.showSuccess('已停止主机');
                  Log.d('LAN Status Sheet: 停止主机消息显示完成');
                } catch (e) {
                  Log.d('LAN Status Sheet: 显示停止主机消息失败 - $e');
                }
              },
              icon: const Icon(Icons.stop),
              label: const Text('停止主机'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],

        // 客户端模式：根据连接状态显示不同按钮
        if (lanState.isClientMode && !lanState.isHost) ...[
          // 如果已连接，显示断开连接按钮
          if (lanState.isConnected) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  // 修复：使用exitClientMode完全退出客户端模式
                  await ref.read(lanProvider.notifier).exitClientMode();
                  // 修复：断开连接后导航到带有底部导航栏的主界面
                  ref.popToMainTab(0);
                },
                icon: const Icon(Icons.wifi_off),
                label: const Text('断开连接'),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ] else ...[
            // 如果未连接，显示重连和退出客户端模式按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: lanState.isReconnecting
                        ? null
                        : () {
                            Navigator.pop(context);
                            ref.read(lanProvider.notifier).manualReconnect();
                          },
                    icon: lanState.isReconnecting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(lanState.isReconnecting ? '重连中...' : '重连'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await ref.read(lanProvider.notifier).exitClientMode();
                      // 修复：退出客户端模式后导航到带有底部导航栏的主界面
                      ref.popToMainTab(0);
                    },
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('退出客户端'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}
