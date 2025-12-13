import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:hafiz_test/enum/surah_select_action.dart';
import 'package:hafiz_test/juz/juz_list_screen.dart';
import 'package:hafiz_test/surah/surah_list_screen.dart';
import 'package:hafiz_test/surah/test_by_surah.dart';
import 'package:hafiz_test/util/app_colors.dart';

import 'package:hafiz_test/main_menu/widgets.dart';

class TestMenuPage extends StatelessWidget {
  const TestMenuPage({
    super.key,
    required this.onOpenSettings,
    required this.onToggleTheme,
  });

  final VoidCallback onOpenSettings;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    const pillOuterBottomPadding = 18.0;
    const pillHeight = 44.0;
    const pillVerticalPadding = 8.0;
    const bottomNavReserved =
        pillOuterBottomPadding + pillHeight + (pillVerticalPadding * 2);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        18,
        0,
        18,
        bottomNavReserved + bottomInset + 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Row(
            children: [
              CircleIconButton(
                background: AppColors.green500,
                icon: SvgPicture.asset(
                  'assets/img/quran-01.svg',
                  width: 20,
                  height: 20,
                  colorFilter:
                      const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
                onTap: () {},
              ),
              const Spacer(),
              CircleIconButton(
                background: const Color(0xFFF2F2F2),
                icon: Icon(
                  Theme.of(context).brightness == Brightness.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                  color: const Color(0xFF111827),
                ),
                onTap: onToggleTheme,
              ),
              const SizedBox(width: 10),
              CircleIconButton(
                background: const Color(0xFFF2F2F2),
                icon: const Icon(
                  Icons.settings,
                  color: Color(0xFF111827),
                ),
                onTap: onOpenSettings,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Test Your Knowledge of the Qur’an',
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Challenge yourself by listening to an ayah of the Quran and guessing the next one.',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF58667B),
            ),
          ),
          const SizedBox(height: 18),
          TestOptionContainer(
            background: const Color(0xFFFADDE5),
            title: 'By Surah',
            subtitle: 'Test your knowledge based\non different surahs',
            icon:
                const Icon(Icons.nights_stay_rounded, color: Color(0xFF9C2A5B)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SurahListScreen(
                    actionType: SurahSelectionAction.test,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          TestOptionContainer(
            background: const Color(0xFF7CB7C6),
            title: 'By Juz',
            subtitle: 'Test how well you know each\nJuz.',
            icon: const Icon(Icons.mosque_rounded, color: Color(0xFF0A3A45)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JuzListScreen()),
              );
            },
          ),
          const SizedBox(height: 14),
          TestOptionContainer(
            background: const Color(0xFFF7CFC7),
            title: 'Random Verses',
            subtitle: 'Get verses from anywhere in\nthe Qur’an.',
            icon: const Icon(Icons.brightness_3_rounded,
                color: Color(0xFF9B4A3D)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TestBySurah()),
              );
            },
          ),
        ],
      ),
    );
  }
}
