import 'package:counters/state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/base_template.dart';
import '../../model/poker50.dart';
import '../../providers/template_provider.dart';
import '../../widgets/snackbar.dart';
import '../base_config_page.dart';

class Poker50ConfigPage extends BaseConfigPage {
  const Poker50ConfigPage({
    required super.oriTemplate,
    super.key,
  });

  @override
  State<Poker50ConfigPage> createState() => _Poker50ConfigPageState();
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
            buildBasicSettings(1, 20),
            _buildOtherList(),
            buildPlayerList(),
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

  @override
  Future<void> updateTempConf() async {
    // 先执行验证和检查，如果返回 false 则直接返回
    if (!validateBasicInputs()) {
      return;
    }

    final template = widget.oriTemplate as Poker50Template;
    final updated = template.copyWith(
      templateName: templateNameController.text,
      playerCount: int.parse(playerCountController.text),
      targetScore: int.parse(targetScoreController.text),
      isAllowNegative: _allowNegative,
      players: players,
    );

    // 检查每个名称是否为空
    for (final player in updated.players) {
      if (player.name.trim().isEmpty) {
        AppSnackBar.error('玩家名称不能为空或全是空格');
        return;
      }
    }

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

    final newTemplate = Poker50Template(
      templateName: templateNameController.text,
      playerCount: playerCount,
      targetScore: targetScore,
      players: players,
      isAllowNegative: _allowNegative,
      baseTemplateId: rootId,
    );

    context.read<TemplateProvider>().saveUserTemplate(newTemplate, rootId);
    Navigator.pop(context);
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
            '• 适用于：类似达到指定分数后计算胜局的游戏，计分最少的玩家获胜。\n'
            '• 典型情况：3人打牌记录剩余手牌数量，累计到50张为败，此时计分最少的玩家获胜。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('其他设置', style: Theme.of(context).textTheme.titleLarge),
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
