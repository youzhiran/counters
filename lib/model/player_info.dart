import 'package:uuid/uuid.dart';

class PlayerInfo {
  final String pid;
  String name;
  String avatar;

  PlayerInfo({
    String? pid,
    required this.name,
    required this.avatar,
  }) : pid = pid ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'pid': pid,
      'name': name,
      'avatar': avatar,
    };
  }

  static PlayerInfo fromMap(Map<String, dynamic> map) {
    return PlayerInfo(
      pid: map['pid'],
      name: map['name'],
      avatar: map['avatar'],
    );
  }

  PlayerInfo copyWith({
    String? pid,
    String? name,
    String? avatar,
  }) {
    return PlayerInfo(
      pid: pid ?? this.pid,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
    );
  }
}
