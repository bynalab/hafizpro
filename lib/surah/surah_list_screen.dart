import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/data/surah_list.dart';
import 'package:hafiz_test/enum/surah_select_action.dart';
import 'package:hafiz_test/main_menu/widgets.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/quran/quran_view.dart';
import 'package:hafiz_test/surah/test_by_surah.dart';
import 'package:hafiz_test/services/analytics_service.dart';

class SurahListScreen extends StatefulWidget {
  final SurahSelectionAction actionType;

  const SurahListScreen({super.key, required this.actionType});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  Surah? selectedSurah;

  @override
  void initState() {
    super.initState();

    // Track surah list screen view
    AnalyticsService.trackScreenView('Surah List Screen');

    _searchController.addListener(() {
      final next = _searchController.text;
      if (next == _query) return;
      setState(() => _query = next);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isWideScreen = MediaQuery.of(context).size.width >= 600;

    final displaySurahs =
        _query.trim().isEmpty ? surahList : searchSurah(_query);

    final list = ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      itemCount: displaySurahs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, index) {
        final surah = displaySurahs[index];
        final surahNumber = surah.number;

        return SurahCard(
          surah: surah,
          showPlayButton: false,
          onTap: () {
            AnalyticsService.trackSurahSelected(surah.englishName, surahNumber);

            if (isWideScreen) {
              setState(() => selectedSurah = surah);

              return;
            }

            switch (widget.actionType) {
              case SurahSelectionAction.read:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => QuranView(surah: surah)),
                );
                break;
              default:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TestBySurah(surahNumber: surahNumber),
                  ),
                );
            }
          },
        );
      },
    );

    if (isWideScreen) {
      return Scaffold(
        backgroundColor: isDark
            ? Theme.of(context).colorScheme.surface
            : const Color(0xFFF9FAFB),
        body: Row(
          children: [
            // Left: List
            Expanded(
              flex: 2,
              child: _SelectListScaffold(
                headerBackground:
                    isDark ? const Color(0xFF4A2A34) : const Color(0xFFFADDE5),
                title: 'Surah List',
                descriptionTitle: 'Select a Surah',
                descriptionBody:
                    'Listen to a verse from a surah and\nguess the next verse.',
                headerImageAsset: 'assets/img/star_crecent.png',
                searchHint: 'Search by Surah',
                searchController: _searchController,
                list: list,
                onBack: () => Navigator.pop(context),
              ),
            ),
            // Right: Details
            Expanded(
              flex: 3,
              child: Container(
                color: isDark
                    ? Theme.of(context).colorScheme.surface
                    : Colors.white,
                child: selectedSurah == null
                    ? Center(
                        child: Text(
                          'Select a Surah',
                          style: TextStyle(
                            color: isDark
                                ? Theme.of(context).colorScheme.onSurface
                                : null,
                          ),
                        ),
                      )
                    : widget.actionType == SurahSelectionAction.read
                        ? QuranView(
                            key: ValueKey(selectedSurah?.number),
                            surah: selectedSurah!,
                          )
                        : TestBySurah(
                            key: ValueKey(selectedSurah?.number),
                            surahNumber: selectedSurah?.number,
                          ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: isDark
            ? Theme.of(context).colorScheme.surface
            : const Color(0xFFF9FAFB),
        body: _SelectListScaffold(
          headerBackground:
              isDark ? const Color(0xFF4A2A34) : const Color(0xFFFADDE5),
          title: 'Surah List',
          descriptionTitle: 'Select a Surah',
          descriptionBody:
              'Listen to a verse from a surah and\nguess the next verse.',
          headerImageAsset: 'assets/img/star_crecent.png',
          searchHint: 'Search by Surah',
          searchController: _searchController,
          list: list,
          onBack: () => Navigator.pop(context),
        ),
      );
    }
  }
}

class _SelectListScaffold extends StatelessWidget {
  const _SelectListScaffold({
    required this.headerBackground,
    required this.title,
    required this.descriptionTitle,
    required this.descriptionBody,
    required this.headerImageAsset,
    required this.searchHint,
    required this.searchController,
    required this.list,
    required this.onBack,
  });

  final Color headerBackground;
  final String title;
  final String descriptionTitle;
  final String descriptionBody;
  final String headerImageAsset;
  final String searchHint;
  final TextEditingController searchController;
  final Widget list;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827);
    final subtitleColor =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF111827);

    return Column(
      children: [
        Container(
          color: headerBackground,
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 170,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: onBack,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF1A1A1A) : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color:
                                isDark ? Colors.white : const Color(0xFF111827),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        title,
                        style: GoogleFonts.cairo(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 120),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            descriptionTitle,
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            descriptionBody,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: subtitleColor,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: -20,
                    bottom: -30,
                    child: Image.asset(
                      headerImageAsset,
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF111111) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF242424)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFFF3F4F6)
                                : const Color(0xFF111827),
                          ),
                          decoration: InputDecoration(
                            hintText: searchHint,
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
                ),
              ),
              Expanded(child: list),
            ],
          ),
        ),
      ],
    );
  }
}
