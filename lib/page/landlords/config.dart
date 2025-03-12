import 'package:counters/db/landlords.dart';
import 'package:counters/fragments/player_select_dialog.dart';
import 'package:counters/providers/player_provider.dart';
import 'package:counters/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../db/base_template.dart';
import '../../db/player_info.dart';
import '../../providers/score_provider.dart';
import '../../providers/template_provider.dart';
import '../../widgets/player_widget.dart';
import '../../widgets/snackbar.dart';

// todo 同步poker50逻辑
class LandlordsConfigPage extends StatefulWidget {
  final LandlordsTemplate oriTemplate;

  const LandlordsConfigPage({
    required this.oriTemplate,
    super.key,
  });

  @override
  State<LandlordsConfigPage> createState() => _LandlordsConfigPageState();
}

class _LandlordsConfigPageState extends State<LandlordsConfigPage> {
  late TextEditingController _templateNameController;
  late TextEditingController _playerCountController;
  late TextEditingController _targetScoreController;
  late List<TextEditingController> _nameControllers;
  late List<PlayerInfo> _players;
  late bool _allowNegative = false;
  late bool _hasHistory = false;

  // 错误提示状态
  String? _playerCountError;
  String? _targetScoreError;
  String? _templateNameError;

  @override
  void initState() {
    super.initState();
    _templateNameController =
        TextEditingController(text: widget.oriTemplate.templateName);
    _playerCountController =
        TextEditingController(text: widget.oriTemplate.playerCount.toString());
    _targetScoreController =
        TextEditingController(text: widget.oriTemplate.targetScore.toString());
    _nameControllers = widget.oriTemplate.players
        .map((p) => TextEditingController(text: p.name))
        .toList();
    _players = List.from(widget.oriTemplate.players);
    _allowNegative = widget.oriTemplate.isAllowNegative;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkHistoryTemp();
      _updatePlayerCount(widget.oriTemplate.playerCount);
    });
  }

  void _validateInputs() {
    // 直接调用校验处理函数
    _handlePlayerCountChange(_playerCountController.text);
    _handleTargetScoreChange(_targetScoreController.text);
    _handleTemplateNameChange(_templateNameController.text);
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
                    Icon(Icons.save, color: _hasHistory ? Colors.orange : null),
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
            _buildInfo(),
            _buildBasicSettings(),
            _buildOtherList(),
            _buildPlayerList(),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                '原模板名：${widget.oriTemplate.templateName}\nID：${widget.oriTemplate.id}',
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

  Future<void> _checkHistoryTemp() async {
    final id = widget.oriTemplate.id;
    final provider = context.read<ScoreProvider>();
    final hasHistory = provider.checkSessionExists(id);
    if (await hasHistory) {
      AppSnackBar.warn('当前模板已有关联计分记录，保存时需清除该记录');
      setState(() {
        _hasHistory = true;
      });
    } else {
      setState(() {
        _hasHistory = false;
      });
    }
  }

  Future<bool> confirmCheckHistory() async {
    final id = widget.oriTemplate.id;
    final provider = context.read<ScoreProvider>();
    // 使用新方法检查模板是否正在计分
    if (provider.currentSession != null) {
      await globalState.showCommonDialog<bool>(
        child: AlertDialog(
          title: const Text('提示'),
          content: const Text('当前模板正在计分，请结束计分后再修改！'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('确认'),
            ),
          ],
        ),
      );
      return false;
    }
    if (await provider.checkSessionExists(id)) {
      final result = await globalState.showCommonDialog<bool>(
        child: AlertDialog(
          title: const Text('警告'),
          content: const Text('当前模板已有关联计分记录，保存后会清除所有关联记录。\n是否继续？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                provider.clearSessionsByTemplate(id);
                Navigator.pop(context, true);
              },
              child:
                  const Text('保存并清除关联计分', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      return result ?? false; // 处理可能的 null 值
    }

    return true; // 没有关联记录时直接允许保存
  }

  Future<void> _updateTemplate() async {
    _validateInputs();

    // 检查玩家数量是否匹配
    final targetCount = int.parse(_playerCountController.text);
    if (_players.length != targetCount) {
      AppSnackBar.error('请添加足够的玩家（${_players.length}/$targetCount）');
      return;
    }

    if (_playerCountError != null ||
        _targetScoreError != null ||
        _templateNameError != null) {
      AppSnackBar.error('请修正输入错误');
      return;
    }

    final updated = widget.oriTemplate.copyWith(
      templateName: _templateNameController.text,
      playerCount: int.parse(_playerCountController.text),
      targetScore: int.parse(_targetScoreController.text),
      isAllowNegative: _allowNegative,
      players: _players,
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
    final shouldProceed = await confirmCheckHistory();

    if (shouldProceed) {
      // 使用之前保存的 provider 而不是通过 context 获取
      templateProvider.updateTemplate(updated);
      globalState.navigatorKey.currentState?.pop();
    } // 用户取消时不执行任何操作
  }

  void _saveAsTemplate() {
    AppSnackBar.show('暂未实现，敬请期待');
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

  Widget _buildInfo() {
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
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _players.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
            child: ListTile(
              leading: PlayerAvatar.build(context, _players[index]),
              title: Text(_players[index].name),
              trailing: IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _players.removeAt(index);
                    _nameControllers.removeAt(index);
                  });
                },
              ),
            ),
          ),
        ),
        if (_players.length < (int.tryParse(_playerCountController.text) ?? 0))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton.icon(
              onPressed: () async {
                final result = await globalState.showCommonDialog(
                  child: PlayerSelectDialog(
                    selectedPlayers: _players,
                    maxCount: int.parse(_playerCountController.text) -
                        _players.length,
                  ),
                );

                if (result != null) {
                  setState(() {
                    for (var player in result) {
                      _players.add(player);
                      _nameControllers
                          .add(TextEditingController(text: player.name));
                    }
                  });
                }
              },
              icon: Icon(Icons.person_add),
              label: Text(
                  '选择玩家（${_players.length}/${_playerCountController.text}）'),
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

  void _updatePlayerCount(int newCount) async {
    final playerProvider = context.read<PlayerProvider>();
    final dbPlayers = playerProvider.players ?? [];

    if (newCount > _players.length) {
      // 只添加数据库中的玩家
      for (int i = _players.length; i < newCount && i < dbPlayers.length; i++) {
        _players.add(dbPlayers[i]);
        _nameControllers.add(TextEditingController(text: dbPlayers[i].name));
      }
    } else if (newCount < _players.length) {
      _players.removeRange(newCount, _players.length);
      _nameControllers.removeRange(newCount, _nameControllers.length);
    }
    setState(() {});
  }
}
