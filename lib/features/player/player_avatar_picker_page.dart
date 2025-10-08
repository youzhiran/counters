import 'package:counters/app/state.dart';
import 'package:counters/common/utils/error_handler.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlayerAvatarSelectionResult {
  const PlayerAvatarSelectionResult({
    required this.icon,
    required this.emoji,
    required this.color,
    required this.useSystemColor,
  });

  final IconData? icon;
  final String? emoji;
  final Color? color;
  final bool useSystemColor;
}

enum _AvatarType {
  icon,
  emoji,
}

enum _ExitDecision {
  save,
  discard,
  cancel,
}

/// 最近使用的 Emoji 在 SharedPreferences 中的存储键
const String _recentEmojisPrefsKey = 'player_recent_emojis';

/// 最近使用的 Emoji 的最大数量
const int _maxRecentEmojis = 20;

class PlayerAvatarPickerPage extends StatefulWidget {
  const PlayerAvatarPickerPage({
    super.key,
    required this.playerName,
    this.initialIcon,
    this.initialColor,
    this.initialEmoji,
    required this.useSystemColor,
    required this.availableIcons,
    required this.colorPalette,
    required this.systemColor,
  });

  final String playerName;
  final IconData? initialIcon;
  final Color? initialColor;
  final String? initialEmoji;
  final bool useSystemColor;
  final List<IconData> availableIcons;
  final List<Color> colorPalette;
  final Color systemColor;

  @override
  State<PlayerAvatarPickerPage> createState() => _PlayerAvatarPickerPageState();
}

class _PlayerAvatarPickerPageState extends State<PlayerAvatarPickerPage> {
  late IconData? _selectedIcon;
  late bool _useSystemColor;
  Color? _selectedColor;
  late Color _customColor;
  String? _selectedEmoji;
  late _AvatarType _avatarType;
  List<String> _recentEmojis = <String>[];
  late final IconData? _initialIcon;
  late final String? _initialEmoji;
  late final Color? _initialColor;
  late final bool _initialUseSystemColor;

  @override
  void initState() {
    super.initState();
    _selectedIcon = widget.initialIcon;
    _useSystemColor = widget.useSystemColor;
    _selectedColor = widget.initialColor;
    _customColor = widget.initialColor ?? widget.colorPalette.first;
    _selectedEmoji =
        widget.initialEmoji != null && widget.initialEmoji!.isNotEmpty
            ? widget.initialEmoji
            : null;
    if (_selectedEmoji != null) {
      _selectedIcon = null;
    }
    _avatarType =
        _selectedEmoji != null ? _AvatarType.emoji : _AvatarType.icon;
    _initialIcon = widget.initialIcon;
    _initialEmoji = widget.initialEmoji;
    _initialColor = widget.initialColor;
    _initialUseSystemColor = widget.useSystemColor;
    _loadRecentEmojis();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previewLetter = widget.playerName.trim().isNotEmpty
        ? String.fromCharCodes(widget.playerName.trim().runes.take(1))
        : '?';

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('定制玩家头像'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _handleBackPressed,
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _handleSave,
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: _AvatarPreview(
                  primaryColor: _currentPrimaryColor(),
                  backgroundColor: _currentBackgroundColor(),
                  icon: _avatarType == _AvatarType.icon ? _selectedIcon : null,
                  emoji:
                      _avatarType == _AvatarType.emoji ? _selectedEmoji : null,
                  previewLetter: previewLetter,
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Text('头像类型', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    SegmentedButton<_AvatarType>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: _AvatarType.icon,
                          label: Text('图标'),
                          icon: Icon(Icons.apps),
                        ),
                        ButtonSegment(
                          value: _AvatarType.emoji,
                          label: Text('Emoji'),
                          icon: Icon(Icons.emoji_emotions),
                        ),
                      ],
                      selected: {_avatarType},
                      onSelectionChanged: (selection) {
                        setState(() {
                          _avatarType = selection.first;
                          if (_avatarType == _AvatarType.icon) {
                            _selectedEmoji = null;
                          } else {
                            _selectedIcon = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_avatarType == _AvatarType.icon) ...[
                      Text('选择图标', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      _buildIconGrid(theme),
                    ] else ...[
                      Text('最近使用的 Emoji', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      _buildEmojiSection(theme),
                    ],
                    const SizedBox(height: 24),
                    Text('系统默认底色', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _buildSystemColorTile(theme),
                    const SizedBox(height: 24),
                    Text('推荐配色', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _buildColorPalette(theme),
                    const SizedBox(height: 16),
                    Text(
                      '选择推荐配色或使用系统底色，也可以通过拾色器自定义喜欢的颜色。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCustomColorSection(theme),
                    const SizedBox(height: 24),
                    _buildFooterActions(theme),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 从 SharedPreferences 加载最近使用的 Emoji 列表
  Future<void> _loadRecentEmojis() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_recentEmojisPrefsKey) ?? <String>[];
      final normalized = <String>[];
      for (final emoji in stored) {
        final value = emoji.trim();
        if (value.isEmpty) {
          continue;
        }
        if (normalized.contains(value)) {
          continue;
        }
        normalized.add(value);
        if (normalized.length >= _maxRecentEmojis) {
          break;
        }
      }
      if (!mounted) return;
      setState(() {
        _recentEmojis = normalized;
      });
    } catch (e, stackTrace) {
      ErrorHandler.handle(
        e,
        stackTrace,
        prefix: '加载最近使用的 Emoji 失败',
      );
    }
  }

  /// 记录 Emoji 使用，并更新最近使用列表
  Future<void> _saveRecentEmoji(String emoji) async {
    final value = emoji.trim();
    if (value.isEmpty) return;

    var updated = <String>[
      value,
      ..._recentEmojis.where((item) => item != value)
    ];
    if (updated.length > _maxRecentEmojis) {
      updated = updated.sublist(0, _maxRecentEmojis);
    }

    if (mounted) {
      setState(() {
        _recentEmojis = updated;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentEmojisPrefsKey, updated);
    } catch (e, stackTrace) {
      ErrorHandler.handle(
        e,
        stackTrace,
        prefix: '保存最近使用的 Emoji 失败',
      );
    }
  }

  /// 统一处理 Emoji 选中后的状态更新
  void _applyEmojiSelection(String emoji) {
    setState(() {
      _selectedEmoji = emoji;
      _selectedIcon = null;
      _avatarType = _AvatarType.emoji;
    });
  }

  Future<void> _clearRecentEmojis() async {
    if (_recentEmojis.isEmpty) {
      return;
    }
    final confirm = await globalState.showCommonDialog<bool>(
      child: Builder(
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('清空最近使用'),
            content: const Text('确定要清空最近使用的 Emoji 吗？此操作无法撤销。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('确定'),
              ),
            ],
          );
        },
      ),
    );
    if (confirm != true) {
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentEmojisPrefsKey);
    } catch (e, stackTrace) {
      ErrorHandler.handle(
        e,
        stackTrace,
        prefix: '清空最近使用的 Emoji 失败',
      );
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _recentEmojis = <String>[];
    });
  }

  Widget _buildIconGrid(ThemeData theme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.availableIcons.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 60,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final iconData = widget.availableIcons[index];
        final isSelected =
            _avatarType == _AvatarType.icon &&
                _selectedIcon?.codePoint == iconData.codePoint;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              setState(() {
                _selectedIcon = iconData;
                _selectedEmoji = null;
                _avatarType = _AvatarType.icon;
              });
            },
            child: Ink(
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(
                        color: theme.colorScheme.primary,
                        width: 2,
                      )
                    : null,
              ),
              child: Icon(
                iconData,
                size: 26,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmojiSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _showCustomEmojiDialog,
              icon: const Icon(Icons.edit),
              label: const Text('自定义 Emoji'),
            ),
            OutlinedButton.icon(
              onPressed: _recentEmojis.isEmpty ? null : _clearRecentEmojis,
              icon: const Icon(Icons.delete_sweep),
              label: const Text('清空历史'),
            ),
            if (_selectedEmoji != null && _selectedEmoji!.isNotEmpty)
              Text(
                '当前选择：$_selectedEmoji',
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentEmojis.isEmpty)
          Text(
            '暂无最近使用的 Emoji，尝试自定义或从其他输入法粘贴。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentEmojis.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 60,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final emoji = _recentEmojis[index];
              final isSelected =
                  _avatarType == _AvatarType.emoji && _selectedEmoji == emoji;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () async {
                    _applyEmojiSelection(emoji);
                    await _saveRecentEmoji(emoji);
                  },
                  child: Ink(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: theme.colorScheme.primary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Future<void> _showCustomEmojiDialog() async {
    final controller = TextEditingController(text: _selectedEmoji ?? '');
    String? errorText;

    final result = await globalState.showCommonDialog<String>(
      child: AlertDialog(
        title: const Text('输入自定义 Emoji'),
        content: StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: '粘贴或输入 Emoji',
                      errorText: errorText,
                    ),
                    autofocus: true,
                    maxLength: 1,
                    onSubmitted: (_) {
                      final parsed = _normalizeEmoji(controller.text);
                      if (parsed != null) {
                        Navigator.of(dialogContext).pop(parsed);
                      } else {
                        setDialogState(() {
                          errorText = '请输入有效的 Emoji';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('取消'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          final parsed = _normalizeEmoji(controller.text);
                          if (parsed != null) {
                            Navigator.of(dialogContext).pop(parsed);
                          } else {
                            setDialogState(() {
                              errorText = '请输入有效的 Emoji';
                            });
                          }
                        },
                        child: const Text('确定'),
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

    controller.dispose();

    if (result != null && result.isNotEmpty) {
      setState(() {
        _selectedEmoji = result;
        _selectedIcon = null;
        _avatarType = _AvatarType.emoji;
      });
      await _saveRecentEmoji(result);
    }
  }

  bool _iconEquals(IconData? a, IconData? b) {
    if (a == null || b == null) {
      return a == b;
    }
    return a.codePoint == b.codePoint &&
        a.fontFamily == b.fontFamily &&
        a.matchTextDirection == b.matchTextDirection;
  }

  bool _colorEquals(Color? a, Color? b) {
    if (a == null || b == null) {
      return a == b;
    }
    return a.value == b.value;
  }

  bool get _hasUnsavedChanges {
    final currentIcon = _avatarType == _AvatarType.icon ? _selectedIcon : null;
    final currentEmoji =
        _avatarType == _AvatarType.emoji ? _selectedEmoji : null;
    final currentUseSystemColor = _useSystemColor;
    final currentColor =
        currentUseSystemColor ? null : (_selectedColor ?? _customColor);

    final initialEmoji = (_initialEmoji != null && _initialEmoji!.isNotEmpty)
        ? _initialEmoji
        : null;
    final initialIcon = initialEmoji == null ? _initialIcon : null;
    final initialUseSystemColor = _initialUseSystemColor;
    final initialColor = initialUseSystemColor ? null : _initialColor;

    if (!_iconEquals(currentIcon, initialIcon)) {
      return true;
    }
    if (currentEmoji != initialEmoji) {
      return true;
    }
    if (currentUseSystemColor != initialUseSystemColor) {
      return true;
    }
    if (!_colorEquals(currentColor, initialColor)) {
      return true;
    }
    return false;
  }

  Future<_ExitDecision?> _showUnsavedChangesDialog() {
    return globalState.showCommonDialog<_ExitDecision>(
      child: Builder(
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('尚未保存的更改'),
            content: const Text('检测到头像设置已修改但尚未保存，是否需要保存？'),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(_ExitDecision.cancel),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(_ExitDecision.discard),
                child: const Text('不保存'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(_ExitDecision.save),
                child: const Text('保存'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) {
      return true;
    }
    final decision = await _showUnsavedChangesDialog();
    if (decision == _ExitDecision.save) {
      _handleSave();
      return false;
    }
    if (decision == _ExitDecision.discard) {
      return true;
    }
    return false;
  }

  Future<void> _handleBackPressed() async {
    final shouldPop = await _onWillPop();
    if (shouldPop && mounted) {
      Navigator.of(context).pop();
    }
  }

  String? _normalizeEmoji(String input) {
    final value = input.trim();
    if (value.isEmpty) return null;
    final runes = value.runes.toList();
    if (runes.isEmpty) return null;
    final buffer = StringBuffer();
    for (final rune in runes) {
      final char = String.fromCharCode(rune);
      if (_isLikelyEmoji(rune)) {
        buffer.write(char);
      }
    }
    final normalized = buffer.toString();
    return normalized.isNotEmpty ? normalized : null;
  }

  bool _isLikelyEmoji(int rune) {
    return (rune >= 0x1F300 && rune <= 0x1FAFF) ||
        (rune >= 0x1F600 && rune <= 0x1F64F) ||
        (rune >= 0x1F680 && rune <= 0x1F6FF) ||
        (rune >= 0x2600 && rune <= 0x27BF) ||
        (rune >= 0x1F900 && rune <= 0x1F9FF) ||
        (rune >= 0x1F1E6 && rune <= 0x1F1FF) ||
        (rune >= 0x2700 && rune <= 0x27BF) ||
        rune == 0x2764 ||
        rune == 0xFE0F;
  }

  Widget _buildSystemColorTile(ThemeData theme) {
    final systemPrimary = widget.systemColor;
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: _useSystemColor,
      onChanged: (value) {
        setState(() {
          _useSystemColor = value;
        });
      },
      title: const Text('根据玩家ID自动匹配'),
      subtitle: const Text('适用于快速识别，保持系统统一风格'),
      secondary: CircleAvatar(
        backgroundColor: systemPrimary.withOpacity(0.2),
        child: Icon(Icons.palette, color: systemPrimary),
      ),
    );
  }

  Widget _buildColorPalette(ThemeData theme) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final color in widget.colorPalette)
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                setState(() {
                  _selectedColor = color;
                  _useSystemColor = false;
                });
              },
              child: Ink(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: _ColorIndicator(
                  color: color,
                  isSelected: !_useSystemColor &&
                      _selectedColor?.value == color.value,
                  borderColor: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCustomColorSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _showCustomColorDialog,
              icon: const Icon(Icons.colorize),
              label: const Text('打开拾色器'),
            ),
            const SizedBox(width: 12),
            _ColorIndicator(
              color: _useSystemColor
                  ? widget.systemColor
                  : (_selectedColor ?? _customColor),
              isSelected: !_useSystemColor,
              showCheck: false,
              size: 44,
              borderColor: theme.colorScheme.outlineVariant,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _useSystemColor
              ? '当前使用系统底色'
              : '自定义颜色：${_colorToHex(_selectedColor ?? _customColor)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFooterActions(ThemeData theme) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        OutlinedButton(
          onPressed: () {
            setState(() {
              _selectedIcon = null;
              _selectedEmoji = null;
              _avatarType = _AvatarType.icon;
            });
          },
          child: const Text('恢复默认图标'),
        ),
        OutlinedButton(
          onPressed: () {
            setState(() {
              _useSystemColor = true;
            });
          },
          child: const Text('恢复默认底色'),
        ),
      ],
    );
  }

  void _handleSave() {
    final effectiveColor =
        _useSystemColor ? null : (_selectedColor ?? _customColor);
    Navigator.of(context).pop(
      PlayerAvatarSelectionResult(
        icon: _avatarType == _AvatarType.icon ? _selectedIcon : null,
        emoji: _avatarType == _AvatarType.emoji ? _selectedEmoji : null,
        color: effectiveColor,
        useSystemColor: _useSystemColor,
      ),
    );
  }

  Color _currentPrimaryColor() {
    if (_useSystemColor) {
      return widget.systemColor;
    }
    return _selectedColor ?? _customColor;
  }

  Color _currentBackgroundColor() {
    return _currentPrimaryColor().withOpacity(0.18);
  }

  Future<void> _showCustomColorDialog() async {
    final baseColor = _selectedColor ?? _customColor;
    int red = baseColor.red;
    int green = baseColor.green;
    int blue = baseColor.blue;

    final pickedColor = await globalState.showCommonDialog<Color>(
      child: AlertDialog(
        title: const Text('自定义颜色'),
        content: StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> showHexInput(Color currentColor) async {
              final controller =
                  TextEditingController(text: _colorToHex(currentColor));
              String? errorText;
              final result = await globalState.showCommonDialog<Color>(
                child: AlertDialog(
                  title: const Text('输入颜色代码'),
                  content: StatefulBuilder(
                    builder: (hexContext, setHexState) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                labelText: '十六进制颜色值',
                                hintText: '例如：#1A73E8 或 1A73E8',
                                errorText: errorText,
                              ),
                              autofocus: true,
                              maxLength: 9,
                              onSubmitted: (_) {
                                final parsed =
                                    _parseHexColor(controller.text);
                                if (parsed != null) {
                                  Navigator.of(hexContext).pop(parsed);
                                } else {
                                  setHexState(() {
                                    errorText = '请输入有效的颜色值';
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(hexContext).pop(),
                                  child: const Text('取消'),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed: () {
                                    final parsed =
                                        _parseHexColor(controller.text);
                                    if (parsed != null) {
                                      Navigator.of(hexContext).pop(parsed);
                                    } else {
                                      setHexState(() {
                                        errorText = '请输入有效的颜色值';
                                      });
                                    }
                                  },
                                  child: const Text('确定'),
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

              controller.dispose();

              if (result != null) {
                setDialogState(() {
                  red = result.red;
                  green = result.green;
                  blue = result.blue;
                });
              }
            }

            final previewColor = Color.fromARGB(255, red, green, blue);
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => showHexInput(previewColor),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: previewColor,
                      child: Text(
                        _colorToHex(previewColor),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildColorSlider(
                    label: 'R',
                    value: red.toDouble(),
                    activeColor: Colors.red,
                    onChanged: (value) {
                      setDialogState(() {
                        red = value.toInt();
                      });
                    },
                  ),
                  _buildColorSlider(
                    label: 'G',
                    value: green.toDouble(),
                    activeColor: Colors.green,
                    onChanged: (value) {
                      setDialogState(() {
                        green = value.toInt();
                      });
                    },
                  ),
                  _buildColorSlider(
                    label: 'B',
                    value: blue.toDouble(),
                    activeColor: Colors.blue,
                    onChanged: (value) {
                      setDialogState(() {
                        blue = value.toInt();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 12,
                      children: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(),
                          child: const Text('取消'),
                        ),
                        FilledButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop(
                              Color.fromARGB(255, red, green, blue),
                            );
                          },
                          child: const Text('确定'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    if (pickedColor != null) {
      setState(() {
        _selectedColor = pickedColor;
        _customColor = pickedColor;
        _useSystemColor = false;
      });
    }
  }

  Widget _buildColorSlider({
    required String label,
    required double value,
    required Color activeColor,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Slider(
            min: 0,
            max: 255,
            divisions: 255,
            value: value,
            activeColor: activeColor,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(value.toInt().toString()),
        ),
      ],
    );
  }

  String _colorToHex(Color color) =>
      '#${color.value.toRadixString(16).substring(2).toUpperCase()}';

  Color? _parseHexColor(String input) {
    final raw = input.trim();
    if (raw.isEmpty) return null;
    var hex = raw.startsWith('#') ? raw.substring(1) : raw;
    if (hex.length == 3) {
      hex = hex.split('').map((c) => '$c$c').join();
    }
    if (hex.length == 6) {
      final parsed = int.tryParse(hex, radix: 16);
      if (parsed != null) {
        return Color(0xFF000000 | parsed);
      }
    } else if (hex.length == 8) {
      final parsed = int.tryParse(hex, radix: 16);
      if (parsed != null) {
        return Color(parsed);
      }
    }
    return null;
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({
    required this.primaryColor,
    required this.backgroundColor,
    required this.previewLetter,
    this.emoji,
    this.icon,
  });

  final Color primaryColor;
  final Color backgroundColor;
  final String? emoji;
  final IconData? icon;
  final String previewLetter;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: backgroundColor,
          child: icon != null
              ? Icon(icon, color: primaryColor, size: 36)
              : emoji != null && emoji!.isNotEmpty
                  ? Text(
                      emoji!,
                      style: const TextStyle(fontSize: 36),
                    )
                  : Text(
                      previewLetter,
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
        ),
        const SizedBox(height: 12),
        Text(
          '实时预览',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _ColorIndicator extends StatelessWidget {
  const _ColorIndicator({
    required this.color,
    required this.isSelected,
    required this.borderColor,
    this.size = 44,
    this.showCheck = true,
  });

  final Color color;
  final bool isSelected;
  final Color borderColor;
  final double size;
  final bool showCheck;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(
                  color: borderColor,
                  width: 2,
                )
              : null,
        ),
        child: Container(
          margin: EdgeInsets.all(isSelected ? 2 : 0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
          child: isSelected && showCheck
              ? const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                )
              : null,
        ),
      ),
    );
  }
}
