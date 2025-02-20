import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../providers/score_provider.dart';
import '../providers/template_provider.dart';
import '../state.dart';
import '../widgets/snackbar.dart';
import 'game_session.dart';

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

  void _handleTemplateSelect(BuildContext context, ScoreTemplate template) {
    context.read<ScoreProvider>().startNewGame(template);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (_) => GameSessionScreen(templateId: template.id)),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key}); // 添加构造函数

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

  String _formatDate(DateTime dt) => "${dt.year}-"
      "${dt.month.toString().padLeft(2, '0')}-"
      "${dt.day.toString().padLeft(2, '0')} "
      "${dt.hour.toString().padLeft(2, '0')}:"
      "${dt.minute.toString().padLeft(2, '0')}:"
      "${dt.second.toString().padLeft(2, '0')}";

  void _resumeSession(BuildContext context, GameSession session) {
    context.read<ScoreProvider>().loadSession(session);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameSessionScreen(templateId: session.templateId),
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
                _buildHistoryButton(context), // 历史游戏按钮
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

  Widget _buildHistoryButton(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: Size(200, 48),
      ),
      onPressed: () => _showHistorySessionDialog(context),
      child: Text('选择历史计分'),
    );
  }

  // 历史会话对话框
  void _showHistorySessionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final sessions = context.read<ScoreProvider>().getAllSessions()
              ..sort((a, b) => b.startTime.compareTo(a.startTime));

            return AlertDialog(
              title: Row(
                children: [
                  const Text('历史计分记录'),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => setState(() {}),
                  )
                ],
              ),
              content: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.7,
                child: sessions.isEmpty
                    ? const Center(child: Text('暂无历史记录'))
                    : ListView.separated(
                        itemCount: sessions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final session = sessions[index];
                          final template = context
                              .read<TemplateProvider>()
                              .getTemplateBySession(session);

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
                              return await showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('确认删除'),
                                  content: const Text('确定要删除这条记录吗？'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('取消'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
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
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              title: Text(
                                template?.templateName ?? "未知模板",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      "${_formatDate(session.startTime)}"),
                                  if (session.endTime != null)
                                    Text(
                                        "${_formatDate(session.endTime!)}"),
                                  Text(
                                    "状态：${session.isCompleted ? '已完成' : '进行中'}",
                                    style: TextStyle(
                                      color: session.isCompleted
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('确认删除'),
                                      content: const Text('确定要删除这条记录吗？'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('取消'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text('删除',
                                              style:
                                                  TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    context
                                        .read<ScoreProvider>()
                                        .deleteSession(session.id);
                                    setState(() {});
                                  }
                                },
                              ),
                              onTap: () {
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
          },
        );
      },
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
              leading: CircleAvatar(child: Text(player.name[0])),
              title: Text(player.name),
              subtitle: Text('总得分: ${score.totalScore}'),
              trailing: Text('+${score.roundScores.lastOrNull ?? 0}'),
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
                    builder: (_) => GameSessionScreen(templateId: template.id),
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
              AppSnackBar.show(context, '已结束当前游戏计分');
            },
            child: Text('确认结束', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 创建应急模板
  ScoreTemplate _createFallbackTemplate() {
    return ScoreTemplate(
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
