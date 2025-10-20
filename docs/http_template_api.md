（本文档由ai生成，接口暂未暴露，目前仅作参考保留在此）

# 局域网实时计分 HTTP 接口说明

本文档描述 `ScoreHttpServer` 对外暴露的静态资源与接口协议，便于在自定义 HTML 模板或第三方看板中复用实时计分数据。

## 服务总览

HTTP 服务由主机端启动，默认监听局域网端口（可在主机端设置中调整）。对外暴露的主要资源如下：

| 路径                        | 方法      | 说明               |
|---------------------------|---------|------------------|
| `/`、`/index.html`         | GET     | 返回当前模板的 HTML 页面  |
| `/api/score`              | GET     | 返回实时计分 JSON 数据   |
| `/assets/qr-download.svg` | GET     | 下载 App 的二维码资源    |
| `OPTIONS *`               | OPTIONS | 处理跨域预检请求（允许 GET） |

除二维码资源外，其余数据均为纯文本 UTF-8 输出，不依赖 Cookie 与 Session，可直接在浏览器或其它终端调用。

## `/api/score` 响应结构

接口返回 `application/json; charset=utf-8`，典型响应格式如下：

```json
{
  "status": "ok",
  "meta": {
    "templateName": "3人扑克50分 不允许负数",
    "templateType": "poker50",
    "targetScore": 50,
    "playerCount": 3,
    "currentRound": 2,
    "roundCount": 4,
    "isCompleted": false,
    "sessionId": "game_session_id",
    "reverseWinRule": false,
    "disableVictoryScoreCheck": false,
    "checkVictoryOnScoreChange": false,
    "otherSettings": {
      "isAllowNegative": false
    }
  },
  "players": [
    {
      "playerId": "player-a",
      "name": "玩家A",
      "avatar": "default_avatar.png",
      "avatarColor": null,
      "order": 0,
      "totalScore": 18,
      "roundScores": [
        8,
        6,
        4,
        null
      ],
      "roundExtended": [
        null,
        null,
        null,
        null
      ],
      "rank": 1
    }
  ],
  "playersOrdered": [
    {
      "playerId": "player-a",
      "name": "玩家A",
      "avatar": "default_avatar.png",
      "avatarColor": null,
      "order": 0,
      "totalScore": 18,
      "roundScores": [
        8,
        6,
        4,
        null
      ],
      "roundExtended": [
        null,
        null,
        null,
        null
      ],
      "rank": 1
    }
  ],
  "updatedAt": "2024-05-01T10:23:45.123Z"
}
```

### 顶层字段

| 字段               | 类型      | 说明                                              |
|------------------|---------|-------------------------------------------------|
| `status`         | string  | 请求状态：`ok`、`loading`、`error`、`no_player`、`empty` |
| `message`        | string? | 当 `status` 为非 `ok` 时的提示信息                       |
| `meta`           | object? | 当 `status=ok` 或 `no_player` 时携带的元信息             |
| `players`        | array?  | 按总分排序的玩家列表，`status=ok` 时返回                      |
| `playersOrdered` | array?  | 按模板配置顺序排列的玩家列表，`status=ok` 时返回                  |
| `updatedAt`      | string  | ISO8601 时间戳，表示服务器生成数据的时间                        |

### `meta` 字段

| 字段                          | 类型      | 说明                                                   |
|-----------------------------|---------|------------------------------------------------------|
| `templateName`              | string  | 模板名称                                                 |
| `templateType`              | string  | 模板类型标识（如 `poker50`、`mahjong` 等）                      |
| `targetScore`               | int?    | 目标分数（不同模板语义不同，为空表示未设置）                               |
| `playerCount`               | int     | 玩家数量                                                 |
| `currentRound`              | int     | 当前进行到的回合（从 1 开始，0 代表尚未开始）                            |
| `roundCount`                | int     | 统计到的最大回合数（用于表格列数或总轮数显示）                              |
| `isCompleted`               | bool    | 当前会话是否已标记为结束                                         |
| `sessionId`                 | string? | 会话 ID（可用于区分不同局次）                                     |
| `reverseWinRule`            | bool    | 是否为“分数越高获胜”类型（通常 false 代表低分胜）                        |
| `disableVictoryScoreCheck`  | bool    | 是否关闭目标分检查（true 表示不自动判断胜负）                            |
| `checkVictoryOnScoreChange` | bool    | 是否在每次分数变化时立即检测胜利条件                                   |
| `otherSettings`             | object  | 模板自定义配置，如扑克 50 的 `isAllowNegative`、麻将的 `baseScore` 等 |

### 玩家对象

| 字段              | 类型               | 说明                                                     |
|-----------------|------------------|--------------------------------------------------------|
| `playerId`      | string           | 玩家 ID                                                  |
| `name`          | string           | 玩家名称                                                   |
| `avatar`        | string           | 头像标识：默认 `default_avatar.png`，也可能为 emoji 或图标 code point |
| `avatarColor`   | string?          | 十进制颜色值的字符串，空代表使用默认配色                                   |
| `order`         | int              | 在模板中配置时的顺序（从 0 开始）                                     |
| `totalScore`    | int              | 累计总分                                                   |
| `roundScores`   | array\<int?\>    | 各回合得分，缺失回合为 `null`                                     |
| `roundExtended` | array\<object?\> | 回合扩展字段列表，索引从 0 起对应第 1 回合；斗地主等模板会放入炸弹、地主等信息             |
| `rank`          | int?             | 排名（`playersOrdered` 会补齐到原顺序中）                          |

### 状态判定

| `status`    | 说明                         |
|-------------|----------------------------|
| `loading`   | 计分数据正在初始化，前端可显示“加载中”       |
| `error`     | 获取数据时发生异常，`message` 包含错误提示 |
| `no_player` | 模板未配置玩家，适合提示用户返回主机端补全配置    |
| `empty`     | 当前没有任何计分数据（例如尚未开始，也没有模板信息） |
| `ok`        | 成功返回有效数据                   |

## 轮询与缓存

- 默认模板每 2 秒调用一次 `/api/score`，开发者可按需调整刷新频率，但不建议低于 1 秒，以免对移动端造成压力。
- 服务端对模板 HTML 和二维码资源做了内存缓存，自定义模板修改后需重启 HTTP 服务或清理缓存。
- 所有响应都允许跨域访问（设置了 `Access-Control-Allow-Origin: *`），可在自定义页面中通过 `fetch`、
  `XMLHttpRequest` 或 WebView 调用。

## 自定义模板接入建议

1. **页面结构**
    - 建议以默认模板为参考，保留基本的容器、状态提示与轮询逻辑。
    - 若希望支持横竖布局切换，可模仿默认模板的 `data-layout` 切换逻辑。
    - 如需主题切换，可监听 `body.dataset.theme` 或自行扩展接口。

2. **数据渲染**
    - 解析 `meta` 中的模板类型、目标分、当前回合等信息，渲染到页面标题或副标题。

- `players` 与 `playersOrdered` 可分别用于排名展示和按配置顺序展示。
- 对于含 `roundExtended` 的模板（如斗地主），可从扩展字段中读出地主、炸弹、翻倍等细节。

3. **错误处理**
    - 当 `status !== 'ok'` 时，应根据 `message` 给出提示，并停止继续渲染旧数据。
    - 建议在网络错误时继续轮询，等待主机端恢复。

4. **性能优化**
    - 可对比分数据生成签名（如将 `players` 序列化后取哈希），仅在数据发生变化时重新渲染。
    - 大列表场景中，渲染后可以滚动到最新列/行，增强观感。

5. **安全注意事项**
    - 仅加载本地或可信来源的资源，避免在局域网中执行第三方脚本。
    - 不要在模板中嵌入会访问公网的敏感接口，防止泄漏房间信息。

## 附：默认模板拓展点

默认模板提供了以下前端交互入口，便于在自定义模板中复用：

| 元素/逻辑  | 说明                                  |
|--------|-------------------------------------|
| 主题切换按钮 | `#themeToggle` 切换 `data-theme` 属性   |
| 布局切换按钮 | `#layoutToggle` 切换 `data-layout` 属性 |
| 状态提示   | `#status` 区域显示加载/错误提示               |
| 总结面板   | `#totalSummary` 展示总分概览（可按需启用/隐藏）    |
| 推广卡片   | `promo-card` 区域，右上角放置推广二维码与文案       |

在此基础上升级自定义页面时，可保持上述交互以获得与系统模板一致的体验。

---

如需调整接口协议或增加字段，请同步更新本文档并在模板内做好兼容处理。欢迎就自定义模板接入方案提需求或建议。***
