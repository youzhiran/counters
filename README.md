# 计分板

一个flutter计分板应用，支持多平台运行。

个人学习作品。本大量项目使用 ai 辅助编程，代码中注释可能由ai生成，仅供参考。

## 下载

<a href="https://github.com/youzhiran/counters/releases"><img alt="Get it on GitHub" src="snapshots/get-it-on-github.svg" width="200px"/></a>


## 编译

### 当前平台各架构打包方法

1. 安装 Flutter 和对应平台环境

2. 构建当前平台各架构应用

  ```bash
  dart .\setup.dart
  ```

3. 输出文件夹在项目根目录dist目录下


### 指定打包方法


```txt
PS D:\MyCode\> dart setup.dart --help # 显示帮助信息
Usage: dart build.dart [options]

Options:
--arch <architecture>  Specify build architectures (comma-separated)
Available: arm, arm64, x64, amd64, all
--help                 Show this help message

Platform defaults:
Android: arm, arm64, x64
Windows: amd64
```



```bash
dart setup.dart --arch arm,arm64 # 构建指定架构
```

```bash
dart setup.dart --arch all # 构建全部架构
```

```bash
dart setup.dart --arch arm64 # 构建arm64
```

```bash
dart setup.dart --arch amd64 # 构建Windows amd64
```

```bash
dart setup.dart --help # 显示帮助信息
```

## todo list

- [x] 计分功能
- [x] 模板保存与编辑
- [x] 快捷输入与高亮
- [x] GitHub CI/CD
- [x] 退出后保留计分
- [x] 历史计分功能
- [ ] 🚧组件模块化
- [ ] 局域网联机
