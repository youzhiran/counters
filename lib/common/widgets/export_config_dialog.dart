import 'dart:io';

import 'package:counters/app/state.dart';
import 'package:counters/common/widgets/message_overlay.dart';
// import 'package:file_picker/file_picker.dart';
import 'package:file_picker_ohos/file_picker_ohos.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// 通用导出配置对话框
///
/// 注意：此类现在只用于非鸿蒙平台。
/// 鸿蒙平台的导出流程由业务层（如 BackupService）直接处理。
class ExportConfigDialog extends StatefulWidget {
  /// 对话框标题
  final String title;

  /// 默认文件名
  final String defaultFileName;

  /// 文件类型
  final List<String> allowedExtensions;

  /// 文件选择器标题
  final String dialogTitle;

  const ExportConfigDialog({
    super.key,
    required this.title,
    required this.defaultFileName,
    this.allowedExtensions = const ['zip'],
    required this.dialogTitle,
  });

  @override
  State<ExportConfigDialog> createState() => _ExportConfigDialogState();
}

class _ExportConfigDialogState extends State<ExportConfigDialog> {
  String? selectedDirectoryPath;
  late final TextEditingController _fileNameController;

  @override
  void initState() {
    super.initState();
    _fileNameController = TextEditingController(text: widget.defaultFileName);
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 使用 ValueListenableBuilder 确保 "确定" 按钮的状态能根据文件名输入动态更新
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _fileNameController,
      builder: (context, value, child) {
        final isReadyToSave =
            selectedDirectoryPath != null && value.text.isNotEmpty;
        return AlertDialog(
          title: Text(widget.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 保存位置选择
              const Text('保存位置:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedDirectoryPath ?? '请选择保存位置',
                      style: TextStyle(
                        color: selectedDirectoryPath == null
                            ? Theme.of(context).hintColor
                            : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _selectSaveLocation,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('选择'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 文件名输入
              const Text('文件名:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _fileNameController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: '请输入文件名',
                  // 提示文件扩展名
                  suffixText: widget.allowedExtensions.isNotEmpty
                      ? '.${widget.allowedExtensions.first}'
                      : null,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              // 根据是否选择了目录和输入了文件名来决定是否可以点击
              onPressed: !isReadyToSave
                  ? null
                  : () {
                      Navigator.of(context).pop({
                        'directory': selectedDirectoryPath!,
                        'fileName': _fileNameController.text,
                      });
                    },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  /// 选择保存位置（文件夹）
  Future<void> _selectSaveLocation() async {
    String? initialDirectory;
    try {
      final Directory directory = await getApplicationDocumentsDirectory();
      initialDirectory = directory.path;
    } catch (e) {
      GlobalMsgManager.showWarn("无法获取应用文档目录: $e");
    }

    // 调用标准的 getDirectoryPath，这在 Windows, Android, iOS, macOS 等平台工作良好
    final String? path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: widget.dialogTitle,
      initialDirectory: initialDirectory,
      lockParentWindow: true, // 建议在桌面端设置为 true
    );

    if (path != null) {
      setState(() {
        selectedDirectoryPath = path;
      });
    }
  }
}

/// 全局导出配置对话框
///
/// 这是一个简单的包装器，用于显示 ExportConfigDialog。
/// 它不再包含任何平台判断逻辑。
class GlobalExportConfigDialog {
  /// 显示导出配置对话框
  static Future<Map<String, String>?> show({
    String title = '导出配置',
    required String defaultFileName,
    List<String> allowedExtensions = const ['zip'],
    String dialogTitle = '选择文件保存位置',
  }) async {
    return globalState.showCommonDialog<Map<String, String>>(
      child: ExportConfigDialog(
        title: title,
        defaultFileName: defaultFileName,
        allowedExtensions: allowedExtensions,
        dialogTitle: dialogTitle,
      ),
    );
  }
}
