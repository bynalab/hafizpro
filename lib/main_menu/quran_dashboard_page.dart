import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';

import 'package:hafiz_test/data/juz_list.dart';
import 'package:hafiz_test/data/surah_list.dart';
import 'package:hafiz_test/locator.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/model/ayah.model.dart';
import 'package:hafiz_test/quran/quran_view.dart';
import 'package:hafiz_test/services/audio_services.dart';
import 'package:hafiz_test/services/analytics_service.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:hafiz_test/surah/test_by_surah.dart';
import 'package:hafiz_test/surah/surah_list_screen.dart';
import 'package:hafiz_test/enum/surah_select_action.dart';
import 'package:hafiz_test/juz/juz_list_screen.dart';
import 'package:hafiz_test/util/app_colors.dart';

import 'package:hafiz_test/main_menu/widgets.dart';

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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    const pillOuterBottomPadding = 18.0;
    const pillHeight = 44.0;
    const pillVerticalPadding = 8.0;
    const bottomNavReserved =
        pillOuterBottomPadding + pillHeight + (pillVerticalPadding * 2);

    final displaySurahs = _isSearching ? searchSurah(widget.query) : surahList;
    final displayJuz = _isSearching ? searchJuz(widget.query) : juzList;

    final lastRead = getIt<IStorageService>().getLastRead();

    final audioServices = getIt<AudioServices>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: CustomScrollView(
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
                      background: const Color(0xFFF2F2F2),
                      icon: Icon(
                        Theme.of(context).brightness == Brightness.dark
                            ? Icons.light_mode
                            : Icons.dark_mode,
                        color: const Color(0xFF111827),
                      ),
                      onTap: widget.onToggleTheme,
                    ),
                    const SizedBox(width: 10),
                    CircleIconButton(
                      background: const Color(0xFFF2F2F2),
                      icon: const Icon(
                        Icons.settings,
                        color: Color(0xFF111827),
                      ),
                      onTap: widget.onOpenSettings,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SearchField(
                  controller: widget.searchController,
                  hintText: widget.segmentIndex == 0
                      ? 'Search by Surah'
                      : 'Search by Juz',
                ),
                const SizedBox(height: 14),
                if (!_isSearching) ...[
                  if (lastRead == null)
                    DashboardFeatureCard(
                      background: const Color(0xFFBFE7EA),
                      title: 'Challenge yourself',
                      onTap: () {
                        AnalyticsService.trackButtonClick('Challenge Yourself',
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
                            colorFilter: const ColorFilter.mode(
                              Color(0xFF111827),
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Listen to an ayah of\nthe Quran and guess\nthe next one.',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF111827),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward,
                            color: Color(0xFF111827),
                          ),
                        ],
                      ),
                    )
                  else
                    _ContinueLastTestCard(lastRead: lastRead),
                  const SizedBox(height: 14),
                  _NowPlayingCard(audioPlayer: audioServices.audioPlayer),
                  const SizedBox(height: 14),
                  _ContinueReadingCard(lastRead: lastRead),
                  const SizedBox(height: 16),
                  Text(
                    'Listen/Read',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
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
                  color: Colors.white,
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SegmentedSwitch(
                    leftLabel: 'Surah',
                    rightLabel: 'Juz',
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
                        surah.englishName, surah.number);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => QuranView(surah: surah)),
                    );
                  },
                  onPlay: () {},
                );
              },
            )
          else
            SliverList.separated(
              itemCount: displayJuz.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final juzNumber = i + 1;
                final name = displayJuz[i];

                return JuzCard(
                  juzNumber: juzNumber,
                  name: name,
                  onTap: () {
                    AnalyticsService.trackJuzSelected(juzNumber);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const JuzListScreen()),
                    );
                  },
                );
              },
            ),
          SliverToBoxAdapter(
            child: SizedBox(height: bottomNavReserved + bottomInset + 12),
          ),
        ],
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
      background: const Color(0xFFBFE7EA),
      title: 'Continue your last test',
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
            colorFilter: const ColorFilter.mode(
              Color(0xFF111827),
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
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Verse ${ayah.numberInSurah}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward, color: Color(0xFF111827)),
        ],
      ),
    );
  }
}

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard({required this.lastRead});

  final (Surah, Ayah)? lastRead;

  @override
  Widget build(BuildContext context) {
    return DashboardFeatureCard(
      background: const Color(0xFFF7CFC7),
      title: 'Continue Reading',
      onTap: () {
        if (lastRead == null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SurahListScreen(
                actionType: SurahSelectionAction.read,
              ),
            ),
          );
          return;
        }

        final surah = lastRead!.$1;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => QuranView(surah: surah)),
        );
      },
      right: Image.asset(
        'assets/img/open_book_glass_icon.png',
        width: 84,
        height: 84,
        fit: BoxFit.contain,
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.book, color: Color(0xFF111827)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (lastRead == null) ...[
                  Text(
                    'Pick a Surah',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Start reading where you want',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ] else ...[
                  Text(
                    lastRead!.$1.englishName,
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Verse ${lastRead!.$2.numberInSurah}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward, color: Color(0xFF111827)),
        ],
      ),
    );
  }
}

class _NowPlayingCard extends StatelessWidget {
  const _NowPlayingCard({required this.audioPlayer});

  final AudioPlayer audioPlayer;

  @override
  Widget build(BuildContext context) {
    return DashboardFeatureCard(
      background: const Color(0xFFE6BDEB),
      title: 'Now Playing',
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
          final playing = state?.playing ?? audioPlayer.playing;

          return Row(
            children: [
              const Icon(CupertinoIcons.waveform, color: Color(0xFF111827)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recitation',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        IconButton(
                          onPressed: audioPlayer.hasPrevious
                              ? () => audioPlayer.seekToPrevious()
                              : null,
                          icon: const Icon(CupertinoIcons.backward_fill),
                        ),
                        IconButton(
                          onPressed: () async {
                            if (playing) {
                              await audioPlayer.pause();
                            } else {
                              await audioPlayer.play();
                            }
                          },
                          icon: Icon(
                            playing
                                ? CupertinoIcons.pause_circle_fill
                                : CupertinoIcons.play_circle_fill,
                            size: 36,
                          ),
                        ),
                        IconButton(
                          onPressed: audioPlayer.hasNext
                              ? () => audioPlayer.seekToNext()
                              : null,
                          icon: const Icon(CupertinoIcons.forward_fill),
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
