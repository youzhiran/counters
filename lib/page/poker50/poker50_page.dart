import 'package:counters/model/base_template.dart';
import 'package:counters/page/base_session.dart';
import 'package:counters/widgets/player_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../fragments/input_panel.dart';
import '../../model/game_session.dart';
import '../../model/player_info.dart';
import '../../model/player_score.dart';
import '../../model/poker50.dart';
import '../../providers/score_provider.dart';
import '../../providers/template_provider.dart';
import '../../state.dart';
import '../../widgets/snackbar.dart';

/// 3人扑克50分
///
/// 玩家打牌计分，首先达到50分的失败，计分少的胜利。
class Poker50SessionPage extends BaseSessionPage {
  const Poker50SessionPage({super.key, required super.templateId});

  @override
  ConsumerState<Poker50SessionPage> createState() => _Poker50SessionPageState();
}

class _Poker50SessionPageState
    extends BaseSessionPageState<Poker50SessionPage> {

  @override
  Widget buildGameBody(
      BuildContext context, BaseTemplate template, GameSession session) {
    final poker50Template = template as Poker50Template;

    return Column(
      children: [
        Expanded(
          child: _ScoreBoard(template: poker50Template, session: session),
        ),
        QuickInputPanel(key: ValueKey('Panel')),
      ],
    );
  }
}

/// 单个玩家得分列组件（垂直布局）
class _ScoreColumn extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final highlight = ref.watch(scoreProvider).when(
          loading: () => null, // 加载中时返回 null
          error: (error, stack) => null, // 出错时返回 null
          data: (state) => state.currentHighlight, // 成功时获取 currentHighlight
        );

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
                onTap: () => _showEditDialog(ref, context, index),
                behavior: HitTestBehavior.opaque,
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

  void _showEditDialog(WidgetRef ref, BuildContext context, int roundIndex) {
    final scoreNotifier = ref.read(scoreProvider.notifier);
    final scoreState = ref.read(scoreProvider);

    final currentRound = scoreState.value?.currentRound ?? 0;
    final currentSession = scoreState.value?.currentSession;

    if (roundIndex < 0 || roundIndex > scores.length) return;

    if (roundIndex == scores.length) {
      // 添加currentRound有效性检查
      final canAddNewRound = currentRound == 0 ||
          currentSession!.scores.every((s) {
            // 调整索引访问逻辑
            final lastRoundIndex = currentRound - 1;
            return s.roundScores.length > lastRoundIndex &&
                s.roundScores[lastRoundIndex] != null;
          });

      if (canAddNewRound) {
        scoreNotifier.addNewRound();
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
          scoreNotifier.updateScore(
            player.pid,
            roundIndex,
            newValue,
          );
        },
      ),
    );
  }
}

class _ScoreBoard extends ConsumerStatefulWidget {
  final Poker50Template template;
  final GameSession session;

  const _ScoreBoard({required this.template, required this.session});

  @override
  ConsumerState<_ScoreBoard> createState() => _ScoreBoardState();
}

class _ScoreBoardState extends ConsumerState<_ScoreBoard> {
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
    // 监听内容区域的滚动事件，同步到标题行
    _contentHorizontalController.addListener(() {
      _headerHorizontalController.jumpTo(_contentHorizontalController.offset);
    });
    // 在初始化时更新高亮位置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scoreProvider.notifier).updateHighlight();
    });
  }


  // 抽取滚动逻辑到单独的方法
  void _scrollToHighlight() {
    final highlight = ref.read(scoreProvider).value?.currentHighlight;
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
    final currentRound = ref.watch(scoreProvider).when(
          loading: () => 0,
          error: (err, stack) => 0,
          data: (state) => state.currentRound,
        );

    // 添加监听器监听分数滚动到高亮
    ref.listen(scoreProvider, (previous, next) {
      if (next.value?.currentHighlight != null) {
        Future.delayed(Duration(milliseconds: 100), () {
          _scrollToHighlight();
        });
      }
    });

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
class _ScoreEditDialog extends ConsumerStatefulWidget {
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

class _ScoreEditDialogState extends ConsumerState<_ScoreEditDialog> {
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
    final template = ref
        .read(templatesProvider.notifier)
        .getTemplate(widget.templateId) as Poker50Template;
    final isAllowNegative = template.isAllowNegative;

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
            if (!isAllowNegative && value < 0) {
              AppSnackBar.warn('当前模板设置不允许输入负数！');
              return;
            }
            widget.onConfirm(value);
            ref.read(scoreProvider.notifier).updateHighlight();
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
class _ScoreCell extends ConsumerWidget {
  final int? score;
  final int total;
  final bool isHighlighted;

  const _ScoreCell({
    this.score,
    required this.total,
    required this.isHighlighted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
