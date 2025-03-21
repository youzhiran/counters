import 'package:collection/collection.dart';
import 'package:counters/dao/template_dao.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../db/db_helper.dart';
import '../model/base_template.dart';
import '../model/game_session.dart';

class TemplateProvider with ChangeNotifier {
  final dbHelper = DatabaseHelper.instance;
  final _templateDao = TemplateDao(); // 添加 DAO 实例

  List<BaseTemplate>? _templates;
  bool _isLoading = true; // 加载状态
  bool get isLoading => _isLoading;

  TemplateProvider() {
    _initialize();
  }

  List<BaseTemplate> get templates => _templates ?? [];

  Future<void> _initialize() async {
    if (_templates != null) return;
    try {
      _templates = await _templateDao.getAllTemplatesWithPlayers();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<BaseTemplate?> getTemplateAsync(String tid) async {
    _templates ??= await _templateDao.getAllTemplatesWithPlayers();
    return _templates?.firstWhereOrNull((t) => t.tid == tid);
  }

  /// 重新加载模板
  Future<void> reloadTemplates() async {
    _isLoading = true;
    notifyListeners();

    try {
      _templates = await _templateDao.getAllTemplatesWithPlayers();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 通过会话获取模板的方法
  BaseTemplate? getTemplateBySession(GameSession session) {
    return getTemplate(session.templateId);
  }

  BaseTemplate? getTemplate(String tid) {
    return templates.firstWhereOrNull((t) => t.tid == tid);
  }

  Future<void> saveUserTemplate(
      BaseTemplate template, String? baseTemplateId) async {
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
    await reloadTemplates();
  }

  Future<void> deleteTemplate(String tid) async {
    await _templateDao.deleteTemplate(tid);
    await reloadTemplates();
  }

  Future<void> updateTemplate(BaseTemplate template) async {
    if (template.isSystemTemplate) return;
    await _templateDao.updateTemplate(template);
    await reloadTemplates();
  }
}
