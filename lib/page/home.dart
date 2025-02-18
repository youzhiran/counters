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
          return _buildEmptyState(context);
        }
        return _buildScoringBoard(context, provider);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('没有进行中的游戏', style: TextStyle(fontSize: 18)),
          SizedBox(height: 20),
          ElevatedButton(
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
          )
        ],
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
        content: Text('确定要结束当前游戏吗？所有未保存的进度将会丢失！'),
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
      isAllowNegative: false
    );
  }
}
