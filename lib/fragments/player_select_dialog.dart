import 'package:counters/page/add_players.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../db/player_info.dart';
import '../providers/player_provider.dart';

class PlayerSelectDialog extends StatefulWidget {
  final List<PlayerInfo> selectedPlayers;
  final int maxCount;

  const PlayerSelectDialog({
    super.key,
    required this.selectedPlayers,
    required this.maxCount,
  });

  @override
  State<PlayerSelectDialog> createState() => _PlayerSelectDialogState();
}

class _PlayerSelectDialogState extends State<PlayerSelectDialog> {
  final List<PlayerInfo> _selectedPlayers = [];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('选择玩家'),
      content: SizedBox(
        width: double.maxFinite,
        child: Consumer<PlayerProvider>(
          builder: (context, provider, child) {
            final players = provider.players ?? [];
            final availablePlayers = players
                .where(
                    (p) => !widget.selectedPlayers.any((sp) => sp.id == p.id))
                .toList();

            return Column(
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
                      icon: Icon(Icons.person_add, size: 20),
                      label: Text('添加新玩家'),
                    ),
                  ],
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: availablePlayers.length,
                    itemBuilder: (context, index) {
                      final player = availablePlayers[index];
                      final isSelected =
                          _selectedPlayers.any((p) => p.id == player.id);

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
                                        .removeWhere((p) => p.id == player.id);
                                  }
                                });
                              },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('取消'),
        ),
        TextButton(
          onPressed: _selectedPlayers.isEmpty
              ? null
              : () => Navigator.pop(context, _selectedPlayers),
          child: Text('确定'),
        ),
      ],
    );
  }
}
