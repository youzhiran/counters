import 'package:counters/features/setting/data_manager.dart';
import 'package:counters/features/setting/file_explorer_page.dart';
import 'package:flutter/material.dart';

class StorageExplorerPage extends StatefulWidget {
  const StorageExplorerPage({super.key});

  @override
  State<StorageExplorerPage> createState() => _StorageExplorerPageState();
}

class _StorageExplorerPageState extends State<StorageExplorerPage> {
  Future<Map<String, Map<String, dynamic>>>? _directoryInfoFuture;

  @override
  void initState() {
    super.initState();
    _directoryInfoFuture = DataManager.getDebugDirectoryInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('存储路径调试'),
      ),
      body: FutureBuilder<Map<String, Map<String, dynamic>>>(
        future: _directoryInfoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('获取目录信息失败: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('未找到目录信息'));
          }

          final directoryInfo = snapshot.data!;
          return ListView.builder(
            itemCount: directoryInfo.length,
            itemBuilder: (context, index) {
              final entry = directoryInfo.entries.elementAt(index);
              final title = entry.key;
              final path = entry.value['path'] as String;
              final isError =
                  path.startsWith('Error:') || path.startsWith('Not');

              return ListTile(
                title: Text(title),
                subtitle: Text(
                  path,
                  style: TextStyle(
                    fontSize: 12,
                    color: isError ? Colors.red : Colors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: isError
                    ? null
                    : const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: isError
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                FileExplorerPage(initialPath: path),
                          ),
                        );
                      },
              );
            },
          );
        },
      ),
    );
  }
}