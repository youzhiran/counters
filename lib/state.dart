import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:counters/utils/log.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class GlobalState with ChangeNotifier {
  final navigatorKey = GlobalKey<NavigatorState>();

  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  final filter = ImageFilter.blur(
    sigmaX: 5,
    sigmaY: 5,
    tileMode: TileMode.mirror,
  );

  ThemeMode get themeMode => _themeMode;

  Color get themeColor => _themeColor;

  // 主题相关状态
  ThemeMode _themeMode = ThemeMode.system;
  Color _themeColor = Colors.blue;
  late SharedPreferences _prefs; // 持久化存储实例

  // 初始化方法（需要在main函数中调用）
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      Log.e('读取SharedPreferences出错: $e');
    }
    _loadPreferences();
  }

  // 加载存储的设置
  void _loadPreferences() {
    // 加载主题模式
    final modeIndex = _prefs.getInt('themeMode') ?? ThemeMode.system.index;
    _themeMode = ThemeMode.values[modeIndex];

    // 加载主题颜色
    final colorValue = _prefs.getInt('themeColor') ?? Colors.blue.toARGB32();
    _themeColor = Color(colorValue);

    notifyListeners(); // 通知监听者更新
  }

  // 主题模式设置方法
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setInt('themeMode', mode.index); // 持久化存储
    notifyListeners(); // 通知界面更新
  }

  // 主题颜色设置方法
  Future<void> setThemeColor(Color color) async {
    _themeColor = color;
    await _prefs.setInt('themeColor', color.toARGB32()); // 持久化存储
    notifyListeners(); // 通知界面更新
  }

  /// 显示进度对话框
  /// 显示进度对话框
  String? _progressMessage;
  double _progressValue = 0;
  Future<bool> showProgressDialog({
    required String title,
    required Future<bool> Function(
      void Function(String message, double progress) onProgress,
    ) task,
  }) async {
    bool? result;
    bool taskStarted = false; // 添加标志，防止任务被多次调用

    await showCommonDialog<void>(
      dismissible: false,
      child: Builder(
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              // 开始执行任务，确保只执行一次
              if (result == null && !taskStarted) {
                taskStarted = true; // 标记任务已开始
                result = null;
                task((message, progress) {
                  if (!context.mounted) return;
                  setState(() {
                    _progressMessage = message;
                    _progressValue = progress;
                  });
                }).then((value) {
                  result = value;
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                });
              }

              return AlertDialog(
                title: Text(title),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_progressMessage ?? '准备中...'),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: _progressValue,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
    return result ?? false;
  }

  Future<T?> showCommonDialog<T>({
    required Widget child,
    bool dismissible = true,
  }) async {
    return await showModal<T>(
      context: navigatorKey.currentState!.context,
      configuration: FadeScaleTransitionConfiguration(
        barrierColor: Colors.black38,
        barrierDismissible: dismissible,
      ),
      builder: (_) => child,
      filter: filter,
    );
  }

  Future<bool?> showMessage<bool>({
    required String title,
    required InlineSpan message,
    String? confirmText,
  }) async {
    return await showCommonDialog<bool>(
      child: Builder(
        builder: (context) {
          return AlertDialog(
            title: Text(title),
            content: Container(
              width: 300,
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: SelectableText.rich(
                  TextSpan(
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.normal,
                        ),
                    children: [message],
                  ),
                  style: const TextStyle(
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: Text(confirmText ?? '确认'),
              )
            ],
          );
        },
      ),
    );
  }

  openUrl(String url) async {
    final res = await showMessage(
      message: TextSpan(text: url),
      title: '外部链接',
      confirmText: '前往',
    );
    if (res != true) {
      return;
    }
    launchUrl(Uri.parse(url));
  }
}

final globalState = GlobalState();
