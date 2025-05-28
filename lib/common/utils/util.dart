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
              color.withAlpha((opacity * 255).toInt()),
              BlendMode.srcIn,
            )
          : null,
    );
  }

  /// 预定义的图标名称常量
  static const String poker_cards = 'poker_cards';
  static const String gardener = 'gardener';
  static const String mahjong = 'mahjong';
  static const String counter = 'counter';
}

class StrUtil {
  /// 简化处理 Markdown 格式的更新说明
  static String md2Str(String markdown) {
    // 移除 Markdown 链接语法，只保留文本
    var text = markdown.replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), markdown);

    // 移除 HTML 标签
    text = text.replaceAll(RegExp(r'<[^>]+>'), '');

    // 处理标题格式
    text = text.replaceAll(RegExp(r'#{1,6}\s'), '● ');

    // 处理列表格式
    text = text.replaceAll(RegExp(r'[-*]\s'), '  - ');

    // 移除多余的空行
    text = text.split('\n').where((line) => line.trim().isNotEmpty).join('\n');

    return text.trim();
  }
}
