import 'package:collection/collection.dart';
import 'package:counters/dao/template_dao.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../db/base_template.dart';
import '../db/db_helper.dart';
import '../db/poker50.dart';

class TemplateProvider with ChangeNotifier {
  final dbHelper = DatabaseHelper.instance;
  final _templateDao = TemplateDao(); // 添加 DAO 实例

  List<BaseTemplate>? _templates;
  bool _isLoading = true; // 加载状态
  bool get isLoading => _isLoading;

  TemplateProvider() {
    _isLoading = false;
    _initialize();
  }

  Future<void> _initialize() async {
    if (_templates != null) return; // 如果已经加载过，就不再重复加载

    _isLoading = true;
    notifyListeners();

    try {
      _templates = await _templateDao.getAllTemplatesWithPlayers();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 通过会话获取模板的方法
  BaseTemplate? getTemplateBySession(GameSession session) {
    return getTemplate(session.templateId);
  }

  List<BaseTemplate> get templates => _templates ?? [];

  BaseTemplate? getTemplate(String id) {
    return templates.firstWhereOrNull((t) => t.id == id);
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
      id: const Uuid().v4(),
      baseTemplateId: rootTemplateId,
      isSystemTemplate: false,
    );

    await _templateDao.insertTemplate(newTemplate);
    await _initialize();
  }

  Future<void> deleteTemplate(String id) async {
    await _templateDao.deleteTemplate(id);
    await _initialize();
  }

  Future<void> updateTemplate(BaseTemplate template) async {
    if (template.isSystemTemplate) return;
    await _templateDao.updateTemplate(template);
    await _initialize();
  }
}
