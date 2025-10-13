import 'package:collection/collection.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/features/score/models/score_action_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _scoreActionOrderKey = 'score_action_order';

/// 负责维护计分界面快捷操作顺序，并持久化到 SharedPreferences
class ScoreActionOrderNotifier extends StateNotifier<List<ScoreActionType>> {
  ScoreActionOrderNotifier() : super(kDefaultPrimaryActionOrder) {
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_scoreActionOrderKey);
      if (stored == null) {
        return;
      }

      final mapped = stored
          .map((key) => ScoreActionType.values
              .firstWhereOrNull((type) => type.storageKey == key))
          .whereType<ScoreActionType>()
          .where((type) => !type.isTool)
          .toList();

      state = _normalizeWithDefaults(mapped);
      Log.d('计分操作顺序已从本地加载: $state');
    } catch (e, stackTrace) {
      Log.e('加载计分操作顺序失败: $e');
      Log.e('StackTrace: $stackTrace');
    }
  }

  /// 更新排序并写入 SharedPreferences
  Future<void> updateOrder(List<ScoreActionType> newOrder) async {
    state = _normalizeWithDefaults(newOrder);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _scoreActionOrderKey,
        state.map((type) => type.storageKey).toList(),
      );
      Log.d('计分操作顺序已更新: $state');
    } catch (e, stackTrace) {
      Log.e('保存计分操作顺序失败: $e');
      Log.e('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// 重置为默认顺序
  Future<void> resetToDefault() async {
    await updateOrder(kDefaultPrimaryActionOrder);
  }

  /// 确保缺失的默认项被加入列表末尾
  List<ScoreActionType> _normalizeWithDefaults(List<ScoreActionType> current) {
    final normalized = current.where((type) => !type.isTool).toList();
    for (final type in kDefaultPrimaryActionOrder) {
      if (!normalized.contains(type)) {
        normalized.add(type);
      }
    }
    // 如果某些存档数据重复或无效，移除重复项
    final deduplicated = <ScoreActionType>[];
    for (final type in normalized) {
      if (!deduplicated.contains(type)) {
        deduplicated.add(type);
      }
    }
    return deduplicated;
  }
}

final scoreActionOrderProvider =
    StateNotifierProvider<ScoreActionOrderNotifier, List<ScoreActionType>>(
  (ref) => ScoreActionOrderNotifier(),
);
