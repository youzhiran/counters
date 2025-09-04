import 'dart:math';

import 'package:flutter/material.dart';

/// 一个响应式的 GridView 容器，可以根据屏幕宽度自动调整列数。
class ResponsiveGridView extends StatelessWidget {
  /// 最小的交叉轴范围，用于计算列数。
  final double minItemWidth;

  /// 理想的交叉轴范围，用于计算列数。
  final double idealItemWidth;

  /// GridView 的内边距。
  final EdgeInsetsGeometry padding;

  /// 子组件的高度。
  final double itemHeight;

  /// 子组件的数量。
  final int itemCount;

  /// 子组件的构建器。
  final IndexedWidgetBuilder itemBuilder;

  /// 子组件之间的交叉轴间距。
  final double crossAxisSpacing;

  /// 子组件之间的主轴间距。
  final double mainAxisSpacing;

  const ResponsiveGridView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.minItemWidth = 300.0,
    this.idealItemWidth = 350.0,
    this.itemHeight = 78.0,
    this.padding = const EdgeInsets.fromLTRB(12, 12, 12, 78),
    this.crossAxisSpacing = 0.0,
    this.mainAxisSpacing = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: max(
          minItemWidth,
          MediaQuery.of(context).size.width /
              (MediaQuery.of(context).size.width ~/ idealItemWidth),
        ),
        mainAxisExtent: itemHeight,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}
