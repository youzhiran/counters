import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state.dart';
import '../widgets/snackbar.dart';
import 'log.dart';

class ErrorHandler {
  static void handleError(Object error, StackTrace? stack,
      {String prefix = ''}) {
    Log.e('$prefix错误: $error');
    if (stack != null) Log.e('Stack: $stack');

    Future.microtask(() {
      if (globalState.scaffoldMessengerKey.currentState != null) {
        final message = '$prefix错误: ${error.toString().split('\n').first}';
        globalState.scaffoldMessengerKey.currentState!.showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: '详情',
              textColor: Colors.white,
              onPressed: () {
                if (globalState.navigatorKey.currentContext != null) {
                  globalState.showCommonDialog(
                    child: Builder(
                      builder: (context) => AlertDialog(
                        title: Text('$prefix错误详情'),
                        content: SingleChildScrollView(
                          child: SelectableText('$error\n\n${stack ?? ''}'),
                        ),
                        actions: [
                          TextButton(
                            child: const Text('复制'),
                            onPressed: () {
                              final errorText = '$error\n\n${stack ?? ''}';
                              Clipboard.setData(ClipboardData(text: errorText));
                              Navigator.pop(context);
                              AppSnackBar.show('已复制到剪贴板');
                            },
                          ),
                          TextButton(
                            child: const Text('关闭'),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        );
      }
    });
  }
}
