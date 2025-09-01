import 'package:counters/app/state.dart';
import 'package:counters/common/model/poker50.dart';
import 'package:counters/features/score/base_config_page.dart';
import 'package:counters/features/template/template_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Poker50ConfigPage extends BaseConfigPage {
  const Poker50ConfigPage({
    required super.oriTemplate,
    super.isReadOnly,
    super.key,
  });

  @override
  ConsumerState<Poker50ConfigPage> createState() => _Poker50ConfigPageState();
}

class _Poker50ConfigPageState extends BaseConfigPageState<Poker50ConfigPage> {
  late bool _allowNegative = false;

  @override
  void initState() {
    super.initState();
    final template = widget.oriTemplate as Poker50Template;

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
    return _buildOtherList();
  }

  @override
  Future<void> updateTempConf() async {
    // 先执行验证和检查，如果返回 false 则直接返回
    if (!validateBasicInputs()) {
      return;
    }

    final template = widget.oriTemplate as Poker50Template;
    var updated = template.copyWith(
      templateName: templateNameController.text,
      playerCount: int.parse(playerCountController.text),
      targetScore: int.parse(targetScoreController.text),
      isAllowNegative: _allowNegative,
      players: players,
    );

    updated = applyWinRuleSettings(updated) as Poker50Template;

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

    var newTemplate = Poker50Template(
      templateName: templateNameController.text,
      playerCount: playerCount,
      targetScore: targetScore,
      players: players,
      isAllowNegative: _allowNegative,
      baseTemplateId: rootId,
    );

    // 应用胜利规则设置
    newTemplate = applyWinRuleSettings(newTemplate) as Poker50Template;

    ref.read(templatesProvider.notifier).saveUserTemplate(newTemplate, rootId);
    globalState.navigatorKey.currentState?.pop();
  }

  @override
  String getTemplateDescription() => '• 适用于：类似达到指定分数后计算胜局的游戏，计分最少的玩家获胜。\n'
      '• 典型情况：3人打牌记录剩余手牌数量，累计到50张为败，此时计分最少的玩家获胜。';

  Widget _buildOtherList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 16),
          child: Text('其他设置', style: Theme.of(context).textTheme.titleLarge),
        ),
        SwitchListTile(
          title: const Text('计分允许输入负数'),
          subtitle: const Text('启用后玩家计分可以输入负数值'),
          value: _allowNegative,
          onChanged: (bool value) {
            setState(() {
              _allowNegative = value;
            });
          },
        ),
      ],
    );
  }
}
