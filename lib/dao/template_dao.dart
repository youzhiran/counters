import 'package:sqflite/sqflite.dart';

import '../model/base_template.dart';
import '../db/db_helper.dart';
import '../model/landlords.dart';
import '../model/player_info.dart';
import '../model/poker50.dart';

class TemplateDao {
  final dbHelper = DatabaseHelper.instance;

  Future<void> insertTemplate(BaseTemplate template) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      // 插入模板
      await txn.insert('templates', template.toMap());

      // 插入模板-玩家关联
      for (var player in template.players) {
        await txn.insert('template_players', {
          'template_id': template.tid,
          'player_id': player.pid,
        });
      }
    });
  }

  Future<Poker50Template?> getPoker50Template(String tid) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'templates',
      where: 'tid = ? AND template_type = ?',
      whereArgs: [tid, 'poker50'],
    );

    if (maps.isEmpty) return null;

    // 获取关联的玩家
    final playerMaps = await db.rawQuery('''
      SELECT p.* FROM players p
      INNER JOIN template_players tp ON p.pid = tp.player_id
      WHERE tp.template_id = ?
    ''', [tid]);

    final players = playerMaps.map((map) => PlayerInfo.fromJson(map)).toList();
    return Poker50Template.fromMap(maps.first, players);
  }

  Future<LandlordsTemplate?> getLandlordsTemplate(String tid) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'templates',
      where: 'tid = ? AND template_type = ?',
      whereArgs: [tid, 'landlords'],
    );

    if (maps.isEmpty) return null;

    // 获取关联的玩家
    final playerMaps = await db.rawQuery('''
      SELECT p.* FROM players p
      INNER JOIN template_players tp ON p.pid = tp.player_id
      WHERE tp.template_id = ?
    ''', [tid]);

    final players = playerMaps.map((map) => PlayerInfo.fromJson(map)).toList();
    return LandlordsTemplate.fromMap(maps.first, players);
  }

  Future<void> deleteTemplate(String tid) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('template_players',
          where: 'template_id = ?', whereArgs: [tid]);
      await txn.delete('templates', where: 'tid = ?', whereArgs: [tid]);
    });
  }

  Future<void> updateTemplate(BaseTemplate template) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.update('templates', template.toMap(),
          where: 'tid = ?', whereArgs: [template.tid]);

      await txn.delete('template_players',
          where: 'template_id = ?', whereArgs: [template.tid]);

      for (var player in template.players) {
        await txn.insert('template_players', {
          'template_id': template.tid,
          'player_id': player.pid,
        });
      }
    });
  }

  Future<void> insertSystemTemplate(BaseTemplate template) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.insert('templates', template.toMap());

      for (var player in template.players) {
        await txn.insert('players', player.toJson());
        await txn.insert('template_players', {
          'template_id': template.tid,
          'player_id': player.pid,
        });
      }
    });
  }

  Future<bool> isTemplateExists(String tid) async {
    final db = await dbHelper.database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM templates WHERE tid = ?',
      [tid],
    ));
    return count != null && count > 0;
  }

  Future<List<Map<String, dynamic>>> getAllTemplates() async {
    final db = await dbHelper.database;
    return await db.query('templates');
  }

  Future<List<BaseTemplate>> getAllTemplatesWithPlayers() async {
    final db = await dbHelper.database;
    final templates = await db.query('templates');
    List<BaseTemplate> result = [];

    for (var map in templates) {
      BaseTemplate? template;
      if (map['template_type'] == 'poker50') {
        template = await getPoker50Template(map['tid'] as String);
      } else if (map['template_type'] == 'landlords') {
        template = await getLandlordsTemplate(map['tid'] as String);
      }
      if (template != null) {
        result.add(template);
      }
    }
    return result;
  }

// 添加其他必要的CRUD方法...
}
