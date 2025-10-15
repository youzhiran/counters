import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 一个有状态的骰子弹窗小部件
class DiceRollerDialog extends StatefulWidget {
  const DiceRollerDialog({super.key});

  @override
  State<DiceRollerDialog> createState() => _DiceRollerDialogState();
}

class _DiceRollerDialogState extends State<DiceRollerDialog>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  late Animation<Offset> _shakeAnimation;
  final _random = Random();
  bool _isInitial = true;
  int _diceCount = 1;
  List<int> _currentValues = <int>[];
  int _rollSequence = 0;
  double _lastControllerValue = 0;
  double _valueUpdateAccumulator = 0;
  final List<_RollHistoryEntry> _history = <_RollHistoryEntry>[];

  static const List<int> _diceCountOptions = <int>[1, 2, 3, 4, 5, 6];
  static const int _historyLimit = 10;
  static const double _minValueUpdateInterval = 0.02;
  static const double _maxValueUpdateInterval = 0.12;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );
    final curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubicEmphasized,
    );

    _shakeAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(10, -12),
        ),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(10, -12),
          end: const Offset(-14, 10),
        ),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(-14, 10),
          end: const Offset(12, 6),
        ),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(12, 6),
          end: const Offset(-8, -6),
        ),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(-8, -6),
          end: Offset.zero,
        ),
        weight: 20,
      ),
    ]).animate(curvedAnimation);

    _glowAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 0.9, curve: Curves.easeInOut),
    );

    _lastControllerValue = 0;
    _valueUpdateAccumulator = 0;

    _controller.addListener(() {
      if (!mounted) {
        return;
      }
      if (!_controller.isAnimating) {
        return;
      }

      final double progress = _controller.value;
      final double delta = (progress - _lastControllerValue).abs();
      _lastControllerValue = progress;
      _valueUpdateAccumulator += delta;

      final double velocity = _computeVelocity(progress);
      final double interval = lerpDouble(
        _maxValueUpdateInterval,
        _minValueUpdateInterval,
        velocity,
      )!
          .clamp(_minValueUpdateInterval, _maxValueUpdateInterval)
          .toDouble();

      final bool shouldUpdateValues =
          _valueUpdateAccumulator >= interval || _currentValues.isEmpty;

      if (shouldUpdateValues) {
        _valueUpdateAccumulator = 0;
      }

      setState(() {
        if (shouldUpdateValues) {
          _currentValues =
              List<int>.generate(_diceCount, (_) => _random.nextInt(6) + 1);
        }
      });
    });

    _controller.addStatusListener((status) {
      if (!mounted) {
        return;
      }
      if (status == AnimationStatus.completed) {
        setState(() {
          if (_currentValues.isEmpty) {
            _currentValues =
                List<int>.generate(_diceCount, (_) => _random.nextInt(6) + 1);
          }
          _rollSequence++;
          _history.insert(
            0,
            _RollHistoryEntry(
              sequence: _rollSequence,
              values: List<int>.from(_currentValues),
              timestamp: DateTime.now(),
            ),
          );
          if (_history.length > _historyLimit) {
            _history.removeRange(_historyLimit, _history.length);
          }
        });
      } else if (status == AnimationStatus.dismissed) {
        setState(() {});
      }
    });
  }

  void _rollDice() {
    if (_controller.isAnimating) return;
    if (_isInitial) {
      setState(() {
        _isInitial = false;
      });
    }
    HapticFeedback.mediumImpact();
    _lastControllerValue = 0;
    _valueUpdateAccumulator = 0;
    _controller.forward(from: 0);
  }

  void _onDiceCountChanged(int? newCount) {
    if (newCount == null || newCount == _diceCount) {
      return;
    }
    if (_controller.isAnimating) {
      _controller.stop();
    }
    _controller.reset();
    _lastControllerValue = 0;
    _valueUpdateAccumulator = 0;
    setState(() {
      _diceCount = newCount;
      _isInitial = true;
      _currentValues = <int>[];
    });
  }

  void _showFullHistory() {
    if (_history.isEmpty) {
      return;
    }
    showDialog<void>(
      context: context,
      builder: (context) => _HistoryDialog(history: _history),
    );
  }

  /// 根据标准抛物线 4t(1 - t) 计算速度因子，使摇骰速度呈现先慢后快再慢的节奏
  double _computeVelocity(double progress) {
    final double velocity = 4 * progress * (1 - progress);
    return velocity.clamp(0.0, 1.0);
  }

  /// 对速度曲线进行积分获取旋转累计进度，驱动旋转角度渐进增加
  double _computeSpinProgress(double progress) {
    final double integral =
        2 * progress * progress - (4 / 3) * progress * progress * progress;
    const double normalizer = 2 / 3;
    final double normalized = (integral / normalizer).clamp(0.0, 1.0);
    return normalized;
  }

  String _buildResultText() {
    if (_currentValues.isEmpty) {
      return '等待投掷结果';
    }
    if (_currentValues.length == 1) {
      return '本次点数：${_currentValues.first}';
    }
    final int total = _currentValues.fold<int>(0, (sum, value) => sum + value);
    final String detail = _currentValues.join(' + ');
    return '本次点数：$detail = $total';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final double controllerValue = _controller.value;
    final double spinVelocity = _computeVelocity(controllerValue);
    final double spinProgress = _computeSpinProgress(controllerValue);
    final glowFactor = _glowAnimation.value;
    final Offset shakeOffset = _shakeAnimation.value;
    final bool isRolling = _controller.isAnimating;
    final bool hasHistory = _history.isNotEmpty;
    final String resultText = _buildResultText();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              colorScheme.surfaceVariant.withOpacity(0.95),
              colorScheme.surface.withOpacity(0.98),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: colorScheme.primary.withOpacity(0.12 + glowFactor * 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.18 + glowFactor * 0.25),
              blurRadius: 32 + (18 * glowFactor),
              spreadRadius: 1 + glowFactor,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.casino_outlined,
                        color: colorScheme.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '掷骰子',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '点击骰面或按下按钮，即可开始。',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: colorScheme.surfaceVariant.withOpacity(0.45),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '每次投掷骰子数量',
                            style: textTheme.labelLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _diceCount,
                            isDense: true,
                            borderRadius: BorderRadius.circular(12),
                            items: _diceCountOptions
                                .map(
                                  (value) => DropdownMenuItem<int>(
                                    value: value,
                                    child: Text('$value 枚'),
                                  ),
                                )
                                .toList(),
                            onChanged: isRolling ? null : _onDiceCountChanged,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _rollDice,
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeInOutCubic,
                    alignment: Alignment.topCenter,
                    child: _DiceCard(
                      isInitial: _isInitial,
                      values: _currentValues,
                      expectedCount: _diceCount,
                      glowFactor: glowFactor,
                      isRolling: isRolling,
                      shakeOffset: shakeOffset,
                      spinVelocity: spinVelocity,
                      spinProgress: spinProgress,
                      controllerValue: controllerValue,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                AnimatedOpacity(
                  opacity: _isInitial ? 0.7 : 1,
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _isInitial ? '准备掷出骰子' : resultText,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _isInitial
                      ? const SizedBox.shrink()
                      : Text(
                          '可以再试一次，刷新点数',
                          key: const ValueKey('tip'),
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final bool isWide = constraints.maxWidth >= 420;
                    final double spacing = isWide ? 16 : 12;
                    final double maxButtonWidth = isWide
                        ? min(220.0, constraints.maxWidth / 2 - spacing / 2)
                        : constraints.maxWidth;

                    Widget buildRollButton() {
                      return SizedBox(
                        width: isWide ? maxButtonWidth : double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isRolling ? null : _rollDice,
                          icon: Icon(
                            isRolling
                                ? Icons.hourglass_bottom_rounded
                                : Icons.casino,
                          ),
                          label: Text(isRolling ? '摇动中...' : '立即摇骰'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      );
                    }

                    Widget buildCloseButton() {
                      return SizedBox(
                        width: isWide ? maxButtonWidth : double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('关闭'),
                        ),
                      );
                    }

                    if (isWide) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          buildRollButton(),
                          SizedBox(width: spacing),
                          buildCloseButton(),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        buildRollButton(),
                        SizedBox(height: spacing),
                        buildCloseButton(),
                      ],
                    );
                  },
                ),
                if (hasHistory) ...[
                  const SizedBox(height: 28),
                  _HistorySection(
                    history: _history,
                    onViewAll: _showFullHistory,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DiceCard extends StatelessWidget {
  const _DiceCard({
    required this.isInitial,
    required this.values,
    required this.expectedCount,
    required this.glowFactor,
    required this.isRolling,
    required this.shakeOffset,
    required this.spinVelocity,
    required this.spinProgress,
    required this.controllerValue,
  });

  final bool isInitial;
  final List<int> values;
  final int expectedCount;
  final double glowFactor;
  final bool isRolling;
  final Offset shakeOffset;
  final double spinVelocity;
  final double spinProgress;
  final double controllerValue;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.decelerate,
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 180),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withOpacity(0.96),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.18 + glowFactor * 0.12),
          width: 1.2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Transform.translate(
              offset: shakeOffset,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutBack,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: _DiceFacesGrid(
                      key: ValueKey(
                        '${values.isEmpty}-'
                        '${values.length}-${values.join(',')}-'
                        '$expectedCount-$isRolling',
                      ),
                      values: values.isEmpty
                          ? List<int>.filled(
                              expectedCount > 0 ? expectedCount : 1,
                              1,
                            )
                          : values,
                      isPlaceholder: values.isEmpty,
                      isRolling: isRolling,
                      spinVelocity: spinVelocity,
                      spinProgress: spinProgress,
                      controllerValue: controllerValue,
                    ),
                  ),
                  if (isInitial) const _DiceIntroOverlay(),
                ],
              ),
            ),
          ),
          if (isRolling)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: 0.12 + glowFactor * 0.18,
                  duration: const Duration(milliseconds: 200),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: colorScheme.primary.withOpacity(0.18),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DiceIntroOverlay extends StatelessWidget {
  const _DiceIntroOverlay();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: colorScheme.surface.withOpacity(0.82),
          border: Border.all(
            color: colorScheme.primary.withOpacity(0.15),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.touch_app_outlined,
              size: 48,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 10),
            Text(
              '轻触即可摇骰',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiceFacesGrid extends StatelessWidget {
  const _DiceFacesGrid({
    super.key,
    required this.values,
    this.isPlaceholder = false,
    required this.isRolling,
    required this.spinVelocity,
    required this.spinProgress,
    required this.controllerValue,
  });

  final List<int> values;
  final bool isPlaceholder;
  final bool isRolling;
  final double spinVelocity;
  final double spinProgress;
  final double controllerValue;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const double spacing = 12;
        final double maxWidth = constraints.maxWidth;
        final int count = values.length;
        int columns;
        if (count <= 1) {
          columns = 1;
        } else if (count == 2) {
          columns = 2;
        } else if (count <= 4) {
          columns = 2;
        } else {
          columns = 3;
        }
        final double rawSize = (maxWidth - spacing * (columns - 1)) / columns;
        final double tileSize = rawSize.clamp(60.0, 88.0).toDouble();

        final bool singleRow = count <= columns;
        final double velocity = spinVelocity.clamp(0.0, 1.0);
        final double progress = spinProgress.clamp(0.0, 1.0);

        final diceWidgets = List<Widget>.generate(values.length, (index) {
          final int wholeTurns = 3 + (index % 2); // 保证停止时回到水平
          final double baseAngle = wholeTurns * progress * 2 * pi; // 累计旋转保持单向
          final double wobble =
              sin((controllerValue * (index + 1)) * pi) * 0.18 * velocity;
          final double direction = index.isEven ? 1 : -1;
          final double angle = direction * baseAngle + wobble;

          return Transform.rotate(
            angle: angle,
            child: SizedBox(
              width: tileSize,
              height: tileSize,
              child: _DiceFace(
                value: values[index],
                dimmed: isPlaceholder,
              ),
            ),
          );
        });

        if (singleRow) {
          return SizedBox(
            width: maxWidth,
            height: tileSize,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < diceWidgets.length; i++) ...[
                    diceWidgets[i],
                    if (i != diceWidgets.length - 1) SizedBox(width: spacing),
                  ],
                ],
              ),
            ),
          );
        }

        return Align(
          alignment: Alignment.center,
          child: Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: spacing,
            runSpacing: spacing,
            children: diceWidgets,
          ),
        );
      },
    );
  }
}

class _DiceFace extends StatelessWidget {
  const _DiceFace({required this.value, this.dimmed = false});

  final int value;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color background = dimmed
        ? colorScheme.surfaceVariant.withOpacity(0.6)
        : colorScheme.surface;
    final Color borderColor = colorScheme.primary.withOpacity(
      dimmed ? 0.1 : 0.18,
    );
    final Color dotColor =
        dimmed ? colorScheme.primary.withOpacity(0.4) : colorScheme.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: CustomPaint(
          painter: _DiceFacePainter(
            value: value,
            dotColor: dotColor,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// 负责绘制骰子点阵的自定义画笔
class _DiceFacePainter extends CustomPainter {
  const _DiceFacePainter({
    required this.value,
    required this.dotColor,
  });

  final int value;
  final Color dotColor;

  static const double _near = 0.26;
  static const double _mid = 0.5;
  static const double _far = 0.74;

  static const Map<int, List<Offset>> _pipLayout = {
    1: [Offset(_mid, _mid)],
    2: [Offset(_near, _near), Offset(_far, _far)],
    3: [Offset(_near, _near), Offset(_mid, _mid), Offset(_far, _far)],
    4: [
      Offset(_near, _near),
      Offset(_far, _near),
      Offset(_near, _far),
      Offset(_far, _far),
    ],
    5: [
      Offset(_near, _near),
      Offset(_far, _near),
      Offset(_mid, _mid),
      Offset(_near, _far),
      Offset(_far, _far),
    ],
    6: [
      Offset(_near, _near),
      Offset(_far, _near),
      Offset(_near, _mid),
      Offset(_far, _mid),
      Offset(_near, _far),
      Offset(_far, _far),
    ],
  };

  @override
  void paint(Canvas canvas, Size size) {
    final int safeValue = value.clamp(1, 6);
    final positions = _pipLayout[safeValue] ?? _pipLayout[1]!;
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;
    final radius = size.shortestSide * 0.09;

    for (final position in positions) {
      final offset =
          Offset(position.dx * size.width, position.dy * size.height);
      canvas.drawCircle(offset, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DiceFacePainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.dotColor != dotColor;
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({
    required this.history,
    required this.onViewAll,
  });

  final List<_RollHistoryEntry> history;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final _RollHistoryEntry latestEntry = history.first;
    final bool hasMore = history.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.history,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              '点数历史记录',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: hasMore ? onViewAll : null,
              child: const Text('全部'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HistoryTile(entry: latestEntry),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});

  final _RollHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bool single = entry.values.length == 1;
    final String detail =
        single ? '${entry.values.first}' : entry.values.join(' + ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: colorScheme.surfaceVariant.withOpacity(0.32),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '#${entry.sequence}',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  single ? '掷出 ${entry.values.first}' : '掷出总和 ${entry.total}',
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '点数组合：$detail',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            entry.timestampFormatted,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withOpacity(0.68),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryDialog extends StatelessWidget {
  const _HistoryDialog({required this.history});

  final List<_RollHistoryEntry> history;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 520,
          minWidth: 360,
          maxHeight: 520,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    '全部点数记录',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: '关闭',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Scrollbar(
                  child: ListView.separated(
                    itemCount: history.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _HistoryTile(entry: history[index]),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RollHistoryEntry {
  const _RollHistoryEntry({
    required this.sequence,
    required this.values,
    required this.timestamp,
  });

  final int sequence;
  final List<int> values;
  final DateTime timestamp;

  int get total =>
      values.fold<int>(0, (previousValue, element) => previousValue + element);

  String get timestampFormatted {
    final String hour = timestamp.hour.toString().padLeft(2, '0');
    final String minute = timestamp.minute.toString().padLeft(2, '0');
    final String second = timestamp.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}
