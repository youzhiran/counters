part of 'home_page.dart';

class _SessionPageLoader extends ConsumerStatefulWidget {
  final BaseTemplate? template;
  final String? templateId;

  const _SessionPageLoader({this.template, this.templateId})
      : assert(template != null || templateId != null);

  @override
  ConsumerState<_SessionPageLoader> createState() => _SessionPageLoaderState();
}

class _SessionPageLoaderState extends ConsumerState<_SessionPageLoader> {
  int _retryCount = 0;

  BaseTemplate? _getTemplate(WidgetRef ref) {
    if (widget.template != null) {
      return widget.template;
    }

    final templatesAsync = ref.watch(templatesProvider);
    return templatesAsync.asData?.value
        .firstWhereOrNull((t) => t.tid == widget.templateId);
  }

  @override
  Widget build(BuildContext context) {
    final template = _getTemplate(ref);
    Log.d(
        '[_SessionPageLoader] Build called. Received template: ${template?.templateName} (ID: ${template?.tid}, Type: ${template?.runtimeType})');

    if (template == null) {
      final lanState = ref.read(lanProvider);
      final isClientMode = lanState.isConnected && !lanState.isHost;

      if (isClientMode) {
        Log.w('客户端模式：等待模板同步，模板ID: ${widget.templateId}');
        if (_retryCount < 10) {
          _retryCount++;
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) setState(() {});
          });
        }
      } else {
        if (_retryCount < 5) {
          _retryCount++;
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              ref.invalidate(templatesProvider);
              ref.read(templatesProvider.notifier).refreshTemplates();
            }
          });
        }
      }
      return Scaffold(
        appBar: AppBar(
          title: const Text('模板同步中'),
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
        ),
        body: const Center(child: Text('正在同步模板信息，请稍候...')),
      );
    }

    Log.d(
        '[_SessionPageLoader] Dispatching based on templateType: ${template.templateType}');
    switch (template.templateType) {
      case Poker50Template.staticTemplateType:
        Log.d('[_SessionPageLoader] -> Poker50SessionPage');
        return Poker50SessionPage(templateId: template.tid);
      case LandlordsTemplate.staticTemplateType:
        Log.d('[_SessionPageLoader] -> LandlordsSessionPage');
        return LandlordsSessionPage(templateId: template.tid);
      case MahjongTemplate.staticTemplateType:
        Log.d('[_SessionPageLoader] -> MahjongPage');
        return MahjongPage(templateId: template.tid);
      case CounterTemplate.staticTemplateType:
        Log.d('[_SessionPageLoader] -> CounterSessionPage');
        return CounterSessionPage(templateId: template.tid);
      default:
        Log.e(
            '[_SessionPageLoader] Unknown template type: ${template.templateType}');
        Future.microtask(() =>
            GlobalMsgManager.showError('未知的模板类型: ${template.templateType}'));
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
          ),
          body: const Center(
            child: Text('错误：未知的模板类型，无法加载计分页面。'),
          ),
        );
    }
  }
}
