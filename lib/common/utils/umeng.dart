import 'dart:io';

import 'package:counters/app/config.dart';
import 'package:counters/app/state.dart';
import 'package:counters/common/utils/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';

class UmengUtil {
  static const MethodChannel _channel =
      MethodChannel('com.devyi.counters/umeng');
  static final bool _isMobile = Platform.isAndroid || Platform.isIOS;

  static Future<void> initWithPrivacy(BuildContext context) async {
    if (!_isMobile) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final bool agreed = prefs.getBool('privacy_agreed') ?? false;
      if (agreed) {
        await _channel.invokeMethod('initUmeng');
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('privacy_agreed', true);
        await _channel.invokeMethod('setPrivacyAgreed');
        await _channel.invokeMethod('initUmeng');
      } else {
        SystemNavigator.pop();
      }
    } catch (e) {
      Log.e('友盟初始化错误: $e');
    }
  }

  static onEvent(String event, Map<String, Object> properties) {
    if (!_isMobile) return;
    UmengCommonSdk.onEvent(event, properties);
  }
}
