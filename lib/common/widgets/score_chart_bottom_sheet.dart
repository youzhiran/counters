import 'dart:async';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:counters/common/model/base_template.dart';
import 'package:counters/common/model/game_session.dart';
import 'package:counters/common/model/player_info.dart';
import 'package:counters/common/widgets/player_widget.dart';
import 'package:counters/features/template/template_provider.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 数据点模型
class DataPoint {
  final String playerId;
  final int round;
  final int score;
  final Offset position;

  DataPoint({
    required this.playerId,
    required this.round,
    required this.score,
    required this.position,
  });

  // 添加 operator== 和 hashCode 以便比较 DataPoint 实例
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataPoint &&
          runtimeType == other.runtimeType &&
          playerId == other.playerId &&
          round == other.round &&
          score == other.score &&
          position == other.position;

  @override
  int get hashCode =>
      playerId.hashCode ^ round.hashCode ^ score.hashCode ^ position.hashCode;
}

// 折线图绘制器
class ScoreLineChartPainter extends CustomPainter {
  final Map<String, List<int>> playerScoreHistory;
  final Map<String, Color> playerColors;
  final int maxRounds;
  final int minScore;
  final int maxScore;
  final Color zeroLineColor; // 新增: 0分线颜色
  static const double margin = 15.0; // 统一定义边距

  ScoreLineChartPainter({
    required this.playerScoreHistory,
    required this.playerColors,
    required this.maxRounds,
    required this.minScore,
    required this.maxScore,
    required this.zeroLineColor, // 新增
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final axisPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1.0;

    // 绘制坐标轴
    // X轴（轮次）
    canvas.drawLine(Offset(margin, height - margin),
        Offset(width - margin, height - margin), axisPaint); // 调整X轴终点以适应右边距
    // Y轴（得分）
    canvas.drawLine(Offset(margin, margin), Offset(margin, height - margin),
        axisPaint); // 调整Y轴起点以适应上边距

    // 绘制0分线
    final double scoreRange = (maxScore - minScore).toDouble();
    if (scoreRange > 0 && minScore <= 0 && maxScore >= 0) {
      final yScale = (height - margin * 2) / scoreRange;
      final yZero = height - margin - (0 - minScore) * yScale;
      // 确保0分线在图表绘制区域内
      if (yZero >= margin && yZero <= height - margin) {
        final zeroLinePaint = Paint()
          ..color = zeroLineColor // 使用传入的颜色
          ..strokeWidth = 1.0;
        canvas.drawLine(Offset(margin, yZero), Offset(width - margin, yZero),
            zeroLinePaint);
      }
    }

    // 绘制每个玩家的折线
    playerScoreHistory.forEach((playerId, scores) {
      final path = Path();
      final paint = Paint()
        ..color = playerColors[playerId] ?? Colors.blue
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      // 确保 maxRounds-1 不为0，如果只有一轮，则xStep没有意义，点直接绘制在起始位置
      final double effectiveMaxRounds =
          (maxRounds > 1 ? maxRounds - 1 : 1).toDouble();
      final xStep = (width - margin * 2) / effectiveMaxRounds;
      // 调整 yScale 以处理 minScore
      final double scoreRange = (maxScore - minScore).toDouble();
      final yScale = (height - margin * 2) / (scoreRange > 0 ? scoreRange : 1);

      for (var i = 0; i < scores.length; i++) {
        final x = margin + i * xStep;
        // Y轴原点在顶部，需要根据 minScore 调整
        // (scores[i] - minScore) 是相对最低点的偏移量
        final y = height - margin - (scores[i] - minScore) * yScale;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
        // 绘制数据点
        canvas.drawCircle(
            Offset(x, y),
            3,
            Paint()
              ..color = playerColors[playerId] ?? Colors.blue
              ..style = PaintingStyle.fill);
      }
      // 只绘制线条，不填充
      canvas.drawPath(path, paint);
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 带提示框的图表组件
class ScoreChartWithTooltip extends StatefulWidget {
  final Map<String, List<int>> playerScoreHistory;
  final Map<String, Color> playerColors;
  final Map<String, String> playerNames;
  final int maxRounds;
  final int minScore; // 新增
  final int maxScore;
  final Size size;

  const ScoreChartWithTooltip({
    super.key,
    required this.playerScoreHistory,
    required this.playerColors,
    required this.playerNames,
    required this.maxRounds,
    required this.minScore, // 新增
    required this.maxScore,
    required this.size,
  });

  @override
  State<ScoreChartWithTooltip> createState() => _ScoreChartWithTooltipState();
}

class _ScoreChartWithTooltipState extends State<ScoreChartWithTooltip> {
  List<DataPoint> _activePoints = []; // 修改：从单个DataPoint? 改为 List<DataPoint>
  Timer? _hideTimer;

  static const double _painterMargin =
      ScoreLineChartPainter.margin; // 与Painter的边距一致

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) => _updateActivePoint(details.localPosition),
      // 立即响应以显示Tooltip
      onPanUpdate: (details) => _updateActivePoint(details.localPosition),
      onTapDown: (details) => _updateActivePoint(details.localPosition),
      onPanEnd: (_) => _scheduleHide(),
      onTapUp: (_) => _scheduleHide(),
      child: Stack(
        children: [
          CustomPaint(
            size: widget.size,
            painter: ScoreLineChartPainter(
              playerScoreHistory: widget.playerScoreHistory,
              playerColors: widget.playerColors,
              maxRounds: widget.maxRounds,
              minScore: widget.minScore,
              maxScore: widget.maxScore,
              zeroLineColor: Theme.of(context).colorScheme.primary, // 从主题获取颜色
            ),
          ),
          if (_activePoints.isNotEmpty) // 修改：检查 _activePoints 是否为空
            Positioned(
              left: _calculateTooltipX(
                  _activePoints.first.position.dx), // 修改：使用第一个点定位
              top: _calculateTooltipY(
                  _activePoints.first.position.dy), // 修改：使用第一个点定位
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha((0.7 * 255).toInt()),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.8 * 255).toInt()),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  // 修改：使用Column显示多个点的信息
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: _activePoints.map((point) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.playerNames[point.playerId] ?? '未知玩家',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '轮次: ${point.round + 1}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                          Text(
                            '总分: ${point.score}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                          if (_activePoints.length > 1 &&
                              point != _activePoints.last)
                            const Divider(
                                color: Colors.white54,
                                height: 8,
                                thickness: 0.5)
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _calculateTooltipX(double x) {
    // 假设Tooltip宽度约为100，根据实际内容调整
    const double tooltipWidth = 100.0;
    // 确保Tooltip不会超出右边界
    final maxX = widget.size.width - tooltipWidth - _painterMargin; // 考虑右边距
    // 确保Tooltip不会超出左边界
    return math
        .max(_painterMargin, x - tooltipWidth / 2)
        .clamp(_painterMargin, maxX);
  }

  double _calculateTooltipY(double y) {
    // 估算Tooltip高度，考虑多个条目
    final double estimatedItemHeight = 55.0; // 估算每个条目的高度 (名称+轮次+分数+内边距)
    final double verticalPadding = 16.0; // Tooltip容器的上下总padding (8*2)
    final double dividerHeight = _activePoints.length > 1
        ? (_activePoints.length - 1) * 1.0
        : 0; // 估算分隔线总高度

    final estimatedTooltipHeight = _activePoints.isNotEmpty
        ? (_activePoints.length * estimatedItemHeight) +
            verticalPadding +
            dividerHeight
        : 60.0; // fallback or default height for a single item

    // 向上偏移一点，避免直接覆盖数据点
    double targetY = y - estimatedTooltipHeight - 10; // 10是额外的偏移量
    // 确保Tooltip不会超出上下边界
    // clamp的下限是 _painterMargin (顶部), 上限是 widget.size.height - estimatedTooltipHeight - _painterMargin (底部)
    return targetY.clamp(_painterMargin,
        widget.size.height - estimatedTooltipHeight - _painterMargin);
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _activePoints.clear()); // 修改：清空列表
      }
    });
  }

  void _updateActivePoint(Offset position) {
    _hideTimer?.cancel(); // 取消隐藏定时器，因为用户正在交互
    final width = widget.size.width;
    final height = widget.size.height;

    final double effectiveMaxRounds =
        (widget.maxRounds > 1 ? widget.maxRounds - 1 : 1).toDouble();
    final xStep = (width - _painterMargin * 2) / effectiveMaxRounds;
    // 调整 yScale 以处理 minScore
    final double scoreRange = (widget.maxScore - widget.minScore).toDouble();
    final yScale =
        (height - _painterMargin * 2) / (scoreRange > 0 ? scoreRange : 1);

    List<DataPoint> newActivePoints = []; // 修改：用于收集所有符合条件的点
    double minDistance = 20; // 最小检测距离 (半径)

    widget.playerScoreHistory.forEach((playerId, scores) {
      for (var i = 0; i < scores.length; i++) {
        final x = _painterMargin + i * xStep;
        // Y轴原点在顶部，需要根据 minScore 调整
        final y =
            height - _painterMargin - (scores[i] - widget.minScore) * yScale;
        final distance = (position - Offset(x, y)).distance;

        if (distance < minDistance) {
          newActivePoints.add(DataPoint(
            // 修改：添加点到列表
            playerId: playerId,
            round: i,
            score: scores[i],
            position: Offset(x, y),
          ));
        }
      }
    });

    // 可选：对点进行排序，例如按分数或玩家ID，以确保显示顺序的一致性
    // 这里简单地按玩家ID和轮次排序
    newActivePoints.sort((a, b) {
      int playerCompare = a.playerId.compareTo(b.playerId);
      if (playerCompare != 0) return playerCompare;
      return a.round.compareTo(b.round);
    });

    // 仅当点列表变化时更新
    // listEquals 需要 'package:flutter/foundation.dart'，通常已由 material.dart 导入
    if (!listEquals(_activePoints, newActivePoints)) {
      setState(() {
        _activePoints = newActivePoints;
      });
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }
}

// BottomSheet的主体Widget
class ScoreChartBottomSheet extends ConsumerWidget {
  final GameSession session;

  const ScoreChartBottomSheet({super.key, required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final template = ref.watch(templatesProvider).valueOrNull?.firstWhereOrNull(
          (t) => t.tid == session.templateId,
        );

    final chartContent =
        _buildScoreLineChartContent(context, ref, session, template);

    return Container(
      height: MediaQuery.of(context).size.height * 0.6, // 可以根据内容调整
      padding: const EdgeInsets.only(
          top: 8.0, left: 8.0, right: 8.0, bottom: 8.0), // 顶部内边距减少，为手柄留空间
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // 使用主题颜色
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch, // 使子项宽度填充
        children: [
          // 添加拖动手柄
          Center(
            child: Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 8.0), // 与标题的间距
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0), // 为标题添加水平边距
            child: Text(
              "计分走势图",
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: chartContent,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreLineChartContent(BuildContext context, WidgetRef ref,
      GameSession session, BaseTemplate? template) {
    final playerScoreHistory = <String, List<int>>{};
    final playerColors = <String, Color>{};
    final playerNames = <String, String>{};

    final playersMap = <String, PlayerInfo>{
      for (var p in template?.players ?? []) p.pid: p
    };

    // 计算每个玩家每轮的累计得分
    for (var i = 0; i < session.scores.length; i++) {
      final score = session.scores[i];
      final scoreHistory = <int>[];
      int cumulativeScore = 0;

      for (var roundScore in score.roundScores) {
        // 如果 roundScore 为 null，则当前轮次不计分，但后续轮次应继续累计
        cumulativeScore += (roundScore ?? 0);
        scoreHistory.add(cumulativeScore);
      }
      // 只有当有实际得分记录时才添加到历史记录
      if (score.roundScores.any((rs) => rs != null) ||
          scoreHistory.isNotEmpty) {
        playerScoreHistory[score.playerId] = scoreHistory;
      }

      final player = playersMap[score.playerId];
      if (player != null) {
        final colorIndex =
            player.pid.hashCode % PlayerAvatar.avatarColors.length;
        playerColors[score.playerId] = PlayerAvatar.avatarColors[colorIndex];
        playerNames[score.playerId] = player.name;
      } else {
        // Fallback if player info not found in template
        playerColors[score.playerId] =
            Colors.primaries[i % Colors.primaries.length];
        playerNames[score.playerId] = '玩家 ${i + 1}';
      }
    }

    int maxRounds = 0;
    int minScore = 0; // 用于处理负分情况
    int maxScore = 0;

    bool hasScores = false; // 标记是否有任何分数
    bool firstPlayerWithScores = true; // 用于正确初始化minScore和maxScore

    playerScoreHistory.forEach((_, scores) {
      if (scores.isNotEmpty) {
        hasScores = true; // 发现有分数列表不为空
        final playerMinScore = scores.reduce(math.min);
        final playerMaxScore = scores.reduce(math.max);

        if (firstPlayerWithScores) {
          minScore = playerMinScore;
          maxScore = playerMaxScore;
          firstPlayerWithScores = false;
        } else {
          if (playerMinScore < minScore) minScore = playerMinScore;
          if (playerMaxScore > maxScore) maxScore = playerMaxScore;
        }
        if (scores.length > maxRounds) maxRounds = scores.length;
      }
    });

    int finalMinForPainter = minScore;
    int finalMaxForPainter = maxScore;

    if (hasScores) {
      // 确保图表的Y轴范围包含0
      if (finalMinForPainter > 0) {
        finalMinForPainter = 0;
      }
      if (finalMaxForPainter < 0) {
        finalMaxForPainter = 0;
      }

      // 如果调整后，范围为零（例如，所有分数实际上都是0），
      // 创建一个围绕0的小的默认范围。
      if (finalMinForPainter == finalMaxForPainter) {
        // 这意味着共同值是0
        finalMinForPainter = -1;
        finalMaxForPainter = 1;
      }
    } else {
      // 如果没有实际分数，但可能maxRounds > 0（例如，模板有轮次但未输入分数）
      // "暂无足够数据"的检查会处理maxRounds也是0的情况。
      // 如果我们仍然要绘制一个空的图表（例如，maxRounds > 0但没有分数）:
      finalMinForPainter = -1;
      finalMaxForPainter = 1;
    }

    // 确保有数据可绘制
    // 如果 maxRounds 为 0 (意味着没有轮次数据) 并且 没有任何玩家有分数记录，则显示无数据提示
    if (maxRounds == 0 && !hasScores) {
      return const Center(child: Text('暂无足够数据或轮次信息生成图表'));
    }

    // 如果所有分数都是0，maxScore可能是0。我们需要让yScale正常工作。

    return LayoutBuilder(
      builder: (lbContext, constraints) {
        if (constraints.maxWidth == 0 || constraints.maxHeight == 0) {
          return const Center(child: Text('图表区域过小'));
        }
        return ScoreChartWithTooltip(
          playerScoreHistory: playerScoreHistory,
          playerColors: playerColors,
          playerNames: playerNames,
          maxRounds: maxRounds,
          minScore: finalMinForPainter,
          // 使用调整后的minScore
          maxScore: finalMaxForPainter,
          // 使用调整后的maxScore
          size: Size(constraints.maxWidth, constraints.maxHeight),
        );
      },
    );
  }
}
