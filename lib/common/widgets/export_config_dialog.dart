import 'package:counters/app/state.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// 通用导出配置对话框
///
/// 用于选择文件保存位置和文件名
class ExportConfigDialog extends StatefulWidget {
  /// 对话框标题
  final String title;

  /// 默认文件名
  final String defaultFileName;

  /// 文件类型
  final List<String> allowedExtensions;

  /// 对话框标题
  final String dialogTitle;

  const ExportConfigDialog({
    super.key,
    this.title = '导出配置',
    required this.defaultFileName,
    this.allowedExtensions = const ['zip'],
    this.dialogTitle = '选择文件保存位置',
  });

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

  @override
  State<ExportConfigDialog> createState() => _ExportConfigDialogState();
}

class _ExportConfigDialogState extends State<ExportConfigDialog> {
  String? selectedFilePath;
  String fileName = '';

  @override
  void initState() {
    super.initState();
    fileName = widget.defaultFileName;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 保存位置选择
          const Text('保存位置:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  selectedFilePath ?? '请选择保存位置',
                  style: TextStyle(
                    color: selectedFilePath == null
                        ? Theme.of(context).hintColor
                        : null,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _selectSaveLocation,
                icon: const Icon(Icons.save),
                label: const Text('选择'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: selectedFilePath == null
              ? null
              : () {
                  Navigator.of(context).pop({
                    'directory': selectedFilePath!,
                    'fileName': fileName,
                  });
                },
          child: const Text('确定'),
        ),
      ],
    );
  }

  /// 选择保存位置
  Future<void> _selectSaveLocation() async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: widget.dialogTitle,
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: widget.allowedExtensions,
    );
    if (result != null) {
      setState(() {
        selectedFilePath = result;
      });
    }
  }
}

/// 全局导出配置对话框
///
/// 使用全局状态管理器显示导出配置对话框
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
