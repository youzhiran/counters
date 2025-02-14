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

1. 安装 Flutter 环境

2. 构建应用

    - android

        1. 安装 Android 环境

        2. 运行版本生成脚本

           ```bash
           dart .\generate_version.dart
           ```
           
        3. 分架构打包 apk
           ```bash
           flutter build apk --target-platform android-arm64  # arm64-v8a
           ```

           ```bash
           flutter build apk --target-platform android-arm  # armeabi-v7a
           flutter build apk --target-platform android-arm64  # arm64-v8a
           flutter build apk --target-platform android-x64  # x86_64
           ```

    - windows

        调试阶段使用Windows正常，尚未测试打包，理论可以直接运行、打包。

   -  其他平台

        尚未测试。


## todo list

- [x] 计分功能
- [x] 模板保存与编辑
- [x] 快捷输入与高亮
- [ ] 组件模块化
- [ ] GitHub CI/CD
- [ ] 退出后保留计分
- [ ] 局域网联机
