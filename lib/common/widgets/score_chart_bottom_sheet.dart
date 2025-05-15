import 'dart:async';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:counters/common/model/base_template.dart';
import 'package:counters/common/model/game_session.dart';
import 'package:counters/common/model/player_info.dart';
import 'package:counters/common/widgets/player_widget.dart';
import 'package:counters/features/template/template_provider.dart';
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
}

// 折线图绘制器
class ScoreLineChartPainter extends CustomPainter {
  final Map<String, List<int>> playerScoreHistory;
  final Map<String, Color> playerColors;
  final int maxRounds;
  final int maxScore;
  static const double margin = 15.0; // 统一定义边距

  ScoreLineChartPainter({
    required this.playerScoreHistory,
    required this.playerColors,
    required this.maxRounds,
    required this.maxScore,
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
      final yScale = (height - margin * 2) / (maxScore > 0 ? maxScore : 1);

      for (var i = 0; i < scores.length; i++) {
        final x = margin + i * xStep;
        // Y轴原点在顶部，所以是 height - margin - score_value
        final y = height - margin - scores[i] * yScale;
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
  final int maxScore;
  final Size size;

  const ScoreChartWithTooltip({
    super.key,
    required this.playerScoreHistory,
    required this.playerColors,
    required this.playerNames,
    required this.maxRounds,
    required this.maxScore,
    required this.size,
  });

  @override
  State<ScoreChartWithTooltip> createState() => _ScoreChartWithTooltipState();
}

class _ScoreChartWithTooltipState extends State<ScoreChartWithTooltip> {
  DataPoint? _activePoint;
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
              maxScore: widget.maxScore,
            ),
          ),
          if (_activePoint != null)
            Positioned(
              left: _calculateTooltipX(_activePoint!.position.dx),
              top: _calculateTooltipY(_activePoint!.position.dy),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.playerNames[_activePoint!.playerId] ?? '未知玩家',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '轮次: ${_activePoint!.round + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Text(
                      '总分: ${_activePoint!.score}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
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
    // 假设Tooltip高度约为80，根据实际内容调整
    const double tooltipHeight = 60.0;
    // 向上偏移一点，避免直接覆盖数据点
    double targetY = y - tooltipHeight - 5;
    // 确保Tooltip不会超出上下边界
    return targetY.clamp(
        _painterMargin, widget.size.height - tooltipHeight - _painterMargin);
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _activePoint = null);
      }
    });
  }

  void _updateActivePoint(Offset position) {
    _hideTimer?.cancel(); // 取消隐藏定时器，因为用户正在交互
    final width = widget.size.width;
    final height = widget.size.height;

    // 使用与Painter一致的计算方式
    final double effectiveMaxRounds =
        (widget.maxRounds > 1 ? widget.maxRounds - 1 : 1).toDouble();
    final xStep = (width - _painterMargin * 2) / effectiveMaxRounds;
    final yScale = (height - _painterMargin * 2) /
        (widget.maxScore > 0 ? widget.maxScore : 1);

    DataPoint? closestPoint;
    double minDistance = 20; // 最小检测距离 (半径)

    widget.playerScoreHistory.forEach((playerId, scores) {
      for (var i = 0; i < scores.length; i++) {
        final x = _painterMargin + i * xStep;
        final y = height - _painterMargin - scores[i] * yScale;
        final distance = (position - Offset(x, y)).distance;

        if (distance < minDistance) {
          minDistance = distance;
          closestPoint = DataPoint(
            playerId: playerId,
            round: i,
            score: scores[i],
            position: Offset(x, y), // 使用计算出的精确点位置
          );
        }
      }
    });

    if (closestPoint != null && _activePoint != closestPoint) {
      // 仅当点变化时更新
      setState(() {
        _activePoint = closestPoint;
      });
    } else if (closestPoint == null && _activePoint != null) {
      // 如果移出所有点，则清除
      setState(() {
        _activePoint = null;
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

    playerScoreHistory.forEach((_, scores) {
      if (scores.length > maxRounds) maxRounds = scores.length;
      if (scores.isNotEmpty) {
        // 同时计算min和max，以适应负分
        final playerMinScore = scores.reduce(math.min);
        final playerMaxScore = scores.reduce(math.max);
        if (playerMinScore < minScore) minScore = playerMinScore;
        if (playerMaxScore > maxScore) maxScore = playerMaxScore;
      }
    });

    // 如果所有分数都是0，maxScore会是0。Painter的yScale处理 (maxScore > 0 ? maxScore : 1)
    // 如果有负分，minScore会小于0。当前Painter的Y轴从0开始，需要调整以显示负分。
    // 为简单起见，当前版本我们将Y轴的0点视为最低点，即所有分数都会画在0或以上。
    // 如果需要显示负分，ScoreLineChartPainter中的yScale和点绘制逻辑需要修改以考虑minScore。
    // 目前，我们仍使用maxScore作为主要缩放依据，且 Painter 假设最低分为0。

    // 确保有数据可绘制
    // 原始逻辑: if (maxRounds == 0 || maxScore == 0)
    // 改进：如果maxRounds为0，则没有数据。maxScore为0是允许的（例如所有得分都是0）
    if (maxRounds == 0 &&
        playerScoreHistory.values.every((list) => list.isEmpty)) {
      return const Center(child: Text('暂无足够数据或轮次信息生成图表'));
    }

    // 如果所有分数都是0，maxScore可能是0。我们需要让yScale正常工作。
    // ScoreLineChartPainter 中的 yScale 已经是 (height - margin * 2) / (maxScore > 0 ? maxScore : 1);
    // 这是对的，如果maxScore是0，它会用1来避免除零，所有0分点会画在x轴上。

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
          // painter会处理maxRounds=1的情况
          maxScore: maxScore,
          size: Size(constraints.maxWidth, constraints.maxHeight),
        );
      },
    );
  }
}
