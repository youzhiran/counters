import 'package:counters/common/model/player_info.dart';
import 'package:counters/features/score/widgets/base_score_edit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BaseScoreEditDialog 错误提示格式化测试', () {
    // 先测试格式化方法的逻辑
    test('格式化方法单元测试', () {
      // 测试整数格式化
      expect(
          '1,000,000'.replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          ),
          equals('1,000,000'));

      // 测试小数格式化
      final testNumber = 21000000.00;
      final decimalStr = testNumber.toStringAsFixed(2);
      final parts = decimalStr.split('.');
      final integerPart = parts[0];
      final decimalPart = parts.length > 1 ? parts[1] : '00';
      final formattedInteger = integerPart.replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
      final result = '$formattedInteger.$decimalPart';
      expect(result, equals('21,000,000.00'));
    });
    testWidgets('整数模式下的错误提示应该显示千分位分隔符', (WidgetTester tester) async {
      final player =
          PlayerInfo(pid: 'test', name: '测试玩家', avatar: 'test_avatar');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BaseScoreEditDialog(
                templateId: 'test',
                player: player,
                initialValue: 0,
                onConfirm: (value) {},
                supportDecimal: false,
              ),
            ),
          ),
        ),
      );

      // 查找输入框
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // 输入超过限制的值
      await tester.enterText(textField, '2000000');
      await tester.pump();

      // 验证错误提示显示千分位分隔符
      expect(find.text('单轮分数不能超过 1,000,000'), findsOneWidget);
    });

    testWidgets('小数模式下的错误提示应该显示小数格式', (WidgetTester tester) async {
      final player =
          PlayerInfo(pid: 'test', name: '测试玩家', avatar: 'test_avatar');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BaseScoreEditDialog(
                templateId: 'test',
                player: player,
                initialValue: 0,
                onConfirm: (value) {},
                supportDecimal: true,
                decimalMultiplier: 100,
              ),
            ),
          ),
        ),
      );

      // 查找输入框
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // 输入超过限制的值（小数格式）
      await tester.enterText(textField, '20000.00');
      await tester.pump();

      // 验证错误提示显示小数格式（1000000 / 100 = 10000.00）
      expect(find.text('单轮分数不能超过 10,000.00'), findsOneWidget);
    });

    testWidgets('小数模式下大数值的错误提示格式化', (WidgetTester tester) async {
      final player =
          PlayerInfo(pid: 'test', name: '测试玩家', avatar: 'test_avatar');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BaseScoreEditDialog(
                templateId: 'test',
                player: player,
                initialValue: 0,
                onConfirm: (value) {},
                supportDecimal: true,
                decimalMultiplier: 100,
              ),
            ),
          ),
        ),
      );

      // 查找输入框
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // 输入超过单轮最大分数限制的值（1000000 / 100 = 10000.00）
      await tester.enterText(textField, '15000.00');
      await tester.pump();

      // 验证错误提示显示小数格式（1000000 / 100 = 10000.00）
      expect(find.text('单轮分数不能超过 10,000.00'), findsOneWidget);
    });
  });
}
