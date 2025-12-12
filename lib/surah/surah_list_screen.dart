import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/data/surah_list.dart';
import 'package:hafiz_test/enum/surah_select_action.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/quran/quran_view.dart';
import 'package:hafiz_test/surah/test_by_surah.dart';
import 'package:hafiz_test/services/analytics_service.dart';
import 'package:hafiz_test/util/l10n_extensions.dart';

class SurahListScreen extends StatefulWidget {
  final SurahSelectionAction actionType;

  const SurahListScreen({super.key, required this.actionType});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  bool isSearching = false;
  Surah? selectedSurah;

  @override
  void initState() {
    super.initState();

    // Track surah list screen view
    AnalyticsService.trackScreenView('Surah List Screen');
  }

  @override
  Widget build(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width >= 600;

    final surahListView = ListView.separated(
      padding: const EdgeInsets.all(15),
      itemCount: surahList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final surah = surahList[index];
        final surahNumber = surah.number;

        return GestureDetector(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF23364F).withValues(alpha: 0.1),
                  spreadRadius: 0,
                  blurRadius: 30,
                  offset: const Offset(4, 4),
                ),
              ],
              color: selectedSurah?.number == surah.number
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$surahNumber. ${surah.englishName}',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: selectedSurah?.number == surah.number
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 15,
                  color: selectedSurah?.number == surah.number
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ],
            ),
          ),
          onTap: () {
            // Track surah selection
            AnalyticsService.trackSurahSelected(surah.englishName, surahNumber);

            if (isWideScreen) {
              setState(() {
                selectedSurah = surah;
              });
            } else {
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
                      builder: (_) {
                        return TestBySurah(surahNumber: surahNumber);
                      },
                    ),
                  );
              }
            }
          },
        );
      },
    );

    if (isWideScreen) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.surface
              : Colors.white,
          surfaceTintColor: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.primary
              : const Color(0xFF004B40),
          scrolledUnderElevation: 10,
          title: Text(
            'Surah List',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.onSurface
                  : const Color(0xFF222222),
            ),
          ),
        ),
        body: Row(
          children: [
            // Left: List
            Expanded(
              flex: 2,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/img/surah_background.png"),
                    fit: BoxFit.cover,
                  ),
                ),
                child: surahListView,
              ),
            ),
            // Right: Details
            Expanded(
              flex: 3,
              child: Container(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.surface
                    : Colors.grey[100],
                child: selectedSurah == null
                    ? Center(
                        child: Text(context.l10n.surahListDesktopPlaceholder))
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
      // Original small-screen view
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.surface
              : Colors.white,
          surfaceTintColor: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.primary
              : const Color(0xFF004B40),
          scrolledUnderElevation: 10,
          centerTitle: false,
          automaticallyImplyLeading: false,
          title: isSearching
              ? TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: context.l10n.surahListSearchHint,
                  ),
                  onChanged: (juzName) {
                    surahList = searchSurah(juzName);
                    setState(() {});
                  },
                )
              : Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: SvgPicture.asset('assets/img/arrow_back.svg'),
                    ),
                    const SizedBox(width: 13),
                    Text(
                      context.l10n.surahListTitle,
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).colorScheme.onSurface
                            : const Color(0xFF222222),
                      ),
                    ),
                  ],
                ),
          actions: [
            if (isSearching)
              IconButton(
                onPressed: () {
                  setSurahList();
                  setState(() => isSearching = false);
                },
                icon: const Icon(Icons.close),
              )
            else
              IconButton(
                onPressed: () {
                  setState(() => isSearching = true);
                },
                icon: SvgPicture.asset('assets/img/search.svg'),
              )
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/img/surah_background.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: surahListView,
        ),
      );
    }
  }
}
