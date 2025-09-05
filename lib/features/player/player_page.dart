import 'package:counters/app/state.dart';
import 'package:counters/common/model/player_info.dart';
import 'package:counters/common/widgets/confirmation_dialog.dart';
import 'package:counters/common/widgets/message_overlay.dart';
import 'package:counters/common/widgets/outline_card.dart';
import 'package:counters/common/widgets/page_transitions.dart';
import 'package:counters/common/widgets/player_widget.dart';
import 'package:counters/common/widgets/responsive_grid_view.dart';
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

class _PlayerManagementPageState extends ConsumerState<PlayerManagementPage>
    with WidgetsBindingObserver {
  bool _isSearching = false;
  final _searchController = TextEditingController();
  bool _isMenuShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // 窗口尺寸变化时，如果菜单是打开的，则关闭它
    if (_isMenuShowing) {
      Navigator.of(context).pop();
    }
  }

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
  Widget build(BuildContext context) {
    final playerAsync = ref.watch(playerProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
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
          playerAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('加载玩家失败: $err')),
            data: (playerState) {
              final players = playerState.filteredPlayers;
              if (players.isEmpty) {
                return const Center(child: Text('未找到玩家'));
              }
              return RefreshIndicator(
                onRefresh: () => ref.refresh(playerProvider.future),
                child: ResponsiveGridView(
                  key: const PageStorageKey('player_list'),
                  minItemWidth: 250.0,
                  idealItemWidth: 300.0,
                  itemHeight: 80,
                  itemCount: players.length,
                  itemBuilder: (gridItemContext, index) {
                    final player = players[index];
                    final playCount =
                        playerState.playCountCache[player.pid] ?? 0;
                    return OutlineCard(
                      key: ValueKey(player.pid),
                      leading: PlayerAvatar.build(gridItemContext, player),
                      title: Text(
                        player.name,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      subtitle: Text('游玩次数：$playCount'),
                      trailing: Builder(
                        builder: (buttonContext) {
                          return IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () {
                              final RenderBox button =
                                  buttonContext.findRenderObject() as RenderBox;
                              final RenderBox overlay = Navigator.of(context)
                                  .overlay!
                                  .context
                                  .findRenderObject() as RenderBox;
                              final RelativeRect position =
                                  RelativeRect.fromRect(
                                Rect.fromPoints(
                                  button.localToGlobal(Offset.zero,
                                      ancestor: overlay),
                                  button.localToGlobal(
                                      button.size.bottomRight(Offset.zero),
                                      ancestor: overlay),
                                ),
                                Offset.zero & overlay.size,
                              );

                              setState(() {
                                _isMenuShowing = true;
                              });
                              showMenu<String>(
                                context: context,
                                position: position,
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
                              ).then((selectedValue) {
                                setState(() {
                                  _isMenuShowing = false;
                                });
                                if (selectedValue == null) return;
                                switch (selectedValue) {
                                  case 'edit':
                                    _showEditDialog(player,
                                        ref.read(playerProvider.notifier));
                                    break;
                                  case 'delete':
                                    _showDeleteDialog(player,
                                        ref.read(playerProvider.notifier));
                                    break;
                                }
                              });
                            },
                          );
                        },
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
              onPressed: () {
                Navigator.of(context).pushWithSlide(
                  AddPlayersPage(),
                  direction: SlideDirection.fromRight,
                  duration: const Duration(milliseconds: 300),
                );
              },
              child: const Icon(Icons.person_add),
            ),
          ),
        ],
      ),
    );
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
      try {
        final deletedCount =
            await ref.read(playerProvider.notifier).cleanUnusedPlayers();
        if (!mounted) return;

        if (deletedCount > 0) {
          ref.showSuccess('已删除 $deletedCount 个未使用的玩家');
        } else {
          ref.showMessage('没有找到未使用的玩家');
        }
      } catch (e) {
        if (!mounted) return;
        // 错误已经在 cleanUnusedPlayers 方法中通过 ErrorHandler.handle 处理
        // 这里只需要显示用户友好的提示
        ref.showWarning('删除操作失败，请稍后重试');
      }
    }
  }

  Future<void> _showEditDialog(
      PlayerInfo player, dynamic playerNotifier) async {
    final playerListItemKey = GlobalKey<PlayerListItemState>();
    globalState.showCommonDialog(
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
