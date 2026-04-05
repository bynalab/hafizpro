import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/data/surah_list.dart';
import 'package:hafiz_test/extension/quran_extension.dart';
import 'package:hafiz_test/locator.dart';
import 'package:hafiz_test/model/ayah.model.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/services/audio_center.dart';
import 'package:hafiz_test/services/audio_services.dart';
import 'package:hafiz_test/services/ayah.services.dart';
import 'package:hafiz_test/services/surah.services.dart';
import 'package:hafiz_test/services/analytics_service.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:hafiz_test/settings/sheets/reciter_picker_sheet.dart';
import 'package:hafiz_test/test_screen.dart';
import 'package:hafiz_test/quran/quran_view.dart';
import 'package:hafiz_test/quran/widgets/error.dart';
import 'package:hafiz_test/util/l10n_extensions.dart';
import 'package:hafiz_test/util/util.dart';
import 'package:hafiz_test/widget/compatibility_error_view.dart';

class TestBySurah extends StatefulWidget {
  final int? surahNumber;
  final int? ayahNumber;
  final List<int>? surahNumbers;

  const TestBySurah({
    super.key,
    this.surahNumber,
    this.ayahNumber,
    this.surahNumbers,
  });

  @override
  State<StatefulWidget> createState() => _TestPage();
}

class _TestPage extends State<TestBySurah> {
  final surahServices = getIt<SurahServices>();
  final audioCenter = getIt<AudioCenter>();
  final storageServices = getIt<IStorageService>();

  bool isLoading = true;
  bool hasError = false;
  String? errorMessage;

  int? _currentSurahNumber;
  int? _currentAyahNumber;

  List<int> get _sortedSurahNumbers => widget.surahNumbers ?? [];

  int get _currentIndex {
    final sortedList = _sortedSurahNumbers;
    if (sortedList.isEmpty || _currentSurahNumber == null) return -1;
    return sortedList.indexOf(_currentSurahNumber!);
  }

  late Surah surah = Surah();
  late Ayah currentAyah;

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

  bool get _isReciterModeError {
    return (errorMessage ?? '').toLowerCase().contains('surah-by-surah');
  }

  Future<void> _changeReciterAndRetry() async {
    final selected = await ReciterPickerSheet(
      selected: storageServices.getReciterId(),
      showOnlyVerseByVerse: _isReciterModeError,
    ).openBottomSheet(context);
    if (selected == null) return;

    await storageServices.setReciterId(selected.identifier);
    // await getIt<AudioCenter>().onReciterChanged();
    await init();
  }

  Future<void> init() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = null;
    });

    try {
      final sortedList = _sortedSurahNumbers;
      if (_currentSurahNumber != null) {
        // Use the surah number from state (for navigation)
      } else if (sortedList.isNotEmpty) {
        // First load of custom selection: Pick a random surah from the list
        final random = Random();
        _currentSurahNumber = sortedList[random.nextInt(sortedList.length)];
      } else if (widget.surahNumber == null) {
        _currentSurahNumber = surahServices.getRandomSurahNumber();
      } else {
        _currentSurahNumber = widget.surahNumber!;
      }

      int surahNumberToLoad = _currentSurahNumber!;
      surah = await surahServices.getSurah(surahNumberToLoad);

      if (surah.isSurahLevelAudio) {
        throw StateError(
          'Selected reciter audio is surah-by-surah, which cannot be used for Test. Please choose a verse-by-verse reciter.',
        );
      }

      currentAyah = _getAyahForSurah();

      await getIt<AudioServices>().setAudioSource(currentAyah.audioSource);

      if (!mounted) return;

      setState(() {
        isLoading = false;
        hasError = false;
        // Reset navigation ayah number after consumption
        _currentAyahNumber = null;
      });
    } catch (e) {
      debugPrint('Error loading surah for test: $e');

      if (!mounted) return;
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = e.toString();
      });
    }
  }

  void _onNextSurah() {
    final currentIndex = _currentIndex;
    if (currentIndex == -1) return;

    final sortedList = _sortedSurahNumbers;
    if (currentIndex < sortedList.length - 1) {
      setState(() {
        _currentSurahNumber = sortedList[currentIndex + 1];
        _currentAyahNumber = 1;
      });

      init();
    } else {
      showSnackBar(context, context.l10n.testEndOfSurah);
    }
  }

  void _onPreviousSurah() {
    final currentIndex = _currentIndex;
    if (currentIndex == -1) return;

    if (currentIndex > 0) {
      final sortedList = _sortedSurahNumbers;
      final prevSurahNumber = sortedList[currentIndex - 1];
      // We need the last ayah number of the previous surah
      final prevSurahData = findSurahByNumber(prevSurahNumber);

      setState(() {
        _currentSurahNumber = prevSurahNumber;
        _currentAyahNumber = prevSurahData.numberOfAyahs;
      });

      init();
    } else {
      showSnackBar(context, context.l10n.testBeginningOfSurah);
    }
  }

  Future<void> _onRefresh() async {
    // For refresh, we want a new random surah (if multi-mode) or same surah random ayah
    if (widget.surahNumbers != null && widget.surahNumbers!.isNotEmpty) {
      _currentSurahNumber = null; // Forces picking a new random one in init()
    }

    await init();
  }

  Ayah _getAyahForSurah() {
    if (_currentAyahNumber != null) {
      return surah.getAyah(_currentAyahNumber);
    }
    return widget.ayahNumber != null
        ? surah.getAyah(widget.ayahNumber)
        : getIt<AyahServices>()
            .getRandomAyahForSurah(surah.ayahs, surahNumber: surah.number);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Track back press
          AnalyticsService.trackBackPress(fromScreen: 'Test By Surah');
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
              Directionality(
                textDirection: TextDirection.ltr,
                child: InkWell(
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
              ),
              const SizedBox(width: 14),
              Text(
                '${surah.englishName} (${surah.number.toString().padLeft(2, '0')})',
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
            if (hasError)
              _isReciterModeError
                  ? CompatibilityErrorView(
                      onChooseReciter: _changeReciterAndRetry,
                      onRetry: init,
                    )
                  : CustomErrorWidget(
                      title: context.l10n.testErrorTitle,
                      message: errorMessage ?? context.l10n.testErrorMessage,
                      icon: Icons.quiz_outlined,
                      color: Colors.orange.shade700,
                      onRetry: () async {
                        await init();
                      },
                      secondaryActionLabel: _isReciterModeError
                          ? context.l10n.changeReciter
                          : null,
                      onSecondaryAction:
                          _isReciterModeError ? _changeReciterAndRetry : null,
                    )
            else
              TestScreen(
                surah: surah,
                currentAyah: isLoading ? Ayah() : currentAyah,
                isLoading: isLoading,
                onReadFull: () async {
                  final surahNumber = _currentSurahNumber ?? 0;
                  final surahName = surah.englishName;
                  if (surahNumber <= 0) return;

                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuranView(
                        surah: Surah(
                          number: surahNumber,
                          englishName: surahName,
                        ),
                      ),
                    ),
                  );
                },
                onRefresh: _onRefresh,
                onNextBoundary:
                    _sortedSurahNumbers.isNotEmpty ? _onNextSurah : null,
                onPreviousBoundary:
                    _sortedSurahNumbers.isNotEmpty ? _onPreviousSurah : null,
              ),
          ],
        ),
      ),
    );
  }
}
