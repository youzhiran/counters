class ScoreHttpTemplates {
  ScoreHttpTemplates._();

  /// 默认模板资源路径
  static const String defaultTemplateAsset =
      'assets/lan_http_templates/scoreboard_default.html';

  /// Poker50 模板页面资源路径
  static const String poker50TemplateAsset =
      'assets/lan_http_templates/scoreboard_poker50.html';

  /// 麻将模板页面资源路径
  static const String mahjongTemplateAsset =
      'assets/lan_http_templates/scoreboard_mahjong.html';

  /// 计数器模板页面资源路径
  static const String counterTemplateAsset =
      'assets/lan_http_templates/scoreboard_counter.html';

  /// 斗地主模板页面资源路径
  static const String landlordsTemplateAsset =
      'assets/lan_http_templates/scoreboard_landlords.html';

  /// 模板类型与资源路径映射
  static const Map<String, String> templateAssetByType = {
    'poker50': poker50TemplateAsset,
    'mahjong': mahjongTemplateAsset,
    'counter': counterTemplateAsset,
    'landlords': landlordsTemplateAsset,
  };

  /// 下载二维码资源路径
  static const String downloadQrAsset = 'assets/svg/qr-download.svg';

  /// 根据模板类型解析对应的资源路径，找不到时回退到默认模板
  static String resolveTemplateAsset(
    String? templateType, {
    String? defaultAssetPath,
  }) {
    final fallback = defaultAssetPath ?? defaultTemplateAsset;
    if (templateType == null || templateType.isEmpty) {
      return fallback;
    }
    return templateAssetByType[templateType] ?? fallback;
  }

  /// 当资源加载失败时使用的回退HTML
  static const String fallbackHtml = '''
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>得益计分 - 实时比分</title>
</head>
<body>
  <main style="font-family: sans-serif; padding: 24px; max-width: 800px; margin: 0 auto;">
    <h1>实时比分不可用</h1>
    <p>未能加载局域网计分模板，请确认资源文件是否存在。</p>
    <p>请返回手机端重新开启 HTTP 实时计分服务或联系管理员。</p>
  </main>
</body>
</html>
''';
}
