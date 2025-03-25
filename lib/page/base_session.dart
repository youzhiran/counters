import 'package:counters/model/base_template.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/game_session.dart';
import '../../model/player_info.dart';
import '../../providers/score_provider.dart';
import '../../providers/template_provider.dart';
import '../../state.dart';
import '../../widgets/snackbar.dart';
import '../model/player_score.dart';

abstract class BaseSessionPage extends StatefulWidget {
  final String templateId;

  const BaseSessionPage({super.key, required this.templateId});
}

abstract class BaseSessionPageState<T extends BaseSessionPage>
    extends State<T> {
  @override
  Widget build(BuildContext context) {
    final template =
        context.read<TemplateProvider>().getTemplate(widget.templateId);
    final session = context.watch<ScoreProvider>().currentSession;

    if (session == null || template == null) {
      return Scaffold(
        appBar: AppBar(title: Text('错误')),
        body: Center(child: Text('模板加载失败')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(template.templateName),
        actions: [
          IconButton(
            icon: Icon(Icons.sports_score),
            onPressed: () => showGameResult(context),
          ),
          IconButton(
            icon: Icon(Icons.restart_alt_rounded),
            onPressed: () => showResetConfirmation(context),
          )
        ],
      ),
      body: buildGameBody(context, template, session),
    );
  }

  Widget buildGameBody(
      BuildContext context, BaseTemplate template, GameSession session);

  /// 获取玩家名称的辅助方法
  /// [playerId]: 玩家ID
  /// [context]: 构建上下文
  /// 返回：玩家名称或"未知玩家"
  String _getPlayerName(String playerId, BuildContext context) {
    return context
            .read<TemplateProvider>()
            .getTemplate(widget.templateId)
            ?.players
            .firstWhere((p) => p.pid == playerId,
                orElse: () => PlayerInfo(name: '未知玩家', avatar: 'default'))
            .name ??
        '未知玩家';
  }

  void showGameResult(BuildContext context) {
    final targetScore = context
        .read<TemplateProvider>()
        .getTemplate(widget.templateId)
        ?.targetScore;

    if (targetScore == null) {
      globalState.showCommonDialog(
        child: AlertDialog(
          title: Text('数据错误'),
          content: Text('未能获取目标分数配置，请检查模板设置'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: Text('确定'))
          ],
        ),
      );
      return;
    }

    // ... 保持原有的游戏结果显示逻辑 ...
    final scores = context.read<ScoreProvider>().currentSession?.scores ?? [];

    // 划分失败玩家（分数>=目标分数）
    final failScores =
        scores.where((s) => s.totalScore >= targetScore).toList();
    final hasFailures = failScores.isNotEmpty;

    // 确定胜利者和失败者
    final List<PlayerScore> winners;
    final List<PlayerScore> losers;

    if (hasFailures) {
      // 存在失败玩家时，胜利者为未失败玩家中的最低分
      final potentialWins =
          scores.where((s) => s.totalScore < targetScore).toList();
      potentialWins.sort((a, b) => a.totalScore.compareTo(b.totalScore));
      final minWinScore =
          potentialWins.isNotEmpty ? potentialWins.first.totalScore : 0;
      winners =
          potentialWins.where((s) => s.totalScore == minWinScore).toList();
      losers = failScores;
    } else {
      // 无失败玩家时，胜利者为全体最低分，失败者为全体最高分
      scores.sort((a, b) => a.totalScore.compareTo(b.totalScore));
      final minScore = scores.first.totalScore;
      final maxScore = scores.last.totalScore;

      winners = scores.where((s) => s.totalScore == minScore).toList();
      losers = scores.where((s) => s.totalScore == maxScore).toList();
    }

    globalState.showCommonDialog(
      child: AlertDialog(
        title: Text(hasFailures ? '游戏结束' : '当前游戏情况'),
        content: SingleChildScrollView(
          // 添加滚动视图
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (losers.isNotEmpty) ...[
                Text('${hasFailures ? '😓 失败' : '⚠️ 最多计分'}：',
                    style: TextStyle(
                        color: hasFailures ? Colors.red : Colors.orange)),
                ...losers.map((s) => Text(
                    '${_getPlayerName(s.playerId, context)}（${s.totalScore}分）')),
                SizedBox(height: 16),
              ],
              Text('${hasFailures ? '🏆 胜利' : '🎉 最少计分'}：',
                  style: TextStyle(color: Colors.green)),
              ...winners.map((s) => Text(
                  '${_getPlayerName(s.playerId, context)}（${s.totalScore}分）')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: Text('确定'),
          ),
        ],
      ),
    );
  }

  void showResetConfirmation(BuildContext context) {
    globalState.showCommonDialog(
      child: AlertDialog(
        title: Text('重置游戏'),
        content: Text('确定要重置当前游戏吗？\n'
            '当前进度将会自动保存并标记为已完成，并启动一个新的计分。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final template = context
                  .read<TemplateProvider>()
                  .getTemplate(widget.templateId);
              final scoreProvider = context.read<ScoreProvider>();
              await scoreProvider.resetGame(true);
              if (template != null) {
                scoreProvider.startNewGame(template);
              } else {
                AppSnackBar.warn('模板加载失败，请重试');
              }
            },
            child: Text('重置'),
          ),
        ],
      ),
    );
  }

  String getPlayerName(String playerId, BuildContext context) {
    return context
            .read<TemplateProvider>()
            .getTemplate(widget.templateId)
            ?.players
            .firstWhere((p) => p.pid == playerId,
                orElse: () => PlayerInfo(name: '未知玩家', avatar: 'default'))
            .name ??
        '未知玩家';
  }
}
