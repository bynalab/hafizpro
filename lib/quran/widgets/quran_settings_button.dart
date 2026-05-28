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

  Color get _activeTrack => AppColors.green500;

  Future<void> _open(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        ReadingPreferences prefs = ReadingPreferences.fromStorage(storage);

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final panelBg = isDark ? const Color(0xFF121212) : Colors.white;
            final onPanel = isDark ? Colors.white : const Color(0xFF111827);
            final muted =
                isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
            final bottomInset = MediaQuery.paddingOf(ctx).bottom;

            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.56,
                minChildSize: 0.44,
                maxChildSize: 0.88,
                builder: (ctx, scrollController) {
                  return Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    decoration: BoxDecoration(
                      color: panelBg,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Opacity(
                              opacity: isDark ? 0.04 : 0.06,
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Align(
                                  alignment: Alignment.topRight,
                                  child: Image.asset(
                                    'assets/img/faded_vector_quran.png',
                                    width: 88,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                          children: [
                            Center(
                              child: Container(
                                width: 36,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: muted.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            Text(
                              context.l10n.readingPreferencesTitle,
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: onPanel,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _DenseSwitchTile(
                              title: context.l10n.translationLabel,
                              subtitle: context.l10n.translationSubtitle,
                              icon: Icons.translate_rounded,
                              value: prefs.showTranslation,
                              isDark: isDark,
                              onChanged: (v) async {
                                await setShowTranslationPreference(
                                  storage,
                                  v,
                                );
                                setSheetState(() =>
                                    prefs = prefs.copyWith(showTranslation: v));
                                onChanged();
                              },
                            ),
                            const SizedBox(height: 6),
                            _DenseSwitchTile(
                              title: context.l10n.transliterationLabel,
                              subtitle: context.l10n.transliterationSubtitle,
                              icon: Icons.text_fields_rounded,
                              value: prefs.showTransliteration,
                              isDark: isDark,
                              onChanged: (v) async {
                                await setShowTransliterationPreference(
                                  storage,
                                  v,
                                );
                                setSheetState(() => prefs =
                                    prefs.copyWith(showTransliteration: v));
                                onChanged();
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.format_size_rounded,
                                    size: 18, color: onPanel),
                                const SizedBox(width: 6),
                                Text(
                                  context.l10n.quranSettingsFontSize,
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: onPanel,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${prefs.arabicFontSize.toInt()}px',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
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
                                overlayColor:
                                    _activeTrack.withValues(alpha: 0.1),
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 7,
                                ),
                              ),
                              child: Slider(
                                value: prefs.arabicFontSize,
                                min: 18,
                                max: 48,
                                divisions: 15,
                                onChanged: (v) async {
                                  await setArabicFontSizePreference(
                                    storage,
                                    v,
                                  );
                                  setSheetState(() => prefs =
                                      prefs.copyWith(arabicFontSize: v));
                                  onChanged();
                                },
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.l10n.quranSettingsArabicFont,
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: onPanel,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _FontOption(
                                    name: 'Amiri',
                                    isSelected:
                                        prefs.arabicFontFamily.toLowerCase() ==
                                            'amiri',
                                    isDark: isDark,
                                    onTap: () async {
                                      await setArabicFontFamilyPreference(
                                        storage,
                                        'Amiri',
                                      );
                                      if (!ctx.mounted) return;
                                      onChanged();
                                      Navigator.of(ctx).pop();
                                    },
                                    fontStyle: GoogleFonts.amiri(),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _FontOption(
                                    name: 'Lateef',
                                    isSelected:
                                        prefs.arabicFontFamily.toLowerCase() ==
                                            'lateef',
                                    isDark: isDark,
                                    onTap: () async {
                                      await setArabicFontFamilyPreference(
                                        storage,
                                        'Lateef',
                                      );
                                      if (!ctx.mounted) return;
                                      onChanged();
                                      Navigator.of(ctx).pop();
                                    },
                                    fontStyle: GoogleFonts.lateef(),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _FontOption(
                                    name: 'Scheher.',
                                    isSelected:
                                        prefs.arabicFontFamily.toLowerCase() ==
                                            'scheherazade new',
                                    isDark: isDark,
                                    onTap: () async {
                                      await setArabicFontFamilyPreference(
                                        storage,
                                        'Scheherazade New',
                                      );
                                      if (!ctx.mounted) return;
                                      onChanged();
                                      Navigator.of(ctx).pop();
                                    },
                                    fontStyle: GoogleFonts.scheherazadeNew(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              context.l10n.quranSettingsLayout,
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: onPanel,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _LayoutChip(
                                    label: context.l10n.quranSettingsLayoutList,
                                    icon: Icons.view_list_rounded,
                                    selected: prefs.readerViewMode ==
                                        QuranReaderViewMode.normal,
                                    isDark: isDark,
                                    onTap: () async {
                                      await setQuranReaderViewModePreference(
                                        storage,
                                        QuranReaderViewMode.normal,
                                      );
                                      if (!ctx.mounted) return;
                                      onChanged();
                                      Navigator.of(ctx).pop();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _LayoutChip(
                                    label: context.l10n.quranSettingsLayoutFocus,
                                    icon: Icons.auto_stories_rounded,
                                    selected: prefs.readerViewMode ==
                                        QuranReaderViewMode.verseFocus,
                                    isDark: isDark,
                                    onTap: () async {
                                      await setQuranReaderViewModePreference(
                                        storage,
                                        QuranReaderViewMode.verseFocus,
                                      );
                                      if (!ctx.mounted) return;
                                      onChanged();
                                      Navigator.of(ctx).pop();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _LayoutChip(
                                    label: context.l10n.quranSettingsLayoutMushaf,
                                    icon: Icons.menu_book_rounded,
                                    selected: prefs.readerViewMode ==
                                        QuranReaderViewMode.mushaf,
                                    isDark: isDark,
                                    onTap: () async {
                                      await setQuranReaderViewModePreference(
                                        storage,
                                        QuranReaderViewMode.mushaf,
                                      );
                                      if (!ctx.mounted) return;
                                      onChanged();
                                      Navigator.of(ctx).pop();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
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

class _DenseSwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool value;
  final bool isDark;
  final Future<void> Function(bool next) onChanged;

  const _DenseSwitchTile({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final onPanel = isDark ? Colors.white : const Color(0xFF111827);
    final muted = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final rowBg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8FAFC);
    final sub = subtitle;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
      decoration: BoxDecoration(
        color: rowBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: onPanel),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: onPanel,
                  ),
                ),
                if (sub != null && sub.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    sub,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                      color: muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Transform.scale(
            scale: 0.88,
            alignment: Alignment.center,
            child: AppSwitch(
              value: value,
              onChanged: (v) => onChanged(v),
            ),
          ),
        ],
      ),
    );
  }
}

class _LayoutChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _LayoutChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.green500;
    final onPanel = isDark ? Colors.white : const Color(0xFF111827);
    final bg = selected
        ? activeColor.withValues(alpha: 0.12)
        : (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8FAFC));
    final border = selected
        ? activeColor
        : (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFE5E7EB));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? activeColor : onPanel.withValues(alpha: 0.75),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? activeColor : onPanel,
                ),
              ),
            ],
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
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'بسم',
              style: fontStyle.copyWith(
                fontSize: 15,
                color: textColor,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? activeColor
                    : textColor.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
