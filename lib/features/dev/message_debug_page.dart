import 'package:counters/common/providers/message_provider.dart';
import 'package:counters/common/widgets/message_overlay.dart';
import 'package:counters/common/widgets/toast_message.dart';
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 状态信息 - 更紧凑的设计
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '消息系统状态',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('活跃: ${messageState.activeMessages.length}',
                            style: Theme.of(context).textTheme.bodySmall),
                        Text('历史: ${messageState.messages.length}',
                            style: Theme.of(context).textTheme.bodySmall),
                        Text('计数: $_messageCount',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 基础消息测试组
            _buildSectionHeader('基础消息测试'),

            Row(
              children: [
                Expanded(
                  child: _buildCompactButton(
                    '成功消息',
                    () {
                      _messageCount++;
                      ref.showSuccess('测试成功消息 #$_messageCount');
                    },
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCompactButton(
                    '警告消息',
                    () {
                      _messageCount++;
                      ref.showWarning('测试警告消息 #$_messageCount');
                    },
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _buildCompactButton(
                    '错误消息',
                    () {
                      _messageCount++;
                      ref.showError('测试错误消息 #$_messageCount');
                    },
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCompactButton(
                    '普通消息',
                    () {
                      _messageCount++;
                      ref.showMessage('测试普通消息 #$_messageCount');
                    },
                    color: Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            _buildSectionHeader('专项测试'),

            _buildCompactButton(
              'AppBar遮挡修复测试',
              () {
                _messageCount++;
                ref.showWarning('当前模板已有关联计分记录，保存时需清除该记录 #$_messageCount');
              },
              color: Colors.orange,
              icon: Icons.layers,
            ),
            const SizedBox(height: 6),

            _buildCompactButton(
              '阴影效果优化测试',
              () {
                _messageCount++;
                // 显示多种类型的消息来测试阴影效果
                ref.showSuccess('阴影优化测试 - 成功消息 #$_messageCount');
                Future.delayed(const Duration(milliseconds: 200), () {
                  ref.showWarning('阴影优化测试 - 警告消息 #$_messageCount');
                });
                Future.delayed(const Duration(milliseconds: 400), () {
                  ref.showError('阴影优化测试 - 错误消息 #$_messageCount');
                });
              },
              color: Colors.deepPurple,
              icon: Icons.auto_fix_high,
            ),
            const SizedBox(height: 6),

            _buildCompactButton(
              '阴影残留修复测试',
              () {
                _messageCount++;
                // 显示一个短时间的消息来测试阴影残留问题
                ref.read(messageManagerProvider.notifier).showMessage(
                      '测试阴影残留修复 #$_messageCount - 请观察消息消失时是否有阴影残留',
                      type: MessageType.warning,
                      duration: const Duration(seconds: 3), // 3秒后自动消失
                    );
              },
              color: Colors.redAccent,
              icon: Icons.bug_report,
            ),

            const SizedBox(height: 6),

            Row(
              children: [
                Expanded(
                  child: _buildCompactButton(
                    '淡出动画 (2秒)',
                    () {
                      _messageCount++;
                      // 显示一个短时间的消息来测试淡出动画
                      ref.read(messageManagerProvider.notifier).showMessage(
                            '测试淡出动画 #$_messageCount',
                            type: MessageType.info,
                            duration: const Duration(seconds: 2), // 2秒后自动淡出
                          );
                    },
                    color: Colors.purple,
                    icon: Icons.timer,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCompactButton(
                    'Toast消息',
                    () {
                      _messageCount++;
                      ToastMessage.showSuccess(context, '显示Toast成功消息');
                    },
                    color: Colors.teal,
                    icon: Icons.notifications,
                  ),
                ),
              ],
            ),



            const SizedBox(height: 12),
            _buildSectionHeader('高级测试'),

            _buildCompactButton(
              'Bottom Sheet 消息测试',
              () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (BuildContext context) {
                    return Container(
                      height: MediaQuery.of(context).size.height * 0.6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
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
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 20),
                            Consumer(
                              builder: (context, ref, child) {
                                return Column(
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        _messageCount++;
                                        ref.showSuccess(
                                            'Bottom Sheet 成功消息 #$_messageCount');
                                      },
                                      child:
                                          const Text('在 Bottom Sheet 中显示成功消息'),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: () {
                                        _messageCount++;
                                        ref.showError(
                                            'Bottom Sheet 错误消息 #$_messageCount');
                                      },
                                      child:
                                          const Text('在 Bottom Sheet 中显示错误消息'),
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
              color: Colors.indigo,
              icon: Icons.view_agenda,
            ),
            const SizedBox(height: 6),

            _buildCompactButton(
              '模拟断开重连测试',
              () {
                // 模拟断开重连后的消息显示
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(
                  '/main',
                  (route) => false,
                )
                    .then((_) {
                  // 延迟一下再显示消息，模拟重连后的操作
                  Future.delayed(const Duration(milliseconds: 500), () {
                    _messageCount++;
                    ref.showSuccess('模拟重连后复制IP: 192.168.1.100');
                  });
                });
              },
              color: Colors.amber,
              icon: Icons.wifi_off,
            ),

            const SizedBox(height: 12),
            _buildSectionHeader('控制操作'),

            // 清理按钮
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 36),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () {
                ref
                    .read(messageManagerProvider.notifier)
                    .clearAllActiveMessages();
                setState(() {
                  _messageCount = 0;
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.clear_all, size: 18),
                  SizedBox(width: 8),
                  Text('清除所有活跃消息'),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 消息历史
            if (messageState.messages.isNotEmpty) ...[
              _buildSectionHeader('消息历史'),
              Card(
                margin: EdgeInsets.zero,
                child: Container(
                  height: 300, // 固定高度
                  child: ListView.builder(
                    padding: const EdgeInsets.all(6),
                    itemCount: messageState.messages.length,
                    itemBuilder: (context, index) {
                      final message = messageState
                          .messages[messageState.messages.length - 1 - index];
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        leading: Icon(
                          _getMessageIcon(message.type),
                          size: 18,
                          color: _getMessageColor(message.type),
                        ),
                        title: Text(
                          message.content,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${message.type.name} - ${message.timestamp.toString().substring(11, 19)}',
                          style: const TextStyle(fontSize: 11),
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

  Color _getMessageColor(MessageType type) {
    switch (type) {
      case MessageType.success:
        return Colors.green;
      case MessageType.warning:
        return Colors.orange;
      case MessageType.error:
        return Colors.red;
      case MessageType.info:
        return Colors.blue;
    }
  }

  /// 构建分组标题
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  /// 构建紧凑按钮
  Widget _buildCompactButton(
    String text,
    VoidCallback onPressed, {
    Color? color,
    IconData? icon,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: color != null ? Colors.white : null,
        minimumSize: const Size(double.infinity, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
