import 'package:counters/page/template_config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/models.dart';
import '../providers/score_provider.dart';
import '../providers/template_provider.dart';
import '../state.dart';
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
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0), // 默认卡片圆角值
      ),
      child: InkWell(
        onTap: () => _handleTap(context),
        borderRadius: BorderRadius.circular(8.0),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      template.templateName,
                      style: TextStyle(fontSize: 18),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('玩家数量: ${template.playerCount}'),
                  Text('目标分数: ${template.targetScore}'),
                ],
              ),
            ),
            // 其他装饰性元素
            Positioned(
              right: 8,
              top: 8,
              child: template.isSystemTemplate
                  ? Icon(Icons.lock, color: Colors.blue)
                  : Icon(Icons.edit, color: Colors.green),
            ),
            Positioned(
              left: 6,
              bottom: 6,
              child: template.isSystemTemplate
                  ? Text('系统模板',
                      style: TextStyle(fontSize: 10, color: Colors.grey))
                  : Text('基于: ${_getRootBaseTemplateName(context)}',
                      style: TextStyle(fontSize: 10, color: Colors.grey)),
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
    final provider = context.read<ScoreProvider>();
    if (provider.currentSession != null) {
      globalState.showCommonDialog<bool>(
        child: AlertDialog(
          title: const Text('删除模板'),
          content: const Text('无法删除该模板，当前模板正在计分，请结束计分后再删除！'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('确认'),
            ),
          ],
        ),
      );
    } else if (provider.checkSessionExists(template.id)) {
      globalState.showCommonDialog(
        child: AlertDialog(
          title: Text('删除模板'),
          content: Text('当前模板已有关联计分记录，会同步清除所有关联记录。\n是否继续删除？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () {
                context.read<TemplateProvider>().deleteTemplate(template.id);
                provider.clearSessionsByTemplate(template.id);
                Navigator.pop(context);
              },
              child: Text('删除并清除关联计分', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } else {
      globalState.showCommonDialog(
        child: AlertDialog(
          title: Text('删除模板'),
          content: Text('确定要永久删除此模板吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () {
                context.read<TemplateProvider>().deleteTemplate(template.id);
                Navigator.pop(context);
              },
              child: Text('删除', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }
  }

  void _handleTap(BuildContext context) {
    if (template.isSystemTemplate) {
      globalState.showCommonDialog(
        child: AlertDialog(
          title: Text('系统模板操作'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('另存新模板'),
                leading: Icon(Icons.edit),
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
                title: Text('开始计分'),
                leading: Icon(Icons.play_arrow),
                onTap: () {
                  context.read<ScoreProvider>().startNewGame(template);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          GameSessionScreen(templateId: template.id),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    } else {
      globalState.showCommonDialog(
        child: AlertDialog(
          title: Text('用户模板操作'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('编辑模板'),
                leading: Icon(Icons.edit),
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
                title: Text('开始计分'),
                leading: Icon(Icons.play_arrow),
                onTap: () {
                  context.read<ScoreProvider>().startNewGame(template);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          GameSessionScreen(templateId: template.id),
                    ),
                  );
                },
              ),
              ListTile(
                title: Text('删除模板', style: TextStyle(color: Colors.red)),
                leading: Icon(Icons.delete, color: Colors.red),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context);
                },
              ),
            ],
          ),
        ),
      );
    }
  }
}
