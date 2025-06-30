// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$backupManagerHash() => r'f651cac5454024ef522bae491f0408ed4398e5ca';

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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
