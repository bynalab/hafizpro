import 'package:flutter/material.dart';
import 'package:hafiz_test/locator.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/quran/widgets/error.dart';
import 'package:hafiz_test/quran/quran_list.dart';
import 'package:hafiz_test/quran/quran_viewmodel.dart';
import 'package:hafiz_test/quran/surah_loader.dart';
import 'package:hafiz_test/services/audio_services.dart';
import 'package:hafiz_test/services/surah.services.dart';
import 'package:hafiz_test/services/analytics_service.dart';
import 'package:hafiz_test/util/l10n_extensions.dart';

class QuranView extends StatefulWidget {
  final Surah surah;

  const QuranView({super.key, required this.surah});

  @override
  State<QuranView> createState() => _QuranViewState();
}

class _QuranViewState extends State<QuranView> {
  final viewModel = QuranViewModel(
    audioService: getIt<AudioServices>(),
    surahService: getIt<SurahServices>(),
  );

  @override
  void initState() {
    super.initState();

    viewModel.initiateListeners();
    viewModel.initialize(widget.surah.number).then((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    viewModel.dispose();

    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading) {
      return Scaffold(body: SurahLoader());
    }

    if (viewModel.hasError) {
      return Scaffold(
        body: CustomErrorWidget(
          title: context.l10n.quranViewErrorTitle,
          message: context.l10n.quranViewErrorMessage,
          icon: Icons.menu_book_rounded,
          color: Colors.green.shade700,
          onRetry: () async {
            setState(() {});
            await viewModel.initialize(widget.surah.number);
            setState(() {});
          },
        ),
      );
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Track back press
          AnalyticsService.trackBackPress(fromScreen: 'Quran View');
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          elevation: 0,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          title: ValueListenableBuilder<int?>(
            valueListenable: viewModel.playingIndexNotifier,
            builder: (context, index, _) {
              final ayahs = viewModel.surah.ayahs;
              final valid = index != null && index >= 0 && index < ayahs.length;
              final verseText = valid
                  ? ' - ${ayahs[index].numberInSurah}/${viewModel.surah.numberOfAyahs}'
                  : '';
              return Text(
                '${viewModel.surah.englishName}$verseText',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              );
            },
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.only(bottom: 80),
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage('assets/img/surah_background.png'),
                    fit: BoxFit.cover,
                  ),
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black.withValues(alpha: 0.3)
                      : null,
                  backgroundBlendMode:
                      Theme.of(context).brightness == Brightness.dark
                          ? BlendMode.multiply
                          : null,
                ),
                child: QuranAyahList(
                  surah: viewModel.surah,
                  playingIndexNotifier: viewModel.playingIndexNotifier,
                  scrollController: viewModel.itemScrollController,
                  onControlPressed: viewModel.onAyahControlPressed,
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: ValueListenableBuilder<bool>(
                  valueListenable: viewModel.isPlayingNotifier,
                  builder: (_, __, ___) {
                    return Container(
                      height: 80,
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surface
                            .withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            viewModel.isPlayingPlaylist
                                ? context.l10n.quranViewPlayingFullSurah
                                : context.l10n.quranViewPlayFullSurah,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          GestureDetector(
                            onTap: viewModel.togglePlayPause,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: viewModel.isPlayingPlaylist
                                    ? Colors.red.shade600
                                    : Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                viewModel.isPlayingPlaylist
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                                size: 25,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
