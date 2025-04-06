import 'package:counters/model/landlords.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/template_provider.dart';
import '../../state.dart';
import '../base_config_page.dart';

class LandlordsConfigPage extends BaseConfigPage {
  const LandlordsConfigPage({
    required super.oriTemplate,
    super.key,
  });

  @override
  ConsumerState<LandlordsConfigPage> createState() =>
      _LandlordsConfigPageState();
}

class _LandlordsConfigPageState
    extends BaseConfigPageState<LandlordsConfigPage> {
  late TextEditingController _baseScoreController;
  String? _baseScoreError;

  @override
  void initState() {
    super.initState();
    final template = widget.oriTemplate as LandlordsTemplate;
    _baseScoreController = TextEditingController(
      text: template.baseScore.toString(),
    );
  }

  @override
  bool validateBasicInputs() {
    // 先执行父类的验证和检查，如果返回 false 则直接返回
    if (!super.validateBasicInputs()) {
      return false;
    }
    _handleBaseScoreChange(_baseScoreController.text);
    return true;
  }

  @override
  int getMinPlayerCount() => 3;

  @override
  int getMaxPlayerCount() => 20;

  @override
  Widget buildOtherSettings() => _buildOtherList();

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

  @override
  Future<void> updateTempConf() async {
    // 先执行验证和检查，如果返回 false 则直接返回
    if (!validateBasicInputs()) {
      return;
    }

    final template = widget.oriTemplate as LandlordsTemplate;
    final updated = template.copyWith(
      templateName: templateNameController.text,
      playerCount: int.parse(playerCountController.text),
      targetScore: int.parse(targetScoreController.text),
      baseScore: int.parse(_baseScoreController.text),
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

    final newTemplate = LandlordsTemplate(
      templateName: templateNameController.text,
      playerCount: playerCount,
      targetScore: targetScore,
      players: players,
      baseScore: int.parse(_baseScoreController.text),
      baseTemplateId: rootId,
    );

    ref.read(templatesProvider.notifier).saveUserTemplate(newTemplate, rootId);
    Navigator.pop(context);
  }

  @override
  String getTemplateDescription() =>
      '• 适用于：类似每局基于底分和倍数，结合胜负、炸弹/火箭翻倍及春天等牌型效果，计算地主与农民的得分或扣分的游戏。\n'
      '• 一局结束：地主得分=2×胜负参数×基数×底分×倍数，农民得分=胜负参数×基数×底分×倍数，胜负参数：胜利方为1，失败方为-1，基数：由游戏产品配置决定，底分：初始叫分时的1、2、3分。';

  Widget _buildOtherList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text('其他设置', style: Theme.of(context).textTheme.titleLarge),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 1,
          itemBuilder: (context, index) {
            return SizedBox(
              height: 80,
              child: TextField(
                controller: _baseScoreController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: InputDecoration(
                  labelText: '基数',
                  border: OutlineInputBorder(),
                  errorText: _baseScoreError,
                  hintText: '输入1-1000',
                  suffixText: '分',
                ),
                onChanged: _handleBaseScoreChange,
              ),
            );
          },
        ),
      ],
    );
  }
}
