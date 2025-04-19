import 'dart:math';

import 'package:counters/app/state.dart';
import 'package:counters/common/model/player_info.dart';
import 'package:counters/common/widgets/confirmation_dialog.dart';
import 'package:counters/common/widgets/player_widget.dart';
import 'package:counters/features/player/add_players.dart';
import 'package:counters/features/player/player_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';



class PlayerManagementPage extends ConsumerStatefulWidget {
  const PlayerManagementPage({super.key});

  @override
  ConsumerState<PlayerManagementPage> createState() =>
      _PlayerManagementPageState();
}

class _PlayerManagementPageState extends ConsumerState<PlayerManagementPage> {
  bool _isSearching = false;
  final _searchController = TextEditingController();

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      ref.read(playerProvider.notifier).setSearchQuery('');
    });
  }

  @override
  void initState() {
    super.initState();
    // 将加载逻辑移到 initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(playerProvider.notifier).loadPlayers();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '搜索玩家...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  ref.read(playerProvider.notifier).setSearchQuery(value);
                },
              )
            : const Text('玩家'),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _stopSearch,
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _startSearch,
            ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => showCleanPlayersDialog(context, ref),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    final provider = ref.watch(playerProvider);
                    final players = provider.filteredPlayers;

                    if (players == null) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (players.isEmpty) {
                      return const Center(child: Text('未找到玩家'));
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        await ref.read(playerProvider.notifier).loadPlayers();
                      },
                      child: GridView.builder(
                        key: const PageStorageKey('player_list'),
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 78),
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: max(
                            250.0,
                            MediaQuery.of(context).size.width /
                                (MediaQuery.of(context).size.width ~/ 300),
                          ),
                          mainAxisExtent: 80,
                          crossAxisSpacing: 0,
                          mainAxisSpacing: 0,
                        ),
                        itemCount: players.length,
                        itemBuilder: (context, index) {
                          final player = players[index];
                          return Card(
                            elevation: 0,
                            shape: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withOpacity(0.2),
                              ),
                            ),
                            key: ValueKey(player.pid),
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
              ),
            ],
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
      ),
    );
  }

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
