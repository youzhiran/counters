import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:counters/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'utils/log.dart';

// 状态数据类
class GlobalStateData {
  final GlobalKey<NavigatorState> navigatorKey;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;
  final ImageFilter filter;
  final ThemeMode themeMode;
  final Color themeColor;
  final String? progressMessage;
  final double progressValue;

  const GlobalStateData({
    required this.navigatorKey,
    required this.scaffoldMessengerKey,
    required this.filter,
    required this.themeMode,
    required this.themeColor,
    this.progressMessage,
    this.progressValue = 0,
  });

  GlobalStateData copyWith({
    GlobalKey<NavigatorState>? navigatorKey,
    GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey,
    ImageFilter? filter,
    ThemeMode? themeMode,
    Color? themeColor,
    String? progressMessage,
    double? progressValue,
  }) {
    return GlobalStateData(
      navigatorKey: navigatorKey ?? this.navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey ?? this.scaffoldMessengerKey,
      filter: filter ?? this.filter,
      themeMode: themeMode ?? this.themeMode,
      themeColor: themeColor ?? this.themeColor,
      progressMessage: progressMessage ?? this.progressMessage,
      progressValue: progressValue ?? this.progressValue,
    );
  }
}

class GlobalState {
  static GlobalState? _instance;
  late SharedPreferences _prefs;
  late GlobalStateData _state;

  // 进度对话框相关状态
  String? _progressDialogMessage;
  double _progressDialogValue = 0;

  // 私有构造函数
  GlobalState._internal();

  // 单例访问点
  factory GlobalState() {
    _instance ??= GlobalState._internal();
    return _instance!;
  }

  // 初始化方法
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      Log.e('读取SharedPreferences出错: $e');
    }

    // 加载主题设置
    final modeIndex = _prefs.getInt('themeMode') ?? ThemeMode.system.index;
    final colorValue = _prefs.getInt('themeColor') ?? Colors.blue.toARGB32();

    _state = GlobalStateData(
      navigatorKey: GlobalKey<NavigatorState>(),
      scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
      filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
      themeMode: ThemeMode.values[modeIndex],
      themeColor: Color(colorValue),
    );
  }

  // 获取当前状态
  GlobalStateData get currentState => _state;

  // 更新状态
  void updateState(GlobalStateData newState) {
    _state = newState;
  }

  // 更新主题模式
  Future<void> setThemeMode(ThemeMode themeMode) async {
    await _prefs.setInt('themeMode', themeMode.index);
    _state = _state.copyWith(themeMode: themeMode);

    // 通知应用重建以应用新主题
    final context = navigatorKey.currentContext;
    if (context != null) {
      // 检查 context 是否仍然挂载
      if (context is Element && context.mounted) {
        // 查找并重建MaterialApp
        void rebuildApp(Element element) {
          element.markNeedsBuild();
          element.visitChildren(rebuildApp);
        }

        context.visitChildElements(rebuildApp);
      }
    }
  }

  // 更新主题颜色
  Future<void> setThemeColor(Color color) async {
    await _prefs.setInt('themeColor', color.toARGB32());
    _state = _state.copyWith(themeColor: color);

    // 通知应用重建以应用新主题
    final context = navigatorKey.currentContext;
    if (context != null) {
      // 检查 context 是否仍然挂载
      if (context is Element && context.mounted) {
        // 查找并重建MaterialApp
        void rebuildApp(Element element) {
          element.markNeedsBuild();
          element.visitChildren(rebuildApp);
        }

        context.visitChildElements(rebuildApp);
      }
    }
  }

  // 更新进度信息
  void updateProgress({String? message, double? value}) {
    _state = _state.copyWith(
      progressMessage: message,
      progressValue: value,
    );
  }

  // 清除进度信息
  void clearProgress() {
    _state = _state.copyWith(progressMessage: null, progressValue: 0);
  }

  // 获取导航键
  GlobalKey<NavigatorState> get navigatorKey => _state.navigatorKey;

  // 获取ScaffoldMessenger键
  GlobalKey<ScaffoldMessengerState> get scaffoldMessengerKey =>
      _state.scaffoldMessengerKey;

  // 获取当前主题模式
  ThemeMode get themeMode => _state.themeMode;

  // 获取当前主题颜色
  Color get themeColor => _state.themeColor;

  // 获取当前滤镜
  ImageFilter get filter => _state.filter;

  // 获取当前进度信息
  String? get progressMessage => _state.progressMessage;

  // 获取当前进度值
  double get progressValue => _state.progressValue;

  /// 显示进度对话框
  Future<bool> showProgressDialog({
    required String title,
    required Future<bool> Function(
      void Function(String message, double progress) onProgress,
    ) task,
  }) async {
    bool? result;
    bool taskStarted = false;

    await showCommonDialog<void>(
      dismissible: false,
      child: Builder(
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              // 开始执行任务，确保只执行一次
              if (result == null && !taskStarted) {
                taskStarted = true;
                result = null;
                task((message, progress) {
                  if (!context.mounted) return;
                  setState(() {
                    _progressDialogMessage = message;
                    _progressDialogValue = progress;
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
                    Text(_progressDialogMessage ?? '准备中...'),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: _progressDialogValue,
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

  /// 显示通用对话框
  Future<T?> showCommonDialog<T>({
    required Widget child,
    bool dismissible = true,
  }) async {
    if (navigatorKey.currentState?.context == null) {
      Log.e('Navigator context is not available');
      return null;
    }

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

  /// 显示消息对话框
  Future<bool?> showMessage({
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
                child: const Text('取消'),
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

  /// 打开外部链接
  Future<void> openUrl(String url) async {
    final res = await showMessage(
      message: TextSpan(text: url),
      title: '外部链接',
      confirmText: '前往',
    );
    if (res != true) {
      return;
    }
    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      Log.e('打开链接失败: $e');
      if (navigatorKey.currentState?.context != null) {
        AppSnackBar.show('无法打开链接: $url');
      }
    }
  }
}

// 全局实例
final globalState = GlobalState();
