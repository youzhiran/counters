import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class FileExplorerPage extends StatefulWidget {
  final String initialPath;

  const FileExplorerPage({super.key, required this.initialPath});

  @override
  State<FileExplorerPage> createState() => _FileExplorerPageState();
}

class _FileExplorerPageState extends State<FileExplorerPage> {
  late String _currentPath;
  List<FileSystemEntity> _entries = [];
  bool _isLoading = true;
  String? _error;
  bool _canGoUp = false;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.initialPath;
    _listDirectory(_currentPath);
  }

  Future<void> _listDirectory(String path) async {
    setState(() {
      _isLoading = true;
      _currentPath = path;
      _error = null;
    });

    try {
      final dir = Directory(path);
      if (await dir.exists()) {
        final entries = await dir.list().toList();
        // 排序：文件夹在前，文件在后，按字母顺序
        entries.sort((a, b) {
          try {
            final aIsDir = a.statSync().type == FileSystemEntityType.directory;
            final bIsDir = b.statSync().type == FileSystemEntityType.directory;

            if (aIsDir && !bIsDir) return -1;
            if (!aIsDir && bIsDir) return 1;
            return p
                .basename(a.path)
                .toLowerCase()
                .compareTo(p.basename(b.path).toLowerCase());
          } catch (e) {
            return 0; // 出错时保持原顺序
          }
        });

        // 检查是否可以返回上一级
        final parent = Directory(_currentPath).parent.path;
        final canGoUp = p.canonicalize(_currentPath) != p.canonicalize(parent);

        setState(() {
          _entries = entries;
          _canGoUp = canGoUp;
        });
      } else {
        setState(() {
          _entries = [];
          _error = '目录不存在';
        });
      }
    } catch (e) {
      setState(() {
        _entries = [];
        _error = '无法访问目录: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onEntryTap(FileSystemEntity entity) {
    try {
      if (entity.statSync().type == FileSystemEntityType.directory) {
        _listDirectory(entity.path);
      } else {
        // 对于文件，可以显示一个简单的提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('这是一个文件: ${p.basename(entity.path)}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('无法访问: $e')),
      );
    }
  }

  void _goUp() {
    if (_canGoUp) {
      final parent = Directory(_currentPath).parent.path;
      _listDirectory(parent);
    }
  }

  @override
  Widget build(BuildContext context) {
    // PopScope 用于拦截返回事件
    return PopScope(
      canPop: !_canGoUp, // 如果不能再向上了，才允许页面退出
      onPopInvoked: (didPop) {
        if (didPop) return; // 如果页面已经退出了，不做任何事
        _goUp(); // 否则，执行向上导航
      },
      child: Scaffold(
        appBar: AppBar(
          // 如果可以向上，显示向上按钮，否则显示默认的返回按钮
          leading: _canGoUp
              ? IconButton(
                  icon: const Icon(Icons.arrow_upward),
                  tooltip: '返回上一级',
                  onPressed: _goUp,
                )
              : null, // null 会让 Flutter 显示默认的返回按钮
          title: Tooltip(
            message: _currentPath,
            child: Text(
              p.basename(_currentPath).isEmpty
                  ? _currentPath // 处理根目录情况, e.g., "C:\"
                  : p.basename(_currentPath),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }
    if (_entries.isEmpty) {
      return const Center(child: Text('目录为空'));
    }

    return ListView.builder(
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final entity = _entries[index];
        IconData iconData;
        try {
          final type = entity.statSync().type;
          if (type == FileSystemEntityType.directory) {
            iconData = Icons.folder;
          } else if (type == FileSystemEntityType.link) {
            iconData = Icons.link;
          } else {
            iconData = Icons.insert_drive_file;
          }
        } catch (e) {
          iconData = Icons.error_outline; // 无法获取状态时显示错误图标
        }

        return ListTile(
          leading: Icon(iconData),
          title: Text(p.basename(entity.path)),
          onTap: () => _onEntryTap(entity),
        );
      },
    );
  }
}