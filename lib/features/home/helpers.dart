part of 'home_page.dart';

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
      body: const _TemplateSelector(),
    ),
    direction: SlideDirection.fromRight,
    duration: const Duration(milliseconds: 300),
  );
}

void _continueCurrentSession(
  BuildContext context,
  WidgetRef ref,
  ScoreState scoreState,
) {
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
  return session.scores.map((s) => s.roundScores.length).fold<int>(0, math.max);
}

bool _canResumeCurrentSession(ScoreState scoreState) {
  final current = scoreState.currentSession;
  if (current == null || current.leagueMatchId != null) return false;
  return scoreState.ongoingSessions.any(
    (s) => s.sid == current.sid && s.leagueMatchId == null,
  );
}

String _buildCurrentSessionSubtitle(ScoreState scoreState) {
  final templateName = scoreState.template?.templateName ?? '未知模板';
  final roundLabel =
      scoreState.currentRound > 0 ? '第${scoreState.currentRound}轮' : '尚未开始';
  return '「$templateName」· $roundLabel';
}
