import 'package:counters/fragments/player_select_dialog.dart';
import 'package:counters/model/landlords.dart';
import 'package:counters/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../model/base_template.dart';
import '../../providers/template_provider.dart';
import '../../widgets/player_widget.dart';
import '../base_config_page.dart';

class LandlordsConfigPage extends BaseConfigPage {
  const LandlordsConfigPage({
    required super.oriTemplate,
    super.key,
  });

  @override
  State<LandlordsConfigPage> createState() => _LandlordsConfigPageState();
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
  Widget build(BuildContext context) {
    final isSystem = widget.oriTemplate.isSystemTemplate;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('配置模板'),
            Text(
              isSystem ? '系统模板' : '基于 ${_getRootBaseTemplateName()} 创建',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          if (!isSystem) // 用户模板显示保存按钮
            Tooltip(
              message: '保存模板',
              child: IconButton(
                icon:
                    Icon(Icons.save, color: hasHistory ? Colors.orange : null),
                onPressed: updateTempConf,
              ),
            ),
          Tooltip(
            message: '另存为新模板',
            child: IconButton(
              icon: Icon(Icons.save_as),
              onPressed: saveAsTemplate,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            buildTemplateInfo(),
            buildBasicSettings(3, 3),
            _buildOtherList(),
            _buildPlayerList(),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                '原模板名：${widget.oriTemplate.templateName}\nID：${widget.oriTemplate.tid}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

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
    final templateProvider = context.read<TemplateProvider>();

    // 等待用户确认
    final shouldProceed = await confirmCheckScoring();

    if (shouldProceed) {
      // 使用之前保存的 provider 而不是通过 context 获取
      templateProvider.updateTemplate(updated);
      globalState.navigatorKey.currentState?.pop();
    } // 用户取消时不执行任何操作
  }

  @override
  Future<void> saveAsTemplate() async {
    // 先执行验证和检查，如果返回 false 则直接返回
    if (!validateBasicInputs()) {
      return;
    }

    final rootId = _getRootBaseTemplateId() ?? widget.oriTemplate.tid;

    final newTemplate = LandlordsTemplate(
      templateName: templateNameController.text,
      playerCount: playerCount,
      targetScore: targetScore,
      players: players,
      baseScore: int.parse(_baseScoreController.text),
      baseTemplateId: rootId,
    );

    context.read<TemplateProvider>().saveUserTemplate(newTemplate, rootId);
    Navigator.pop(context);
    return;
  }

  // 获取根模板ID的方法
  String? _getRootBaseTemplateId() {
    BaseTemplate? current = widget.oriTemplate;
    while (current != null && !current.isSystemTemplate) {
      current =
          context.read<TemplateProvider>().getTemplate(current.baseTemplateId!);
    }
    return current?.tid;
  }

  String _getRootBaseTemplateName() {
    BaseTemplate? current = widget.oriTemplate;

    // 递归查找直到系统模板
    while (current != null && !current.isSystemTemplate) {
      final baseId = current.baseTemplateId;
      current = context.read<TemplateProvider>().getTemplate(baseId ?? '');
    }

    return current?.templateName ?? '系统模板';
  }

  @override
  Widget buildTemplateInfo() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary),
              SizedBox(width: 8),
              Text(
                '基于：${_getRootBaseTemplateName()}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '• 适用于：类似每局基于底分和倍数，结合胜负、炸弹/火箭翻倍及春天等牌型效果，计算地主与农民的得分或扣分的游戏。\n'
            '• 本模板暂未完成，敬请期待。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('玩家设置', style: Theme.of(context).textTheme.titleLarge),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: players.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
            child: ListTile(
              leading: PlayerAvatar.build(context, players[index]),
              title: Text(players[index].name),
              trailing: IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    players.removeAt(index);
                    nameControllers.removeAt(index);
                  });
                },
              ),
            ),
          ),
        ),
        if (players.length < (int.tryParse(playerCountController.text) ?? 0))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton.icon(
              onPressed: () async {
                final result = await globalState.showCommonDialog(
                  child: PlayerSelectDialog(
                    selectedPlayers: players,
                    maxCount:
                        int.parse(playerCountController.text) - players.length,
                  ),
                );

                if (result != null) {
                  setState(() {
                    for (var player in result) {
                      players.add(player);
                      nameControllers
                          .add(TextEditingController(text: player.name));
                    }
                  });
                }
              },
              icon: Icon(Icons.person_add),
              label:
                  Text('选择玩家（${players.length}/${playerCountController.text}）'),
            ),
          ),
      ],
    );
  }

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
                  labelText: '底分',
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
