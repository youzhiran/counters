import 'dart:io';

import 'package:counters/common/utils/error_handler.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/features/backup/backup_models.dart';
import 'package:counters/features/backup/backup_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'backup_provider.g.dart';

/// 备份状态管理
@riverpod
class BackupManager extends _$BackupManager {
  @override
  BackupState build() {
    return const BackupState();
  }

  /// 导出数据
  Future<String?> exportData({ExportOptions? options}) async {
    try {
      state = state.copyWith(
        isLoading: true,
        isExporting: true,
        progress: 0.0,
        error: null,
      );

      // 检查权限
      if (!await _checkPermissions()) {
        throw Exception('缺少必要的文件访问权限');
      }

      final exportOptions = options ?? const ExportOptions();

      final exportPath = await BackupService.exportData(
        options: exportOptions,
        onProgress: (message, progress) {
          Log.v('导出进度: $message ($progress)');
          state = state.copyWith(
            currentOperation: message,
            progress: progress,
          );
        },
      );

      state = state.copyWith(
        isLoading: false,
        isExporting: false,
        progress: 1.0,
        currentOperation: '导出完成',
        lastExportPath: exportPath,
      );

      return exportPath;
    } catch (e, stackTrace) {
      Log.e('导出失败: $e');
      state = state.copyWith(
        isLoading: false,
        isExporting: false,
        error: e.toString(),
        currentOperation: null,
      );
      ErrorHandler.handle(e, stackTrace, prefix: '数据导出失败');
      return null;
    }
  }

  /// 导入数据
  Future<bool> importData({
    String? filePath,
    ImportOptions? options,
  }) async {
    try {
      state = state.copyWith(
        isLoading: true,
        isImporting: true,
        progress: 0.0,
        error: null,
      );

      // 选择文件（如果未提供路径）
      String? selectedPath = filePath;
      if (selectedPath == null) {
        selectedPath = await _selectImportFile();
        if (selectedPath == null) {
          state = state.copyWith(
            isLoading: false,
            isImporting: false,
          );
          return false;
        }
      }

      // 检查权限
      if (!await _checkPermissions()) {
        throw Exception('缺少必要的文件访问权限');
      }

      final importOptions = options ?? const ImportOptions();

      await BackupService.importData(
        zipPath: selectedPath,
        options: importOptions,
        onProgress: (message, progress) {
          Log.v('导入进度: $message ($progress)');
          state = state.copyWith(
            currentOperation: message,
            progress: progress,
          );
        },
      );

      state = state.copyWith(
        isLoading: false,
        isImporting: false,
        progress: 1.0,
        currentOperation: '导入完成',
      );

      return true;
    } catch (e, stackTrace) {
      Log.e('导入失败: $e');
      state = state.copyWith(
        isLoading: false,
        isImporting: false,
        error: e.toString(),
        currentOperation: null,
      );
      ErrorHandler.handle(e, stackTrace, prefix: '数据导入失败');
      return false;
    }
  }

  /// 从指定文件导入数据（用于预览后的导入）
  Future<bool> importDataFromFile(
    String filePath, {
    ImportOptions? options,
  }) async {
    try {
      state = state.copyWith(
        isLoading: true,
        isImporting: true,
        progress: 0.0,
        error: null,
      );

      // 检查权限
      if (!await _checkPermissions()) {
        throw Exception('缺少必要的文件访问权限');
      }

      final importOptions = options ?? const ImportOptions();

      await BackupService.importData(
        zipPath: filePath,
        options: importOptions,
        onProgress: (message, progress) {
          Log.v('导入进度: $message ($progress)');
          state = state.copyWith(
            currentOperation: message,
            progress: progress,
          );
        },
      );

      state = state.copyWith(
        isLoading: false,
        isImporting: false,
        progress: 1.0,
        currentOperation: '导入完成',
      );

      return true;
    } catch (e, stackTrace) {
      Log.e('从文件导入失败: $e');
      state = state.copyWith(
        isLoading: false,
        isImporting: false,
        error: e.toString(),
        currentOperation: null,
      );
      ErrorHandler.handle(e, stackTrace, prefix: '数据导入失败');
      return false;
    }
  }

  /// 检查文件兼容性
  Future<CompatibilityInfo?> checkFileCompatibility(String? filePath) async {
    try {
      String? selectedPath = filePath;
      if (selectedPath == null) {
        selectedPath = await _selectImportFile();
        if (selectedPath == null) return null;
      }

      return await BackupService.checkZipCompatibility(selectedPath);
    } catch (e, stackTrace) {
      Log.e('检查兼容性失败: $e');
      ErrorHandler.handle(e, stackTrace, prefix: '检查文件兼容性失败');
      return const CompatibilityInfo(
        level: CompatibilityLevel.incompatible,
        message: '无法检查文件兼容性',
        errors: ['文件读取失败或格式错误'],
      );
    }
  }

  /// 清除错误状态
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// 重置状态
  void reset() {
    state = const BackupState();
  }

  /// 检查权限
  Future<bool> _checkPermissions() async {
    try {
      if (Platform.isAndroid) {
        Log.v('开始检查Android存储权限');

        // Android 13+ (API 33+) 使用新的权限模型
        // 首先尝试请求管理外部存储权限（推荐用于文件管理应用）
        try {
          final manageStatus = await Permission.manageExternalStorage.status;
          Log.v('管理外部存储权限状态: $manageStatus');

          if (!manageStatus.isGranted) {
            Log.v('请求管理外部存储权限');
            final result = await Permission.manageExternalStorage.request();
            Log.v('管理外部存储权限请求结果: $result');

            if (result.isGranted) {
              Log.v('管理外部存储权限已授权');
              return true;
            } else {
              Log.w('管理外部存储权限被拒绝，尝试其他权限');
              if (result == PermissionStatus.permanentlyDenied) {
                Log.w('管理外部存储权限被永久拒绝');
              }
            }
          } else {
            Log.v('管理外部存储权限已授权');
            return true;
          }
        } catch (e) {
          Log.v('管理外部存储权限检查失败，可能是旧版本Android: $e');
        }

        // 如果管理外部存储权限不可用或被拒绝，尝试传统存储权限（Android 12及以下）
        try {
          final storageStatus = await Permission.storage.status;
          Log.v('传统存储权限状态: $storageStatus');

          if (!storageStatus.isGranted) {
            Log.v('请求传统存储权限');
            final result = await Permission.storage.request();
            Log.v('传统存储权限请求结果: $result');

            if (result.isGranted) {
              Log.v('传统存储权限已授权');
              return true;
            } else {
              Log.w('传统存储权限被拒绝');
              if (result == PermissionStatus.permanentlyDenied) {
                throw Exception('存储权限被永久拒绝，请在系统设置中手动授权后重试');
              }
            }
          } else {
            Log.v('传统存储权限已授权');
            return true;
          }
        } catch (e) {
          Log.v('传统存储权限检查失败: $e');
        }

        // 如果以上权限都不可用，抛出错误
        throw Exception('无法获取存储权限。请在系统设置中手动授权存储权限，或者授权"所有文件访问权限"');
      }

      Log.v('权限检查完成');
      return true;
    } catch (e) {
      Log.e('权限检查失败: $e');
      rethrow; // 重新抛出异常，让上层处理
    }
  }

  /// 选择导入文件
  Future<String?> _selectImportFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        dialogTitle: '选择备份文件',
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.first.path;
      }
      return null;
    } catch (e) {
      Log.e('选择文件失败: $e');
      return null;
    }
  }
}

/// 导出选项提供者
@riverpod
class ExportOptionsManager extends _$ExportOptionsManager {
  @override
  ExportOptions build() {
    return const ExportOptions();
  }

  void updateOptions(ExportOptions options) {
    state = options;
  }

  void toggleSharedPreferences() {
    state = state.copyWith(
      includeSharedPreferences: !state.includeSharedPreferences,
    );
  }

  void toggleDatabases() {
    state = state.copyWith(
      includeDatabases: !state.includeDatabases,
    );
  }

  void setCustomPath(String? path) {
    state = state.copyWith(customPath: path);
  }

  void setCustomFileName(String? fileName) {
    state = state.copyWith(customFileName: fileName);
  }
}

/// 导入选项提供者
@riverpod
class ImportOptionsManager extends _$ImportOptionsManager {
  @override
  ImportOptions build() {
    return const ImportOptions();
  }

  void updateOptions(ImportOptions options) {
    state = options;
  }

  void toggleSharedPreferences() {
    state = state.copyWith(
      importSharedPreferences: !state.importSharedPreferences,
    );
  }

  void toggleDatabases() {
    state = state.copyWith(
      importDatabases: !state.importDatabases,
    );
  }

  void toggleCreateBackup() {
    state = state.copyWith(
      createBackup: !state.createBackup,
    );
  }

  void toggleForceImport() {
    state = state.copyWith(
      forceImport: !state.forceImport,
    );
  }
}
