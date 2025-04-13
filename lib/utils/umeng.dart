import 'dart:io';

import 'package:umeng_common_sdk/umeng_common_sdk.dart';

import '../config.dart';

class UmengUtil {
  static final bool _isMobile = Platform.isAndroid || Platform.isIOS;

  static init() {
    if (!_isMobile) return;
    UmengCommonSdk.initCommon(
        Config.umengAndroidKey, Config.umengiOSKey, Config.umengChannel);
    UmengCommonSdk.setPageCollectionModeAuto();
  }

  static onEvent(String event, Map<String, dynamic> properties) {
    if (!_isMobile) return;
    UmengCommonSdk.onEvent(event, properties);
  }
}
