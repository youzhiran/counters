import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../providers/score_provider.dart';
import '../providers/template_provider.dart';
import '../widgets/snackbar.dart';

class GameSessionScreen extends StatelessWidget {
  final String templateId;

  const GameSessionScreen({super.key, required this.templateId});

  @override
  Widget build(BuildContext context) {
    final template = context.read<TemplateProvider>().getTemplate(templateId);
    final session = context
        .watch<ScoreProvider>()
        .currentSession;

    if (template == null || session == null) {
      return Scaffold(
        appBar: AppBar(title: Text('错误')),
        body: Center(child: Text('模板加载失败')),
      );
    }

    var failureScore =
        context
            .read<TemplateProvider>()
            .getTemplate(templateId)
            ?.targetScore;

    // 检查游戏是否结束
    final overPlayers =
    session.scores.where((s) => s.totalScore >= failureScore!).toList();
    if (overPlayers.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGameResult(context);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(template.templateName),
        actions: [
          IconButton(
            icon: Icon(Icons.sports_score),
            onPressed: () => _showGameResult(context),
          ),
          IconButton(
            icon: Icon(Icons.restart_alt_rounded),
            onPressed: () => _showResetConfirmation(context),
          )
        ],
      ),
      body: Column(
        children: [
          // 可滚动的计分区
          Expanded(
            child: _ScoreBoard(template: template, session: session),
          ),
          // 固定快捷输入
          _QuickInputPanel(),
        ],
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text('重置游戏'),
            content: Text('确定要重置当前游戏吗？所有进度将会丢失！'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // 先关闭对话框
                  final template =
                  context.read<TemplateProvider>().getTemplate(templateId);
                  context.read<ScoreProvider>()
                    ..resetGame()
                    ..startNewGame(template!);
                },
                child: Text('确定重置', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  /// 显示游戏结果弹窗
  /// 规则：
  /// 1. 达到或超过目标分数的玩家视为失败
  /// 2. 当存在失败玩家时，胜利者为未失败玩家中分数最低者（可能多人并列）
  /// 3. 当无失败玩家时，胜利者为全体最低分玩家，失败者为全体最高分玩家（可能多人并列）
  void _showGameResult(BuildContext context) {
    final targetScore =
        context
            .read<TemplateProvider>()
            .getTemplate(templateId)
            ?.targetScore;

    if (targetScore == null) {
      showDialog(
        context: context,
        builder: (context) =>
            AlertDialog(
              title: Text('数据错误'),
              content: Text('未能获取目标分数配置，请检查模板设置'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('确定'))
              ],
            ),
      );
      return;
    }

    final scores = context
        .read<ScoreProvider>()
        .currentSession
        ?.scores ?? [];

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

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text(hasFailures ? '游戏结果' : '当前游戏结果'), // 修改点：动态标题
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 显示失败/最高分玩家
                if (losers.isNotEmpty) ...[
                  Text('${hasFailures ? '😓 失败' : '⚠️ 最多计分'}：',
                      style: TextStyle(
                          color: hasFailures ? Colors.red : Colors.orange)),
                  ...losers.map((s) =>
                      Text(
                          '${_getPlayerName(s.playerId, context)}（${s
                              .totalScore}分）')),
                  SizedBox(height: 16),
                ],

                // 显示胜利者
                Text('👑 胜利：', style: TextStyle(color: Colors.green)),
                ...winners.map((s) =>
                    Text(
                        '${_getPlayerName(s.playerId, context)}（${s
                            .totalScore}分）')),
              ],
            ),
            actions: [
              TextButton(
                onPressed: Navigator
                    .of(context)
                    .pop,
                child: Text('确定'),
              ),
            ],
          ),
    );
  }

  /// 获取玩家名称的辅助方法
  /// [playerId]: 玩家ID
  /// [context]: 构建上下文
  /// 返回：玩家名称或"未知玩家"
  String _getPlayerName(String playerId, BuildContext context) {
    return context
        .read<TemplateProvider>()
        .getTemplate(templateId)
        ?.players
        .firstWhere((p) => p.id == playerId,
        orElse: () => PlayerInfo(name: '未知玩家', avatar: 'default'))
        .name ??
        '未知玩家';
  }
}

/// 单个玩家得分列组件（垂直布局）
/// 参数说明：
/// [player]: 玩家信息
/// [scores]: 回合得分列表
/// [total]: 总得分
/// [currentRound]: 当前回合数
/// [isHighlighted]: 是否高亮显示
/// [animation]: 高亮动画
/// [onTap]: 点击回调
class _ScoreColumn extends StatelessWidget {
  final PlayerInfo player;
  final List<int?> scores;
  final int currentRound;

  const _ScoreColumn({
    required this.player,
    required this.scores,
    required this.currentRound,
  });

  @override
  Widget build(BuildContext context) {
    final highlight = context
        .watch<ScoreProvider>()
        .currentHighlight;

    return SizedBox(
      width: 80,
      child: Column(
        children: [
          // 历史回合得分
          ...List.generate(currentRound, (index) {
            final isHighlight = highlight != null &&
                highlight.key == player.id &&
                highlight.value == index;
            final score = index < scores.length ? scores[index] : null;

            return Expanded(
              // 新增 Expanded
              child: GestureDetector(
                onTap: () => _showEditDialog(context, index),
                behavior: HitTestBehavior.opaque, // 新增点击行为
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  child: _ScoreCell(
                    isHighlighted: isHighlight,
                    score: score,
                    total: scores
                        .take(index + 1)
                        .fold(0, (sum, item) => sum + (item ?? 0)),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 显示分数编辑对话框
  /// [context]: 构建上下文
  /// [roundIndex]: 要编辑的回合索引
  // 修改后的方法
  void _showEditDialog(BuildContext context, int roundIndex) {
    final scoreProvider = context.read<ScoreProvider>();
    final currentRound = scoreProvider.currentRound;

    if (roundIndex < 0 || roundIndex > scores.length) return;

    if (roundIndex == scores.length) {
      // 添加currentRound有效性检查
      final canAddNewRound = currentRound == 0 ||
          scoreProvider.currentSession!.scores.every((s) {
            // 调整索引访问逻辑
            final lastRoundIndex = currentRound - 1;
            return s.roundScores.length > lastRoundIndex &&
                s.roundScores[lastRoundIndex] != null;
          });

      if (canAddNewRound) {
        scoreProvider.addNewRound();
      } else {
        // 添加提示逻辑
        AppSnackBar.show(context, '请填写所有玩家的【第$currentRound轮】后再添加新回合！');
        return;
      }
    }

    final currentScore = roundIndex < scores.length ? scores[roundIndex] : null;

    showDialog(
      context: context,
      builder: (context) =>
          _ScoreEditDialog(
            player: player,
            round: roundIndex + 1,
            initialValue: currentScore ?? 0,
            onConfirm: (newValue) {
              scoreProvider.updateScore(
                player.id,
                roundIndex,
                newValue,
              );
            },
          ),
    );
  }
}

/// 计分板组件（水平滚动布局）
/// 参数说明：
/// [template]: 游戏模板数据
/// [session]: 当前游戏会话
class _ScoreBoard extends StatefulWidget {
  final ScoreTemplate template;
  final GameSession session;

  const _ScoreBoard({required this.template, required this.session});

  @override
  _ScoreBoardState createState() => _ScoreBoardState();
}

class _ScoreBoardState extends State<_ScoreBoard> {
  @override
  Widget build(BuildContext context) {
    final currentRound =
    context.select<ScoreProvider, int>((p) => p.currentRound);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 玩家标题行
            Row(
              children: [
                const SizedBox(width: 50),
                ...widget.template.players.map((player) =>
                    SizedBox(
                      width: 80,
                      child: Column(
                        children: [
                          CircleAvatar(
                              child: Text(player.name.substring(0, 1))),
                          Text(player.name, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    )),
              ],
            ),

            // 修改后的回合行
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左侧回合标签列
                  Column(
                    children: List.generate(
                      currentRound + 1,
                          (index) =>
                          Container(
                            width: 50,
                            height: 48,
                            alignment: Alignment.center,
                            child: Text('第${index + 1}轮'), // 直接显示回合标签
                          ),
                    ),
                  ),

                  // 玩家得分列
                  ...widget.template.players.map((player) {
                    final score = widget.session.scores.firstWhere(
                          (s) => s.playerId == player.id,
                      orElse: () => PlayerScore(playerId: player.id),
                    );

                    return _ScoreColumn(
                      player: player,
                      scores: score.roundScores,
                      currentRound: currentRound + 1,
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 分数编辑对话框组件
/// 参数说明：
/// [player]: 关联的玩家信息
/// [round]: 编辑的回合数
/// [initialValue]: 初始分数值
/// [onConfirm]: 确认修改回调
class _ScoreEditDialog extends StatefulWidget {
  final PlayerInfo player;
  final int round;
  final int initialValue;
  final ValueChanged<int> onConfirm;

  const _ScoreEditDialog({
    required this.player,
    required this.round,
    required this.initialValue,
    required this.onConfirm,
  });

  @override
  _ScoreEditDialogState createState() => _ScoreEditDialogState();
}

class _ScoreEditDialogState extends State<_ScoreEditDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue.toString());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('修改分数'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.player.name} - 第${widget.round}轮'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: '输入新分数',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('取消'),
        ),
        TextButton(
          onPressed: () {
            final value = int.tryParse(_controller.text) ?? 0;
            widget.onConfirm(value);
            Navigator.pop(context);
            // 自动更新高亮位置
            context.read<ScoreProvider>().updateHighlight();
          },
          child: Text('确认'),
        ),
      ],
    );
  }
}

/// 单个得分单元格组件
/// 参数说明：
/// [score]: 当前回合得分（可选）
/// [total]: 累计总得分
/// [isCurrent]: 是否为当前回合
class _ScoreCell extends StatelessWidget {
  final int? score;
  final int total;
  final bool isHighlighted;

  const _ScoreCell({
    this.score,
    required this.total,
    required this.isHighlighted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // 新增装饰
        color: isHighlighted ? Colors.blue[100] : null,
        border: isHighlighted
            ? Border.all(color: Colors.blueAccent, width: 2)
            : null,
      ),
      width: 80,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            score == null ? '--' : (score == 0 ? '👑' : '$total'),
            style: TextStyle(
              fontSize: 18,
            ),
          ),
          if (score != null)
            Positioned(
              right: 0,
              top: 0,
              child: Text(
                '+$score',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          if (score == null)
            Positioned(
              right: 0,
              top: 0,
              child: Text('--', style: TextStyle(color: Colors.grey)),
            ),
        ],
      ),
    );
  }
}

/// 快捷输入面板组件
/// 提供常用数值的快速输入按钮
class _QuickInputPanel extends StatelessWidget {
  final List<int> quickNumbers = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                  '快捷输入', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                alignment: WrapAlignment.center,
                children: quickNumbers
                    .map((number) =>
                    ActionChip(
                      label: Text('+$number'),
                      onPressed: () {
                        final provider = context.read<ScoreProvider>();
                        final highlight = provider.currentHighlight;
                        final session = provider.currentSession;

                        if (highlight != null && session != null) {
                          final playerScore = session.scores.firstWhere(
                                (s) => s.playerId == highlight.key,
                            orElse: () =>
                                PlayerScore(
                                    playerId: 'invalid', roundScores: []),
                          );

                          if (playerScore.playerId != 'invalid') {
                            // 移除长度校验
                            final currentValue = playerScore
                                .roundScores.length >
                                highlight.value
                                ? playerScore.roundScores[highlight.value] ??
                                0
                                : 0; // 安全获取当前值
                            provider.updateScore(
                              highlight.key,
                              highlight.value,
                              currentValue + number,
                            );
                          }
                        }
                      },
                    ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
