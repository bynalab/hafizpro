import 'package:flutter/material.dart';
import 'package:hafiz_test/l10n/app_localizations.dart';
import 'package:hafiz_test/main_menu/download_manager_screen.dart';

final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

final GlobalKey<NavigatorState> appNavigatorKey =
    GlobalKey<NavigatorState>();

class AppMessenger {
  static void showSnackBar(String message) {
    final messenger = appScaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// Resolves the message using [AppLocalizations] from the scaffold context.
  static void showLocalizedSnackBar(
    String Function(AppLocalizations l10n) message,
  ) {
    final ctx = appScaffoldMessengerKey.currentContext;
    if (ctx == null) return;
    final l10n = AppLocalizations.of(ctx);
    if (l10n == null) return;
    showSnackBar(message(l10n));
  }

  /// Shows a beautiful bottom sheet warning the user they are offline and how to download audio.
  static void showOfflineAudioDialog() {
    final ctx = appNavigatorKey.currentContext;
    if (ctx == null) return;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Allow custom rounded decorative border
      builder: (context) {
        final theme = Theme.of(context);
        final l10n = AppLocalizations.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        // Gorgeous deep colors matching light/dark modes
        final sheetBgColor = isDark ? const Color(0xFF161C1A) : const Color(0xFFF4F7F6);
        final primaryAccent = theme.colorScheme.primary; // Emerald green or Mint teal
        const goldAccent = Color(0xFFD4AF37); // Royal Gold accent
        
        return Container(
          decoration: BoxDecoration(
            color: sheetBgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: isDark ? primaryAccent.withValues(alpha: 0.15) : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  // Elegant Top Handle
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Gorgeous Islamic 8-Pointed Star (Rub el Hizb ۞) Geometric Icon Container
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer rotating squares to form the 8-pointed star
                      Transform.rotate(
                        angle: 0,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: primaryAccent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: goldAccent.withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      Transform.rotate(
                        angle: 0.785398, // 45 degrees
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: primaryAccent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: goldAccent.withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      // Core Icon
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 32,
                        color: isDark ? primaryAccent : primaryAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Title
                  Text(
                    l10n?.audioNeedsInternet ?? 'Internet connection required',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                      color: isDark ? Colors.white : const Color(0xFF003028),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  
                  // Modern Islamic Divider (Star and line accent)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 1.5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, goldAccent.withValues(alpha: 0.5)],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Transform.rotate(
                        angle: 0.785398,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: goldAccent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 32,
                        height: 1.5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [goldAccent.withValues(alpha: 0.5), Colors.transparent],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      'To play this Surah offline, you can download it first while you have an active internet connection.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.white70 : const Color(0xFF556660),
                        height: 1.45,
                        fontSize: 14.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  // Primary Button (Go to Downloads)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAccent,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        final navigator = Navigator.of(context);
                        navigator.pop();
                        navigator.push(
                          MaterialPageRoute(
                            builder: (context) => const DownloadManagerScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Go to Downloads',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Secondary Button (Dismiss)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Dismiss',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : const Color(0xFF778882),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

  /// Shows a gorgeous one-time dialog prompting the user about the new offline downloads feature.
  static void showOfflineOnboardingPrompt() {
    final ctx = appNavigatorKey.currentContext;
    if (ctx == null) return;

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        final dialogBgColor = isDark ? const Color(0xFF161C1A) : const Color(0xFFF4F7F6);
        final primaryAccent = theme.colorScheme.primary;
        const goldAccent = Color(0xFFD4AF37);
        
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            decoration: BoxDecoration(
              color: dialogBgColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark ? primaryAccent.withValues(alpha: 0.15) : Colors.white,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 8-Pointed Star (Rub el Hizb ۞) Geometric Icon Container
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.rotate(
                        angle: 0,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: primaryAccent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: goldAccent.withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      Transform.rotate(
                        angle: 0.785398, // 45 degrees
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: primaryAccent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: goldAccent.withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.download_for_offline_rounded,
                        size: 28,
                        color: primaryAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Title
                  Text(
                    'Offline Audio Available!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: isDark ? Colors.white : const Color(0xFF003028),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  
                  // Modern Islamic Divider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 1.2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, goldAccent.withValues(alpha: 0.4)],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Transform.rotate(
                        angle: 0.785398,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(color: goldAccent),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 24,
                        height: 1.2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [goldAccent.withValues(alpha: 0.4), Colors.transparent],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Message
                  Text(
                    'You can now download the complete Holy Quran audio files for offline streaming. Listen to your favorite recitations anywhere without needing internet access!',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : const Color(0xFF556660),
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Primary CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAccent,
                        foregroundColor: theme.colorScheme.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        final navigator = Navigator.of(context);
                        navigator.pop();
                        navigator.push(
                          MaterialPageRoute(
                            builder: (context) => const DownloadManagerScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Manage Downloads',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Secondary Dismiss Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Dismiss',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : const Color(0xFF778882),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
