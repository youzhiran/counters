import 'package:counters/common/utils/log.dart';
import 'package:counters/features/dev/player_performance_test.dart';
import 'package:counters/features/player/player_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 性能优化演示页面
class PerformanceDemoPage extends ConsumerStatefulWidget {
  const PerformanceDemoPage({super.key});

  @override
  ConsumerState<PerformanceDemoPage> createState() =>
      _PerformanceDemoPageState();
}

class _PerformanceDemoPageState extends ConsumerState<PerformanceDemoPage> {
  bool _isRunningTest = false;
  String _testResults = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('性能优化演示'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '玩家游玩次数优化',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text('优化内容：'),
                    const Text('• 数据库索引优化'),
                    const Text('• 智能缓存策略'),
                    const Text('• 增量更新机制'),
                    const Text('• UI层性能优化'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 缓存状态显示
            Consumer(
              builder: (context, ref, child) {
                final playerState = ref.watch(playerProvider);
                final cacheSize = playerState.playCountCache.length;
                final playerCount = playerState.players?.length ?? 0;
                final coverageRate =
                    playerCount > 0 ? (cacheSize / playerCount * 100) : 0;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '当前缓存状态',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text('缓存大小: $cacheSize'),
                        Text('玩家总数: $playerCount'),
                        Text('缓存覆盖率: ${coverageRate.toStringAsFixed(1)}%'),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // 操作按钮
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isRunningTest ? null : _runPerformanceTest,
                  child: _isRunningTest
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('运行性能测试'),
                ),
                ElevatedButton(
                  onPressed: _analyzeCacheState,
                  child: const Text('分析缓存状态'),
                ),
                ElevatedButton(
                  onPressed: _testBatchQuery,
                  child: const Text('测试批量查询'),
                ),
                ElevatedButton(
                  onPressed: _clearResults,
                  child: const Text('清除结果'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 测试结果显示
            if (_testResults.isNotEmpty)
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '测试结果',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              _testResults,
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _runPerformanceTest() async {
    if (!kDebugMode) {
      _showMessage('性能测试仅在调试模式下可用');
      return;
    }

    setState(() {
      _isRunningTest = true;
      _testResults = '正在运行性能测试...\n';
    });

    try {
      await PlayerPerformanceTest.runPerformanceTest(ref);
      setState(() {
        _testResults += '性能测试完成！\n';
        _testResults += '请查看控制台输出获取详细结果。\n';
      });
    } catch (e) {
      setState(() {
        _testResults += '性能测试失败: $e\n';
      });
    } finally {
      setState(() {
        _isRunningTest = false;
      });
    }
  }

  void _analyzeCacheState() {
    if (!kDebugMode) {
      _showMessage('缓存分析仅在调试模式下可用');
      return;
    }

    PlayerPerformanceTest.analyzeCacheState(ref);
    setState(() {
      _testResults += '缓存状态分析完成，请查看控制台输出。\n';
    });
  }

  Future<void> _testBatchQuery() async {
    final playerNotifier = ref.read(playerProvider.notifier);
    final playerState = ref.read(playerProvider);

    if (playerState.players == null || playerState.players!.isEmpty) {
      _showMessage('没有可用的玩家数据');
      return;
    }

    final playerIds = playerState.players!.take(5).map((p) => p.pid).toList();

    setState(() {
      _testResults += '测试批量查询 ${playerIds.length} 个玩家...\n';
    });

    final stopwatch = Stopwatch()..start();

    try {
      final results =
          await playerNotifier.getMultiplePlayerPlayCounts(playerIds);
      stopwatch.stop();

      setState(() {
        _testResults += '批量查询完成！\n';
        _testResults += '耗时: ${stopwatch.elapsedMilliseconds}ms\n';
        _testResults += '结果: ${results.length} 个玩家数据\n';
        _testResults += '详情: ${results.toString()}\n\n';
      });
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _testResults += '批量查询失败: $e\n';
      });
    }
  }

  void _clearResults() {
    setState(() {
      _testResults = '';
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

/// 性能优化功能的快速访问工具
class PerformanceUtils {
  /// 快速分析当前缓存状态
  static void quickAnalyze(WidgetRef ref) {
    if (kDebugMode) {
      PlayerPerformanceTest.analyzeCacheState(ref);
    }
  }

  /// 快速测试批量查询性能
  static Future<void> quickBatchTest(
      WidgetRef ref, List<String> playerIds) async {
    if (kDebugMode && playerIds.isNotEmpty) {
      final playerNotifier = ref.read(playerProvider.notifier);
      final stopwatch = Stopwatch()..start();

      try {
        final results =
            await playerNotifier.getMultiplePlayerPlayCounts(playerIds);
        stopwatch.stop();

        Log.i('批量查询测试完成:');
        Log.i('- 查询玩家数: ${playerIds.length}');
        Log.i('- 耗时: ${stopwatch.elapsedMilliseconds}ms');
        Log.i('- 结果数: ${results.length}');
      } catch (e) {
        Log.e('批量查询测试失败: $e');
      }
    }
  }

  /// 快速测试缓存性能
  static Future<void> quickCacheTest(WidgetRef ref, String playerId) async {
    if (kDebugMode) {
      final playerNotifier = ref.read(playerProvider.notifier);

      // 第一次查询
      final stopwatch1 = Stopwatch()..start();
      await playerNotifier.getPlayerPlayCount(playerId);
      stopwatch1.stop();

      // 第二次查询（应该命中缓存）
      final stopwatch2 = Stopwatch()..start();
      await playerNotifier.getPlayerPlayCount(playerId);
      stopwatch2.stop();

      Log.i('缓存性能测试:');
      Log.i('- 首次查询: ${stopwatch1.elapsedMilliseconds}ms');
      Log.i('- 缓存查询: ${stopwatch2.elapsedMilliseconds}ms');
      Log.i(
          '- 加速比: ${(stopwatch1.elapsedMilliseconds / stopwatch2.elapsedMilliseconds).toStringAsFixed(2)}x');
    }
  }
}
