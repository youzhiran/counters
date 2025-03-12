import 'package:counters/widgets/player_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../db/base_template.dart';
import '../db/player_info.dart';
import '../db/poker50.dart';
import '../providers/score_provider.dart';
import '../providers/template_provider.dart';
import '../state.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/history_session_item.dart';
import '../widgets/snackbar.dart';
import 'poker50/poker50_session.dart';

class _TemplateSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<TemplateProvider>(
      builder: (context, provider, _) {
        final userTemplates = provider.templates
            .where((template) => !template.isSystemTemplate)
            .toList();

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
                        (route) => false, // 清除所有路由栈
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
                      _handleTemplateSelect(context, userTemplates[index]),
                ),
              );
      },
    );
  }

  void _handleTemplateSelect(BuildContext context, BaseTemplate template) {
    context.read<ScoreProvider>().startNewGame(template);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (_) => Poker50SessionPage(templateId: template.id)),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key}); // 添加构造函数

  @override
  Widget build(BuildContext context) {
    return Consumer<ScoreProvider>(
      builder: (context, provider, _) {
        if (provider.currentSession == null) {
          return _buildHomeWithHistory(context); // 修改后的主页
        }
        return _buildScoringBoard(context, provider);
      },
    );
  }

  Widget _buildHomeWithHistory(BuildContext context) {
    return Column(
      children: [
        _buildEmptyState(context),
      ],
    );
  }

  void _resumeSession(BuildContext context, GameSession session) {
    context.read<ScoreProvider>().loadSession(session);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Poker50SessionPage(templateId: session.templateId),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('没有进行中的游戏', style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            // 新增按钮容器
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTemplateButton(context), // 选择模板按钮
                SizedBox(height: 12),
                _buildHistoryButton(), // 历史游戏按钮
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

  Widget _buildHistoryButton() {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: Size(200, 48),
      ),
      onPressed: () => _showHistorySessionDialog(),
      child: Text('选择历史计分'),
    );
  }

  void _showClearConfirmation(BuildContext context) {
    // 在异步操作前获取需要的对象
    final provider = Provider.of<ScoreProvider>(context, listen: false);

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
        // 直接在这里执行清除操作，不传递 context
        _clearAllHistory(provider);
      }
    });
  }

  void _clearAllHistory(ScoreProvider provider) async {
    // 执行清除操作
    await provider.clearAllHistory();

    // 关闭当前对话框并重新打开以刷新列表
    globalState.navigatorKey.currentState?.pop();

    // 显示操作反馈
    AppSnackBar.show('已清除所有历史记录');
  }

  // 历史会话对话框
  void _showHistorySessionDialog() {
    globalState.showCommonDialog(
      child: StatefulBuilder(
        builder: (context, setState) {
          return FutureBuilder<List<GameSession>>(
            future: context.read<ScoreProvider>().getAllSessions(),
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
                        onPressed: () => _showClearConfirmation(context),
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
                                key: Key(session.id),
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
                                              style:
                                                  TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                onDismissed: (_) async {
                                  await context
                                      .read<ScoreProvider>()
                                      .deleteSession(session.id);
                                  setState(() {});
                                },
                                child: HistorySessionItem(
                                  session: session,
                                  onDelete: () async {
                                    await context
                                        .read<ScoreProvider>()
                                        .deleteSession(session.id);
                                    setState(() {});
                                  },
                                  onResume: () {
                                    Navigator.pop(context);
                                    _resumeSession(context, session);
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
      ),
    );
  }

  Widget _buildScoringBoard(BuildContext context, ScoreProvider provider) {
    final session = provider.currentSession!;
    final template =
        context.read<TemplateProvider>().getTemplate(session.templateId) ??
            _createFallbackTemplate();
    return Column(
      children: [
        Expanded(
            child: ListView.builder(
          itemCount: session.scores.length,
          itemBuilder: (context, index) {
            final score = session.scores[index];
            // 添加容错处理
            final player = template.players.firstWhere(
              (p) => p.id == score.playerId,
              orElse: () => PlayerInfo(
                  id: 'default_$index',
                  name: '玩家 ${index + 1}',
                  avatar: 'default_avatar.png'),
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
        )),
        // 继续本轮&结束本轮按钮
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Poker50SessionPage(templateId: template.id),
                  ),
                ),
                child: Text('继续本轮', style: TextStyle(color: Colors.white)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                onPressed: () => _showEndConfirmation(context, provider),
                child: Text('结束本轮', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        )
      ],
    );
  }

  void _showEndConfirmation(BuildContext context, ScoreProvider provider) {
    // 检查是否有任何得分记录
    final hasScores =
        provider.currentSession?.scores.any((s) => s.roundScores.isNotEmpty) ??
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
              provider.resetGame(hasScores);
              AppSnackBar.show('已结束当前游戏计分');
            },
            child: Text('确认结束', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 创建应急模板
  Poker50Template _createFallbackTemplate() {
    return Poker50Template(
        templateName: '应急模板',
        playerCount: 3,
        targetScore: 50,
        players: List.generate(
            3,
            (i) => PlayerInfo(
                id: 'emergency_$i',
                name: '玩家 ${i + 1}',
                avatar: 'default_avatar.png')),
        isAllowNegative: false);
  }
}
