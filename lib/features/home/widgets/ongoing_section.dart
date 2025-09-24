part of '../home_page.dart';

/// “继续未完成的对局”——横向滑动列表
Widget _buildOngoingSection(BuildContext context, WidgetRef ref) {
  return Consumer(
    builder: (context, ref, child) {
      final scoreState = ref.watch(scoreProvider).asData?.value;
      if (scoreState == null) {
        return const SizedBox.shrink();
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

      const double tileWidth = 260;
      const double tileSpacing = 12.0;
      const double viewportHeight = 168;

      if (sessions.isEmpty) {
        return const SizedBox.shrink();
      }

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
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
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
                Icon(
                  Icons.play_arrow,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
