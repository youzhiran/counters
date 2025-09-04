import 'package:counters/app/state.dart';
import 'package:counters/common/model/base_template.dart';
import 'package:counters/common/model/counter.dart';
import 'package:counters/common/model/landlords.dart';
import 'package:counters/common/model/mahjong.dart';
import 'package:counters/common/model/player_info.dart';
import 'package:counters/common/model/poker50.dart';
import 'package:counters/common/utils/error_handler.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/common/utils/util.dart';
import 'package:counters/common/widgets/page_transitions.dart';
import 'package:counters/features/score/counter/config.dart';
import 'package:counters/features/score/landlords/config.dart';
import 'package:counters/features/score/mahjong/config.dart';
import 'package:counters/features/score/poker50/config.dart';
import 'package:counters/features/score/score_provider.dart';
import 'package:counters/features/template/template_provider.dart';
import 'package:counters/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// 可复用的模板卡片组件
///
/// 支持两种模式：
/// - [TemplateCardMode.management] - 模板管理模式，支持编辑、删除等操作
/// - [TemplateCardMode.selection] - 模板选择模式，点击直接开始计分
class TemplateCard extends ConsumerWidget {
  final BaseTemplate template;
  final TemplateCardMode mode;
  final VoidCallback? onTap;

  const TemplateCard({
    super.key,
    required this.template,
    this.mode = TemplateCardMode.management,
    this.onTap,
  });

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
        onTap: onTap ?? () => _handleTap(context, ref),
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
            // 右上角图标 - 仅在管理模式下显示
            if (mode == TemplateCardMode.management)
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
        SvgIconUtils.pokerCards,
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
    } else if (template is CounterTemplate) {
      return SvgIconUtils.getIcon(
        SvgIconUtils.counter,
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

  // 获取根基础模板的方法
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

  void _handleTap(BuildContext context, WidgetRef ref) {
    switch (mode) {
      case TemplateCardMode.management:
        _handleManagementTap(context, ref);
        break;
      case TemplateCardMode.selection:
        _handleSelectionTap(context, ref);
        break;
    }
  }

  // 管理模式的点击处理
  void _handleManagementTap(BuildContext context, WidgetRef ref) {
    if (template.isSystemTemplate) {
      globalState.showCommonDialog(
        child: AlertDialog(
          title: const Text('系统模板操作'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('快速体验'),
                leading: const Icon(Icons.flash_on),
                onTap: () {
                  globalState.navigatorKey.currentState?.pop();
                  _handleQuickStart(context, ref);
                },
              ),
              ListTile(
                title: const Text('另存新模板'),
                leading: const Icon(Icons.edit),
                onTap: () {
                  globalState.navigatorKey.currentState?.pop();
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
                  _navigateToConfigPage(context, ref, template);
                },
              ),
              ListTile(
                title: const Text('开始计分'),
                leading: const Icon(Icons.play_arrow),
                onTap: () async {
                  ref.read(scoreProvider.notifier).startNewGame(template);
                  if (!context.mounted) return;
                  Navigator.of(context).pushReplacement(
                    CustomPageTransitions.slideFromRight(
                      HomePage.buildSessionPage(template),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                  );
                },
              ),
              ListTile(
                title: const Text('删除模板', style: TextStyle(color: Colors.red)),
                leading: const Icon(Icons.delete, color: Colors.red),
                onTap: () async {
                  globalState.navigatorKey.currentState?.pop();
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

  // 选择模式的点击处理
  void _handleSelectionTap(BuildContext context, WidgetRef ref) {
    ref.read(scoreProvider.notifier).startNewGame(template);
    Navigator.of(context).pushReplacement(
      CustomPageTransitions.slideFromRight(
        HomePage.buildSessionPage(template),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
    );
  }

  // 删除确认对话框
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final scoreNotifier = ref.read(scoreProvider.notifier);
    final scoreState = await ref.read(scoreProvider.future);
    final templateNotifier = ref.read(templatesProvider.notifier);

    // 检查是否被联赛引用
    final leaguesUsingTemplate =
        await templateNotifier.getLeaguesUsingTemplate(template.tid);
    if (leaguesUsingTemplate.isNotEmpty) {
      if (!context.mounted) return;
      final leagueList = leaguesUsingTemplate.join('、');
      _showErrorDialog(
          context, '无法删除该模板', '该模板正在被以下联赛使用，请先结束联赛并删除：\n\n$leagueList');
      return;
    }

    // 检查是否正在计分
    if (template.tid == scoreState.currentSession?.templateId) {
      if (!context.mounted) return;
      _showErrorDialog(context, '无法删除该模板', '该模板正在计分，请结束计分后删除。');
      return;
    }

    // 检查是否有历史记录
    if (await scoreNotifier.checkSessionExists(template.tid)) {
      if (!context.mounted) return;
      globalState.showCommonDialog(
        child: AlertDialog(
          title: const Text('删除模板'),
          content: const Text('当前模板已有关联计分记录，会同步清除所有关联记录.\n是否继续删除？'),
          actions: [
            TextButton(
              onPressed: () => globalState.navigatorKey.currentState?.pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                await templateNotifier.deleteTemplate(template.tid);
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
                await templateNotifier.deleteTemplate(template.tid);
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

  // 显示错误对话框的辅助方法
  void _showErrorDialog(BuildContext context, String title, String content) {
    globalState.showCommonDialog(
      child: AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => globalState.navigatorKey.currentState?.pop(),
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  // 快速体验处理方法
  void _handleQuickStart(BuildContext context, WidgetRef ref) {
    // 提前获取 Notifier，避免在回调中使用 ref
    final templatesNotifier = ref.read(templatesProvider.notifier);
    final scoreNotifier = ref.read(scoreProvider.notifier);

    globalState.showCommonDialog(
      child: AlertDialog(
        title: const Text('快速体验'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('即将使用以下设置开始计分：'),
            const SizedBox(height: 12),
            Text('• 模板：${template.templateName}'),
            Text('• 玩家数量：${template.playerCount}'),
            Text('• 目标分数：${template.targetScore}'),
            Text(
                '• 玩家名称：${_generatePlayerNames(template.playerCount).join('、')}'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha((0.1 * 255).toInt()),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withAlpha((0.3 * 255).toInt()),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 16),
                      SizedBox(width: 4),
                      Text('注意事项',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text('• 此模式下的计分数据为临时数据，仅适用于快速体验，无确认胜负功能',
                      style: TextStyle(fontSize: 12)),
                  Text('• 退出计分界面后，所有数据将自动丢失', style: TextStyle(fontSize: 12)),
                  Text('• 如需正常计分，请使用"另存新模板"功能', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => globalState.navigatorKey.currentState?.pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              globalState.navigatorKey.currentState?.pop();
              await _startQuickGame(templatesNotifier, scoreNotifier);
            },
            child: const Text('开始计分'),
          ),
        ],
      ),
    );
  }

  // 生成默认玩家名称
  List<String> _generatePlayerNames(int playerCount) {
    return List.generate(playerCount, (index) => '玩家${index + 1}');
  }

  // 开始快速计分
  Future<void> _startQuickGame(
    Templates templatesNotifier,
    Score scoreNotifier,
  ) async {
    try {
      // 创建临时模板副本，使用默认玩家信息
      final tempTemplate = _createTempTemplate();

      // 将临时模板添加到模板提供者中（仅在内存中）
      await templatesNotifier.addTempTemplate(tempTemplate);

      // 开始临时计分会话
      scoreNotifier.startTempGame(tempTemplate);

      // 使用全局 navigator key 进行导航，避免使用可能已失效的 context
      globalState.navigatorKey.currentState?.push(
        CustomPageTransitions.slideFromRight(
          HomePage.buildSessionPage(tempTemplate),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ),
      );
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '快速体验失败');
    }
  }

  // 创建临时模板
  BaseTemplate _createTempTemplate() {
    // 生成默认玩家信息
    final defaultPlayers = List.generate(
      template.playerCount,
      (index) => PlayerInfo(
        name: '玩家${index + 1}',
        avatar: 'default_avatar.png',
      ),
    );

    // 创建临时模板副本
    return template.copyWith(
      tid: 'temp_${const Uuid().v4()}',
      players: defaultPlayers,
      isSystemTemplate: false,
    );
  }

  // 导航到配置页面的方法
  void _navigateToConfigPage(
      BuildContext context, WidgetRef ref, BaseTemplate template) {
    Widget configPage;
    switch (template) {
      case Poker50Template():
        configPage = Poker50ConfigPage(oriTemplate: template);
        break;
      case LandlordsTemplate():
        configPage = LandlordsConfigPage(oriTemplate: template);
        break;
      case MahjongTemplate():
        configPage = MahjongConfigPage(oriTemplate: template);
        break;
      case CounterTemplate():
        configPage = CounterConfigPage(oriTemplate: template);
        break;
      default:
        Log.w('不支持的模板类型: ${template.runtimeType}');
        return;
    }

    globalState.navigatorKey.currentState?.pushWithSlide(
      configPage,
      direction: SlideDirection.fromRight,
      duration: const Duration(milliseconds: 300),
    );
  }
}

/// 模板卡片的显示模式
enum TemplateCardMode {
  /// 管理模式 - 显示编辑、删除等操作
  management,

  /// 选择模式 - 点击直接开始计分
  selection,
}
