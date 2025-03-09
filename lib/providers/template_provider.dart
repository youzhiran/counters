import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../db/base_template.dart';
import '../db/db_helper.dart';
import '../db/landlords.dart';
import '../db/player_info.dart';
import '../db/poker50.dart';

class TemplateProvider with ChangeNotifier {
  final dbHelper = DatabaseHelper.instance;
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

  List<BaseTemplate>? _templates;

  TemplateProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _checkSystemTemplates();
    await _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('templates');

    _templates = [];
    for (var map in maps) {
      final playerMaps = await db.rawQuery('''
        SELECT p.* FROM players p
        INNER JOIN template_players tp ON p.id = tp.player_id
        WHERE tp.template_id = ?
      ''', [map['id']]);

      final players = playerMaps.map((m) => PlayerInfo.fromMap(m)).toList();

      if (map['template_type'] == 'poker50') {
        _templates!.add(Poker50Template.fromMap(map, players));
      } else if (map['template_type'] == 'landlords') {
        _templates!.add(LandlordsTemplate.fromMap(map, players));
      }
    }
    notifyListeners();
  }

  // 通过会话获取模板的方法
  BaseTemplate? getTemplateBySession(GameSession session) {
    return getTemplate(session.templateId);
  }

  Future<void> _checkSystemTemplates() async {
    final db = await dbHelper.database;
    for (final template in _systemTemplates) {
      // 检查系统模板是否存在
      final count = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM templates WHERE id = ?',
        [template.id],
      ));

      if (count == 0) {
        await db.transaction((txn) async {
          // 插入模板
          await txn.insert('templates', template.toMap());

          // 插入玩家
          for (var player in template.players) {
            await txn.insert('players', player.toMap());

            // 插入关联关系
            await txn.insert('template_players', {
              'template_id': template.id,
              'player_id': player.id,
            });
          }
        });
      }
    }
  }

  List<BaseTemplate> get templates =>
      [..._systemTemplates, ...?_templates?.where((t) => !t.isSystemTemplate)];

  BaseTemplate? getTemplate(String id) {
    return templates.firstWhereOrNull((t) => t.id == id);
  }

  Future<void> saveUserTemplate(
      BaseTemplate template, String? baseTemplateId) async {
    final db = await dbHelper.database;

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

    await db.transaction((txn) async {
      await txn.insert('templates', newTemplate.toMap());

      for (var player in newTemplate.players) {
        await txn.insert('players', player.toMap());
        await txn.insert('template_players', {
          'template_id': newTemplate.id,
          'player_id': player.id,
        });
      }
    });

    await _loadTemplates();
  }

  Future<void> deleteTemplate(String id) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      // 删除模板-玩家关联
      await txn.delete('template_players',
          where: 'template_id = ?', whereArgs: [id]);
      // 删除模板
      await txn.delete('templates', where: 'id = ?', whereArgs: [id]);
    });
    await _loadTemplates();
  }

  Future<void> updateTemplate(BaseTemplate template) async {
    if (template.isSystemTemplate) return;

    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.update('templates', template.toMap(),
          where: 'id = ?', whereArgs: [template.id]);

      // 更新玩家关联
      await txn.delete('template_players',
          where: 'template_id = ?', whereArgs: [template.id]);

      for (var player in template.players) {
        await txn.insert('template_players', {
          'template_id': template.id,
          'player_id': player.id,
        });
      }
    });

    await _loadTemplates();
  }
}
