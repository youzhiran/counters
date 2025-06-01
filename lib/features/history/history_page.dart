import 'dart:math' as math;

import 'package:counters/app/state.dart';
import 'package:counters/common/model/game_session.dart';
import 'package:counters/common/widgets/confirmation_dialog.dart';
import 'package:counters/common/widgets/history_session_item.dart';
import 'package:counters/common/widgets/snackbar.dart';
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
          return FutureBuilder<List<GameSession>>(
            future: ref.read(scoreProvider.notifier).getAllSessions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else {
                final sessions = snapshot.data ?? [];
                sessions.sort((a, b) => b.startTime.compareTo(a.startTime));

                return sessions.isEmpty
                    ? const Center(child: Text('暂无历史记录'))
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(scoreProvider);
                        },
                        child: GridView.builder(
                          key: const PageStorageKey('history_list'),
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                          gridDelegate:
                              SliverGridDelegateWithMaxCrossAxisExtent(
                            // 卡片宽度至少300，然后根据屏幕宽度计算每行卡片数量
                            maxCrossAxisExtent: math.max(
                              300.0,
                              MediaQuery.of(context).size.width /
                                  (MediaQuery.of(context).size.width ~/ 300),
                            ),
                            mainAxisExtent: 108,
                            crossAxisSpacing: 0,
                            mainAxisSpacing: 0,
                          ),
                          itemCount: sessions.length,
                          itemBuilder: (context, index) {
                            final session = sessions[index];
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
                                  child: const Icon(Icons.delete,
                                      color: Colors.white),
                                ),
                                confirmDismiss: (direction) async {
                                  return await globalState.showCommonDialog(
                                    child: AlertDialog(
                                      title: const Text('确认删除'),
                                      content: const Text('确定要删除这条记录吗？'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('取消'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('删除',
                                              style:
                                                  TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                onDismissed: (_) async {
                                  await ref
                                      .read(scoreProvider.notifier)
                                      .deleteSession(session.sid);
                                  setState(() {});
                                },
                                child: HistorySessionItem(
                                  session: session,
                                  onDelete: () async {
                                    await ref
                                        .read(scoreProvider.notifier)
                                        .deleteSession(session.sid);
                                    setState(() {});
                                  },
                                  onResume: () {
                                    _resumeSession(context, ref, session);
                                  },
                                ),
                              ),
                            );
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
    // No need to pop dialog, as it's a page now
    AppSnackBar.show('已清除所有历史记录');
    setState(() {}); // Refresh the page to show empty state
  }

  void _resumeSession(
      BuildContext context, WidgetRef ref, GameSession session) async {
    ref.read(scoreProvider.notifier).loadSession(session);
    final template = await ref
        .read(templatesProvider.notifier)
        .getTemplateAsync(session.templateId);

    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomePage.buildSessionPage(template, session.templateId),
      ),
    );
  }
}
