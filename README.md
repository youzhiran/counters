# 计分板

一个flutter计分板应用，支持多平台运行。推荐使用 Android 体验，其他平台尚未完整测试。

个人学习作品。本大量项目使用 ai 辅助编程，代码中注释可能由ai生成，仅供参考。

程序支持：

- 自定义存储位置（Windows）
- 自定义计分模板
- 深色模式与8种预定义主题
- 计分功能与图表走势
- 快捷输入分数

<p style="text-align: center;">
    <img alt="snapshots" src="snapshots/img.png">
</p>

## 下载

带有 beta 或 alpha 后缀的版本为测试版，带有 rc 后缀的版本为正式版。请按需下载。

<a href="https://github.com/youzhiran/counters/releases"><img alt="Get it on GitHub" src="snapshots/get-it-on-github.svg" width="200px"/></a>


## 编译

### 当前平台各架构打包方法

1. 安装 Flutter 和对应平台环境

2. 构建当前平台各架构应用

  ```bash
  dart .\setup.dart
  ```

3. 输出文件夹在项目根目录dist目录下

### Windows打包安卓和Windows

  ```bash
  dart .\setup.dart all
  ```

### Windows打包安卓

  ```bash
  dart .\setup.dart android
  ```

## Todo list

### v0.9.x

- [x] 程序日志系统
- [x] 全新设计的计分流程及玩家管理
- [x] 使用 sqlite 代替 hive
- [x] 优化中文字体显示效果
- [x] 设置&数据库重置功能
- [x] 数据迁移功能（目前仅限Windows）
- [x] 新增斗地主计分系统模板
- [x] 使用 Riverpod 管理状态
- [x] 玩家头像优化，支持显示 emoji 
- [x] 玩家页面支持搜索

### v0.10.x

- [ ] 局域网联机
- [ ] 更多新特性...

## 统计

支持开发最简单的方法是点击页面顶部的星号（⭐）

或点击[下载](https://github.com/youzhiran/counters/releases/latest)体验

![](https://img.shields.io/github/downloads/youzhiran/counters/total)

