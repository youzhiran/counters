import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../fragments/player_select_dialog.dart';
import '../../model/base_template.dart';
import '../../model/player_info.dart';
import '../../providers/player_provider.dart';
import '../../providers/score_provider.dart';
import '../../providers/template_provider.dart';
import '../../state.dart';
import '../../widgets/player_widget.dart';
import '../../widgets/snackbar.dart';

abstract class BaseConfigPage extends StatefulWidget {
  final BaseTemplate oriTemplate;

  const BaseConfigPage({
    required this.oriTemplate,
    super.key,
  });
}

abstract class BaseConfigPageState<T extends BaseConfigPage> extends State<T> {
  late TextEditingController templateNameController;
  late TextEditingController playerCountController;
  late TextEditingController targetScoreController;
  late List<TextEditingController> nameControllers;
  late List<PlayerInfo> players;
  late bool hasHistory = false;

  // 错误提示状态
  String? _playerCountError;
  String? _targetScoreError;
  String? _templateNameError;

  // 经常使用的变量
  late int playerCount = widget.oriTemplate.playerCount;
  late int targetScore = widget.oriTemplate.targetScore;

  @override
  void initState() {
    super.initState();
    templateNameController =
        TextEditingController(text: widget.oriTemplate.templateName);
    playerCountController =
        TextEditingController(text: widget.oriTemplate.playerCount.toString());
    targetScoreController =
        TextEditingController(text: widget.oriTemplate.targetScore.toString());
    nameControllers = widget.oriTemplate.players
        .map((p) => TextEditingController(text: p.name))
        .toList();
    players = List.from(widget.oriTemplate.players);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkHistoryTemp();
      _updatePlayerCount(widget.oriTemplate.playerCount);
    });
  }

  /// 构建模板信息说明
  Widget buildTemplateInfo();

  // 用于验证输入
  bool validateBasicInputs() {
    // 直接调用校验显示函数
    _handlePlayerCountChange(playerCountController.text);
    _handleTargetScoreChange(targetScoreController.text);
    _handleTemplateNameChange(templateNameController.text);

    // 检查输入值是否有效并更新
    final newPlayerCount = int.tryParse(playerCountController.text);
    final newTargetScore = int.tryParse(targetScoreController.text);

    if (newPlayerCount == null || newTargetScore == null) {
      AppSnackBar.error('玩家数量和目标分数必须为有效数字');
      return false;
    }

    playerCount = newPlayerCount;
    targetScore = newTargetScore;

    // 检查玩家数量是否匹配
    if (players.length != playerCount) {
      AppSnackBar.warn('请添加/删除足够的玩家（${players.length}/$playerCount）');
      return false;
    }

    if (_playerCountError != null ||
        _targetScoreError != null ||
        _templateNameError != null) {
      AppSnackBar.warn('请修正输入错误');
      return false;
    }
    return true;
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

  /// 进入模板配置页的提示
  Future<void> _checkHistoryTemp() async {
    final tid = widget.oriTemplate.tid;
    final provider = context.read<ScoreProvider>();
    final isExists = provider.checkSessionExists(tid);
    if (await isExists) {
      AppSnackBar.warn('当前模板已有关联计分记录，保存时需清除该记录');
      setState(() {
        hasHistory = true;
      });
    } else {
      setState(() {
        hasHistory = false;
      });
    }
  }

  ///  检查模板是否正在计分
  Future<bool> confirmCheckScoring() async {
    final tid = widget.oriTemplate.tid;
    final provider = context.read<ScoreProvider>();
    if (provider.currentSession?.templateId == tid) {
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
    if (hasHistory) {
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
                provider.clearSessionsByTemplate(tid);
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

  /// 用于更新模板
  Future<void> updateTempConf();

  /// 用于另存为模板
  Future<void> saveAsTemplate();

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
          if (!isSystem)
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

  /// 基础设置组件，包含模板名称，玩家设置
  /// [minPlayerCount] 最小玩家数量
  /// [maxPlayerCount] 最大玩家数量
  Widget buildBasicSettings(minPlayerCount, int maxPlayerCount) {
    return Column(
      children: [
        SizedBox(
          height: 80,
          child: TextField(
            controller: templateNameController,
            decoration: InputDecoration(
              labelText: '模板名称',
              border: OutlineInputBorder(),
              errorText: _templateNameError,
            ),
            onChanged: _handleTemplateNameChange,
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                height: 80,
                child: TextField(
                  controller: playerCountController,
                  keyboardType: TextInputType.number,
                  enabled: minPlayerCount != maxPlayerCount,
                  readOnly: minPlayerCount == maxPlayerCount,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2)
                  ],
                  decoration: InputDecoration(
                    labelText: '玩家数量',
                    border: OutlineInputBorder(),
                    errorText: _playerCountError,
                    hintText: minPlayerCount == maxPlayerCount
                        ? '固定$minPlayerCount人'
                        : '输入$minPlayerCount-$maxPlayerCount人',
                  ),
                  onChanged: (value) {
                    if (value.isEmpty) {
                      setState(() => _playerCountError = '不能为空');
                    } else if (int.tryParse(value) == null) {
                      setState(() => _playerCountError = '必须为数字');
                    } else {
                      final num = int.parse(value);
                      if (num < minPlayerCount) {
                        setState(
                            () => _playerCountError = '至少$minPlayerCount人');
                      } else if (num > maxPlayerCount) {
                        setState(
                            () => _playerCountError = '最多$maxPlayerCount人');
                      } else {
                        setState(() => _playerCountError = null);
                      }
                    }
                  },
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 80,
                child: TextField(
                  controller: targetScoreController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6)
                  ],
                  decoration: InputDecoration(
                    labelText: '目标分数',
                    border: OutlineInputBorder(),
                    errorText: _targetScoreError,
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

  Widget buildPlayerList() {
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
              contentPadding: const EdgeInsets.only(left: 16, right: 16),
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

  void _updatePlayerCount(int newCount) async {
    final playerProvider = context.read<PlayerProvider>();
    final dbPlayers = playerProvider.players ?? [];

    if (newCount > players.length) {
      for (int i = players.length; i < newCount && i < dbPlayers.length; i++) {
        players.add(dbPlayers[i]);
        nameControllers.add(TextEditingController(text: dbPlayers[i].name));
      }
    } else if (newCount < players.length) {
      players.removeRange(newCount, players.length);
      nameControllers.removeRange(newCount, nameControllers.length);
    }
    setState(() {});
  }

  String _getRootBaseTemplateName() {
    BaseTemplate? current = widget.oriTemplate;
    while (current != null && !current.isSystemTemplate) {
      final baseId = current.baseTemplateId;
      current = context.read<TemplateProvider>().getTemplate(baseId ?? '');
    }
    return current?.templateName ?? '系统模板';
  }
}
