import 'package:counters/common/db/db_helper.dart';
import 'package:counters/common/model/base_template.dart';
import 'package:counters/common/model/player_info.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/common/utils/template_utils.dart';
import 'package:sqflite/sqflite.dart';

class TemplateDao {
  final dbHelper = DatabaseHelper.instance;


  /// 根据模板类型获取对应的模板
  Future<BaseTemplate?> _getTemplateByType(
      String tid, String templateType) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'templates',
      where: 'tid = ?',
      whereArgs: [tid],
    );

    if (maps.isEmpty) return null;

    // 获取关联的玩家
    final playerMaps = await db.rawQuery('''
      SELECT p.* FROM players p
      INNER JOIN template_players tp ON p.pid = tp.player_id
      WHERE tp.template_id = ?
    ''', [tid]);

    final players = playerMaps.map((map) => PlayerInfo.fromJson(map)).toList();

    // 使用 TemplateUtils 构建模板实例
    return TemplateUtils.buildTemplateFromType(
        templateType, maps.first, players);
  }

  /// 插入模板
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
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // 3. 插入模板-玩家关联
      await _insertTemplatePlayers(txn, template);
    });
  }

  /// 更新模板
  Future<void> updateTemplate(BaseTemplate template) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      // 1. 准备并更新模板本身
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

      // 4. 插入新的模板-玩家关联
      await _insertTemplatePlayers(txn, template);
    });
  }

  /// 插入系统模板
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

  /// 删除模板
  Future<void> deleteTemplate(String tid) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('template_players',
          where: 'template_id = ?', whereArgs: [tid]);
      await txn.delete('templates', where: 'tid = ?', whereArgs: [tid]);
    });
  }

  /// 检查模板是否存在
  Future<bool> isTemplateExists(String tid) async {
    final db = await dbHelper.database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM templates WHERE tid = ?',
      [tid],
    ));
    return count != null && count > 0;
  }

  /// 获取所有模板
  Future<List<Map<String, dynamic>>> getAllTemplates() async {
    final db = await dbHelper.database;
    return await db.query('templates');
  }

  /// 获取所有带玩家信息的模板
  Future<List<BaseTemplate>> getAllTemplatesWithPlayers() async {
    final db = await dbHelper.database;
    final templates = await db.query('templates');
    List<BaseTemplate> result = [];

    for (var map in templates) {
      final template = await _getTemplateByType(
        map['tid'] as String,
        map['template_type'] as String,
      );
      if (template != null) {
        result.add(template);
      }
    }
    return result;
  }

  /// 插入模板-玩家关联
  Future<void> _insertTemplatePlayers(
      Transaction txn, BaseTemplate template) async {
    final insertedPlayerIds = <String>{};
    for (var player in template.players) {
      if (insertedPlayerIds.add(player.pid)) {
        await txn.insert('template_players', {
          'template_id': template.tid,
          'player_id': player.pid,
        });
      } else {
        Log.w('尝试为模板 ${template.tid} 插入重复的玩家 ${player.pid}');
      }
    }
  }
}
