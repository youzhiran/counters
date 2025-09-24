import 'dart:convert';

import 'package:counters/common/utils/log.dart';
import 'package:sqflite/sqflite.dart';

class Migrations {
  static Future<void> onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    Log.i("数据库升级，从版本 $oldVersion 到 $newVersion");
    if (oldVersion < 4) {
      await _apply1to4Migrations(db);
    }
    if (oldVersion < 5) {
      await _apply4to5Migrations(db);
    }
    if (oldVersion < 6) {
      await _ensureRoundRobinRoundsColumn(db);
    }
  }

  static Future<void> _apply1to4Migrations(Database db) async {
    Log.i("应用 v1 到 v4 的数据库结构变更...");

    // 步骤 1: 创建联赛相关的表 (原V2)
    await _createLeagueTables(db);

    // 步骤 2: 为旧表添加新列 (原V2)
    await db.execute('''
        ALTER TABLE game_sessions ADD COLUMN league_match_id TEXT
      ''');
    await db.execute('''
        ALTER TABLE templates ADD COLUMN disable_victory_score_check INTEGER NOT NULL DEFAULT 0
      ''');
    await db.execute('''
        ALTER TABLE templates ADD COLUMN reverse_win_rule INTEGER NOT NULL DEFAULT 0
      ''');

    // 步骤 3: 为 matches 表添加 bracket_type 列 (原V3)
    // 注意：_createLeagueTables 中已直接包含此字段，此处无需 ALTER
    // await db.execute('''
    //     ALTER TABLE matches ADD COLUMN bracket_type TEXT
    //   ''');

    Log.i("数据库表结构变更应用完成。");

    // 步骤 4: 从 other_set 迁移数据到新列 (原V2)
    await _migrateTemplateData(db);

    // 步骤 5: 更新 counter 模板的胜利规则 (原V4)
    await db.update(
      'templates',
      {'reverse_win_rule': 1},
      where: 'tid = ?',
      whereArgs: ['counter'],
    );
    Log.i("数据库数据更新应用完成。");
  }

  static Future<void> _createLeagueTables(Database db) async {
    // 创建联赛表
    await db.execute('''
      -- 联赛信息表
      CREATE TABLE leagues (
        lid TEXT PRIMARY KEY, -- 联赛唯一ID
        name TEXT NOT NULL, -- 联赛名称
        type TEXT NOT NULL, -- 联赛类型 (如: roundRobin, knockout)
        player_ids TEXT NOT NULL, -- 参赛者ID列表 (JSON格式)
        default_template_id TEXT NOT NULL, -- 默认计分器模板ID
        points_for_win INTEGER NOT NULL, -- 胜场积分
        points_for_draw INTEGER NOT NULL, -- 平局积分
        points_for_loss INTEGER NOT NULL, -- 负场积分
        round_robin_rounds INTEGER NOT NULL DEFAULT 1, -- 循环赛总轮次
        current_round INTEGER -- 当前进行的轮次 (用于淘汰赛)
      )
    ''');

    // 创建比赛表 (已包含 bracket_type 字段)
    await db.execute('''
      -- 联赛中的比赛记录表
      CREATE TABLE matches (
        mid TEXT PRIMARY KEY, -- 比赛唯一ID
        league_id TEXT NOT NULL, -- 所属联赛ID
        round INTEGER NOT NULL, -- 比赛轮次
        player1_id TEXT NOT NULL, -- 选手1的ID
        player2_id TEXT, -- 选手2的ID (轮空时可为空)
        status TEXT NOT NULL, -- 比赛状态 (如: pending, in_progress, completed)
        player1_score INTEGER, -- 选手1的得分
        player2_score INTEGER, -- 选手2的得分
        winner_id TEXT, -- 胜利者ID
        template_id TEXT, -- 该场比赛使用的计分器模板ID
        start_time INTEGER, -- 开始时间 (Unix时间戳)
        end_time INTEGER, -- 结束时间 (Unix时间戳)
        bracket_type TEXT, -- 比赛类型 (胜者组/败者组)
        FOREIGN KEY (league_id) REFERENCES leagues (lid) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> _migrateTemplateData(Database db) async {
    Log.i("开始迁移 templates 表的数据...");
    try {
      final templates =
      await db.query('templates', columns: ['tid', 'other_set']);
      final batch = db.batch();

      for (final template in templates) {
        final tid = template['tid'] as String;
        final otherSetJson = template['other_set'] as String?;

        if (otherSetJson != null && otherSetJson.isNotEmpty) {
          try {
            final otherSet = jsonDecode(otherSetJson) as Map<String, dynamic>;
            final disableCheck = otherSet['disableVictoryScoreCheck'] as bool?;
            final reverseRule = otherSet['reverseWinRule'] as bool?;

            if (disableCheck != null || reverseRule != null) {
              final updates = <String, dynamic>{};
              if (disableCheck != null) {
                updates['disable_victory_score_check'] = disableCheck ? 1 : 0;
                otherSet.remove('disableVictoryScoreCheck');
              }
              if (reverseRule != null) {
                updates['reverse_win_rule'] = reverseRule ? 1 : 0;
                otherSet.remove('reverseWinRule');
              }

              // 更新 other_set
              updates['other_set'] =
              otherSet.isEmpty ? null : jsonEncode(otherSet);

              batch.update('templates', updates,
                  where: 'tid = ?', whereArgs: [tid]);
              Log.v("正在迁移模板 $tid 的数据: $updates");
            }
          } catch (e) {
            Log.w("解析或迁移模板 $tid 的 other_set 失败: $e");
          }
        }
      }

      await batch.commit(noResult: true);
      Log.i("templates 表数据迁移成功完成。");
    } catch (e) {
      Log.e("模板数据迁移过程中发生错误: $e");
      // 如果迁移失败，不应阻塞整个升级过程，但需要记录错误
    }
  }

  static Future<void> _apply4to5Migrations(Database db) async {
    Log.i("应用 v4 到 v5 的数据库结构变更...");
    await _ensureRoundRobinRoundsColumn(db);
  }

  /// 确保联赛表存在 round_robin_rounds 列，新安装与旧版本升级都会走到这里。
  static Future<void> _ensureRoundRobinRoundsColumn(Database db) async {
    final hasColumn = await _columnExists(db, 'leagues', 'round_robin_rounds');
    if (hasColumn) {
      Log.i("round_robin_rounds 列已存在，跳过新增步骤。");
      return;
    }
    await db.execute('''
        ALTER TABLE leagues ADD COLUMN round_robin_rounds INTEGER NOT NULL DEFAULT 1
      ''');
    Log.i("round_robin_rounds 列已添加到 leagues 表。");
  }

  /// 查询指定表是否存在特定列，避免重复执行 ALTER 语句。
  static Future<bool> _columnExists(
      Database db, String tableName, String columnName) async {
    final columns = await db.rawQuery('PRAGMA table_info($tableName)');
    for (final column in columns) {
      final name = column['name'] as String?;
      if (name == columnName) {
        return true;
      }
    }
    return false;
  }
}
