import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/main_menu/widgets.dart';
import 'package:hafiz_test/util/app_colors.dart';
import 'package:hafiz_test/adhkar/adhkar_list_page.dart';
import 'package:adhkar/adhkar.dart';
import 'package:hafiz_test/adhkar/adhkar_service.dart';

class AdhkarHomePage extends StatelessWidget {
  final VoidCallback onOpenSettings;
  final VoidCallback onToggleTheme;

  const AdhkarHomePage({
    super.key,
    required this.onOpenSettings,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtitleColor =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final iconBg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF2F2F2);
    final titleColor =
        isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827);

    return Scaffold(
      backgroundColor: Colors.transparent, // Handled by parent
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
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
                    background: iconBg,
                    icon: Icon(
                      Theme.of(context).brightness == Brightness.dark
                          ? Icons.light_mode
                          : Icons.dark_mode,
                      color: titleColor,
                    ),
                    onTap: onToggleTheme,
                  ),
                  const SizedBox(width: 10),
                  CircleIconButton(
                    background: iconBg,
                    icon: const Icon(
                      Icons.settings,
                      color: null,
                    ),
                    onTap: onOpenSettings,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Adhkar',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A collection of timeless supplications to anchor the heart and protect you',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.5,
                  color: subtitleColor,
                ),
              ),
              const SizedBox(height: 32),

              // Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85, // Adjust based on image
                  children: [
                    _AdhkarCard(
                      title: 'Morning',
                      imagePath: 'assets/img/morning_adhkar.webp',
                      isDark: isDark,
                      onTap: () {
                        final adhkar = AdhkarService.getMorningEvening();
                        _navToDetail(context, adhkar);
                      },
                    ),
                    _AdhkarCard(
                      title: 'Evening',
                      imagePath: 'assets/img/evening_adhkar.webp',
                      isDark: isDark,
                      onTap: () {
                        final adhkar = AdhkarService.getMorningEvening();
                        _navToDetail(context, adhkar);
                      },
                    ),
                    _AdhkarCard(
                      title: 'Before sleeping',
                      imagePath: 'assets/img/sleep_adhkar.webp',
                      isDark: isDark,
                      onTap: () {
                        final adhkar = AdhkarService.getBeforeSleeping();
                        _navToDetail(context, adhkar);
                      },
                    ),
                    _AdhkarCard(
                      title: 'Waking up',
                      imagePath: 'assets/img/wake_adhkar.webp',
                      isDark: isDark,
                      onTap: () {
                        final adhkar = AdhkarService.getWakingUp();
                        _navToDetail(context, adhkar);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navToDetail(BuildContext context, Adhkar adhkar) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdhkarListPage(adhkarCategory: adhkar)),
    );
  }
}

class _AdhkarCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final bool isDark;
  final VoidCallback onTap;

  const _AdhkarCard({
    required this.title,
    required this.imagePath,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: ResizeImage(
              AssetImage(imagePath),
              width: 600, // Optimize memory usage for 4K images
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.1),
                Colors.black.withValues(alpha: 0.7),
              ],
              stops: const [0.5, 0.7, 1.0],
            ),
          ),
          padding: const EdgeInsets.all(16),
          alignment: Alignment.bottomLeft,
          child: Text(
            title,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
