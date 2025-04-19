import 'package:collection/collection.dart';
import 'package:counters/common/model/base_template.dart';
import 'package:counters/common/model/game_session.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/features/score/template_dao.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'template_provider.g.dart';

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

  // 新增：保存或更新从网络接收的模板，保留原始TID
  Future<void> saveOrUpdateNetworkTemplate(BaseTemplate template) async {
    Log.i('saveOrUpdateNetworkTemplate 开始，模板ID: ${template.tid}');
    state = const AsyncLoading();
    try {
      Log.d('检查模板是否存在: ${template.tid}');
      final existingTemplate =
          await _templateDao.isTemplateExists(template.tid);
      Log.d('模板存在检查完成: $existingTemplate，模板ID: ${template.tid}');
      if (existingTemplate) {
        Log.d('更新现有模板: ${template.tid}');
        await _templateDao.updateTemplate(template);
        Log.d('模板更新完成: ${template.tid}');
      } else {
        Log.d('插入新模板: ${template.tid}');
        // 确保 isSystemTemplate 为 false，因为网络模板是用户定义的
        final networkTemplate = template.copyWith(isSystemTemplate: false);
        await _templateDao.insertTemplate(networkTemplate);
        Log.d('模板插入完成: ${template.tid}');
      }
      Log.d('保存/更新后获取所有模板，针对模板ID: ${template.tid}');
      final result = await _templateDao.getAllTemplatesWithPlayers();
      Log.d('处理模板ID ${template.tid} 后获取到 ${result.length} 个模板');
      state = AsyncData(result);
      Log.i(
          'saveOrUpdateNetworkTemplate 成功完成，模板ID: ${template.tid}, 当前状态: ${state.runtimeType}');
    } catch (e, s) {
      Log.e(
          'saveOrUpdateNetworkTemplate 出错，模板ID: ${template.tid}. 错误: $e\n堆栈: $s');
      state = AsyncError(e, s);
      Log.i(
          'saveOrUpdateNetworkTemplate 出错完成，模板ID: ${template.tid}, 当前状态: ${state.runtimeType}');
      // 如果调用者需要知道错误，可以选择重新抛出
      // throw e;
    }
  }

  // 新增：强制刷新模板列表
  Future<void> refreshTemplates() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
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
