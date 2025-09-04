import 'package:collection/collection.dart';
import 'package:counters/app/state.dart';
import 'package:counters/common/model/base_template.dart';
import 'package:counters/common/model/counter.dart';
import 'package:counters/common/model/game_session.dart';
import 'package:counters/common/model/landlords.dart';
import 'package:counters/common/model/league_enums.dart';
import 'package:counters/common/model/mahjong.dart';
import 'package:counters/common/model/player_info.dart';
import 'package:counters/common/model/poker50.dart';
import 'package:counters/common/providers/league_provider.dart';
import 'package:counters/common/utils/error_handler.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/common/utils/wakelock_helper.dart';
import 'package:counters/common/widgets/dice_roller_dialog.dart';
import 'package:counters/common/widgets/message_overlay.dart';
import 'package:counters/common/widgets/page_transitions.dart';
import 'package:counters/features/lan/lan_discovery_page.dart';
import 'package:counters/features/lan/lan_provider.dart';
import 'package:counters/features/lan/log_test_page.dart';
import 'package:counters/features/lan/widgets/lan_status_button.dart';
import 'package:counters/features/lan/widgets/ping_widget.dart';
import 'package:counters/features/score/counter/config.dart';
import 'package:counters/features/score/landlords/config.dart';
import 'package:counters/features/score/mahjong/config.dart';
import 'package:counters/features/score/poker50/config.dart';
import 'package:counters/features/score/score_provider.dart';
import 'package:counters/features/score/widgets/base_score_edit_dialog.dart';
import 'package:counters/features/score/widgets/score_chart_bottom_sheet.dart';
import 'package:counters/features/setting/screen_wakelock_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class BaseSessionPage extends ConsumerStatefulWidget {
  final String templateId;

  const BaseSessionPage({super.key, required this.templateId});
}

abstract class BaseSessionPageState<T extends BaseSessionPage>
    extends ConsumerState<T> {
  GameSession? _initialSession;

  @override
  void initState() {
    super.initState();
    // 页面初始化时根据设置启用屏幕常亮
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleScreenWakelock();
    });
  }

  @override
  void dispose() {
    // 页面销毁时禁用屏幕常亮
    // 使用 WakelockHelper 的安全方法，避免使用可能已失效的 ref
    WakelockHelper.safeDisable();
    super.dispose();
  }

  /// 处理屏幕常亮设置
  void _handleScreenWakelock() {
    try {
      if (mounted) {
        final wakelockNotifier =
            ref.read(screenWakelockSettingProvider.notifier);
        wakelockNotifier.enableWakelock();
      }
    } catch (e) {
      // 在初始化过程中的错误可以使用 ErrorHandler，因为 widget 还未销毁
      ErrorHandler.handle(e, StackTrace.current, prefix: '启用屏幕常亮失败');
    }
  }

  /// 确保屏幕常亮状态正确（在 build 方法中调用）
  /// 根据 wakelock_plus 文档建议，应该持续调用以防止 OS 释放 wakelock
  void _ensureScreenWakelockState() {
    try {
      if (mounted) {
        final wakelockState = ref.read(screenWakelockSettingProvider);
        // 使用 WakelockHelper 的 toggle 方法，它是幂等的
        WakelockHelper.toggle(enable: wakelockState.isEnabled);
      }
    } catch (e) {
      // 在 build 过程中的错误只记录，不影响 UI 构建
      Log.w('确保屏幕常亮状态失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 根据 wakelock_plus 文档建议，在 build 方法中持续调用 enable
    // 因为 OS 可能随时释放 wakelock，需要持续检查和启用
    _ensureScreenWakelockState();

    ref.listen(scoreProvider, (previous, next) {
      if (next.value?.showGameEndDialog == true) {
        showGameResult(context);
      }
    });

    ref.watch(lanProvider);

    final scoreAsync = ref.watch(scoreProvider);

    return scoreAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text('加载中...')),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: Text('错误')),
        body: Center(child: Text('加载分数失败: $error')),
      ),
      data: (scoreState) {
        final session = scoreState.currentSession;
        // 模板现在直接从 ScoreState 获取，这是唯一的数据源
        final template = scoreState.template;

        if (session == null || template == null) {
          return Scaffold(
            appBar: AppBar(title: Text('错误')),
            body: Center(child: Text('模板加载失败')),
          );
        }

        // 在第一次构建时，创建会话数据的快照
        _initialSession ??= session.copyWith(
          scores: session.scores
              .map((s) => s.copyWith(
                    roundScores: List.from(s.roundScores),
                    roundExtendedFields: Map.from(s.roundExtendedFields),
                  ))
              .toList(),
        );

        // 客户端模式和主机模式退出提示
        return PopScope(
            canPop: false,
            onPopInvokedWithResult: (bool didPop, Object? result) async {
              if (didPop) return;
              await _handleExitRequest();
            },
            child: Stack(
              children: [
                Scaffold(
                  appBar: AppBar(
                    leading: scoreState.isTempMode
                        ? IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => _handleTempModeExit(context),
                          )
                        : null,
                    automaticallyImplyLeading: !scoreState.isTempMode,
                    title: Row(
                      children: [
                        Expanded(child: Text(template.templateName)),
                        if (scoreState.isTempMode)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  Colors.orange.withAlpha((0.2 * 255).toInt()),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange
                                    .withAlpha((0.5 * 255).toInt()),
                              ),
                            ),
                            child: const Text(
                              '临时',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    actions: [
                      // 显示LAN状态图标：主机模式、已连接的客户端、或处于客户端模式（包括重连状态）
                      LanStatusButton(),
                      IconButton(
                        icon: Icon(Icons.sports_score),
                        tooltip: '当前计分情况',
                        onPressed: () => showGameResult(context),
                      ),
                      IconButton(
                        icon: Icon(Icons.stacked_line_chart),
                        tooltip: '查看计分图表',
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (BuildContext modalContext) {
                              return ScoreChartBottomSheet(session: session);
                            },
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.apps),
                        tooltip: '更多操作',
                        onPressed: () =>
                            _showMoreActionsGrid(context, template),
                      ),
                    ],
                  ),
                  body: buildGameBody(context, template, session),
                ),
                // 在联机状态下显示ping值
                const PingWidget(),
              ],
            ));
      },
    );
  }

  void _toggleLanConnection(BuildContext context, BaseTemplate template) {
    final lanNotifier = ref.read(lanProvider.notifier);
    final lanState = ref.read(lanProvider);

    // 检查客户端模式限制
    if (lanState.isClientMode) {
      ref.showMessage('客户端模式下无法开启局域网联机');
      return;
    }

    if (lanState.isHost) {
      lanNotifier.disposeManager();
      ref.showSuccess('已停止主机');
    } else if (lanState.isConnected) {
      // 修复：客户端断开连接时返回到带有底部导航栏的主界面
      lanNotifier.disposeManager();
      ref.showSuccess('已断开连接');
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/main',
        (route) => false,
      );
    } else {
      lanNotifier
          .startHost(8080, template.tid, templateName: template.templateName)
          .then((_) {
        // 检查启动是否真正成功（通过检查状态）
        final currentLanState = ref.read(lanProvider);
        if (currentLanState.isHost &&
            !currentLanState.connectionStatus.contains('被占用') &&
            !currentLanState.connectionStatus.contains('启动失败')) {
          ref.showSuccess('主机已启动，等待客户端连接');
        }
        // 如果启动失败，错误消息已经在 lan_provider.dart 中显示了，这里不需要重复显示
      }).catchError((error) {
        // 这里的错误通常是网络层面的异常，lan_provider.dart 中的错误处理可能没有覆盖到
        ref.showError('启动主机失败: $error');
      });
    }
  }

  Widget buildGameBody(
      BuildContext context, BaseTemplate template, GameSession session);

  String _getPlayerName(String playerId) {
    final scoreState = ref.read(scoreProvider).value;
    // 优先从 scoreState 中的 template 获取玩家信息，因为这可能是为比赛定制的临时模板
    final player = scoreState?.template?.players
        .firstWhereOrNull((p) => p.pid == playerId);
    return player?.name ?? '未知玩家';
  }

  void showGameResult(BuildContext context) {
    if (ModalRoute.of(context)?.isCurrent != true) {
      return;
    }

    final scoreState = ref.read(scoreProvider).value;
    final template = scoreState?.template;

    if (template == null) {
      globalState.showCommonDialog(
        child: AlertDialog(
          title: Text('数据错误'),
          content: Text('未能获取模板配置，请检查模板设置'),
          actions: [
            TextButton(
                onPressed: () => globalState.navigatorKey.currentState?.pop(),
                child: Text('确定'))
          ],
        ),
      );
      return;
    }

    final result =
        ref.read(scoreProvider.notifier).calculateGameResult(template);

    final reverseWinRule = template.reverseWinRule;

    globalState.showCommonDialog(
        child: PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        ref.read(scoreProvider.notifier).resetGameEndDialog();
      },
      child: AlertDialog(
        title: Text(result.havTargetScore ? '计分结束' : '当前计分情况'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (result.losers.isNotEmpty) ...[
                Text(
                    result.havTargetScore
                        ? '💔 失败'
                        : (reverseWinRule ? '⚠️ 最少计分' : '⚠️ 最多计分'),
                    style: TextStyle(
                        color: result.havTargetScore
                            ? Colors.red
                            : Colors.orange)),
                ...result.losers.map((s) =>
                    Text('${_getPlayerName(s.playerId)}（${s.totalScore}分）')),
                SizedBox(height: 16),
              ],
              Text(
                  result.havTargetScore
                      ? '🏆 胜利'
                      : (reverseWinRule ? '🎉 最多计分' : '🎉 最少计分'),
                  style: TextStyle(color: Colors.green)),
              ...result.winners.map((s) =>
                  Text('${_getPlayerName(s.playerId)}（${s.totalScore}分）')),
              if (result.havTargetScore) ...[
                SizedBox(height: 16),
                Text('💡 计分结束，但仍可继续计分，每回合结束将再次检查计分',
                    style: TextStyle(
                      color: Colors.blue,
                    )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('确定'),
          ),
          // 修复：始终显示“确认胜负”按钮，除非是临时模式
          if (scoreState?.isTempMode == false)
            TextButton(
              onPressed: () {
                // 如果已经分出胜负，则直接确认
                if (result.havTargetScore) {
                  _confirmAndExit(context, scoreState);
                } else {
                  // 否则，弹窗二次确认
                  globalState.showCommonDialog(
                    child: AlertDialog(
                      title: const Text('提前结束'),
                      content:
                          const Text('提前结束将按当前分数结算胜负，若改变了胜负情况，后续比赛也会更新，确定吗？'),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              globalState.navigatorKey.currentState?.pop(),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () {
                            // 关闭二次确认对话框
                            globalState.navigatorKey.currentState?.pop();
                            // 执行确认并退出
                            _confirmAndExit(context, scoreState);
                          },
                          child: const Text('确定'),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: Text(result.havTargetScore ? '确认胜负' : '提前结束'),
            ),
        ],
      ),
    ));
  }

  /// 封装确认比赛结果并退出的逻辑
  void _confirmAndExit(BuildContext context, ScoreState? scoreState) async {
    // UI层前置校验：检查淘汰赛平局
    final league = ref
        .read(leagueNotifierProvider)
        .value
        ?.leagues
        .firstWhereOrNull((l) => l.matches
            .any((m) => m.mid == scoreState?.currentSession?.leagueMatchId));
    if (league != null && league.type == LeagueType.knockout) {
      final scores = scoreState?.currentSession?.scores;
      if (scores != null && scores.length == 2) {
        if (scores[0].totalScore == scores[1].totalScore) {
          ref.showWarning('淘汰赛不允许平局，请决出胜负！');
          return; // 中断执行
        }
      }
    }

    // 在 await 之前获取 Navigator
    final navigator = Navigator.of(context);
    // 先关闭计分结果对话框
    navigator.pop();

    // 根据是否为联赛，调用不同的确认方法
    if (scoreState?.currentSession?.leagueMatchId != null) {
      final message =
          await ref.read(scoreProvider.notifier).confirmLeagueMatchResult();

      if (!mounted) return;

      if (message != null && message.isNotEmpty) {
        // 如果有消息返回，说明有后续比赛被修改，弹窗提示用户
        GlobalMsgManager.showMessage(message);
      }
      // 无论是否有消息，都重置状态并退出
      ref.read(scoreProvider.notifier).resetScoreState();
      // 延迟pop以避免渲染错误
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) navigator.pop();
      });
    } else {
      // 普通比赛的逻辑保持不变
      await ref.read(scoreProvider.notifier).confirmGameResult();
      // 退出计分页面
      // 延迟pop以避免渲染错误
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) navigator.pop();
      });
    }
  }

  void showResetConfirmation(BuildContext context) {
    globalState.showCommonDialog(
      child: AlertDialog(
        title: Text('重置计分'),
        content: Text('确定要重置当前计分吗？\n' '当前进度将会自动保存并标记为已完成，并启动一个新的计分。'),
        actions: [
          TextButton(
            onPressed: () => globalState.navigatorKey.currentState?.pop(),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              globalState.navigatorKey.currentState?.pop();
              final template = ref.read(scoreProvider).value?.template;
              await ref.read(scoreProvider.notifier).resetGame(true);
              if (template != null) {
                ref.read(scoreProvider.notifier).startNewGame(template);
              } else {
                ref.showWarning('模板加载失败，请重试');
              }
            },
            child: Text('重置'),
          ),
        ],
      ),
    );
  }

  String getPlayerName(String playerId) {
    final scoreState = ref.read(scoreProvider).value;
    final player = scoreState?.template?.players
        .firstWhereOrNull((p) => p.pid == playerId);
    return player?.name ?? '未知玩家';
  }

  /// 显示通用的分数编辑弹窗
  ///
  /// [player] 玩家信息
  /// [initialValue] 初始分数值
  /// [onConfirm] 确认回调，返回新的分数值
  /// [title] 弹窗标题，默认为"修改分数"
  /// [subtitle] 副标题，默认为玩家名称
  /// [inputLabel] 输入框标签，默认为"输入新分数"
  /// [supportDecimal] 是否支持小数输入，默认为false
  /// [decimalMultiplier] 小数转换倍数，默认为100（用于将小数转为整数存储）
  /// [allowNegative] 是否允许负数，如果为null则从模板配置中获取
  void showScoreEditDialog({
    required PlayerInfo player,
    required int initialValue,
    required ValueChanged<int> onConfirm,
    String? title,
    String? subtitle,
    String? inputLabel,
    int? round,
    bool supportDecimal = false,
    int decimalMultiplier = 100,
    bool? allowNegative,
  }) {
    globalState.showCommonDialog(
      child: BaseScoreEditDialog(
        templateId: widget.templateId,
        player: player,
        initialValue: initialValue,
        onConfirm: onConfirm,
        title: title,
        subtitle: subtitle,
        inputLabel: inputLabel,
        round: round,
        supportDecimal: supportDecimal,
        decimalMultiplier: decimalMultiplier,
        allowNegative: allowNegative,
      ),
    );
  }

  /// 显示轮次分数编辑弹窗（适用于麻将、Poker50等基于轮次的计分）
  ///
  /// [player] 玩家信息
  /// [roundIndex] 轮次索引（从0开始）
  /// [scores] 玩家的分数列表
  /// [supportDecimal] 是否支持小数输入
  /// [decimalMultiplier] 小数转换倍数，默认为100
  void showRoundScoreEditDialog({
    required PlayerInfo player,
    required int roundIndex,
    required List<int?> scores,
    bool supportDecimal = false,
    int decimalMultiplier = 100,
  }) {
    final scoreNotifier = ref.read(scoreProvider.notifier);
    final scoreState = ref.read(scoreProvider);

    final currentRound = scoreState.value?.currentRound ?? 0;
    final currentSession = scoreState.value?.currentSession;

    if (roundIndex < 0 || roundIndex > scores.length) return;

    // 检查是否需要添加新轮次
    if (roundIndex == scores.length) {
      final canAddNewRound = currentRound == 0 ||
          currentSession!.scores.every((s) {
            final lastRoundIndex = currentRound - 1;
            return s.roundScores.length > lastRoundIndex &&
                s.roundScores[lastRoundIndex] != null;
          });

      if (canAddNewRound) {
        scoreNotifier.addNewRound();
      } else if (roundIndex >= currentRound) {
        GlobalMsgManager.showMessage('请填写所有玩家的【第$currentRound轮】后再添加新回合！');
        return;
      }
    }

    final currentScore = roundIndex < scores.length ? scores[roundIndex] : null;

    showScoreEditDialog(
      player: player,
      initialValue: currentScore ?? 0,
      round: roundIndex + 1,
      supportDecimal: supportDecimal,
      decimalMultiplier: decimalMultiplier,
      onConfirm: (newValue) {
        scoreNotifier.updateScore(
          player.pid,
          roundIndex,
          newValue,
        );
        ref.read(scoreProvider.notifier).updateHighlight();
      },
    );
  }

  /// 处理临时模式退出
  void _handleTempModeExit(BuildContext context) {
    globalState.showCommonDialog(
      child: AlertDialog(
        title: const Text('退出临时计分'),
        content: const Text('退出后，当前的计分数据将会丢失，确定要退出吗？'),
        actions: [
          TextButton(
            onPressed: () => globalState.navigatorKey.currentState?.pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              globalState.navigatorKey.currentState?.pop();

              // 检查并断开联机连接
              await _handleNetworkDisconnection();

              // 重置计分状态（不保存历史）
              ref.read(scoreProvider.notifier).resetGame(false);

              // 返回到上一个页面（保持底部导航）
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确定退出'),
          ),
        ],
      ),
    );
  }

  /// 处理网络连接断开
  Future<void> _handleNetworkDisconnection() async {
    try {
      final lanState = ref.read(lanProvider);

      if (lanState.isHost) {
        Log.i('临时计分退出：检测到主机模式，正在断开联机连接');
        // 主机模式：停止服务并断开所有客户端
        await ref.read(lanProvider.notifier).disposeManager();
        Log.i('临时计分退出：主机连接已断开');
      } else if (lanState.isConnected) {
        Log.i('临时计分退出：检测到客户端模式，正在断开联机连接');
        // 客户端模式：断开与主机的连接
        await ref.read(lanProvider.notifier).disposeManager();
        Log.i('临时计分退出：客户端连接已断开');
      } else {
        Log.i('临时计分退出：当前未处于联机状态，无需断开连接');
      }
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '临时计分退出时断开网络连接失败');
    }
  }

  /// 处理退出请求的主入口
  Future<void> _handleExitRequest() async {
    try {
      final scoreState = ref.read(scoreProvider).value;
      final session = scoreState?.currentSession;

      // 检查是否为已完成的联赛对局且有修改
      if (session != null &&
          _initialSession != null &&
          session.isCompleted &&
          session.leagueMatchId != null) {
        final hasChanges = !const DeepCollectionEquality()
            .equals(session.scores, _initialSession!.scores);
        if (hasChanges) {
          await _handleCompletedLeagueExit();
          return;
        }
      }

      // 临时计分模式优先级最高，优先处理
      if (scoreState?.isTempMode == true) {
        _handleTempModeExit(context);
        return;
      }

      final lanState = ref.read(lanProvider);

      if (_isClientMode(lanState)) {
        await _handleClientModeExit(lanState);
      } else if (_isHostMode(lanState)) {
        await _handleHostModeExit(lanState);
      } else {
        await _handleStandaloneModeExit();
      }
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '退出计分失败');
    }
  }

  /// 处理已完成联赛的退出逻辑
  Future<void> _handleCompletedLeagueExit() async {
    final result = await globalState.showCommonDialog<String>(
      child: AlertDialog(
        title: const Text('保留修改'),
        content: const Text('你对已结束的比赛计分进行了修改，要保留这些修改吗？\n\n'
            '注意：保存后可能会影响并重新生成后续的比赛。'),
        actions: [
          TextButton(
            onPressed: () =>
                globalState.navigatorKey.currentState?.pop('cancel'),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () =>
                globalState.navigatorKey.currentState?.pop('discard'),
            child: const Text('放弃修改'),
          ),
          TextButton(
            onPressed: () => globalState.navigatorKey.currentState?.pop('save'),
            child: const Text('保存并退出'),
          ),
        ],
      ),
    );

    if (result == 'save') {
      // UI层前置校验：检查淘汰赛平局
      final scoreState = ref.read(scoreProvider).value;
      final league = ref
          .read(leagueNotifierProvider)
          .value
          ?.leagues
          .firstWhereOrNull((l) => l.matches
              .any((m) => m.mid == scoreState?.currentSession?.leagueMatchId));
      if (league != null && league.type == LeagueType.knockout) {
        final scores = scoreState?.currentSession?.scores;
        if (scores != null && scores.length == 2) {
          if (scores[0].totalScore == scores[1].totalScore) {
            ref.showWarning('淘汰赛不允许平局，请决出胜负！');
            return; // 中断执行
          }
        }
      }

      // 在 await 之前获取 Navigator
      final navigator = Navigator.of(context);
      final message = await ref
          .read(scoreProvider.notifier)
          .updateCompletedLeagueMatchResult(_initialSession!);

      if (!mounted) return;

      if (message != null && message.isNotEmpty) {
        // 如果有消息返回，说明有后续比赛被修改，弹窗提示用户
        await globalState.showCommonDialog(
          dismissible: false,
          child: AlertDialog(
            title: const Text('后续比赛已更新'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  globalState.navigatorKey.currentState?.pop();
                  // 关闭计分页面
                  // 延迟pop以避免渲染错误
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) navigator.pop();
                  });
                },
                child: const Text('好的'),
              ),
            ],
          ),
        );
      } else {
        // 如果没有影响，直接退出
        // 延迟pop以避免渲染错误
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) navigator.pop();
        });
      }
    } else if (result == 'discard') {
      // 恢复到初始状态
      ref.read(scoreProvider.notifier).loadSession(_initialSession!);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
    // if result is 'cancel' or null, do nothing
  }

  /// 检查是否为客户端模式
  bool _isClientMode(dynamic lanState) {
    return lanState.isClientMode && !lanState.isHost;
  }

  /// 检查是否为主机模式
  bool _isHostMode(dynamic lanState) {
    return lanState.isHost;
  }

  /// 处理客户端模式退出
  Future<void> _handleClientModeExit(dynamic lanState) async {
    final exitInfo = _getClientModeExitInfo(lanState);

    final confirmed = await _showExitConfirmDialog(
      title: '确认退出',
      content: exitInfo.content,
      actionText: exitInfo.actionText,
      isDestructive: true,
    );

    if (confirmed == true) {
      await _executeClientModeExit();
    }
  }

  /// 获取客户端模式退出信息
  ({String content, String actionText}) _getClientModeExitInfo(
      dynamic lanState) {
    if (lanState.isConnected) {
      return (content: '退出当前页面将会断开与主机的连接，确定要退出吗？', actionText: '断开并退出');
    } else if (lanState.isReconnecting) {
      return (
        content: '当前正在重连中，退出将停止重连并退出客户端模式，确定要退出吗？',
        actionText: '停止重连并退出'
      );
    } else {
      return (content: '退出当前页面将退出客户端模式，确定要退出吗？', actionText: '退出客户端模式');
    }
  }

  /// 执行客户端模式退出
  Future<void> _executeClientModeExit() async {
    try {
      // 使用exitClientMode来完全退出客户端模式
      await ref.read(lanProvider.notifier).exitClientMode();
      ref.invalidate(scoreProvider);

      if (mounted && context.mounted) {
        // 修复：客户端断开连接时返回到带有底部导航栏的主界面
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/main',
          (route) => false,
        );
      }
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '客户端模式退出失败');
    }
  }

  /// 处理主机模式退出
  Future<void> _handleHostModeExit(dynamic lanState) async {
    final exitInfo = _getHostModeExitInfo(lanState);

    final confirmed = await _showExitConfirmDialog(
      title: '确认离开',
      content: exitInfo.content,
      actionText: exitInfo.actionText,
      isDestructive: true,
    );

    if (confirmed == true) {
      await _executeHostModeExit();
    }
  }

  /// 获取主机模式退出信息
  ({String content, String actionText}) _getHostModeExitInfo(dynamic lanState) {
    if (lanState.connectedClientIps.isNotEmpty) {
      return (
        content:
            '离开此页面将停止主机服务，所有连接的客户端（${lanState.connectedClientIps.length}个）将断开连接，确定要离开吗？',
        actionText: '确认离开'
      );
    } else {
      return (content: '离开此页面将停止主机服务，确定要离开吗？', actionText: '确认离开');
    }
  }

  /// 执行主机模式退出
  Future<void> _executeHostModeExit() async {
    try {
      // 停止主机服务
      await ref.read(lanProvider.notifier).disposeManager();
      ref.showSuccess('已停止主机服务');

      if (mounted) {
        globalState.navigatorKey.currentState?.pop();
      }
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '主机模式退出失败');
    }
  }

  /// 处理单机模式退出
  Future<void> _handleStandaloneModeExit() async {
    final confirmed = await _showExitConfirmDialog(
      title: '确认退出',
      content: '确定要退出当前计分吗？',
      actionText: '确认退出',
      isDestructive: false,
    );

    if (confirmed == true) {
      await _executeStandaloneModeExit();
    }
  }

  /// 执行单机模式退出
  Future<void> _executeStandaloneModeExit() async {
    try {
      if (mounted) {
        globalState.navigatorKey.currentState?.pop();
      }
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '单机模式退出失败');
    }
  }

  /// 显示通用的退出确认对话框
  Future<bool?> _showExitConfirmDialog({
    required String title,
    required String content,
    required String actionText,
    required bool isDestructive,
  }) async {
    return await globalState.showCommonDialog(
      child: AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => globalState.navigatorKey.currentState?.pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => globalState.navigatorKey.currentState?.pop(true),
            style: isDestructive
                ? TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  )
                : null,
            child: Text(actionText),
          ),
        ],
      ),
    );
  }

  /// 切换屏幕常亮设置
  void _toggleScreenWakelock() async {
    try {
      final wakelockNotifier = ref.read(screenWakelockSettingProvider.notifier);
      final currentState = ref.read(screenWakelockSettingProvider);
      final newValue = !currentState.isEnabled;

      // 立即更新UI状态，提供即时反馈
      await wakelockNotifier.setEnabled(newValue);

      // 根据新状态启用或禁用屏幕常亮
      if (newValue) {
        await wakelockNotifier.enableWakelock();
        ref.showSuccess('屏幕常亮已启用');
      } else {
        await wakelockNotifier.disableWakelock();
        ref.showSuccess('屏幕常亮已关闭');
      }
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '切换屏幕常亮设置失败');
      ref.showError('设置屏幕常亮失败');
    }
  }

  void _showMoreActionsGrid(BuildContext context, BaseTemplate template) {
    final scoreState = ref.read(scoreProvider).value;
    if (scoreState == null) return;

    final lanState = ref.read(lanProvider);
    final wakelockState = ref.read(screenWakelockSettingProvider);

    void handleSelection(String value) {
      Navigator.of(context).pop(); // Close the bottom sheet first
      switch (value) {
        case 'Template_set':
          Widget configPage;
          if (template is LandlordsTemplate) {
            configPage =
                LandlordsConfigPage(oriTemplate: template, isReadOnly: true);
          } else if (template is Poker50Template) {
            configPage =
                Poker50ConfigPage(oriTemplate: template, isReadOnly: true);
          } else if (template is MahjongTemplate) {
            configPage =
                MahjongConfigPage(oriTemplate: template, isReadOnly: true);
          } else if (template is CounterTemplate) {
            configPage =
                CounterConfigPage(oriTemplate: template, isReadOnly: true);
          } else {
            ref.showWarning('该模板类型暂不支持查看设置: ${template.runtimeType}');
            return;
          }
          Navigator.of(context).pushWithSlide(
            configPage,
            direction: SlideDirection.fromRight,
            duration: const Duration(milliseconds: 300),
          );
          break;
        case 'reset_game':
          if (scoreState.isTempMode) {
            ref.showWarning('临时计分模式下不可重置计分');
            break;
          }
          showResetConfirmation(context);
          break;
        case 'lan_conn':
          _toggleLanConnection(context, template);
          break;
        case 'lan_discovery':
          Navigator.of(context).pushWithSlide(
            const LanDiscoveryPage(),
            direction: SlideDirection.fromRight,
            duration: const Duration(milliseconds: 300),
          );
          break;
        case 'lan_test':
          Navigator.of(context).pushWithSlide(
            const LogTestPage(),
            direction: SlideDirection.fromRight,
            duration: const Duration(milliseconds: 300),
          );
          break;
        case 'screen_wakelock':
          _toggleScreenWakelock();
          break;
        case 'dice_roller':
          globalState.showCommonDialog(child: const DiceRollerDialog());
          break;
        default:
          Log.warn('未知选项: $value');
          break;
      }
    }

    Widget buildGridItem({
      required String value,
      required IconData icon,
      required String label,
      bool enabled = true,
    }) {
      final color = enabled
          ? Theme.of(context).textTheme.bodyLarge?.color
          : Theme.of(context).disabledColor;
      return InkWell(
        onTap: enabled ? () => handleSelection(value) : null,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 90,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 30),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext modalContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    buildGridItem(
                      value: 'lan_test',
                      icon: Icons.article_outlined,
                      label: '程序日志',
                    ),
                    buildGridItem(
                      value: 'lan_conn',
                      icon: lanState.isHost ? Icons.wifi_off : Icons.wifi,
                      label: lanState.isHost ? '停止主机' : '开启局域网联机',
                      enabled: !lanState.isConnected && !lanState.isClientMode,
                    ),
                    buildGridItem(
                      value: 'lan_discovery',
                      icon: Icons.search,
                      label: '发现局域网计分',
                      enabled: !lanState.isHost && !lanState.isClientMode,
                    ),
                    buildGridItem(
                      value: 'reset_game',
                      icon: Icons.restart_alt_rounded,
                      label: '重置计分',
                      enabled: !scoreState.isTempMode,
                    ),
                    buildGridItem(
                      value: 'Template_set',
                      icon: Icons.info_outline,
                      label: '查看模板设置',
                    ),
                    buildGridItem(
                      value: 'screen_wakelock',
                      icon: wakelockState.isEnabled
                          ? Icons.flashlight_on_outlined
                          : Icons.flashlight_off_outlined,
                      label: '切换屏幕常亮',
                    ),
                  ],
                ),
                const Divider(height: 32),
                Text(
                  '计分工具',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    buildGridItem(
                      value: 'dice_roller',
                      icon: Icons.casino_outlined,
                      label: '掷骰子',
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
