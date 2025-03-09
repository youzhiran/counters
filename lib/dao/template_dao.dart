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

// 添加其他必要的CRUD方法...
}