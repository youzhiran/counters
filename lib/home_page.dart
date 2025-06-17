import 'package:collection/collection.dart';
import 'package:counters/app/state.dart';
import 'package:counters/common/model/base_template.dart';
import 'package:counters/common/model/counter.dart';
import 'package:counters/common/model/landlords.dart';
import 'package:counters/common/model/mahjong.dart';
import 'package:counters/common/model/player_info.dart';
import 'package:counters/common/model/poker50.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/common/widgets/message_overlay.dart';
import 'package:counters/common/widgets/optimized_list.dart';
import 'package:counters/common/widgets/page_transitions.dart';
import 'package:counters/common/widgets/player_widget.dart';
import 'package:counters/common/widgets/template_card.dart';
import 'package:counters/features/history/history_page.dart';
import 'package:counters/features/lan/lan_discovery_page.dart';
import 'package:counters/features/lan/lan_provider.dart';
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
                        '暂无可使用的模板\n请先在模板管理中创建',
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
        HomePage.buildSessionPage(template, template.tid),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      ),
    );
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static Widget buildSessionPage(BaseTemplate? template, String templateId) {
    return _SessionPageLoader(templateId: templateId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(scoreProvider);
    final lanState = ref.watch(lanProvider);

    return Scaffold(
        appBar: AppBar(
          title: const Text('首页'),
          automaticallyImplyLeading: false,
        ),
        body: scoreAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('加载失败: $err')),
          data: (scoreState) {
            if (scoreState.currentSession?.isCompleted == false) {
              return _buildScoringBoard(context, ref, scoreState);
            } else {
              return _buildHomeWithHistory(context, ref, lanState);
            }
          },
        ));
  }

  Widget _buildHomeWithHistory(
      BuildContext context, WidgetRef ref, LanState lanState) {
    return Column(
      children: [
        _buildEmptyState(context, ref, lanState),
      ],
    );
  }

  Widget _buildEmptyState(
      BuildContext context, WidgetRef ref, LanState lanState) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('没有进行中的游戏', style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTemplateButton(context),
                SizedBox(height: 12),
                _buildHistoryButton(ref),
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
          appBar: AppBar(title: Text('选择模板')),
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
      onPressed: () => Navigator.of(ref.context).pushWithSlide(
        const HistoryPage(),
        direction: SlideDirection.fromRight,
        duration: const Duration(milliseconds: 300),
      ),
      child: Text('选择历史计分'),
    );
  }

  Widget _buildLanButton(WidgetRef ref, LanState lanState) {
    final isDisabled = lanState.isHost || lanState.isClientMode;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: Size(200, 48),
        foregroundColor: isDisabled ? Colors.grey : null,
        side: isDisabled ? BorderSide(color: Colors.grey.shade300) : null,
      ),
      onPressed: isDisabled
          ? null
          : () {
              Navigator.of(ref.context).pushWithSlide(
                const LanDiscoveryPage(),
                direction: SlideDirection.fromRight,
                duration: const Duration(milliseconds: 300),
              );
            },
      child: Text('连接到局域网计分(Beta)'),
    );
  }

  Widget _buildScoringBoard(
      BuildContext context, WidgetRef ref, ScoreState scoreState) {
    final session = scoreState.currentSession!;
    final templatesAsync = ref.watch(templatesProvider);

    return templatesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('加载失败: $err')),
      data: (templates) {
        final template = templates.firstWhere(
          (t) => t.tid == session.templateId,
          orElse: () => _createFallbackTemplate(),
        );

        return Column(
          children: [
            Expanded(
              child: OptimizedListView.builder(
                itemCount: session.scores.length,
                itemBuilder: (context, index) {
                  final score = session.scores[index];
                  final player = template.players.firstWhere(
                    (p) => p.pid == score.playerId,
                    orElse: () {
                      Log.w('找不到玩家ID: ${score.playerId}');
                      return PlayerInfo(
                        pid: 'default_$index',
                        name: '玩家 ${index + 1}',
                        avatar: 'default_avatar.png',
                      );
                    },
                  );
                  return SmartListItem(
                    debugLabel: 'PlayerScore_$index',
                    child: ListTile(
                      leading: PlayerAvatar.build(context, player),
                      title: Text(player.name),
                      subtitle: Text('总得分: ${score.totalScore}'),
                      trailing: () {
                        final lastScore = score.roundScores.lastOrNull;
                        final displayScore = lastScore ?? 0;
                        final prefix = displayScore >= 0 ? '+' : '';
                        return Text('$prefix$displayScore');
                      }(),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding:
                          EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      CustomPageTransitions.slideFromRight(
                        HomePage.buildSessionPage(template, template.tid),
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                      ),
                    ),
                    child: Text('继续本轮', style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding:
                          EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    onPressed: () =>
                        _showEndConfirmation(context, ref, scoreState),
                    child: Text('结束本轮', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            )
          ],
        );
      },
    );
  }

  void _showEndConfirmation(
      BuildContext context, WidgetRef ref, ScoreState scoreState) {
    final hasScores = scoreState.currentSession?.scores
            .any((s) => s.roundScores.isNotEmpty) ??
        false;

    final message =
        hasScores ? '确定要结束当前游戏吗？进度将会保存' : '当前游戏没有任何得分记录，结束后将不会保存到历史记录中';

    final scoreNotifier = ref.read(scoreProvider.notifier);
    final lanNotifier = ref.read(lanProvider.notifier);

    globalState.showCommonDialog(
      child: AlertDialog(
        title: Text('结束本轮游戏'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => globalState.navigatorKey.currentState?.pop(),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () {
              globalState.navigatorKey.currentState?.pop();
              scoreNotifier.resetGame(hasScores);
              lanNotifier.disposeManager();
              ref.showSuccess('已结束当前游戏计分');
            },
            child: Text('确认结束', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Poker50Template _createFallbackTemplate() {
    return Poker50Template(
        templateName: '应急模板',
        playerCount: 3,
        targetScore: 50,
        players: List.generate(
            3,
            (i) => PlayerInfo(
                pid: 'emergency_$i',
                name: '玩家 ${i + 1}',
                avatar: 'default_avatar.png')),
        isAllowNegative: false);
  }
}

class _SessionPageLoader extends ConsumerStatefulWidget {
  final String templateId;

  const _SessionPageLoader({required this.templateId});

  @override
  ConsumerState<_SessionPageLoader> createState() => _SessionPageLoaderState();
}

class _SessionPageLoaderState extends ConsumerState<_SessionPageLoader> {
  int _retryCount = 0;

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(templatesProvider);

    // 使用 LayoutBuilder 确保有正确的布局约束
    return LayoutBuilder(
      builder: (context, constraints) {
        return templatesAsync.when(
          loading: () => Scaffold(
            appBar: AppBar(title: Text('模板同步中')),
            body: const Center(child: Text('正在同步模板信息，请稍候...')),
          ),
          error: (e, s) => Scaffold(
            appBar: AppBar(title: Text('模板加载失败')),
            body: Center(child: Text('模板加载失败: $e')),
          ),
          data: (templates) {
        Log.d('所有模板ID: ${templates.map((t) => t.tid).join(",")}');
        Log.d('buildSessionPage 需要的 templateId: ${widget.templateId}');
        final template =
            templates.firstWhereOrNull((t) => t.tid == widget.templateId);
        if (template == null) {
          // 修复：检查是否为客户端模式，如果是则不要重新加载模板
          final lanState = ref.read(lanProvider);
          final isClientMode = lanState.isConnected && !lanState.isHost;

          if (isClientMode) {
            // 客户端模式下，模板可能还在同步中，等待一下但不要重新加载
            Log.w('客户端模式：等待模板同步，模板ID: ${widget.templateId}');
            if (_retryCount < 10) {
              // 增加重试次数但不重新加载
              _retryCount++;
              Future.delayed(Duration(milliseconds: 500), () {
                if (mounted) {
                  setState(() {}); // 仅触发重建，不重新加载模板
                }
              });
            }
          } else {
            // 主机模式或非联机模式：正常重新加载模板
            if (_retryCount < 5) {
              _retryCount++;
              Future.delayed(Duration(seconds: 2), () {
                if (mounted) {
                  ref.invalidate(templatesProvider);
                  ref.read(templatesProvider.notifier).refreshTemplates();
                }
              });
            }
          }
          return Scaffold(
            appBar: AppBar(title: const Text('模板同步中')),
            body: const Center(child: Text('正在同步模板信息，请稍候...')),
          );
        }
        if (template is Poker50Template) {
          return Poker50SessionPage(templateId: widget.templateId);
        } else if (template is LandlordsTemplate) {
          return LandlordsSessionPage(templateId: widget.templateId);
        } else if (template is MahjongTemplate) {
          return MahjongPage(templateId: widget.templateId);
        } else if (template is CounterTemplate) {
          return CounterSessionPage(templateId: widget.templateId);
        }
        Future.microtask(() => GlobalMsgManager.showError('未知的模板类型'));
        return const HomePage();
          },
        );
      },
    );
  }
}
