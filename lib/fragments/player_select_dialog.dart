import 'package:counters/page/add_players.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/player_info.dart';
import '../providers/player_provider.dart';

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
  final List<PlayerInfo> _selectedPlayers = [];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerProvider);

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
                    // 强制刷新状态以显示新添加的玩家
                    setState(() {});
                  },
                  icon: const Icon(Icons.person_add, size: 20),
                  label: const Text('添加新玩家'),
                ),
              ],
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: state.players?.length ?? 0,
                itemBuilder: (context, index) {
                  final player = state.players![index];
                  final isAvailable =
                      !widget.selectedPlayers.any((sp) => sp.pid == player.pid);
                  final isSelected =
                      _selectedPlayers.any((p) => p.pid == player.pid);

                  if (!isAvailable) return const SizedBox.shrink();

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
                                _selectedPlayers
                                    .removeWhere((p) => p.pid == player.pid);
                              }
                            });
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
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _selectedPlayers.isEmpty
              ? null
              : () => Navigator.pop(context, _selectedPlayers),
          child: const Text('确定'),
        ),
      ],
    );
  }
}
