import 'package:counters/app/state.dart';
import 'package:counters/common/widgets/responsive_grid_view.dart';
import 'package:counters/common/widgets/template_card.dart';
import 'package:counters/features/template/template_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TemplatePage extends ConsumerStatefulWidget {
  const TemplatePage({super.key});

  @override
  ConsumerState<TemplatePage> createState() => _TemplatePageState();
}

class _TemplatePageState extends ConsumerState<TemplatePage> {
  /// 显示创建模板帮助弹窗
  void _showCreateTemplateHelp() {
    globalState.showCommonDialog(
      child: AlertDialog(
        title: const Text('如何创建用户模板'),
        content: const Text(
          '要创建用于计分的用户模板，请按以下步骤操作：\n\n'
          '1. 浏览下方的系统模板\n'
          '2. 点击您需要的系统模板\n'
          '3. 选择"另存新模板"选项\n'
          '4. 按要求填写信息并保存\n\n'
          '这样就可以创建一个属于您的用户模板，用于计分！',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => globalState.navigatorKey.currentState?.pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(templatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('模板'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '如何创建用户模板',
            onPressed: _showCreateTemplateHelp,
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (Widget child, Animation<double> animation) {
          // 使用淡入淡出动画替代默认的滑动动画，避免从上方滑落的视觉效果
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: templatesAsync.when(
          loading: () => const Center(
            key: ValueKey('loading'),
            child: CircularProgressIndicator(),
          ),
          error: (err, stack) => Center(
            key: ValueKey('error'),
            child: Text('加载失败: $err'),
          ),
          data: (templates) {
            if (templates.isEmpty) {
              return const Center(
                key: ValueKey('empty'),
                child: CircularProgressIndicator(),
              );
            }

            return RefreshIndicator(
              key: const ValueKey('grid'),
              onRefresh: () async => ref.invalidate(templatesProvider),
              child: ResponsiveGridView(
                key: const PageStorageKey<String>('template_list'),
                minItemWidth: 200,
                idealItemWidth: 150,
                itemHeight: 150,
                padding: const EdgeInsets.all(12),
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                itemCount: templates.length,
                itemBuilder: (context, index) => TemplateCard(
                  template: templates[index],
                  mode: TemplateCardMode.management,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}