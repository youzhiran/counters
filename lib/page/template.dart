import 'package:counters/page/template_config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../providers/score_provider.dart';
import '../providers/template_provider.dart';
import 'game_session.dart';

class TemplateScreen extends StatelessWidget {
  const TemplateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TemplateProvider>(
      builder: (context, provider, _) {
        if (provider.templates.isEmpty) {
          return Center(child: CircularProgressIndicator());
        }

        final templates = provider.templates;
        return GridView.builder(
          padding: EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200, // 卡片最大宽度
            mainAxisExtent: 150, // 直接指定卡片高度
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: templates.length,
          itemBuilder: (context, index) =>
              _TemplateCard(template: templates[index]),
        );
      },
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final ScoreTemplate template;

  const _TemplateCard({required this.template});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 1, // MD3默认较低海拔
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // MD3更大圆角
      ),
      color: colorScheme.surfaceContainerLow, // 使用表面容器颜色
      child: InkWell(
        onTap: () => _handleTap(context),
        borderRadius: BorderRadius.circular(12),
        overlayColor: WidgetStatePropertyAll(
            colorScheme.primary.withValues(alpha: 0.1)), // 新涟漪效果
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      template.templateName,
                      style:
                          Theme.of(context).textTheme.titleMedium, // 使用MD3文字样式
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('玩家数量: ${template.playerCount}',
                      style: Theme.of(context).textTheme.bodyMedium),
                  Text('目标分数: ${template.targetScore}',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: template.isSystemTemplate
                  ? Icon(Icons.lock_outline, // 使用outline图标
                      color: colorScheme.primary)
                  : Icon(Icons.edit_outlined, color: colorScheme.secondary),
            ),
            Positioned(
              left: 12,
              bottom: 8,
              child: template.isSystemTemplate
                  ? Text('系统模板',
                      style: TextStyle(
                          fontSize: 10, color: colorScheme.onSurfaceVariant))
                  : Text('基于: ${_getRootBaseTemplateName(context)}',
                      style: TextStyle(
                          fontSize: 10, color: colorScheme.onSurfaceVariant)),
            ),
          ],
        ),
      ),
    );
  }

  // 添加获取根基础模板的方法
  String _getRootBaseTemplateName(BuildContext context) {
    String? baseId = template.baseTemplateId;
    ScoreTemplate? current =
        context.read<TemplateProvider>().getTemplate(baseId ?? '');

    // 递归查找直到系统模板
    while (current != null && !current.isSystemTemplate) {
      baseId = current.baseTemplateId;
      current = context.read<TemplateProvider>().getTemplate(baseId ?? '');
    }

    return current?.templateName ?? '系统模板';
  }

  // 添加删除确认对话框
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: const Text('删除模板'),
        content: const Text('确定要永久删除此模板吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton.tonal(
            // 使用填充按钮
            onPressed: () {
              context.read<TemplateProvider>().deleteTemplate(template.id);
              Navigator.pop(context);
            },
            child: Text('删除',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _handleTap(BuildContext context) {
    final isSystem = template.isSystemTemplate;
    showModalBottomSheet(
      // 改为底部动作面板
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(isSystem ? Icons.copy : Icons.edit_note),
              title: Text(isSystem ? '另存新模板' : '编辑模板'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TemplateConfigScreen(baseTemplate: template),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.play_circle_outline),
              title: const Text('开始计分'),
              onTap: () {
                context.read<ScoreProvider>().startNewGame(template);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GameSessionScreen(templateId: template.id),
                  ),
                );
              },
            ),
            if (!isSystem) ...[
              const Divider(),
              ListTile(
                leading: Icon(Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error),
                title: Text('删除模板',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
