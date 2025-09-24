part of '../home_page.dart';

Widget _buildHeroSection(
  BuildContext context,
  ScoreState scoreState,
  LanState lanState,
) {
  final theme = Theme.of(context);
  final isDarkMode = theme.brightness == Brightness.dark;

  // 主页不展示联赛对局的续玩提示
  final currentSessionExists = scoreState.currentSession != null &&
      scoreState.currentSession!.leagueMatchId == null &&
      scoreState.ongoingSessions.any(
        (s) =>
            s.sid == scoreState.currentSession!.sid && s.leagueMatchId == null,
      );

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
  final midColor = Color.lerp(gradientColors.first, gradientColors.last, 0.5)!;
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
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(50),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: foregroundColor),
        ),
      ],
    ),
  );
}
