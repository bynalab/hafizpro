import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/data/surah_list.dart';
import 'package:hafiz_test/extension/quran_extension.dart';
import 'package:hafiz_test/locator.dart';
import 'package:hafiz_test/model/ayah.model.dart';
import 'package:hafiz_test/model/juz.model.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/quran/widgets/ayah_card.dart';
import 'package:hafiz_test/quran/widgets/error.dart';
import 'package:hafiz_test/quran/surah_loader.dart';
import 'package:hafiz_test/services/audio_center.dart';
import 'package:hafiz_test/services/surah.services.dart';
import 'package:hafiz_test/util/bismillah.dart';

class JuzQuranView extends StatefulWidget {
  final JuzModel juz;

  const JuzQuranView({super.key, required this.juz});

  @override
  State<JuzQuranView> createState() => _JuzQuranViewState();
}

class _JuzQuranViewState extends State<JuzQuranView> {
  final _surahServices = getIt<SurahServices>();
  final _audioCenter = getIt<AudioCenter>();

  final _scrollController = ScrollController();
  final _scrollViewKey = GlobalKey();

  bool _isLoading = true;
  bool _hasError = false;
  String _error = '';

  final _playingIndexNotifier = ValueNotifier<int?>(null);

  List<_JuzSection> _sections = const [];
  List<GlobalKey> _sectionMarkerKeys = const [];
  String _currentStickySurahTitle = '';

  String _pad2(int n) => n.toString().padLeft(2, '0');

  String _surahName(int surahNumber) {
    final idx = surahNumber - 1;
    if (idx < 0 || idx >= surahList.length) return 'Surah';
    return surahList[idx].englishName;
  }

  String get _rangeText {
    final j = widget.juz;
    return '${_surahName(j.startSurah)}(${_pad2(j.startAyah)}) : ${_surahName(j.endSurah)}(${_pad2(j.endAyah)})';
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _error = '';
    });

    try {
      final sections = <_JuzSection>[];
      var globalAyahIndex = 0;

      for (final range in widget.juz.surahRanges()) {
        final full = await _surahServices.getSurah(range.surahNumber);
        if (full.ayahs.isEmpty) continue;

        final endAyah = range.endAyah ?? full.numberOfAyahs;
        final startIndex = range.startAyah - 1;
        final endIndexInclusive = endAyah - 1;

        if (startIndex < 0 || endIndexInclusive < 0) continue;

        final clampedStart = startIndex.clamp(0, full.ayahs.length - 1);
        final clampedEnd = endIndexInclusive.clamp(0, full.ayahs.length - 1);
        if (clampedEnd < clampedStart) continue;

        final showBismillah =
            range.startAyah == 1 && Bismillah.shouldShow(range.surahNumber);

        final ayahs = full.ayahs.sublist(clampedStart, clampedEnd + 1);
        sections.add(
          _JuzSection(
            surah: full,
            ayahs: ayahs,
            showBismillah: showBismillah,
            startGlobalAyahIndex: globalAyahIndex,
          ),
        );

        globalAyahIndex += ayahs.length;
      }

      setState(() {
        _sections = sections;
        _sectionMarkerKeys = List.generate(sections.length, (_) => GlobalKey());
        _currentStickySurahTitle =
            sections.isEmpty ? '' : sections.first.surah.englishName;
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _updateStickyHeader();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _error = e.toString();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _playingIndexNotifier.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateStickyHeader() {
    if (_sections.isEmpty) return;

    final scrollBox = _scrollViewKey.currentContext?.findRenderObject();
    if (scrollBox is! RenderBox) return;
    final scrollTopY = scrollBox.localToGlobal(Offset.zero).dy;
    final thresholdY = scrollTopY + 1;

    int currentIndex = 0;

    for (int i = 0; i < _sectionMarkerKeys.length; i++) {
      final key = _sectionMarkerKeys[i];
      final box = key.currentContext?.findRenderObject();
      if (box is! RenderBox) continue;

      final y = box.localToGlobal(Offset.zero).dy;
      if (y <= thresholdY) {
        currentIndex = i;
      } else {
        break;
      }
    }

    final nextTitle = _sections[currentIndex].surah.englishName;
    if (nextTitle == _currentStickySurahTitle) return;
    setState(() => _currentStickySurahTitle = nextTitle);
  }

  List<Widget> _buildSectionSlivers(int index) {
    final section = _sections[index];

    return [
      SliverToBoxAdapter(
        child: _SurahMarker(
          key: _sectionMarkerKeys[index],
          title: section.surah.englishName,
        ),
      ),
      if (section.showBismillah)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
            child: Text(
              Bismillah.glyph,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.amiri(
                fontSize: 24,
                height: 2,
                color: const Color(0xFF111827),
              ),
            ),
          ),
        ),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, localIndex) {
            final globalIndex = section.startGlobalAyahIndex + localIndex;
            final ayah = section.ayahs[localIndex];
            final isEven = globalIndex % 2 == 0;

            final displayText = (section.showBismillah && localIndex == 0)
                ? Bismillah.trimLeadingForDisplay(ayah.text)
                : ayah.text;

            return AyahCard(
              index: globalIndex,
              ayah: Ayah(
                number: ayah.number,
                audio: ayah.audio,
                audioSecondary: ayah.audioSecondary,
                text: displayText,
                translation: ayah.translation,
                numberInSurah: ayah.numberInSurah,
                juz: ayah.juz,
                manzil: ayah.manzil,
                page: ayah.page,
                ruku: ayah.ruku,
                hizbQuarter: ayah.hizbQuarter,
                surah: ayah.surah,
              ),
              playingIndexNotifier: _playingIndexNotifier,
              backgroundColor:
                  isEven ? const Color(0xFFF3F4F6) : const Color(0xFFF9FAFB),
              onPlayPressed: _onPlayPressed,
            );
          },
          childCount: section.ayahs.length,
        ),
      ),
    ];
  }

  Future<void> _onPlayPressed(int globalIndex) async {
    if (globalIndex < 0) return;

    final current = _playingIndexNotifier.value;
    final audioPlayer = _audioCenter.audioPlayer;

    if (current == globalIndex && audioPlayer.playing) {
      await audioPlayer.stop();
      _playingIndexNotifier.value = null;
      return;
    }

    _playingIndexNotifier.value = globalIndex;

    for (final section in _sections) {
      final start = section.startGlobalAyahIndex;
      final end = start + section.ayahs.length - 1;
      if (globalIndex >= start && globalIndex <= end) {
        final localIndex = globalIndex - start;
        final ayah = section.ayahs[localIndex];
        await _audioCenter.playSingleAyah(section.surah, ayah.audioSource);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: SurahLoader());
    }

    if (_hasError) {
      return Scaffold(
        body: CustomErrorWidget(
          title: 'Failed to Load Juz',
          message:
              'Please check your internet connection or try again shortly. $_error',
          icon: Icons.menu_book_rounded,
          color: Colors.green,
          onRetry: _load,
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF78B7C6),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 120,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
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
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Juz ${widget.juz.number}',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _rangeText,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.juz.ayahCount} verses',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollUpdateNotification ||
                    notification is UserScrollNotification) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    _updateStickyHeader();
                  });
                }
                return false;
              },
              child: CustomScrollView(
                key: _scrollViewKey,
                controller: _scrollController,
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 10)),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickySurahHeaderDelegate(
                      title: _currentStickySurahTitle,
                    ),
                  ),
                  for (int i = 0; i < _sections.length; i++)
                    ..._buildSectionSlivers(i),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JuzSection {
  final Surah surah;
  final List<Ayah> ayahs;
  final bool showBismillah;
  final int startGlobalAyahIndex;

  const _JuzSection({
    required this.surah,
    required this.ayahs,
    required this.showBismillah,
    required this.startGlobalAyahIndex,
  });
}

class _StickySurahHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;

  _StickySurahHeaderDelegate({required this.title});

  @override
  double get minExtent => 44;

  @override
  double get maxExtent => 44;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFFF9FAFB),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Text(
            title,
            key: ValueKey(title),
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickySurahHeaderDelegate oldDelegate) {
    return oldDelegate.title != title;
  }
}

class _SurahMarker extends StatelessWidget {
  final String title;

  const _SurahMarker({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
