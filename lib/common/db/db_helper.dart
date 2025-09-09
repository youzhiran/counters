import 'dart:io';

import 'package:counters/common/db/migrations.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/common/utils/platform_utils.dart';
import 'package:counters/features/setting/data_manager.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const int dbVersion = 4;
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _database;

  // 定义初始系统模板数据
  static final List<Map<String, dynamic>> _initialSystemTemplates = [
    {
      'tid': 'poker50',
      'template_name': '3人扑克50分',
      'player_count': 3,
      'target_score': 50,
      'is_system_template': 1,
      'base_template_id': null,
      'template_type': 'poker50',
      'disable_victory_score_check': 0,
      'reverse_win_rule': 0,
      'other_set': null
    },
    {
      'tid': 'landlords',
      'template_name': '斗地主',
      'player_count': 3,
      'target_score': 100,
      'is_system_template': 1,
      'base_template_id': null,
      'template_type': 'landlords',
      'disable_victory_score_check': 0,
      'reverse_win_rule': 0,
      'other_set': null
    },
    {
      'tid': 'mahjong',
      'template_name': '麻将',
      'player_count': 4,
      'target_score': 10000,
      'is_system_template': 1,
      'base_template_id': null,
      'template_type': 'mahjong',
      'disable_victory_score_check': 0,
      'reverse_win_rule': 0,
      'other_set': null
    },
    {
      'tid': 'counter',
      'template_name': '点击计数器',
      'player_count': 4,
      'target_score': 50,
      'is_system_template': 1,
      'base_template_id': null,
      'template_type': 'counter',
      'disable_victory_score_check': 0,
      'reverse_win_rule': 1,
      'other_set': null
    }
    // 如果有新的系统模板，在这里添加
  ];

  DatabaseHelper._();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = await getDbPath();

    bool exists = await databaseExists(path);
    Log.i('数据库${exists ? "已经存在" : "不存在"} 在 $path');

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: dbVersion,
        onCreate: _onCreate,
        onUpgrade: Migrations.onUpgrade,
        onOpen: _onOpen,
      ),
    );
  }

  Future<String> getDbPath() async {
    final appDir = await DataManager.getCurrentDataDir();
    final dbPath = join(appDir, 'databases');
    await Directory(dbPath).create(recursive: true);
    String path = join(dbPath, 'counters.db');
    return path;
  }

  /// 重置数据库连接
  /// 关闭现有连接，下次访问时会重新初始化
  Future<void> resetConnection() async {
    Log.v('DatabaseHelper: 重置数据库连接');
    if (_database != null) {
      await _database!.close();
      _database = null;
      Log.v('DatabaseHelper: 数据库连接已关闭并重置');
    }
  }

  /// 删除并重新创建数据库
  Future<void> resetDatabase() async {
    // 关闭现有数据库连接
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    String path = await getDbPath();

    // 如果是鸿蒙系统，清空数据库数据而不是删除文件
    if (PlatformUtils.isOhosPlatformSync()) {
      await _clearDatabaseDataForOhos();
      return;
    }

    Log.i('尝试删除数据库：$path');
    if (await databaseExists(path)) {
      try {
        await deleteDatabase(path);
        // 检查删除是否成功
        if (await databaseExists(path)) {
          throw Exception('数据库文件删除失败，可能被其他程序占用');
        }
        Log.i('数据库文件删除成功');
      } catch (e) {
        throw Exception('删除数据库文件时出错: $e');
      }
    } else {
      await _printDefaultBaseDirFiles();
    }

    // 重新初始化数据库
    Log.i('重新创建数据库');
    _database = await _initDatabase();
  }

  Future<void> _onCreate(Database db, int version) async {
    Log.i("_onCreate db:${db.path}");

    final batch = db.batch();

    // 创建玩家表
    batch.execute('''
      -- 玩家信息表
      CREATE TABLE players (
        pid TEXT PRIMARY KEY, -- 玩家唯一ID
        name TEXT NOT NULL DEFAULT '未知玩家', -- 玩家名称
        avatar TEXT NOT NULL DEFAULT 'default_avatar.png' -- 玩家头像
      );
    ''');

    // 创建模板基础表
    batch.execute('''
      -- 计分器模板表
      CREATE TABLE templates (
        tid TEXT PRIMARY KEY, -- 模板唯一ID
        template_name TEXT NOT NULL, -- 模板名称
        player_count INTEGER NOT NULL, -- 玩家人数
        target_score INTEGER NOT NULL, -- 目标分数
        is_system_template INTEGER NOT NULL DEFAULT 0, -- 是否为系统模板 (1:是, 0:否)
        base_template_id TEXT, -- 自定义模板所基于的系统模板ID
        template_type TEXT NOT NULL, -- 模板类型 (如: poker50, mahjong)
        disable_victory_score_check INTEGER NOT NULL DEFAULT 0, -- 不检查胜利分数 (1:是, 0:否)
        reverse_win_rule INTEGER NOT NULL DEFAULT 0, -- 反转胜利规则 (1:是, 0:否)
        other_set TEXT -- 其他设置 (JSON格式字符串)
      );
      ''');

    // 插入初始系统模板
    for (var template in _initialSystemTemplates) {
      batch.insert('templates', template);
    }

    // 创建模板-玩家关联表
    batch.execute('''
      -- 模板与玩家常用关联表
      CREATE TABLE template_players (
        template_id TEXT NOT NULL, -- 模板ID
        player_id TEXT NOT NULL, -- 玩家ID
        PRIMARY KEY (template_id, player_id)
      );
    ''');

    // 创建计分会话表
    batch.execute('''
      -- 计分会话历史表
      CREATE TABLE game_sessions (
        sid TEXT PRIMARY KEY, -- 会话唯一ID
        template_id TEXT NOT NULL, -- 使用的模板ID
        start_time INTEGER NOT NULL, -- 开始时间 (Unix时间戳)
        end_time INTEGER, -- 结束时间 (Unix时间戳)
        is_completed INTEGER NOT NULL DEFAULT 0, -- 是否已完成 (1:是, 0:否)
        league_match_id TEXT -- 关联的联赛比赛ID (V2新增)
      )
    ''');

    // 创建玩家得分表
    batch.execute('''
      -- 玩家具体得分历史表
      CREATE TABLE player_scores (
        session_id TEXT NOT NULL, -- 会话ID
        player_id TEXT NOT NULL, -- 玩家ID
        round_number INTEGER NOT NULL, -- 回合数
        score INTEGER, -- 本回合得分
        extended_field TEXT, -- 扩展字段 (用于特殊计分类型, JSON格式)
        PRIMARY KEY (session_id, player_id, round_number)
      )
    ''');

    // 创建V2相关的表
    _createV2Tables(batch);

    await batch.commit(noResult: true);

    // 创建性能优化索引
    await _createPerformanceIndexes(db);
  }

  void _createV2Tables(Batch batch) {
    // 创建联赛表
    batch.execute('''
      -- 联赛信息表 (V2新增)
      CREATE TABLE leagues (
        lid TEXT PRIMARY KEY, -- 联赛唯一ID
        name TEXT NOT NULL, -- 联赛名称
        type TEXT NOT NULL, -- 联赛类型 (如: roundRobin, knockout)
        player_ids TEXT NOT NULL, -- 参赛者ID列表 (JSON格式)
        default_template_id TEXT NOT NULL, -- 默认计分器模板ID
        points_for_win INTEGER NOT NULL, -- 胜场积分
        points_for_draw INTEGER NOT NULL, -- 平局积分
        points_for_loss INTEGER NOT NULL, -- 负场积分
        current_round INTEGER -- 当前进行的轮次 (用于淘汰赛)
      )
    ''');

    // 创建比赛表
    batch.execute('''
      -- 联赛中的比赛记录表 (V2新增)
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
        bracket_type TEXT, -- 比赛类型 (胜者组/败者组, V3新增)
        FOREIGN KEY (league_id) REFERENCES leagues (lid) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onOpen(Database db) async {
    await _checkAndAddSystemTemplates(db);
    await _ensurePerformanceIndexes(db);
  }

  Future<void> _checkAndAddSystemTemplates(Database db) async {
    // 检查每个系统模板是否存在
    for (var templateData in _initialSystemTemplates) {
      final count = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM templates WHERE tid = ?',
        [templateData['tid']],
      ));

      // 如果模板不存在，则添加它
      if (count == 0) {
        Log.i('添加缺失的系统模板: ${templateData['template_name']}');
        await db.insert('templates', templateData);
      }
    }
  }

  /// 创建性能优化索引
  Future<void> _createPerformanceIndexes(Database db) async {
    Log.i('创建性能优化索引');

    // 为 player_scores 表创建索引，优化游玩次数查询
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_player_scores_player_id
      ON player_scores(player_id)
    ''');

    // 为 player_scores 表创建复合索引，优化会话相关查询
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_player_scores_session_player
      ON player_scores(session_id, player_id)
    ''');

    // 为 template_players 表创建索引，优化玩家使用状态查询
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_template_players_player_id
      ON template_players(player_id)
    ''');

    // 为 matches 表创建索引，优化联赛查询
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_matches_league_id
      ON matches(league_id)
    ''');

    Log.i('性能优化索引创建完成');
  }

  /// 确保性能索引存在（用于数据库升级）
  Future<void> _ensurePerformanceIndexes(Database db) async {
    try {
      // 检查索引是否存在，如果不存在则创建
      final indexExists =
          await _checkIndexExists(db, 'idx_player_scores_player_id');
      if (!indexExists) {
        Log.i('检测到缺失的性能索引，正在创建...');
        await _createPerformanceIndexes(db);
      }
    } catch (e) {
      Log.e('检查或创建性能索引时出错: $e');
    }
  }

  /// 检查索引是否存在
  Future<bool> _checkIndexExists(Database db, String indexName) async {
    final result = await db.rawQuery('''
      SELECT name FROM sqlite_master
      WHERE type='index' AND name=?
    ''', [indexName]);
    return result.isNotEmpty;
  }

  /// 打印默认基础目录下的所有文件信息，用于调试
  Future<void> _printDefaultBaseDirFiles() async {
    try {
      final defaultBaseDir = await DataManager.getDefaultBaseDir();
      Log.i('开始打印默认基础目录文件信息：$defaultBaseDir');

      final directory = Directory(defaultBaseDir);
      if (!await directory.exists()) {
        Log.w('默认基础目录不存在：$defaultBaseDir');
        return;
      }

      // 递归列出所有文件和目录
      await for (final entity in directory.list(recursive: true)) {
        try {
          if (entity is File) {
            final stat = await entity.stat();
            final size = stat.size;
            final modified = stat.modified;
            Log.i('文件: ${entity.path} (大小: $size字节, 修改时间: $modified)');
          } else if (entity is Directory) {
            Log.i('目录: ${entity.path}');
          } else {
            Log.i('其他: ${entity.path} (类型: ${entity.runtimeType})');
          }
        } catch (e) {
          Log.w('无法获取文件信息: ${entity.path}, 错误: $e');
        }
      }

      Log.i('默认基础目录文件信息打印完成');
    } catch (e) {
      Log.e('打印默认基础目录文件信息失败: $e');
    }
  }

  /// 鸿蒙系统专用：清空数据库数据而不删除文件
  Future<void> _clearDatabaseDataForOhos() async {
    try {
      Log.i('鸿蒙系统：开始清空数据库数据');

      // 确保数据库已初始化
      final db = await database;

      // 直接清空所有表
      await db.transaction((txn) async {
        await txn.delete('player_scores');
        await txn.delete('game_sessions');
        await txn.delete('template_players');
        await txn.delete('players');
        await txn.delete('templates');

        Log.i('鸿蒙系统：所有表已清空');
      });

      // 重新初始化数据库（会重新创建系统模板）
      await _database!.close();
      _database = null;
      _database = await _initDatabase();

      Log.i('鸿蒙系统：数据库重新初始化完成');
    } catch (e) {
      Log.e('鸿蒙系统：清空数据库数据失败: $e');
      throw Exception('清空数据库数据失败: $e');
    }
  }
}
