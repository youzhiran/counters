import 'package:counters/common/widgets/message_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard

class IpDisplayWidget extends StatelessWidget {
  final String localIp;
  final String interfaceName; // 新增：接口名称
  final VoidCallback onRefreshIp;

  const IpDisplayWidget({
    super.key,
    required this.localIp,
    required this.interfaceName,
    required this.onRefreshIp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '你的IP地址: $localIp ($interfaceName)',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('复制IP'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: localIp));
                  GlobalMsgManager.showMessage('IP地址已复制');
                },
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('刷新IP'),
                onPressed: onRefreshIp,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
