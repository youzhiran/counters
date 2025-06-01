import 'package:counters/common/model/player_score.dart';
import 'package:counters/features/score/score_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 快捷输入面板组件
/// 提供常用数值的快速输入按钮，支持左右滑动切换功能区
/// 支持上下滑动收起/展开面板
class QuickInputPanel extends ConsumerStatefulWidget {
  const QuickInputPanel({super.key});

  @override
  ConsumerState<QuickInputPanel> createState() => _QuickInputPanelState();
}

class _QuickInputPanelState extends ConsumerState<QuickInputPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['快捷输入'];

  // 不同标签页的数字配置
  final List<int> _commonNumbers = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];

  // 面板状态控制
  final bool _isPanelExpanded = true;

  // 添加面板高度控制
  double _panelHeight = 140.0; // 默认高度

  // 常量定义，避免魔法数字
  static const double _defaultPanelHeight = 140.0;
  static const double _tabHeight = 30.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);

    // 监听标签页变化，重置面板高度
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _panelHeight = _defaultPanelHeight; // 切换标签时重置为默认高度
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.zero,
            bottomRight: Radius.zero,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildTabBar(context),
            _buildContentArea(),
          ],
        ),
      ),
    );
  }

  // 构建标签栏
  Widget _buildTabBar(BuildContext context) {
    return TabBar(
      controller: _tabController,
      tabs: _tabs
          .map((tab) => Tab(
                text: tab,
                height: _tabHeight, // 减小标签高度
              ))
          .toList(),
      labelColor: Theme.of(context).colorScheme.primary,
      unselectedLabelColor: Colors.grey,
      indicatorSize: TabBarIndicatorSize.label,
      indicatorWeight: 3,
      dividerHeight: 0,
      labelPadding: const EdgeInsets.symmetric(vertical: 2), // 减小标签内边距
    );
  }

  // 构建内容区域
  Widget _buildContentArea() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _isPanelExpanded ? _panelHeight : 0, // 使用动态高度
      child: TabBarView(
        controller: _tabController,
        physics: _isPanelExpanded
            ? const AlwaysScrollableScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        children: [
          _buildCommonNumbersTab(),
        ],
      ),
    );
  }

  // 常用数字标签页
  Widget _buildCommonNumbersTab() {
    return _buildNumberGrid(_commonNumbers);
  }

  // 构建数字网格
  Widget _buildNumberGrid(List<int> numbers) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 0,
        runSpacing: 0,
        alignment: WrapAlignment.center,
        children: numbers.map((number) => _buildNumberButton(number)).toList(),
      ),
    );
  }

  // 构建数字按钮
  Widget _buildNumberButton(int number) {
    return SizedBox(
      width: 80, // 固定按钮宽度
      child: ActionChip(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // 直角
          side: BorderSide.none, // 移除边框
        ),
        label: Container(
          width: double.infinity, // 标签填满宽度
          alignment: Alignment.center,
          child: Text(number >= 0 ? '+$number' : '$number'),
        ),
        labelPadding: EdgeInsets.zero,
        // 移除标签内边距
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onPressed: () => _handleNumberPressed(number),
      ),
    );
  }

  // 处理数字按钮点击
  void _handleNumberPressed(int number) {
    final highlight = ref.watch(scoreProvider).value?.currentHighlight;
    final session = ref.watch(scoreProvider).value?.currentSession;

    HapticFeedback.mediumImpact();

    if (highlight != null && session != null) {
      final playerScore = session.scores.firstWhere(
        (s) => s.playerId == highlight.key,
        orElse: () => PlayerScore(playerId: 'invalid', roundScores: []),
      );

      if (playerScore.playerId != 'invalid') {
        final currentValue = playerScore.roundScores.length > highlight.value
            ? playerScore.roundScores[highlight.value] ?? 0
            : 0;
        ref.read(scoreProvider.notifier).updateScore(
              highlight.key,
              highlight.value,
              currentValue + number,
            );
      }
    }
    ref.read(scoreProvider.notifier).updateHighlight();
  }
}
