import 'dart:math';

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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(80),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _handleTap,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12.0)),
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
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 78),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: max(
          400.0,
          MediaQuery.of(context).size.width /
              (MediaQuery.of(context).size.width ~/ 450),
        ),
        mainAxisExtent: 72,
        crossAxisSpacing: 0,
        mainAxisSpacing: 0,
      ),
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
      return Card(
        elevation: 0,
        shape: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .outline
                .withAlpha((0.2 * 255).toInt()),
          ),
        ),
        child: ListTile(
          leading: Icon(Icons.airline_stops_rounded,
              color: Theme.of(context).colorScheme.primary),
          title: Text('${player1.name} - 轮空'),
          subtitle: const Text('自动晋级'),
        ),
      );
    }

    final player2 = playerState.players.firstWhere(
        (p) => p.pid == match.player2Id,
        orElse: () => PlayerInfo(name: '未知', avatar: ''));

    return Card(
      elevation: 0,
      shape: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(
          color: Theme.of(context)
              .colorScheme
              .outline
              .withAlpha((0.2 * 255).toInt()),
        ),
      ),
      child: ListTile(
        title: Text('${player1.name} vs ${player2.name}'),
        subtitle: _buildSubtitle(match),
        trailing: _buildMatchTrailing(context, ref, match, templates),
        onTap: () => _navigateToGame(context, ref, match, templates, league),
      ),
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

    return ElevatedButton(
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
class _RankingsTable extends ConsumerWidget {
  final League league;

  const _RankingsTable({required this.league});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerAsync = ref.watch(playerProvider);
    return playerAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('加载玩家失败: $err')),
      data: (playerState) {
        final players = playerState.players;
        final rankings = _calculateRankings(players);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('排名')),
              DataColumn(label: Text('玩家')),
              DataColumn(label: Text('场次')),
              DataColumn(label: Text('胜')),
              DataColumn(label: Text('平')),
              DataColumn(label: Text('负')),
              DataColumn(label: Text('积分')),
            ],
            rows: rankings.map((r) {
              return DataRow(cells: [
                DataCell(Text(r.rank.toString())),
                DataCell(Text(r.player.name)),
                DataCell(Text(r.played.toString())),
                DataCell(Text(r.wins.toString())),
                DataCell(Text(r.draws.toString())),
                DataCell(Text(r.losses.toString())),
                DataCell(Text(r.points.toString())),
              ]);
            }).toList(),
          ),
        );
      },
    );
  }

  List<_RankingInfo> _calculateRankings(List<PlayerInfo> allPlayers) {
    final playerRankings = {
      for (var p in league.playerIds)
        p: _RankingInfo(player: allPlayers.firstWhere((ap) => ap.pid == p))
    };

    for (final match in league.matches) {
      if (match.status != MatchStatus.completed) continue;

      final p1Stats = playerRankings[match.player1Id]!;
      final p2Stats = playerRankings[match.player2Id]!;

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
    sortedRankings.sort((a, b) => b.points.compareTo(a.points));

    for (int i = 0; i < sortedRankings.length; i++) {
      sortedRankings[i].rank = i + 1;
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
