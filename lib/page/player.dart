import 'dart:math';

import 'package:counters/state.dart';
import 'package:counters/widgets/player_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../db/player_info.dart';
import '../providers/player_provider.dart';
import '../widgets/confirmation_dialog.dart';
import 'add_players.dart';

class PlayerManagementPage extends StatefulWidget {
  const PlayerManagementPage({super.key});

  @override
  State<PlayerManagementPage> createState() => _PlayerManagementPageState();

  Future<void> showCleanPlayersDialog(BuildContext context) async {
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
      context.read<PlayerProvider>().cleanUnusedPlayers();
    }
  }
}

class _PlayerManagementPageState extends State<PlayerManagementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlayerProvider>().loadPlayers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Consumer<PlayerProvider>(
          builder: (context, provider, _) {
            if (provider.players == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.players!.isEmpty) {
              return const Center(child: Text('暂无玩家'));
            }

            return RefreshIndicator(
              onRefresh: () async {
                // 重新加载数据
                await provider.loadPlayers();
              },
              child: GridView.builder(
                key: PageStorageKey('player_list'), // 为整个列表添加key
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 78),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: max(
                    250.0, // 最小宽度
                    MediaQuery.of(context).size.width /
                        (MediaQuery.of(context).size.width ~/ 300), // 目标宽度
                  ),
                  mainAxisExtent: 72, // 卡片高度
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
                    key: ValueKey(player.id), // 为每个Card添加唯一的key
                    // margin: const EdgeInsets.only(bottom: 8),
                    child: Center(
                      child: ListTile(
                        leading: PlayerAvatar.build(context, player),
                        title: Text(
                          player.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        subtitle: FutureBuilder<int>(
                          future: provider.getPlayerPlayCount(player.id),
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
                                _showEditDialog(context, player);
                                break;
                              case 'delete':
                                _showDeleteDialog(context, player);
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

  Future<void> _showEditDialog(BuildContext context, PlayerInfo player) async {
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
              SizedBox(height: 16),
              PlayerListItem(
                key: playerListItemKey,
                initialPlayer: player,
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('取消'),
                  ),
                  SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      final playerListItem = playerListItemKey.currentState;
                      if (playerListItem != null &&
                          playerListItem.hasValidName()) {
                        final updatedPlayer = playerListItem.getPlayerInfo();
                        context
                            .read<PlayerProvider>()
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
      context.read<PlayerProvider>().loadPlayers();
    }
  }

  Future<void> _showDeleteDialog(
      BuildContext context, PlayerInfo player) async {
    final provider = context.read<PlayerProvider>();
    final isUsed = await provider.isPlayerInUse(player.id);

    if (!context.mounted) return;

    if (isUsed) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('无法删除'),
          content: Text('${player.name} 已被使用，不能删除'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('确定'),
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
      provider.deletePlayer(player.id);
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
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final provider = context.watch<PlayerProvider>();
    provider.setSearchQuery(query);

    if (provider.filteredPlayers == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.filteredPlayers!.isEmpty) {
      return const Center(child: Text('未找到玩家'));
    }

    return ListView.builder(
      itemCount: provider.filteredPlayers!.length,
      itemBuilder: (context, index) {
        final player = provider.filteredPlayers![index];
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
