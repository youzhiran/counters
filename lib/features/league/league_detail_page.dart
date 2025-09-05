import 'package:collection/collection.dart';
import 'package:counters/app/state.dart';
import 'package:counters/common/model/base_template.dart';
import 'package:counters/common/model/league.dart';
import 'package:counters/common/model/league_enums.dart';
import 'package:counters/common/model/match.dart';
import 'package:counters/common/model/player_info.dart';
import 'package:counters/common/providers/league_provider.dart';
import 'package:counters/common/utils/league_helper.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/common/widgets/message_overlay.dart';
import 'package:counters/common/widgets/outline_card.dart';
import 'package:counters/common/widgets/responsive_grid_view.dart';
import 'package:counters/features/league/widgets/tournament_bracket_view.dart';
import 'package:counters/features/player/player_provider.dart';
import 'package:counters/features/score/score_provider.dart';
import 'package:counters/features/template/template_provider.dart';
import 'package:counters/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LeagueDetailPage extends ConsumerStatefulWidget {
  final String leagueId;

  const LeagueDetailPage({super.key, required this.leagueId});

  @override
  ConsumerState<LeagueDetailPage> createState() => _LeagueDetailPageState();
}

class _LeagueDetailPageState extends ConsumerState<LeagueDetailPage> {
  int _selectedIndex = 0;
  bool _isBracketFullscreen = false;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leagueAsync = ref.watch(leagueNotifierProvider);

    return leagueAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('加载联赛失败: $err')),
      ),
      data: (leagueState) {
        final league = leagueState.leagues
            .firstWhereOrNull((l) => l.lid == widget.leagueId);

        if (league == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: Text('联赛未找到或已删除'),
            ),
          );
        }

        // 根据联赛类型确定页面和导航项
        final List<Widget> pages;
        final List<NavigationDestination> destinations;

        if (league.type == LeagueType.roundRobin) {
          pages = [
            _RoundRobinMatchesList(league: league),
            _RankingsTable(league: league),
          ];
          destinations = [
            const NavigationDestination(
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt),
              label: '赛程',
            ),
            const NavigationDestination(
              icon: Icon(Icons.leaderboard_outlined),
              selectedIcon: Icon(Icons.leaderboard),
              label: '排名',
            ),
          ];
        } else {
          pages = [
            _KnockoutMatchesList(league: league),
            TournamentBracketView(
              league: league,
              onFullscreenToggle: (isFullscreen) {
                setState(() {
                  _isBracketFullscreen = isFullscreen;
                });
              },
            ),
          ];
          destinations = [
            const NavigationDestination(
              icon: Icon(Icons.view_list_outlined),
              selectedIcon: Icon(Icons.view_list),
              label: '赛程列表',
            ),
            const NavigationDestination(
              icon: Icon(Icons.emoji_events_outlined),
              selectedIcon: Icon(Icons.emoji_events),
              label: '对阵图',
            ),
          ];
        }

        return Scaffold(
          appBar: _isBracketFullscreen
              ? null
              : AppBar(
                  title: Text(league.name),
                  elevation: 0,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                ),
          body: PageView(
            physics: const NeverScrollableScrollPhysics(),
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            children: pages,
          ),
          bottomNavigationBar: _isBracketFullscreen
              ? null
              : NavigationBar(
                  destinations: destinations,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
        );
      },
    );
  }
}

// =============================================
// 淘汰赛视图 (_KnockoutMatchesList)
// =============================================
class _KnockoutMatchesList extends ConsumerWidget {
  final League league;

  const _KnockoutMatchesList({required this.league});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 按轮次分组比赛
    final groupedMatches =
        groupBy<Match, int>(league.matches, (match) => match.round);

    // 按轮次升序排序
    final sortedRounds = groupedMatches.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: sortedRounds.length,
      itemBuilder: (context, index) {
        final round = sortedRounds[index];
        final matchesInRound = groupedMatches[round]!;
        final roundName = getRoundName(league.playerIds.length, round);

        return _AnimatedExpansionPanel(
          title: Text(
            roundName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          deleteButton: Builder(
              builder: (context) => IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: '重置此轮次',
                    onPressed: () async {
                      final confirmed = await globalState.showCommonDialog(
                        child: AlertDialog(
                          title: const Text('确认重置'),
                          content: Text('确定要重置 "$roundName" 吗？\n\n'
                              '此操作将删除此轮次及其所有后续轮次的比赛，并根据前一轮的结果重新生成 "$roundName" 的对阵，且玩家对阵结果可能被改变。此操作不可撤销。'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('取消'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('重置',
                                  style: TextStyle(color: Colors.orange)),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        try {
                          await ref
                              .read(leagueNotifierProvider.notifier)
                              .resetRound(league.lid, round);
                        } catch (e) {
                          if (context.mounted) {
                            GlobalMsgManager.showWarn('重置失败');
                          }
                        }
                      }
                    },
                  )),
          children: matchesInRound
              .map((match) => _MatchTile(match: match, league: league))
              .toList(),
        );
      },
    );
  }
}

class _AnimatedExpansionPanel extends StatefulWidget {
  final Widget title;
  final List<Widget> children;
  final Widget? deleteButton; // 新增删除按钮参数

  const _AnimatedExpansionPanel(
      {required this.title, required this.children, this.deleteButton});

  @override
  _AnimatedExpansionPanelState createState() => _AnimatedExpansionPanelState();
}

class _AnimatedExpansionPanelState extends State<_AnimatedExpansionPanel>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = true;
  late AnimationController _controller;
  late Animation<double> _iconTurns;
  late Animation<double> _heightFactor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _iconTurns = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _heightFactor = _controller.drive(CurveTween(curve: Curves.easeInOut));

    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const borderRadiusValue = 8.0; // Match OutlineCard

    // 卡片的形状现在是固定的，始终保持四个角都是圆角
    final cardShape = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadiusValue),
      borderSide: BorderSide(
        color: Theme.of(context)
            .colorScheme
            .outline
            .withAlpha((0.2 * 255).toInt()),
      ),
    );

    return Card(
      elevation: 0,
      color: Theme.of(context).scaffoldBackgroundColor,
      clipBehavior: Clip.hardEdge,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: cardShape, // 使用固定的形状
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: _handleTap,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: widget.title),
                  if (widget.deleteButton != null) widget.deleteButton!,
                  RotationTransition(
                    turns: _iconTurns,
                    child: const Icon(Icons.expand_more),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _heightFactor,
            child: Column(children: widget.children),
          ),
        ],
      ),
    );
  }
}

// =============================================
// 循环赛视图 (_RoundRobinMatchesList)
// =============================================
class _RoundRobinMatchesList extends ConsumerWidget {
  final League league;

  const _RoundRobinMatchesList({required this.league});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveGridView(
      itemCount: league.matches.length,
      itemBuilder: (context, index) {
        final match = league.matches[index];
        return _MatchTile(match: match, league: league);
      },
    );
  }
}

// =============================================
// 通用比赛条目 (_MatchTile)
// =============================================
class _MatchTile extends ConsumerWidget {
  final Match match;
  final League league;

  const _MatchTile({required this.match, required this.league});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider).value;
    final templates = ref.watch(templatesProvider).value;

    if (playerState == null || templates == null) {
      return const ListTile(title: Text('加载数据中...'));
    }

    final player1 = playerState.players.firstWhere(
        (p) => p.pid == match.player1Id,
        orElse: () => PlayerInfo(name: '未知', avatar: ''));

    // 关键修复：处理轮空情况
    if (match.player2Id == 'bye') {
      return OutlineCard(
        leading: Icon(Icons.airline_stops_rounded,
            color: Theme.of(context).colorScheme.primary),
        title: Text('${player1.name} - 轮空'),
        subtitle: const Text('自动晋级'),
      );
    }

    final player2 = playerState.players.firstWhere(
        (p) => p.pid == match.player2Id,
        orElse: () => PlayerInfo(name: '未知', avatar: ''));

    return OutlineCard(
      title: Text('${player1.name} vs ${player2.name}'),
      subtitle: _buildSubtitle(match),
      trailing: _buildMatchTrailing(context, ref, match, templates),
      onTap: () => _navigateToGame(context, ref, match, templates, league),
    );
  }

  Widget _buildSubtitle(Match match) {
    String statusText;
    switch (match.status) {
      case MatchStatus.pending:
        statusText = '未开始';
        break;
      case MatchStatus.inProgress:
        statusText = '进行中';
        break;
      case MatchStatus.completed:
        statusText = '已完成';
        break;
    }

    if (match.status != MatchStatus.pending) {
      statusText +=
          ' - ${match.player1Score ?? 0} : ${match.player2Score ?? 0}';
    }

    return Text(statusText);
  }

  Widget? _buildMatchTrailing(BuildContext context, WidgetRef ref, Match match,
      List<BaseTemplate> templates) {
    // 关键修复：轮空比赛不应有任何操作按钮
    if (match.player2Id == 'bye') {
      return null;
    }

    final String buttonText;
    if (match.status == MatchStatus.completed) {
      buttonText = '查看详情';
    } else if (match.status == MatchStatus.inProgress) {
      buttonText = '继续计分';
    } else {
      buttonText = '进入比赛';
    }

    return TextButton(
      onPressed: () => _navigateToGame(context, ref, match, templates, league),
      child: Text(buttonText),
    );
  }

  void _navigateToGame(BuildContext context, WidgetRef ref, Match match,
      List<BaseTemplate> templates, League league) async {
    // 关键修复：增加安全检查，防止导航到轮空比赛
    if (match.player2Id == 'bye') {
      Log.d('尝试导航到轮空比赛，操作被阻止。');
      return;
    }

    final baseTemplate =
        templates.firstWhereOrNull((t) => t.tid == league.defaultTemplateId);

    if (baseTemplate == null) {
      Log.e(
          '[League Detail] FATAL: Could not find base template with ID: ${league.defaultTemplateId}');
      return;
    }

    final allPlayers = ref.read(playerProvider).value!.players;

    final player1 = allPlayers.firstWhere((p) => p.pid == match.player1Id);
    final player2 = allPlayers.firstWhere((p) => p.pid == match.player2Id);

    final matchTemplate = baseTemplate.copyWith(
      tid: 'temp_league_${match.mid}',
      templateName: '${league.name}: ${player1.name} vs ${player2.name}',
      playerCount: 2,
      players: [player1, player2],
      isSystemTemplate: false,
    );

    await ref.read(scoreProvider.notifier).startNewGame(
          matchTemplate,
          leagueMatchId: match.mid, // 传入联赛比赛ID
          persistentTemplateId: league.defaultTemplateId, // 传入用于持久化的模板ID
        );

    if (context.mounted) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => HomePage.buildSessionPage(matchTemplate),
      ));
    }
  }
}

// =============================================
// 排名视图 (_RankingsTable)
// =============================================
class _RankingsTable extends ConsumerStatefulWidget {
  final League league;

  const _RankingsTable({required this.league});

  @override
  ConsumerState<_RankingsTable> createState() => _RankingsTableState();
}

class _RankingsTableState extends ConsumerState<_RankingsTable> {
  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _bodyScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 同步滚动
    _bodyScrollController.addListener(() {
      if (_headerScrollController.hasClients &&
          _headerScrollController.offset != _bodyScrollController.offset) {
        _headerScrollController.jumpTo(_bodyScrollController.offset);
      }
    });
    _headerScrollController.addListener(() {
      if (_bodyScrollController.hasClients &&
          _bodyScrollController.offset != _headerScrollController.offset) {
        _bodyScrollController.jumpTo(_headerScrollController.offset);
      }
    });
  }

  @override
  void dispose() {
    _headerScrollController.dispose();
    _bodyScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerAsync = ref.watch(playerProvider);
    return playerAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('加载玩家失败: $err')),
      data: (playerState) {
        final players = playerState.players;
        final rankings = _calculateRankings(players);

        final headerStyle = Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.bold);
        const cellPadding =
            EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0);

        // 自动计算玩家列宽度以包裹内容
        // 1. 计算所有玩家名字所需的最大宽度
        double maxPlayerNameWidth = 0;
        final cellTextStyle = Theme.of(context).textTheme.bodyMedium;
        if (rankings.isNotEmpty && cellTextStyle != null) {
          final textPainter = TextPainter(
            maxLines: 1,
            textDirection: TextDirection.ltr,
          );
          for (final r in rankings) {
            textPainter.text =
                TextSpan(text: r.player.name, style: cellTextStyle);
            textPainter.layout(minWidth: 0, maxWidth: double.infinity);
            if (textPainter.size.width > maxPlayerNameWidth) {
              maxPlayerNameWidth = textPainter.size.width;
            }
          }
        }

        // 2. 计算表头 "玩家" 所需的宽度
        double headerWidth = 0;
        if (headerStyle != null) {
          final headerPainter = TextPainter(
            text: TextSpan(text: '玩家', style: headerStyle),
            maxLines: 1,
            textDirection: TextDirection.ltr,
          )..layout(minWidth: 0, maxWidth: double.infinity);
          headerWidth = headerPainter.size.width;
        }

        // 3. 确定最终的玩家列宽度
        // 取名字和表头中的最大值，设置一个最小宽度，并增加一些内边距
        final double playerWidth = [maxPlayerNameWidth, headerWidth, 40.0]
                .reduce((a, b) => a > b ? a : b) +
            16.0; // 左右各8px内边距

        // 定义其他列宽
        const double rankWidth = 50;
        const double statWidth = 50;
        // 计算内容总宽度
        final contentWidth = rankWidth + playerWidth + (statWidth * 5);
        // 加上表格的水平内边距
        final totalWidth = contentWidth + 16.0; // 整个表格行的左右内边距

        // 构建表头
        Widget buildHeader() {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1.0,
                ),
              ),
            ),
            child: SingleChildScrollView(
              controller: _headerScrollController,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: Container(
                width: totalWidth,
                padding: cellPadding,
                child: Row(
                  children: [
                    SizedBox(
                        width: rankWidth,
                        child: Text('排名',
                            style: headerStyle, textAlign: TextAlign.center)),
                    SizedBox(
                        width: playerWidth,
                        child: Text('玩家', style: headerStyle)),
                    SizedBox(
                        width: statWidth,
                        child: Text('场次',
                            style: headerStyle, textAlign: TextAlign.center)),
                    SizedBox(
                        width: statWidth,
                        child: Text('胜',
                            style: headerStyle, textAlign: TextAlign.center)),
                    SizedBox(
                        width: statWidth,
                        child: Text('平',
                            style: headerStyle, textAlign: TextAlign.center)),
                    SizedBox(
                        width: statWidth,
                        child: Text('负',
                            style: headerStyle, textAlign: TextAlign.center)),
                    SizedBox(
                        width: statWidth,
                        child: Text('积分',
                            style: headerStyle, textAlign: TextAlign.center)),
                  ],
                ),
              ),
            ),
          );
        }

        // 构建表格主体
        Widget buildBody() {
          return Expanded(
            child: Scrollbar(
              controller: _bodyScrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _bodyScrollController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: totalWidth,
                  child: ListView.separated(
                    itemCount: rankings.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final r = rankings[index];
                      return Container(
                        padding: cellPadding,
                        child: Row(
                          children: [
                            SizedBox(
                                width: rankWidth,
                                child: Text(r.rank.toString(),
                                    textAlign: TextAlign.center)),
                            SizedBox(
                                width: playerWidth,
                                child: Text(r.player.name,
                                    overflow: TextOverflow.ellipsis)),
                            SizedBox(
                                width: statWidth,
                                child: Text(r.played.toString(),
                                    textAlign: TextAlign.center)),
                            SizedBox(
                                width: statWidth,
                                child: Text(r.wins.toString(),
                                    textAlign: TextAlign.center)),
                            SizedBox(
                                width: statWidth,
                                child: Text(r.draws.toString(),
                                    textAlign: TextAlign.center)),
                            SizedBox(
                                width: statWidth,
                                child: Text(r.losses.toString(),
                                    textAlign: TextAlign.center)),
                            SizedBox(
                                width: statWidth,
                                child: Text(r.points.toString(),
                                    textAlign: TextAlign.center)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        }

        return Column(
          children: [
            buildHeader(),
            buildBody(),
          ],
        );
      },
    );
  }

  List<_RankingInfo> _calculateRankings(List<PlayerInfo> allPlayers) {
    final league = widget.league;
    final playerRankings = {
      for (var p in league.playerIds)
        p: _RankingInfo(player: allPlayers.firstWhere((ap) => ap.pid == p))
    };

    for (final match in league.matches) {
      if (match.status != MatchStatus.completed) continue;

      // 轮空比赛不计入统计
      if (match.player2Id == 'bye') continue;

      final p1Stats = playerRankings[match.player1Id];
      final p2Stats = playerRankings[match.player2Id];

      if (p1Stats == null || p2Stats == null) continue;

      p1Stats.played++;
      p2Stats.played++;

      if (match.winnerId == null) {
        // Draw
        p1Stats.draws++;
        p2Stats.draws++;
        p1Stats.points += league.pointsForDraw;
        p2Stats.points += league.pointsForDraw;
      } else if (match.winnerId == match.player1Id) {
        // P1 wins
        p1Stats.wins++;
        p2Stats.losses++;
        p1Stats.points += league.pointsForWin;
        p2Stats.points += league.pointsForLoss;
      } else {
        // P2 wins
        p2Stats.wins++;
        p1Stats.losses++;
        p2Stats.points += league.pointsForWin;
        p1Stats.points += league.pointsForLoss;
      }
    }

    final sortedRankings = playerRankings.values.toList();
    sortedRankings.sort((a, b) {
      int pointCompare = b.points.compareTo(a.points);
      if (pointCompare != 0) return pointCompare;
      // 如果积分相同，可以添加次要排序规则，例如净胜分等
      return a.player.name.compareTo(b.player.name); // 默认按名字排序
    });

    for (int i = 0; i < sortedRankings.length; i++) {
      if (i > 0 && sortedRankings[i].points == sortedRankings[i - 1].points) {
        // 如果积分与前一名相同，则排名相同
        sortedRankings[i].rank = sortedRankings[i - 1].rank;
      } else {
        // 否则，排名为当前索引 + 1
        sortedRankings[i].rank = i + 1;
      }
    }

    return sortedRankings;
  }
}

class _RankingInfo {
  final PlayerInfo player;
  int rank = 0;
  int played = 0;
  int wins = 0;
  int draws = 0;
  int losses = 0;
  int points = 0;

  _RankingInfo({required this.player});
}
