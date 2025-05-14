import 'package:counters/common/db/db_helper.dart';
import 'package:counters/common/model/base_template.dart';
import 'package:counters/common/model/landlords.dart';
import 'package:counters/common/model/mahjong.dart';
import 'package:counters/common/model/player_info.dart';
import 'package:counters/common/model/poker50.dart';
import 'package:counters/common/utils/log.dart';
import 'package:sqflite/sqflite.dart';

class TemplateDao {
  final dbHelper = DatabaseHelper.instance;

  Future<void> insertTemplate(BaseTemplate template) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      // 1. 准备并插入模板本身 (移除 players 字段)
      final templateData = Map<String, dynamic>.from(template.toMap())
        ..remove('players');
      await txn.insert('templates', templateData);

      // 2. 插入或更新玩家信息
      for (var player in template.players) {
        await txn.insert(
          'players',
          player.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace, // 如果玩家已存在则更新
        );
      }

      // 3. 插入模板-玩家关联 (增加重复检查)
      final insertedPlayerIds = <String>{};
      for (var player in template.players) {
        if (insertedPlayerIds.add(player.pid)) {
          await txn.insert('template_players', {
            'template_id': template.tid,
            'player_id': player.pid,
          });
        } else {
          Log.w(
              'Attempted to insert duplicate player (${player.pid}) for template (${template.tid}) in insertTemplate.');
        }
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

  Future<MahjongTemplate?> getMahjongTemplate(String tid) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'templates',
      where: 'tid = ? AND template_type = ?',
      whereArgs: [tid, 'mahjong'],
    );

    if (maps.isEmpty) return null;

    // 获取关联的玩家
    final playerMaps = await db.rawQuery('''
      SELECT p.* FROM players p
      INNER JOIN template_players tp ON p.pid = tp.player_id
      WHERE tp.template_id = ?
    ''', [tid]);

    final players = playerMaps.map((map) => PlayerInfo.fromJson(map)).toList();
    return MahjongTemplate.fromMap(maps.first, players);
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
      // 1. 准备并更新模板本身 (移除 players 字段)
      final templateData = Map<String, dynamic>.from(template.toMap())
        ..remove('players');
      await txn.update('templates', templateData,
          where: 'tid = ?', whereArgs: [template.tid]);

      // 2. 插入或更新玩家信息
      for (var player in template.players) {
        await txn.insert(
          'players',
          player.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // 3. 删除旧的模板-玩家关联
      await txn.delete('template_players',
          where: 'template_id = ?', whereArgs: [template.tid]);

      // 4. 插入新的模板-玩家关联 (增加重复检查)
      final insertedPlayerIds = <String>{};
      for (var player in template.players) {
        if (insertedPlayerIds.add(player.pid)) {
          await txn.insert('template_players', {
            'template_id': template.tid,
            'player_id': player.pid,
          });
        } else {
          Log.w(
              'Attempted to insert duplicate player (${player.pid}) for template (${template.tid}) in updateTemplate.');
        }
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
      } else if (map['template_type'] == 'mahjong') {
        template = await getMahjongTemplate(map['tid'] as String);
      }
      if (template != null) {
        result.add(template);
      }
    }
    return result;
  }

// 添加其他必要的CRUD方法...
}
