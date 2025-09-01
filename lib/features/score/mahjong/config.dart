import 'package:counters/app/state.dart';
import 'package:counters/common/model/mahjong.dart';
import 'package:counters/features/score/base_config_page.dart';
import 'package:counters/features/template/template_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MahjongConfigPage extends BaseConfigPage {
  const MahjongConfigPage({
    required super.oriTemplate,
    super.isReadOnly,
    super.key,
  });

  @override
  ConsumerState<MahjongConfigPage> createState() => _MahjongConfigPageState();
}

class _MahjongConfigPageState extends BaseConfigPageState<MahjongConfigPage> {
  late TextEditingController _baseScoreController;
  String? _baseScoreError;

  @override
  void initState() {
    super.initState();
    final template = widget.oriTemplate as MahjongTemplate;
    _baseScoreController = TextEditingController(
      text: template.baseScore.toString(),
    );
  }

  @override
  void dispose() {
    _baseScoreController.dispose();
    super.dispose();
  }

  @override
  bool validateBasicInputs() {
    // 先执行父类的验证和检查，如果返回 false 则直接返回
    if (!super.validateBasicInputs()) {
      return false;
    }
    _handleBaseScoreChange(_baseScoreController.text);
    return _baseScoreError == null;
  }

  @override
  int getMinPlayerCount() => 2;

  @override
  int getMaxPlayerCount() => 20;

  @override
  String getTemplateDescription() => '• 适用于：麻将游戏，支持4人玩法。\n'
      '• 本模板显示为 2 位小数计分\n'
      '• 这里目标分数1分=实际游戏中0.01分';

  @override
  Future<void> updateTempConf() async {
    // 先执行验证和检查，如果返回 false 则直接返回
    if (!validateBasicInputs()) {
      return;
    }

    final template = widget.oriTemplate as MahjongTemplate;
    var updated = template.copyWith(
      templateName: templateNameController.text,
      playerCount: int.parse(playerCountController.text),
      targetScore: int.parse(targetScoreController.text),
      players: players,
    );

    updated = applyWinRuleSettings(updated) as MahjongTemplate;

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

    var newTemplate = MahjongTemplate(
      templateName: templateNameController.text,
      playerCount: playerCount,
      targetScore: targetScore,
      players: players,
      baseTemplateId: rootId,
      isSystemTemplate: false,
      baseScore: int.parse(_baseScoreController.text),
    );

    // 应用胜利规则设置
    newTemplate = applyWinRuleSettings(newTemplate) as MahjongTemplate;

    ref.read(templatesProvider.notifier).saveUserTemplate(newTemplate, rootId);
    globalState.navigatorKey.currentState?.pop();
  }

  // @override
  // Widget buildOtherSettings() {
  //   return _buildOtherList();
  // }

  // 底分验证方法
  void _handleBaseScoreChange(String value) {
    if (value.isEmpty) {
      setState(() => _baseScoreError = '不能为空');
    } else if (int.tryParse(value) == null) {
      setState(() => _baseScoreError = '必须为数字');
    } else {
      final score = int.parse(value);
      if (score < 1) {
        setState(() => _baseScoreError = '至少1分');
      } else if (score > 1000) {
        setState(() => _baseScoreError = '最多1000分');
      } else {
        setState(() => _baseScoreError = null);
      }
    }
  }
}
