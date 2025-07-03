# 数据目录平台特定修改说明

## 修改概述

本次修改实现了数据目录设置的平台特定行为：
- **Windows平台**：继续使用SharedPreferences中的数据目录设置
- **其他平台**（Android、iOS、macOS、Linux）：忽略SharedPreferences设置，使用默认平台目录，并清理相关设置项

## 修改的文件

### 1. `lib/features/setting/data_manager.dart`
- **修改了 `getCurrentDataDir()` 方法**：添加平台检测逻辑
- **新增了 `_cleanupNonWindowsSettings()` 方法**：清理非Windows平台的SharedPreferences设置
- **新增了 `initialize()` 方法**：在应用启动时初始化数据管理器

### 2. `lib/main.dart`
- **添加了DataManager导入**
- **在main()函数中添加了DataManager.initialize()调用**：确保应用启动时正确初始化

### 3. 新增测试文件
- **`test/data_manager_test.dart`**：单元测试验证平台特定行为
- **`scripts/verify_data_manager.dart`**：验证脚本

## 核心逻辑变更

### 原始逻辑
```dart
static Future<String> getCurrentDataDir() async {
  final prefs = await SharedPreferences.getInstance();
  final defaultDir = await getDefaultBaseDir();
  final baseDir = prefs.getString('data_storage_path') ?? defaultDir;
  return getDataDir(baseDir);
}
```

### 修改后逻辑
```dart
static Future<String> getCurrentDataDir() async {
  final defaultDir = await getDefaultBaseDir();
  
  // 仅在Windows平台使用SharedPreferences设置
  if (Platform.isWindows) {
    final prefs = await SharedPreferences.getInstance();
    final baseDir = prefs.getString('data_storage_path') ?? defaultDir;
    return getDataDir(baseDir);
  } else {
    // 非Windows平台使用默认目录，并清理SharedPreferences中的相关设置
    await _cleanupNonWindowsSettings();
    return getDataDir(defaultDir);
  }
}
```

## 清理逻辑

非Windows平台会自动清理以下SharedPreferences键：
- `data_storage_path`：数据存储路径
- `is_custom_path`：是否使用自定义路径标记

清理过程：
1. 检查当前平台是否为Windows
2. 如果不是Windows，检查SharedPreferences中是否存在相关键
3. 删除存在的键并记录日志
4. 使用ErrorHandler处理可能的异常

## 向后兼容性

### Windows平台
- **完全兼容**：现有用户的数据目录设置不受影响
- **功能保持**：数据目录选择和迁移功能正常工作

### 非Windows平台
- **平滑迁移**：自动切换到默认目录，无需用户干预
- **数据安全**：不会删除或移动现有数据文件
- **设置清理**：自动清理无效的SharedPreferences设置

## UI界面

设置界面保持不变：
- Windows平台：显示数据目录设置选项
- 非Windows平台：不显示数据目录设置选项（已有的平台检测逻辑）

## 错误处理

使用项目标准的错误处理模式：
- 使用 `ErrorHandler.handle()` 处理异常
- 记录详细的日志信息
- 不因清理失败而影响应用正常运行

## 测试验证

### 单元测试
运行 `flutter test test/data_manager_test.dart` 验证：
- Windows平台使用SharedPreferences设置
- 非Windows平台使用默认目录并清理设置
- 初始化方法正常工作

### 手动验证
运行验证脚本：
```bash
dart scripts/verify_data_manager.dart
```

## 注意事项

1. **首次运行**：非Windows平台用户首次运行修改后的版本时，会自动清理SharedPreferences设置
2. **数据位置**：非Windows平台的数据目录将固定为系统默认文档目录下的 `counters-data` 文件夹
3. **设置界面**：非Windows平台用户将不再看到数据目录设置选项
4. **日志记录**：所有清理操作都会记录在应用日志中

## 影响范围

### 直接影响
- `DataManager.getCurrentDataDir()` 方法行为
- 非Windows平台的SharedPreferences清理

### 间接影响
- 所有依赖 `getCurrentDataDir()` 的功能（数据库、备份等）
- 非Windows平台用户的数据目录位置

### 无影响
- Windows平台用户体验
- 现有数据文件位置
- 其他SharedPreferences设置
