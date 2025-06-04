import 'package:counters/app/state.dart';
import 'package:counters/common/model/base_template.dart';
import 'package:counters/common/model/counter.dart';
import 'package:counters/common/model/game_session.dart';
import 'package:counters/common/model/landlords.dart';
import 'package:counters/common/model/mahjong.dart';
import 'package:counters/common/model/player_info.dart';
import 'package:counters/common/model/poker50.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/common/widgets/snackbar.dart';
import 'package:counters/features/lan/lan_discovery_page.dart';
import 'package:counters/features/lan/lan_provider.dart';
import 'package:counters/features/lan/lan_test_page.dart';
import 'package:counters/features/score/counter/config.dart';
import 'package:counters/features/score/landlords/config.dart';
import 'package:counters/features/score/mahjong/config.dart';
import 'package:counters/features/score/poker50/config.dart';
import 'package:counters/features/score/score_provider.dart';
import 'package:counters/features/score/widgets/base_score_edit_dialog.dart';
import 'package:counters/features/score/widgets/score_chart_bottom_sheet.dart';
import 'package:counters/features/template/template_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


abstract class BaseSessionPage extends ConsumerStatefulWidget {
  final String templateId;

  const BaseSessionPage({super.key, required this.templateId});
}

abstract class BaseSessionPageState<T extends BaseSessionPage>
    extends ConsumerState<T> with SingleTickerProviderStateMixin {
  late AnimationController _broadcastAnimationController;
  late Animation<double> _broadcastScaleAnimation;

  @override
  void initState() {
    super.initState();
    _broadcastAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _broadcastScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(_broadcastAnimationController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final initialLanState = ref.read(lanProvider);
      if (initialLanState.isHost && initialLanState.isBroadcasting) {
        _broadcastAnimationController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _broadcastAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final template =
        ref.watch(templatesProvider.notifier).getTemplate(widget.templateId);

    ref.listen(scoreProvider, (previous, next) {
      if (next.value?.showGameEndDialog == true) {
        showGameResult(context);
      }
    });

    ref.listen<LanState>(lanProvider, (previous, next) {
      final wasBroadcasting =
          previous?.isHost == true && previous?.isBroadcasting == true;
      final isBroadcasting = next.isHost && next.isBroadcasting;

      if (!mounted) return;

      if (isBroadcasting && !wasBroadcasting) {
        _broadcastAnimationController.repeat(reverse: true);
      } else if (!isBroadcasting && wasBroadcasting) {
        _broadcastAnimationController.stop();
        _broadcastAnimationController.value = 0.0;
      }
    });

    final lanState = ref.watch(lanProvider);

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

        if (session == null || template == null) {
          return Scaffold(
            appBar: AppBar(title: Text('错误')),
            body: Center(child: Text('模板加载失败')),
          );
        }

        // 客户端模式退出提示
        return PopScope(
            canPop: false,
            onPopInvokedWithResult: (bool didPop, Object? result) async {
              if (didPop) {
                return;
              }
              final lanState = ref.read(lanProvider);
              if (lanState.isConnected && !lanState.isHost) {
                final confirmed = await globalState.showCommonDialog(
                  child: AlertDialog(
                    title: Text('确认退出'),
                    content: Text('退出当前页面将会断开与主机的连接，确定要退出吗？'),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            globalState.navigatorKey.currentState?.pop(false),
                        child: Text('取消'),
                      ),
                      TextButton(
                        onPressed: () {
                          globalState.navigatorKey.currentState?.pop(true);
                        },
                        child: Text('确定'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  ref.read(lanProvider.notifier).disposeManager();
                  ref.invalidate(scoreProvider);
                  AppSnackBar.show('已断开连接');
                  if (mounted) {
                    globalState.navigatorKey.currentState?.pop();
                  }
                }
              } else {
                if (mounted) {
                  globalState.navigatorKey.currentState?.pop();
                }
              }
            },
            child: Scaffold(
              appBar: AppBar(
                title: Text(template.templateName),
                actions: [
                  if (lanState.isHost || lanState.isConnected)
                    IconButton(
                      icon: ScaleTransition(
                        scale: _broadcastScaleAnimation,
                        child: Icon(
                          lanState.isHost ? Icons.wifi_tethering : Icons.wifi,
                          color: lanState.isConnected
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                      tooltip: lanState.isHost
                          ? '主机模式: ${lanState.connectionStatus}'
                          : '客户端模式: ${lanState.connectionStatus}',
                      onPressed: () => showLanStatus(context),
                    ),
                  IconButton(
                    icon: Icon(Icons.sports_score),
                    tooltip: '当前游戏情况',
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
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert),
                    tooltip: '更多操作',
                    onSelected: (String value) {
                      switch (value) {
                        case 'Template_set':
                          Widget configPage;
                          if (template is LandlordsTemplate) {
                            configPage = LandlordsConfigPage(
                                oriTemplate: template, isReadOnly: true);
                          } else if (template is Poker50Template) {
                            configPage = Poker50ConfigPage(
                                oriTemplate: template, isReadOnly: true);
                          } else if (template is MahjongTemplate) {
                            configPage = MahjongConfigPage(
                                oriTemplate: template, isReadOnly: true);
                          } else if (template is CounterTemplate) {
                            configPage = CounterConfigPage(
                                oriTemplate: template, isReadOnly: true);
                          } else {
                            AppSnackBar.warn(
                                '该模板类型暂不支持查看设置: ${template.runtimeType}');
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => configPage),
                          );
                          break;
                        case 'reset_game':
                          showResetConfirmation(context);
                          break;
                        case 'lan_debug':
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LanTestPage()));
                          break;
                        case 'lan_conn':
                          _toggleLanConnection(context, template);
                          break;
                        case 'lan_discovery':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LanDiscoveryPage()),
                          );
                          break;
                        case 'lan_test':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LanTestPage()),
                          );
                          break;
                        default:
                          Log.warn('未知选项: $value');
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'lan_test',
                        child: Row(
                          children: [
                            Icon(Icons.network_check),
                            SizedBox(width: 8),
                            Text('局域网联机测试'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'lan_conn',
                        enabled: !lanState.isConnected,
                        child: Row(
                          children: [
                            Icon(Icons.wifi),
                            SizedBox(width: 8),
                            Text(lanState.isHost ? '停止主机' : '开启局域网联机'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'lan_discovery',
                        enabled: !lanState.isHost,
                        child: Row(
                          children: [
                            Icon(Icons.search,
                                color: !lanState.isHost ? null : Colors.grey),
                            SizedBox(width: 8),
                            Text('发现局域网游戏',
                                style: TextStyle(
                                    color:
                                        !lanState.isHost ? null : Colors.grey)),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'reset_game',
                        child: Row(
                          children: [
                            Icon(Icons.restart_alt_rounded),
                            SizedBox(width: 8),
                            Text('重置游戏'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'Template_set',
                        child: Row(
                          children: [
                            Icon(Icons.info_outline),
                            SizedBox(width: 8),
                            Text('查看模板设置'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              body: buildGameBody(context, template, session),
            ));
      },
    );
  }

  void _toggleLanConnection(BuildContext context, BaseTemplate template) {
    final lanNotifier = ref.read(lanProvider.notifier);
    final lanState = ref.read(lanProvider);

    if (lanState.isHost) {
      lanNotifier.disposeManager();
      AppSnackBar.show('已停止主机');
    } else if (lanState.isConnected) {
      lanNotifier.disposeManager();
      AppSnackBar.show('已断开连接');
    } else {
      lanNotifier.startHost(8080, template.tid).then((_) {
        AppSnackBar.show('主机已启动，等待客户端连接');
      }).catchError((error) {
        AppSnackBar.error('启动主机失败: $error');
      });
    }
  }

  void showLanStatus(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('局域网状态'),
        content: Consumer(
          builder: (context, ref, child) {
            final currentLanState = ref.watch(lanProvider);
            String currentStatusText = '';
            if (currentLanState.isHost) {
              currentStatusText = '主机模式\n';
              currentStatusText += 'IP地址: ${currentLanState.localIp}\n';
              currentStatusText += '端口: 8080\n';
              currentStatusText += '连接状态: ${currentLanState.connectionStatus}';
            } else if (currentLanState.isConnected) {
              currentStatusText = '客户端模式\n';
              currentStatusText += 'IP地址: ${currentLanState.localIp}\n';
              currentStatusText +=
                  '已连接到主机地址: ${currentLanState.connectionStatus}';
            } else {
              currentStatusText = '未连接';
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(currentStatusText),
                SizedBox(height: 16),
                if (currentLanState.isHost) ...[
                  Text('已连接客户端:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  if (currentLanState.connectedClientIps.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text('  无', style: TextStyle(color: Colors.grey)),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0, left: 8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: currentLanState.connectedClientIps
                            .map((ip) => Text('  - $ip'))
                            .toList(),
                      ),
                    ),
                  SizedBox(height: 16),
                ],
                if (currentLanState.isHost)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('广播状态：'),
                      Switch(
                        value: currentLanState.isBroadcasting,
                        onChanged: (value) {
                          ref
                              .read(lanProvider.notifier)
                              .setBroadcastState(value);
                          AppSnackBar.show(value ? '广播已开启' : '广播已关闭');
                        },
                      ),
                    ],
                  ),
                SizedBox(height: 16),
                if (currentLanState.isHost || currentLanState.isConnected)
                  ElevatedButton(
                    onPressed: () {
                      globalState.navigatorKey.currentState?.pop();
                      ref.read(lanProvider.notifier).disposeManager();
                      AppSnackBar.show(
                          currentLanState.isHost ? '已停止主机' : '已断开连接');
                    },
                    child: Text(currentLanState.isHost ? '停止主机' : '断开连接'),
                  ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => globalState.navigatorKey.currentState?.pop(),
            child: Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget buildGameBody(
      BuildContext context, BaseTemplate template, GameSession session);

  String _getPlayerName(String playerId, BuildContext context) {
    return ref
            .read(templatesProvider.notifier)
            .getTemplate(widget.templateId)
            ?.players
            .firstWhere((p) => p.pid == playerId,
                orElse: () => PlayerInfo(name: '未知玩家', avatar: 'default'))
            .name ??
        '未知玩家';
  }

  void showGameResult(BuildContext context) {
    if (ModalRoute.of(context)?.isCurrent != true) {
      return;
    }

    final targetScore = ref
        .read(templatesProvider.notifier)
        .getTemplate(widget.templateId)
        ?.targetScore;

    if (targetScore == null) {
      globalState.showCommonDialog(
        child: AlertDialog(
          title: Text('数据错误'),
          content: Text('未能获取目标分数配置，请检查模板设置'),
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
        ref.read(scoreProvider.notifier).calculateGameResult(targetScore);

    globalState.showCommonDialog(
        child: PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        ref.read(scoreProvider.notifier).resetGameEndDialog();
      },
      child: AlertDialog(
        title: Text(result.hasFailures ? '游戏结束' : '当前游戏情况'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (result.losers.isNotEmpty) ...[
                Text('${result.hasFailures ? '😓 失败' : '⚠️ 最多计分'}：',
                    style: TextStyle(
                        color:
                            result.hasFailures ? Colors.red : Colors.orange)),
                ...result.losers.map((s) => Text(
                    '${_getPlayerName(s.playerId, context)}（${s.totalScore}分）')),
                SizedBox(height: 16),
              ],
              Text('${result.hasFailures ? '🏆 胜利' : '🎉 最少计分'}：',
                  style: TextStyle(color: Colors.green)),
              ...result.winners.map((s) => Text(
                  '${_getPlayerName(s.playerId, context)}（${s.totalScore}分）')),
              if (result.hasFailures) ...[
                SizedBox(height: 16),
                Text('💡 游戏结束，但仍可继续计分，每回合结束将再次检查计分',
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
            child: Text('确定'),
          ),
        ],
      ),
    ));
  }

  void showResetConfirmation(BuildContext context) {
    globalState.showCommonDialog(
      child: AlertDialog(
        title: Text('重置游戏'),
        content: Text('确定要重置当前游戏吗？\n'
            '当前进度将会自动保存并标记为已完成，并启动一个新的计分。'),
        actions: [
          TextButton(
            onPressed: () => globalState.navigatorKey.currentState?.pop(),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              globalState.navigatorKey.currentState?.pop();
              final template = ref
                  .read(templatesProvider.notifier)
                  .getTemplate(widget.templateId);
              await ref.read(scoreProvider.notifier).resetGame(true);
              if (template != null) {
                ref.read(scoreProvider.notifier).startNewGame(template);
              } else {
                AppSnackBar.warn('模板加载失败，请重试');
              }
            },
            child: Text('重置'),
          ),
        ],
      ),
    );
  }

  String getPlayerName(String playerId, BuildContext context) {
    return ref
            .read(templatesProvider.notifier)
            .getTemplate(widget.templateId)
            ?.players
            .firstWhere((p) => p.pid == playerId,
                orElse: () => PlayerInfo(name: '未知玩家', avatar: 'default'))
            .name ??
        '未知玩家';
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

  /// 显示轮次分数编辑弹窗（适用于麻将、Poker50等基于轮次的游戏）
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
      } else {
        AppSnackBar.show('请填写所有玩家的【第$currentRound轮】后再添加新回合！');
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

  /// 显示总分编辑弹窗（适用于Counter等累计分数的游戏）
  ///
  /// [player] 玩家信息
  /// [currentScore] 当前总分
  /// [title] 弹窗标题，默认为"修改总分数"
  /// [inputLabel] 输入框标签，默认为"输入总分数"
  void showTotalScoreEditDialog({
    required PlayerInfo player,
    required int currentScore,
    String? title,
    String? inputLabel,
  }) {
    final scoreNotifier = ref.read(scoreProvider.notifier);

    showScoreEditDialog(
      player: player,
      initialValue: currentScore,
      title: title ?? '修改总分数',
      inputLabel: inputLabel ?? '输入总分数',
      supportDecimal: false,
      onConfirm: (newValue) {
        // 更新玩家的总分数
        // 注意：这里需要根据 ScoreProvider 的实际API来调用
        // 临时方案：模拟更新第一个回合的分数，以影响总分
        scoreNotifier.updateScore(player.pid, 0, newValue);
        ref.read(scoreProvider.notifier).updateHighlight();
      },
    );
  }
}
