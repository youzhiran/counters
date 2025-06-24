import 'dart:io';

import 'package:counters/app/config.dart';
import 'package:counters/app/state.dart';
import 'package:counters/common/utils/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
// 友盟SDK相关导入已注释 - 友盟功能已禁用
// import 'package:umeng_common_sdk/umeng_common_sdk.dart';

class PrivacyUtil {
  // 友盟MethodChannel已注释 - 友盟功能已禁用
  // static const MethodChannel _channel =
  //     MethodChannel('com.devyi.counters/umeng');
  // static final bool _isMobile = Platform.isAndroid || Platform.isIOS;

  // 防止重复调用的标志
  static bool _isInitializing = false;
  static bool _hasInitialized = false;

  static Future<void> initWithPrivacy(BuildContext context) async {
    // 防止重复调用
    if (_isInitializing || _hasInitialized) {
      Log.d('隐私政策初始化已跳过: 正在初始化=$_isInitializing, 已初始化=$_hasInitialized');
      return;
    }

    _isInitializing = true;
    Log.d('开始隐私政策初始化检查');

    // 友盟已注释
    // if (!_isMobile) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final bool agreed = prefs.getBool('privacy_agreed') ?? false;
      if (agreed) {
        Log.d('用户已同意隐私政策，跳过弹窗');
        _hasInitialized = true;
        _isInitializing = false;
        // 友盟初始化调用已注释 - 友盟功能已禁用
        // await _channel.invokeMethod('initUmeng');
        return;
      }

      final bool? result = await globalState.showCommonDialog(
        child: AlertDialog(
          title: const Text('隐私政策'),
          content: const Text(
              '欢迎您使用 Counters ！我们非常重视用户的隐私和个人信息保护。您在使用我们的产品与/或服务时，我们可能会收集和使用您的相关信息。我们希望通过本《隐私政策》向您清晰地介绍我们对您个人信息的处理方式，因此我们建议您完整地阅读本政策，以帮助您了解维护自己隐私权的方式。'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                globalState.openUrl(
                  Config.urlPrivacyPolicy,
                  '查看隐私政策',
                );
              },
              child: const Text('查看隐私政策'),
            ),
            TextButton(
              onPressed: () =>
                  globalState.navigatorKey.currentState?.pop(false),
              child: const Text('不同意'),
            ),
            TextButton(
              onPressed: () => globalState.navigatorKey.currentState?.pop(true),
              child: const Text('同意'),
            ),
          ],
        ),
      );

      if (result == true) {
        Log.d('用户同意隐私政策');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('privacy_agreed', true);
        _hasInitialized = true;
        // 友盟相关MethodChannel调用已注释 - 友盟功能已禁用
        // await _channel.invokeMethod('setPrivacyAgreed');
        // await _channel.invokeMethod('initUmeng');
      } else if (result == false) {
        Log.w('用户明确拒绝隐私政策，退出应用');
        await _exitApplication();
      } else {
        // result == null，用户可能通过返回键或其他方式关闭了弹窗
        Log.w('用户未做选择或关闭了隐私政策弹窗，退出应用');
        await _exitApplication();
      }
    } catch (e) {
      Log.e('隐私政策处理错误: $e'); // 更新错误信息描述
    } finally {
      _isInitializing = false;
    }
  }

  /// 退出应用程序的方法，支持多平台
  static Future<void> _exitApplication() async {
    try {
      Log.i('开始退出应用程序...');

      // 根据平台选择合适的退出方式
      if (Platform.isAndroid) {
        Log.d('Android平台：使用SystemNavigator.pop()退出');
        SystemNavigator.pop();
      } else if (Platform.isIOS) {
        Log.d('iOS平台：使用exit(0)退出');
        // iOS上SystemNavigator.pop()可能不够可靠，使用exit(0)
        exit(0);
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        Log.d('桌面平台：使用exit(0)退出');
        // 桌面平台直接使用exit(0)
        exit(0);
      } else {
        Log.d('其他平台：尝试使用SystemNavigator.pop()退出');
        // 其他平台尝试使用SystemNavigator.pop()
        SystemNavigator.pop();

        // 如果SystemNavigator.pop()不起作用，延迟后使用exit(0)
        await Future.delayed(const Duration(milliseconds: 500));
        Log.w('SystemNavigator.pop()可能未生效，使用exit(0)强制退出');
        exit(0);
      }
    } catch (e) {
      Log.e('退出应用程序时发生错误: $e');
      // 如果其他方法都失败了，最后尝试exit(0)
      try {
        exit(0);
      } catch (exitError) {
        Log.e('强制退出也失败了: $exitError');
      }
    }
  }

  // 友盟事件追踪方法已注释 - 友盟功能已禁用
  // static onEvent(String event, Map<String, Object> properties) {
  //   if (!_isMobile) return;
  //   UmengCommonSdk.onEvent(event, properties);
  // }
}
