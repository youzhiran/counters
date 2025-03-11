import 'dart:io';

import 'package:counters/utils/log.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _database;

  DatabaseHelper._();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // 使用应用文档目录
    final appDir = await path_provider.getApplicationDocumentsDirectory();
    final dbPath = join(appDir.path, 'databases');
    await Directory(dbPath).create(recursive: true);
    String path = join(dbPath, 'counters.db');

    bool exists = await databaseExists(path);
    Log.i('数据库${exists ? "已经存在" : "不存在"} 在 $path');

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _onCreate,
      ),
    );
  }

  /// 删除并重新创建数据库
  Future<void> resetDatabase() async {
    try {
      // 关闭现有数据库连接
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      // 获取数据库路径
      final appDir = await path_provider.getApplicationDocumentsDirectory();
      final dbPath = join(appDir.path, 'databases');
      String path = join(dbPath, 'counters.db');

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
    } catch (e) {
      Log.e('重置数据库失败: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // 创建玩家表
    await db.execute('''
      CREATE TABLE players (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL DEFAULT '未知玩家',
        avatar TEXT NOT NULL DEFAULT 'default_avatar.png'
      );
    ''');

    // 创建模板基础表
    await db.execute('''
      CREATE TABLE templates (
        id TEXT PRIMARY KEY,
        template_name TEXT NOT NULL,
        player_count INTEGER NOT NULL,
        target_score INTEGER NOT NULL,
        is_system_template INTEGER NOT NULL DEFAULT 0,
        base_template_id TEXT,
        template_type TEXT NOT NULL,
        is_allow_negative INTEGER NOT NULL DEFAULT 0
      );
      ''');
    await db.execute('''
    INSERT INTO templates (id, template_name, player_count, target_score, is_system_template, base_template_id, template_type, is_allow_negative) 
    VALUES ('poker50', '3人扑克50分', 3, 50, 1, NULL, 'poker50', 0);
    ''');
    await db.execute('''
    INSERT INTO templates (id, template_name, player_count, target_score, is_system_template, base_template_id, template_type, is_allow_negative) 
    VALUES ('landlords', '斗地主', 3, 100, 1, NULL, 'landlords', 0);
    ''');

    // 创建模板-玩家关联表
    await db.execute('''
      CREATE TABLE template_players (
        template_id TEXT NOT NULL,
        player_id TEXT NOT NULL,
        FOREIGN KEY (template_id) REFERENCES templates (id),
        FOREIGN KEY (player_id) REFERENCES players (id),
        PRIMARY KEY (template_id, player_id)
      );
    ''');

    // 创建游戏会话表
    await db.execute('''
      CREATE TABLE game_sessions (
        id TEXT PRIMARY KEY,
        template_id TEXT NOT NULL,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        is_completed INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (template_id) REFERENCES templates (id)
      )
    ''');

    // 创建玩家得分表
    await db.execute('''
      CREATE TABLE player_scores (
        session_id TEXT NOT NULL,
        player_id TEXT NOT NULL,
        round_number INTEGER NOT NULL,
        score INTEGER,
        FOREIGN KEY (session_id) REFERENCES game_sessions (id),
        FOREIGN KEY (player_id) REFERENCES players (id),
        PRIMARY KEY (session_id, player_id, round_number)
      )
    ''');
  }
}
