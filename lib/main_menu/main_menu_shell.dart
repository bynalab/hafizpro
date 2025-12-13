import 'package:flutter/material.dart';
import 'package:hafiz_test/services/analytics_service.dart';
import 'package:hafiz_test/settings/settings_screen.dart';
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
    return Scaffold(
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
