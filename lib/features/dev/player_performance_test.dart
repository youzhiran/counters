import 'package:counters/common/db/db_helper.dart';
import 'package:counters/common/model/player_info.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/features/player/player_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 玩家游玩次数性能测试工具
class PlayerPerformanceTest {
  static const int _testPlayerCount = 100;
  static const int _testSessionCount = 50;

  /// 运行完整的性能测试
  static Future<void> runPerformanceTest(WidgetRef ref) async {
    if (!kDebugMode) return;

    Log.i('开始玩家游玩次数性能测试');

    try {
      // 1. 准备测试数据
      await _prepareTestData();

      // 2. 测试批量查询性能
      await _testBatchQuery(ref);

      // 3. 测试缓存性能
      await _testCachePerformance(ref);

      // 4. 测试增量更新性能
      await _testIncrementalUpdate(ref);

      // 5. 清理测试数据
      await _cleanupTestData();

      Log.i('玩家游玩次数性能测试完成');
    } catch (e) {
      Log.e('性能测试失败: $e');
    }
  }

  /// 准备测试数据
  static Future<void> _prepareTestData() async {
    final db = await DatabaseHelper.instance.database;

    Log.i('准备测试数据: $_testPlayerCount 个玩家, $_testSessionCount 个会话');

    // 创建测试玩家
    for (int i = 0; i < _testPlayerCount; i++) {
      final player = PlayerInfo(
        pid: 'test_player_$i',
        name: '测试玩家$i',
        avatar: 'default_avatar.png',
      );

      await db.insert('players', player.toJson());
    }

    // 创建测试会话和得分
    for (int sessionIndex = 0;
        sessionIndex < _testSessionCount;
        sessionIndex++) {
      final sessionId = 'test_session_$sessionIndex';

      // 插入会话
      await db.insert('game_sessions', {
        'sid': sessionId,
        'template_id': 'test_template',
        'start_time': DateTime.now().millisecondsSinceEpoch,
        'end_time': DateTime.now().millisecondsSinceEpoch,
        'is_completed': 1,
      });

      // 为随机玩家插入得分记录
      final participatingPlayers =
          List.generate(4, (index) => 'test_player_${index * 5}');

      for (final playerId in participatingPlayers) {
        await db.insert('player_scores', {
          'session_id': sessionId,
          'player_id': playerId,
          'round_number': 1,
          'score': 10,
          'extended_field': null,
        });
      }
    }

    Log.i('测试数据准备完成');
  }

  /// 测试批量查询性能
  static Future<void> _testBatchQuery(WidgetRef ref) async {
    Log.i('测试批量查询性能');

    final playerNotifier = ref.read(playerProvider.notifier);
    final testPlayerIds = List.generate(20, (index) => 'test_player_$index');

    final stopwatch = Stopwatch()..start();

    // 测试批量查询
    final results =
        await playerNotifier.getMultiplePlayerPlayCounts(testPlayerIds);

    stopwatch.stop();

    Log.i(
        '批量查询 ${testPlayerIds.length} 个玩家耗时: ${stopwatch.elapsedMilliseconds}ms');
    Log.i('查询结果: ${results.length} 个玩家数据');
  }

  /// 测试缓存性能
  static Future<void> _testCachePerformance(WidgetRef ref) async {
    Log.i('测试缓存性能');

    final playerNotifier = ref.read(playerProvider.notifier);
    const testPlayerId = 'test_player_0';

    // 第一次查询（缓存未命中）
    final stopwatch1 = Stopwatch()..start();
    final count1 = await playerNotifier.getPlayerPlayCount(testPlayerId);
    stopwatch1.stop();

    // 第二次查询（缓存命中）
    final stopwatch2 = Stopwatch()..start();
    final count2 = await playerNotifier.getPlayerPlayCount(testPlayerId);
    stopwatch2.stop();

    Log.i('首次查询耗时: ${stopwatch1.elapsedMilliseconds}ms, 结果: $count1');
    Log.i('缓存查询耗时: ${stopwatch2.elapsedMilliseconds}ms, 结果: $count2');
    Log.i(
        '缓存加速比: ${(stopwatch1.elapsedMilliseconds / stopwatch2.elapsedMilliseconds).toStringAsFixed(2)}x');
  }

  /// 测试增量更新性能
  static Future<void> _testIncrementalUpdate(WidgetRef ref) async {
    Log.i('测试增量更新性能');

    final playerNotifier = ref.read(playerProvider.notifier);
    final testPlayerIds = ['test_player_0', 'test_player_5', 'test_player_10'];

    final stopwatch = Stopwatch()..start();

    // 测试增量更新
    await playerNotifier.updatePlayerPlayCounts(testPlayerIds);

    stopwatch.stop();

    Log.i(
        '增量更新 ${testPlayerIds.length} 个玩家耗时: ${stopwatch.elapsedMilliseconds}ms');
  }

  /// 清理测试数据
  static Future<void> _cleanupTestData() async {
    final db = await DatabaseHelper.instance.database;

    Log.i('清理测试数据');

    // 删除测试数据
    await db.delete('player_scores',
        where: 'session_id LIKE ?', whereArgs: ['test_session_%']);
    await db.delete('game_sessions',
        where: 'sid LIKE ?', whereArgs: ['test_session_%']);
    await db
        .delete('players', where: 'pid LIKE ?', whereArgs: ['test_player_%']);

    Log.i('测试数据清理完成');
  }

  /// 分析当前缓存状态
  static void analyzeCacheState(WidgetRef ref) {
    if (!kDebugMode) return;

    final playerAsync = ref.read(playerProvider);
    playerAsync.when(
      loading: () => Log.i('玩家数据加载中，无法分析缓存'),
      error: (err, stack) => Log.e('玩家数据加载失败，无法分析缓存: $err'),
      data: (playerState) {
        final cacheSize = playerState.playCountCache.length;
        final playerCount = playerState.players.length;

        Log.i('=== 玩家缓存状态分析 ===');
        Log.i('缓存大小: $cacheSize');
        Log.i('玩家总数: $playerCount');
        Log.i(
            '缓存覆盖率: ${cacheSize > 0 ? (cacheSize / playerCount * 100).toStringAsFixed(1) : 0}%');

        if (cacheSize > 0) {
          final cacheValues = playerState.playCountCache.values.toList();
          final totalPlayCount = cacheValues.fold(0, (sum, count) => sum + count);
          final avgPlayCount = totalPlayCount / cacheSize;

          Log.i('平均游玩次数: ${avgPlayCount.toStringAsFixed(1)}');
          Log.i('最大游玩次数: ${cacheValues.reduce((a, b) => a > b ? a : b)}');
          Log.i('最小游玩次数: ${cacheValues.reduce((a, b) => a < b ? a : b)}');
        }
      },
    );
  }
}
