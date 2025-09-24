part of '../home_page.dart';

List<_HomeQuickAction> _buildQuickActions(
  BuildContext context,
  WidgetRef ref,
  LanState lanState,
  ScoreState scoreState,
) {
  final actions = <_HomeQuickAction>[];
  if (_canResumeCurrentSession(scoreState)) {
    final subtitle = _buildCurrentSessionSubtitle(scoreState);
    actions.add(
      _HomeQuickAction(
        title: '继续对局',
        subtitle: subtitle,
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
      title: '模板管理',
      subtitle: '自定义模板，灵活配置计分',
      icon: Icons.view_list,
      color: kActionColors[4],
      onTap: () => ref.switchMainTab(2),
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
      color: kActionColors[5],
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
            Text(
              action.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
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
