class Config {
  // 友盟配置已注释 - 友盟功能已禁用
  // /// 友盟 key
  // static const umengAndroidKey = '67c155ee9a16fe6dcd555f54';
  // static const umengiOSKey = "67c155ee9a16fe6dcd555f54"; // 暂未申请
  // static const umengChannel = "Github";

  // 常量字符串 - URL
  static const urlPrivacyPolicy = "https://counters.devyi.com/privacy-policy";
  static const urlGithub = "https://github.com/youzhiran/counters";
  static const String urlReleases =
      'https://api.github.com/repos/youzhiran/counters/releases';
  static const String urlDevyi = 'https://devyi.com';
  static const String urlApp = 'https://counters.devyi.com/?ref=app';
  static const String urlContact = 'https://counters.devyi.com/contact';

  // 常量字符串 - JSON
  static const String jsonPrivacyVersion =
      'https://counters.devyi.com/api/private-version.json';

  // 常量字符串 - LAN
  static const int discoveryPort = 8099; // 用于服务发现的 UDP 端口 (不同于 WebSocket 端口)
  static const int webSocketPort = 8080; // 默认 WebSocket 服务端口
  static const String discoveryMsgPrefix = 'CountersGameHost:'; // 广播消息标识
  static const String appName = '得益计分'; // 程序名称

  // 端口范围配置
  static const int discoveryPortMin = 8099; // 广播端口最小值
  static const int discoveryPortMax = 8109; // 广播端口最大值
  static const int webSocketPortMin = 8080; // WebSocket 端口最小值
  static const int webSocketPortMax = 8090; // WebSocket 端口最大值

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

  static const int roundScoreMax = 1000000; // 每轮最大分数
  static const int gameScoreMax = 2100000000; // 每局累计最大分数，暂未使用
}
