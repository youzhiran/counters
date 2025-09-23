import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:counters/common/model/base_template.dart';
import 'package:counters/common/model/counter.dart';
import 'package:counters/common/model/game_session.dart';
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

/// 主页快捷卡固定“彩色”色板（不跟随主题色）
const List<Color> kActionColors = <Color>[
  Color(0xFF6C8EF5), // 蓝
  Color(0xFFFF8A65), // 橙
  Color(0xFF26A69A), // 青
  Color(0xFF7E57C2), // 紫
  Color(0xFFFFCA28), // 黄
];

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
            final quickActions =
                _buildQuickActions(context, ref, lanState, scoreState);
            // 主页“进行中对局”仅展示非联赛对局
            final ongoingSessions = scoreState.ongoingSessions
                .where((s) => s.leagueMatchId == null)
                .toList();

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: _buildHeroSection(context, scoreState, lanState),
                    ),
                  ),
                ),
                if (quickActions.isNotEmpty)
                  SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 250,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.05,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _QuickActionCard(
                          action: quickActions[index],
                        ),
                        childCount: quickActions.length,
                      ),
                    ),
                  ),
                if (ongoingSessions.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: _buildOngoingSection(context, ref),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 24 + MediaQuery.of(context).padding.bottom,
                  ),
                ),
              ],
            );
          },
        ));
  }

  Widget _buildHeroSection(BuildContext context,
      ScoreState scoreState,
      LanState lanState,) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // 主页不展示联赛对局的续玩提示
    final currentSessionExists = scoreState.currentSession != null &&
        scoreState.currentSession!.leagueMatchId == null &&
        scoreState.ongoingSessions.any((s) =>
            s.sid == scoreState.currentSession!.sid && s.leagueMatchId == null);

    final templateName = scoreState.template?.templateName;
    final headline = currentSessionExists && templateName != null
        ? '继续「$templateName」'
        : '欢迎使用得益计分';
    final description = currentSessionExists && templateName != null
        ? '上次停留在第${scoreState.currentRound}轮，随时可以恢复。'
        : '挑选模板创建新对局，或快速回到历史记录。';
    // 顶部文案“进行中”数量也排除联赛场次
    final nonLeagueCount =
        scoreState.ongoingSessions.where((s) => s.leagueMatchId == null).length;
    final ongoingLabel =
        nonLeagueCount == 0 ? '暂无进行中对局' : '进行中：$nonLeagueCount 场';
    final lanLabel = _getLanSummary(lanState);

    // 使用固定色板生成渐变
    final gradientColors = isDarkMode
        ? [
            kActionColors[3].withOpacity(0.3), // 紫
            kActionColors[1].withOpacity(0.3), // 橙
          ]
        : [
            kActionColors[0], // 蓝
            kActionColors[2], // 青
          ];

    // 根据渐变中间色推算前景色
    final midColor =
        Color.lerp(gradientColors.first, gradientColors.last, 0.5)!;
    final isMidColorLight =
        ThemeData.estimateBrightnessForColor(midColor) == Brightness.light;
    final baseForegroundColor = isMidColorLight ? Colors.black87 : Colors.white;

    final headlineColor = baseForegroundColor;
    final descriptionColor = baseForegroundColor.withOpacity(0.85);
    final iconColor = baseForegroundColor.withOpacity(0.8);
    final chipForeground = baseForegroundColor.withOpacity(0.9);
    final chipIconColor = baseForegroundColor.withOpacity(0.8);
    final chipBackground = baseForegroundColor.withOpacity(0.15);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(color: headlineColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: descriptionColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.auto_graph,
                size: 52,
                color: iconColor,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildHeroChip(
                context,
                Icons.timer,
                ongoingLabel,
                foregroundColor: chipForeground,
                iconColor: chipIconColor,
                backgroundColor: chipBackground,
              ),
              _buildHeroChip(
                context,
                Icons.wifi_tethering,
                lanLabel,
                foregroundColor: chipForeground,
                iconColor: chipIconColor,
                backgroundColor: chipBackground,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroChip(
    BuildContext context,
    IconData icon,
    String label, {
    required Color foregroundColor,
    required Color iconColor,
    required Color backgroundColor,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: foregroundColor),
          ),
        ],
      ),
    );
  }

  // 汇总快速入口（使用固定彩色）
  List<_HomeQuickAction> _buildQuickActions(
    BuildContext context,
    WidgetRef ref,
    LanState lanState,
    ScoreState scoreState,
  ) {
    final actions = <_HomeQuickAction>[];

    // 检查当前会话是否真的存在于“进行中”列表，且不是联赛对局
    // 联赛的计分不应在主页继续
    final currentSessionExists = scoreState.currentSession != null &&
        scoreState.currentSession!.leagueMatchId == null &&
        scoreState.ongoingSessions.any((s) =>
            s.sid == scoreState.currentSession!.sid && s.leagueMatchId == null);

    if (currentSessionExists) {
      final templateName = scoreState.template?.templateName ?? '未知模板';
      final roundLabel =
          scoreState.currentRound > 0 ? '第${scoreState.currentRound}轮' : '尚未开始';
      actions.add(
        _HomeQuickAction(
          title: '继续对局',
          subtitle: '「$templateName」· $roundLabel',
          icon: Icons.play_circle_fill,
          color: kActionColors[0],
          onTap: () => _continueCurrentSession(context, ref, scoreState),
        ),
      );
    }

    actions.add(
      _HomeQuickAction(
        title: '快速开局',
        subtitle: '挑选模板并创建新比赛',
        icon: Icons.dashboard_customize,
        color: kActionColors[1],
        onTap: () => _openTemplateSelector(context),
      ),
    );

    actions.add(
      _HomeQuickAction(
        title: '历史记录',
        subtitle: '查看并恢复过往对局',
        icon: Icons.auto_stories,
        color: kActionColors[2],
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const HistoryPage()),
        ),
      ),
    );

    actions.add(
      _HomeQuickAction(
        title: '联赛中心',
        subtitle: '管理淘汰赛或循环赛',
        icon: Icons.emoji_events,
        color: kActionColors[3],
        onTap: () => Navigator.of(context).pushWithSlide(
          const LeagueListPage(),
          direction: SlideDirection.fromRight,
          duration: const Duration(milliseconds: 300),
        ),
      ),
    );

    final isShowState = lanState.isHost || lanState.isClientMode;
    actions.add(
      _HomeQuickAction(
        title: '局域网联机',
        subtitle: _getLanSummary(lanState),
        icon: lanState.isHost
            ? Icons.dns
            : lanState.isClientMode
                ? Icons.wifi
                : Icons.wifi_find,
        color: kActionColors[4],
        onTap: () {
          if (isShowState) {
            showLanStatusSheet();
          } else {
            Navigator.of(context).pushWithSlide(
              const LanDiscoveryPage(),
              direction: SlideDirection.fromRight,
              duration: const Duration(milliseconds: 300),
            );
          }
        },
      ),
    );

    return actions;
  }

  /// “继续未完成的对局”——横向滑动列表
  Widget _buildOngoingSection(BuildContext context, WidgetRef ref) {
    // Consumer widget will rebuild this section when scoreProvider changes.
    return Consumer(
      builder: (context, ref, child) {
        final scoreState = ref.watch(scoreProvider).asData?.value;
        if (scoreState == null) {
          return const SizedBox.shrink(); // Or a loading indicator
        }

        // 准备模板映射
        final templates = ref.watch(templatesProvider).maybeWhen(
              data: (value) => value,
              orElse: () => <BaseTemplate>[],
            );
        final templateMap = {
          for (final template in templates) template.tid: template
        };
        // 列表中排除联赛对局
        final sessions = scoreState.ongoingSessions
            .where((s) => s.leagueMatchId == null)
            .toList();

        // 单卡默认宽度（含内容），高度由卡片内部自适应；外层给一个合适的视口高度
        const double tileWidth = 260;
        const double tileSpacing = 12.0;
        final double viewportHeight = 168; // 适配你卡片内容的大致高度

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('继续未完成的对局', '左右滑动以浏览更多'),
            const SizedBox(height: 12),
            SizedBox(
              height: viewportHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: sessions.length,
                separatorBuilder: (_, __) => const SizedBox(width: tileSpacing),
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  final template = templateMap[session.templateId] ??
                      (scoreState.template?.tid == session.templateId
                          ? scoreState.template
                          : null);

                  return SizedBox(
                    width: tileWidth,
                    child: _OngoingSessionCard(
                      session: session,
                      template: template,
                      isCurrent: scoreState.currentSession?.sid == session.sid,
                      rounds: _estimateSessionRound(session),
                      startLabel: _formatSessionTime(context, session),
                      onTap: () => _openSession(context, ref, session),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _openTemplateSelector(BuildContext context) {
    Navigator.of(context).pushWithSlide(
      Scaffold(
        appBar: AppBar(
          title: const Text('选择模板'),
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
        ),
        body: _TemplateSelector(),
      ),
      direction: SlideDirection.fromRight,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _continueCurrentSession(
      BuildContext context, WidgetRef ref, ScoreState scoreState) {
    final current = scoreState.currentSession;
    if (current == null) return;

    // 强制刷新，确保数据最新
    ref.read(scoreProvider.notifier).switchToSession(current.sid);

    final template = scoreState.template;
    final targetPage = template != null
        ? HomePage.buildSessionPage(template)
        : HomePage.buildSessionPageFromId(current.templateId);
    Navigator.of(context).push(
      CustomPageTransitions.slideFromRight(
        targetPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      ),
    );
  }

  void _openSession(
    BuildContext context,
    WidgetRef ref,
    GameSession session,
  ) {
    ref.read(scoreProvider.notifier).switchToSession(session.sid);
    final targetPage = HomePage.buildSessionPageFromId(session.templateId);
    Navigator.of(context).push(
      CustomPageTransitions.slideFromRight(
        targetPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      ),
    );
  }

  String _getLanSummary(LanState lanState) {
    if (lanState.isHost) {
      final count = lanState.connectedClientIps.length;
      final suffix = count > 0 ? '$count 台客户端已连接' : '等待客户端加入';
      return '主机模式 · $suffix';
    } else if (lanState.isClientMode) {
      if (lanState.isConnected) {
        return '客户端模式 · 已连接';
      } else if (lanState.isReconnecting) {
        return '客户端模式 · 重连中';
      } else {
        return '客户端模式 · 已断开';
      }
    }
    return '未连接 · 可搜索';
  }

  String _formatSessionTime(BuildContext context, GameSession session) {
    final local = session.startTime.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final localDay = DateTime(local.year, local.month, local.day);
    final difference = today.difference(localDay).inDays;

    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final formattedTime = '$hour:$minute';

    if (difference == 0) {
      return '今天 $formattedTime';
    } else if (difference == 1) {
      return '昨天 $formattedTime';
    } else if (difference == 2) {
      return '前天 $formattedTime';
    } else {
      final isSameYear = now.year == local.year;
      final buffer = StringBuffer();
      if (!isSameYear) {
        buffer.write('${local.year}年');
      }
      buffer.write('${local.month}月${local.day}日');
      const weekdayLabels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      final weekdayLabel = weekdayLabels[local.weekday - 1];
      return '${buffer.toString()} $weekdayLabel $formattedTime';
    }
  }

  int _estimateSessionRound(GameSession session) {
    if (session.scores.isEmpty) return 0;
    return session.scores
        .map((s) => s.roundScores.length)
        .fold<int>(0, math.max);
  }
}

class _HomeQuickAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HomeQuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _QuickActionCard extends StatelessWidget {
  final _HomeQuickAction action;

  const _QuickActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outlineVariant.withOpacity(0.35);

    // 计算“两行副标题”的固定高度
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final fontSize =
        MediaQuery.textScalerOf(context).scale(subtitleStyle?.fontSize ?? 12.0);
    final lineHeightFactor = subtitleStyle?.height ?? 1.2;
    final twoLineSubtitleHeight = fontSize * lineHeightFactor * 2;

    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: action.color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: action.color.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(action.icon, color: action.color, size: 24),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward,
                  color: action.color.withOpacity(0.6),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 标题
            Text(
              action.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // 副标题：固定两行高度，下对齐
            SizedBox(
              height: twoLineSubtitleHeight,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  action.subtitle,
                  style: subtitleStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OngoingSessionCard extends StatelessWidget {
  final GameSession session;
  final BaseTemplate? template;
  final bool isCurrent;
  final int rounds;
  final String startLabel;
  final VoidCallback onTap;

  const _OngoingSessionCard({
    required this.session,
    required this.template,
    required this.isCurrent,
    required this.rounds,
    required this.startLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = template?.templateName ?? '未找到模板';
    final playerCount = session.scores.length;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        // 由网格控制宽度，不再固定 240
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCurrent
              ? theme.colorScheme.primary.withOpacity(0.08)
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.25),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isCurrent
                ? theme.colorScheme.primary.withOpacity(0.4)
                : theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '当前',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '玩家：$playerCount 人',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              rounds > 0 ? '已进行 $rounds 轮' : '尚未开始计分',
              style: theme.textTheme.bodySmall,
            ),
            const Spacer(),
            Row(
              children: [
                Icon(Icons.schedule,
                    size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    startLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.play_arrow,
                    size: 20, color: theme.colorScheme.primary),
              ],
            ),
          ],
        ),
      ),
    );
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
