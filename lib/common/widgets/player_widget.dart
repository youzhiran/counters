import 'package:counters/common/model/player_info.dart';
import 'package:counters/features/player/player_avatar_picker_page.dart';
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

  /// 将数据库中存储的颜色字符串转换为 [Color]
  static Color? tryParseColor(String? colorValue) {
    if (colorValue == null || colorValue.isEmpty) {
      return null;
    }
    final parsed = int.tryParse(colorValue);
    if (parsed == null) {
      return null;
    }
    return Color(parsed);
  }

  /// 将 [Color] 转换为数据库可存储的字符串
  static String? colorToStorageValue(Color? color) {
    return color?.value.toString();
  }

  /// 解析玩家头像的主色调，如无自定义则退回到哈希计算的默认色
  static Color resolvePrimaryColor(PlayerInfo player) {
    final storedColor = tryParseColor(player.avatarColor);
    if (storedColor != null) {
      return storedColor;
    }
    final colorIndex = player.pid.hashCode.abs() % avatarColors.length;
    return avatarColors[colorIndex];
  }

  /// 根据指定透明度生成头像背景色，主要用于保持统一的视觉风格
  static Color resolveBackgroundColor(
    PlayerInfo player, {
    double opacity = 0.2,
  }) {
    final safeOpacity = opacity.clamp(0.0, 1.0);
    return resolvePrimaryColor(player).withOpacity(safeOpacity);
  }

  /// 创建玩家头像组件
  static Widget build(BuildContext context, PlayerInfo player) {
    final foregroundColor = resolvePrimaryColor(player);
    final backgroundColor = resolveBackgroundColor(player);
    final iconCodePoint = int.tryParse(player.avatar);
    final isDefault = player.avatar == 'default_avatar.png';
    final isEmoji = !isDefault && iconCodePoint == null;

    return CircleAvatar(
      backgroundColor: backgroundColor,
      child: isDefault
          ? Text(
              player.name.isNotEmpty
                  ? String.fromCharCodes(player.name.runes.take(1))
                  : '?',
              style: TextStyle(
                color: foregroundColor,
                fontWeight: FontWeight.bold,
              ),
            )
          : isEmoji
              ? Text(
                  player.avatar,
                  style: const TextStyle(fontSize: 24),
                )
              : Icon(
                  // 使用查找表从预定义图标中获取
                  getIconFromCodePoint(
                    iconCodePoint ?? Icons.person.codePoint,
                  ),
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
  String? _selectedEmoji;
  Color? _selectedColor;
  bool _useSystemColor = false;
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

    _selectedIcon = widget.initialIcon;
    _selectedEmoji = null;
    final initialAvatar = widget.initialPlayer?.avatar;
    if (initialAvatar != null && initialAvatar != 'default_avatar.png') {
      final iconCodePoint = int.tryParse(initialAvatar);
      if (iconCodePoint != null) {
        _selectedIcon = getIconFromCodePoint(iconCodePoint);
      } else {
        _selectedEmoji = initialAvatar;
        _selectedIcon = null;
      }
    }

    _selectedColor =
        PlayerAvatar.tryParseColor(widget.initialPlayer?.avatarColor);
    _useSystemColor = widget.initialPlayer?.avatarColor == null;
    if (_selectedColor != null) {
      _useSystemColor = false;
    }
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
    final trimmedName = _controller.text.trim();
    String avatarValue;
    if (_selectedEmoji != null && _selectedEmoji!.isNotEmpty) {
      avatarValue = _selectedEmoji!;
    } else if (_selectedIcon != null) {
      avatarValue = _selectedIcon!.codePoint.toString();
    } else {
      avatarValue = 'default_avatar.png';
    }
    final colorValue = _useSystemColor
        ? null
        : PlayerAvatar.colorToStorageValue(
            _selectedColor ??
                PlayerAvatar.tryParseColor(widget.initialPlayer?.avatarColor),
          );

    return PlayerInfo(
      pid: widget.initialPlayer?.pid,
      name: trimmedName,
      avatar: avatarValue,
      avatarColor: colorValue,
    );
  }

  Future<void> _openAvatarPicker() async {
    final result =
        await Navigator.of(context).push<PlayerAvatarSelectionResult>(
      MaterialPageRoute(
        builder: (_) => PlayerAvatarPickerPage(
          playerName: _controller.text.trim(),
          initialIcon: _selectedIcon,
          initialColor: _selectedColor ??
              PlayerAvatar.tryParseColor(widget.initialPlayer?.avatarColor),
          initialEmoji: _selectedEmoji,
          useSystemColor: _useSystemColor,
          availableIcons: availablePlayerIcons,
          colorPalette: PlayerAvatar.avatarColors,
          systemColor: _systemColorPreview(),
        ),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      _selectedIcon = result.icon;
      _selectedEmoji = result.emoji;
      _useSystemColor = result.useSystemColor;
      if (_selectedEmoji != null) {
        _selectedIcon = null;
      }
      if (_selectedIcon != null) {
        _selectedEmoji = null;
      }
      if (result.useSystemColor) {
        _selectedColor = null;
      } else {
        _selectedColor = result.color ??
            PlayerAvatar.tryParseColor(widget.initialPlayer?.avatarColor) ??
            _selectedColor;
      }
    });
  }

  // 保存玩家数据
  void savePlayer() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    final player = getPlayerInfo();

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
              onTap: _openAvatarPicker,
              borderRadius: BorderRadius.circular(24),
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, _) {
                  final primaryColor = _primaryColorForPreview();
                  final backgroundColor = _backgroundColorForPreview();
                  final trimmed = value.text.trim();
                  final displayText = trimmed.isNotEmpty
                      ? String.fromCharCodes(trimmed.runes.take(1))
                      : '?';
                  return CircleAvatar(
                    radius: 24,
                    backgroundColor: backgroundColor,
                    child: _selectedIcon != null
                        ? Icon(
                            _selectedIcon,
                            color: primaryColor,
                          )
                        : (_selectedEmoji != null &&
                                _selectedEmoji!.isNotEmpty)
                            ? Text(
                                _selectedEmoji!,
                                style: const TextStyle(fontSize: 24),
                              )
                            : Text(
                                displayText,
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                  );
                },
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

  /// 计算系统默认底色预览值
  Color _systemColorPreview() {
    if (widget.initialPlayer != null) {
      return PlayerAvatar.resolvePrimaryColor(
        widget.initialPlayer!.copyWith(avatarColor: null),
      );
    }
    return PlayerAvatar.avatarColors.first;
  }

  /// 预览状态下计算头像主色，用于渲染示意图
  Color _primaryColorForPreview() {
    if (_useSystemColor) {
      return _systemColorPreview();
    }
    return _selectedColor ??
        PlayerAvatar.tryParseColor(widget.initialPlayer?.avatarColor) ??
        PlayerAvatar.avatarColors.first;
  }

  /// 预览状态下计算头像背景色
  Color _backgroundColorForPreview({double opacity = 0.2}) {
    final safeOpacity = opacity.clamp(0.0, 1.0);
    return _primaryColorForPreview().withOpacity(safeOpacity);
  }
}
