# 备份功能测试文档

本目录包含了备份功能模块的全面单元测试和集成测试。

## 测试结构

```
test/features/backup/
├── README.md                           # 本文档
├── backup_models_test.dart             # 数据模型测试
├── backup_service_test.dart            # 核心服务测试
├── backup_provider_test.dart           # Riverpod状态管理测试
├── backup_preview_provider_test.dart   # 预览功能测试
├── backup_integration_test.dart        # 集成测试
├── services/
│   └── hash_service_test.dart          # 哈希服务测试
└── widget/
    └── backup_page_test.dart           # UI组件测试
```

## 测试覆盖范围

### 1. 数据模型测试 (`backup_models_test.dart`)
- ✅ BackupMetadata 序列化/反序列化
- ✅ DatabaseFile 数据结构
- ✅ BackupData 完整数据模型
- ✅ BackupState 状态管理
- ✅ CompatibilityInfo 兼容性信息
- ✅ HashInfo 哈希信息
- ✅ ExportOptions/ImportOptions 选项配置

### 2. 哈希服务测试 (`services/hash_service_test.dart`)
- ✅ SHA-256 哈希生成
- ✅ 文件完整性验证
- ✅ 哈希值比较
- ✅ 错误处理

### 3. 备份服务测试 (`backup_service_test.dart`)
- ✅ ZIP文件创建和双层结构
- ✅ SharedPreferences数据备份
- ✅ 数据库文件备份
- ✅ 文件完整性哈希生成
- ✅ 用户自定义保存路径
- ✅ ZIP文件解析和验证
- ✅ 哈希完整性验证
- ✅ 版本兼容性检查
- ✅ 原子操作和错误回滚
- ✅ 进度回调机制
- ✅ 错误处理（权限、文件访问等）

### 4. Riverpod状态管理测试 (`backup_provider_test.dart`)
- ✅ BackupManager 状态变化
- ✅ 导出/导入操作的状态管理
- ✅ 进度更新机制
- ✅ 错误状态处理
- ✅ ExportOptionsManager 选项管理
- ✅ ImportOptionsManager 选项管理
- ✅ 状态重置和清理

### 5. 预览功能测试 (`backup_preview_provider_test.dart`)
- ✅ 备份文件分析
- ✅ 元数据解析
- ✅ 数据统计计算
- ✅ 数据类型识别
- ✅ 兼容性检查集成
- ✅ 哈希验证状态
- ✅ 当前数据统计对比

### 6. UI组件测试 (`widget/backup_page_test.dart`)
- ✅ 基本UI元素渲染
- ✅ 导出/导入选项交互
- ✅ 按钮点击响应
- ✅ 进度显示
- ✅ 错误信息展示
- ✅ 响应式布局适配

### 7. 集成测试 (`backup_integration_test.dart`)
- ✅ 完整的导出-导入流程
- ✅ 数据完整性验证
- ✅ 版本兼容性处理
- ✅ 错误恢复和回滚
- ✅ 并发操作处理
- ✅ 性能测试

## 运行测试

### 运行所有备份功能测试
```bash
flutter test test/features/backup/
```

### 运行特定测试文件
```bash
# 运行模型测试
flutter test test/features/backup/backup_models_test.dart

# 运行服务测试
flutter test test/features/backup/backup_service_test.dart

# 运行Provider测试
flutter test test/features/backup/backup_provider_test.dart

# 运行集成测试
flutter test test/features/backup/backup_integration_test.dart
```

### 运行测试并生成覆盖率报告
```bash
flutter test --coverage test/features/backup/
genhtml coverage/lcov.info -o coverage/html
```

## 测试数据和Mock

### 测试辅助工具 (`test/helpers/test_helpers.dart`)
提供了丰富的测试辅助方法：
- 创建测试用的备份数据
- 生成测试ZIP文件
- 设置Mock SharedPreferences
- 平台通道Mock设置
- 临时文件管理

### Mock数据
- 测试用的SharedPreferences数据
- 模拟的数据库文件
- 各种兼容性级别的备份文件
- 损坏的ZIP文件（用于错误处理测试）

## 测试最佳实践

### 1. 测试隔离
- 每个测试都有独立的setUp和tearDown
- 使用临时文件，测试后自动清理
- Mock外部依赖，避免测试间相互影响

### 2. 错误处理测试
- 测试各种异常情况
- 验证ErrorHandler.handle()的调用
- 确保错误状态正确传播

### 3. 状态管理测试
- 验证Riverpod状态的正确变化
- 测试异步操作的状态管理
- 确保状态重置和清理正确

### 4. 性能测试
- 大数据量处理测试
- 操作时间限制验证
- 内存使用监控

## 已知限制和注意事项

1. **平台依赖**: 某些测试依赖于平台特定的功能，使用Mock进行模拟
2. **文件系统**: 测试使用临时文件系统，可能与实际环境有差异
3. **权限测试**: 权限相关的测试在不同平台上可能表现不同
4. **并发测试**: 并发操作测试可能在不同硬件上有不同结果

## 测试维护

### 添加新测试
1. 在相应的测试文件中添加新的test case
2. 使用TestHelpers中的辅助方法
3. 确保测试的隔离性和可重复性
4. 添加适当的文档注释

### 更新现有测试
1. 当备份功能发生变化时，及时更新相关测试
2. 保持测试数据的一致性
3. 更新Mock对象以反映新的接口

### 测试覆盖率目标
- 单元测试覆盖率：> 90%
- 集成测试覆盖率：> 80%
- 关键路径覆盖率：100%

## 故障排除

### 常见问题
1. **临时文件清理失败**: 检查文件权限和占用情况
2. **Mock设置不生效**: 确保在setUp中正确调用TestHelpers.setupPlatformChannelMocks()
3. **异步测试超时**: 增加测试超时时间或优化测试逻辑
4. **状态管理测试失败**: 检查Provider的生命周期管理

### 调试技巧
1. 使用`debugPrint`输出测试过程中的关键信息
2. 检查临时文件的内容以验证数据正确性
3. 使用`pumpAndSettle()`确保Widget测试中的异步操作完成
4. 监听Provider状态变化以调试状态管理问题

## 贡献指南

1. 新增功能时必须添加相应的测试
2. 测试代码应该清晰、可读、可维护
3. 遵循现有的测试模式和命名约定
4. 确保所有测试都能通过CI/CD流水线
