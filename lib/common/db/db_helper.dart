import 'dart:io';

import 'package:counters/common/utils/log.dart';
import 'package:counters/features/setting/data_manager.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
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
        version: 1,
        onCreate: _onCreate,
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

  /// 删除并重新创建数据库
  Future<void> resetDatabase() async {
    // 关闭现有数据库连接
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    String path = await getDbPath();

    if (await databaseExists(path)) {
      Log.i('尝试删除数据库：$path');
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
    }

    // 重新初始化数据库
    Log.i('重新创建数据库');
    _database = await _initDatabase();
  }

  Future<void> _onCreate(Database db, int version) async {
    // 创建玩家表
    await db.execute('''
      CREATE TABLE players (
        pid TEXT PRIMARY KEY,
        name TEXT NOT NULL DEFAULT '未知玩家',
        avatar TEXT NOT NULL DEFAULT 'default_avatar.png'
      );
    ''');

    // 创建模板基础表
    await db.execute('''
      CREATE TABLE templates (
        tid TEXT PRIMARY KEY,
        template_name TEXT NOT NULL,
        player_count INTEGER NOT NULL,
        target_score INTEGER NOT NULL,
        is_system_template INTEGER NOT NULL DEFAULT 0,
        base_template_id TEXT,
        template_type TEXT NOT NULL,
        other_set TEXT
      );
      ''');

    // 插入初始系统模板
    for (var template in _initialSystemTemplates) {
      await db.insert('templates', template);
    }

    // 创建模板-玩家关联表
    await db.execute('''
      CREATE TABLE template_players (
        template_id TEXT NOT NULL,
        player_id TEXT NOT NULL,
        PRIMARY KEY (template_id, player_id)
      );
    ''');

    // 创建游戏会话表
    await db.execute('''
      CREATE TABLE game_sessions (
        sid TEXT PRIMARY KEY,
        template_id TEXT NOT NULL,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        is_completed INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 创建玩家得分表
    await db.execute('''
      CREATE TABLE player_scores (
        session_id TEXT NOT NULL,
        player_id TEXT NOT NULL,
        round_number INTEGER NOT NULL,
        score INTEGER,
        extended_field TEXT,
        PRIMARY KEY (session_id, player_id, round_number)
      )
    ''');
  }

  Future<void> _onOpen(Database db) async {
    await _checkAndAddSystemTemplates(db);
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
}
