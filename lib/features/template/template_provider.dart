import 'package:collection/collection.dart';
import 'package:counters/common/model/base_template.dart';
import 'package:counters/common/model/game_session.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/features/lan/lan_provider.dart';
import 'package:counters/features/template/template_dao.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'template_provider.g.dart';

// 全局的客户端模板缓存，避免Provider重建时丢失
class _ClientModeTemplateCache {
  static List<BaseTemplate>? _templates;
  static bool _isClientMode = false;

  static void setTemplates(List<BaseTemplate> templates, bool isClientMode) {
    _templates = templates;
    _isClientMode = isClientMode;
    Log.d('_ClientModeTemplateCache.setTemplates: ${templates.length} 个模板, 客户端模式: $isClientMode');
  }

  static List<BaseTemplate>? getTemplates(bool isClientMode) {
    if (isClientMode && _isClientMode && _templates != null) {
      Log.d('_ClientModeTemplateCache.getTemplates: 返回缓存的 ${_templates!.length} 个模板');
      return _templates;
    }
    return null;
  }

  static void clear() {
    Log.d('_ClientModeTemplateCache.clear: 清除缓存');
    _templates = null;
    _isClientMode = false;
  }
}

@riverpod
class Templates extends _$Templates {
  final _templateDao = TemplateDao();

  @override
  Future<List<BaseTemplate>> build() async {
    // 修复：检查是否为客户端模式，如果是且已有缓存数据，则不重新加载数据库
    final lanState = ref.read(lanProvider);
    final isClientMode = lanState.isConnected && !lanState.isHost;

    Log.d('TemplatesProvider.build() 被调用 - 客户端模式: $isClientMode');

    // 尝试从全局缓存获取
    final cachedTemplates = _ClientModeTemplateCache.getTemplates(isClientMode);
    if (cachedTemplates != null) {
      Log.i('客户端模式：build() 返回全局缓存的模板数据，数量: ${cachedTemplates.length}');
      Log.i('缓存模板ID: ${cachedTemplates.map((t) => t.tid).join(", ")}');
      return cachedTemplates;
    }

    Log.d('正常模式：从数据库加载模板');
    final templates = await _templateDao.getAllTemplatesWithPlayers();
    Log.d('从数据库加载的模板数量: ${templates.length}, ID: ${templates.map((t) => t.tid).join(", ")}');

    // 如果不是客户端模式，清除全局缓存
    if (!isClientMode) {
      _ClientModeTemplateCache.clear();
    }

    return templates;
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

  /// 检查当前是否为客户端模式（连接到主机但不是主机）
  bool _isClientMode() {
    final lanState = ref.read(lanProvider);
    // 客户端模式：已连接但不是主机
    return lanState.isConnected && !lanState.isHost;
  }

  // 新增：保存或更新从网络接收的模板，保留原始TID
  Future<void> saveOrUpdateNetworkTemplate(BaseTemplate template) async {
    Log.i('saveOrUpdateNetworkTemplate 开始，模板ID: ${template.tid}');

    // 修复：客户端模式下不保存模板到本地数据库，仅在内存中保持
    if (_isClientMode()) {
      Log.i('客户端模式：跳过模板保存到数据库，仅在内存中保持模板信息');
      // 在客户端模式下，我们仍然需要更新状态以包含新模板，但不保存到数据库
      try {
        final currentTemplates = _ClientModeTemplateCache.getTemplates(true) ?? state.valueOrNull ?? [];
        final existingIndex = currentTemplates.indexWhere((t) => t.tid == template.tid);

        List<BaseTemplate> updatedTemplates;
        if (existingIndex != -1) {
          // 更新现有模板
          updatedTemplates = List.from(currentTemplates);
          updatedTemplates[existingIndex] = template;
          Log.i('客户端模式：在内存中更新模板 ${template.tid}');
        } else {
          // 添加新模板
          updatedTemplates = [...currentTemplates, template];
          Log.i('客户端模式：在内存中添加新模板 ${template.tid}');
        }

        // 更新全局缓存和状态
        _ClientModeTemplateCache.setTemplates(updatedTemplates, true);
        state = AsyncData(updatedTemplates);
        Log.i('客户端模式：模板 ${template.tid} 已在内存中更新，当前模板数量: ${updatedTemplates.length}');
      } catch (e, s) {
        Log.e('客户端模式：内存中更新模板失败: $e\n堆栈: $s');
        state = AsyncError(e, s);
      }
      return;
    }

    // 主机模式：正常保存到数据库
    state = const AsyncLoading();
    try {
      Log.d('主机模式：检查模板是否存在: ${template.tid}');
      final existingTemplate =
          await _templateDao.isTemplateExists(template.tid);
      Log.d('主机模式：模板存在检查完成: $existingTemplate，模板ID: ${template.tid}');
      if (existingTemplate) {
        Log.d('主机模式：更新现有模板: ${template.tid}');
        await _templateDao.updateTemplate(template);
        Log.d('主机模式：模板更新完成: ${template.tid}');
      } else {
        Log.d('主机模式：插入新模板: ${template.tid}');
        // 确保 isSystemTemplate 为 false，因为网络模板是用户定义的
        final networkTemplate = template.copyWith(isSystemTemplate: false);
        await _templateDao.insertTemplate(networkTemplate);
        Log.d('主机模式：模板插入完成: ${template.tid}');
      }
      Log.d('主机模式：保存/更新后获取所有模板，针对模板ID: ${template.tid}');
      final result = await _templateDao.getAllTemplatesWithPlayers();
      Log.d('主机模式：处理模板ID ${template.tid} 后获取到 ${result.length} 个模板');
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
    // 修复：客户端模式下不要重新从数据库加载，避免覆盖内存中的临时模板
    if (_isClientMode()) {
      Log.i('客户端模式：跳过模板刷新，保持内存中的临时模板');
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return _templateDao.getAllTemplatesWithPlayers();
    });
  }

  /// 清理客户端模式下的临时模板数据（当断开连接时调用）
  Future<void> clearClientModeTemplates() async {
    Log.i('清理客户端模式临时模板数据');

    // 清除全局缓存（无论当前状态如何都要清理）
    _ClientModeTemplateCache.clear();

    // 重新从数据库加载模板，这样会移除所有仅在内存中的网络模板
    try {
      state = await AsyncValue.guard(() async {
        return _templateDao.getAllTemplatesWithPlayers();
      });
      Log.i('客户端模式：模板数据已重新从数据库加载');
    } catch (e) {
      Log.e('重新加载模板数据时出错: $e');
      // 如果加载失败，至少确保状态不是loading
      if (state.isLoading) {
        state = AsyncError(e, StackTrace.current);
      }
    }
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
