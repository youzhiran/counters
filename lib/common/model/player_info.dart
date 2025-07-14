import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'player_info.freezed.dart';
part 'player_info.g.dart';

@freezed
abstract class PlayerInfo with _$PlayerInfo {
  const PlayerInfo._(); // 添加私有构造函数以支持自定义方法

  const factory PlayerInfo.internal({
    required String pid,
    required String name,
    required String avatar,
  }) = _PlayerInfo;

  factory PlayerInfo({
    String? pid,
    required String name,
    required String avatar,
  }) {
    return PlayerInfo.internal(
      pid: pid ?? Uuid().v4(),
      name: name,
      avatar: avatar,
    );
  }

  factory PlayerInfo.fromJson(Map<String, dynamic> json) =>
      _$PlayerInfoFromJson(json);
}
