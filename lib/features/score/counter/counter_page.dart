import 'package:counters/app/state.dart';
import 'package:counters/common/model/base_template.dart';
import 'package:counters/common/model/counter.dart';
import 'package:counters/common/model/game_session.dart';
import 'package:counters/common/model/player_info.dart';
import 'package:counters/common/model/player_score.dart';
import 'package:counters/common/widgets/player_widget.dart';
import 'package:counters/common/widgets/snackbar.dart';
import 'package:counters/features/score/base_page.dart';
import 'package:counters/features/score/score_provider.dart';
import 'package:counters/features/template/template_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 3人扑克50分
///
/// 玩家打牌计分，首先达到50分的失败，计分少的胜利。
class CounterSessionPage extends BaseSessionPage {
  const CounterSessionPage({super.key, required super.templateId});

  @override
  ConsumerState<CounterSessionPage> createState() => _CounterSessionPageState();
}

class _CounterSessionPageState
    extends BaseSessionPageState<CounterSessionPage> {
  @override
  Widget buildGameBody(
      BuildContext context, BaseTemplate template, GameSession session) {
    final counterTemplate = template as CounterTemplate;

    return Column(
      children: [
        Expanded(
          child: _ScoreBoardGrid(template: counterTemplate, session: session),
        ),
      ],
    );
  }
}

/// 新的分数板网格组件
class _ScoreBoardGrid extends ConsumerWidget {
  final CounterTemplate template;
  final GameSession session;

  const _ScoreBoardGrid({required this.template, required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听分数变化以更新UI
    final scores = ref.watch(scoreProvider).when(
          loading: () => session.scores, // 加载中显示初始数据
          error: (error, stack) => session.scores, // 出错时显示初始数据
          data: (state) =>
              state.currentSession?.scores ?? session.scores, // 成功时获取最新数据
        );

    // 将 PlayerScore 列表转换为 Map，方便按 pid 查找
    final scoreMap = {for (var score in scores) score.playerId: score};

    return LayoutBuilder(
      builder: (context, constraints) {
        final playerCount = template.players.length;

        // 计算最佳的行列配置以充分利用屏幕空间
        final gridConfig = _calculateOptimalGrid(
            playerCount, constraints.maxWidth, constraints.maxHeight);

        final cols = gridConfig['cols'] as int;
        final rows = gridConfig['rows'] as int;
        final needsScroll = gridConfig['needsScroll'] as bool;

        Widget gridWidget = _buildGrid(context, ref, scoreMap, cols, rows);

        // 只有在需要滚动时才包装 SingleChildScrollView
        return needsScroll
            ? SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      minHeight: constraints
                          .maxHeight), // 确保SingleChildScrollView至少占满屏幕高度
                  child: gridWidget,
                ),
              )
            : gridWidget;
      },
    );
  }

  /// 计算最佳的网格配置
  Map<String, dynamic> _calculateOptimalGrid(
      int playerCount, double width, double height) {
    const double itemAspectRatio = 1.0; // 期望的格子宽高比例接近1
    const double minItemWidth = 100.0; // 最小格子宽度
    const double minItemHeight = 110.0; // 最小格子高度

    int bestCols = 1;
    int bestRows = playerCount;
    bool needsScroll = true;
    double minAspectRatioDiff = double.infinity; // 最小的宽高比差异

    // 优先考虑能一次显示所有玩家的配置
    for (int cols = 1; cols <= playerCount; cols++) {
      int rows = (playerCount / cols).ceil();
      double requiredHeight = rows * minItemHeight;

      if (requiredHeight <= height) {
        // 可以一次显示所有玩家，计算实际的格子宽高比
        double actualItemWidth = width / cols;
        double actualItemHeight = height / rows;
        double actualAspectRatio = actualItemWidth / actualItemHeight;
        double aspectRatioDiff = (actualAspectRatio - itemAspectRatio).abs();

        // 如果当前配置的宽高比更接近期望值，或者在接近的情况下，格子面积更大（更充分利用空间）
        if (aspectRatioDiff < minAspectRatioDiff) {
          minAspectRatioDiff = aspectRatioDiff;
          bestCols = cols;
          bestRows = rows;
          needsScroll = false;
        } else if (aspectRatioDiff == minAspectRatioDiff) {
          // 如果宽高比差异相同，选择格子面积更大的
          double currentArea = actualItemWidth * actualItemHeight;
          double bestArea = (width / bestCols) * (height / bestRows);
          if (currentArea > bestArea) {
            bestCols = cols;
            bestRows = rows;
          }
        }
      }
    }

    // 如果没有任何配置能一次显示所有玩家，则选择行数最少（滚动距离最短）的配置，同时考虑让格子尽量方正
    if (needsScroll) {
      bestRows = playerCount; // 初始最大行数
      bestCols = 1;
      minAspectRatioDiff = double.infinity; // 重置最小宽高比差异
      double minScrollRows = playerCount.toDouble(); // 最小滚动行数

      // 遍历可能的列数，寻找最小行数且格子尽量方正的配置
      int maxPossibleCols = (width / minItemWidth).floor();
      if (maxPossibleCols < 1) maxPossibleCols = 1;

      for (int cols = 1; cols <= maxPossibleCols; cols++) {
        int rows = (playerCount / cols).ceil();
        double itemWidth = width / cols;
        double itemHeight = minItemHeight; // 在滚动模式下，格子高度至少为最小高度
        double aspectRatio = itemWidth / itemHeight;
        double aspectRatioDiff = (aspectRatio - itemAspectRatio).abs();

        if (rows < minScrollRows) {
          minScrollRows = rows.toDouble();
          bestCols = cols;
          bestRows = rows;
          minAspectRatioDiff = aspectRatioDiff;
        } else if (rows == minScrollRows) {
          // 如果行数相同，选择宽高比更接近期望值的
          if (aspectRatioDiff < minAspectRatioDiff) {
            bestCols = cols;
            bestRows = rows;
            minAspectRatioDiff = aspectRatioDiff;
          }
        }
      }
    }

    return {
      'cols': bestCols,
      'rows': bestRows,
      'needsScroll': needsScroll,
    };
  }

  /// 构建网格
  Widget _buildGrid(BuildContext context, WidgetRef ref,
      Map<String, PlayerScore> scoreMap, int cols, int rows) {
    // 移除外层 Container 的边框
    return Column(
      children: List.generate(rows, (rowIndex) {
        return Expanded(
          child: Row(
            children: List.generate(cols, (colIndex) {
              final playerIndex = rowIndex * cols + colIndex;

              if (playerIndex >= template.players.length) {
                // 空白格子
                return Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        // 保留内部边框
                        right: colIndex < cols - 1
                            ? BorderSide(
                                color: Theme.of(context).dividerColor, width: 1)
                            : BorderSide.none,
                        bottom: rowIndex < rows - 1
                            ? BorderSide(
                                color: Theme.of(context).dividerColor, width: 1)
                            : BorderSide.none,
                      ),
                    ),
                  ),
                );
              }

              final player = template.players[playerIndex];
              final playerScore =
                  scoreMap[player.pid] ?? PlayerScore(playerId: player.pid);
              final totalScore = playerScore.roundScores
                  .fold(0, (sum, score) => sum + (score ?? 0));

              return Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      // 保留内部边框
                      right: colIndex < cols - 1
                          ? BorderSide(
                              color: Theme.of(context).dividerColor, width: 1)
                          : BorderSide.none,
                      bottom: rowIndex < rows - 1
                          ? BorderSide(
                              color: Theme.of(context).dividerColor, width: 1)
                          : BorderSide.none,
                    ),
                  ),
                  child: _PlayerScoreGridItem(
                    templateId: template.tid,
                    player: player,
                    score: totalScore,
                    onTap: () => _incrementScore(ref, player, totalScore),
                    onLongPress: () =>
                        _showEditDialog(ref, context, player, totalScore),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  // 点击 +1 分数
  void _incrementScore(WidgetRef ref, PlayerInfo player, int currentScore) {
    final scoreNotifier = ref.read(scoreProvider.notifier);
    // 更新玩家的总分数，这里仍然使用更新第一个回合分数的临时方案
    scoreNotifier.updateScore(player.pid, 0, currentScore + 1);
  }

  // 显示分数编辑对话框
  void _showEditDialog(WidgetRef ref, BuildContext context, PlayerInfo player,
      int currentScore) {
    final scoreNotifier = ref.read(scoreProvider.notifier);

    globalState.showCommonDialog(
      child: _ScoreEditDialog(
        templateId: template.tid,
        player: player,
        initialValue: currentScore, // 传递当前总分数
        onConfirm: (newValue) {
          // 更新玩家的总分数
          // 注意：这里需要根据 ScoreProvider 的实际API来调用
          // 如果 ScoreProvider 没有直接更新总分的API，可能需要先获取当前session，修改对应的PlayerScore，然后更新session
          // 假设 ScoreProvider 有一个 updatePlayerTotalScore 方法
          // scoreNotifier.updatePlayerTotalScore(player.pid, newValue);
          // 临时方案：模拟更新第一个回合的分数，以影响总分
          scoreNotifier.updateScore(player.pid, 0, newValue); // 假设编辑的是第一个回合的分数
          ref.read(scoreProvider.notifier).updateHighlight(); // 更新高亮状态（如果需要）
        },
      ),
    );
  }
}

/// 单个玩家得分网格项组件
class _PlayerScoreGridItem extends StatelessWidget {
  final String templateId;
  final PlayerInfo player;
  final int score;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _PlayerScoreGridItem({
    required this.templateId,
    required this.player,
    required this.score,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // 点击编辑分数
      onLongPress: onLongPress, // 长按编辑分数
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.transparent, // 确保整个区域都可以点击
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PlayerAvatar.build(context, player), // 玩家头像
            const SizedBox(height: 8.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                player.name, // 玩家名字
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.2),
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              '$score', // 显示总分数
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
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
/// [initialValue]: 初始分数值 (这里指总分数)
/// [onConfirm]: 确认修改回调 (传递新的总分数)
class _ScoreEditDialog extends ConsumerStatefulWidget {
  final String templateId;
  final PlayerInfo player;
  final int initialValue;
  final ValueChanged<int> onConfirm;

  const _ScoreEditDialog({
    required this.templateId,
    required this.player,
    required this.initialValue,
    required this.onConfirm,
  });

  @override
  _ScoreEditDialogState createState() => _ScoreEditDialogState();
}

class _ScoreEditDialogState extends ConsumerState<_ScoreEditDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final initialText = widget.initialValue != 0
        ? widget.initialValue.toString()
        : widget.initialValue.toString(); // 初始值显示0而不是空
    _controller = TextEditingController(text: initialText);
  }

  @override
  Widget build(BuildContext context) {
    final template = ref
        .read(templatesProvider.notifier)
        .getTemplate(widget.templateId) as CounterTemplate;
    final isAllowNegative = template.isAllowNegative;

    return AlertDialog(
      title: Text('修改总分数'), // 修改标题
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.player.name}'), // 只显示玩家名字
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType:
                TextInputType.numberWithOptions(signed: true, decimal: false),
            autofocus: true,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
            ],
            decoration: InputDecoration(
              labelText: '输入总分数', // 修改标签
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => globalState.navigatorKey.currentState?.pop(),
          child: Text('取消'),
        ),
        TextButton(
          onPressed: () {
            final value = int.tryParse(_controller.text) ?? 0;
            globalState.navigatorKey.currentState?.pop();
            if (!isAllowNegative && value < 0) {
              AppSnackBar.warn('当前模板设置不允许输入负数！');
              return;
            }
            widget.onConfirm(value); // 调用回调传递新的总分数
          },
          child: Text('确认'),
        ),
      ],
    );
  }
}
