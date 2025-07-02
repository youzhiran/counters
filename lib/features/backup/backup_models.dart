import 'package:freezed_annotation/freezed_annotation.dart';

part 'backup_models.freezed.dart';
part 'backup_models.g.dart';

/// 备份数据模型
@freezed
sealed class BackupData with _$BackupData {
  const factory BackupData({
    required BackupMetadata metadata,
    required Map<String, dynamic> sharedPreferences,
    required List<DatabaseFile> databases,
  }) = _BackupData;

  factory BackupData.fromJson(Map<String, dynamic> json) =>
      _$BackupDataFromJson(json);
}

/// 备份元数据
@freezed
sealed class BackupMetadata with _$BackupMetadata {
  const factory BackupMetadata({
    required String appVersion,
    required String buildNumber,
    required int timestamp,
    required String platform,
    required int backupCode,
  }) = _BackupMetadata;

  factory BackupMetadata.fromJson(Map<String, dynamic> json) =>
      _$BackupMetadataFromJson(json);
}

/// 数据库文件信息
@freezed
sealed class DatabaseFile with _$DatabaseFile {
  const factory DatabaseFile({
    required String name,
    required String relativePath,
    required int size,
    required String checksum,
  }) = _DatabaseFile;

  factory DatabaseFile.fromJson(Map<String, dynamic> json) =>
      _$DatabaseFileFromJson(json);
}

/// 导入导出状态
@freezed
sealed class BackupState with _$BackupState {
  const factory BackupState({
    @Default(false) bool isLoading,
    @Default(false) bool isExporting,
    @Default(false) bool isImporting,
    @Default(0.0) double progress,
    String? currentOperation,
    String? error,
    String? lastExportPath,
    BackupMetadata? lastImportMetadata,
  }) = _BackupState;
}

/// 版本兼容性检查结果
enum CompatibilityLevel {
  compatible,    // 完全兼容
  warning,       // 可能有问题，但可以导入
  incompatible,  // 不兼容，不建议导入
}

/// 版本兼容性信息
@freezed
sealed class CompatibilityInfo with _$CompatibilityInfo {
  const factory CompatibilityInfo({
    required CompatibilityLevel level,
    required String message,
    List<String>? warnings,
    List<String>? errors,
  }) = _CompatibilityInfo;
}

/// 导入选项
@freezed
sealed class ImportOptions with _$ImportOptions {
  const factory ImportOptions({
    @Default(true) bool importSharedPreferences,
    @Default(true) bool importDatabases,
    @Default(true) bool createBackup,
    @Default(false) bool forceImport,
  }) = _ImportOptions;
}

/// 还原选项
@freezed
sealed class RestoreOptions with _$RestoreOptions {
  const factory RestoreOptions({
    @Default(true) bool restoreSharedPreferences,
    @Default(true) bool restoreDatabases,
    @Default(false) bool forceRestore,
  }) = _RestoreOptions;
}

/// 备份文件信息
@freezed
sealed class BackupFileInfo with _$BackupFileInfo {
  const factory BackupFileInfo({
    required String fileName,
    required String filePath,
    required int fileSize,
    required DateTime createdTime,
    BackupMetadata? metadata,
    String? description,
  }) = _BackupFileInfo;
}

/// 备份文件列表状态
@freezed
sealed class BackupFilesState with _$BackupFilesState {
  const factory BackupFilesState({
    @Default(false) bool isLoading,
    @Default([]) List<BackupFileInfo> backupFiles,
    String? error,
  }) = _BackupFilesState;
}

/// 导出选项
@freezed
sealed class ExportOptions with _$ExportOptions {
  const factory ExportOptions({
    @Default(true) bool includeSharedPreferences,
    @Default(true) bool includeDatabases,
    String? customPath,
    String? customFileName,
  }) = _ExportOptions;
}

/// 文件哈希信息
@freezed
sealed class HashInfo with _$HashInfo {
  const factory HashInfo({
    required String algorithm,
    required String hash,
    required String timestamp,
  }) = _HashInfo;

  factory HashInfo.fromJson(Map<String, dynamic> json) =>
      _$HashInfoFromJson(json);
}

/// 备份预览信息
@freezed
sealed class BackupPreviewInfo with _$BackupPreviewInfo {
  const factory BackupPreviewInfo({
    required BackupMetadata metadata,
    required Map<String, dynamic> dataStatistics,
    required List<String> dataTypes,
    required bool hasHash,
    required bool hashValid,
    String? hashError,
    CompatibilityInfo? compatibilityInfo,
  }) = _BackupPreviewInfo;
}

/// 数据统计信息
@freezed
sealed class DataStatistics with _$DataStatistics {
  const factory DataStatistics({
    @Default(0) int countersCount,
    @Default(0) int mahjongSessionsCount,
    @Default(0) int poker50SessionsCount,
    @Default(0) int templatesCount,
    @Default(0) int sharedPreferencesCount,
    @Default(0) int databaseFilesCount,
  }) = _DataStatistics;
}

/// 预览状态
@freezed
sealed class PreviewState with _$PreviewState {
  const factory PreviewState({
    @Default(false) bool isLoading,
    @Default(false) bool isAnalyzing,
    @Default(false) bool isCheckingCompatibility,
    BackupPreviewInfo? previewInfo,
    String? error,
    String? selectedFilePath,
  }) = _PreviewState;
}
