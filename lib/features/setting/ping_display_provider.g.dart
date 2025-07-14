// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ping_display_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pingDisplaySettingHash() =>
    r'e499a0eee811f2768918d4896c839939a68647f4';

/// PingWidget 显示设置 Provider
/// 控制是否在计分界面显示 PingWidget
///
/// Copied from [PingDisplaySetting].
@ProviderFor(PingDisplaySetting)
final pingDisplaySettingProvider =
    NotifierProvider<PingDisplaySetting, bool>.internal(
  PingDisplaySetting.new,
  name: r'pingDisplaySettingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pingDisplaySettingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PingDisplaySetting = Notifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
