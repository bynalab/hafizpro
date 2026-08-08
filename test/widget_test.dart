import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_test/main_menu.dart';
import 'package:hafiz_test/splash_screen.dart';
import 'package:hafiz_test/l10n/app_localizations.dart';
import 'test_helper.dart';

void main() {
  setUp(() {
    setupTestLocator();
    setupMockSharedPreferences();
  });

  tearDown(() {
    tearDownTestLocator();
  });

  testWidgets('SplashScreen builds and navigates to MainMenu', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SplashScreen(),
      ),
    );

    expect(find.text('Master the Quran, one Ayah at a time'), findsOneWidget);
    expect(
      find.text(
          "وَلَقَدْ يَسَّرْنَا الْقُرْآنَ لِلذِّكْرِ فَهَلْ مِن مُّدَّكِرٍ"),
      findsOneWidget,
    );

    // Wait for navigation to complete
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Check if MainMenu is present (ignore UI overflow warnings)
    expect(find.byType(MainMenu), findsOneWidget);
  });
}
