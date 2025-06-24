import 'dart:io';

import 'package:counters/app/config.dart';
import 'package:counters/app/state.dart';
import 'package:counters/common/providers/privacy_version_provider.dart';
import 'package:counters/common/utils/error_handler.dart';
import 'package:counters/common/utils/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
// 友盟SDK相关导入已注释 - 友盟功能已禁用
// import 'package:umeng_common_sdk/umeng_common_sdk.dart';

class PrivacyUtil {
  // 友盟MethodChannel已注释 - 友盟功能已禁用
  // static const MethodChannel _channel =
  //     MethodChannel('com.devyi.counters/umeng');
  // static final bool _isMobile = Platform.isAndroid || Platform.isIOS;

  static Future<void> initWithPrivacy(BuildContext context) async {
    Log.d('开始隐私政策初始化检查');

    try {
      // 获取ProviderContainer
      final container = ProviderScope.containerOf(context);
      final privacyNotifier = container.read(privacyVersionProvider.notifier);

      // 检查隐私政策版本更新
      final hasUpdate = await privacyNotifier.checkForUpdate();

      // 如果需要更新（包括首次使用和版本更新），显示隐私政策弹窗
      if (hasUpdate) {
        // 判断是首次使用还是版本更新
        final hasAgreed = await privacyNotifier.hasAgreedPrivacy();
        final isUpdate = hasAgreed; // 如果之前已同意过，说明是版本更新

        Log.i('需要显示隐私政策弹窗: 是否为更新=$isUpdate');
        if (context.mounted) {
          await _showPrivacyDialog(context, container, isUpdate: isUpdate);
        }
      } else {
        Log.d('用户已同意最新版本隐私政策，跳过弹窗');
      }

    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '隐私政策处理错误');
    }
  }

  /// 显示隐私政策弹窗
  static Future<void> _showPrivacyDialog(BuildContext context, ProviderContainer container, {bool isUpdate = false}) async {
    final String title = isUpdate ? '隐私政策已更新' : '隐私政策';
    final String content = isUpdate
        ? '欢迎您使用 Counters ！本次我们更新了隐私政策。我们非常重视用户的隐私和个人信息保护。您在使用我们的产品与/或服务时，我们可能会收集和使用您的相关信息。我们希望通过本《隐私政策》向您清晰地介绍我们对您个人信息的处理方式，因此我们建议您完整地阅读本政策，以帮助您了解维护自己隐私权的方式。'
        : '欢迎您使用 Counters ！我们非常重视用户的隐私和个人信息保护。您在使用我们的产品与/或服务时，我们可能会收集和使用您的相关信息。我们希望通过本《隐私政策》向您清晰地介绍我们对您个人信息的处理方式，因此我们建议您完整地阅读本政策，以帮助您了解维护自己隐私权的方式。';

    final bool? result = await globalState.showCommonDialog(
      child: AlertDialog(
        title: Text(title),
        content: Text(content),
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
      final actionText = isUpdate ? '用户同意更新的隐私政策' : '用户同意隐私政策';
      Log.d(actionText);
      final privacyNotifier = container.read(privacyVersionProvider.notifier);
      final privacyState = container.read(privacyVersionProvider);
      final remoteVersion = privacyState.remoteVersion;

      if (remoteVersion != null) {
        // 保存远程版本的时间戳
        await privacyNotifier.savePrivacyAgreement(remoteVersion.timestamp);
        Log.i('已保存隐私政策同意状态和时间戳: ${remoteVersion.timestamp}');
      } else {
        // 如果没有远程版本信息，保存当前时间戳
        final currentTimestamp = DateTime.now().millisecondsSinceEpoch;
        await privacyNotifier.savePrivacyAgreement(currentTimestamp);
        Log.i('已保存当前时间戳作为隐私政策同意时间: $currentTimestamp');
      }

    } else if (result == false) {
      Log.w('用户明确拒绝隐私政策，退出应用');
      await _exitApplication();
    } else {
      // result == null，用户可能通过返回键或其他方式关闭了弹窗
      Log.w('用户未做选择或关闭了隐私政策弹窗，退出应用');
      await _exitApplication();
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

  /// 获取隐私政策状态（用于调试页面）
  static Future<Map<String, dynamic>> getPrivacyStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final agreedValue = prefs.getBool('privacy_agreed');
      final timeValue = prefs.getInt('privacy_time');

      Map<String, dynamic> status = {
        'hasAgreedKey': prefs.containsKey('privacy_agreed'),
        'hasTimeKey': prefs.containsKey('privacy_time'),
        'agreed': agreedValue ?? false,
        'timestamp': timeValue,
        'agreedType': agreedValue.runtimeType.toString(),
        'timeType': timeValue.runtimeType.toString(),
      };

      return status;
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '获取隐私政策状态失败');
      return {
        'error': e.toString(),
        'hasAgreedKey': false,
        'hasTimeKey': false,
        'agreed': false,
        'timestamp': null,
      };
    }
  }

  /// 手动检查隐私政策更新（用于调试页面）
  static Future<bool> checkPrivacyUpdate() async {
    try {
      // 创建临时的Provider实例进行检查
      final notifier = PrivacyVersionNotifier();
      return await notifier.checkForUpdate();
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '手动检查隐私政策更新失败');
      return false;
    }
  }

  // 友盟事件追踪方法已注释 - 友盟功能已禁用
  // static onEvent(String event, Map<String, Object> properties) {
  //   if (!_isMobile) return;
  //   UmengCommonSdk.onEvent(event, properties);
  // }
}
