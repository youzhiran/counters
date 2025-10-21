2025年10月21日

## 新增计分模板开发指引

在扩展新的计分模板类型时，请按以下清单同步修改，确保模板在单机、联机和历史数据中都能正常运作。

### 1. 数据模型与数据库

- 在 `lib/common/model/` 目录下定义新的模板类，补充必需的字段、`copyWith`、`fromMap` 与 `toMap` 方法，并声明
  `staticTemplateType` 常量。
- 更新 `lib/common/model/template_factory.dart`，为 `createTemplateByType` 增加新模板分支，避免模板反序列化时报错。
- 如需内置系统模板，补充 `lib/common/db/db_helper.dart` 中 `_initialSystemTemplates` 列表，并视需要在
  `lib/common/db/migrations.dart` 加入补丁以为旧库写入缺失模板。

### 2. 模板装配与页面路由

- 在 `lib/common/utils/template_utils.dart` 中同时更新 `buildTemplateFromType` 与
  `buildSessionPageForTemplate`，保证模板能被正确解析并路由到新页面。
- 扩展 `lib/features/home/session_page_loader.dart` 里的分发逻辑，让异步加载流程认识新的
  `templateType`。
- 为新模板创建独立的配置页与计分页面（建议放置在 `lib/features/score/<模板名>/` 目录），并在
  `HomePage.buildSessionPage` 相关调用链中调用。

### 3. 前端展示与交互

- 补充 `lib/common/widgets/template_card.dart` 的模板图标、配置页跳转及“查看模板设置”逻辑，让模板管理界面展示一致。
- 根据模板特性，更新 `lib/features/score/base_page.dart` 快捷操作、
  `lib/features/score/widgets/base_score_edit_dialog.dart` 的负数校验，以及
  `lib/common/fragments/input_panel.dart` 的快速输入限制。

### 4. 联机与外部输出

- 为局域网实时比分新增 HTML 模板（放在 `assets/lan_http_templates/`），并在
  `lib/features/lan/resources/score_http_templates.dart` 的 `templateAssetByType` 中登记映射，同时在
  `pubspec.yaml` 中声明资源路径。
- 若模板需要额外的实时同步字段，请同步调整 `lib/features/lan/score_http_server.dart` 的数据打包结构。

### 5. 其它注意事项

- 检查 `lib/features/score/score_provider.dart`、统计报表、日志等位置是否需要针对新模板添加特化逻辑。
- 完成以上修改后，至少运行一次 `flutter analyze` 与核心流程自测，验证新模板在“快速体验”、“联赛”、“历史记录”以及
  LAN 联机场景下的行为。
