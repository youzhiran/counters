import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../providers/template_provider.dart';
import '../widgets/snackbar.dart';

class TemplateConfigScreen extends StatefulWidget {
  final ScoreTemplate baseTemplate;

  const TemplateConfigScreen({
    required this.baseTemplate,
    super.key, // 添加key参数
  });

  @override
  _TemplateConfigScreenState createState() => _TemplateConfigScreenState();
}

class _TemplateConfigScreenState extends State<TemplateConfigScreen> {
  late TextEditingController _templateNameController;
  late TextEditingController _playerCountController;
  late TextEditingController _targetScoreController;
  late List<TextEditingController> _nameControllers;
  late List<PlayerInfo> _players;
  late bool _allowNegative = false;

  // 错误提示状态
  String? _playerCountError;
  String? _targetScoreError;
  String? _templateNameError;

  @override
  void initState() {
    super.initState();
    _templateNameController =
        TextEditingController(text: widget.baseTemplate.templateName);
    _playerCountController =
        TextEditingController(text: widget.baseTemplate.playerCount.toString());
    _targetScoreController =
        TextEditingController(text: widget.baseTemplate.targetScore.toString());
    _nameControllers = widget.baseTemplate.players
        .map((p) => TextEditingController(text: p.name))
        .toList();
    _players = List.from(widget.baseTemplate.players);
    _allowNegative = widget.baseTemplate.isAllowNegative;
  }

  void _validateInputs() {
    // 直接调用校验处理函数
    _handlePlayerCountChange(_playerCountController.text);
    _handleTargetScoreChange(_targetScoreController.text);
    _handleTemplateNameChange(_templateNameController.text);
  }

  @override
  Widget build(BuildContext context) {
    final isSystem = widget.baseTemplate.isSystemTemplate;

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
                icon: Icon(Icons.save),
                onPressed: _updateTemplate,
              ),
            ),
          Tooltip(
            message: '另存为新模板',
            child: IconButton(
              icon: Icon(Icons.save_as),
              onPressed: _saveAsTemplate,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildBasicSettings(),
            _buildOtherList(),
            _buildPlayerList(),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                '原模板名：${widget.baseTemplate.templateName}\nID：${widget.baseTemplate.id}',
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

  void _updateTemplate() {
    for (int i = 0; i < _nameControllers.length; i++) {
      _players[i] = _players[i].copyWith(
          name: _nameControllers[i].text.trim()
      );
    }

    _validateInputs();

    if (_playerCountError != null ||
        _targetScoreError != null ||
        _templateNameError != null) {
      AppSnackBar.error(context, '请修正输入错误');
      return;
    }

    final updated = widget.baseTemplate.copyWith(
      templateName: _templateNameController.text,
      playerCount: int.parse(_playerCountController.text),
      targetScore: int.parse(_targetScoreController.text),
      isAllowNegative:_allowNegative,
      players: _players,
    );

    // 检查每个名称是否为空
    for (final player in updated.players) {
      if (player.name.trim().isEmpty) {
        AppSnackBar.error(context, '玩家名称不能为空或全是空格');
        return;
      }
    }

    context.read<TemplateProvider>().updateTemplate(updated);
    Navigator.pop(context);
  }

  void _saveAsTemplate() {
    for (int i = 0; i < _nameControllers.length; i++) {
      _players[i] = _players[i].copyWith(
          name: _nameControllers[i].text.trim()
      );
    }

    _validateInputs();

    if (_playerCountError != null ||
        _targetScoreError != null ||
        _templateNameError != null) {
      AppSnackBar.error(context, '请修正输入错误');
      return;
    }

    final rootId = _getRootBaseTemplateId() ?? widget.baseTemplate.id;

    final newTemplate = ScoreTemplate(
      templateName: _templateNameController.text,
      playerCount: int.parse(_playerCountController.text),
      targetScore: int.parse(_targetScoreController.text),
      players: _players,
      isAllowNegative:_allowNegative,
      baseTemplateId: rootId,
    );

    // 检查每个名称是否为空
    for (final player in newTemplate.players) {
      if (player.name.trim().isEmpty) {
        AppSnackBar.error(context, '玩家名称不能为空或全是空格');
        return;
      }
    }

    context.read<TemplateProvider>().saveUserTemplate(newTemplate, rootId);
    Navigator.pop(context);
  }

  // 获取根模板ID的方法
  String? _getRootBaseTemplateId() {
    ScoreTemplate? current = widget.baseTemplate;
    while (current != null && !current.isSystemTemplate) {
      current =
          context.read<TemplateProvider>().getTemplate(current.baseTemplateId!);
    }
    return current?.id;
  }

  String _getRootBaseTemplateName() {
    ScoreTemplate? current = widget.baseTemplate;

    // 递归查找直到系统模板
    while (current != null && !current.isSystemTemplate) {
      final baseId = current.baseTemplateId;
      current = context.read<TemplateProvider>().getTemplate(baseId ?? '');
    }

    return current?.templateName ?? '系统模板';
  }

  void _handlePlayerCountChange(String value) {
    if (value.isEmpty) {
      setState(() => _playerCountError = '不能为空');
    } else if (int.tryParse(value) == null) {
      setState(() => _playerCountError = '必须为数字');
    } else {
      final num = int.parse(value);
      if (num < 1) {
        setState(() => _playerCountError = '至少1人');
      } else if (num > 20) {
        setState(() => _playerCountError = '最多20人');
      } else {
        setState(() => _playerCountError = null);
        _updatePlayerCount(num);
      }
    }
  }

  void _handleTemplateNameChange(String value) {
    if (value.isEmpty) {
      setState(() => _templateNameError = '标题不能为空');
    } else {
      setState(() => _templateNameError = null);
    }
  }

  void _handleTargetScoreChange(String value) {
    if (value.isEmpty) {
      setState(() => _targetScoreError = '不能为空');
    } else if (int.tryParse(value) == null) {
      setState(() => _targetScoreError = '必须为数字');
    } else if (int.parse(value) <= 0) {
      setState(() => _targetScoreError = '必须大于0');
    } else if (int.parse(value) > 100000) {
      setState(() => _targetScoreError = '最大10万');
    } else {
      setState(() => _targetScoreError = null);
    }
  }

  Widget _buildBasicSettings() {
    return Column(
      children: [
        SizedBox(
          height: 80,
          child: TextField(
            controller: _templateNameController,
            decoration: InputDecoration(
              labelText: '模板名称',
              border: OutlineInputBorder(),
              errorText: _templateNameError,
            ),
            onChanged: _handleTemplateNameChange,
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start, // 顶部对齐
          children: [
            Expanded(
              child: SizedBox(
                // 固定高度容器
                height: 80, // 预留错误提示空间的高度
                child: TextField(
                  controller: _playerCountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2)
                  ],
                  decoration: InputDecoration(
                    labelText: '玩家数量',
                    border: OutlineInputBorder(),
                    errorText: _playerCountError, // 使用默认错误提示
                    hintText: '输入1-20',
                  ),
                  onChanged: _handlePlayerCountChange,
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                // 固定高度容器
                height: 80,
                child: TextField(
                  controller: _targetScoreController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6)
                  ],
                  decoration: InputDecoration(
                    labelText: '目标分数',
                    border: OutlineInputBorder(),
                    errorText: _targetScoreError, // 使用默认错误提示
                    hintText: '输入正整数',
                  ),
                  onChanged: _handleTargetScoreChange,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlayerList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('玩家设置', style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _players.length,
          itemBuilder: (context, index) => _PlayerItemEditor(
            controller: _nameControllers[index], // 传递控制器
          ),
        ),
      ],
    );
  }

  Widget _buildOtherList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('其他设置', style: Theme.of(context).textTheme.titleLarge),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 1,
          itemBuilder: (context, index) {
            return SwitchListTile(
              title: const Text('计分允许输入负数'),
              subtitle: const Text('启用后玩家计分可以输入负数值'),
              value: _allowNegative,
              onChanged: (bool value) {
                setState(() {
                  _allowNegative = value;
                });
              },
            );
          },
        ),
      ],
    );
  }

  void _updatePlayerCount(int newCount) {
    if (newCount > _players.length) {
      for (int i = _players.length; i < newCount; i++) {
        _players.add(PlayerInfo(name: '玩家 ${i + 1}', avatar: 'default_avatar.png'));
        _nameControllers.add(TextEditingController(text: '玩家 ${i + 1}')); // 新增控制器
      }
    } else if (newCount < _players.length) {
      _players.removeRange(newCount, _players.length);
      _nameControllers.removeRange(newCount, _nameControllers.length); // 移除多余控制器
    }
    setState(() {});
  }
}

class _PlayerItemEditor extends StatelessWidget { // 改为无状态组件
  final TextEditingController controller;

  const _PlayerItemEditor({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(radius: 24, child: Icon(Icons.person)),
          SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: '玩家名称',
                border: OutlineInputBorder(),
                counterText: '${controller.text.length}/10',
              ),
              maxLength: 10,
            ),
          ),
        ],
      ),
    );
  }
}
