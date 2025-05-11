import 'package:counters/app/state.dart';
import 'package:counters/common/model/player_info.dart';
import 'package:counters/features/player/player_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlayerAvatar {
  static final List<Color> avatarColors = [
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.cyan,
    Colors.amber,
    Colors.deepPurple,
  ];

  /// 创建玩家头像组件
  static Widget build(BuildContext context, PlayerInfo player) {
    // 根据玩家ID生成固定的随机颜色
    final colorIndex = player.pid.hashCode % avatarColors.length;
    final backgroundColor =
        avatarColors[colorIndex].withAlpha((0.2 * 255).toInt());
    final foregroundColor = avatarColors[colorIndex];

    return CircleAvatar(
      backgroundColor: backgroundColor,
      child: player.avatar == 'default_avatar.png'
          ? Text(
              player.name.isNotEmpty
                  ? String.fromCharCodes(player.name.runes.take(1))
                  : '?',
              style: TextStyle(
                color: foregroundColor,
                fontWeight: FontWeight.bold,
              ),
            )
          : Icon(
              // 使用查找表从预定义图标中获取
              getIconFromCodePoint(int.parse(player.avatar)),
              color: foregroundColor,
            ),
    );
  }
}

/// 根据代码点获取图标
IconData getIconFromCodePoint(int codePoint) {
  // 查找预定义图标
  for (var icon in availablePlayerIcons) {
    if (icon.codePoint == codePoint) {
      return icon;
    }
  }
  // 如果找不到匹配的图标，返回默认图标
  return Icons.person;
}

// 可选择的图标列表
final List<IconData> availablePlayerIcons = [
  Icons.face,
  Icons.pets,
  Icons.sports_esports,
  Icons.emoji_emotions,
  Icons.catching_pokemon,
  Icons.sports_basketball,
  Icons.sports_football,
  Icons.favorite,
  Icons.star,
  Icons.music_note,
  Icons.movie,
  Icons.book,
  Icons.lightbulb,
  Icons.games,
  Icons.cake,
  Icons.paid,
  Icons.emoji_nature,
  Icons.sports_baseball,
  Icons.piano,
  Icons.psychology,
  Icons.science,
  Icons.palette,
  Icons.restaurant,
  Icons.camera,
  Icons.cruelty_free,
  Icons.flutter_dash,
  Icons.spa,
  Icons.eco,
  Icons.forest,
  Icons.waves,
  Icons.water_drop,
  Icons.local_fire_department,
  Icons.cloud,
  Icons.ac_unit,
  Icons.brightness_5,
  Icons.nights_stay,
  Icons.rocket_launch,
  Icons.agriculture,
  Icons.phishing,
  Icons.park,
];

class PlayerListItem extends ConsumerStatefulWidget {
  final TextEditingController? controller;
  final IconData? initialIcon;
  final bool showRemoveButton;
  final VoidCallback? onRemove;
  final PlayerInfo? initialPlayer;
  final Function(PlayerInfo)? onPlayerSaved;

  const PlayerListItem({
    super.key,
    this.controller,
    this.initialIcon,
    this.showRemoveButton = false,
    this.onRemove,
    this.initialPlayer,
    this.onPlayerSaved,
  });

  @override
  ConsumerState<PlayerListItem> createState() => PlayerListItemState();
}

class PlayerListItemState extends ConsumerState<PlayerListItem> {
  late TextEditingController _controller;
  IconData? _selectedIcon;
  bool _isInternalController = false;

  @override
  void initState() {
    super.initState();

    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _isInternalController = true;
      _controller = TextEditingController(
        text: widget.initialPlayer?.name ?? '',
      );
    }

    _selectedIcon = widget.initialIcon ??
        (widget.initialPlayer?.avatar != null &&
                widget.initialPlayer?.avatar != 'default_avatar.png'
            ? getIconFromCodePoint(int.parse(widget.initialPlayer!.avatar))
            : null);
  }

  @override
  void dispose() {
    if (_isInternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  bool hasValidName() {
    return _controller.text.trim().isNotEmpty;
  }

  PlayerInfo getPlayerInfo() {
    return PlayerInfo(
      pid: widget.initialPlayer?.pid,
      name: _controller.text.trim(),
      avatar: _selectedIcon?.codePoint.toString() ?? 'default_avatar.png',
    );
  }

  void _showIconPicker() {
    showIconPicker(context, (icon) {
      setState(() {
        _selectedIcon = icon;
      });
    });
  }

  // 保存玩家数据
  void savePlayer() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    final player = PlayerInfo(
      pid: widget.initialPlayer?.pid,
      name: name,
      avatar: _selectedIcon?.codePoint.toString() ?? 'default_avatar.png',
    );

    if (widget.onPlayerSaved != null) {
      widget.onPlayerSaved!(player);
    } else {
      // 如果没有提供回调，则直接保存到Provider
      final provider = ref.read(playerProvider.notifier);
      if (widget.initialPlayer != null) {
        provider.updatePlayer(player);
      } else {
        provider.addPlayer(player);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 6, 0, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: InkWell(
              onTap: _showIconPicker,
              child: CircleAvatar(
                radius: 24,
                child: _selectedIcon != null
                    ? Icon(_selectedIcon)
                    : Icon(Icons.person),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, child) {
                return TextField(
                  controller: _controller,
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
          if (widget.showRemoveButton && widget.onRemove != null)
            Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: IconButton(
                icon: Icon(Icons.person_remove),
                onPressed: widget.onRemove,
              ),
            ),
        ],
      ),
    );
  }

  // 显示图标选择对话框
  void showIconPicker(BuildContext context, Function(IconData) onIconSelected) {
    globalState.showCommonDialog(
      child: Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '选择头像',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 16),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 60,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: availablePlayerIcons.length,
                  itemBuilder: (context, iconIndex) {
                    return Center(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () {
                            onIconSelected(availablePlayerIcons[iconIndex]);
                            Navigator.of(context).pop();
                          },
                          child: Ink(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              child: Icon(
                                availablePlayerIcons[iconIndex],
                                size: 24,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  '目前头像底色由系统自动分配',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                ),
              ),
              SizedBox(height: 16),
              OverflowBar(
                alignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(), // 取消
                    child: Text('取消'),
                  ),
                  TextButton(
                    onPressed: () {
                      _selectedIcon = null; // 恢复默认头像
                      Navigator.of(context).pop();
                    },
                    child: Text('恢复默认'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
