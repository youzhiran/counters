import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../db/player_info.dart';
import '../providers/player_provider.dart';
import '../widgets/confirmation_dialog.dart';
import 'add_players.dart';

class PlayerManagementPage extends StatelessWidget {
  const PlayerManagementPage({super.key});

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

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.players!.length,
              itemBuilder: (context, index) {
                final player = provider.players![index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        player.name.isNotEmpty ? player.name[0] : '?',
                        style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    title: Text(player.name),
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
                );
              },
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
    final controller = TextEditingController(text: player.name);

    if (!context.mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑玩家'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '玩家名称',
            hintText: '请输入玩家名称',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    if (result == true && controller.text.isNotEmpty) {
      final updatedPlayer = player.copyWith(name: controller.text);
      context.read<PlayerProvider>().updatePlayer(updatedPlayer);
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

  Future<void> showDeleteAllDialog(BuildContext context) async {
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
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              player.name.isNotEmpty ? player.name[0] : '?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          title: Text(player.name),
          onTap: () {
            close(context, null);
          },
        );
      },
    );
  }
}
