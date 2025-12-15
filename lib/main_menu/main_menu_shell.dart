import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hafiz_test/services/analytics_service.dart';
import 'package:hafiz_test/settings/settings_screen.dart';
import 'package:hafiz_test/util/app_colors.dart';
import 'package:hafiz_test/util/theme_controller.dart';
import 'package:hafiz_test/locator.dart';

import 'package:hafiz_test/main_menu/quran_dashboard_page.dart';
import 'package:hafiz_test/main_menu/test_menu_page.dart';
import 'package:hafiz_test/main_menu/widgets.dart';

class MainMenuShell extends StatefulWidget {
  const MainMenuShell({super.key});

  @override
  State<StatefulWidget> createState() => _MainMenuShellState();
}

class _MainMenuShellState extends State<MainMenuShell> {
  final _themeController = getIt<ThemeController>();

  int _tabIndex = 0;
  int _quranSegment = 0; // 0=Surah, 1=Juz

  DateTime? _lastBackPress;

  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();

    AnalyticsService.trackScreenView('Main Menu');
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (_tabIndex != 0) {
          setState(() => _tabIndex = 0);
          return;
        }

        final now = DateTime.now();
        final last = _lastBackPress;
        _lastBackPress = now;

        if (last != null && now.difference(last) < const Duration(seconds: 2)) {
          AnalyticsService.trackBackPress(fromScreen: 'Main Menu');
          SystemNavigator.pop();
          return;
        }

        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: AppColors.green500,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              content: Semantics(
                liveRegion: true,
                label: 'Press back again within two seconds to exit the app',
                child: Text(
                  'Press back again to exit',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              duration: Duration(seconds: 2),
            ),
          );
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              IndexedStack(
                index: _tabIndex,
                children: [
                  QuranDashboardPage(
                    segmentIndex: _quranSegment,
                    onSegmentChanged: (i) => setState(() => _quranSegment = i),
                    searchController: _searchController,
                    query: _query,
                    onOpenSettings: _openSettings,
                    onToggleTheme: _toggleTheme,
                  ),
                  TestMenuPage(
                    onOpenSettings: _openSettings,
                    onToggleTheme: _toggleTheme,
                  ),
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: BottomPillNav(
                    index: _tabIndex,
                    onChanged: (i) => setState(() => _tabIndex = i),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSettings() async {
    AnalyticsService.trackButtonClick('Settings', screen: 'Main Menu');
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _toggleTheme() async {
    final current = ThemeMode.values.byName(_themeController.mode);
    final next = current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _themeController.setMode(next.name);
    if (!mounted) return;
    setState(() {});
  }
}
