import 'package:counters/model/base_template.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/game_session.dart';
import '../../model/player_info.dart';
import '../../providers/score_provider.dart';
import '../../providers/template_provider.dart';
import '../../widgets/snackbar.dart';
import '../state.dart';

abstract class BaseSessionPage extends ConsumerStatefulWidget {
  final String templateId;

  const BaseSessionPage({super.key, required this.templateId});
}

abstract class BaseSessionPageState<T extends BaseSessionPage>
    extends ConsumerState<T> {
  @override
  Widget build(BuildContext context) {
    final template =
        ref.watch(templatesProvider.notifier).getTemplate(widget.templateId);

    final scoreAsync = ref.watch(scoreProvider);

    return scoreAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text('加载中...')),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: Text('错误')),
        body: Center(child: Text('加载分数失败: $error')),
      ),
      data: (scoreState) {
        // final session = ref.watch(scoreProvider).value?.currentSession;
        final session = scoreState.currentSession;

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
      },
    );

  }

  Widget buildGameBody(
      BuildContext context, BaseTemplate template, GameSession session);

  /// 获取玩家名称的辅助方法
  /// [playerId]: 玩家ID
  /// [context]: 构建上下文
  /// 返回：玩家名称或"未知玩家"
  String _getPlayerName(String playerId, BuildContext context) {
    return ref
            .read(templatesProvider.notifier)
            .getTemplate(widget.templateId)
            ?.players
            .firstWhere((p) => p.pid == playerId,
                orElse: () => PlayerInfo(name: '未知玩家', avatar: 'default'))
            .name ??
        '未知玩家';
  }

  void showGameResult(BuildContext context) {
    final targetScore = ref
        .read(templatesProvider.notifier)
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

    final result =
        ref.read(scoreProvider.notifier).calculateGameResult(targetScore);

    globalState.showCommonDialog(
      child: AlertDialog(
        title: Text(result.hasFailures ? '游戏结束' : '当前游戏情况'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (result.losers.isNotEmpty) ...[
                Text('${result.hasFailures ? '😓 失败' : '⚠️ 最多计分'}：',
                    style: TextStyle(
                        color:
                            result.hasFailures ? Colors.red : Colors.orange)),
                ...result.losers.map((s) => Text(
                    '${_getPlayerName(s.playerId, context)}（${s.totalScore}分）')),
                SizedBox(height: 16),
              ],
              Text('${result.hasFailures ? '🏆 胜利' : '🎉 最少计分'}：',
                  style: TextStyle(color: Colors.green)),
              ...result.winners.map((s) => Text(
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
              final template = ref
                  .read(templatesProvider.notifier)
                  .getTemplate(widget.templateId);
              await ref.read(scoreProvider.notifier).resetGame(true);
              if (template != null) {
                ref.read(scoreProvider.notifier).startNewGame(template);
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
    return ref
            .read(templatesProvider.notifier)
            .getTemplate(widget.templateId)
            ?.players
            .firstWhere((p) => p.pid == playerId,
                orElse: () => PlayerInfo(name: '未知玩家', avatar: 'default'))
            .name ??
        '未知玩家';
  }
}
