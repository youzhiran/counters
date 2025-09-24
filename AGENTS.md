## 语言要求

代码注释、日志和对话回答使用中文!代码注释、日志和对话回答使用中文!
如果有需要更新本文档的地方，请询问用户添加内容。

## 项目UI组件总览

本文档旨在梳理项目中多次使用的核心UI组件和设计模式，以确保后续开发的一致性。

### 一、 核心设计元素

项目中通过对Flutter标准组件的统一风格化，形成了一套核心设计元素。

#### 1. 卡片 (`Card`)

- **用途**: 作为列表中条目或信息块的主要容器，常见于网格和列表布局中。
- **风格**: 项目中的卡片风格多样，以适应不同场景：
    - **轮廓卡片**: 在 `player_page.dart` 中，`Card` 被用于网格布局中的每个玩家项。它设置了
      `elevation: 0` 并通过 `shape` 定义了一个带有透明度边框的 `OutlineInputBorder`，呈现出更扁平、现代的轮廓感。
    - **标准卡片**: 在 `league_list_page.dart` 中，使用标准的 `Card` 包裹 `ListTile`，并设置 `margin`
      ，提供圆角和阴影，这是传统的卡片用法。
- **示例**:
    - `player_page.dart`: 玩家列表中的网格项。
    - `outline_card.dart`: 这是一个将 `Card` 封装后的自定义容器，可传入标题，副标题，按钮等参数，也可以自定义内部组件。

#### 2. 列表项 (`ListTile`)

- **用途**: 在 `Card` 内部或直接在 `ListView` 中显示一行信息，是构建列表页面的基础。
- **结构**: 标准结构包含 `title` (主标题), `subtitle` (副标题), 和 `trailing` (尾部图标/按钮)。
- **交互**: 通常 `onTap` 事件用于导航到详情页，`trailing` 部分放置 `IconButton` 用于执行删除等快捷操作。

#### 3. 按钮

- **主要按钮 (`ElevatedButton`)**: 用于表单提交、创建等主要操作，通常尺寸较大，有填充背景。
- **次要/轮廓按钮 (`OutlinedButton`)**: 用于次要操作，如“选择玩家”，背景透明，有轮廓边框。
- **图标按钮 (`IconButton`)**: 用于在 `AppBar` 或 `ListTile` 的 `trailing` 中放置的图标类操作，如保存、删除。

#### 4. 响应式网格布局 (`GridView`)

- **用途**: 在不同尺寸的屏幕上高效地展示列表内容。在窄屏上（如手机）显示为单列列表，在宽屏上（如平板、桌面端）自动转换为多列网格，提升空间利用率和用户体验。
- **实现**: 通过 `GridView.builder` 结合 `SliverGridDelegateWithMaxCrossAxisExtent` 来实现。其中
  `maxCrossAxisExtent` 属性是关键，它通过一个动态计算来决定网格项的最大宽度，从而控制列数。
- **算法**: `max(minWidth, screenWidth / (screenWidth ~/ idealWidth))`
    - `screenWidth / (screenWidth ~/ idealWidth)`: 这个表达式计算出在当前屏幕宽度下，为了使每列宽度接近
      `idealWidth`，实际应该分配给每列的宽度。
    - `max(minWidth, ...)`: 确保即使在非常宽的屏幕上，每列的宽度也不会小于一个设定的 `minWidth`
      ，避免内容被过度拉伸。
- **示例**:
    - `player_page.dart`: 玩家列表页是此模式的最初实现。
    - `league_list_page.dart`: 联赛列表页也已改造为使用此响应式布局。

### 二、 通用自定义组件

为了提高代码复用性，项目在 `lib/common/widgets/` 目录下沉淀了一系列自定义组件。

#### 1. `SettingListTile`

- **文件**: `setting_list_tile.dart`
- **用途**: 专用于设置页面的 `ListTile`。它封装了设置项的通用布局，通常包含左侧的 `Icon` 和右侧的
  `Switch` 或其他交互控件。
- **价值**: 统一了所有设置页面的风格，便于快速构建新的设置项。

#### 2. `OutlineCard`

- **文件**: `outline_card.dart`
- **用途**: 一个定制化的 `Card`容器，用于显示列表或网格项目。
- **结构**: 可传入标题，副标题，按钮等参数，也可以自定义内部组件。

#### 3. `ConfirmationDialog`

- **文件**: `confirmation_dialog.dart`
- **用途**: 一个标准化的确认对话框 `AlertDialog`。
- **价值**: 封装了对话框的通用结构（标题、内容、确认/取消按钮），使得在不同地方调用确认对话框时，UI和行为保持一致。例如，删除操作前的确认提示。

### 三、 全局服务与叠加层

这些组件或服务通常是无UI的，但对用户体验和代码组织至关重要。

#### 1. `MessageOverlay`

- **文件**: `message_overlay.dart`
- **用途**: 实现一个全局的消息提醒管理器 (`GlobalMsgManager`)，可以在应用的任何地方（无需
  `BuildContext`）弹出成功、警告或错误等提示信息。
- **实现**: 通过 `Overlay` 和 `OverlayEntry` 实现，不会打断用户操作。
- **调用**: 通常通过 `ref.showSuccess('...')` 等封装好的扩展方法来调用。

#### 2. `PageTransitions`

- **文件**: `page_transitions.dart`
- **用途**: 为 `Navigator` 提供了 `pushWithSlide` 扩展方法。
- **价值**: 统一了应用内的页面切换动画（如此处定义的左右滑动），提供了连贯、一致的导航体验。

#### 3. `ErrorHandler`

- **文件**: `lib/common/utils/error_handler.dart`
- **用途**: 提供一个全局统一的错误处理机制。
- **调用**: 通过静态方法 `ErrorHandler.handle(error, stackTrace, prefix: '...')` 来调用。
- **价值**: 封装了项目中的错误处理逻辑。所有 `try-catch` 块中捕获的异常都应通过此方法报告。它确保了错误被一致地记录到日志，并通过
  `SnackBar` 向用户提供即时反馈。用户还可以点击“详情”查看完整的错误信息并复制，极大地提升了调试效率。
- **实现细节**:
    - 使用 `Log.e` 记录详细错误和堆栈信息。
    - 使用 `globalState.scaffoldMessengerKey` 显示一个红色的 `SnackBar` 提示。
    - `SnackBar` 中的“详情”按钮会调用 `globalState.showCommonDialog` 来展示包含完整错误信息的对话框。

#### 4. `globalState.showCommonDialog`

- **来源**: `lib/app/state.dart`
- **用途**: 提供一个全局可访问的底层方法，用于显示任何自定义的对话框内容。它基于 `animations` 包的
  `showModal` 实现，并集成了全局的背景模糊效果。
- **参数**:
    - `child` (required): 需要在对话框中显示的 `Widget`。
    - `dismissible` (optional): 点击背景是否可以关闭对话框，默认为 `true`。
- **价值**: 这是项目中最灵活的对话框弹出方式。与 `ConfirmationDialog` 等封装好的组件不同，
  `showCommonDialog` 允许开发者传入任意 `Widget`
  作为对话框主体，从而实现高度定制化的弹窗界面。例如，它可以用来显示复杂的表单、自定义的提示信息或特殊的交互流程（如
  `showProgressDialog` 就是基于它实现的）。
- **注意**: 此方法非常底层，它只负责弹出和关闭。对话框内部的逻辑、状态管理和UI布局完全由传入的 `child`
  Widget 负责。

### 四、 日志工具 (`Log`)

项目封装了一个全局统一的日志工具，位于 `lib/common/utils/log.dart`，旨在提供分级、易用且包含调用位置的日志输出。
请在必要的时候添加调试日志。

#### 1. 日志级别

日志工具提供了多个级别，用于区分不同重要程度的信息。默认显示级别为 `debug`，意味着 `verbose`
级别的日志在正常运行时不会显示。

- **`Log.v(message)`**: **Verbose (详细)** - 用于输出最详尽的调试信息，如变量的每一步变化、循环的每一次迭代等。此级别默认关闭，只在需要深入追踪问题时通过
  `Log.setLevel(Level.trace)` 开启。
- **`Log.d(message)`**: **Debug (调试)** - 用于输出开发过程中的调试信息，帮助理解代码执行流程。这是最常用的调试级别。
- **`Log.i(message)`**: **Info (信息)** - 用于记录应用运行过程中的重要事件，如用户登录、数据库初始化完成等。
- **`Log.w(message)`**: **Warning (警告)** - 用于记录潜在的问题或非严重错误，应用仍可继续运行。
- **`Log.e(message)`**: **Error (错误)** - 用于记录导致功能失败的严重错误。`ErrorHandler`
  捕获的异常默认使用此级别记录。

#### 2. 使用方法

所有日志方法都是静态的，可以直接通过 `Log` 类调用。

#### 3. 特性

- **自动附加调用位置**: 每条日志都会自动附加其在代码中的调用位置（文件名和行号），便于快速定位问题。
- **可配置的日志级别**: 可以在应用启动时或通过开发者选项动态设置日志的输出级别，以控制日志的详细程度。
- **颜色高亮**: 在支持的控制台（如VS Code、Android Studio）中，不同级别的日志会以不同颜色显示，提高可读性。
- **日志流**: 提供一个全局的 `Log.logStream`，可以监听此流来构建一个应用内的日志显示界面，方便测试和调试。

