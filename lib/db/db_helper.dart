import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _database;

  DatabaseHelper._();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'counters.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 创建玩家表
    await db.execute('''
      CREATE TABLE players (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL DEFAULT '未知玩家',
        avatar TEXT NOT NULL DEFAULT 'default_avatar.png'
      )
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
      )
    ''');

    // 创建模板-玩家关联表
    await db.execute('''
      CREATE TABLE template_players (
        template_id TEXT NOT NULL,
        player_id TEXT NOT NULL,
        FOREIGN KEY (template_id) REFERENCES templates (id),
        FOREIGN KEY (player_id) REFERENCES players (id),
        PRIMARY KEY (template_id, player_id)
      )
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
