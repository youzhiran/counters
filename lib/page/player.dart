import 'dart:math';

import 'package:counters/widgets/player_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/player_info.dart';
import '../providers/player_provider.dart';
import '../state.dart';
import '../widgets/confirmation_dialog.dart';
import 'add_players.dart';

class PlayerManagementPage extends ConsumerWidget {
  const PlayerManagementPage({super.key});

  Future<void> showCleanPlayersDialog(
      BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: '删除未使用玩家',
        content: '确定要删除所有未使用玩家吗？此操作不可恢复。',
        confirmText: '删除',
      ),
    );

    if (!context.mounted) return;
    if (result == true) {
      ref.read(playerProvider.notifier).cleanUnusedPlayers();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 初始化加载玩家数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playerProvider.notifier).loadPlayers();
    });

    return Stack(
      children: [
        Consumer(
          builder: (context, ref, _) {
            final provider = ref.watch(playerProvider);

            if (provider.players == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.players!.isEmpty) {
              return const Center(child: Text('暂无玩家'));
            }

            return RefreshIndicator(
              onRefresh: () async {
                // 重新加载数据
                await ref.read(playerProvider.notifier).loadPlayers();
              },
              child: GridView.builder(
                key: const PageStorageKey('player_list'),
                // 为整个列表添加key
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 78),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: max(
                    250.0, // 最小宽度
                    MediaQuery.of(context).size.width /
                        (MediaQuery.of(context).size.width ~/ 300), // 目标宽度
                  ),
                  mainAxisExtent: 80, // 卡片高度
                  crossAxisSpacing: 0, // 水平间距
                  mainAxisSpacing: 0, // 垂直间距
                ),
                itemCount: provider.players!.length,
                itemBuilder: (context, index) {
                  final player = provider.players![index];
                  return Card(
                    elevation: 0,
                    shape: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.2),
                      ),
                    ),
                    key: ValueKey(player.pid), // 为每个Card添加唯一的key
                    child: Center(
                      child: ListTile(
                        leading: PlayerAvatar.build(context, player),
                        title: Text(
                          player.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        subtitle: FutureBuilder<int>(
                          future: ref
                              .read(playerProvider.notifier)
                              .getPlayerPlayCount(player.pid),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Text('游玩次数：加载中...');
                            }
                            final count = snapshot.data ?? 0;
                            return Text('游玩次数：$count');
                          },
                        ),
                        trailing: PopupMenuButton<String>(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text('编辑'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete),
                                  SizedBox(width: 8),
                                  Text('删除'),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _showEditDialog(context, player, ref);
                                break;
                              case 'delete':
                                _showDeleteDialog(context, player, ref);
                                break;
                            }
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => AddPlayersPage()),
            ),
            child: const Icon(Icons.person_add),
          ),
        ),
      ],
    );
  }

  Future<void> _showEditDialog(
      BuildContext context, PlayerInfo player, WidgetRef ref) async {
    if (!context.mounted) return;

    final playerListItemKey = GlobalKey<PlayerListItemState>();

    final result = await globalState.showCommonDialog(
      child: Dialog(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '编辑玩家',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              PlayerListItem(
                key: playerListItemKey,
                initialPlayer: player,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      final playerListItem = playerListItemKey.currentState;
                      if (playerListItem != null &&
                          playerListItem.hasValidName()) {
                        final updatedPlayer = playerListItem.getPlayerInfo();
                        ref
                            .read(playerProvider.notifier)
                            .updatePlayer(updatedPlayer);
                        Navigator.of(context).pop(true);
                      }
                    },
                    child: const Text('保存'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (!context.mounted) return;
    if (result == true) {
      ref.read(playerProvider.notifier).loadPlayers();
    }
  }

  Future<void> _showDeleteDialog(
      BuildContext context, PlayerInfo player, WidgetRef ref) async {
    final isUsed =
        await ref.read(playerProvider.notifier).isPlayerInUse(player.pid);

    if (!context.mounted) return;

    if (isUsed) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('无法删除'),
          content: Text('${player.name} 已被使用，不能删除'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        ),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: '删除玩家',
        content: '确定要删除玩家 ${player.name} 吗？',
        confirmText: '删除',
      ),
    );

    if (!context.mounted) return;
    if (result == true) {
      ref.read(playerProvider.notifier).deletePlayer(player.pid);
    }
  }
}

class PlayerSearchDelegate extends SearchDelegate<void> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showResults(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return _buildSearchResults(context, ref);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return _buildSearchResults(context, ref);
      },
    );
  }

  Widget _buildSearchResults(BuildContext context, WidgetRef ref) {
    ref.read(playerProvider.notifier).setSearchQuery(query);
    final state = ref.watch(playerProvider);

    if (state.filteredPlayers == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.filteredPlayers!.isEmpty) {
      return const Center(child: Text('未找到玩家'));
    }

    return ListView.builder(
      itemCount: state.filteredPlayers!.length,
      itemBuilder: (context, index) {
        final player = state.filteredPlayers![index];
        return ListTile(
          leading: PlayerAvatar.build(context, player),
          title: Text(player.name),
          onTap: () {
            close(context, null);
          },
        );
      },
    );
  }
}
