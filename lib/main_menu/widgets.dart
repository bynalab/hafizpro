import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:hafiz_test/juz/juz_list_screen.dart';
import 'package:hafiz_test/model/juz.model.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/quran/quran_view.dart';
import 'package:hafiz_test/services/analytics_service.dart';
import 'package:hafiz_test/util/app_colors.dart';
import 'package:hafiz_test/widget/star_burst_icon.dart';
import 'package:hafiz_test/data/surah_list.dart';

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
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF9CA3AF),
                ),
                border: InputBorder.none,
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
  final Widget right;
  final Widget child;
  final VoidCallback? onTap;

  const DashboardFeatureCard({
    super.key,
    required this.background,
    required this.title,
    required this.right,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.black500,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFBFE7EA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Challenge yourself',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/img/brain.svg',
                          width: 22,
                          height: 22,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF111827),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Listen to an ayah of\nthe Quran and guess\nthe next one.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF111827),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward,
                          color: Color(0xFF111827),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Image.asset(
                  'assets/img/quran_question_icon.png',
                  width: 72,
                  height: 72,
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
        color: const Color(0xFFF3F4F6),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        boxShadow: active
            ? [
                const BoxShadow(
                  color: Color(0x14000000),
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
          color: active ? const Color(0xFF115E59) : const Color(0xFF6B7280),
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

  const SurahCard({
    super.key,
    required this.surah,
    required this.onTap,
    this.showPlayButton = true,
    this.onPlay,
    this.isPlaying = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
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
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    surah.englishNameTranslation,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF9CA3AF),
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
                    border:
                        Border.all(color: const Color(0xFF111827), width: 1.4),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF111827),
                            ),
                          ),
                        )
                      : Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: const Color(0xFF111827),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
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
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rangeText,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6B7280),
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
                      color: const Color(0xFF111827),
                      width: 1.4,
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF111827),
                            ),
                          ),
                        )
                      : Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow_rounded,
                          color: const Color(0xFF111827),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6B7280),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(width: 56, height: 56, child: Center(child: icon)),
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
        width: 44,
        height: 44,
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
    return Container(
      width: 240,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFBFE7EA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: PillNavItem(
              active: index == 0,
              label: 'Quran',
              icon: SvgPicture.asset(
                'assets/img/quran-01.svg',
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(
                  index == 0 ? Colors.white : const Color(0xFF115E59),
                  BlendMode.srcIn,
                ),
              ),
              onTap: () => onChanged(0),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: PillNavItem(
              active: index == 1,
              label: 'Test',
              icon: SvgPicture.asset(
                'assets/img/brain.svg',
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(
                  index == 1 ? Colors.white : const Color(0xFF115E59),
                  BlendMode.srcIn,
                ),
              ),
              onTap: () => onChanged(1),
            ),
          ),
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
