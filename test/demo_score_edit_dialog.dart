import 'package:counters/common/model/player_info.dart';
import 'package:counters/features/score/widgets/base_score_edit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 演示分数编辑对话框的错误提示格式化功能
void main() {
  runApp(const ProviderScope(child: DemoApp()));
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '分数编辑对话框演示',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const DemoHomePage(),
    );
  }
}

class DemoHomePage extends StatelessWidget {
  const DemoHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final player = PlayerInfo(pid: 'demo', name: '演示玩家', avatar: 'demo_avatar');

    return Scaffold(
      appBar: AppBar(
        title: const Text('分数编辑对话框演示'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '点击按钮测试错误提示格式化功能：',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => BaseScoreEditDialog(
                    templateId: 'demo',
                    player: player,
                    initialValue: 0,
                    title: '整数模式测试',
                    subtitle: '输入超过 1,000,000 的值查看错误提示',
                    supportDecimal: false,
                    onConfirm: (value) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('输入值: $value')),
                      );
                    },
                  ),
                );
              },
              child: const Text('测试整数模式错误提示'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => BaseScoreEditDialog(
                    templateId: 'demo',
                    player: player,
                    initialValue: 0,
                    title: '小数模式测试',
                    subtitle: '输入超过 10,000.00 的值查看错误提示',
                    supportDecimal: true,
                    decimalMultiplier: 100,
                    onConfirm: (value) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('输入值: $value')),
                      );
                    },
                  ),
                );
              },
              child: const Text('测试小数模式错误提示'),
            ),
            const SizedBox(height: 30),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                '说明：\n'
                '• 整数模式：错误提示显示千分位分隔符（如：1,000,000）\n'
                '• 小数模式：错误提示显示小数格式（如：10,000.00）\n'
                '• 错误提示格式与用户输入格式保持一致',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.left,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
