import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/l10n/app_localizations.dart';
import 'package:hafiz_test/widget/button.dart';

class CompatibilityErrorView extends StatelessWidget {
  final VoidCallback onChooseReciter;
  final VoidCallback onRetry;

  const CompatibilityErrorView({
    super.key,
    required this.onChooseReciter,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryTeal = Color(0xFF004B40);
    const accentGold = Color(0xFFD4AF37);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: accentGold.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.audio_file_outlined,
                      size: 40,
                      color: accentGold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.reciterCompatibilityTitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : primaryTeal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.reciterCompatibilityBody1,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.reciterCompatibilityBody2,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Button(
                    width: double.infinity,
                    onPressed: onChooseReciter,
                    color: primaryTeal,
                    radius: BorderRadius.circular(16),
                    child: Text(
                      l10n.chooseCompatibleReciter,
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: onRetry,
                    child: Text(
                      l10n.errorRetryButton,
                      style: GoogleFonts.montserrat(
                        color: isDark
                            ? Colors.white70
                            : primaryTeal.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
