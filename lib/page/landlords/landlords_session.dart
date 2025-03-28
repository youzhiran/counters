import 'package:counters/model/landlords.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/base_template.dart';
import '../../model/game_session.dart';
import '../../model/player_info.dart';
import '../../model/player_score.dart';
import '../../providers/score_provider.dart';
import '../../providers/template_provider.dart';
import '../../widgets/player_widget.dart';
import '../base_session.dart';

class LandlordsSessionPage extends BaseSessionPage {
  const LandlordsSessionPage({super.key, required super.templateId});

  @override
  ConsumerState<LandlordsSessionPage> createState() =>
      _LandlordsSessionPageState();
}

class _LandlordsSessionPageState
    extends BaseSessionPageState<LandlordsSessionPage> {
  // 当前轮次的数据
  String? _currentLandlordId;
  int _baseScore = 1; // 底分
  Map<String, int> _bombUsed = {};
  Map<String, bool> _rocketUsed = {};
  Map<String, bool> _springUsed = {};
  bool _isEditing = false;
  int _currentEditRound = -1;
  bool _landlordWin = false;
  bool _hasSelectedWinner = false;

  @override
  Widget build(BuildContext context) {
    final template = ref
        .read(templatesProvider.notifier)
        .getTemplate(widget.templateId) as LandlordsTemplate;
    final session = ref.watch(scoreProvider).value?.currentSession;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: Text('错误')),
        body: Center(child: Text('模板加载失败')),
      );
    }

    final currentRound = ref.read(scoreProvider).value?.currentRound ?? 0;

    final failureScore = template.targetScore;

    // 当轮次完成时检查
    if (currentRound > 0) {
      final allPlayersFilled = session.scores.every((s) =>
          s.roundScores.length >= currentRound &&
          s.roundScores[currentRound - 1] != null);

      if (allPlayersFilled) {
        final overPlayers =
            session.scores.where((s) => s.totalScore >= failureScore).toList();
        if (overPlayers.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showGameResult(context);
          });
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(template.templateName),
        actions: [
          // IconButton(
          //   icon: Icon(Icons.switch_access_shortcut_add),
          //   tooltip: '新样式，点击切换',
          //   onPressed: () {
          //     Navigator.pushReplacement(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) => LandlordsSessionOldPage(
          //           templateId: widget.templateId,
          //         ),
          //       ),
          //     );
          //   },
          // ),
          IconButton(
            icon: Icon(Icons.sports_score),
            onPressed: () => showGameResult(context),
          ),
          IconButton(
            icon: Icon(Icons.restart_alt_rounded),
            onPressed: () => showResetConfirmation(context),
          )
        ],
      ),
      body: buildGameBody(context, template, session),
    );
  }

  @override
  Widget buildGameBody(
      BuildContext context, BaseTemplate template, GameSession session) {
    final template = ref
        .read(templatesProvider.notifier)
        .getTemplate(widget.templateId) as LandlordsTemplate;

    return Column(
      children: [
        // 可滚动的计分区
        Expanded(
          child: _ScoreBoard(
            template: template,
            session: session,
            onEditRound: _startEditRound,
            currentEditRound: _currentEditRound,
          ),
        ),
        // 编辑面板
        if (_isEditing) _buildEditPanel(template, session)
      ],
    );
  }

  void _startEditRound(int roundIndex) {
    setState(() {
      _isEditing = true;
      _currentEditRound = roundIndex;
      _resetRoundData();

      // 如果是编辑已有轮次，加载已有数据
      final session = ref.read(scoreProvider).value?.currentSession;
      if (session != null &&
          roundIndex < session.scores.first.roundScores.length) {
        _loadRoundData(session, roundIndex);
      }
    });
  }

  void _resetRoundData() {
    _currentLandlordId = null;
    _baseScore = 1;
    _bombUsed = {};
    _rocketUsed = {};
    _springUsed = {};
    _hasSelectedWinner = false;
    _landlordWin = false;
  }

  void _loadRoundData(GameSession session, int roundIndex) {
    for (var playerScore in session.scores) {
      // 从扩展字段中加载数据
      final extendedData = playerScore.getExtendedField(roundIndex);
      if (extendedData != null) {
        if (extendedData['isLandlord'] == true) {
          _currentLandlordId = playerScore.playerId;
          // 从地主的分数判断胜负
          if (roundIndex < playerScore.roundScores.length) {
            final score = playerScore.roundScores[roundIndex] ?? 0;
            _landlordWin = score > 0;
            _hasSelectedWinner = true;
          }
        }
        _baseScore = extendedData['baseScore'] ?? 1;
        _bombUsed[playerScore.playerId] = extendedData['bomb'] ?? 0;
        _rocketUsed[playerScore.playerId] = extendedData['rocket'] ?? false;
        _springUsed[playerScore.playerId] = extendedData['spring'] ?? false;
      }
    }
  }

  Widget _buildWinnerButton({
    required String label,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.horizontal(
        left: label == '地主胜' ? Radius.circular(8) : Radius.zero,
        right: label == '农民胜' ? Radius.circular(8) : Radius.zero,
      ),
      child: InkWell(
        borderRadius: BorderRadius.horizontal(
          left: label == '地主胜' ? Radius.circular(8) : Radius.zero,
          right: label == '农民胜' ? Radius.circular(8) : Radius.zero,
        ),
        onTap: onPressed,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditPanel(LandlordsTemplate template, GameSession session) {
    final players = template.players;

    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border(
            top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 底分设置
          Row(
            children: [
              Text('底分：', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  children: [1, 2, 3]
                      .map((score) => ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _baseScore == score
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                              foregroundColor: _baseScore == score
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                              minimumSize: Size(0, 36),
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => setState(() => _baseScore = score),
                            child: Text('$score分'),
                          ))
                      .toList(),
                ),
              ),
              SizedBox(width: 12),
              // 胜负显示
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildWinnerButton(
                      label: '地主胜',
                      isSelected: _hasSelectedWinner && _landlordWin,
                      onPressed: () => setState(() {
                        _landlordWin = true;
                        _hasSelectedWinner = true;
                      }),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: Colors.grey[300],
                    ),
                    _buildWinnerButton(
                      label: '农民胜',
                      isSelected: _hasSelectedWinner && !_landlordWin,
                      onPressed: () => setState(() {
                        _landlordWin = false;
                        _hasSelectedWinner = true;
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),

          // 玩家设置
          ...players.map((player) => _buildPlayerRow(player, session)),

          SizedBox(height: 8),

          // 按钮区
          Row(
            children: [
              // 提示文字
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Text(
                    _currentLandlordId == null
                        ? '请点击头像选择地主'
                        : !_hasSelectedWinner
                            ? '请选择胜利方'
                            : '',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
              // 按钮区域
              TextButton(
                onPressed: () => setState(() {
                  _isEditing = false;
                  _currentEditRound = -1;
                }),
                child: Text('取消'),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: (_currentLandlordId == null || !_hasSelectedWinner)
                    ? null
                    : () => _calculateAndSaveScores(template, session),
                child: Text('完成本轮计分'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(PlayerInfo player, GameSession session) {
    final isLandlord = _currentLandlordId == player.pid;
    final bombCount = _bombUsed[player.pid] ?? 0;
    final hasRocket = _rocketUsed[player.pid] ?? false;
    final hasSpring = _springUsed[player.pid] ?? false;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLandlord
              ? Colors.orange
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          width: isLandlord ? 1 : 1,
        ),
      ),
      child: Row(
        children: [
          // 玩家头像和地主标记
          GestureDetector(
            onTap: () => setState(() => _currentLandlordId = player.pid),
            child: Stack(
              children: [
                PlayerAvatar.build(context, player),
                if (isLandlord)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.star, size: 12, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 8),

          // 玩家名称
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.name,
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(isLandlord ? '地主' : '农民',
                    style: TextStyle(
                      color: isLandlord ? Colors.orange : Colors.green,
                      fontSize: 12,
                    )),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: IconButton(
                  icon: Icon(Icons.remove_circle_outline),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                  iconSize: 20,
                  onPressed: bombCount > 0
                      ? () =>
                          setState(() => _bombUsed[player.pid] = bombCount - 1)
                      : null,
                ),
              ),
              Container(
                constraints: BoxConstraints(minWidth: 40),
                child: Text(
                  '炸弹($bombCount)',
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(
                width: 24,
                height: 24,
                child: IconButton(
                  icon: Icon(Icons.add_circle_outline),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                  iconSize: 20,
                  onPressed: () =>
                      setState(() => _bombUsed[player.pid] = (bombCount + 1)),
                ),
              ),
            ],
          ),
          // 特殊牌型按钮
          SizedBox(width: 4),
          _buildToggleButton(
            label: '火箭',
            isActive: hasRocket,
            onPressed: () =>
                setState(() => _rocketUsed[player.pid] = !hasRocket),
          ),
          SizedBox(width: 4),
          _buildToggleButton(
            label: '春天',
            isActive: hasSpring,
            onPressed: () =>
                setState(() => _springUsed[player.pid] = !hasSpring),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
      {required String label,
      required bool isActive,
      required VoidCallback onPressed}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        foregroundColor: isActive
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurfaceVariant,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size(0, 32),
      ),
      onPressed: onPressed,
      child: Text(label, style: TextStyle(fontSize: 12)),
    );
  }

  void _calculateAndSaveScores(
      LandlordsTemplate template, GameSession session) {
    // 计算倍数
    int multiplier = 1;

    // 统计炸弹数量
    int bombCount = 0;
    _bombUsed.forEach((playerId, count) {
      bombCount += count;
    });

    // 炸弹翻倍
    if (bombCount > 0) {
      multiplier *= (1 + bombCount);
    }

    // 火箭翻倍
    _rocketUsed.forEach((playerId, used) {
      if (used) multiplier *= 2;
    });

    // 春天翻倍
    _springUsed.forEach((playerId, used) {
      if (used) multiplier *= 2;
    });

    // 计算基础分数
    final baseValue = template.baseScore * _baseScore * multiplier;

    // 直接使用当前选择的胜利方状态
    _finalizeScores(template, session, _landlordWin, baseValue, ref);
  }

  void _finalizeScores(
    LandlordsTemplate template,
    GameSession session,
    bool landlordWin,
    int baseValue,
    WidgetRef ref,
  ) {
    final scoreNotifier = ref.read(scoreProvider.notifier);

    // 计算每个玩家的得分
    for (var playerScore in session.scores) {
      final isLandlord = playerScore.playerId == _currentLandlordId;
      int score;

      if (isLandlord) {
        score = 2 * (landlordWin ? 1 : -1) * baseValue;
      } else {
        score = (landlordWin ? -1 : 1) * baseValue;
      }

      // 保存扩展数据
      final extendedData = {
        'isLandlord': isLandlord,
        'baseScore': _baseScore,
        'bomb': _bombUsed[playerScore.playerId] ?? 0,
        'rocket': _rocketUsed[playerScore.playerId] ?? false,
        'spring': _springUsed[playerScore.playerId] ?? false,
        'multiplier': baseValue / (template.baseScore * _baseScore),
        'landlordWin': landlordWin,
      };

      // 更新或添加分数
      if (_currentEditRound < playerScore.roundScores.length) {
        scoreNotifier.updateScore(
            playerScore.playerId, _currentEditRound, score);
        // 为特定回合设置扩展字段
        extendedData.forEach((key, value) {
          playerScore.setRoundExtendedField(_currentEditRound, key, value);
        });
      } else {
        scoreNotifier.addScore(playerScore.playerId, score);
        final newRoundIndex = playerScore.roundScores.length - 1;
        // 为新回合设置扩展字段
        extendedData.forEach((key, value) {
          playerScore.setRoundExtendedField(newRoundIndex, key, value);
        });
      }
    }

    // 重置编辑状态
    setState(() {
      _isEditing = false;
      _currentEditRound = -1;
    });
  }
}

class _ScoreBoard extends ConsumerStatefulWidget {
  final LandlordsTemplate template;
  final GameSession session;
  final Function(int) onEditRound;
  final int currentEditRound;

  const _ScoreBoard({
    required this.template,
    required this.session,
    required this.onEditRound,
    required this.currentEditRound,
  });

  @override
  _ScoreBoardState createState() => _ScoreBoardState();
}

class _ScoreBoardState extends ConsumerState<_ScoreBoard> {
  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _contentHorizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 同步两个滚动控制器
    _contentHorizontalController.addListener(() {
      _headerHorizontalController.jumpTo(_contentHorizontalController.offset);
    });
  }

  @override
  void dispose() {
    _headerHorizontalController.dispose();
    _contentHorizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentRound = ref.watch(scoreProvider).when(
      loading: () => 0,
      error: (err, stack) => 0,
      data: (state) => state.currentRound,
    );

    return Column(
      children: [
        // 标题行（禁用用户手动滚动）
        SizedBox(
          height: 64,
          child: SingleChildScrollView(
            controller: _headerHorizontalController,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: _buildHeaderRow(),
          ),
        ),
        // 内容区域（垂直 + 水平滚动）
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: SingleChildScrollView(
                    controller: _contentHorizontalController,
                    scrollDirection: Axis.horizontal,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: _buildContentRow(currentRound),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 修改内容行构建方法，支持整行编辑
  Widget _buildContentRow(int currentRound) {
    return Column(
      children: List.generate(
        currentRound + 1,
        (roundIndex) => _buildRoundRow(roundIndex),
      ),
    );
  }

  // 构建标题行
  Widget _buildHeaderRow() {
    final players = widget.template.players;
    final playerWidth = 92.0;

    return Row(
      children: [
        // 轮次列
        Container(
          width: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            border:
                Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Text('轮次', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        // 玩家列
        ...players.map((player) => Container(
              width: playerWidth,
              height: 100,
              // padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                border: Border(
                  right: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant),
                  top: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant),
                  bottom: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    PlayerAvatar.build(context, player),
                    Text(
                      player.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(height: 1.2),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  // 构建每一轮的行
  Widget _buildRoundRow(int roundIndex) {
    final players = widget.template.players;
    final playerWidth = 92.0;
    final isNewRound =
        roundIndex >= widget.session.scores.first.roundScores.length;
    final isEditing = widget.currentEditRound == roundIndex;

    return GestureDetector(
      onTap: () => widget.onEditRound(roundIndex),
      child: Container(
        decoration: BoxDecoration(
          color: isEditing
              ? Theme.of(context).colorScheme.primaryContainer
              : roundIndex % 2 == 0
                  ? Theme.of(context).colorScheme.surface
                  : Theme.of(context).colorScheme.surfaceContainerLow,
          border: Border(
            bottom:
                BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          children: [
            // 轮次列
            Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant),
                  right: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant),
                ),
              ),
              child: Text('第${roundIndex + 1}轮'),
            ),
            // 玩家分数列
            ...players.map((player) {
              final playerScore = _getPlayerScore(player.pid, roundIndex);
              final extendedData =
                  _getExtendedData(player.pid, roundIndex, ref);
              final isLandlord = extendedData?['isLandlord'] == true;
              final totalScore = _getTotalScore(player.pid, roundIndex);

              return Container(
                width: playerWidth,
                height: 60,
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                ),
                child: isNewRound
                    ? Center(
                        child: Icon(Icons.add, color: Colors.grey),
                      )
                    : // 修改后的Stack部分代码
                    Stack(
                        alignment: Alignment.center,
                        children: [
                          // 累计总得分（保持黑色）
                          Text(
                            '$totalScore',
                            style: TextStyle(
                              fontSize: 18,
                              // fontWeight: FontWeight.bold,
                            ),
                          ),
                          // 当前轮得分（应用颜色效果）
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Text(
                              playerScore >= 0
                                  ? '+$playerScore'
                                  : '$playerScore',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: playerScore > 0
                                    ? Colors.green
                                    : playerScore < 0
                                        ? Colors.red
                                        : Colors.grey,
                              ),
                            ),
                          ),
                          // 地主标记
                          if (isLandlord)
                            Positioned(
                              left: 0,
                              top: 0,
                              child: Container(
                                padding: EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.star,
                                    size: 12, color: Colors.white),
                              ),
                            ),
                          // 特殊标记
                          if (extendedData != null)
                            Positioned(
                              bottom: 0,
                              child: _buildSpecialMarkers(extendedData),
                            ),
                        ],
                      ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // 构建特殊标记（炸弹、火箭、春天）
  Widget _buildSpecialMarkers(Map<String, dynamic> extendedData) {
    final List<Widget> markers = [];

    if (extendedData['bomb'] > 0) {
      markers.add(_buildMarker('炸×${extendedData['bomb']}', Colors.red));
    }

    if (extendedData['rocket'] == true) {
      markers.add(_buildMarker('火', Colors.purple));
    }

    if (extendedData['spring'] == true) {
      markers.add(_buildMarker('春', Colors.green));
    }

    return Row(
      mainAxisSize: MainAxisSize.min, // 确保行宽度最小
      children: markers,
    );
  }

  Widget _buildMarker(String text, Color baseColor) {
    final color = Theme.of(context).brightness == Brightness.dark
        ? baseColor.withValues(alpha: 0.7) // 深色模式下稍微调亮
        : baseColor;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      margin: EdgeInsets.only(right: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          height: 1.1,
        ),
      ),
    );
  }

  // 获取玩家在指定轮次的分数
  int _getPlayerScore(String playerId, int roundIndex) {
    final playerScore = widget.session.scores.firstWhere(
      (score) => score.playerId == playerId,
      orElse: () => PlayerScore(playerId: playerId),
    );

    if (roundIndex < playerScore.roundScores.length) {
      return playerScore.roundScores[roundIndex] ?? 0;
    }

    return 0;
  }

  // 获取累计总得分
  int _getTotalScore(String playerId, int roundIndex) {
    final playerScore = widget.session.scores.firstWhere(
      (score) => score.playerId == playerId,
      orElse: () => PlayerScore(playerId: playerId),
    );

    if (roundIndex < playerScore.roundScores.length) {
      return playerScore.roundScores
          .take(roundIndex + 1)
          .fold(0, (sum, item) => sum + (item ?? 0));
    }

    return 0;
  }

// 获取扩展数据
  Map<String, dynamic>? _getExtendedData(
    String playerId,
    int roundIndex,
    WidgetRef ref,
  ) {
    try {
      final playerScore = widget.session.scores.firstWhere(
        (score) => score.playerId == playerId,
      );

      // 使用新的按轮次获取扩展字段的方法
      final extendedData = playerScore.getExtendedField(roundIndex);
      if (extendedData == null) {
        // 尝试从数据库重新加载数据
        final scoreNotifier = ref.read(scoreProvider.notifier);
        scoreNotifier.loadRoundExtendedData(widget.session.sid, roundIndex);
        return playerScore.getExtendedField(roundIndex);
      }

      return extendedData;
    } catch (e) {
      return null;
    }
  }
}
