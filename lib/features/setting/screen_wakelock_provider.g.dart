// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'screen_wakelock_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$screenWakelockSettingHash() =>
    r'b64c7cc7d4e20705b09bf57a303047ca6c6d619e';

/// 屏幕常亮设置 Provider
/// 控制计分时是否保持屏幕常亮，支持所有平台
///
/// Copied from [ScreenWakelockSetting].
@ProviderFor(ScreenWakelockSetting)
final screenWakelockSettingProvider =
    NotifierProvider<ScreenWakelockSetting, ScreenWakelockState>.internal(
  ScreenWakelockSetting.new,
  name: r'screenWakelockSettingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$screenWakelockSettingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ScreenWakelockSetting = Notifier<ScreenWakelockState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
