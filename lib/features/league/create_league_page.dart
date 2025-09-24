import 'package:counters/app/state.dart';
import 'package:counters/common/model/base_template.dart';
import 'package:counters/common/model/league_enums.dart';
import 'package:counters/common/model/player_info.dart';
import 'package:counters/common/providers/league_provider.dart';
import 'package:counters/common/widgets/message_overlay.dart';
import 'package:counters/features/player/player_select_dialog.dart';
import 'package:counters/features/template/template_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateLeaguePage extends ConsumerStatefulWidget {
  const CreateLeaguePage({super.key});

  @override
  ConsumerState<CreateLeaguePage> createState() => _CreateLeaguePageState();
}

class _CreateLeaguePageState extends ConsumerState<CreateLeaguePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _roundRobinRoundsController = TextEditingController(text: '1');
  final _winPointsController = TextEditingController(text: '3');
  final _drawPointsController = TextEditingController(text: '1');
  final _lossPointsController = TextEditingController(text: '0');
  LeagueType _selectedType = LeagueType.roundRobin;
  final List<PlayerInfo> _selectedPlayers = [];
  BaseTemplate? _selectedTemplate;

  @override
  void dispose() {
    _nameController.dispose();
    _roundRobinRoundsController.dispose();
    _winPointsController.dispose();
    _drawPointsController.dispose();
    _lossPointsController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedPlayers.length < 2) {
        ref.showWarning('请至少选择2名玩家');
        return;
      }

      // 双败淘汰赛，限制玩家数为2的次方数(如4、8、16)
      if (_selectedType == LeagueType.doubleElimination) {
        final playerCount = _selectedPlayers.length;
        if (playerCount < 4 || (playerCount & (playerCount - 1)) != 0) {
          ref.showWarning('双败淘汰赛的玩家数量必须是2的次方数(如4, 8, 16)');
          return;
        }
      }

      if (_selectedTemplate == null) {
        ref.showWarning('请选择一个计分模板');
        return;
      }

      await ref.read(leagueNotifierProvider.notifier).addLeague(
            name: _nameController.text,
            type: _selectedType,
            playerIds: _selectedPlayers.map((p) => p.pid).toList(),
            defaultTemplateId: _selectedTemplate!.tid,
            roundRobinRounds: int.parse(_roundRobinRoundsController.text),
            pointsForWin: int.parse(_winPointsController.text),
            pointsForDraw: int.parse(_drawPointsController.text),
            pointsForLoss: int.parse(_lossPointsController.text),
          );

      // 检查组件是否仍然挂载
      if (!mounted) return;
      Navigator.of(context).pop();
      ref.showSuccess('联赛创建成功');
    }
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(templatesProvider);
    final bool hasSuitableUserTemplates = templatesAsync.maybeWhen(
      data: (templates) =>
          templates.any((template) => !template.isSystemTemplate),
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('创建新联赛'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: hasSuitableUserTemplates ? _submitForm : null,
            tooltip: '保存联赛',
          )
        ],
      ),
      body: templatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('加载模板失败: $err')),
        data: (templates) {
          // 联赛功能当前仅支持2人对战，但模板选择放开
          final suitableUserTemplates =
              templates.where((t) => !t.isSystemTemplate).toList();

          if (suitableUserTemplates.isEmpty) {
            // 当缺少用户模板时提示用户前往创建
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.insert_drive_file_outlined,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '当前没有可用的用户模板，请先至少创建一个模板后再来创建联赛。',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/templates');
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('去创建模板'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '联赛名称',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入联赛名称';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: '2',
                  enabled: false, // 当前禁用，为未来保留
                  decoration: const InputDecoration(
                    labelText: '联赛玩家数量',
                    border: OutlineInputBorder(),
                    helperText: '此功能暂未开放',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<LeagueType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: '联赛类型',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: LeagueType.roundRobin,
                      child: Text('循环赛'),
                    ),
                    DropdownMenuItem(
                      value: LeagueType.knockout,
                      child: Text('单败淘汰赛'),
                    ),
                    DropdownMenuItem(
                      value: LeagueType.doubleElimination,
                      child: Text('双败淘汰赛'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                // 积分设置
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _winPointsController,
                        enabled: _selectedType == LeagueType.roundRobin,
                        decoration: InputDecoration(
                          labelText: '胜场得分',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (_selectedType == LeagueType.roundRobin &&
                              (value == null ||
                                  value.isEmpty ||
                                  int.tryParse(value) == null)) {
                            return '请输入有效数字';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _drawPointsController,
                        enabled: _selectedType == LeagueType.roundRobin,
                        decoration: const InputDecoration(
                          labelText: '平局得分',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (_selectedType == LeagueType.roundRobin &&
                              (value == null ||
                                  value.isEmpty ||
                                  int.tryParse(value) == null)) {
                            return '请输入有效数字';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _lossPointsController,
                        enabled: _selectedType == LeagueType.roundRobin,
                        decoration: const InputDecoration(
                          labelText: '负场得分',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (_selectedType == LeagueType.roundRobin &&
                              (value == null ||
                                  value.isEmpty ||
                                  int.tryParse(value) == null)) {
                            return '请输入有效数字';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildPlayerSelector(context),
                const SizedBox(height: 16),
                // 模板选择部分
                DropdownButtonFormField<BaseTemplate>(
                  value: _selectedTemplate,
                  decoration: const InputDecoration(
                    labelText: '默认计分模板',
                    border: OutlineInputBorder(),
                    helperText: '注意：联赛将固定为2人对战模式。',
                    // 提示信息
                    helperMaxLines: 2,
                  ),
                  hint: const Text('选择一个模板'),
                  items: suitableUserTemplates.map((template) {
                    return DropdownMenuItem(
                      value: template,
                      child: Text(
                          '${template.templateName} (${template.playerCount}人)'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedTemplate = value;
                      });
                    }
                  },
                  validator: (value) => value == null ? '请选择一个模板' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: hasSuitableUserTemplates ? _submitForm : null,
                  icon: const Icon(Icons.save),
                  label: const Text('创建联赛'),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48)),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlayerSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: () async {
            final result = await globalState.showCommonDialog<List<PlayerInfo>>(
              child: PlayerSelectDialog(
                selectedPlayers: _selectedPlayers,
                maxCount: 20, // Allow up to 20 players
              ),
            );
            if (result != null) {
              setState(() {
                _selectedPlayers.clear();
                _selectedPlayers.addAll(result);
              });
            }
          },
          icon: const Icon(Icons.group_add),
          label: Text('选择参赛玩家 (${_selectedPlayers.length})'),
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: _selectedPlayers.map((player) {
            return Chip(
              label: Text(player.name),
              onDeleted: () {
                setState(() {
                  _selectedPlayers.removeWhere((p) => p.pid == player.pid);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
