part of '../home_page.dart';

class _TemplateSelector extends ConsumerWidget {
  const _TemplateSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(templatesProvider);

    return templatesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('加载失败: $err')),
      data: (templates) {
        final userTemplates =
            templates.where((template) => !template.isSystemTemplate).toList();

        return userTemplates.isEmpty
            ? RepaintBoundary(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '暂无可使用的模板\n请先选择系统模板创建自定义模板',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/templates',
                          (route) => false,
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(200, 48),
                        ),
                        child: const Text('前往模板管理'),
                      ),
                    ],
                  ),
                ),
              )
            : OptimizedGridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  mainAxisExtent: 150,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: userTemplates.length,
                itemBuilder: (context, index) => SmartListItem(
                  debugLabel: 'TemplateCard_$index',
                  child: TemplateCard(
                    template: userTemplates[index],
                    mode: TemplateCardMode.selection,
                    onTap: () => _handleTemplateSelect(
                      context,
                      ref,
                      userTemplates[index],
                    ),
                  ),
                ),
              );
      },
    );
  }

  void _handleTemplateSelect(
    BuildContext context,
    WidgetRef ref,
    BaseTemplate template,
  ) {
    ref.read(scoreProvider.notifier).startNewGame(template);
    Navigator.of(context).pushReplacement(
      CustomPageTransitions.slideFromRight(
        HomePage.buildSessionPage(template),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      ),
    );
  }
}
