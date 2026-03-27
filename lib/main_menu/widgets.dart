import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:hafiz_test/juz/juz_list_screen.dart';
import 'package:hafiz_test/model/juz.model.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/quran/quran_view.dart';
import 'package:hafiz_test/services/analytics_service.dart';
import 'package:hafiz_test/util/app_colors.dart';
import 'package:hafiz_test/util/l10n_extensions.dart';
import 'package:hafiz_test/widget/star_burst_icon.dart';
import 'package:hafiz_test/data/surah_list.dart';

class DashboardPalette {
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color segmentedActiveBorder(BuildContext context) {
    return isDark(context) ? const Color(0xFF2A6B6F) : Colors.transparent;
  }

  static Color searchBg(BuildContext context) {
    return isDark(context) ? const Color(0xFF111111) : Colors.white;
  }

  static Color searchBorder(BuildContext context) {
    return isDark(context) ? const Color(0xFF242424) : const Color(0xFFE5E7EB);
  }

  static Color primaryText(BuildContext context) {
    return isDark(context) ? const Color(0xFFF3F4F6) : const Color(0xFF111827);
  }

  static Color secondaryText(BuildContext context) {
    return isDark(context) ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  }

  static Color segmentedBg(BuildContext context) {
    return isDark(context) ? const Color(0xFF141414) : const Color(0xFFF3F4F6);
  }

  static Color segmentedActiveBg(BuildContext context) {
    return isDark(context) ? const Color(0xFF1E1E1E) : Colors.white;
  }

  static Color listTileBg(BuildContext context) {
    return isDark(context) ? const Color(0xFF101010) : Colors.white;
  }

  static Color listTileBorder(BuildContext context) {
    return isDark(context) ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB);
  }

  static Color pillBg(BuildContext context) {
    return isDark(context) ? const Color(0xFF2A6B6F) : const Color(0xFFBFE7EA);
  }

  static Color iconButtonBg(BuildContext context) {
    return isDark(context) ? const Color(0xFF1A1A1A) : const Color(0xFFF2F2F2);
  }

  static Color pinnedHeaderBg(BuildContext context) {
    return isDark(context) ? const Color(0xFF0B0B0B) : Colors.white;
  }

  static Color cardPeach(BuildContext context) {
    return isDark(context) ? const Color(0xFF2D1B18) : const Color(0xFFF7CFC7);
  }

  static Color cardTeal(BuildContext context) {
    return isDark(context) ? const Color(0xFF182D2D) : const Color(0xFFBFE7EA);
  }

  static Color cardPurple(BuildContext context) {
    return isDark(context) ? const Color(0xFF2D182D) : const Color(0xFFE6BDEB);
  }
}

class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const SearchField({
    super.key,
    required this.controller,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: DashboardPalette.searchBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardPalette.searchBorder(context)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.search, color: DashboardPalette.secondaryText(context)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              textAlignVertical: TextAlignVertical.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: DashboardPalette.primaryText(context),
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: DashboardPalette.secondaryText(context),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardFeatureCard extends StatelessWidget {
  final Color background;
  final String title;
  final Widget? trailingTitle;
  final Widget right;
  final Widget child;
  final VoidCallback? onTap;

  const DashboardFeatureCard({
    super.key,
    required this.background,
    required this.title,
    this.trailingTitle,
    required this.right,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DashboardPalette.primaryText(context),
                  ),
                ),
                if (trailingTitle != null) trailingTitle!,
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: DashboardPalette.listTileBg(context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: child,
                  ),
                ),
                const SizedBox(width: 12),
                right,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ChallengeContainer extends StatelessWidget {
  final VoidCallback onTap;

  const ChallengeContainer({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? scheme.surfaceContainerHigh : const Color(0xFFBFE7EA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.dashboardChallengeTitle,
              style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/img/brain.svg',
                          width: 18,
                          height: 18,
                          colorFilter: ColorFilter.mode(
                            scheme.onSurface,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.l10n.dashboardChallengeDescription,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: scheme.onSurface,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Image.asset(
                  'assets/img/quran_question_icon.png',
                  width: 56,
                  height: 56,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SegmentedSwitch extends StatelessWidget {
  final String leftLabel;
  final String rightLabel;
  final int index;
  final ValueChanged<int> onChanged;

  const SegmentedSwitch({
    super.key,
    required this.leftLabel,
    required this.rightLabel,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DashboardPalette.segmentedBg(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(0),
              child: _SegmentedItem(
                active: index == 0,
                label: leftLabel,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(1),
              child: _SegmentedItem(
                active: index == 1,
                label: rightLabel,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedItem extends StatelessWidget {
  final bool active;
  final String label;

  const _SegmentedItem({required this.active, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = DashboardPalette.isDark(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active
            ? DashboardPalette.segmentedActiveBg(context)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: active && isDark
            ? Border.all(
                color: DashboardPalette.segmentedActiveBorder(context)
                    .withValues(alpha: 0.55),
                width: 1,
              )
            : null,
        boxShadow: active
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                )
              ]
            : [],
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: active
              ? AppColors.green500
              : DashboardPalette.secondaryText(context),
        ),
      ),
    );
  }
}

class SurahListWidget extends StatelessWidget {
  final List<Surah> surahs;

  const SurahListWidget({super.key, required this.surahs});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: surahs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final s = surahs[i];
        return SurahCard(
          surah: s,
          onTap: () {
            AnalyticsService.trackSurahSelected(s.englishName, s.number);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => QuranView(surah: s)),
            );
          },
          onPlay: () {
            AnalyticsService.trackSurahSelected(s.englishName, s.number);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => QuranView(surah: s)),
            );
          },
        );
      },
    );
  }
}

class SurahCard extends StatelessWidget {
  final Surah surah;
  final VoidCallback onTap;
  final bool showPlayButton;
  final VoidCallback? onPlay;
  final bool isPlaying;
  final bool isLoading;

  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectChanged;

  const SurahCard({
    super.key,
    required this.surah,
    required this.onTap,
    this.showPlayButton = true,
    this.onPlay,
    this.isPlaying = false,
    this.isLoading = false,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = DashboardPalette.isDark(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected && !isDark
              ? const Color(0xFFF3E8EA) // Muted light pink background
              : DashboardPalette.listTileBg(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4A2A34) // Deep maroon border
                : DashboardPalette.listTileBorder(context),
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          children: [
            StarburstIcon(text: '${surah.number}'),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah.englishName,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: DashboardPalette.primaryText(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    surah.englishNameTranslation,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: DashboardPalette.secondaryText(context),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelectionMode)
              Checkbox(
                value: isSelected,
                onChanged: onSelectChanged,
                activeColor: const Color(0xFF4A2A34), // Deep maroon
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              )
            else if (showPlayButton)
              GestureDetector(
                onTap: isLoading ? null : (onPlay ?? onTap),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: DashboardPalette.primaryText(context),
                      width: 1.4,
                    ),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              DashboardPalette.primaryText(context),
                            ),
                          ),
                        )
                      : Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: DashboardPalette.primaryText(context),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class JuzListWidget extends StatelessWidget {
  final List<JuzModel> juzNames;

  const JuzListWidget({super.key, required this.juzNames});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: juzNames.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final juz = juzNames[i];
        final juzNumber = juz.number;

        return JuzCard(
          juz: juz,
          onTap: () {
            AnalyticsService.trackJuzSelected(juzNumber);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JuzListScreen()),
            );
          },
        );
      },
    );
  }
}

class JuzCard extends StatelessWidget {
  final JuzModel juz;
  final VoidCallback onTap;
  final bool showPlayButton;
  final VoidCallback? onPlay;
  final bool isPlaying;
  final bool isLoading;

  const JuzCard({
    super.key,
    required this.juz,
    required this.onTap,
    this.showPlayButton = true,
    this.onPlay,
    this.isPlaying = false,
    this.isLoading = false,
  });

  String _pad2(int v) => v.toString().padLeft(2, '0');

  String _surahName(int surahNumber) {
    final s = surahList.firstWhere((x) => x.number == surahNumber);
    return s.englishName;
  }

  @override
  Widget build(BuildContext context) {
    final juzNumber = juz.number;
    final rangeText =
        '${_surahName(juz.startSurah)}(${_pad2(juz.startAyah)}) : ${_surahName(juz.endSurah)}(${_pad2(juz.endAyah)})';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: DashboardPalette.listTileBg(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DashboardPalette.listTileBorder(context)),
        ),
        child: Row(
          children: [
            StarburstIcon(text: '$juzNumber'),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    juz.name,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: DashboardPalette.primaryText(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rangeText,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: DashboardPalette.secondaryText(context),
                    ),
                  ),
                ],
              ),
            ),
            if (showPlayButton)
              GestureDetector(
                onTap: isLoading ? null : (onPlay ?? onTap),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: DashboardPalette.primaryText(context),
                      width: 1.4,
                    ),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              DashboardPalette.primaryText(context),
                            ),
                          ),
                        )
                      : Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow_rounded,
                          color: DashboardPalette.primaryText(context),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TestOptionContainer extends StatelessWidget {
  final Color background;
  final String title;
  final String subtitle;
  final Widget icon;
  final VoidCallback onTap;

  const TestOptionContainer({
    super.key,
    required this.background,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(width: 48, height: 48, child: Center(child: icon)),
          ],
        ),
      ),
    );
  }
}

class CircleIconButton extends StatelessWidget {
  final Color background;
  final Widget icon;
  final VoidCallback onTap;

  const CircleIconButton({
    super.key,
    required this.background,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
        ),
        child: Center(child: icon),
      ),
    );
  }
}

class BottomPillNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const BottomPillNav({
    super.key,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = DashboardPalette.isDark(context);

    return Container(
      width: 340,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: DashboardPalette.pillBg(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: PillNavItem(
              active: index == 0,
              label: context.l10n.bottomNavQuran,
              icon: SvgPicture.asset(
                'assets/img/quran-01.svg',
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(
                  index == 0
                      ? Colors.white
                      : (isDark ? const Color(0xFFBFE7EA) : AppColors.green500),
                  BlendMode.srcIn,
                ),
              ),
              onTap: () => onChanged(0),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: PillNavItem(
              active: index == 1,
              label: context.l10n.bottomNavTest,
              icon: SvgPicture.asset(
                'assets/img/brain.svg',
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(
                  index == 1
                      ? Colors.white
                      : (isDark ? const Color(0xFFBFE7EA) : AppColors.green500),
                  BlendMode.srcIn,
                ),
              ),
              onTap: () => onChanged(1),
            ),
          ),
          // const SizedBox(width: 4),
          // Expanded(
          //   child: PillNavItem(
          //     active: index == 2,
          //     label: 'Adhkar',
          //     icon: Icon(
          //       Icons.spa_outlined,
          //       size: 18,
          //       color: index == 2
          //           ? Colors.white
          //           : (isDark ? const Color(0xFFBFE7EA) : AppColors.green500),
          //     ),
          //     onTap: () => onChanged(2),
          //   ),
          // ),
        ],
      ),
    );
  }
}

class PillNavItem extends StatelessWidget {
  final bool active;
  final String label;
  final Widget icon;
  final VoidCallback onTap;

  const PillNavItem({
    super.key,
    required this.active,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.green500 : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            if (active) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
