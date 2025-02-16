# 计分板

一个flutter计分板应用，支持多平台运行。

个人学习作品。本大量项目使用 ai 辅助编程，代码中注释可能由ai生成，仅供参考。

## 编译

### arm64-v8a快速打包命令

安装所需要依赖后

  ```bash
  dart .\generate_version.dart
  flutter build apk --target-platform android-arm64  # arm64-v8a
  ```

### 各平台打包方法

1. 安装 Flutter 和对应平台环境

2. 构建应用

  ```bash
  dart .\setup.dart
  ```

### 指定打包方法

```bash
flutter build apk --target-platform android-arm64  # arm64-v8a
```

```bash
flutter build windows --release # Windows
```

```bash
flutter build apk --target-platform android-arm  # armeabi-v7a
flutter build apk --target-platform android-arm64  # arm64-v8a
flutter build apk --target-platform android-x64  # x86_64
```


## todo list

- [x] 计分功能
- [x] 模板保存与编辑
- [x] 快捷输入与高亮
- [x] GitHub CI/CD
- [ ] 组件模块化
- [ ] 退出后保留计分
- [ ] 局域网联机
