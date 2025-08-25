import 'dart:math';

import 'package:flutter/material.dart';

/// 一个有状态的骰子弹窗小部件
class DiceRollerDialog extends StatefulWidget {
  const DiceRollerDialog({super.key});

  @override
  State<DiceRollerDialog> createState() => _DiceRollerDialogState();
}

class _DiceRollerDialogState extends State<DiceRollerDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int? _diceValue;
  final _random = Random();
  bool _isInitial = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _controller.addListener(() {
      if (_controller.isAnimating) {
        setState(() {
          _diceValue = _random.nextInt(6) + 1;
        });
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
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('掷骰子'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _rollDice,
            child: RotationTransition(
              turns: CurvedAnimation(
                  parent: _controller, curve: Curves.easeOutCubic),
              child: _buildDiceFace(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _rollDice,
            icon: const Icon(Icons.casino_outlined),
            label: const Text('摇一摇'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  Widget _buildDiceFace() {
    if (_isInitial) {
      return Text(
        '?',
        style: TextStyle(
          fontSize: 100,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }
    // 使用 Unicode 字符来显示骰子点数
    final diceChars = ['⚀', '⚁', '⚂', '⚃', '⚄', '⚅'];
    return Text(
      diceChars[(_diceValue ?? 1) - 1],
      style: TextStyle(
        fontSize: 100,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}