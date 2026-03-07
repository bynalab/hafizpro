import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:hafiz_test/util/app_colors.dart';
import 'package:hafiz_test/util/reading_preferences.dart';
import 'package:hafiz_test/widget/app_switch.dart';
import 'package:hafiz_test/util/l10n_extensions.dart';

class QuranSettingsButton extends StatelessWidget {
  final IStorageService storage;
  final VoidCallback onChanged;
  final bool isDark;

  const QuranSettingsButton({
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
        ReadingPreferences prefs = ReadingPreferences.fromStorage(storage);

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final panelBg = isDark ? const Color(0xFF121212) : Colors.white;
            final onPanel = isDark ? Colors.white : const Color(0xFF111827);
            final muted =
                isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

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
                            context.l10n.readingPreferencesTitle,
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: onPanel,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _PreferenceTile(
                            title: context.l10n.translationLabel,
                            subtitle: context.l10n.translationSubtitle,
                            icon: Icons.translate_rounded,
                            value: prefs.showTranslation,
                            isDark: isDark,
                            activeTrack: _activeTrack,
                            inactiveTrack: _inactiveTrack,
                            inactiveThumb: _inactiveThumb,
                            onChanged: (v) async {
                              await setShowTranslationPreference(storage, v);
                              setSheetState(() =>
                                  prefs = prefs.copyWith(showTranslation: v));
                              onChanged();
                            },
                          ),
                          const SizedBox(height: 10),
                          _PreferenceTile(
                            title: context.l10n.transliterationLabel,
                            subtitle: context.l10n.transliterationSubtitle,
                            icon: Icons.text_fields_rounded,
                            value: prefs.showTransliteration,
                            isDark: isDark,
                            activeTrack: _activeTrack,
                            inactiveTrack: _inactiveTrack,
                            inactiveThumb: _inactiveThumb,
                            onChanged: (v) async {
                              await setShowTransliterationPreference(
                                  storage, v);
                              setSheetState(() => prefs =
                                  prefs.copyWith(showTransliteration: v));
                              onChanged();
                            },
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Icon(Icons.format_size_rounded,
                                  size: 20, color: onPanel),
                              const SizedBox(width: 8),
                              Text(
                                "Font Size",
                                style: GoogleFonts.cairo(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: onPanel,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                "${prefs.arabicFontSize.toInt()}px",
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: muted,
                                ),
                              ),
                            ],
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: _activeTrack,
                              inactiveTrackColor: _inactiveTrack,
                              thumbColor: _activeTrack,
                              overlayColor: _activeTrack.withValues(alpha: 0.1),
                              trackHeight: 4,
                            ),
                            child: Slider(
                              value: prefs.arabicFontSize,
                              min: 18,
                              max: 48,
                              divisions: 15,
                              onChanged: (v) async {
                                await setArabicFontSizePreference(storage, v);
                                setSheetState(() =>
                                    prefs = prefs.copyWith(arabicFontSize: v));
                                onChanged();
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Quran Font",
                            style: GoogleFonts.cairo(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: onPanel,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _FontOption(
                                  name: "Amiri",
                                  isSelected:
                                      prefs.arabicFontFamily.toLowerCase() ==
                                          'amiri',
                                  isDark: isDark,
                                  onTap: () async {
                                    await setArabicFontFamilyPreference(
                                        storage, 'Amiri');
                                    setSheetState(() => prefs = prefs.copyWith(
                                        arabicFontFamily: 'Amiri'));
                                    onChanged();
                                  },
                                  fontStyle: GoogleFonts.amiri(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _FontOption(
                                  name: "Lateef",
                                  isSelected:
                                      prefs.arabicFontFamily.toLowerCase() ==
                                          'lateef',
                                  isDark: isDark,
                                  onTap: () async {
                                    await setArabicFontFamilyPreference(
                                        storage, 'Lateef');
                                    setSheetState(() => prefs = prefs.copyWith(
                                        arabicFontFamily: 'Lateef'));
                                    onChanged();
                                  },
                                  fontStyle: GoogleFonts.lateef(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _FontOption(
                                  name: "Scheherazade",
                                  isSelected:
                                      prefs.arabicFontFamily.toLowerCase() ==
                                          'scheherazade new',
                                  isDark: isDark,
                                  onTap: () async {
                                    await setArabicFontFamilyPreference(
                                        storage, 'Scheherazade New');
                                    setSheetState(() => prefs = prefs.copyWith(
                                        arabicFontFamily: 'Scheherazade New'));
                                    onChanged();
                                  },
                                  fontStyle: GoogleFonts.scheherazadeNew(),
                                ),
                              ),
                            ],
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
            Icons.settings_rounded,
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

class _FontOption extends StatelessWidget {
  final String name;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;
  final TextStyle fontStyle;

  const _FontOption({
    required this.name,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
    required this.fontStyle,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.green500;
    final bgColor = isSelected
        ? activeColor.withValues(alpha: 0.1)
        : (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8FAFC));
    final borderColor = isSelected
        ? activeColor
        : (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFE5E7EB));
    final textColor = isDark ? Colors.white : const Color(0xFF111827);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "بسم الله",
              style: fontStyle.copyWith(
                fontSize: 18,
                color: textColor,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color:
                    isSelected ? activeColor : textColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
