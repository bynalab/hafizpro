import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/extension/quran_extension.dart';
import 'package:hafiz_test/locator.dart';
import 'package:hafiz_test/model/ayah.model.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/services/audio_center.dart';
import 'package:hafiz_test/services/audio_services.dart';
import 'package:hafiz_test/services/ayah.services.dart';
import 'package:hafiz_test/services/surah.services.dart';
import 'package:hafiz_test/services/analytics_service.dart';
import 'package:hafiz_test/test_screen.dart';
import 'package:hafiz_test/quran/widgets/error.dart';

class TestByJuz extends StatefulWidget {
  final int juzNumber;

  const TestByJuz({super.key, required this.juzNumber});

  @override
  State<StatefulWidget> createState() => _TestPage();
}

class _TestPage extends State<TestByJuz> {
  final surahServices = getIt<SurahServices>();
  final ayahServices = getIt<AyahServices>();
  final audioCenter = getIt<AudioCenter>();

  bool isLoading = true;
  bool hasError = false;
  String? errorMessage;

  late Ayah currentAyah;

  Surah surah = Surah();

  Future<void> init() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = null;
    });

    try {
      // The Ayah returned from this function does not contain `audioSource`
      final ayahFromJuz =
          await ayahServices.getRandomAyahFromJuz(widget.juzNumber);

      final surahNumber = ayahFromJuz.surah?.number ?? 0;
      surah = await surahServices.getSurah(surahNumber);

      // Hence, the need to loop through surah ayahs to get audioSource for `ayahFromJuz`
      currentAyah = surah.ayahs.firstWhere(
        (ayah) => ayah.number == ayahFromJuz.number,
      );

      await getIt<AudioServices>().setAudioSource(currentAyah.audioSource);

      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading juz for test: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      audioCenter.beginTestSession();
      init();
    });
  }

  @override
  void dispose() {
    audioCenter.endTestSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Track back press
          AnalyticsService.trackBackPress(fromScreen: 'Test By Juz');
        }
      },
      child: Scaffold(
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
          scrolledUnderElevation: 0,
          centerTitle: false,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHigh
                        .withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    'assets/img/arrow_back.svg',
                    width: 18,
                    height: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Juz ${widget.juzNumber}',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.onSurface
                      : const Color(0xFF222222),
                ),
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            if (isLoading)
              const Center(
                child: CircularProgressIndicator.adaptive(
                  strokeWidth: 5,
                  backgroundColor: Colors.blueGrey,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else if (hasError)
              CustomErrorWidget(
                title: 'Failed to Load Juz Test',
                message:
                    'Unable to load the juz for testing. Please check your connection and try again.',
                icon: Icons.quiz_outlined,
                color: Colors.purple.shade700,
                onRetry: () async {
                  await init();
                },
              )
            else
              SingleChildScrollView(
                child: TestScreen(
                  surah: surah,
                  currentAyah: currentAyah,
                  onRefresh: init,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
