import 'package:counters/common/model/base_template.dart';
import 'package:counters/common/model/counter.dart';
import 'package:counters/common/model/landlords.dart';
import 'package:counters/common/model/mahjong.dart';
import 'package:counters/common/model/poker50.dart';

/// 一个工厂类，用于根据模板类型字符串创建对应的模板实例
class TemplateFactory {
  /// 根据模板类型[templateType]创建一个临时的[BaseTemplate]实例。
  ///
  /// 这个实例仅用于访问特定于该模板类型的方法，例如[getValidOtherSetKeys]。
  /// 它不包含任何实际的模板数据，因此不应用于业务逻辑。
  ///
  /// 如果[templateType]无法识别，则抛出[UnimplementedError]。
  static BaseTemplate createTemplateByType(String templateType) {
    switch (templateType) {
      case CounterTemplate.staticTemplateType:
        return CounterTemplate(
            templateName: '', playerCount: 0, targetScore: 0, players: []);
      case LandlordsTemplate.staticTemplateType:
        return LandlordsTemplate(
            templateName: '', playerCount: 0, targetScore: 0, players: []);
      case MahjongTemplate.staticTemplateType:
        return MahjongTemplate(
            templateName: '',
            playerCount: 0,
            targetScore: 0,
            players: [],
            isSystemTemplate: false);
      case Poker50Template.staticTemplateType:
        return Poker50Template(
            templateName: '', playerCount: 0, targetScore: 0, players: []);
      default:
        throw UnimplementedError('未知的模板类型: $templateType');
    }
  }
}
