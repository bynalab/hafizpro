import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/data/juz_list.dart';
import 'package:hafiz_test/juz/test_by_juz.dart';
import 'package:hafiz_test/services/analytics_service.dart';
import 'package:hafiz_test/util/l10n_extensions.dart';

class JuzListScreen extends StatefulWidget {
  const JuzListScreen({super.key});

  @override
  State<JuzListScreen> createState() => _JuzListScreenState();
}

class _JuzListScreenState extends State<JuzListScreen> {
  bool isSearching = false;

  @override
  void initState() {
    super.initState();

    // Track juz list screen view
    AnalyticsService.trackScreenView('Juz List Screen');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).colorScheme.surface
          : Colors.white,
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
                decoration:
                    InputDecoration(hintText: context.l10n.juzListSearchHint),
                onChanged: (juzName) {
                  juzList = searchJuz(juzName);

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
                    context.l10n.juzListTitle,
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
                setJuz();
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
        child: kIsWeb
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: _buildJuzListView(),
                ),
              )
            : _buildJuzListView(),
      ),
    );
  }

  Widget _buildJuzListView() {
    return ListView.separated(
      padding: const EdgeInsets.all(15),
      itemCount: juzList.length,
      separatorBuilder: (context, index) {
        return const SizedBox(height: 10);
      },
      itemBuilder: (_, index) {
        final juzNumber = index + 1;

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
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.surface
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$juzNumber. ${juzList[index]}',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).colorScheme.onSurface
                        : const Color(0xFF222222),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 15,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.onSurface
                      : const Color(0xFF181817),
                ),
              ],
            ),
          ),
          onTap: () {
            // Track juz selection
            AnalyticsService.trackJuzSelected(juzNumber);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) {
                  return TestByJuz(juzNumber: juzNumber);
                },
              ),
            );
          },
        );
      },
    );
  }
}
