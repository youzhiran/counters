part of 'home_page.dart';

/// 主页快捷卡固定“彩色”色板（不跟随主题色）
const List<Color> kActionColors = <Color>[
  Color(0xFF6C8EF5), // 蓝
  Color(0xFFFF8A65), // 橙
  Color(0xFF26A69A), // 青
  Color(0xFF7E57C2), // 紫
  Color(0xFFFFCA28), // 黄
  Color(0xff78a355), // 柳色
];

typedef _DidYouKnowTip = ({String title, String description});

const List<_DidYouKnowTip> _kDidYouKnowTips = [
  (
    title: '支持通过模板快速开局',
    description: '在模板页选中常用模板，点击卡片即可创建新的计分局，免去手动配置步骤。',
  ),
  (
    title: '善用局域网联机',
    description: '在同一网络下开启主持或加入联机，多人可实时同步计分结果，适合线下计分。',
  ),
  (
    title: '模板可导出备份',
    description: '在“数据备份与恢复”中导出自定义模板与数据，换设备时直接导入即可无缝衔接。',
  ),
  (
    title: '玩家页面支持搜索',
    description: '进入玩家页面后，可按玩家名称关键字筛选，快速定位玩家。',
  ),
  (
    title: '桌面模式更适合大屏',
    description: '在设置中开启桌面模式，侧边导航与多列布局让鼠标操作更高效。',
  ),
  (
    title: '多平台的计分',
    description: '得益计分目前支持安卓、Windows和鸿蒙平台，不同平台相同版本可轻松联机。',
  ),
  (
    title: '扑克计分只能用于扑克？',
    description: '模板名称仅代表典型计分场景，自定义不同设置项，扑克模板同样可用于其他多人计分。',
  ),
  (
    title: '啊！有bug？',
    description: '必应搜索得益计分，前往官网可联系开发者反馈问题~',
  ),
  (
    title: '绿驿管家',
    description: '烦恼 Windows 中各种绿色软件管理？快来试试开发者新作绿驿管家！GitHub可搜索下载。',
  ),
  (
    title: '摸鱼时刻',
    description:
        '神秘编码：5b+r5p2l5Yqg5YWl5pG46bG8576k5LiA6LW3546p6ICN4oCU4oCUNzA2MTMzNjk0',
  ),
  (
    title: '多轮循环赛',
    description: '循环赛支持增加轮次，可累计积分。点击赛程右上角即可添加。',
  ),
  (
    title: '设置头像',
    description: '编辑玩家弹窗中点击左侧头像可选择玩家头像，若不设置将使用玩家名称的第一个字或emoji。',
  ),
];

final math.Random _didYouKnowRandom = math.Random();
