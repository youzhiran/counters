import 'package:counters/model/landlords.dart';
import 'package:counters/page/poker50/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/base_template.dart';
import '../model/poker50.dart';
import '../providers/score_provider.dart';
import '../providers/template_provider.dart';
import '../state.dart';
import '../utils/log.dart';
import 'home.dart';
import 'landlords/config.dart';

class TemplatePage extends ConsumerStatefulWidget {
  const TemplatePage({super.key});

  @override
  ConsumerState<TemplatePage> createState() => _TemplatePageState();
}

class _TemplatePageState extends ConsumerState<TemplatePage> {
  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(templatesProvider);

    return templatesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('加载失败: $err')),
      data: (templates) {
        if (templates.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(templatesProvider),
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              mainAxisExtent: 150,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: templates.length,
            itemBuilder: (context, index) =>
                _TemplateCard(template: templates[index]),
          ),
        );
      },
    );
  }
}

class _TemplateCard extends ConsumerWidget {
  final BaseTemplate template;

  const _TemplateCard({required this.template});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 0,
      shape: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        onTap: () => _handleTap(context, ref),
        borderRadius: BorderRadius.circular(8.0),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      template.templateName,
                      style: const TextStyle(fontSize: 18),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                  ? const Icon(Icons.lock, color: Colors.blue)
                  : const Icon(Icons.edit, color: Colors.green),
            ),
            Positioned(
              left: 6,
              bottom: 6,
              child: template.isSystemTemplate
                  ? const Text('系统模板',
                      style: TextStyle(fontSize: 10, color: Colors.grey))
                  : Text('基于: ${_getRootBaseTemplateName(ref)}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  // 添加获取根基础模板的方法
  String _getRootBaseTemplateName(WidgetRef ref) {
    String? baseId = template.baseTemplateId;
    final templatesData = ref.read(templatesProvider).valueOrNull;
    if (templatesData == null) return '系统模板';

    BaseTemplate? current = templatesData.firstWhere((t) => t.tid == baseId,
        orElse: () => templatesData.first);

    // 递归查找直到系统模板
    while (current != null && !current.isSystemTemplate) {
      baseId = current.baseTemplateId;
      current = templatesData.firstWhere((t) => t.tid == baseId,
          orElse: () => templatesData.first);
    }

    return current?.templateName ?? '系统模板';
  }

  // 添加删除确认对话框
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final scoreNotifier = ref.read(scoreProvider.notifier);
    final currentSession = ref.read(scoreProvider).value?.currentSession;

    // 使用新方法检查模板是否正在计分
    if (currentSession != null) {
      globalState.showCommonDialog(
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
    } else if (await scoreNotifier.checkSessionExists(template.tid)) {
      globalState.showCommonDialog(
        child: AlertDialog(
          title: const Text('删除模板'),
          content: const Text('当前模板已有关联计分记录，会同步清除所有关联记录。\n是否继续删除？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                ref
                    .read(templatesProvider.notifier)
                    .deleteTemplate(template.tid);
                scoreNotifier.clearSessionsByTemplate(template.tid);
                Navigator.pop(context);
              },
              child:
                  const Text('删除并清除关联计分', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } else {
      globalState.showCommonDialog(
        child: AlertDialog(
          title: const Text('删除模板'),
          content: const Text('确定要永久删除此模板吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                ref
                    .read(templatesProvider.notifier)
                    .deleteTemplate(template.tid);
                Navigator.pop(context);
              },
              child: const Text('删除', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }
  }

  void _handleTap(BuildContext context, WidgetRef ref) {
    if (template.isSystemTemplate) {
      globalState.showCommonDialog(
        child: AlertDialog(
          title: const Text('系统模板操作'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('另存新模板'),
                leading: const Icon(Icons.edit),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) {
                        if (template is Poker50Template) {
                          return Poker50ConfigPage(
                              oriTemplate: template as Poker50Template);
                        } else if (template is LandlordsTemplate) {
                          return LandlordsConfigPage(
                              oriTemplate: template as LandlordsTemplate);
                        } else {
                          Log.w('不支持的模板类型: ${template.runtimeType}');
                          return const SizedBox.shrink();
                        }
                      },
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
          title: const Text('用户模板操作'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('编辑模板'),
                leading: const Icon(Icons.edit),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) {
                        if (template is Poker50Template) {
                          return Poker50ConfigPage(
                              oriTemplate: template as Poker50Template);
                        } else if (template is LandlordsTemplate) {
                          return LandlordsConfigPage(
                              oriTemplate: template as LandlordsTemplate);
                        } else {
                          Log.w('不支持的模板类型: ${template.runtimeType}');
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                  );
                },
              ),
              ListTile(
                title: const Text('开始计分'),
                leading: const Icon(Icons.play_arrow),
                onTap: () {
                  ref.read(scoreProvider.notifier).startNewGame(template);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          HomePage.buildSessionPage(template, template.tid),
                    ),
                  );
                },
              ),
              ListTile(
                title: const Text('删除模板', style: TextStyle(color: Colors.red)),
                leading: const Icon(Icons.delete, color: Colors.red),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, ref);
                },
              ),
            ],
          ),
        ),
      );
    }
  }
}
