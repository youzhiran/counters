import 'package:sqflite/sqflite.dart';

import '../db/base_template.dart';
import '../db/db_helper.dart';
import '../db/landlords.dart';
import '../db/player_info.dart';
import '../db/poker50.dart';

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
          'template_id': template.id,
          'player_id': player.id,
        });
      }
    });
  }

  Future<Poker50Template?> getPoker50Template(String id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'templates',
      where: 'id = ? AND template_type = ?',
      whereArgs: [id, 'poker50'],
    );

    if (maps.isEmpty) return null;

    // 获取关联的玩家
    final playerMaps = await db.rawQuery('''
      SELECT p.* FROM players p
      INNER JOIN template_players tp ON p.id = tp.player_id
      WHERE tp.template_id = ?
    ''', [id]);

    final players = playerMaps.map((map) => PlayerInfo.fromMap(map)).toList();
    return Poker50Template.fromMap(maps.first, players);
  }

  Future<LandlordsTemplate?> getLandlordsTemplate(String id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'templates',
      where: 'id = ? AND template_type = ?',
      whereArgs: [id, 'landlords'],
    );

    if (maps.isEmpty) return null;

    // 获取关联的玩家
    final playerMaps = await db.rawQuery('''
      SELECT p.* FROM players p
      INNER JOIN template_players tp ON p.id = tp.player_id
      WHERE tp.template_id = ?
    ''', [id]);

    final players = playerMaps.map((map) => PlayerInfo.fromMap(map)).toList();
    return LandlordsTemplate.fromMap(maps.first, players);
  }

  Future<void> deleteTemplate(String id) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('template_players',
          where: 'template_id = ?', whereArgs: [id]);
      await txn.delete('templates', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> updateTemplate(BaseTemplate template) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.update('templates', template.toMap(),
          where: 'id = ?', whereArgs: [template.id]);

      await txn.delete('template_players',
          where: 'template_id = ?', whereArgs: [template.id]);

      for (var player in template.players) {
        await txn.insert('template_players', {
          'template_id': template.id,
          'player_id': player.id,
        });
      }
    });
  }

  Future<void> insertSystemTemplate(BaseTemplate template) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.insert('templates', template.toMap());

      for (var player in template.players) {
        await txn.insert('players', player.toMap());
        await txn.insert('template_players', {
          'template_id': template.id,
          'player_id': player.id,
        });
      }
    });
  }

  Future<bool> isTemplateExists(String id) async {
    final db = await dbHelper.database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM templates WHERE id = ?',
      [id],
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
        template = await getPoker50Template(map['id'] as String);
      } else if (map['template_type'] == 'landlords') {
        template = await getLandlordsTemplate(map['id'] as String);
      }
      if (template != null) {
        result.add(template);
      }
    }
    return result;
  }

// 添加其他必要的CRUD方法...
}
