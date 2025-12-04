import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/enum/surah_select_action.dart';
import 'package:hafiz_test/locator.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:hafiz_test/services/analytics_service.dart';
import 'package:hafiz_test/widget/last_read_card.dart';
import 'package:hafiz_test/widget/showcase.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:hafiz_test/juz/juz_list_screen.dart';
import 'package:hafiz_test/settings_dialog.dart';
import 'package:hafiz_test/surah/surah_list_screen.dart';
import 'package:hafiz_test/surah/test_by_surah.dart';
import 'package:hafiz_test/widget/test_menu_card.dart';
import 'package:hafiz_test/services/rating_service.dart';

class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      builder: (_) => _MainMenu(key: key),
      onFinish: () => getIt<IStorageService>().saveUserGuide(),
    );
  }
}

class _MainMenu extends StatefulWidget {
  const _MainMenu({super.key});

  @override
  State<StatefulWidget> createState() => _MainMenuState();
}

class _MainMenuState extends State<_MainMenu> {
  final _settingKey = GlobalKey();
  final _bugReportKey = GlobalKey();
  final _lastReadKey = GlobalKey();
  final _quranCardKey = GlobalKey();
  final _surahCardKey = GlobalKey();
  final _juzCardKey = GlobalKey();
  final _randomCardKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // Track main menu screen view
    AnalyticsService.trackScreenView('Main Menu');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      startShowcase();
    });
  }

  void startShowcase() {
    final hasViewedShowcase = getIt<IStorageService>().hasViewedShowcase();

    if (!mounted || hasViewedShowcase) return;

    ShowCaseWidget.of(context).startShowCase([
      _bugReportKey,
      _settingKey,
      _lastReadKey,
      _quranCardKey,
      _surahCardKey,
      _juzCardKey,
      _randomCardKey,
    ]);
  }

  Future<void> navigateTo(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    setState(() {});

    // Check if we should show rating dialog after user returns
    _checkAndShowRatingDialog();
  }

  Future<void> _checkAndShowRatingDialog() async {
    if (await RatingService.shouldShowRatingDialog()) {
      // Small delay to ensure UI is ready
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        await RatingService.showRatingDialog(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAction = ShowCase(
      widgetKey: _settingKey,
      title: 'Settings',
      description: 'Change autoplay settings and select your favorite reciter',
      child: IconButton(
        onPressed: () {
          AnalyticsService.trackButtonClick('Settings', screen: 'Main Menu');
          showDialog(
            barrierDismissible: false,
            context: context,
            builder: (_) {
              return const SettingDialog();
            },
          );
        },
        icon: SvgPicture.asset(
          'assets/img/settings.svg',
          colorFilter: ColorFilter.mode(
            Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.onSurface
                : const Color(0xFF222222),
            BlendMode.srcIn,
          ),
        ),
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: onMainMenuPopInvoked,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.surface
              : Colors.white,
          surfaceTintColor: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.primary
              : const Color(0xFF004B40),
          scrolledUnderElevation: 10,
          automaticallyImplyLeading: false,
          title: kIsWeb
              ? Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image.asset(
                          'assets/img/logo.png',
                          width: 100,
                          height: 100,
                        ),
                        settingsAction,
                      ],
                    ),
                  ),
                )
              : Image.asset(
                  'assets/img/logo.png',
                  width: 100,
                  height: 100,
                ),
          actions: kIsWeb ? [] : [settingsAction],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Builder(
            builder: (context) {
              final content = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LastReadCard(lastReadKey: _lastReadKey),
                  const SizedBox(height: 34),
                  Row(
                    children: [
                      Expanded(
                        child: ShowCase(
                          widgetKey: _quranCardKey,
                          title: 'Read Quran',
                          description:
                              'Read or listen to the Holy Quran with your preferred reciter.',
                          child: TestMenuCard(
                            title: 'Read/Listen to Quran',
                            image: 'card_quran',
                            color: const Color(0xFF2BFF00),
                            onTap: () {
                              AnalyticsService.trackButtonClick('Read Quran',
                                  screen: 'Main Menu');
                              navigateTo(
                                const SurahListScreen(
                                  actionType: SurahSelectionAction.read,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 17),
                  Text(
                    'Tests',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.onSurface
                          : const Color(0xFF222222),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ShowCase(
                          widgetKey: _surahCardKey,
                          title: 'By Surah',
                          description:
                              'Begin your test journey by selecting a specific Surah.',
                          child: TestMenuCard(
                            height: 160,
                            title: 'By Surah',
                            image: 'card_surah',
                            color: const Color(0xFFFF8E6F),
                            onTap: () {
                              AnalyticsService.trackButtonClick('Test By Surah',
                                  screen: 'Main Menu');
                              navigateTo(
                                const SurahListScreen(
                                  actionType: SurahSelectionAction.test,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 17),
                  Row(
                    children: [
                      Expanded(
                        child: ShowCase(
                          widgetKey: _juzCardKey,
                          title: 'By Juz',
                          description:
                              'Begin your test journey by selecting a specific Juz of the Quran.',
                          child: TestMenuCard(
                            height: 160,
                            title: 'By Juz',
                            image: 'card_juz',
                            color: const Color(0xFFFBBE15),
                            onTap: () {
                              AnalyticsService.trackButtonClick('Test By Juz',
                                  screen: 'Main Menu');
                              navigateTo(const JuzListScreen());
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 17),
                      Expanded(
                        child: ShowCase(
                          widgetKey: _randomCardKey,
                          title: 'Random Test',
                          description:
                              'Challenge yourself with verses selected at random from across the Holy Quran.',
                          child: TestMenuCard(
                            height: 160,
                            title: 'Randomly',
                            image: 'card_random',
                            color: const Color(0xFF6E81F6),
                            onTap: () {
                              AnalyticsService.trackButtonClick('Random Test',
                                  screen: 'Main Menu');
                              navigateTo(const TestBySurah());
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );

              if (kIsWeb) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: content,
                  ),
                );
              }

              return content;
            },
          ),
        ),
      ),
    );
  }

  Future<void> onMainMenuPopInvoked(bool didPop, Object? result) async {
    if (didPop) return;

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text('Do you want to exit?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      SystemNavigator.pop();
    }
  }
}
