import 'package:counters/app/state.dart';
import 'package:counters/common/widgets/snackbar.dart';
import 'package:counters/features/lan/lan_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 显示LAN状态对话框
void showLanStatusDialog() {
  globalState.showCommonDialog(
    child: const LanStatusDialog(),
  );
}

class LanStatusDialog extends ConsumerWidget {
  const LanStatusDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lanState = ref.watch(lanProvider);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.wifi_tethering,
               color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          const Text('局域网状态'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => globalState.navigatorKey.currentState?.pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final LanState lanState;

  const _StatusCard({required this.lanState});

  @override
  Widget build(BuildContext context) {
    final (statusIcon, statusColor, statusText, statusDescription) = _getStatusInfo();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusDescription,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
    } else if (lanState.isConnected) {
      return (
        Icons.wifi,
        Colors.blue,
        '客户端模式',
        '已连接到主机',
      );
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
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
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
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
          if (lanState.isHost)
            _InfoRow(
              icon: Icons.router,
              label: '服务端口',
              value: lanState.serverPort > 0 ? lanState.serverPort.toString() : '8080',
            ),
          if (lanState.isConnected && !lanState.isHost)
            _InfoRow(
              icon: Icons.dns,
              label: '主机地址',
              value: _extractHostIp(lanState.connectionStatus),
              canCopy: true,
            ),
        ],
      ),
    );
  }



  String _extractHostIp(String connectionStatus) {
    // 修复：正确解析主机IP地址
    // 处理各种可能的格式：
    // "已连接到 192.168.1.100:8080" -> "192.168.1.100"
    // "192.168.1.100:8080" -> "192.168.1.100"
    // "192.168.1.100" -> "192.168.1.100"

    String result = connectionStatus.trim();

    // 使用正则表达式匹配IP地址模式
    final ipPattern = RegExp(r'\b(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\b');
    final match = ipPattern.firstMatch(result);

    if (match != null) {
      return match.group(1) ?? result;
    }

    // 如果没有匹配到IP地址模式，返回原始字符串
    return result;
  }
}

class _InfoRow extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, 
               color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (canCopy && _canCopyValue(value))
            InkWell(
              onTap: () => _copyToClipboard(value),
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

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    AppSnackBar.show('已复制: $text');
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
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
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
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // 已连接客户端
          Row(
            children: [
              Icon(Icons.devices, size: 14, 
                   color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                '已连接客户端: ',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${lanState.connectedClientIps.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: lanState.connectedClientIps
                    .map((ip) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Row(
                            children: [
                              Icon(Icons.smartphone, size: 12,
                                   color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 6),
                              Text(ip, style: Theme.of(context).textTheme.bodySmall),
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
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.broadcast_on_personal, size: 16,
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        lanState.isBroadcasting ? '正在广播，其他设备可发现此主机' : '已停止广播',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11,
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
                      AppSnackBar.show(value ? '广播已开启' : '广播已关闭');
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
    if (!lanState.isHost && !lanState.isConnected) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {
          globalState.navigatorKey.currentState?.pop();
          ref.read(lanProvider.notifier).disposeManager();
          AppSnackBar.show(lanState.isHost ? '已停止主机' : '已断开连接');
        },
        icon: Icon(lanState.isHost ? Icons.stop : Icons.wifi_off),
        label: Text(lanState.isHost ? '停止主机' : '断开连接'),
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.onError,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
