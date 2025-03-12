import 'dart:async';
import 'dart:math' as math;

import 'package:counters/widgets/player_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../db/player_info.dart';
import '../db/poker50.dart';
import '../providers/score_provider.dart';
import '../providers/template_provider.dart';

/// 快捷输入面板组件
/// 提供常用数值的快速输入按钮，支持左右滑动切换功能区
/// 支持上下滑动收起/展开面板
class QuickInputPanel extends StatefulWidget {
  const QuickInputPanel({super.key});

  @override
  State<QuickInputPanel> createState() => _QuickInputPanelState();
}

class _QuickInputPanelState extends State<QuickInputPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['快捷输入', '图表'];

  // 不同标签页的数字配置
  final List<int> _commonNumbers = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];

  // 面板状态控制
  bool _isPanelExpanded = true;

  // 添加面板高度控制
  double _panelHeight = 140.0; // 默认高度
  double _maxPanelHeight = 140.0; // 最大高度，将在build方法中更新

  // 常量定义，避免魔法数字
  static const double _defaultPanelHeight = 140.0;
  static const double _handleHeight = 20.0;
  static const double _tabHeight = 30.0;

  // 添加固定高度选项
  static const List<double> _snapHeights = [140.0, 240.0, 320.0];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);

    // 监听标签页变化，重置面板高度
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _panelHeight = _defaultPanelHeight; // 切换标签时重置为默认高度
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 添加一个状态变量来跟踪是否正在拖动
  bool _isDragging = false;

  // 构建拖动手柄
  Widget _buildDragHandle() {
    return GestureDetector(
      onVerticalDragStart: (_) {
        setState(() {
          _isDragging = true; // 开始拖动
        });
      },
      onVerticalDragUpdate: (details) {
        if (_isPanelExpanded) {
          setState(() {
            // 跟随手指移动调整高度
            _panelHeight = (_panelHeight - details.delta.dy).clamp(
              _defaultPanelHeight, // 最小高度
              _maxPanelHeight, // 最大高度
            );
          });
        }
      },
      onVerticalDragEnd: (details) {
        // 释放时吸附到最近的固定高度
        if (_isPanelExpanded) {
          _snapToNearestHeight();
          // 延迟一小段时间后再显示图表内容
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() {
                _isDragging = false; // 结束拖动
              });
            }
          });
        } else if (details.velocity.pixelsPerSecond.dy < -300) {
          // 快速向上滑动时展开面板
          setState(() => _isPanelExpanded = true);
          // 延迟一小段时间后再显示图表内容
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() {
                _isDragging = false; // 结束拖动
              });
            }
          });
        }
      },
      onTap: () {
        // 点击切换展开/收起状态
        setState(() => _isPanelExpanded = !_isPanelExpanded);
      },
      child: Container(
        width: double.infinity,
        height: _handleHeight,
        color: Colors.transparent,
        child: Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  // 添加吸附到最近高度的方法
  void _snapToNearestHeight() {
    // 过滤出不超过最大高度的吸附点
    final validSnapHeights =
        _snapHeights.where((height) => height <= _maxPanelHeight).toList();

    if (validSnapHeights.isEmpty) {
      return;
    }

    // 找出最接近当前高度的吸附点
    double nearestHeight = validSnapHeights.first;
    double minDistance = (_panelHeight - nearestHeight).abs();

    for (final height in validSnapHeights) {
      final distance = (_panelHeight - height).abs();
      if (distance < minDistance) {
        minDistance = distance;
        nearestHeight = height;
      }
    }

    // 使用动画平滑过渡到吸附高度
    setState(() {
      _panelHeight = nearestHeight;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 计算最大面板高度为屏幕高度的50%
    _maxPanelHeight = MediaQuery.of(context).size.height * 0.5;

    return Center(
      child: Card(
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.zero,
            bottomRight: Radius.zero,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildDragHandle(),
            _buildTabBar(context),
            _buildContentArea(),
          ],
        ),
      ),
    );
  }

  // 构建标签栏
  Widget _buildTabBar(BuildContext context) {
    return TabBar(
      controller: _tabController,
      tabs: _tabs
          .map((tab) => Tab(
                text: tab,
                height: _tabHeight, // 减小标签高度
              ))
          .toList(),
      labelColor: Theme.of(context).colorScheme.primary,
      unselectedLabelColor: Colors.grey,
      indicatorSize: TabBarIndicatorSize.label,
      indicatorWeight: 3,
      dividerHeight: 0,
      labelPadding: const EdgeInsets.symmetric(vertical: 2), // 减小标签内边距
    );
  }

  // 构建内容区域
  Widget _buildContentArea() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _isPanelExpanded ? _panelHeight : 0, // 使用动态高度
      child: TabBarView(
        controller: _tabController,
        physics: _isPanelExpanded
            ? const AlwaysScrollableScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        children: [
          _buildCommonNumbersTab(),
          _buildChartTab(),
        ],
      ),
    );
  }

  // 构建图表标签页
  Widget _buildChartTab() {
    final scoreProvider = context.read<ScoreProvider>();
    final currentSession = scoreProvider.currentSession;

    // 如果正在拖动，显示占位符
    if (_isDragging) {
      return const Center(child: Text('调整面板高度中...'));
    }

    return currentSession != null
        ? _buildScoreLineChart(currentSession)
        : const Center(child: Text('暂无游戏数据'));
  }

  // 常用数字标签页
  Widget _buildCommonNumbersTab() {
    return _buildNumberGrid(_commonNumbers);
  }

  // 构建数字网格
  Widget _buildNumberGrid(List<int> numbers) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 0,
        runSpacing: 0,
        alignment: WrapAlignment.center,
        children: numbers.map((number) => _buildNumberButton(number)).toList(),
      ),
    );
  }

  // 构建数字按钮
  Widget _buildNumberButton(int number) {
    return SizedBox(
      width: 80, // 固定按钮宽度
      child: ActionChip(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // 直角
          side: BorderSide.none, // 移除边框
        ),
        label: Container(
          width: double.infinity, // 标签填满宽度
          alignment: Alignment.center,
          child: Text(number >= 0 ? '+$number' : '$number'),
        ),
        labelPadding: EdgeInsets.zero,
        // 移除标签内边距
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onPressed: () => _handleNumberPressed(number),
      ),
    );
  }

  // 处理数字按钮点击
  void _handleNumberPressed(int number) {
    final provider = context.read<ScoreProvider>();
    final highlight = provider.currentHighlight;
    final session = provider.currentSession;

    HapticFeedback.mediumImpact();

    if (highlight != null && session != null) {
      final playerScore = session.scores.firstWhere(
        (s) => s.playerId == highlight.key,
        orElse: () => PlayerScore(playerId: 'invalid', roundScores: []),
      );

      if (playerScore.playerId != 'invalid') {
        final currentValue = playerScore.roundScores.length > highlight.value
            ? playerScore.roundScores[highlight.value] ?? 0
            : 0;
        provider.updateScore(
          highlight.key,
          highlight.value,
          currentValue + number,
        );
      }
    }
  }

  // 构建得分折线图
  Widget _buildScoreLineChart(GameSession session) {
    // 获取所有玩家的得分历史
    final playerScoreHistory = <String, List<int>>{};
    final playerColors = <String, Color>{};
    final playerNames = <String, String>{};

    // 提前获取模板数据
    final template =
        context.read<TemplateProvider>().getTemplate(session.templateId);
    final playersMap = <String, PlayerInfo>{
      for (var p in template?.players ?? []) p.id: p
    };

    // 计算每个玩家每轮的累计得分
    for (var i = 0; i < session.scores.length; i++) {
      final score = session.scores[i];
      final scoreHistory = <int>[];
      int cumulativeScore = 0;

      for (var roundScore in score.roundScores) {
        if (roundScore == null) {
          continue;
        }
        cumulativeScore += roundScore;
        scoreHistory.add(cumulativeScore);
      }

      playerScoreHistory[score.playerId] = scoreHistory;
      playerColors[score.playerId] =
          Colors.primaries[i % Colors.primaries.length];
      // 获取玩家信息
      final player = playersMap[score.playerId];
      if (player != null) {
        // 使用玩家ID生成固定的颜色（与PlayerAvatar保持一致）
        final colorIndex =
            player.id.hashCode % PlayerAvatar.avatarColors.length;
        playerColors[score.playerId] = PlayerAvatar.avatarColors[colorIndex];
        playerNames[score.playerId] = player.name;
      } else {
        // fallback颜色
        playerColors[score.playerId] =
            Colors.primaries[i % Colors.primaries.length];
        playerNames[score.playerId] = '玩家 ${i + 1}';
      }
    }

    // 找出最大轮次和最大分数，用于绘图比例计算
    int maxRounds = 0;
    int maxScore = 0;

    playerScoreHistory.forEach((_, scores) {
      if (scores.length > maxRounds) maxRounds = scores.length;
      if (scores.isNotEmpty) {
        final playerMaxScore = scores.reduce(math.max);
        if (playerMaxScore > maxScore) maxScore = playerMaxScore;
      }
    });

    // 确保有数据可绘制
    if (maxRounds == 0 || maxScore == 0) {
      return const Center(child: Text('暂无足够数据生成图表'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return ScoreChartWithTooltip(
          playerScoreHistory: playerScoreHistory,
          playerColors: playerColors,
          playerNames: playerNames,
          maxRounds: maxRounds,
          maxScore: maxScore,
          size: Size(constraints.maxWidth, constraints.maxHeight),
        );
      },
    );
  }
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
  // 当前触摸位置附近的数据点
  DataPoint? _activePoint;
  Timer? _hideTimer;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) => _updateActivePoint(details.localPosition),
      onTapDown: (details) => _updateActivePoint(details.localPosition),
      onPanEnd: (_) => _scheduleHide(),
      onTapUp: (_) => _scheduleHide(),
      child: Stack(
        children: [
          // 绘制图表
          CustomPaint(
            size: widget.size,
            painter: ScoreLineChartPainter(
              playerScoreHistory: widget.playerScoreHistory,
              playerColors: widget.playerColors,
              maxRounds: widget.maxRounds,
              maxScore: widget.maxScore,
            ),
          ),
          // 显示提示框
          if (_activePoint != null)
            Positioned(
              left: _calculateTooltipX(_activePoint!.position.dx),
              top: _calculateTooltipY(_activePoint!.position.dy),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
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
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      '总分: ${_activePoint!.score}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 计算X轴位置（考虑右侧边界）
  double _calculateTooltipX(double x) {
    const double tooltipWidth = 80.0;
    final maxX = widget.size.width - tooltipWidth;
    return x.clamp(0.0, maxX);
  }

  // 计算Y轴位置（考虑顶部边界）
  double _calculateTooltipY(double y) {
    const double tooltipHeight = 80.0;
    final maxY = widget.size.height - tooltipHeight;
    return y.clamp(0.0, maxY);
  }

  // 定时隐藏方法
  void _scheduleHide() {
    _hideTimer?.cancel(); // 取消之前的定时器
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _activePoint = null);
      }
    });
  }

  // 更新当前活跃的数据点
  void _updateActivePoint(Offset position) {
    final width = widget.size.width;
    final height = widget.size.height;
    final xStep =
        (width - 40) / (widget.maxRounds > 1 ? widget.maxRounds - 1 : 1);
    final yScale = (height - 40) / (widget.maxScore > 0 ? widget.maxScore : 1);

    DataPoint? closestPoint;
    double minDistance = 20; // 最小检测距离

    widget.playerScoreHistory.forEach((playerId, scores) {
      for (var i = 0; i < scores.length; i++) {
        final x = 30 + i * xStep;
        final y = height - 20 - scores[i] * yScale;
        final distance = (position - Offset(x, y)).distance;

        if (distance < minDistance) {
          minDistance = distance;
          closestPoint = DataPoint(
            playerId: playerId,
            round: i,
            score: scores[i],
            position: Offset(x, y),
          );
        }
      }
    });

    setState(() {
      _activePoint = closestPoint;
    });
  }
}

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
    // 调整坐标轴位置，使原点距离左下角15dp
    const double margin = 15.0;
    // 绘制坐标轴
    // X轴（轮次）
    canvas.drawLine(Offset(margin, height - margin),
        Offset(width, height - margin), axisPaint);
    // Y轴（得分）
    canvas.drawLine(
        Offset(margin, 0), Offset(margin, height - margin), axisPaint);
    // 绘制每个玩家的折线
    playerScoreHistory.forEach((playerId, scores) {
      final path = Path();
      final paint = Paint()
        ..color = playerColors[playerId] ?? Colors.blue
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      final xStep = (width - margin * 2) / (maxRounds > 1 ? maxRounds - 1 : 1);
      final yScale = (height - margin * 2) / (maxScore > 0 ? maxScore : 1);
      for (var i = 0; i < scores.length; i++) {
        final x = margin + i * xStep;
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
