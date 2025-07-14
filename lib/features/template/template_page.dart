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
  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(templatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('模板'),
        automaticallyImplyLeading: false,
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
              child: GridView.builder(
                key: const PageStorageKey('template_grid'),
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  mainAxisExtent: 150,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
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