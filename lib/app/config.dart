class Config {
  /// 友盟 key
  static const umengAndroidKey = '67c155ee9a16fe6dcd555f54';
  static const umengiOSKey = "67c155ee9a16fe6dcd555f54"; // 暂未申请
  static const umengChannel = "Github";

  // 常量字符串 - URL
  static const urlPrivacyPolicy = "https://counters.devyi.com/privacy-policy";
  static const urlGithub = "https://github.com/youzhiran/counters";
  static const String urlReleases =
      'https://api.github.com/repos/youzhiran/counters/releases';
  static const String urlDevyi = 'https://devyi.com';

  // 常量字符串 - LAN
  static const int discoveryPort = 8099; // 用于服务发现的 UDP 端口 (不同于 WebSocket 端口)
  static const String discoveryMsgPrefix = 'CountersGameHost:'; // 广播消息标识

  // 常量字符串列表 - 回退字体
  static const List<String> chineseFontFallbacks = [
    'HarmonyOS Sans SC',
    'PingFang SC',
    'MiSans',
    'MiSans VF',
    'Ubuntu',
    "Helvetica Neue",
    'Roboto',
    'Microsoft YaHei UI',
    'Microsoft YaHei',
    'Noto Sans SC',
    'Arial',
  ];
}
