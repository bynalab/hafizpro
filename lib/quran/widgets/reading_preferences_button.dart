import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:hafiz_test/util/app_colors.dart';
import 'package:hafiz_test/util/reading_preferences.dart';
import 'package:hafiz_test/widget/app_switch.dart';

class ReadingPreferencesButton extends StatelessWidget {
  final IStorageService storage;
  final VoidCallback onChanged;
  final bool isDark;

  const ReadingPreferencesButton({
    super.key,
    required this.storage,
    required this.onChanged,
    required this.isDark,
  });

  Color get _inactiveTrack =>
      isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB);

  Color get _inactiveThumb =>
      isDark ? const Color(0xFF9CA3AF) : const Color(0xFF9CA3AF);

  Color get _activeTrack => AppColors.green500;

  Future<void> _open(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (ctx) {
        final prefs = getReadingPreferences(storage);
        bool showTranslation = prefs.showTranslation;
        bool showTransliteration = prefs.showTransliteration;

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final panelBg = isDark ? const Color(0xFF121212) : Colors.white;
            final onPanel = isDark ? Colors.white : const Color(0xFF111827);

            return SafeArea(
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                decoration: BoxDecoration(
                  color: panelBg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: isDark ? 0.06 : 0.10,
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Image.asset(
                                'assets/img/faded_vector_quran.png',
                                width: 120,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reading Preferences',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: onPanel,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _PreferenceTile(
                            title: 'Translation',
                            subtitle: 'Show meaning under each ayah',
                            icon: Icons.translate_rounded,
                            value: showTranslation,
                            isDark: isDark,
                            activeTrack: _activeTrack,
                            inactiveTrack: _inactiveTrack,
                            inactiveThumb: _inactiveThumb,
                            onChanged: (v) async {
                              await setShowTranslationPreference(storage, v);
                              setSheetState(() => showTranslation = v);
                              onChanged();
                            },
                          ),
                          const SizedBox(height: 10),
                          _PreferenceTile(
                            title: 'Transliteration',
                            subtitle: 'Show pronunciation in Latin letters',
                            icon: Icons.text_fields_rounded,
                            value: showTransliteration,
                            isDark: isDark,
                            activeTrack: _activeTrack,
                            inactiveTrack: _inactiveTrack,
                            inactiveThumb: _inactiveThumb,
                            onChanged: (v) async {
                              await setShowTransliterationPreference(
                                storage,
                                v,
                              );
                              setSheetState(() => showTransliteration = v);
                              onChanged();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            Icons.translate_rounded,
            size: 20,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
      ),
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final bool isDark;
  final Color activeTrack;
  final Color inactiveTrack;
  final Color inactiveThumb;
  final Future<void> Function(bool next) onChanged;

  const _PreferenceTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.isDark,
    required this.activeTrack,
    required this.inactiveTrack,
    required this.inactiveThumb,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final onPanel = isDark ? Colors.white : const Color(0xFF111827);
    final muted = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final rowBg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8FAFC);

    return Container(
      decoration: BoxDecoration(
        color: rowBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: AppSwitchListTile(
        value: value,
        onChanged: (v) async => onChanged(v),
        secondary: Icon(icon, color: onPanel),
        title: Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: onPanel,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: muted,
          ),
        ),
      ),
    );
  }
}
