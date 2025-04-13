import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgIconUtils {
  /// 获取 SVG 图标
  /// [name] SVG 文件名（不包含扩展名）
  /// [size] 图标大小
  /// [color] 图标颜色
  /// [opacity] 透明度 0-1
  static Widget getIcon(
    String name, {
    double size = 24,
    Color? color,
    double opacity = 1.0,
  }) {
    return SvgPicture.asset(
     'assets/svg/$name.svg',
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(
              color.withOpacity( opacity),
              BlendMode.srcIn,
            )
          : null,
    );
  }

  /// 预定义的图标名称常量
  static const String poker_cards = 'poker_cards';
  static const String gardener = 'gardener';
}
