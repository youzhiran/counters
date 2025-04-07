import 'package:counters/model/landlords.dart';
import 'package:counters/utils/log.dart';
import 'package:counters/widgets/player_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/base_template.dart';
import '../model/game_session.dart';
import '../model/player_info.dart';
import '../model/poker50.dart';
import '../providers/score_provider.dart';
import '../providers/template_provider.dart';
import '../state.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/history_session_item.dart';
import '../widgets/snackbar.dart';
import 'landlords/landlords_page.dart';
import 'poker50/poker50_page.dart';

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
            ? Center(
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
              )
            : ListView.builder(
                itemCount: userTemplates.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(userTemplates[index].templateName),
                  subtitle: Text('玩家数: ${userTemplates[index].playerCount}'),
                  onTap: () =>
                      _handleTemplateSelect(context, ref, userTemplates[index]),
                ),
              );
      },
    );
  }

  void _handleTemplateSelect(
      BuildContext context, WidgetRef ref, BaseTemplate template) {
    ref.read(scoreProvider.notifier).startNewGame(template);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomePage.buildSessionPage(template, template.tid),
      ),
    );
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static Widget buildSessionPage(BaseTemplate? template, String templateId) {
    if (template is Poker50Template) {
      return Poker50SessionPage(templateId: templateId);
    } else if (template is LandlordsTemplate) {
      return LandlordsSessionPage(templateId: templateId);
    }
    AppSnackBar.error('未知的模板类型');
    return const HomePage();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(scoreProvider);

    return scoreAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('加载失败: $err')),
      data: (scoreState) {
        // 有未完成的记录加载_buildScoringBoard
        if (scoreState.currentSession?.isCompleted == false) {
          return _buildScoringBoard(context, ref, scoreState);
        } else {
          return _buildHomeWithHistory(context, ref);
        }
      },
    );
  }

  Widget _buildHomeWithHistory(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _buildEmptyState(context, ref),
      ],
    );
  }

  void _resumeSession(
      BuildContext context, WidgetRef ref, GameSession session) async {
    ref.read(scoreProvider.notifier).loadSession(session);
    final template = await ref
        .read(templatesProvider.notifier)
        .getTemplateAsync(session.templateId);

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HomePage.buildSessionPage(template, session.templateId),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
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
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text('选择模板')),
            body: _TemplateSelector(),
          ),
        ),
      ),
      child: Text('选择计分模板'),
    );
  }

  Widget _buildHistoryButton(WidgetRef ref) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: Size(200, 48),
      ),
      onPressed: () => _showHistorySessionDialog(ref),
      child: Text('选择历史计分'),
    );
  }

  void _showClearConfirmation(BuildContext context, WidgetRef ref) {
    globalState
        .showCommonDialog(
      child: ConfirmationDialog(
        title: '确认清除',
        content: '这将永久删除所有历史记录!\n玩家统计数据同时也会被清除。\n此操作不可撤销!',
        confirmText: '确认清除',
      ),
    )
        .then((confirmed) {
      if (confirmed == true) {
        _clearAllHistory(ref);
      }
    });
  }

  void _clearAllHistory(WidgetRef ref) async {
    await ref.read(scoreProvider.notifier).clearAllHistory();
    globalState.navigatorKey.currentState?.pop();
    AppSnackBar.show('已清除所有历史记录');
  }

  void _showHistorySessionDialog(WidgetRef ref) {
    globalState.showCommonDialog(
      child: StatefulBuilder(
        builder: (context, setState) {
          return Consumer(
            builder: (context, ref, _) {
              return FutureBuilder<List<GameSession>>(
                future: ref.read(scoreProvider.notifier).getAllSessions(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const AlertDialog(
                      content: Center(child: CircularProgressIndicator()),
                    );
                  } else {
                    final sessions = snapshot.data ?? [];
                    sessions.sort((a, b) => b.startTime.compareTo(a.startTime));

                    return AlertDialog(
                      title: Row(
                        children: [
                          const Text('历史计分记录'),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.delete_forever),
                            tooltip: '清除所有记录',
                            onPressed: () =>
                                _showClearConfirmation(context, ref),
                          )
                        ],
                      ),
                      content: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.9,
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: sessions.isEmpty
                            ? const Center(child: Text('暂无历史记录'))
                            : ListView.separated(
                                itemCount: sessions.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final session = sessions[index];
                                  return Dismissible(
                                    key: Key(session.sid),
                                    background: Container(
                                      color: Colors.red,
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      child: const Icon(Icons.delete,
                                          color: Colors.white),
                                    ),
                                    confirmDismiss: (direction) async {
                                      return await globalState.showCommonDialog(
                                        child: AlertDialog(
                                          title: const Text('确认删除'),
                                          content: const Text('确定要删除这条记录吗？'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('取消'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('删除',
                                                  style: TextStyle(
                                                      color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    onDismissed: (_) async {
                                      await ref
                                          .read(scoreProvider.notifier)
                                          .deleteSession(session.sid);
                                      setState(() {});
                                    },
                                    child: HistorySessionItem(
                                      session: session,
                                      onDelete: () async {
                                        await ref
                                            .read(scoreProvider.notifier)
                                            .deleteSession(session.sid);
                                        setState(() {});
                                      },
                                      onResume: () {
                                        Navigator.pop(context);
                                        _resumeSession(context, ref, session);
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('关闭'),
                        ),
                      ],
                    );
                  }
                },
              );
            },
          );
        },
      ),
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
              child: ListView.builder(
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
                  return ListTile(
                    leading: PlayerAvatar.build(context, player),
                    title: Text(player.name),
                    subtitle: Text('总得分: ${score.totalScore}'),
                    trailing: () {
                      final lastScore = score.roundScores.lastOrNull;
                      final displayScore = lastScore ?? 0;
                      final prefix = displayScore >= 0 ? '+' : '';
                      return Text('$prefix$displayScore');
                    }(),
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
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            HomePage.buildSessionPage(template, template.tid),
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

    globalState.showCommonDialog(
      child: AlertDialog(
        title: Text('结束本轮游戏'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(scoreProvider.notifier).resetGame(hasScores);
              AppSnackBar.show('已结束当前游戏计分');
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
