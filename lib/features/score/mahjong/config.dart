import 'package:counters/app/state.dart';
import 'package:counters/common/model/mahjong.dart';
import 'package:counters/features/score/base_config_page.dart';
import 'package:counters/features/template/template_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MahjongConfigPage extends BaseConfigPage {
  const MahjongConfigPage({
    required super.oriTemplate,
    super.key,
  });

  @override
  ConsumerState<MahjongConfigPage> createState() => _MahjongConfigPageState();
}

class _MahjongConfigPageState extends BaseConfigPageState<MahjongConfigPage> {
  final _templateNameController = TextEditingController();
  final _targetScoreController = TextEditingController();
  final _playerCountController = TextEditingController();
  late TextEditingController _baseScoreController;
  String? _baseScoreError;
  bool _checkMultiplier = false;
  bool _bombMultiplyMode = false; // true: 每次×2, false: 增加倍数

  @override
  void initState() {
    super.initState();
    final template = widget.oriTemplate as MahjongTemplate;
    _templateNameController.text = template.templateName;
    _targetScoreController.text = template.targetScore.toString();
    _playerCountController.text = template.playerCount.toString();
    _baseScoreController = TextEditingController(
      text: template.baseScore.toString(),
    );
    _checkMultiplier = template.checkMultiplier;
    _bombMultiplyMode = template.bombMultiplyMode;
  }

  @override
  void dispose() {
    _templateNameController.dispose();
    _targetScoreController.dispose();
    _playerCountController.dispose();
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
      '• 一局结束：根据胡牌类型和番数计算得分。\n'
      '• 本模板显示为 2 位小数计分';

  @override
  Future<void> updateTempConf() async {
    // 先执行验证和检查，如果返回 false 则直接返回
    if (!validateBasicInputs()) {
      return;
    }

    final template = widget.oriTemplate as MahjongTemplate;
    final updated = template.copyWith(
      templateName: _templateNameController.text,
      playerCount: int.parse(_playerCountController.text),
      targetScore: int.parse(_targetScoreController.text),
      players: players,
      otherSet: {
        'baseScore': int.parse(_baseScoreController.text),
        'checkMultiplier': _checkMultiplier,
        'bombMultiplyMode': _bombMultiplyMode,
      },
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

    final newTemplate = MahjongTemplate(
      templateName: _templateNameController.text,
      playerCount: int.parse(_playerCountController.text),
      targetScore: int.parse(_targetScoreController.text),
      players: players,
      baseTemplateId: rootId,
      isSystemTemplate: false,
      baseScore: int.parse(_baseScoreController.text),
      checkMultiplier: _checkMultiplier,
      bombMultiplyMode: _bombMultiplyMode,
    );

    ref.read(templatesProvider.notifier).saveUserTemplate(newTemplate, rootId);
    Navigator.pop(context);
  }

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

  Widget _buildOtherList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 16),
          child: Text('其他设置', style: Theme.of(context).textTheme.titleLarge),
        ),
        ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // 底分设置
            ListTile(
              title: TextField(
                controller: _baseScoreController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: InputDecoration(
                  labelText: '底分',
                  border: OutlineInputBorder(),
                  errorText: _baseScoreError,
                  hintText: '输入1-1000',
                  suffixText: '分',
                ),
                onChanged: _handleBaseScoreChange,
              ),
            ),
            // 番数检查设置
            SwitchListTile(
              title: Text('检查番数'),
              subtitle: Text('开启后将检查胡牌类型和番数的合法性'),
              value: _checkMultiplier,
              onChanged: (value) {
                setState(() => _checkMultiplier = value);
              },
            ),
            // 番数计算方式
            ListTile(
              title: Text('番数计算方式'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RadioListTile<bool>(
                    title: Text('每个番数都×2'),
                    subtitle: Text('例如：3番 = ×2×2×2 = 8倍'),
                    value: true,
                    groupValue: _bombMultiplyMode,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _bombMultiplyMode = value);
                      }
                    },
                    dense: true,
                  ),
                  RadioListTile<bool>(
                    title: Text('番数增加倍数'),
                    subtitle: Text('例如：3番 = (1+3) = 4倍'),
                    value: false,
                    groupValue: _bombMultiplyMode,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _bombMultiplyMode = value);
                      }
                    },
                    dense: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
