import 'package:counters/app/state.dart';
import 'package:counters/common/model/base_template.dart';
import 'package:counters/common/model/counter.dart';
import 'package:counters/common/model/landlords.dart';
import 'package:counters/common/model/mahjong.dart';
import 'package:counters/common/model/poker50.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/common/utils/util.dart';
import 'package:counters/features/score/counter/config.dart';
import 'package:counters/features/score/landlords/config.dart';
import 'package:counters/features/score/mahjong/config.dart';
import 'package:counters/features/score/poker50/config.dart';
import 'package:counters/features/score/score_provider.dart';
import 'package:counters/features/template/template_provider.dart';
import 'package:counters/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TemplatePage extends ConsumerStatefulWidget {
  const TemplatePage({super.key});

  @override
  ConsumerState<TemplatePage> createState() => _TemplatePageState();
}

class _TemplatePageState extends ConsumerState<TemplatePage> {
  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(templatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('模板'),
        automaticallyImplyLeading: false,
      ),
      body: templatesAsync.when(
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
      ),
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
          color: Theme.of(context)
              .colorScheme
              .outline
              .withAlpha((0.2 * 255).toInt()),
        ),
      ),
      child: InkWell(
        onTap: () => _handleTap(context, ref),
        borderRadius: BorderRadius.circular(8.0),
        child: Stack(
          children: [
            // 背景图标
            Positioned(
              right: -5,
              bottom: -5,
              child: _getTemplateIcon(context),
            ),
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

  Widget _getTemplateIcon(BuildContext context) {
    if (template is Poker50Template) {
      return SvgIconUtils.getIcon(
        SvgIconUtils.poker_cards,
        size: 100,
        color: Theme.of(context).colorScheme.primary,
        opacity: 0.1,
      );
    } else if (template is LandlordsTemplate) {
      return SvgIconUtils.getIcon(
        SvgIconUtils.gardener,
        size: 100,
        color: Theme.of(context).colorScheme.primary,
        opacity: 0.1,
      );
    } else if (template is MahjongTemplate) {
      return SvgIconUtils.getIcon(
        SvgIconUtils.mahjong,
        size: 100,
        color: Theme.of(context).colorScheme.primary,
        opacity: 0.1,
      );
    }
    return Icon(
      Icons.games,
      size: 100,
      color: Theme.of(context).colorScheme.primary.withAlpha(25),
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

    // 直接获取当前状态（不监听变化），等待scoreProvider加载完成
    final scoreState = await ref.read(scoreProvider.future);

    if (template.tid == scoreState.currentSession?.templateId) {
      if (!context.mounted) return;
      globalState.showCommonDialog(
        child: AlertDialog(
          title: const Text('无法删除该模板'),
          content: const Text('该模板正在计分，请结束计分后删除。'),
          actions: [
            TextButton(
              onPressed: () => globalState.navigatorKey.currentState?.pop(),
              child: const Text('确认'),
            ),
          ],
        ),
      );
      return;
    }

    if (await scoreNotifier.checkSessionExists(template.tid)) {
      if (!context.mounted) return;
      globalState.showCommonDialog(
        child: AlertDialog(
          title: const Text('删除模板'),
          content: const Text('当前模板已有关联计分记录，会同步清除所有关联记录。\n是否继续删除？'),
          actions: [
            TextButton(
              onPressed: () => globalState.navigatorKey.currentState?.pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                await ref
                    .read(templatesProvider.notifier)
                    .deleteTemplate(template.tid);
                await scoreNotifier.clearSessionsByTemplate(template.tid);
                if (!context.mounted) return;
                globalState.navigatorKey.currentState?.pop();
              },
              child:
                  const Text('删除并清除关联计分', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } else {
      if (!context.mounted) return;
      globalState.showCommonDialog(
        child: AlertDialog(
          title: const Text('删除模板'),
          content: const Text('确定要永久删除此模板吗？'),
          actions: [
            TextButton(
              onPressed: () => globalState.navigatorKey.currentState?.pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                await ref
                    .read(templatesProvider.notifier)
                    .deleteTemplate(template.tid);
                if (!context.mounted) return;
                globalState.navigatorKey.currentState?.pop();
              },
              child: const Text('删除', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }
  }

  // 提取重复的导航逻辑到配置页面的方法
  void _navigateToConfigPage(
      BuildContext context, WidgetRef ref, BaseTemplate template) {
    globalState.navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) {
          // 使用 switch 语句和类型模式匹配来导航
          switch (template) {
            case Poker50Template():
              return Poker50ConfigPage(oriTemplate: template);
            case LandlordsTemplate():
              return LandlordsConfigPage(oriTemplate: template);
            case MahjongTemplate():
              return MahjongConfigPage(oriTemplate: template);
            case CounterTemplate():
              return CounterConfigPage(oriTemplate: template);
            default:
              Log.w('不支持的模板类型: ${template.runtimeType}');
              return const SizedBox.shrink();
          }
        },
      ),
    );
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
                  globalState.navigatorKey.currentState?.pop();
                  // 调用提取出的导航方法
                  _navigateToConfigPage(context, ref, template);
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
                  globalState.navigatorKey.currentState?.pop();
                  // 调用提取出的导航方法
                  _navigateToConfigPage(context, ref, template);
                },
              ),
              ListTile(
                title: const Text('开始计分'),
                leading: const Icon(Icons.play_arrow),
                onTap: () async {
                  // 获取当前状态，等待scoreProvider加载完成
                  final scoreState = await ref.watch(scoreProvider.future);

                  // 添加 mounted 检查
                  if (!context.mounted) return;

                  if (scoreState.currentSession != null) {
                    globalState.showCommonDialog(
                      child: AlertDialog(
                        title: const Text('无法开始新计分'),
                        content: const Text('当前已有正在进行的计分，请先完成当前计分后再开始新的计分。'),
                        actions: [
                          TextButton(
                            child: const Text('确认'),
                            onPressed: () => globalState
                                .navigatorKey.currentState
                                ?.pop(context),
                          ),
                        ],
                      ),
                    );
                    return;
                  }
                  ref.read(scoreProvider.notifier).startNewGame(template);
                  if (!context.mounted) return;
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
                onTap: () async {
                  // 先关闭当前弹窗
                  globalState.navigatorKey.currentState?.pop();

                  // 使用globalState.navigatorKey.currentContext来获取当前有效的context
                  if (globalState.navigatorKey.currentContext != null) {
                    _confirmDelete(
                        globalState.navigatorKey.currentContext!, ref);
                  }
                },
              ),
            ],
          ),
        ),
      );
    }
  }
}
