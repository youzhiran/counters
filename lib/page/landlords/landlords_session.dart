import 'package:counters/model/landlords.dart';
import 'package:counters/state.dart';
import 'package:counters/widgets/player_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../fragments/input_panel.dart';
import '../../model/game_session.dart';
import '../../model/player_info.dart';
import '../../model/player_score.dart';
import '../../providers/score_provider.dart';
import '../../providers/template_provider.dart';
import '../../widgets/snackbar.dart';

class LandlordsSessionPage extends StatefulWidget {
  final String templateId;

  const LandlordsSessionPage({super.key, required this.templateId});

  @override
  State<LandlordsSessionPage> createState() => _LandlordsSessionPageState();
}

class _LandlordsSessionPageState extends State<LandlordsSessionPage> {
  @override
  Widget build(BuildContext context) {
    final template = context
        .read<TemplateProvider>()
        .getTemplate(widget.templateId) as LandlordsTemplate;
    final session = context.watch<ScoreProvider>().currentSession;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: Text('错误')),
        body: Center(child: Text('模板加载失败')),
      );
    }

    final currentRound = context.read<ScoreProvider>().currentRound;
    final failureScore = template.targetScore;

    // 当轮次完成时检查
    if (currentRound > 0) {
      final allPlayersFilled = session.scores.every((s) =>
          s.roundScores.length >= currentRound &&
          s.roundScores[currentRound - 1] != null);

      if (allPlayersFilled) {
        final overPlayers =
            session.scores.where((s) => s.totalScore >= failureScore).toList();
        if (overPlayers.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showGameResult(context);
          });
        }
      }
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
          QuickInputPanel(key: ValueKey('Panel')),
        ],
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
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
              Navigator.pop(context); // 先关闭对话框
              final template = context
                  .read<TemplateProvider>()
                  .getTemplate(widget.templateId);
              // 使用await确保resetGame完成后再执行startNewGame
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

  /// 显示游戏结果弹窗
  /// 规则：
  /// 1. 达到或超过目标分数的玩家视为失败
  /// 2. 当存在失败玩家时，胜利者为未失败玩家中分数最低者（可能多人并列）
  /// 3. 当无失败玩家时，胜利者为全体最低分玩家，失败者为全体最高分玩家（可能多人并列）
  void _showGameResult(BuildContext context) {
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
      winners = potentialWins
          .where((s) => s.totalScore == minWinScore)
          .cast<PlayerScore>()
          .toList();
      losers = failScores.cast<PlayerScore>();
    } else {
      // 无失败玩家时，胜利者为全体最低分，失败者为全体最高分
      scores.sort((a, b) => a.totalScore.compareTo(b.totalScore));
      final minScore = scores.first.totalScore;
      final maxScore = scores.last.totalScore;

      winners = scores
          .where((s) => s.totalScore == minScore)
          .cast<PlayerScore>()
          .toList();
      losers = scores
          .where((s) => s.totalScore == maxScore)
          .cast<PlayerScore>()
          .toList();
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
}

/// 单个玩家得分列组件（垂直布局）
class _ScoreColumn extends StatelessWidget {
  final String templateId;
  final PlayerInfo player;
  final List<int?> scores;
  final int currentRound;
  final Map<String, GlobalKey> cellKeys;

  const _ScoreColumn({
    required this.templateId,
    required this.player,
    required this.scores,
    required this.currentRound,
    required this.cellKeys,
  });

  @override
  Widget build(BuildContext context) {
    final highlight = context.watch<ScoreProvider>().currentHighlight;

    return SizedBox(
      width: 80,
      child: Column(
        children: [
          // 历史回合得分
          ...List.generate(currentRound, (index) {
            final isHighlight = highlight != null &&
                highlight.key == player.pid &&
                highlight.value == index;
            final score = index < scores.length ? scores[index] : null;

            // 为每个单元格生成唯一标识
            final key = '${player.pid}_$index';
            final cellKey = cellKeys.putIfAbsent(key, () => GlobalKey());

            return Expanded(
              // 新增 Expanded
              child: GestureDetector(
                onTap: () => _showEditDialog(context, index),
                behavior: HitTestBehavior.opaque, // 新增点击行为
                child: Container(
                  key: isHighlight ? cellKey : null, // 仅高亮单元格设置 key
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
        AppSnackBar.show('请填写所有玩家的【第$currentRound轮】后再添加新回合！');
        return;
      }
    }

    final currentScore = roundIndex < scores.length ? scores[roundIndex] : null;

    globalState.showCommonDialog(
      child: _ScoreEditDialog(
        templateId: templateId,
        player: player,
        round: roundIndex + 1,
        initialValue: currentScore ?? 0,
        onConfirm: (newValue) {
          scoreProvider.updateScore(
            player.pid,
            roundIndex,
            newValue,
          );
        },
      ),
    );
  }
}

class _ScoreBoard extends StatefulWidget {
  final LandlordsTemplate template;
  final GameSession session;

  const _ScoreBoard({required this.template, required this.session});

  @override
  _ScoreBoardState createState() => _ScoreBoardState();
}

class _ScoreBoardState extends State<_ScoreBoard> {
  final Map<String, GlobalKey> _cellKeys = {};
  final ScrollController _horizontalScrollController = ScrollController();
  late final ScrollController _headerHorizontalController = ScrollController();
  late final ScrollController _contentHorizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // 在初始化时更新高亮位置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScoreProvider>().updateHighlight();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final highlight = context.watch<ScoreProvider>().currentHighlight;

    if (highlight != null) {
      // 改为使用延迟执行
      Future.delayed(Duration(milliseconds: 100), () {
        _scrollToHighlight();
      });
    }
  }

  // 抽取滚动逻辑到单独的方法
  void _scrollToHighlight() {
    final highlight = context.read<ScoreProvider>().currentHighlight;
    if (highlight != null) {
      final key = '${highlight.key}_${highlight.value}';
      final cellKey = _cellKeys[key];
      if (cellKey?.currentContext != null) {
        Scrollable.ensureVisible(
          cellKey!.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.5,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRound =
        context.select<ScoreProvider, int>((p) => p.currentRound);

    return Column(
      children: [
        // 标题行（禁用用户手动滚动）
        SizedBox(
          height: 80,
          child: SingleChildScrollView(
            controller: _headerHorizontalController,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: _buildHeaderRow(),
          ),
        ),
        // 内容区域（垂直 + 水平滚动）
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SizedBox(
                  // 动态设置内容区域的最小宽度（确保水平滚动可用）
                  width: constraints.maxWidth, // 保持与父级同宽
                  child: SingleChildScrollView(
                    controller: _contentHorizontalController,
                    scrollDirection: Axis.horizontal,
                    physics: const AlwaysScrollableScrollPhysics(), // 强制允许滚动
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth, // 最小宽度填满父容器
                      ),
                      child: _buildContentRow(currentRound),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      children: [
        const SizedBox(width: 50),
        ...widget.template.players.map((player) => SizedBox(
              width: 80,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  PlayerAvatar.build(context, player),
                  Text(
                    player.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(height: 1.2),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildContentRow(int currentRound) {
    return IntrinsicHeight(
      child: Row(
        mainAxisSize: MainAxisSize.max, // 扩展 Row 至最大可用宽度
        mainAxisAlignment: MainAxisAlignment.center, // 子项水平居中
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 左侧回合标签列
          Column(
            children: List.generate(
              currentRound + 1,
              (index) => Container(
                width: 50,
                height: 48,
                alignment: Alignment.center,
                child: Text('第${index + 1}轮'),
              ),
            ),
          ),
          // 玩家得分列
          ...widget.template.players.map((player) {
            final score = widget.session.scores.firstWhere(
              (s) => s.playerId == player.pid,
              orElse: () => PlayerScore(playerId: player.pid),
            );
            return _ScoreColumn(
              templateId: widget.template.tid,
              player: player,
              scores: score.roundScores,
              currentRound: currentRound + 1,
              cellKeys: _cellKeys,
            );
          }),
        ],
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
  final String templateId;
  final PlayerInfo player;
  final int round;
  final int initialValue;
  final ValueChanged<int> onConfirm;

  const _ScoreEditDialog({
    required this.templateId,
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
    final initialText =
        widget.initialValue != 0 ? widget.initialValue.toString() : '';
    _controller = TextEditingController(text: initialText);
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
            Navigator.pop(context);
            widget.onConfirm(value);
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
/// [isHighlighted]: 是否高亮
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
        color: isHighlighted
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
        border: isHighlighted
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
            : null,
      ),
      width: 80,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            score == null ? '--' : (score == 0 ? '🏆' : '$total'),
            style: TextStyle(
              fontSize: 18,
            ),
          ),
          if (score != null)
            Positioned(
              right: 0,
              top: 0,
              child: Text(
                score! >= 0 ? '+$score' : '$score',
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
