import 'package:counters/common/db/db_helper.dart';
import 'package:counters/features/score/game_session_dao.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'game_session_dao_provider.g.dart';

// DAO 实例通常是单例或应用级别的，使用 keepAlive: true
@Riverpod(keepAlive: true)
GameSessionDao gameSessionDao(Ref ref) {
  // 获取 DatabaseHelper 实例，DatabaseHelper 应该已经是单例
  final dbHelper = DatabaseHelper.instance;
  // 创建 GameSessionDao 实例并传入 DatabaseHelper
  return GameSessionDao(dbHelper: dbHelper);
}
