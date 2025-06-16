import 'package:counters/common/model/base_template.dart';
import 'package:counters/common/model/counter.dart';
import 'package:counters/common/model/landlords.dart';
import 'package:counters/common/model/mahjong.dart';
import 'package:counters/common/model/player_info.dart';
import 'package:counters/common/model/poker50.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/common/widgets/message_overlay.dart';
import 'package:counters/features/score/counter/counter_page.dart';
import 'package:counters/features/score/landlords/landlords_page.dart';
import 'package:counters/features/score/mahjong/mahjong_page.dart';
import 'package:counters/features/score/poker50/poker50_page.dart';
import 'package:flutter/material.dart';

class TemplateUtils {
  /// 根据模板类型和数据创建模板实例
  static BaseTemplate? buildTemplateFromType(String templateType,
      Map<String, dynamic> templateMap, List<PlayerInfo> players) {
    switch (templateType) {
      case 'landlords':
        return LandlordsTemplate.fromMap(templateMap, players);
      case 'poker50':
        return Poker50Template.fromMap(templateMap, players);
      case 'mahjong':
        return MahjongTemplate.fromMap(templateMap, players);
      case 'counter':
        return CounterTemplate.fromMap(templateMap, players);
      default:
        Log.e('未知的模板类型: $templateType');
        return null;
    }
  }

  /// 根据模板实例获取对应的会话页面 Widget
  static Widget? buildSessionPageForTemplate(BaseTemplate template) {
    switch (template.runtimeType) {
      case Poker50Template _:
        return Poker50SessionPage(templateId: template.tid);
      case LandlordsTemplate _:
        return LandlordsSessionPage(templateId: template.tid);
      case MahjongTemplate _:
        return MahjongPage(templateId: template.tid);
      case CounterTemplate _:
        return CounterSessionPage(templateId: template.tid);
      default:
        Future.microtask(() => GlobalMsgManager.showError('未知的模板类型'));
        return null; // 返回 null 表示未知模板类型
    }
  }
}
