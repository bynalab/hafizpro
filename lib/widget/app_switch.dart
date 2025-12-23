import 'package:flutter/material.dart';
import 'package:hafiz_test/util/app_colors.dart';

class AppSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Switch(
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppColors.green500,
      activeColor: Colors.white,
      inactiveTrackColor:
          isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB),
      inactiveThumbColor: const Color(0xFF9CA3AF),
    );
  }
}

class AppSwitchListTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget title;
  final Widget? subtitle;
  final Widget? secondary;

  const AppSwitchListTile({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.subtitle,
    this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: title,
      subtitle: subtitle,
      secondary: secondary,
      activeTrackColor: AppColors.green500,
      activeColor: Colors.white,
      inactiveTrackColor:
          isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB),
      inactiveThumbColor: const Color(0xFF9CA3AF),
    );
  }
}
