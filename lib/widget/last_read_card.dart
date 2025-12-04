import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/util/l10n_extensions.dart';
import 'package:hafiz_test/locator.dart';
import 'package:hafiz_test/model/ayah.model.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:hafiz_test/surah/test_by_surah.dart';
import 'package:hafiz_test/widget/showcase.dart';
import 'package:hafiz_test/services/analytics_service.dart';

class LastReadCard extends StatelessWidget {
  final GlobalKey lastReadKey;
  const LastReadCard({super.key, required this.lastReadKey});

  @override
  Widget build(BuildContext context) {
    final lastRead = getIt<IStorageService>().getLastRead();

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: 200,
            ),
            child: Image.asset('assets/img/banner.png'),
          ),
        ),
        if (Theme.of(context).brightness == Brightness.dark)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xB3000000),
                      Color(0x1A000000),
                      Color(0x00000000),
                    ],
                  ),
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(23),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShowCase(
                widgetKey: lastReadKey,
                title: context.l10n.lastReadTitle,
                description: context.l10n.lastReadDescription,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.lastReadTitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 15),
                    LastReadWidget(lastRead: lastRead),
                  ],
                ),
              ),
              Image.asset(
                'assets/img/quran_opened_star.png',
                height: 120,
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 15,
          left: 23,
          child: GestureDetector(
            onTap: () async {
              if (lastRead == null) return;

              final (surah, ayah) = lastRead;

              AnalyticsService.trackEvent('Last Read Continued', properties: {
                'surah_name': surah.englishName,
                'surah_number': surah.number,
                'ayah_number': ayah.numberInSurah,
                'timestamp': DateTime.now().toIso8601String(),
              });

              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) {
                    return TestBySurah(
                      surahNumber: surah.number,
                      ayahNumber: ayah.numberInSurah,
                    );
                  },
                ),
              );
            },
            child: Container(
              width: 115,
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withValues(alpha: 0.5)
                    : const Color(0xFFFAF6EB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      context.l10n.lastReadContinue,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  Image.asset(
                    'assets/img/arrow_right_circle.png',
                    width: 16,
                    height: 16,
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class LastReadWidget extends StatelessWidget {
  final (Surah, Ayah)? lastRead;

  const LastReadWidget({super.key, this.lastRead});

  @override
  Widget build(BuildContext context) {
    if (lastRead == null) {
      return Text(
        context.l10n.lastReadNone,
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Theme.of(context).colorScheme.onSurface,
        ),
      );
    }

    final (surah, ayah) = lastRead!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          surah.name.replaceAll('سُورَةُ ', ''),
          style: TextStyle(
            fontFamily: 'Kitab',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          context.l10n.lastReadAyahNumber(ayah.numberInSurah),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w300,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
