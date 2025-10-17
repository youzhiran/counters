class ScoreHttpTemplates {
  ScoreHttpTemplates._();

  /// 默认模板资源路径
  static const String defaultTemplateAsset =
      'assets/lan_http_templates/scoreboard_default.html';

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
