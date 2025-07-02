// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$backupManagerHash() => r'b0cd3eb81a241bb449cb7230a558d8189a4e1d52';

/// 备份状态管理
///
/// Copied from [BackupManager].
@ProviderFor(BackupManager)
final backupManagerProvider =
    AutoDisposeNotifierProvider<BackupManager, BackupState>.internal(
  BackupManager.new,
  name: r'backupManagerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$backupManagerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BackupManager = AutoDisposeNotifier<BackupState>;
String _$exportOptionsManagerHash() =>
    r'3ed7a6d372f1858d6dab18f7817bc62df510b3ee';

/// 导出选项提供者
///
/// Copied from [ExportOptionsManager].
@ProviderFor(ExportOptionsManager)
final exportOptionsManagerProvider =
    AutoDisposeNotifierProvider<ExportOptionsManager, ExportOptions>.internal(
  ExportOptionsManager.new,
  name: r'exportOptionsManagerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$exportOptionsManagerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ExportOptionsManager = AutoDisposeNotifier<ExportOptions>;
String _$importOptionsManagerHash() =>
    r'd1d5100c69ab26dab41ac6b5ad01b3583951842b';

/// 导入选项提供者
///
/// Copied from [ImportOptionsManager].
@ProviderFor(ImportOptionsManager)
final importOptionsManagerProvider =
    AutoDisposeNotifierProvider<ImportOptionsManager, ImportOptions>.internal(
  ImportOptionsManager.new,
  name: r'importOptionsManagerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$importOptionsManagerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ImportOptionsManager = AutoDisposeNotifier<ImportOptions>;
String _$restoreOptionsManagerHash() =>
    r'c4327712864364170444e24f3afb0612aa41b7f2';

/// 还原选项提供者
///
/// Copied from [RestoreOptionsManager].
@ProviderFor(RestoreOptionsManager)
final restoreOptionsManagerProvider =
    AutoDisposeNotifierProvider<RestoreOptionsManager, RestoreOptions>.internal(
  RestoreOptionsManager.new,
  name: r'restoreOptionsManagerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$restoreOptionsManagerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$RestoreOptionsManager = AutoDisposeNotifier<RestoreOptions>;
String _$backupFilesManagerHash() =>
    r'0a57fd29fd41def38ad9ce6ecc330da54730c4f3';

/// 备份文件管理器
///
/// Copied from [BackupFilesManager].
@ProviderFor(BackupFilesManager)
final backupFilesManagerProvider =
    AutoDisposeNotifierProvider<BackupFilesManager, BackupFilesState>.internal(
  BackupFilesManager.new,
  name: r'backupFilesManagerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$backupFilesManagerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BackupFilesManager = AutoDisposeNotifier<BackupFilesState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
