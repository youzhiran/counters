import 'package:counters/state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../db/poker50.dart';
import '../providers/template_provider.dart';
import '../utils/date_formatter.dart';
import 'confirmation_dialog.dart';

class HistorySessionItem extends StatelessWidget {
  final GameSession session;
  final VoidCallback onDelete;
  final VoidCallback onResume;

  const HistorySessionItem({
    super.key,
    required this.session,
    required this.onDelete,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    final template =
        context.read<TemplateProvider>().getTemplateBySession(session);

    return Dismissible(
      key: Key(session.id),
      background: _buildDeleteBackground(),
      confirmDismiss: (direction) => _confirmDismiss(direction, context),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(
          template?.templateName ?? "未知模板",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: _buildSessionSubtitle(),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () async {
            final confirm = await globalState.showCommonDialog(
              child: ConfirmationDialog(
                title: '确认删除',
                content: '确定要删除这条记录吗？',
                confirmText: '删除',
              ),
            );
            if (confirm == true) onDelete();
          },
        ),
        onTap: onResume,
      ),
    );
  }

  // 提取子组件方法
  Widget _buildDeleteBackground() => Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      );

  // 滑动删除
  Future<bool?> _confirmDismiss(
      DismissDirection direction, BuildContext context) async {
    return await globalState.showCommonDialog(
      child: ConfirmationDialog(
        title: '确认删除',
        content: '确定要删除这条记录吗？',
        confirmText: '删除',
      ),
    );
  }

  Widget _buildSessionSubtitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(DateFormatter.format(session.startTime)),
        if (session.endTime != null)
          Text(DateFormatter.format(session.endTime!)),
        Text(
          "状态：${session.isCompleted ? '已完成' : '进行中'}",
          style: TextStyle(
            color: session.isCompleted ? Colors.green : Colors.orange,
          ),
        ),
      ],
    );
  }
}
