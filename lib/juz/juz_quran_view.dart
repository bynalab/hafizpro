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
import 'package:hafiz_test/util/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:just_audio/just_audio.dart';
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

    final entryIndex = _globalAyahIndexToEntryIndex[globalIndex];
    if (entryIndex < 0 || entryIndex >= _entries.length) return;
    final entry = _entries[entryIndex];
    final surah = entry.surah;
    final ayah = entry.ayah;
    if (surah == null || ayah == null) return;
    await _audioCenter.playSingleAyah(surah, ayah.audioSource);
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
                              color: const Color(0xFF111827),
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
                          backgroundColor: isEven
                              ? const Color(0xFFF3F4F6)
                              : const Color(0xFFF9FAFB),
                          onPlayPressed: _onPlayPressed,
                        );
                    }
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 2),
                ),
                _PinnedHeader(title: _currentStickySurahTitle),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                    color: const Color(0xFF78B7C6),
                    child: SafeArea(
                      top: false,
                      child: ValueListenableBuilder<int?>(
                        valueListenable: _playingIndexNotifier,
                        builder: (context, index, _) {
                          final matches =
                              _audioCenter.isCurrentJuz(widget.juz.number);
                          final title = _titleForGlobalIndex(index);

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.cairo(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.black500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              StreamBuilder<Duration>(
                                stream: matches
                                    ? _audioCenter.audioPlayer.positionStream
                                    : const Stream<Duration>.empty(),
                                builder: (context, snap) {
                                  final pos = matches
                                      ? (snap.data ?? Duration.zero)
                                      : Duration.zero;
                                  final total = matches
                                      ? (_audioCenter.audioPlayer.duration ??
                                          Duration.zero)
                                      : Duration.zero;
                                  final totalMs = total.inMilliseconds;
                                  final value = totalMs == 0
                                      ? 0.0
                                      : (pos.inMilliseconds / totalMs)
                                          .clamp(0.0, 1.0);

                                  String fmt(Duration d) {
                                    final m = d.inMinutes
                                        .remainder(60)
                                        .toString()
                                        .padLeft(2, '0');
                                    final s = d.inSeconds
                                        .remainder(60)
                                        .toString()
                                        .padLeft(2, '0');
                                    return '$m:$s';
                                  }

                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        fmt(pos),
                                        style: GoogleFonts.manrope(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.black500,
                                        ),
                                      ),
                                      const SizedBox(width: 9),
                                      Expanded(
                                        child: SliderTheme(
                                          data:
                                              SliderTheme.of(context).copyWith(
                                            trackHeight: 4,
                                            thumbShape:
                                                const RoundSliderThumbShape(
                                                    enabledThumbRadius: 0),
                                            overlayShape:
                                                SliderComponentShape.noOverlay,
                                            activeTrackColor:
                                                AppColors.green500,
                                            inactiveTrackColor: AppColors
                                                .black500
                                                .withValues(alpha: 0.30),
                                          ),
                                          child: Slider(
                                            value: value,
                                            onChanged: matches
                                                ? (v) async {
                                                    final ms =
                                                        (totalMs * v).round();
                                                    await _audioCenter
                                                        .audioPlayer
                                                        .pause();
                                                    await _audioCenter
                                                        .audioPlayer
                                                        .seek(Duration(
                                                            milliseconds: ms));
                                                  }
                                                : null,
                                            onChangeEnd: matches
                                                ? (v) async {
                                                    final ms =
                                                        (totalMs * v).round();
                                                    await _audioCenter
                                                        .audioPlayer
                                                        .seek(Duration(
                                                            milliseconds: ms));
                                                    await _audioCenter
                                                        .audioPlayer
                                                        .play();
                                                  }
                                                : null,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 9),
                                      Text(
                                        fmt(total),
                                        style: GoogleFonts.manrope(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.black500,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              StreamBuilder<SequenceState?>(
                                stream: _audioCenter
                                    .audioPlayer.sequenceStateStream,
                                builder: (context, _) {
                                  final hasPrevious = matches &&
                                      _audioCenter.audioPlayer.hasPrevious;
                                  final hasNext = matches &&
                                      _audioCenter.audioPlayer.hasNext;

                                  return StreamBuilder<PlayerState>(
                                    stream: _audioCenter
                                        .audioPlayer.playerStateStream,
                                    builder: (context, snap) {
                                      final isActuallyPlaying =
                                          snap.data?.playing ?? false;
                                      final playing =
                                          matches && isActuallyPlaying;

                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          GestureDetector(
                                            onTap: () async {
                                              _speed = _speed == 2.0
                                                  ? 1.0
                                                  : _speed + 0.5;
                                              await _audioCenter.audioPlayer
                                                  .setSpeed(_speed);
                                              setState(() {});
                                            },
                                            child: Text(
                                              '${_speed.toStringAsFixed(1)}x',
                                              style: GoogleFonts.cairo(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.black500,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: hasPrevious
                                                ? _audioCenter
                                                    .audioPlayer.seekToPrevious
                                                : null,
                                            padding: EdgeInsets.zero,
                                            constraints:
                                                const BoxConstraints.tightFor(
                                              width: 40,
                                              height: 40,
                                            ),
                                            icon: SvgPicture.asset(
                                              'assets/icons/previous.svg',
                                              width: 30,
                                              height: 30,
                                              colorFilter:
                                                  const ColorFilter.mode(
                                                Color(0xFF111827),
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFF111827),
                                            ),
                                            child: IconButton(
                                              onPressed: () async {
                                                await _audioCenter
                                                    .toggleJuz(widget.juz);
                                              },
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints.expand(),
                                              icon: Icon(
                                                playing
                                                    ? Icons.pause
                                                    : Icons.play_arrow,
                                                size: 28,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: hasNext
                                                ? _audioCenter
                                                    .audioPlayer.seekToNext
                                                : null,
                                            padding: EdgeInsets.zero,
                                            constraints:
                                                const BoxConstraints.tightFor(
                                              width: 40,
                                              height: 40,
                                            ),
                                            icon: SvgPicture.asset(
                                              'assets/icons/next.svg',
                                              width: 30,
                                              height: 30,
                                              colorFilter:
                                                  const ColorFilter.mode(
                                                Color(0xFF111827),
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                          ),
                                          StreamBuilder<LoopMode>(
                                            stream: _audioCenter
                                                .audioPlayer.loopModeStream,
                                            builder: (context, snap) {
                                              final loopMode =
                                                  snap.data ?? LoopMode.off;

                                              return IconButton(
                                                onPressed: () async {
                                                  final next =
                                                      loopMode == LoopMode.one
                                                          ? LoopMode.off
                                                          : LoopMode.one;
                                                  await _audioCenter.audioPlayer
                                                      .setLoopMode(next);
                                                },
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints
                                                        .tightFor(
                                                  width: 40,
                                                  height: 40,
                                                ),
                                                icon: Icon(
                                                  Icons.repeat_rounded,
                                                  size: 24,
                                                  color:
                                                      loopMode == LoopMode.one
                                                          ? AppColors.black
                                                          : AppColors.black600,
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),
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
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 44,
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
      ),
    );
  }
}

class _SurahMarker extends StatelessWidget {
  final String title;

  const _SurahMarker({required this.title});

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
