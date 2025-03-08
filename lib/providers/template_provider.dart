import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../model/base_template.dart';
import '../model/landlords.dart';
import '../model/poker50.dart';
import '../model/player_info.dart';

class TemplateProvider with ChangeNotifier {
  final Box<BaseTemplate> _templateBox;
  final List<BaseTemplate> _systemTemplates = [
    Poker50Template(
        templateName: '3人扑克50分',
        playerCount: 3,
        targetScore: 50,
        players: List.generate(
            3,
            (i) => PlayerInfo(
                  name: '玩家 ${i + 1}',
                  avatar: 'default_avatar.png',
                )),
        isSystemTemplate: true,
        isAllowNegative: false),
    LandlordsTemplate(
        templateName: '斗地主',
        playerCount: 3,
        targetScore: 100,
        players: List.generate(
            3,
            (i) => PlayerInfo(
                  name: '玩家 ${i + 1}',
                  avatar: 'default_avatar.png',
                )),
        isSystemTemplate: true,
        isAllowNegative: false),
  ];

  TemplateProvider(this._templateBox) {
    _checkSystemTemplates();
  }

  // 通过会话获取模板的方法
  BaseTemplate? getTemplateBySession(GameSession session) {
    return getTemplate(session.templateId);
  }

  // 检查系统模板初始化
  void _checkSystemTemplates() {
    for (final t in _systemTemplates) {
      _templateBox.put(t.id, t);
    }
  }

  List<BaseTemplate> get templates => [
        ..._systemTemplates,
        ..._templateBox.values.where((t) => !t.isSystemTemplate)
      ];

  BaseTemplate? getTemplate(String id) {
    return _templateBox.get(id) ??
        _systemTemplates.firstWhereOrNull((t) => t.id == id);
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
      baseTemplateId: rootTemplateId, // 始终指向系统模板
      isSystemTemplate: false,
    );

    await _templateBox.put(newTemplate.id, newTemplate);
    notifyListeners();
  }

  Future<void> deleteTemplate(String id) async {
    await _templateBox.delete(id);
    notifyListeners();
  }

  PlayerInfo? getPlayer(String playerId) {
    return templates
        .expand((t) => t.players)
        .firstWhereOrNull((p) => p.id == playerId);
  }

  // 模板更新方法
  Future<void> updateTemplate(BaseTemplate template) async {
    if (template.isSystemTemplate) return;
    await _templateBox.put(template.id, template);
    notifyListeners();
  }
}
