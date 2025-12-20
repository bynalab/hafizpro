import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/util/app_colors.dart';
import 'package:hafiz_test/settings/widgets/leading_circle.dart';

class NotificationSheetResult {
  final bool enabled;
  final TimeOfDay time;

  const NotificationSheetResult({required this.enabled, required this.time});
}

class NotificationsSheet extends StatelessWidget {
  final bool initialEnabled;
  final TimeOfDay initialTime;

  const NotificationsSheet({
    super.key,
    required this.initialEnabled,
    required this.initialTime,
  });

  Future<NotificationSheetResult?> openBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<NotificationSheetResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0E0E0E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => this,
    );
  }

  String formatTime(TimeOfDay time) {
    final h = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final m = time.minute.toString().padLeft(2, '0');
    final suffix = time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$h:$m$suffix';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    var localEnabled = initialEnabled;
    var localTime = initialTime;
    var showSaved = false;

    return StatefulBuilder(
      builder: (context, setSheetState) {
        Future<void> pickTime() async {
          final picked = await showTimePicker(
            context: context,
            initialTime: localTime,
          );

          if (picked == null) return;
          setSheetState(() => localTime = picked);
        }

        if (showSaved) {
          return Padding(
            padding: EdgeInsets.only(
              left: 18,
              right: 18,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 18,
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.green500.withValues(alpha: 0.18)
                          : AppColors.green100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 34,
                      color: AppColors.green500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Changes Saved!',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.green500,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(
                        context,
                        NotificationSheetResult(
                          enabled: localEnabled,
                          time: localTime,
                        ),
                      ),
                      child: Text(
                        'OK',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 18,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    'Notifications',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A1A) : AppColors.black50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const LeadingCircle.asset(
                        'assets/icons/notification_bell.png',
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Enable Notifications',
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : AppColors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Receive daily motivational messages',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: isDark
                                    ? const Color(0xFF9CA3AF)
                                    : AppColors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: localEnabled,
                        onChanged: (v) => setSheetState(() => localEnabled = v),
                        activeTrackColor: AppColors.green500,
                        activeColor: Colors.white,
                      ),
                    ],
                  ),
                ),
                if (localEnabled) ...[
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: pickTime,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF121212) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 32,
                            color: AppColors.black500,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Notification Time',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.black500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formatTime(localTime),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? const Color(0xFF9CA3AF)
                                        : AppColors.black400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color:
                                isDark ? Colors.white : const Color(0xFF111827),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: localEnabled
                          ? AppColors.green500
                          : (isDark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: localEnabled
                        ? () => setSheetState(() => showSaved = true)
                        : null,
                    child: Text(
                      'Save',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: localEnabled
                            ? Colors.white
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
