import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';

import 'package:hafiz_test/data/juz_list.dart';
import 'package:hafiz_test/data/surah_dashboard_search.dart';
import 'package:hafiz_test/data/surah_list.dart';
import 'package:hafiz_test/locator.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/model/ayah.model.dart';
import 'package:hafiz_test/model/juz.model.dart';
import 'package:hafiz_test/model/bookmark.model.dart';
import 'package:hafiz_test/juz/juz_quran_view.dart';
import 'package:hafiz_test/quran/quran_view.dart';
import 'package:hafiz_test/services/audio_center.dart';
import 'package:hafiz_test/services/analytics_service.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:hafiz_test/surah/test_by_surah.dart';
// import 'package:hafiz_test/surah/surah_list_screen.dart';
// import 'package:hafiz_test/enum/surah_select_action.dart';
import 'package:hafiz_test/util/app_colors.dart';
import 'package:hafiz_test/util/l10n_extensions.dart';
// import 'package:hafiz_test/widget/cumulative_playlist_progress_bar.dart';
import 'package:hafiz_test/bookmark/bookmarks_page.dart';

import 'package:hafiz_test/main_menu/widgets.dart';
import 'package:hafiz_test/main_menu/widgets/quran_progress_card.dart';
// import 'package:hafiz_test/main_menu/widgets/takbeer_card.dart';

class QuranDashboardPage extends StatefulWidget {
  const QuranDashboardPage({
    super.key,
    required this.segmentIndex,
    required this.onSegmentChanged,
    required this.searchController,
    required this.query,
    required this.onOpenSettings,
    required this.onToggleTheme,
  });

  final int segmentIndex;
  final ValueChanged<int> onSegmentChanged;
  final TextEditingController searchController;
  final String query;
  final VoidCallback onOpenSettings;
  final VoidCallback onToggleTheme;

  @override
  State<QuranDashboardPage> createState() => _QuranDashboardPageState();
}

class _QuranDashboardPageState extends State<QuranDashboardPage> {
  bool get _isSearching => widget.query.trim().isNotEmpty;

  final _audioCenter = getIt<AudioCenter>();

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    const pillOuterBottomPadding = 18.0;
    const pillHeight = 44.0;
    const pillVerticalPadding = 8.0;
    const bottomNavReserved =
        pillOuterBottomPadding + pillHeight + (pillVerticalPadding * 2);

    final surahSearch = resolveSurahDashboardSearch(widget.query);
    final displaySurahs =
        widget.segmentIndex == 0 ? surahSearch.surahs : surahList;
    final displayJuz = _isSearching ? searchJuz(widget.query) : juzList;

    final storage = getIt<IStorageService>();
    final lastRead = storage.getLastRead();
    final bookmarks = storage.getBookmarks();
    final bookmark = bookmarks.isNotEmpty ? bookmarks.first : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: AnimatedBuilder(
        animation: _audioCenter,
        builder: (context, _) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      CircleIconButton(
                        background: AppColors.green500,
                        icon: SvgPicture.asset(
                          'assets/img/quran-01.svg',
                          width: 20,
                          height: 20,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                        onTap: () {},
                      ),
                      const Spacer(),
                      CircleIconButton(
                        background: DashboardPalette.iconButtonBg(context),
                        icon: Icon(
                          Theme.of(context).brightness == Brightness.dark
                              ? Icons.light_mode
                              : Icons.dark_mode,
                          color: DashboardPalette.primaryText(context),
                        ),
                        onTap: widget.onToggleTheme,
                      ),
                      const SizedBox(width: 10),
                      CircleIconButton(
                        background: DashboardPalette.iconButtonBg(context),
                        icon: const Icon(
                          Icons.settings,
                          color: null,
                        ),
                        onTap: widget.onOpenSettings,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SearchField(
                    controller: widget.searchController,
                    hintText: widget.segmentIndex == 0
                        ? context.l10n.searchBySurahOrVerseHint
                        : context.l10n.searchByJuzHint,
                  ),
                  const SizedBox(height: 10),
                  if (!_isSearching) ...[
                    if (storage.getProgressTrackingMode() != 'off') ...[
                      const QuranProgressCard(),
                      const SizedBox(height: 10),
                    ],
                    if (lastRead == null)
                      DashboardFeatureCard(
                        background: DashboardPalette.cardTeal(context),
                        title: context.l10n.dashboardChallengeTitle,
                        onTap: () {
                          AnalyticsService.trackButtonClick(
                              'Challenge Yourself',
                              screen: 'Main Menu');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TestBySurah(),
                            ),
                          );
                        },
                        right: Image.asset(
                          'assets/img/quran_question_icon.png',
                          width: 56,
                          height: 56,
                          fit: BoxFit.contain,
                        ),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/img/brain.svg',
                              width: 18,
                              height: 18,
                              colorFilter: ColorFilter.mode(
                                DashboardPalette.primaryText(context),
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                context.l10n.dashboardChallengeDescription,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: DashboardPalette.primaryText(context),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: DashboardPalette.primaryText(context),
                            ),
                          ],
                        ),
                      )
                    else
                      _ContinueLastTestCard(lastRead: lastRead),
                    const SizedBox(height: 10),
                    _ContinueReadingCard(bookmark: bookmark),
                    // const SizedBox(height: 10),
                    // const TakbeerCard(),
                    ListenableBuilder(
                      listenable: _audioCenter,
                      builder: (context, _) {
                        final currentSurahNumber =
                            _audioCenter.currentSurahNumber;
                        final currentSurahName = _audioCenter.currentSurahName;
                        final currentJuzNumber = _audioCenter.currentJuzNumber;

                        if (currentJuzNumber == null &&
                            (currentSurahNumber == null ||
                                currentSurahName == null)) {
                          return const SizedBox.shrink();
                        }

                        final title = currentJuzNumber != null
                            ? context.l10n.juzNumberLabel(currentJuzNumber)
                            : (currentSurahName ?? '');

                        return Column(
                          children: [
                            const SizedBox(height: 10),
                            _NowPlayingCard(
                              audioPlayer: _audioCenter.audioPlayer,
                              title: title,
                              isLoading: _audioCenter.isLoading,
                              onTap: () {
                                final juzNumber = currentJuzNumber;
                                if (juzNumber != null) {
                                  final juz = findJuzByNumber(juzNumber);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => JuzQuranView(juz: juz),
                                    ),
                                  );
                                  return;
                                }

                                final surahNumber = currentSurahNumber;
                                final surahName = currentSurahName;
                                if (surahNumber == null || surahName == null) {
                                  return;
                                }

                                final surah = Surah(
                                  number: surahNumber,
                                  englishName: surahName,
                                );

                                AnalyticsService.trackSurahSelected(
                                  surah.englishName,
                                  surah.number,
                                );

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => QuranView(surah: surah),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 14),
                          ],
                        );
                      },
                    ),
                    // _ContinueReadingCard(lastRead: lastRead),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.dashboardListenReadHeader,
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: DashboardPalette.primaryText(context),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            if (!_isSearching)
              SliverPersistentHeader(
                pinned: true,
                delegate: _PinnedSegmentHeaderDelegate(
                  minExtent: 58,
                  maxExtent: 58,
                  child: Container(
                    color: DashboardPalette.pinnedHeaderBg(context),
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SegmentedSwitch(
                      leftLabel: context.l10n.segmentSurah,
                      rightLabel: context.l10n.segmentJuz,
                      index: widget.segmentIndex,
                      onChanged: widget.onSegmentChanged,
                    ),
                  ),
                ),
              )
            else
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
            if (widget.segmentIndex == 0)
              SliverList.separated(
                itemCount: displaySurahs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final surah = displaySurahs[i];

                  return SurahCard(
                    surah: surah,
                    onTap: () {
                      AnalyticsService.trackSurahSelected(
                        surah.englishName,
                        surah.number,
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) {
                            return QuranView(
                              surah: surah,
                              initialAyahNumber: surahSearch.initialAyahNumber,
                            );
                          },
                        ),
                      );
                    },
                    onPlay: () async {
                      await _audioCenter.toggleSurah(surah);
                    },
                    isPlaying: _audioCenter.isCurrentSurah(surah.number) &&
                        _audioCenter.isPlaying,
                    isLoading: _audioCenter.isCurrentSurah(surah.number) &&
                        _audioCenter.isLoading,
                  );
                },
              )
            else
              SliverList.separated(
                itemCount: displayJuz.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final JuzModel juz = displayJuz[i];
                  final juzNumber = juz.number;

                  return JuzCard(
                    juz: juz,
                    onTap: () {
                      AnalyticsService.trackJuzSelected(juzNumber);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JuzQuranView(juz: juz),
                        ),
                      );
                    },
                    onPlay: () async {
                      AnalyticsService.trackJuzSelected(juzNumber);
                      await _audioCenter.toggleJuz(juz);
                    },
                    isPlaying: _audioCenter.isCurrentJuz(juzNumber) &&
                        _audioCenter.isPlaying,
                    isLoading: _audioCenter.isCurrentJuz(juzNumber) &&
                        _audioCenter.isLoading,
                  );
                },
              ),
            SliverToBoxAdapter(
              child: SizedBox(height: bottomNavReserved + bottomInset + 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinnedSegmentHeaderDelegate extends SliverPersistentHeaderDelegate {
  _PinnedSegmentHeaderDelegate({
    required this.minExtent,
    required this.maxExtent,
    required this.child,
  });

  @override
  final double minExtent;

  @override
  final double maxExtent;

  final Widget child;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _PinnedSegmentHeaderDelegate oldDelegate) {
    return minExtent != oldDelegate.minExtent ||
        maxExtent != oldDelegate.maxExtent ||
        child != oldDelegate.child;
  }
}

class _ContinueLastTestCard extends StatelessWidget {
  const _ContinueLastTestCard({required this.lastRead});

  final (Surah, Ayah) lastRead;

  @override
  Widget build(BuildContext context) {
    final surah = lastRead.$1;
    final ayah = lastRead.$2;

    return DashboardFeatureCard(
      background: DashboardPalette.cardTeal(context),
      title: context.l10n.dashboardContinueLastTestTitle,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TestBySurah(
              surahNumber: surah.number,
              ayahNumber: ayah.numberInSurah,
            ),
          ),
        );
      },
      right: Image.asset(
        'assets/img/quran_question_icon.png',
        width: 72,
        height: 72,
        fit: BoxFit.contain,
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/img/brain.svg',
            width: 22,
            height: 22,
            colorFilter: ColorFilter.mode(
              DashboardPalette.primaryText(context),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  surah.englishName,
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: DashboardPalette.primaryText(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.verseNumberLabel(ayah.numberInSurah),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: DashboardPalette.secondaryText(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward,
            color: DashboardPalette.primaryText(context),
          ),
        ],
      ),
    );
  }
}

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard({required this.bookmark});

  final Bookmark? bookmark;

  @override
  Widget build(BuildContext context) {
    if (bookmark == null) return const SizedBox.shrink();

    final isDark = DashboardPalette.isDark(context);
    final surah = bookmark!.surah;
    final ayah = bookmark!.ayah;
    final isJuzContext = bookmark!.viewContext == BookmarkViewContext.juz;

    String contextText = '';
    if (isJuzContext) {
      contextText =
          'Juz ${bookmark!.juzNumber}, ${surah.englishName}, Verse ${ayah.numberInSurah}';
    } else {
      contextText = '${surah.englishName}, Verse ${ayah.numberInSurah}';
    }

    return DashboardFeatureCard(
      background: DashboardPalette.cardPeach(context),
      title: context.l10n.lastReadTitle,
      trailingTitle: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BookmarksPage()),
          );
        },
        child: Text(
          context.l10n.seeAllBookmarks,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: DashboardPalette.primaryText(context).withValues(alpha: 0.7),
            decoration: TextDecoration.underline,
          ),
        ),
      ),
      onTap: () {
        if (isJuzContext) {
          final juz = findJuzByNumber(bookmark!.juzNumber!);
          // We need an "initialAyahIndex" for JuzView.
          // Since we save the bookmark which includes the ayah, we can calculate its index in the juz.
          // For now, let's just use 0 if not easily available, but better to implement the logic.

          // Actually, we can calculate the global ayah index in the juz if we have the surah and ayah.
          // But a simpler way is to pass the surah/ayah to JuzView and let it find the index.
          // However, my updated JuzView expects initialAyahIndex.

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JuzQuranView(
                juz: juz,
                initialSurahNumber: surah.number,
                initialAyahNumber: ayah.numberInSurah,
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QuranView(
                surah: surah,
                initialAyahNumber: ayah.numberInSurah,
              ),
            ),
          );
        }
      },
      right: Image.asset(
        'assets/img/open_book_glass_icon.png',
        width: 64,
        height: 64,
        fit: BoxFit.contain,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.white54,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.menu_book_rounded,
                size: 18, color: DashboardPalette.primaryText(context)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isJuzContext
                      ? 'Juz ${bookmark!.juzNumber}'
                      : surah.englishName,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: DashboardPalette.primaryText(context),
                  ),
                ),
                Text(
                  contextText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: DashboardPalette.secondaryText(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: DashboardPalette.primaryText(context)),
        ],
      ),
    );
  }
}

class _NowPlayingCard extends StatelessWidget {
  final String title;
  final AudioPlayer audioPlayer;
  final VoidCallback onTap;
  final bool isLoading;

  const _NowPlayingCard({
    required this.audioPlayer,
    required this.title,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardFeatureCard(
      onTap: onTap,
      background: DashboardPalette.cardPurple(context),
      title: context.l10n.dashboardNowPlayingTitle,
      right: Image.asset(
        'assets/img/headset_icon.png',
        width: 84,
        height: 84,
        fit: BoxFit.contain,
      ),
      child: StreamBuilder<PlayerState>(
        stream: audioPlayer.playerStateStream,
        builder: (context, snap) {
          final state = snap.data;
          final processingState =
              state?.processingState ?? audioPlayer.processingState;
          final playing = (state?.playing ?? audioPlayer.playing) &&
              processingState != ProcessingState.completed;

          return Row(
            children: [
              Icon(
                Icons.graphic_eq_rounded,
                color: DashboardPalette.primaryText(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: DashboardPalette.primaryText(context),
                      ),
                    ),
                    // const SizedBox(height: 10),
                    // CumulativePlaylistProgressBar(
                    //   audioPlayer: audioPlayer,
                    //   minHeight: 4,
                    //   backgroundColor:
                    //       const Color(0xFF111827).withValues(alpha: 0.15),
                    //   valueColor: const Color(0xFF111827),
                    // ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          onPressed: !isLoading && audioPlayer.hasPrevious
                              ? () => audioPlayer.seekToPrevious()
                              : null,
                          icon: SvgPicture.asset(
                            'assets/icons/previous.svg',
                            width: 22,
                            height: 22,
                            colorFilter: ColorFilter.mode(
                              DashboardPalette.primaryText(context),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  if (playing) {
                                    await audioPlayer.pause();
                                  } else {
                                    if (processingState ==
                                        ProcessingState.completed) {
                                      await audioPlayer.seek(Duration.zero,
                                          index: 0);
                                    }
                                    await audioPlayer.play();
                                  }
                                },
                          icon: isLoading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      DashboardPalette.primaryText(context),
                                    ),
                                  ),
                                )
                              : Icon(
                                  playing
                                      ? Icons.pause_circle_filled_rounded
                                      : Icons.play_circle_filled_rounded,
                                  size: 36,
                                ),
                        ),
                        IconButton(
                          onPressed: !isLoading && audioPlayer.hasNext
                              ? () => audioPlayer.seekToNext()
                              : null,
                          icon: SvgPicture.asset(
                            'assets/icons/next.svg',
                            width: 22,
                            height: 22,
                            colorFilter: ColorFilter.mode(
                              DashboardPalette.primaryText(context),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
