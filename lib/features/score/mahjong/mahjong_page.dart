import 'package:counters/app/state.dart';
import 'package:counters/common/model/base_template.dart';
import 'package:counters/common/model/game_session.dart';
import 'package:counters/common/model/mahjong.dart';
import 'package:counters/common/model/player_info.dart';
import 'package:counters/common/model/player_score.dart';
import 'package:counters/common/widgets/player_widget.dart';
import 'package:counters/features/score/base_page.dart';
import 'package:counters/features/score/score_provider.dart';
import 'package:counters/features/score/widgets/base_score_edit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MahjongPage extends BaseSessionPage {
  const MahjongPage({super.key, required super.templateId});

  @override
  ConsumerState<MahjongPage> createState() => _MahjongPageState();
}

class _MahjongPageState extends BaseSessionPageState<MahjongPage> {
  final Map<String, TextEditingController> _scoreControllers = {};

  @override
  void dispose() {
    for (var controller in _scoreControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget buildGameBody(
      BuildContext context, BaseTemplate template, GameSession session) {
    final mahjongTemplate = template as MahjongTemplate;

    return Column(
      children: [
        Expanded(
          child: _ScoreBoard(template: mahjongTemplate, session: session),
        ),
        // QuickInputPanel(key: ValueKey('Panel')), // 麻将计分通常比较复杂，暂时移除快捷输入
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

  const _ScoreColumn({
    required this.templateId,
    required this.player,
    required this.scores,
    required this.currentRound,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 80,
      child: Column(
        children: [
          // 历史回合得分
          ...List.generate(currentRound, (index) {
            final score = index < scores.length ? scores[index] : null;

            return Expanded(
              child: RepaintBoundary(
                child: GestureDetector(
                  onTap: () {
                    final currentScore =
                        index < scores.length ? scores[index] ?? 0 : 0;

                    globalState.showCommonDialog(
                      child: BaseScoreEditDialog(
                        templateId: templateId,
                        player: player,
                        initialValue: currentScore,
                        supportDecimal: true,
                        decimalMultiplier: 100,
                        round: index + 1, // 修复轮次显示：从1开始计数而不是0开始
                        onConfirm: (newValue) {
                          ref
                              .read(scoreProvider.notifier)
                              .updateScore(player.pid, index, newValue);
                        },
                      ),
                    );
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    child: _ScoreCell(
                      score: score,
                      total: scores
                          .take(index + 1)
                          .fold(0, (sum, item) => sum + (item ?? 0)),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ScoreBoard extends ConsumerStatefulWidget {
  final MahjongTemplate template;
  final GameSession session;

  const _ScoreBoard({required this.template, required this.session});

  @override
  ConsumerState<_ScoreBoard> createState() => _ScoreBoardState();
}

class _ScoreBoardState extends ConsumerState<_ScoreBoard> {
  final ScrollController _horizontalScrollController = ScrollController();
  late final ScrollController _headerHorizontalController = ScrollController();
  late final ScrollController _contentHorizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _headerHorizontalController.dispose();
    _contentHorizontalController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _contentHorizontalController.addListener(() {
      if (_headerHorizontalController.hasClients &&
          _contentHorizontalController.hasClients) {
        _headerHorizontalController.jumpTo(_contentHorizontalController.offset);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentRound = ref.watch(scoreProvider).when(
          loading: () => 0,
          error: (err, stack) => 0,
          data: (state) => state.currentRound,
        );

    return Column(
      children: [
        SizedBox(
          height: 80,
          child: SingleChildScrollView(
            controller: _headerHorizontalController,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: _buildHeaderRow(),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: SingleChildScrollView(
                    controller: _contentHorizontalController,
                    scrollDirection: Axis.horizontal,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
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
                    style: const TextStyle(height: 1.2),
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
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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
              // 传递的是总轮次数，用于List.generate
            );
          }),
        ],
      ),
    );
  }
}

class _ScoreCell extends ConsumerWidget {
  final int? score; // 存储的仍然是乘以100后的整数
  final int total; // 存储的仍然是乘以100后的整数

  const _ScoreCell({
    this.score,
    required this.total,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 将整数分数转换为带两位小数的字符串进行显示
    final displayScore =
        score == null ? '--' : (score! / 100.0).toStringAsFixed(2);
    final displayTotal = (total / 100.0).toStringAsFixed(2);

    return Container(
      width: 80,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            score == null ? '--' : displayTotal,
            style: const TextStyle(
              fontSize: 18,
            ),
          ),
          if (score != null)
            Positioned(
              right: 0,
              top: 0,
              child: Text(
                (score! >= 0 ? '+' : '') + displayScore,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          if (score == null)
            const Positioned(
              right: 0,
              top: 0,
              child: Text('--', style: TextStyle(color: Colors.grey)),
            ),
        ],
      ),
    );
  }
}
