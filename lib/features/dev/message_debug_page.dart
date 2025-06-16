import 'package:counters/common/providers/message_provider.dart';
import 'package:counters/common/widgets/message_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 消息系统调试页面
/// 用于测试和调试消息显示问题
class MessageDebugPage extends ConsumerStatefulWidget {
  const MessageDebugPage({super.key});

  @override
  ConsumerState<MessageDebugPage> createState() => _MessageDebugPageState();
}

class _MessageDebugPageState extends ConsumerState<MessageDebugPage> {
  int _messageCount = 0;

  @override
  Widget build(BuildContext context) {
    final messageState = ref.watch(messageManagerProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('消息系统调试'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 状态信息
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '消息系统状态',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('当前消息: ${messageState.currentMessage?.content ?? "无"}'),
                    Text('消息历史数量: ${messageState.messages.length}'),
                    Text('消息计数器: $_messageCount'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 测试按钮
            Text(
              '测试按钮',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: () {
                _messageCount++;
                ref.showSuccess('测试成功消息 #$_messageCount');
              },
              child: const Text('显示成功消息'),
            ),
            const SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: () {
                _messageCount++;
                ref.showWarning('测试警告消息 #$_messageCount');
              },
              child: const Text('显示警告消息'),
            ),
            const SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: () {
                _messageCount++;
                ref.showError('测试错误消息 #$_messageCount');
              },
              child: const Text('显示错误消息'),
            ),
            const SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: () {
                _messageCount++;
                ref.showMessage('测试普通消息 #$_messageCount');
              },
              child: const Text('显示普通消息'),
            ),
            
            const SizedBox(height: 20),
            
            // Bottom Sheet 测试
            ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (BuildContext context) {
                    return Container(
                      height: MediaQuery.of(context).size.height * 0.6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const Text(
                              'Bottom Sheet 测试',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 20),
                            Consumer(
                              builder: (context, ref, child) {
                                return Column(
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        _messageCount++;
                                        ref.showSuccess('Bottom Sheet 成功消息 #$_messageCount');
                                      },
                                      child: const Text('在 Bottom Sheet 中显示成功消息'),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: () {
                                        _messageCount++;
                                        ref.showError('Bottom Sheet 错误消息 #$_messageCount');
                                      },
                                      child: const Text('在 Bottom Sheet 中显示错误消息'),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text('关闭 Bottom Sheet'),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              child: const Text('测试 Bottom Sheet 中的消息'),
            ),
            
            const SizedBox(height: 20),
            
            // 清理按钮
            OutlinedButton(
              onPressed: () {
                ref.read(messageManagerProvider.notifier).clearAllMessages();
                setState(() {
                  _messageCount = 0;
                });
              },
              child: const Text('清除所有消息'),
            ),

            const SizedBox(height: 12),

            // 模拟局域网断开重连测试
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                // 模拟断开重连后的消息显示
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/main',
                  (route) => false,
                ).then((_) {
                  // 延迟一下再显示消息，模拟重连后的操作
                  Future.delayed(const Duration(milliseconds: 500), () {
                    _messageCount++;
                    ref.showSuccess('模拟重连后复制IP: 192.168.1.100');
                  });
                });
              },
              child: const Text('模拟断开重连测试'),
            ),
            
            const SizedBox(height: 20),
            
            // 消息历史
            if (messageState.messages.isNotEmpty) ...[
              Text(
                '消息历史',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Card(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: messageState.messages.length,
                    itemBuilder: (context, index) {
                      final message = messageState.messages[messageState.messages.length - 1 - index];
                      return ListTile(
                        dense: true,
                        leading: Icon(_getMessageIcon(message.type)),
                        title: Text(message.content),
                        subtitle: Text(
                          '${message.type.name} - ${message.timestamp.toString().substring(11, 19)}',
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  IconData _getMessageIcon(MessageType type) {
    switch (type) {
      case MessageType.success:
        return Icons.check_circle;
      case MessageType.warning:
        return Icons.warning;
      case MessageType.error:
        return Icons.error;
      case MessageType.info:
        return Icons.info;
    }
  }
}
