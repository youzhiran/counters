import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/base_template.dart';
import '../model/poker50.dart';
import '../model/player_info.dart';
import '../providers/score_provider.dart';
import '../providers/template_provider.dart';
import '../state.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/history_session_item.dart';
import '../widgets/snackbar.dart';
import 'poker50/session.dart';

class _TemplateSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<TemplateProvider>(
      builder: (context, provider, _) {
        return ListView.builder(
          itemCount: provider.templates.length,
          itemBuilder: (context, index) => ListTile(
            title: Text(provider.templates[index].templateName),
            subtitle: Text('玩家数: ${provider.templates[index].playerCount}'),
            onTap: () =>
                _handleTemplateSelect(context, provider.templates[index]),
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
        content: '这将永久删除所有历史记录!\n此操作不可撤销!',
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
    globalState.showCommonDialog(child: StatefulBuilder(
      builder: (context, setState) {
        final sessions = context.read<ScoreProvider>().getAllSessions()
          ..sort((a, b) => b.startTime.compareTo(a.startTime));
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
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final session = sessions[index];

                      return Dismissible(
                          key: Key(session.id),
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child:
                                const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (direction) async {
                            return await globalState.showCommonDialog(
                              child: AlertDialog(
                                title: const Text('确认删除'),
                                content: const Text('确定要删除这条记录吗？'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('取消'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('删除',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (_) {
                            context
                                .read<ScoreProvider>()
                                .deleteSession(session.id);
                          },
                          child: HistorySessionItem(
                            session: session,
                            onDelete: () {
                              context
                                  .read<ScoreProvider>()
                                  .deleteSession(session.id);
                              setState(() {});
                            },
                            onResume: () {
                              Navigator.pop(context);
                              _resumeSession(context, session);
                            },
                          ));
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
      },
    ));
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
              leading: CircleAvatar(child: Text(player.name[0])),
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
    globalState.showCommonDialog(
      child: AlertDialog(
        title: Text('结束本轮游戏'),
        content: Text('确定要结束当前游戏吗？进度将会保存'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 先关闭对话框
              provider.resetGame();
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
