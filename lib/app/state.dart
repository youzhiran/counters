import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:counters/common/utils/error_handler.dart';
import 'package:counters/common/utils/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// 状态数据类
class GlobalStateData {
  final GlobalKey<NavigatorState> navigatorKey;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;
  final ImageFilter filter;
  final ThemeMode themeMode;
  final Color themeColor;
  final String? progressMessage;
  final double progressValue;
  final bool enableDesktopMode;

  const GlobalStateData({
    required this.navigatorKey,
    required this.scaffoldMessengerKey,
    required this.filter,
    required this.themeMode,
    required this.themeColor,
    this.progressMessage,
    this.progressValue = 0,
    this.enableDesktopMode = false,
  });

  GlobalStateData copyWith({
    GlobalKey<NavigatorState>? navigatorKey,
    GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey,
    ImageFilter? filter,
    ThemeMode? themeMode,
    Color? themeColor,
    String? progressMessage,
    double? progressValue,
    bool? enableDesktopMode,
  }) {
    return GlobalStateData(
      navigatorKey: navigatorKey ?? this.navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey ?? this.scaffoldMessengerKey,
      filter: filter ?? this.filter,
      themeMode: themeMode ?? this.themeMode,
      themeColor: themeColor ?? this.themeColor,
      progressMessage: progressMessage ?? this.progressMessage,
      progressValue: progressValue ?? this.progressValue,
      enableDesktopMode: enableDesktopMode ?? this.enableDesktopMode,
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

  // 弹窗模糊
  final filter = ImageFilter.blur(
    sigmaX: 5,
    sigmaY: 5,
    tileMode: TileMode.mirror,
  );

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
      ErrorHandler.handle(e, StackTrace.current,
          prefix: '读取SharedPreferences出错');
    }

    // 加载主题设置
    final modeIndex = _prefs.getInt('themeMode') ?? ThemeMode.system.index;
    final colorValue = _prefs.getInt('themeColor') ?? Colors.blue.toARGB32();

    // 加载桌面模式设置
    final enableDesktopMode = _prefs.getBool('enable_desktop_mode') ?? false;

    _state = GlobalStateData(
      navigatorKey: GlobalKey<NavigatorState>(),
      scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
      filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
      themeMode: ThemeMode.values[modeIndex],
      themeColor: Color(colorValue),
      enableDesktopMode: enableDesktopMode,
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

  // 获取当前进度信息
  String? get progressMessage => _state.progressMessage;

  // 获取当前进度值
  double get progressValue => _state.progressValue;

  // 获取当前桌面模式设置
  bool get enableDesktopMode => _state.enableDesktopMode;

  /// 显示一个带进度更新的异步任务对话框
  ///
  /// 参数：
  ///   - `title`：对话框标题文本
  ///   - `task`：异步任务函数，接收一个进度回调函数
  ///     - 进度回调参数：(message, progress)
  ///       - message：当前进度描述文本
  ///       - progress：进度值（0.0-1.0）
  ///
  /// 返回值：Future\<bool\>，表示任务最终执行结果
  ///
  /// 示例代码：
  /// ```dart
  /// final success = await globalState.showProgressDialog(
  ///   title: '文件导出中',
  ///   task: (updateProgress) async {
  ///     updateProgress('正在准备数据...', 0.2);
  ///     await Future.delayed(Duration(seconds: 1));
  ///     updateProgress('正在处理内容...', 0.5);
  ///     await Future.delayed(Duration(seconds: 1));
  ///     updateProgress('正在生成文件...', 0.8);
  ///     await Future.delayed(Duration(seconds: 1));
  ///     updateProgress('导出完成！', 1.0);
  ///     return true; // 返回最终结果
  ///   },
  /// );
  /// if (success) {
  ///   globalState.showMessage(
  ///     title: '导出成功',
  ///     message: TextSpan(text: '导出成功'),
  ///   );
  /// }
  /// ```
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
                  globalState.navigatorKey.currentState?.pop();
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
                  globalState.navigatorKey.currentState?.pop(false);
                },
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  globalState.navigatorKey.currentState?.pop(true);
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
  Future<void> openUrl(String url, [String msg = '']) async {
    final res = await showMessage(
      message: TextSpan(text: msg.isEmpty ? url : msg),
      title: '外部链接',
      confirmText: '前往',
    );
    if (res != true) {
      return;
    }
    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '打开链接失败');
    }
  }
}

// 全局实例
final globalState = GlobalState();

// 新增：用于提供 Provider 日志在启动时的实际状态
final providerLoggerActuallyEnabledProvider = Provider<bool>((ref) {
  // 此 Provider 应该在 main.dart 中的 ProviderScope 进行 override。
  // 如果没有 override 就直接使用，会抛出这个错误，以提醒开发者配置。
  throw StateError('providerLoggerActuallyEnabledProvider was not overridden. '
      'Ensure it is overridden in ProviderScope in main.dart.');
});
