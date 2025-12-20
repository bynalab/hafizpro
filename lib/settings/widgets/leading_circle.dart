import 'package:flutter/material.dart';

class LeadingCircle extends StatelessWidget {
  final IconData? icon;
  final String? assetPath;
  final Color? iconColor;

  const LeadingCircle(this.icon, {super.key, this.iconColor})
      : assetPath = null;

  const LeadingCircle.asset(
    this.assetPath, {
    super.key,
    this.iconColor,
  }) : icon = null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      ),
      child: Center(
        child: assetPath != null
            ? Image.asset(
                assetPath!,
                width: 22,
                height: 22,
                fit: BoxFit.contain,
              )
            : Icon(
                icon,
                color: iconColor ??
                    (isDark ? Colors.white : const Color(0xFF111827)),
              ),
      ),
    );
  }
}
