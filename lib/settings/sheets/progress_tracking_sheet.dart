import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/util/app_colors.dart';

class ProgressTrackingSheet extends StatelessWidget {
  final String initialMode;
  final bool isDark;

  const ProgressTrackingSheet({
    super.key,
    required this.initialMode,
    required this.isDark,
  });

  Future<String?> openBottomSheet(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => this,
    );
  }

  @override
  Widget build(BuildContext context) {
    final panelBg = isDark ? const Color(0xFF121212) : Colors.white;
    final onPanel = isDark ? Colors.white : const Color(0xFF111827);

    return StatefulBuilder(
      builder: (context, setState) {
        String currentMode = initialMode;

        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            decoration: BoxDecoration(
              color: panelBg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Reading Progress Tracking",
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: onPanel,
                  ),
                ),
                const SizedBox(height: 16),
                _TrackingModeOption(
                  title: 'Smart',
                  description:
                      'Automatically updates your progress based on your reading activity.',
                  icon: Icons.auto_awesome_rounded,
                  isSelected: currentMode == 'smart',
                  isDark: isDark,
                  onTap: () => Navigator.of(context).pop('smart'),
                ),
                const SizedBox(height: 10),
                _TrackingModeOption(
                  title: 'Manual',
                  description:
                      'Tap the "double-tick" icon on the last verse you’ve read to mark it and everything before it as completed.',
                  icon: Icons.touch_app_rounded,
                  isSelected: currentMode == 'manual',
                  isDark: isDark,
                  onTap: () => Navigator.of(context).pop('manual'),
                ),
                const SizedBox(height: 10),
                _TrackingModeOption(
                  title: 'Off',
                  description: 'Progress is not tracked.',
                  icon: Icons.block_rounded,
                  isSelected: currentMode == 'off',
                  isDark: isDark,
                  onTap: () => Navigator.of(context).pop('off'),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TrackingModeOption extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _TrackingModeOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.green500;
    final rowBg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8FAFC);
    final onPanel = isDark ? Colors.white : const Color(0xFF111827);
    final muted = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.08) : rowBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE5E7EB)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? activeColor : muted,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? activeColor : onPanel,
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, size: 20, color: activeColor),
          ],
        ),
      ),
    );
  }
}
