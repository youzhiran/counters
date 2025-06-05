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
            onPressed: showCleanPlayersDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Consumer(
                  builder: (context, watchRef, _) {
                    final providerState = watchRef.watch(playerProvider);
                    final players = providerState.filteredPlayers;

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
                        itemBuilder: (gridItemContext, index) {
                          final player = players[index];
                          return Card(
                            elevation: 0,
                            shape: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(
                                color: Theme.of(gridItemContext)
                                    .colorScheme
                                    .outline
                                    .withAlpha((0.2 * 255).toInt()),
                              ),
                            ),
                            key: ValueKey(player.pid),
                            child: Center(
                              // 使用 GestureDetector 包裹 ListTile 来获取 onTapDown
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque, //确保整个区域都能响应点击
                                onTapDown: (details) {
                                  _showPlayerActionsMenu(
                                      context,
                                      // 使用父级 context (Page's context) 来显示菜单
                                      details.globalPosition, // 全局点击位置
                                      player,
                                      ref.read(playerProvider.notifier));
                                },
                                child: ListTile(
                                  leading: PlayerAvatar.build(
                                      gridItemContext, player),
                                  title: Text(
                                    player.name,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  subtitle: Consumer(
                                    builder: (context, ref, child) {
                                      final playerState =
                                          ref.watch(playerProvider);
                                      final count = playerState
                                              .playCountCache[player.pid] ??
                                          0;
                                      return Text('游玩次数：$count');
                                    },
                                  ),
                                  // 如果希望点击整个 ListTile 触发，trailing 可以是 null
                                  // 或者你也可以放一个非交互的图标，或者一个有不同功能的 IconButton
                                  trailing: const Icon(Icons.more_vert),
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
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => AddPlayersPage()),
                );
              },
              child: const Icon(Icons.person_add),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPlayerActionsMenu(
    BuildContext pageContext,
    Offset globalPosition, // 现在明确是 Offset
    PlayerInfo player,
    dynamic playerNotifier,
  ) async {
    final RelativeRect menuPosition = RelativeRect.fromLTRB(
      globalPosition.dx,
      globalPosition.dy,
      globalPosition.dx + 1, // 让 showMenu 根据内容自动调整宽度
      globalPosition.dy + 1, // 让 showMenu 根据内容自动调整高度
    );

    final String? selectedAction = await showMenu<String>(
      context: pageContext,
      position: menuPosition,
      items: <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20),
              SizedBox(width: 8),
              Text('编辑'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 20),
              SizedBox(width: 8),
              Text('删除'),
            ],
          ),
        ),
      ],
      elevation: 8.0,
    );

    if (selectedAction != null) {
      switch (selectedAction) {
        case 'edit':
          _showEditDialog(player, playerNotifier);
          break;
        case 'delete':
          _showDeleteDialog(player, playerNotifier);
          break;
      }
    }
  }

  Future<void> showCleanPlayersDialog() async {
    final result = await globalState.showCommonDialog(
      child: ConfirmationDialog(
        title: '删除未使用玩家',
        content: '确定要删除所有未使用玩家吗？此操作不可恢复。',
        confirmText: '删除',
      ),
    );
    if (!mounted) return;
    if (result == true) {
      ref.read(playerProvider.notifier).cleanUnusedPlayers();
    }
  }

  Future<void> _showEditDialog(
      PlayerInfo player, dynamic playerNotifier) async {
    final playerListItemKey = GlobalKey<PlayerListItemState>();
    final result = await globalState.showCommonDialog(
      child: Dialog(
        child: Builder(
          builder: (dialogContext) {
            return Container(
              width: 400,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '编辑玩家',
                    style: Theme.of(dialogContext).textTheme.titleLarge,
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
                        onPressed: () {
                          globalState.navigatorKey.currentState?.pop();
                        },
                        child: const Text('取消'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          final playerListItem = playerListItemKey.currentState;
                          if (playerListItem != null &&
                              playerListItem.hasValidName()) {
                            final updatedPlayer =
                                playerListItem.getPlayerInfo();
                            playerNotifier.updatePlayer(updatedPlayer);
                            globalState.navigatorKey.currentState?.pop();
                          }
                        },
                        child: const Text('保存'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
    if (!mounted) return;
    if (result == true) {
      ref.read(playerProvider.notifier).loadPlayers();
    }
  }

  Future<void> _showDeleteDialog(
      PlayerInfo player, dynamic playerNotifier) async {
    final isUsed = await playerNotifier.isPlayerInUse(player.pid);
    if (isUsed) {
      globalState.showCommonDialog(
        child: AlertDialog(
          title: const Text('无法删除'),
          content: Text('${player.name} 已被使用，不能删除'),
          actions: [
            TextButton(
              onPressed: () => globalState.navigatorKey.currentState?.pop(),
              child: const Text('确定'),
            ),
          ],
        ),
      );
      return;
    }
    final result = await globalState.showCommonDialog(
      child: Builder(builder: (dialogContext) {
        return ConfirmationDialog(
          title: '删除玩家',
          content: '确定要删除玩家 ${player.name} 吗？',
          confirmText: '删除',
        );
      }),
    );
    if (result == true) {
      playerNotifier.deletePlayer(player.pid);
    }
  }
}
