import 'package:collection/collection.dart';
import 'package:counters/common/model/base_template.dart';
import 'package:counters/common/model/counter.dart';
import 'package:counters/common/model/landlords.dart';
import 'package:counters/common/model/mahjong.dart';
import 'package:counters/common/model/poker50.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/common/widgets/message_overlay.dart';
import 'package:counters/common/widgets/optimized_list.dart';
import 'package:counters/common/widgets/page_transitions.dart';
import 'package:counters/common/widgets/template_card.dart';
import 'package:counters/features/history/history_page.dart';
import 'package:counters/features/lan/lan_discovery_page.dart';
import 'package:counters/features/lan/lan_provider.dart';
import 'package:counters/features/lan/widgets/lan_status_sheet.dart';
import 'package:counters/features/league/league_list_page.dart';
import 'package:counters/features/score/counter/counter_page.dart';
import 'package:counters/features/score/landlords/landlords_page.dart';
import 'package:counters/features/score/mahjong/mahjong_page.dart';
import 'package:counters/features/score/poker50/poker50_page.dart';
import 'package:counters/features/score/score_provider.dart';
import 'package:counters/features/template/template_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _TemplateSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(templatesProvider);

    return templatesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('加载失败: $err')),
      data: (templates) {
        final userTemplates =
            templates.where((template) => !template.isSystemTemplate).toList();

        return userTemplates.isEmpty
            ? RepaintBoundary(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '暂无可使用的模板\n请先选择系统模板创建自定义模板',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/templates',
                          (route) => false,
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(200, 48),
                        ),
                        child: Text('前往模板管理'),
                      ),
                    ],
                  ),
                ),
              )
            : OptimizedGridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  mainAxisExtent: 150,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: userTemplates.length,
                itemBuilder: (context, index) => SmartListItem(
                  debugLabel: 'TemplateCard_$index',
                  child: TemplateCard(
                    template: userTemplates[index],
                    mode: TemplateCardMode.selection,
                    onTap: () => _handleTemplateSelect(
                        context, ref, userTemplates[index]),
                  ),
                ),
              );
      },
    );
  }

  void _handleTemplateSelect(
      BuildContext context, WidgetRef ref, BaseTemplate template) {
    ref.read(scoreProvider.notifier).startNewGame(template);
    Navigator.of(context).pushReplacement(
      CustomPageTransitions.slideFromRight(
        HomePage.buildSessionPage(template),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      ),
    );
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static Widget buildSessionPage(BaseTemplate template) {
    return _SessionPageLoader(template: template);
  }

  static Widget buildSessionPageFromId(String templateId) {
    return _SessionPageLoader(templateId: templateId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(scoreProvider);
    final lanState = ref.watch(lanProvider);

    return Scaffold(
        appBar: AppBar(
          title: const Text('主页'),
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          automaticallyImplyLeading: false,
        ),
        body: scoreAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('加载失败: $err')),
          data: (scoreState) {
            return _buildHomeWithHistory(context, ref, lanState, scoreState);
          },
        ));
  }

  Widget _buildHomeWithHistory(BuildContext context, WidgetRef ref,
      LanState lanState, ScoreState scoreState) {
    return Column(
      children: [
        _buildEmptyState(context, ref, lanState, scoreState),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref,
      LanState lanState, ScoreState scoreState) {
    final text = '选择模板开始新计分\n或从历史记录中继续';

    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(text,
                style: TextStyle(fontSize: 18), textAlign: TextAlign.center),
            SizedBox(height: 20),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTemplateButton(context),
                SizedBox(height: 12),
                _buildHistoryButton(ref),
                SizedBox(height: 12),
                _buildLeagueButton(context),
                SizedBox(height: 12),
                _buildLanButton(ref, lanState),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: Size(200, 48),
      ),
      onPressed: () => Navigator.of(context).pushWithSlide(
        Scaffold(
          appBar: AppBar(
            title: Text('选择模板'),
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
          ),
          body: _TemplateSelector(),
        ),
        direction: SlideDirection.fromRight,
        duration: const Duration(milliseconds: 300),
      ),
      child: Text('选择计分模板'),
    );
  }

  Widget _buildHistoryButton(WidgetRef ref) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: Size(200, 48),
      ),
      onPressed: () => Navigator.of(ref.context).push(
        MaterialPageRoute(builder: (_) => const HistoryPage()),
      ),
      child: Text('选择历史计分'),
    );
  }

  Widget _buildLeagueButton(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: Size(200, 48),
      ),
      onPressed: () => Navigator.of(context).pushWithSlide(
        const LeagueListPage(),
        direction: SlideDirection.fromRight,
        duration: const Duration(milliseconds: 300),
      ),
      child: Text('联赛管理'),
    );
  }

  Widget _buildLanButton(WidgetRef ref, LanState lanState) {
    final isShowState = lanState.isHost || lanState.isClientMode;
    final buttonText = _getLanButtonText(lanState);

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: Size(200, 48),
      ),
      onPressed: isShowState
          ? () {
              showLanStatusSheet();
            }
          : () {
              Navigator.of(ref.context).pushWithSlide(
                const LanDiscoveryPage(),
                direction: SlideDirection.fromRight,
                duration: const Duration(milliseconds: 300),
              );
            },
      child: Text(buttonText),
    );
  }

  /// 根据 LAN 状态获取按钮文字
  String _getLanButtonText(LanState lanState) {
    if (lanState.isHost) {
      if (lanState.connectedClientIps.isNotEmpty) {
        return '主机模式 (${lanState.connectedClientIps.length}个客户端)';
      } else {
        return '主机模式 (等待连接)';
      }
    } else if (lanState.isClientMode) {
      if (lanState.isConnected) {
        return '客户端模式 (已连接)';
      } else if (lanState.isReconnecting) {
        return '客户端模式 (重连中...)';
      } else {
        return '客户端模式 (已断开)';
      }
    } else {
      return '连接到局域网计分';
    }
  }
}

class _SessionPageLoader extends ConsumerStatefulWidget {
  final BaseTemplate? template;
  final String? templateId;

  const _SessionPageLoader({this.template, this.templateId})
      : assert(template != null || templateId != null);

  @override
  ConsumerState<_SessionPageLoader> createState() => _SessionPageLoaderState();
}

class _SessionPageLoaderState extends ConsumerState<_SessionPageLoader> {
  int _retryCount = 0;

  BaseTemplate? _getTemplate(WidgetRef ref) {
    if (widget.template != null) {
      return widget.template;
    }

    final templatesAsync = ref.watch(templatesProvider);
    return templatesAsync.asData?.value
        .firstWhereOrNull((t) => t.tid == widget.templateId);
  }

  @override
  Widget build(BuildContext context) {
    final template = _getTemplate(ref);
    Log.d(
        '[_SessionPageLoader] Build called. Received template: ${template?.templateName} (ID: ${template?.tid}, Type: ${template?.runtimeType})');

    if (template == null) {
      final lanState = ref.read(lanProvider);
      final isClientMode = lanState.isConnected && !lanState.isHost;

      if (isClientMode) {
        Log.w('客户端模式：等待模板同步，模板ID: ${widget.templateId}');
        if (_retryCount < 10) {
          _retryCount++;
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) setState(() {});
          });
        }
      } else {
        if (_retryCount < 5) {
          _retryCount++;
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              ref.invalidate(templatesProvider);
              ref.read(templatesProvider.notifier).refreshTemplates();
            }
          });
        }
      }
      return Scaffold(
        appBar: AppBar(
          title: const Text('模板同步中'),
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
        ),
        body: const Center(child: Text('正在同步模板信息，请稍候...')),
      );
    }

    Log.d(
        '[_SessionPageLoader] Dispatching based on templateType: ${template.templateType}');
    switch (template.templateType) {
      case Poker50Template.staticTemplateType:
        Log.d('[_SessionPageLoader] -> Poker50SessionPage');
        return Poker50SessionPage(templateId: template.tid);
      case LandlordsTemplate.staticTemplateType:
        Log.d('[_SessionPageLoader] -> LandlordsSessionPage');
        return LandlordsSessionPage(templateId: template.tid);
      case MahjongTemplate.staticTemplateType:
        Log.d('[_SessionPageLoader] -> MahjongPage');
        return MahjongPage(templateId: template.tid);
      case CounterTemplate.staticTemplateType:
        Log.d('[_SessionPageLoader] -> CounterSessionPage');
        return CounterSessionPage(templateId: template.tid);
      default:
        Log.e(
            '[_SessionPageLoader] Unknown template type: ${template.templateType}');
        Future.microtask(() =>
            GlobalMsgManager.showError('未知的模板类型: ${template.templateType}'));
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
          ),
          body: const Center(
            child: Text('错误：未知的模板类型，无法加载计分页面。'),
          ),
        );
    }
  }
}
