import 'package:uuid/uuid.dart';

class PlayerInfo {
  final String id;
  String name;
  String avatar;

  PlayerInfo({
    String? id,
    required this.name,
    required this.avatar,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
    };
  }

  static PlayerInfo fromMap(Map<String, dynamic> map) {
    return PlayerInfo(
      id: map['id'],
      name: map['name'],
      avatar: map['avatar'],
    );
  }

  PlayerInfo copyWith({
    String? id,
    String? name,
    String? avatar,
  }) {
    return PlayerInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
    );
  }
}
