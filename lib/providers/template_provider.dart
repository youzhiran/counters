import 'package:collection/collection.dart';
import 'package:counters/dao/template_dao.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../db/base_template.dart';
import '../db/db_helper.dart';
import '../db/landlords.dart';
import '../db/player_info.dart';
import '../db/poker50.dart';

class TemplateProvider with ChangeNotifier {
  final dbHelper = DatabaseHelper.instance;
  final _templateDao = TemplateDao(); // 添加 DAO 实例

  // final List<BaseTemplate> _systemTemplates = [
  //   Poker50Template(
  //       templateName: '3人扑克50分',
  //       playerCount: 3,
  //       targetScore: 50,
  //       players: List.generate(
  //           3,
  //           (i) => PlayerInfo(
  //                 name: '玩家 ${i + 1}',
  //                 avatar: 'default_avatar.png',
  //               )),
  //       isSystemTemplate: true,
  //       isAllowNegative: false),
  //   LandlordsTemplate(
  //       templateName: '斗地主',
  //       playerCount: 3,
  //       targetScore: 100,
  //       players: List.generate(
  //           3,
  //           (i) => PlayerInfo(
  //                 name: '玩家 ${i + 1}',
  //                 avatar: 'default_avatar.png',
  //               )),
  //       isSystemTemplate: true,
  //       isAllowNegative: false),
  // ];

  List<BaseTemplate>? _templates;

  TemplateProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    // await _checkSystemTemplates();
    await _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    _templates = await _templateDao.getAllTemplatesWithPlayers();
    notifyListeners();
  }

  // 通过会话获取模板的方法
  BaseTemplate? getTemplateBySession(GameSession session) {
    return getTemplate(session.templateId);
  }

  // // 检查系统模板
  // Future<void> _checkSystemTemplates() async {
  //   for (final template in _systemTemplates) {
  //     if (!await _templateDao.isTemplateExists(template.id)) {
  //       await _templateDao.insertSystemTemplate(template);
  //     }
  //   }
  // }

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
    await _loadTemplates();
  }

  Future<void> deleteTemplate(String id) async {
    await _templateDao.deleteTemplate(id);
    await _loadTemplates();
  }

  Future<void> updateTemplate(BaseTemplate template) async {
    if (template.isSystemTemplate) return;
    await _templateDao.updateTemplate(template);
    await _loadTemplates();
  }
}
