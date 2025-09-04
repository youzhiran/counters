import 'package:counters/app/state.dart';
import 'package:counters/common/model/player_info.dart';
import 'package:counters/features/player/add_players.dart';
import 'package:counters/features/player/player_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlayerSelectDialog extends ConsumerStatefulWidget {
  final List<PlayerInfo> selectedPlayers;
  final int maxCount;

  const PlayerSelectDialog({
    super.key,
    required this.selectedPlayers,
    required this.maxCount,
  });

  @override
  ConsumerState<PlayerSelectDialog> createState() => _PlayerSelectDialogState();
}

class _PlayerSelectDialogState extends ConsumerState<PlayerSelectDialog> {
  late final List<PlayerInfo> _selectedPlayers;

  @override
  void initState() {
    super.initState();
    _selectedPlayers = List.from(widget.selectedPlayers);
  }

  @override
  Widget build(BuildContext context) {
    final playerAsync = ref.watch(playerProvider);

    return AlertDialog(
      title: const Text('选择玩家'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('已选择 ${_selectedPlayers.length}/${widget.maxCount} 人'),
                TextButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddPlayersPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_add, size: 20),
                  label: const Text('添加新玩家'),
                ),
              ],
            ),
            Flexible(
              child: playerAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('加载玩家失败: $err')),
                data: (playerState) {
                  final players = playerState.players;
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      final player = players[index];
                      final isSelected =
                          _selectedPlayers.any((p) => p.pid == player.pid);

                      return CheckboxListTile(
                        title: Text(player.name),
                        value: isSelected,
                        onChanged: _selectedPlayers.length >= widget.maxCount &&
                                !isSelected
                            ? null
                            : (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedPlayers.add(player);
                                  } else {
                                    _selectedPlayers.removeWhere(
                                        (p) => p.pid == player.pid);
                                  }
                                });
                              },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => globalState.navigatorKey.currentState?.pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _selectedPlayers),
          child: const Text('确定'),
        ),
      ],
    );
  }
}
