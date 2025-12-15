import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/data/juz_list.dart';
import 'package:hafiz_test/juz/test_by_juz.dart';
import 'package:hafiz_test/main_menu/widgets.dart';
import 'package:hafiz_test/model/juz.model.dart';
import 'package:hafiz_test/services/analytics_service.dart';

class JuzListScreen extends StatefulWidget {
  const JuzListScreen({super.key});

  @override
  State<JuzListScreen> createState() => _JuzListScreenState();
}

class _JuzListScreenState extends State<JuzListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();

    // Track juz list screen view
    AnalyticsService.trackScreenView('Juz List Screen');

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
    final displayJuz = _query.trim().isEmpty ? juzList : searchJuz(_query);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: kIsWeb
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: _JuzListBody(
                  title: 'Juz List',
                  headerBackground: const Color(0xFF7CB7C6),
                  headerDescriptionTitle: 'Select a Juz',
                  headerDescriptionBody:
                      'Listen to a verse from a Juz and\nguess the next verse.',
                  headerImage: 'assets/img/juz_image.png',
                  searchHint: 'Type Juz number',
                  searchController: _searchController,
                  juzNames: displayJuz,
                  onBack: () => Navigator.pop(context),
                ),
              ),
            )
          : _JuzListBody(
              title: 'Juz List',
              headerBackground: const Color(0xFF7CB7C6),
              headerDescriptionTitle: 'Select a Juz',
              headerDescriptionBody:
                  'Listen to a verse from a Juz and\nguess the next verse.',
              headerImage: 'assets/img/juz_image.png',
              searchHint: 'Type Juz number',
              searchController: _searchController,
              juzNames: displayJuz,
              onBack: () => Navigator.pop(context),
            ),
    );
  }
}

class _JuzListBody extends StatelessWidget {
  const _JuzListBody({
    required this.title,
    required this.headerBackground,
    required this.headerDescriptionTitle,
    required this.headerDescriptionBody,
    required this.headerImage,
    required this.searchHint,
    required this.searchController,
    required this.juzNames,
    required this.onBack,
  });

  final String title;
  final Color headerBackground;
  final String headerDescriptionTitle;
  final String headerDescriptionBody;
  final String headerImage;
  final String searchHint;
  final TextEditingController searchController;
  final List<JuzModel> juzNames;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
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
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: Color(0xFF111827),
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
                          color: const Color(0xFF111827),
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
                            headerDescriptionTitle,
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            headerDescriptionBody,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF111827),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: -20,
                    bottom: -33,
                    child: Image.asset(
                      headerImage,
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
                          controller: searchController,
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
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                  itemCount: juzNames.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (_, index) {
                    final juz = juzNames[index];
                    final juzNumber = juz.number;

                    return JuzCard(
                      juz: juz,
                      showPlayButton: false,
                      onTap: () {
                        AnalyticsService.trackJuzSelected(juzNumber);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TestByJuz(juzNumber: juzNumber),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
