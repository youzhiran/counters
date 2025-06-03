import 'package:flutter/material.dart';

/// 设置页面的列表项基础组件
class _BaseSettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final EdgeInsetsGeometry? padding;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Widget? switchWidget;

  const _BaseSettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.padding,
    this.trailing,
    this.onTap,
    this.switchWidget,
  });

  @override
  Widget build(BuildContext context) {
    final content = switchWidget != null
        ? SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Icon(icon, size: 24),
            title: Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            subtitle: subtitle != null
                ? Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                  )
                : null,
            value: (switchWidget as Switch).value,
            onChanged: (switchWidget as Switch).onChanged,
          )
        : ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(icon, size: 24),
            title: Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            subtitle: subtitle != null
                ? Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trailing != null) ...[
                  trailing!,
                  const SizedBox(width: 8),
                ],
                const Icon(Icons.chevron_right, size: 24),
              ],
            ),
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: content,
        ),
      ),
    );
  }
}

/// 设置页面的列表项组件
class SettingListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final EdgeInsetsGeometry? padding;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.padding,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseSettingTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      padding: padding,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

/// 设置页面的开关列表项组件
class SettingSwitchListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final EdgeInsetsGeometry? padding;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const SettingSwitchListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.padding,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseSettingTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      padding: padding,
      switchWidget: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
