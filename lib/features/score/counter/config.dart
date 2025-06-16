import 'package:counters/app/state.dart';
import 'package:counters/common/model/counter.dart';
import 'package:counters/features/score/base_config_page.dart';
import 'package:counters/features/template/template_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CounterConfigPage extends BaseConfigPage {
  const CounterConfigPage({
    required super.oriTemplate,
    super.isReadOnly,
    super.key,
  });

  @override
  ConsumerState<CounterConfigPage> createState() => _CounterConfigPageState();
}

class _CounterConfigPageState extends BaseConfigPageState<CounterConfigPage> {
  late bool _allowNegative = false;

  @override
  void initState() {
    super.initState();
    final template = widget.oriTemplate as CounterTemplate;

    _allowNegative = template.isAllowNegative;
  }

  @override
  bool validateBasicInputs() {
    // 先执行父类的验证和检查，如果返回 false 则直接返回
    if (!super.validateBasicInputs()) {
      return false;
    }
    return true;
  }

  @override
  int getMinPlayerCount() => 1;

  @override
  int getMaxPlayerCount() => 20;

  @override
  Widget buildOtherSettings() {
    return SizedBox.shrink();
    // return _buildOtherList();
  }

  @override
  Future<void> updateTempConf() async {
    // 先执行验证和检查，如果返回 false 则直接返回
    if (!validateBasicInputs()) {
      return;
    }

    final template = widget.oriTemplate as CounterTemplate;
    final updated = template.copyWith(
      templateName: templateNameController.text,
      playerCount: int.parse(playerCountController.text),
      targetScore: int.parse(targetScoreController.text),
      isAllowNegative: _allowNegative,
      players: players,
    );

    // 在异步操作前获取需要的对象
    final templateNotifier = ref.read(templatesProvider.notifier);

    // 等待用户确认
    final shouldProceed = await confirmCheckScoring();

    if (shouldProceed) {
      templateNotifier.updateTemplate(updated);
      globalState.navigatorKey.currentState?.pop();
    }
  }

  @override
  Future<void> saveAsTemplate() async {
    // 先执行验证和检查，如果返回 false 则直接返回
    if (!validateBasicInputs()) {
      return;
    }

    final rootId = getRootBaseTemplateId() ?? widget.oriTemplate.tid;

    final newTemplate = CounterTemplate(
      templateName: templateNameController.text,
      playerCount: playerCount,
      targetScore: targetScore,
      players: players,
      isAllowNegative: _allowNegative,
      baseTemplateId: rootId,
    );

    ref.read(templatesProvider.notifier).saveUserTemplate(newTemplate, rootId);
    globalState.navigatorKey.currentState?.pop();
  }

  @override
  String getTemplateDescription() => '• 适用于：对玩家或其他事物进行点击+1的计数操作。\n'
      '• 本模板不会记录计分轮次和走势\n'
      '• 点击单个格子可+1分，长按可设置分数';

  // Widget _buildOtherList() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.stretch,
  //     children: [
  //       Padding(
  //         padding: const EdgeInsets.only(bottom: 8, top: 16),
  //         child: Text('其他设置', style: Theme.of(context).textTheme.titleLarge),
  //       ),
  //       SwitchListTile(
  //         contentPadding: const EdgeInsets.only(left: 16, right: 16),
  //         title: const Text('待配置选项'),
  //         subtitle: const Text('待配置选项说明'),
  //         value: _allowNegative,
  //         onChanged: (bool value) {
  //           setState(() {
  //             _allowNegative = value;
  //           });
  //         },
  //       ),
  //     ],
  //   );
  // }
}
