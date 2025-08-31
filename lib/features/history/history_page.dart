import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:counters/app/state.dart';
import 'package:counters/common/model/game_session.dart';
import 'package:counters/common/model/league.dart' as model;
import 'package:counters/common/providers/league_provider.dart';
import 'package:counters/common/widgets/confirmation_dialog.dart';
import 'package:counters/common/widgets/history_session_item.dart';
import 'package:counters/common/widgets/message_overlay.dart';
import 'package:counters/common/widgets/page_transitions.dart';
import 'package:counters/features/league/league_detail_page.dart';
import 'package:counters/features/score/score_provider.dart';
import 'package:counters/features/template/template_provider.dart';
import 'package:counters/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  Future<List<dynamic>> _getDisplayItems() async {
    final allSessions = await ref.read(scoreProvider.notifier).getAllSessions();
    final leagueState = await ref.read(leagueNotifierProvider.future);
    final allLeagues = leagueState.leagues;

    final List<dynamic> displayItems = [];
    final Set<String> processedLeagueIds = {};

    // Sort sessions by start time descending
    allSessions.sort((a, b) => b.startTime.compareTo(a.startTime));

    for (final session in allSessions) {
      if (session.leagueMatchId == null) {
        // It's a normal session
        displayItems.add(session);
      } else {
        // It's a league session
        final league = allLeagues.firstWhereOrNull(
            (l) => l.matches.any((m) => m.mid == session.leagueMatchId));
        if (league != null && !processedLeagueIds.contains(league.lid)) {
          displayItems.add(league);
          processedLeagueIds.add(league.lid);
        }
      }
    }
    return displayItems;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('历史计分记录'),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: '清除所有记录',
              onPressed: () => _showClearConfirmation(context, ref),
            )
          ],
        ),
      ),
      body: Consumer(
        builder: (context, ref, _) {
          return FutureBuilder<List<dynamic>>(
            future: _getDisplayItems(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('加载历史记录失败: ${snapshot.error}'));
              } else {
                final displayItems = snapshot.data ?? [];

                return displayItems.isEmpty
                    ? const Center(child: Text('暂无历史记录'))
                    : RefreshIndicator(
                        onRefresh: () async {
                          setState(() {});
                        },
                        child: GridView.builder(
                          key: const PageStorageKey('history_list'),
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                          gridDelegate:
                              SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: math.max(
                              300.0,
                              MediaQuery.of(context).size.width /
                                  (MediaQuery.of(context).size.width ~/ 300),
                            ),
                            mainAxisExtent: 108,
                            crossAxisSpacing: 0,
                            mainAxisSpacing: 0,
                          ),
                          itemCount: displayItems.length,
                          itemBuilder: (context, index) {
                            final item = displayItems[index];
                            if (item is GameSession) {
                              return _buildGameSessionCard(item);
                            } else if (item is model.League) {
                              return _buildLeagueCard(item);
                            }
                            return const SizedBox.shrink(); // Should not happen
                          },
                        ),
                      );
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildGameSessionCard(GameSession session) {
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
      key: ValueKey(session.sid),
      child: Dismissible(
        key: Key(session.sid),
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (direction) async {
          return await globalState.showCommonDialog(
            child: AlertDialog(
              title: const Text('确认删除'),
              content: const Text('确定要删除这条记录吗？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('删除', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        },
        onDismissed: (_) async {
          await ref.read(scoreProvider.notifier).deleteSession(session.sid);
          setState(() {});
        },
        child: HistorySessionItem(
          session: session,
          onDelete: () async {
            await ref.read(scoreProvider.notifier).deleteSession(session.sid);
            setState(() {});
          },
          onResume: () {
            _resumeSession(context, ref, session);
          },
        ),
      ),
    );
  }

  Widget _buildLeagueCard(model.League league) {
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
      key: ValueKey(league.lid),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => LeagueDetailPage(leagueId: league.lid),
          ));
        },
        borderRadius: BorderRadius.circular(8.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              const Icon(Icons.emoji_events, size: 40, color: Colors.orangeAccent),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(league.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    const Text('联赛记录', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearConfirmation(BuildContext context, WidgetRef ref) {
    globalState
        .showCommonDialog(
      child: ConfirmationDialog(
        title: '确认清除',
        content: '这将永久删除所有历史记录!\n玩家统计数据同时也会被清除。\n此操作不可撤销!',
        confirmText: '确认清除',
      ),
    )
        .then((confirmed) {
      if (confirmed == true) {
        _clearAllHistory(ref);
      }
    });
  }

  void _clearAllHistory(WidgetRef ref) async {
    await ref.read(scoreProvider.notifier).clearAllHistory();
    ref.showSuccess('已清除所有历史记录');
    setState(() {}); // Refresh the page to show empty state
  }

  void _resumeSession(
      BuildContext context, WidgetRef ref, GameSession session) async {
    final template = await ref
        .read(templatesProvider.notifier)
        .getTemplateAsync(session.templateId);

    if (template == null) {
      GlobalMsgManager.showError('找不到此记录对应的模板 (ID: ${session.templateId})，可能已被删除。');
      return;
    }

    ref.read(scoreProvider.notifier).loadSession(session);

    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      CustomPageTransitions.slideFromRight(
        HomePage.buildSessionPage(template),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
    );
  }
}
