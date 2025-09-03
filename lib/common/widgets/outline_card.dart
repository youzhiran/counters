import 'package:flutter/material.dart';

/// 一个可复用的、带有轮廓边框的卡片组件。
///
/// 通常用于列表或网格中，提供统一的视觉风格。
class OutlineCard extends StatelessWidget {
  /// 卡片的主标题 Widget。
  final Widget? title;

  /// 卡片的副标题 Widget。
  final Widget? subtitle;

  /// 显示在标题左侧的 Widget，通常是一个 Icon。
  final Widget? leading;

  /// 显示在标题右侧的 Widget，通常是一个 IconButton 或其他操作按钮。
  final Widget? trailing;

  /// 点击整个卡片时的回调函数 (仅在默认ListTile模式下有效)。
  final VoidCallback? onTap;

  /// 自定义卡片内容的Widget。如果提供了child，则会忽略title, subtitle, leading, trailing和onTap。
  final Widget? child;

  const OutlineCard({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.child,
  }) : assert(child != null || title != null,
            'Either a child or a title must be provided.');

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.hardEdge, // 修复水波纹裁剪问题
      shape: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(
          color: Theme.of(context)
              .colorScheme
              .outline
              .withAlpha((0.2 * 255).toInt()),
        ),
      ),
      child: Center(
        child: child ??
            ListTile(
              leading: leading,
              title: title!,
              subtitle: subtitle,
              trailing: trailing,
              onTap: onTap,
            ),
      ),
    );
  }
}
