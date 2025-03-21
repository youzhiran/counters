import 'package:counters/widgets/player_widget.dart';
import 'package:counters/widgets/snackbar.dart';
import 'package:flutter/material.dart';

class AddPlayersPage extends StatefulWidget {
  const AddPlayersPage({super.key});

  @override
  State<AddPlayersPage> createState() => _AddPlayersPageState();
}

class _AddPlayersPageState extends State<AddPlayersPage> {
  // 使用List<GlobalKey>来引用PlayerListItem组件
  final List<GlobalKey<PlayerListItemState>> _playerKeys = [
    GlobalKey<PlayerListItemState>()
  ];

  void _addNewPlayer() {
    setState(() {
      _playerKeys.add(GlobalKey<PlayerListItemState>());
    });
  }

  void _removePlayer(int index) {
    setState(() {
      _playerKeys.removeAt(index);
    });
  }

  void _savePlayers(BuildContext context) {
    bool hasValidPlayers = false;

    for (var key in _playerKeys) {
      if (key.currentState != null) {
        key.currentState!.savePlayer();
        if (key.currentState!.hasValidName()) {
          hasValidPlayers = true;
        }
      }
    }

    if (hasValidPlayers) {
      Navigator.pop(context);
    } else {
      AppSnackBar.warn('请至少输入一个有效的玩家名称');
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
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _playerKeys.length,
        itemBuilder: (context, index) {
          return PlayerListItem(
            key: _playerKeys[index],
            showRemoveButton: _playerKeys.length > 1,
            onRemove: () => _removePlayer(index),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SafeArea(
          child: OutlinedButton.icon(
            onPressed: _addNewPlayer,
            icon: Icon(Icons.person_add),
            label: Text('添加新玩家'),
          ),
        ),
      ),
    );
  }
}
