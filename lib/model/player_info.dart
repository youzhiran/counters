import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'player_info.g.dart';

@HiveType(typeId: 1)
class PlayerInfo {
  @HiveField(0)
  final String id;

  @HiveField(1, defaultValue: '未知玩家')
  String name;

  @HiveField(2, defaultValue: 'default_avatar.png')
  String avatar;

  PlayerInfo({
    String? id,
    required this.name,
    required this.avatar,
  }) : id = id ?? Uuid().v4();

  PlayerInfo copyWith({
    String? id, // 添加 id 参数
    String? name,
    String? avatar,
  }) {
    return PlayerInfo(
      id: id ?? this.id, // 允许覆盖 ID
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
    );
  }
}
