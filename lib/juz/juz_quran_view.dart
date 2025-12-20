import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/data/surah_list.dart';
import 'package:hafiz_test/locator.dart';
import 'package:hafiz_test/model/ayah.model.dart';
import 'package:hafiz_test/model/juz.model.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/quran/surah_loader.dart';
import 'package:hafiz_test/quran/widgets/ayah_card.dart';
import 'package:hafiz_test/quran/widgets/bottom_audio_controls.dart';
import 'package:hafiz_test/quran/widgets/error.dart';
import 'package:hafiz_test/services/audio_center.dart';
import 'package:hafiz_test/services/surah.services.dart';
import 'package:hafiz_test/util/bismillah.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class JuzQuranView extends StatefulWidget {
  final JuzModel juz;

  const JuzQuranView({super.key, required this.juz});

  @override
  State<JuzQuranView> createState() => _JuzQuranViewState();
}

class _JuzQuranViewState extends State<JuzQuranView> {
  final _surahServices = getIt<SurahServices>();
  final _audioCenter = getIt<AudioCenter>();

  bool _isLoading = true;
  bool _hasError = false;
  String _error = '';

  final _playingIndexNotifier = ValueNotifier<int?>(null);

  double _speed = 1.5;

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  List<_JuzEntry> _entries = const [];
  List<int> _globalAyahIndexToEntryIndex = const [];

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
      final entries = <_JuzEntry>[];
      final globalAyahIndexToEntryIndex = <int>[];

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

        entries.add(
          _JuzEntry.header(
            surahTitle: full.englishName,
          ),
        );

        if (showBismillah) {
          entries.add(const _JuzEntry.bismillah());
        }

        final ayahs = full.ayahs.sublist(clampedStart, clampedEnd + 1);
        for (int localIndex = 0; localIndex < ayahs.length; localIndex++) {
          final ayah = ayahs[localIndex];
          final displayText = (showBismillah && localIndex == 0)
              ? Bismillah.trimLeadingForDisplay(ayah.text)
              : ayah.text;

          globalAyahIndexToEntryIndex.add(entries.length);
          entries.add(
            _JuzEntry.ayah(
              globalAyahIndex: globalAyahIndex,
              surah: full,
              ayah: ayah,
              displayText: displayText,
            ),
          );
          globalAyahIndex++;
        }
      }

      setState(() {
        _entries = entries;
        _globalAyahIndexToEntryIndex = globalAyahIndexToEntryIndex;
        _currentStickySurahTitle =
            entries.isEmpty ? '' : _firstHeaderTitle(entries);
        _isLoading = false;
      });

      _itemPositionsListener.itemPositions.addListener(_onPositionsChanged);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Scroll to the currently playing ayah if we're in the right juz.
        if (!mounted) return;
        if (!_audioCenter.isCurrentJuz(widget.juz.number)) return;

        final idx = _audioCenter.juzPlayingIndexNotifier.value ??
            _audioCenter.audioPlayer.currentIndex;
        _setPlayingIndexAndScroll(idx, animated: false);
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

    _audioCenter.juzPlayingIndexNotifier.addListener(_onJuzAudioIndexChanged);
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_onPositionsChanged);
    _audioCenter.juzPlayingIndexNotifier
        .removeListener(_onJuzAudioIndexChanged);
    _playingIndexNotifier.dispose();
    super.dispose();
  }

  void _onJuzAudioIndexChanged() {
    if (!mounted) return;
    if (!_audioCenter.isCurrentJuz(widget.juz.number)) return;

    final idx = _audioCenter.juzPlayingIndexNotifier.value;
    _setPlayingIndexAndScroll(idx, animated: true);
  }

  void _setPlayingIndexAndScroll(int? idx, {required bool animated}) {
    if (idx == null) return;
    if (_globalAyahIndexToEntryIndex.isEmpty) return;
    if (idx < 0 || idx >= _globalAyahIndexToEntryIndex.length) return;

    final entryIndex = _globalAyahIndexToEntryIndex[idx];
    _playingIndexNotifier.value = idx;

    if (!_itemScrollController.isAttached) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!_itemScrollController.isAttached) return;
        _setPlayingIndexAndScroll(idx, animated: animated);
      });
      return;
    }

    if (animated) {
      _itemScrollController.scrollTo(
        index: entryIndex,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        alignment: 0.10,
      );
    } else {
      _itemScrollController.jumpTo(index: entryIndex, alignment: 0.10);
    }
  }

  String _titleForGlobalIndex(int? globalIndex) {
    if (globalIndex == null) return 'Juz ${widget.juz.number}';
    if (globalIndex < 0 || globalIndex >= _globalAyahIndexToEntryIndex.length) {
      return 'Juz ${widget.juz.number}';
    }

    final entryIndex = _globalAyahIndexToEntryIndex[globalIndex];
    if (entryIndex < 0 || entryIndex >= _entries.length) {
      return 'Juz ${widget.juz.number}';
    }

    final entry = _entries[entryIndex];
    final surah = entry.surah;
    final ayah = entry.ayah;
    if (surah == null || ayah == null) return 'Juz ${widget.juz.number}';
    return '${surah.englishName}: ${ayah.numberInSurah}';
  }

  String _firstHeaderTitle(List<_JuzEntry> entries) {
    for (final e in entries) {
      if (e.type == _JuzEntryType.header) return e.surahTitle ?? '';
    }

    return '';
  }

  void _onPositionsChanged() {
    if (!mounted) return;
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    final visible = positions.where((p) => p.itemTrailingEdge > 0).toList()
      ..sort((a, b) => a.itemLeadingEdge.compareTo(b.itemLeadingEdge));

    if (visible.isEmpty) return;
    final firstIndex = visible.first.index;

    String? nextTitle;
    for (int i = firstIndex; i >= 0; i--) {
      if (i >= _entries.length) continue;
      final e = _entries[i];
      if (e.type == _JuzEntryType.header) {
        nextTitle = e.surahTitle;
        break;
      }
    }

    if (nextTitle == null || nextTitle == _currentStickySurahTitle) return;
    setState(() => _currentStickySurahTitle = nextTitle!);
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

    if (globalIndex < 0 || globalIndex >= _globalAyahIndexToEntryIndex.length) {
      return;
    }

    // Start (or seek within) the Juz playlist from the tapped verse so playback
    // continues to the next verses within the Juz.
    await _audioCenter.toggleJuz(widget.juz, startIndex: globalIndex);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      backgroundColor: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : const Color(0xFFF9FAFB),
      body: Column(
        children: [
          Container(
            color: isDark ? const Color(0xFF1D353B) : const Color(0xFF78B7C6),
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
                          decoration: BoxDecoration(
                            color:
                                isDark ? const Color(0xFF1A1A1A) : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF111827),
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
                            color:
                                isDark ? Colors.white : const Color(0xFF111827),
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
                              color: isDark
                                  ? const Color(0xFFE5E7EB)
                                  : const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.juz.ayahCount} verses',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFF111827),
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
            child: Stack(
              children: [
                ScrollablePositionedList.separated(
                  padding: const EdgeInsets.only(top: 54, bottom: 180),
                  itemCount: _entries.length,
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                  itemBuilder: (context, index) {
                    final entry = _entries[index];

                    switch (entry.type) {
                      case _JuzEntryType.header:
                        return _SurahMarker(title: entry.surahTitle ?? '');
                      case _JuzEntryType.bismillah:
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
                          child: Text(
                            Bismillah.glyph,
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.amiri(
                              fontSize: 24,
                              height: 2,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF111827),
                            ),
                          ),
                        );
                      case _JuzEntryType.ayah:
                        final globalIndex = entry.globalAyahIndex ?? 0;
                        final isEven = globalIndex % 2 == 0;
                        final ayah = entry.ayah;

                        if (ayah == null) {
                          return const SizedBox.shrink();
                        }

                        return AyahCard(
                          index: globalIndex,
                          ayah: ayah.copyWith(
                            text: entry.displayText ?? ayah.text,
                          ),
                          playingIndexNotifier: _playingIndexNotifier,
                          backgroundColor: isDark
                              ? (isEven
                                  ? const Color(0xFF101010)
                                  : const Color(0xFF0E0E0E))
                              : (isEven
                                  ? const Color(0xFFFCFCFC)
                                  : const Color(0xFFF2F2F2)),
                          onPlayPressed: _onPlayPressed,
                        );
                    }
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 2),
                ),
                _PinnedHeader(title: _currentStickySurahTitle),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ListenableBuilder(
                    listenable: _audioCenter,
                    builder: (context, _) {
                      return BottomAudioControls(
                        playingIndexListenable: _playingIndexNotifier,
                        titleBuilder: _titleForGlobalIndex,
                        audioCenter: _audioCenter,
                        audioPlayer: _audioCenter.audioPlayer,
                        isContextActive:
                            _audioCenter.isCurrentJuz(widget.juz.number),
                        speed: _speed,
                        onSpeedChanged: (nextSpeed) async {
                          _speed = nextSpeed;
                          await _audioCenter.audioPlayer.setSpeed(_speed);
                          setState(() {});
                        },
                        onTogglePlayPause: () async {
                          await _audioCenter.toggleJuz(widget.juz);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _JuzEntryType { header, bismillah, ayah }

class _JuzEntry {
  final _JuzEntryType type;
  final String? surahTitle;
  final int? globalAyahIndex;
  final Surah? surah;
  final Ayah? ayah;
  final String? displayText;

  const _JuzEntry._({
    required this.type,
    this.surahTitle,
    this.globalAyahIndex,
    this.surah,
    this.ayah,
    this.displayText,
  });

  const _JuzEntry.header({required String surahTitle})
      : this._(type: _JuzEntryType.header, surahTitle: surahTitle);

  const _JuzEntry.bismillah() : this._(type: _JuzEntryType.bismillah);

  const _JuzEntry.ayah({
    required int globalAyahIndex,
    required Surah surah,
    required Ayah ayah,
    required String displayText,
  }) : this._(
          type: _JuzEntryType.ayah,
          globalAyahIndex: globalAyahIndex,
          surah: surah,
          ayah: ayah,
          displayText: displayText,
        );
}

class _PinnedHeader extends StatelessWidget {
  final String title;

  const _PinnedHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 44,
        color: isDark
            ? Theme.of(context).scaffoldBackgroundColor
            : const Color(0xFFF9FAFB),
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
                color:
                    isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SurahMarker extends StatelessWidget {
  final String title;

  const _SurahMarker({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
