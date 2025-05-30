// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlayerInfo {
  String get pid;
  String get name;
  String get avatar;

  /// Create a copy of PlayerInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PlayerInfoCopyWith<PlayerInfo> get copyWith =>
      _$PlayerInfoCopyWithImpl<PlayerInfo>(this as PlayerInfo, _$identity);

  /// Serializes this PlayerInfo to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PlayerInfo &&
            (identical(other.pid, pid) || other.pid == pid) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.avatar, avatar) || other.avatar == avatar));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, pid, name, avatar);

  @override
  String toString() {
    return 'PlayerInfo(pid: $pid, name: $name, avatar: $avatar)';
  }
}

/// @nodoc
abstract mixin class $PlayerInfoCopyWith<$Res> {
  factory $PlayerInfoCopyWith(
          PlayerInfo value, $Res Function(PlayerInfo) _then) =
      _$PlayerInfoCopyWithImpl;
  @useResult
  $Res call({String pid, String name, String avatar});
}

/// @nodoc
class _$PlayerInfoCopyWithImpl<$Res> implements $PlayerInfoCopyWith<$Res> {
  _$PlayerInfoCopyWithImpl(this._self, this._then);

  final PlayerInfo _self;
  final $Res Function(PlayerInfo) _then;

  /// Create a copy of PlayerInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pid = null,
    Object? name = null,
    Object? avatar = null,
  }) {
    return _then(_self.copyWith(
      pid: null == pid
          ? _self.pid
          : pid // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      avatar: null == avatar
          ? _self.avatar
          : avatar // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _PlayerInfo extends PlayerInfo {
  const _PlayerInfo(
      {required this.pid, required this.name, required this.avatar})
      : super._();
  factory _PlayerInfo.fromJson(Map<String, dynamic> json) =>
      _$PlayerInfoFromJson(json);

  @override
  final String pid;
  @override
  final String name;
  @override
  final String avatar;

  /// Create a copy of PlayerInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PlayerInfoCopyWith<_PlayerInfo> get copyWith =>
      __$PlayerInfoCopyWithImpl<_PlayerInfo>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PlayerInfoToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PlayerInfo &&
            (identical(other.pid, pid) || other.pid == pid) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.avatar, avatar) || other.avatar == avatar));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, pid, name, avatar);

  @override
  String toString() {
    return 'PlayerInfo._internal(pid: $pid, name: $name, avatar: $avatar)';
  }
}

/// @nodoc
abstract mixin class _$PlayerInfoCopyWith<$Res>
    implements $PlayerInfoCopyWith<$Res> {
  factory _$PlayerInfoCopyWith(
          _PlayerInfo value, $Res Function(_PlayerInfo) _then) =
      __$PlayerInfoCopyWithImpl;
  @override
  @useResult
  $Res call({String pid, String name, String avatar});
}

/// @nodoc
class __$PlayerInfoCopyWithImpl<$Res> implements _$PlayerInfoCopyWith<$Res> {
  __$PlayerInfoCopyWithImpl(this._self, this._then);

  final _PlayerInfo _self;
  final $Res Function(_PlayerInfo) _then;

  /// Create a copy of PlayerInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? pid = null,
    Object? name = null,
    Object? avatar = null,
  }) {
    return _then(_PlayerInfo(
      pid: null == pid
          ? _self.pid
          : pid // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      avatar: null == avatar
          ? _self.avatar
          : avatar // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
