import 'package:collection/collection.dart';
import 'package:counters/dao/template_dao.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../model/base_template.dart';
import '../model/game_session.dart';

part 'generated/template_provider.g.dart';

@riverpod
class Templates extends _$Templates {
  final _templateDao = TemplateDao();

  @override
  Future<List<BaseTemplate>> build() async {
    return _templateDao.getAllTemplatesWithPlayers();
  }

  Future<BaseTemplate?> getTemplateAsync(String tid) async {
    final templates = await future;
    return templates.firstWhereOrNull((t) => t.tid == tid);
  }

  BaseTemplate? getTemplate(String tid) {
    return state.valueOrNull?.firstWhereOrNull((t) => t.tid == tid);
  }

  BaseTemplate? getTemplateBySession(GameSession session) {
    return getTemplate(session.templateId);
  }

  Future<void> saveUserTemplate(
      BaseTemplate template, String? baseTemplateId) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      // 查找原始系统模板
      String? rootTemplateId = baseTemplateId;
      BaseTemplate? current = getTemplate(baseTemplateId ?? '');

      while (current != null && !current.isSystemTemplate) {
        rootTemplateId = current.baseTemplateId;
        current = getTemplate(rootTemplateId ?? '');
      }

      final newTemplate = template.copyWith(
        tid: const Uuid().v4(),
        baseTemplateId: rootTemplateId,
        isSystemTemplate: false,
      );

      await _templateDao.insertTemplate(newTemplate);
      return _templateDao.getAllTemplatesWithPlayers();
    });
  }

  Future<void> deleteTemplate(String tid) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _templateDao.deleteTemplate(tid);
      return _templateDao.getAllTemplatesWithPlayers();
    });
  }

  Future<void> updateTemplate(BaseTemplate template) async {
    if (template.isSystemTemplate) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _templateDao.updateTemplate(template);
      return _templateDao.getAllTemplatesWithPlayers();
    });
  }
}

// // 在 Widget 中使用
// final templates = ref.watch(templatesProvider);

// // 模板列表
// templates.when(
//   data: (list) => ListView(...),
//   loading: () => CircularProgressIndicator(),
//   error: (err, stack) => Text('Error: $err'),
// );

// // 调用方法
// await ref.read(templatesProvider.notifier).saveUserTemplate(...);
