import 'package:counters/app/state.dart';
import 'package:counters/common/model/base_template.dart';
import 'package:counters/common/model/player_info.dart';
import 'package:counters/common/widgets/player_widget.dart';
import 'package:counters/common/widgets/snackbar.dart';
import 'package:counters/features/player/player_select_dialog.dart';
import 'package:counters/features/score/score_provider.dart';
import 'package:counters/features/template/template_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class BaseConfigPage extends ConsumerStatefulWidget {
  final BaseTemplate oriTemplate;
  final bool isReadOnly;

  const BaseConfigPage({
    required this.oriTemplate,
    this.isReadOnly = false,
    super.key,
  });
}

abstract class BaseConfigPageState<T extends BaseConfigPage>
    extends ConsumerState<T> {
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
    });
  }

  // 获取根模板ID的方法
  String? getRootBaseTemplateId() {
    BaseTemplate? current = widget.oriTemplate;
    while (current != null && !current.isSystemTemplate) {
      current = ref
          .read(templatesProvider.notifier)
          .getTemplate(current.baseTemplateId!);
    }
    return current?.tid;
  }

  String getRootBaseTemplateName() {
    BaseTemplate? current = widget.oriTemplate;

    // 递归查找直到系统模板
    while (current != null && !current.isSystemTemplate) {
      final baseId = current.baseTemplateId;
      current = ref.read(templatesProvider.notifier).getTemplate(baseId ?? '');
    }

    return current?.templateName ?? '系统模板';
  }

  /// 获取模板描述信息
  String getTemplateDescription();

  /// 构建模板信息说明
  Widget buildTemplateInfo() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primary
            .withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .primary
              .withAlpha((0.3 * 255).toInt()),
        ),
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
                '基于：${getRootBaseTemplateName()}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            getTemplateDescription(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

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
      AppSnackBar.warn('玩家数量和目标分数必须为有效数字');
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
      if (num < getMinPlayerCount()) {
        setState(() => _playerCountError = '至少${getMinPlayerCount()}人');
      } else if (num > getMaxPlayerCount()) {
        setState(() => _playerCountError = '最多${getMaxPlayerCount()}人');
      } else {
        setState(() => _playerCountError = null);
      }
    }
  }

  /// 进入模板配置页的提示
  Future<void> _checkHistoryTemp() async {
    final tid = widget.oriTemplate.tid;
    final provider = ref.read(scoreProvider.notifier);
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
    final provider = ref.read(scoreProvider.notifier);
    final scoreState = await ref.read(scoreProvider.future);
    if (scoreState.currentSession?.templateId == tid) {
      await globalState.showCommonDialog(
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
      final result = await globalState.showCommonDialog(
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

    // 定义页面核心内容列
    final pageContentColumn = Column(
      children: [
        buildTemplateInfo(),
        buildBasicSettings(getMinPlayerCount(), getMaxPlayerCount()),
        buildOtherSettings(),
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
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.isReadOnly ? '查看模板' : '配置模板'),
            Text(
              isSystem ? '系统模板' : '基于 ${getRootBaseTemplateName()} 创建',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: widget.isReadOnly
            ? []
            : [
                if (!isSystem) // 用户模板显示保存按钮
                  Tooltip(
                    message: '保存模板',
                    child: IconButton(
                      icon: Icon(Icons.save,
                          color: hasHistory ? Colors.orange : null),
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
        padding: const EdgeInsets.all(16), // 内边距移到 SingleChildScrollView
        child: Opacity(
          opacity: widget.isReadOnly ? 0.6 : 1.0,
          child: AbsorbPointer(
            absorbing: widget.isReadOnly,
            child: pageContentColumn, // 将核心内容列放在这里
          ),
        ),
      ),
    );
  }

  /// 玩家人数控制，例如 int getMinPlayerCount() => 1;
  int getMinPlayerCount();

  int getMaxPlayerCount();

  /// 其他设置， 由子类实现
  Widget buildOtherSettings() => const SizedBox.shrink();

  /// 基础设置组件，包含模板名称，玩家设置
  /// [minPlayerCount] 最小玩家数量
  /// [maxPlayerCount] 最大玩家数量
  Widget buildBasicSettings(int minPlayerCount, int maxPlayerCount) {
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
                  onChanged: _handlePlayerCountChange,
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
                    LengthLimitingTextInputFormatter(8)
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
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 16),
          child: Text('玩家设置', style: Theme.of(context).textTheme.titleLarge),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: players.length,
          itemBuilder: (context, index) => ListTile(
            leading: PlayerAvatar.build(context, players[index]),
            contentPadding: const EdgeInsets.only(left: 16, right: 16),
            title: Text(players[index].name),
            trailing: widget.isReadOnly
                ? null
                : IconButton(
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: OutlinedButton.icon(
            onPressed: (players.length <
                    (int.tryParse(playerCountController.text) ?? 0))
                ? () async {
                    final currentEnteredPlayerCount =
                        int.tryParse(playerCountController.text);
                    if (currentEnteredPlayerCount == null ||
                        _playerCountError != null) {
                      AppSnackBar.warn('请先设置有效的玩家数量');
                      return;
                    }
                    if (players.length >= currentEnteredPlayerCount) {
                      AppSnackBar.show('已达到玩家数量上限');
                      return;
                    }

                    final result = await globalState.showCommonDialog(
                      child: PlayerSelectDialog(
                        selectedPlayers: players,
                        maxCount: (currentEnteredPlayerCount - players.length)
                            .clamp(0, 20),
                      ),
                    );

                    if (result != null) {
                      setState(() {
                        for (var player in result) {
                          if (players.length < currentEnteredPlayerCount) {
                            players.add(player);
                            nameControllers
                                .add(TextEditingController(text: player.name));
                          } else {
                            AppSnackBar.show('已达到玩家数量上限，部分玩家未添加');
                            break;
                          }
                        }
                      });
                    }
                  }
                : null,
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
    } else if (int.parse(value) > 1000000) {
      setState(() => _targetScoreError = '最大100万');
    } else {
      setState(() => _targetScoreError = null);
    }
  }
}
