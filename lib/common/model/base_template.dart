import 'dart:convert';

import 'package:counters/common/model/player_info.dart';
import 'package:uuid/uuid.dart';

abstract class BaseTemplate {
  final String tid;
  String templateName;
  int playerCount;
  int targetScore;
  List<PlayerInfo> players;
  bool isSystemTemplate;
  final String? baseTemplateId;
  Map<String, dynamic>? otherSet;

  BaseTemplate({
    String? tid,
    required this.templateName,
    required this.playerCount,
    required this.targetScore,
    required this.players,
    this.isSystemTemplate = false,
    this.baseTemplateId,
    this.otherSet,
  }) : tid = tid ?? const Uuid().v4();

  Map<String, dynamic> toMap();

  // 新增：标准toJson方法，便于网络传输
  Map<String, dynamic> toJson() => toMap();

  // 抽象复制方法
  BaseTemplate copyWith({
    String? tid,
    String? templateName,
    int? playerCount,
    int? targetScore,
    List<PlayerInfo>? players,
    bool? isSystemTemplate,
    String? baseTemplateId,
    Map<String, dynamic>? otherSet,
  });

  // 获取指定类型的值，如果不存在或类型不匹配则返回默认值
  T? getOtherSet<T>(String key, {T? defaultValue}) {
    try {
      final value = otherSet?[key];
      if (value == null) return defaultValue;
      if (value is T) return value;
      return defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  // 设置值并返回是否成功
  bool setOtherSet(String key, dynamic value) {
    try {
      otherSet ??= {};
      otherSet![key] = value;
      return true;
    } catch (e) {
      return false;
    }
  }

  // 移除指定键值
  bool removeOtherSet(String key) {
    try {
      otherSet?.remove(key);
      return true;
    } catch (e) {
      return false;
    }
  }

  // 将 otherSet 转换为 JSON 字符串
  String? otherSetToJson() {
    return otherSet == null ? null : jsonEncode(otherSet);
  }

  // 从 JSON 字符串解析 otherSet
  bool otherSetFromJson(String? jsonString) {
    try {
      if (jsonString == null || jsonString.isEmpty) {
        otherSet = null;
        return true;
      }
      otherSet = jsonDecode(jsonString);
      return true;
    } catch (e) {
      return false;
    }
  }
}
// // 读取数值
// int baseScore = template.getOtherSet<int>('baseScore', defaultValue: 1) ?? 1;
// bool allowDouble = template.getOtherSet<bool>('allowDouble', defaultValue: false) ?? false;
// String gameMode = template.getOtherSet<String>('gameMode', defaultValue: 'normal') ?? 'normal';

// // 设置值
// template.setOtherSet('baseScore', 5);
// template.setOtherSet('allowDouble', true);

// // 移除设置
// template.removeOtherSet('tempSetting');
