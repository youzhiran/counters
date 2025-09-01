# 计分板

一个flutter计分板应用，支持多平台运行。推荐使用 Android 体验，其他平台尚未完整测试。

个人学习作品。本大量项目使用 ai 辅助编程，代码中注释可能由ai生成，仅供参考。


_想要快速了解本项目？可查看 DeepWiki ：_
 
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/youzhiran/counters)

## 程序主要功能与截图

Counters 是一款用于桌游计分的 flutter 多平台计分程序，目前程序支持以下游戏的计分。

- 计分扑克牌
- 斗地主
- 麻将（两位小数计分）
- 点击计数器

Counters 同时支持下面的特色功能：

- 计分走势图
- 局域网连接，同步查看计分数据

_图片供参考，最新 UI 及特性请下载安装包体验_

<p style="text-align: center;">
    <img alt="snapshots" src="snapshots/1.png">
    <img alt="snapshots" src="snapshots/2.png">
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

### v0.11.x

- [ ] 🚧联赛模式

## 统计

支持开发最简单的方法是点击页面顶部的星号（⭐）

或点击[下载](https://github.com/youzhiran/counters/releases/latest)体验

![](https://img.shields.io/github/downloads/youzhiran/counters/total)

## 致谢

DeepSeek、Gemini、GPT、Claude、Trae、Cursor、Augment、Gemini CLI 等 AI 模型和工具的大力支持。

