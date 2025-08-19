// lib/ui/widgets/settings/setting_tile.dart
import 'package:flutter/material.dart';

class SettingTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? textColor;
  final bool enabled;

  const SettingTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.textColor,
    this.enabled = true,
  });

  const SettingTile.toggle({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    required bool value,
    required Function(bool) onChanged,
    this.enabled = true,
  }) : onTap = null,
       trailing = Switch(
         value: value,
         onChanged: enabled ? onChanged : null,
       ),
       textColor = null;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: enabled,
      leading: leading,
      title: Text(
        title,
        style: textColor != null 
          ? TextStyle(color: textColor)
          : null,
      ),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
