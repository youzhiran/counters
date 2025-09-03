import 'dart:math';

import 'package:counters/app/state.dart';
import 'package:counters/common/model/league.dart';
import 'package:counters/common/model/league_enums.dart';
import 'package:counters/common/providers/league_provider.dart';
import 'package:counters/common/widgets/confirmation_dialog.dart';
import 'package:counters/common/widgets/outline_card.dart';
import 'package:counters/common/widgets/page_transitions.dart';
import 'package:counters/features/league/create_league_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'league_detail_page.dart';

class LeagueListPage extends ConsumerWidget {
  const LeagueListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leagueAsync = ref.watch(leagueNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: const Text('联赛管理'),
      ),
      body: leagueAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('加载失败: $err')),
        data: (leagueState) => _buildBody(context, ref, leagueState.leagues),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushWithSlide(
            const CreateLeaguePage(),
            direction: SlideDirection.fromBottom,
          );
        },
        tooltip: '创建新联赛',
        child: const Icon(Icons.add),
      ),
    );
  }

  String _getLeagueTypeDesc(LeagueType type) {
    switch (type) {
      case LeagueType.knockout:
        return '淘汰赛';
      case LeagueType.roundRobin:
        return '循环赛';
    }
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, List<League> leagues) {
    if (leagues.isEmpty) {
      return const Center(
        child: Text(
          '还没有创建任何联赛.\n点击右下角按钮创建一个吧！',
          textAlign: TextAlign.center,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.refresh(leagueNotifierProvider.future),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 78),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: max(
            300.0,
            MediaQuery.of(context).size.width /
                (MediaQuery.of(context).size.width ~/ 350),
          ),
          mainAxisExtent: 72,
          crossAxisSpacing: 0,
          mainAxisSpacing: 0,
        ),
        itemCount: leagues.length,
        itemBuilder: (context, index) {
          final league = leagues[index];
          return OutlineCard(
            title: Text(league.name),
            subtitle: Text(
                '类型: ${_getLeagueTypeDesc(league.type)} | 玩家: ${league.playerIds.length}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: '删除联赛',
              onPressed: () =>
                  _showDeleteConfirmationDialog(context, ref, league.lid),
            ),
            onTap: () {
              Navigator.of(context).pushWithSlide(
                LeagueDetailPage(leagueId: league.lid),
                direction: SlideDirection.fromRight,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, WidgetRef ref, String leagueId) async {
    final bool? confirmed = await globalState.showCommonDialog<bool>(
      child: const ConfirmationDialog(
        title: '确认删除',
        content: '你确定要删除这个联赛吗？此操作不可撤销。',
        confirmText: '删除',
      ),
    );

    if (confirmed == true) {
      ref.read(leagueNotifierProvider.notifier).deleteLeague(leagueId);
    }
  }
}
