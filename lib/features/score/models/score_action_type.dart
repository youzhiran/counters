import 'package:flutter/material.dart';

/// 计分界面快捷操作类型定义
enum ScoreActionType {
  showScoreboard,
  showChart,
  toggleLanHost,
  discoverLanSession,
  openLanLog,
  resetGame,
  viewTemplateSettings,
  toggleScreenWakelock,
  openDiceRoller,
}

extension ScoreActionTypeLabel on ScoreActionType {
  /// SharedPreferences 中存储使用的标识
  String get storageKey => name;

  /// 设置界面中展示的标题
  String get displayName {
    switch (this) {
      case ScoreActionType.showScoreboard:
        return '当前计分情况';
      case ScoreActionType.showChart:
        return '查看计分图表';
      case ScoreActionType.toggleLanHost:
        return '启动/停止局域网主机';
      case ScoreActionType.discoverLanSession:
        return '发现局域网计分';
      case ScoreActionType.openLanLog:
        return '程序日志';
      case ScoreActionType.resetGame:
        return '重置计分';
      case ScoreActionType.viewTemplateSettings:
        return '查看模板设置';
      case ScoreActionType.toggleScreenWakelock:
        return '切换屏幕常亮';
      case ScoreActionType.openDiceRoller:
        return '掷骰子';
    }
  }

  /// 设置界面中展示的图标
  IconData get displayIcon {
    switch (this) {
      case ScoreActionType.showScoreboard:
        return Icons.sports_score;
      case ScoreActionType.showChart:
        return Icons.stacked_line_chart;
      case ScoreActionType.toggleLanHost:
        return Icons.wifi;
      case ScoreActionType.discoverLanSession:
        return Icons.search;
      case ScoreActionType.openLanLog:
        return Icons.article_outlined;
      case ScoreActionType.resetGame:
        return Icons.restart_alt_rounded;
      case ScoreActionType.viewTemplateSettings:
        return Icons.info_outline;
      case ScoreActionType.toggleScreenWakelock:
        return Icons.flashlight_on_outlined;
      case ScoreActionType.openDiceRoller:
        return Icons.casino_outlined;
    }
  }

  /// 是否属于“计分工具”分类
  bool get isTool => this == ScoreActionType.openDiceRoller;

  /// 分类名称
  String get categoryName => isTool ? '计分工具' : '常规操作';
}

/// 默认的快捷操作顺序
const List<ScoreActionType> kDefaultPrimaryActionOrder = [
  ScoreActionType.showScoreboard,
  ScoreActionType.showChart,
  ScoreActionType.resetGame,
  ScoreActionType.viewTemplateSettings,
  ScoreActionType.toggleLanHost,
  ScoreActionType.discoverLanSession,
  ScoreActionType.openLanLog,
  ScoreActionType.toggleScreenWakelock,
];

/// 计分工具列表（不参与顺序调整）
const List<ScoreActionType> kScoreToolActions = [
  ScoreActionType.openDiceRoller,
];
