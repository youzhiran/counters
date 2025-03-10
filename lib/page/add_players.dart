import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../db/player_info.dart';
import '../providers/player_provider.dart';

class AddPlayersPage extends StatefulWidget {
  const AddPlayersPage({super.key});

  @override
  State<AddPlayersPage> createState() => _AddPlayersPageState();
}

class _AddPlayersPageState extends State<AddPlayersPage> {
  final List<TextEditingController> _controllers = [TextEditingController()];

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addNewPlayer() {
    setState(() {
      _controllers.add(TextEditingController());
    });
  }

  void _removePlayer(int index) {
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
    });
  }

  void _savePlayers(BuildContext context) {
    final provider = context.read<PlayerProvider>();
    bool hasValidPlayers = false;

    for (var controller in _controllers) {
      final name = controller.text.trim();
      if (name.isNotEmpty) {
        hasValidPlayers = true;
        final player = PlayerInfo(
          name: name,
          avatar: 'default_avatar.png',
        );
        provider.addPlayer(player);
      }
    }

    if (hasValidPlayers) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('添加玩家'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () => _savePlayers(context),
          ),
        ],
      ),
      body: ListView.separated(
        padding: EdgeInsets.all(16),
        itemCount: _controllers.length + 1,
        separatorBuilder: (context, index) {
          // 最后一个分隔线（添加按钮之前）使用不同样式
          if (index == _controllers.length - 1) {
            return Divider(height: 1, thickness: 1);
          }
          return Divider(height: 1);
        },
        itemBuilder: (context, index) {
          if (index == _controllers.length) {
            return Padding(
              padding: EdgeInsets.only(top: 16),
              child: OutlinedButton.icon(
                onPressed: _addNewPlayer,
                icon: Icon(Icons.add),
                label: Text('添加新玩家'),
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(0, 6, 0, 6),
            child: Row(
              children: [
                CircleAvatar(radius: 24, child: Icon(Icons.person)),
                SizedBox(width: 16),
                Expanded(
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _controllers[index],
                    builder: (context, value, child) {
                      return TextField(
                        controller: _controllers[index],
                        decoration: InputDecoration(
                          labelText: '玩家名称',
                          border: OutlineInputBorder(),
                          counterText: '${value.text.length}/10',
                        ),
                        maxLength: 10,
                      );
                    },
                  ),
                ),
                if (_controllers.length > 1)
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline),
                    onPressed: () => _removePlayer(index),
                    color: Colors.red,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
