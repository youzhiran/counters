**FVM (Flutter Version Manager)** 支持在不同分支使用不同的 Flutter 版本，你可以通过在项目里创建 `.fvm` 配置来实现。思路大概是：

---

## 🛠 常用方法

### 1. 针对分支配置 `.fvm/fvm_config.json`
- 在每个分支里手动执行：
  ```bash
  fvm use <flutter_version>
  ```
  这样 `.fvm/fvm_config.json` 会记录当前分支使用的版本。
- 当切换分支时，版本会随配置文件变化。

---

### 2. 配合 Git 钩子自动切换版本
- 使用 **git hooks**（例如 `post-checkout`）检测当前分支，自动运行对应的 `fvm use` 命令：
  ```bash
  # .git/hooks/post-checkout
  BRANCH=$(git rev-parse --abbrev-ref HEAD)

  if [ "$BRANCH" = "dev" ]; then
    fvm use 3.32.8
  elif [ "$BRANCH" = "master" ]; then
    fvm use 3.32.8
  elif [ "$BRANCH" = "ohos" ]; then
    fvm use custom_3.22.0-ohos
  fi
  ```
- 这样切换分支时，会自动应用目标 Flutter 版本。

---

### 3. 用 `.tool-versions`（可选）
- 如果你团队用 **asdf** 或其他版本管理器，也可以配合 `.tool-versions` 文件实现自动切换。

---

💡 **小贴士**
- `.fvm` 目录建议加入 `.gitignore`，只提交 `fvm_config.json`，避免把实际 Flutter SDK 一起提交。
- 团队协作时，保持各分支的 `fvm_config.json` 明确指定版本，这样切换分支就能同步版本。

---



好，那我们直接升级成 **智能自动读取版本** 模式 🚀  
这样每个分支只要维护自己的 `.fvm/fvm_config.json`，Git Hook 会自动读文件里的版本并执行 `fvm use`，再也不用在脚本里硬编码版本号了。

---

## 📜 智能 `post-checkout` 脚本
保存到 `.git/hooks/post-checkout` 并赋予执行权限：
```bash
#!/bin/bash

BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "[FVM] 检测到分支: $BRANCH"

CONFIG_FILE=".fvm/fvm_config.json"

if [ -f "$CONFIG_FILE" ]; then
  # 从 fvm_config.json 读取 "flutterSdkVersion" 值
  VERSION=$(grep -oP '(?<="flutterSdkVersion": ")[^"]+' "$CONFIG_FILE")
  
  if [ -n "$VERSION" ]; then
    echo "[FVM] 从配置读取版本: $VERSION"
    fvm install "$VERSION"
    fvm use "$VERSION"
    fvm global "$VERSION"
    fvm flutter pub get
    echo "[FVM] 已完成自动版本切换: $VERSION"
  else
    echo "[FVM] 配置文件存在，但未找到 flutterSdkVersion 字段"
  fi
else
  echo "[FVM] 未找到 $CONFIG_FILE，跳过版本切换"
fi
```

---

## 🛠 使用说明
1. **每个分支** 先运行一次：
   ```bash
   fvm use <flutter_version>
   ```
   这样就会生成 `.fvm/fvm_config.json` 并写入版本号  
   （建议 `.fvm` 目录 `.gitignore`，只提交 `fvm_config.json`）

2. **下次切换到该分支** 时，脚本会：
  - 自动读取版本号
  - 自动安装（如未安装）
  - 自动切换
  - 自动 `pub get`

---

这样你的团队只要改 `fvm_config.json`，就能全局生效，再也不用每次去改脚本了。

我还可以帮你加上一个 **切回上一个版本的缓存机制**，这样跨分支来回切换会更快，要帮你加上吗 🧩