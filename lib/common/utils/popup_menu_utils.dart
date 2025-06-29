import 'package:flutter/material.dart';

/// 弹窗菜单工具类
/// 提供统一的弹窗定位和显示逻辑
class PopupMenuUtils {
  /// 根据全局点击位置计算弹窗菜单的显示位置
  ///
  /// [globalPosition] - 全局点击位置
  /// [context] - BuildContext，用于获取屏幕尺寸进行边界检测
  ///
  /// 返回计算好的RelativeRect位置信息
  static RelativeRect calculateMenuPositionFromGlobalPosition(
    Offset globalPosition,
    BuildContext context,
  ) {
    // 获取屏幕尺寸用于边界检测
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    // 可用屏幕区域
    final availableWidth = screenSize.width;
    final availableHeight = screenSize.height - padding.top - padding.bottom;

    // 预估菜单尺寸（用于边界检测）
    const estimatedMenuWidth = 200.0;
    const estimatedMenuHeight = 150.0;

    double left = globalPosition.dx;
    double top = globalPosition.dy;

    // 水平边界检测
    if (left + estimatedMenuWidth > availableWidth) {
      left = availableWidth - estimatedMenuWidth;
    }
    if (left < 0) {
      left = 0;
    }

    // 垂直边界检测
    if (top + estimatedMenuHeight > availableHeight) {
      top = globalPosition.dy - estimatedMenuHeight;
    }
    if (top < padding.top) {
      top = padding.top;
    }

    return RelativeRect.fromLTRB(
      left,
      top,
      left + estimatedMenuWidth,
      top + estimatedMenuHeight,
    );
  }

  /// 计算弹窗菜单的显示位置（兼容旧版本）
  ///
  /// [context] - 当前组件的BuildContext
  /// [offsetX] - 水平偏移量，默认从右侧200像素处显示
  /// [offsetY] - 垂直偏移量，默认向下偏移50像素
  ///
  /// 返回计算好的RelativeRect位置信息，如果计算失败返回null
  @Deprecated('使用 calculateMenuPositionFromGlobalPosition 获得更好的定位效果')
  static RelativeRect? calculateMenuPosition(
    BuildContext context, {
    double offsetX = 200.0,
    double offsetY = 50.0,
  }) {
    // 获取当前点击的组件位置信息
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;

    // 计算菜单显示位置，使其显示在组件的右侧
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    return RelativeRect.fromLTRB(
      offset.dx + size.width - offsetX, // 从右侧offsetX像素处显示
      offset.dy + offsetY, // 垂直方向向下偏移offsetY像素
      offset.dx + size.width,
      offset.dy + size.height,
    );
  }

  /// 显示选择菜单（推荐使用，支持基于点击位置的精确定位）
  ///
  /// [context] - BuildContext
  /// [items] - 菜单项列表
  /// [globalPosition] - 全局点击位置，如果提供则使用精确定位
  /// [position] - 菜单显示位置，如果为null且globalPosition也为null会自动计算
  /// [offsetX] - 水平偏移量（仅在position和globalPosition都为null时生效）
  /// [offsetY] - 垂直偏移量（仅在position和globalPosition都为null时生效）
  ///
  /// 返回用户选择的值，如果取消选择返回null
  static Future<T?> showSelectionMenu<T>({
    required BuildContext context,
    required List<PopupMenuItem<T>> items,
    Offset? globalPosition,
    RelativeRect? position,
    double offsetX = 200.0,
    double offsetY = 50.0,
  }) async {
    // 优先使用全局位置进行精确定位
    if (globalPosition != null) {
      position = calculateMenuPositionFromGlobalPosition(globalPosition, context);
    } else {
      // 如果没有提供位置，使用旧的自动计算方法（向后兼容）
      // ignore: deprecated_member_use_from_same_package
      position ??= calculateMenuPosition(
        context,
        offsetX: offsetX,
        offsetY: offsetY,
      );
    }

    if (position == null) return null;

    return await showMenu<T>(
      context: context,
      position: position,
      items: items,
      elevation: 8.0, // 添加阴影效果
    );
  }

  /// 显示选择菜单（基于点击位置的便捷方法）
  ///
  /// [context] - BuildContext
  /// [items] - 菜单项列表
  /// [globalPosition] - 全局点击位置
  ///
  /// 返回用户选择的值，如果取消选择返回null
  static Future<T?> showSelectionMenuAtPosition<T>({
    required BuildContext context,
    required List<PopupMenuItem<T>> items,
    required Offset globalPosition,
  }) async {
    return showSelectionMenu<T>(
      context: context,
      items: items,
      globalPosition: globalPosition,
    );
  }

  /// 创建带选中状态的菜单项
  /// 
  /// [value] - 菜单项的值
  /// [text] - 显示的文本
  /// [isSelected] - 是否被选中
  /// [context] - BuildContext，用于获取主题色
  /// 
  /// 返回配置好的PopupMenuItem
  static PopupMenuItem<T> createMenuItem<T>({
    required T value,
    required String text,
    required bool isSelected,
    required BuildContext context,
  }) {
    return PopupMenuItem<T>(
      value: value,
      child: Row(
        children: [
          Icon(
            Icons.check,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
          ),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  /// 创建端口选择菜单项
  /// 
  /// [port] - 端口号
  /// [defaultPort] - 默认端口号
  /// [currentPort] - 当前选中的端口号
  /// [context] - BuildContext
  /// 
  /// 返回配置好的端口菜单项
  static PopupMenuItem<int> createPortMenuItem({
    required int port,
    required int defaultPort,
    required int currentPort,
    required BuildContext context,
  }) {
    final isSelected = currentPort == port;
    final isDefault = port == defaultPort;
    final text = '$port${isDefault ? ' (默认)' : ''}';

    return createMenuItem<int>(
      value: port,
      text: text,
      isSelected: isSelected,
      context: context,
    );
  }
}
