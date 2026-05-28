import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/data/surah_list.dart';
import 'package:hafiz_test/locator.dart';
import 'package:hafiz_test/main_menu/widgets.dart';
import 'package:hafiz_test/quran/quran_view.dart';
import 'package:hafiz_test/services/quran_search_service.dart';
import 'package:hafiz_test/services/recitation_verification_service.dart';
import 'package:hafiz_test/util/app_colors.dart';
import 'package:hafiz_test/util/arabic_text_normalizer.dart';
import 'package:hafiz_test/util/l10n_extensions.dart';

class AyahFinderPage extends StatefulWidget {
  const AyahFinderPage({super.key});

  @override
  State<AyahFinderPage> createState() => _AyahFinderPageState();
}

class _AyahFinderPageState extends State<AyahFinderPage>
    with SingleTickerProviderStateMixin {
  final _searchService = getIt<QuranSearchService>();
  final _sttService = getIt<RecitationVerificationService>();

  bool _isListening = false;
  String _recognizedText = '';
  List<QuranSearchResult> _results = [];
  late AnimationController _rippleController;

  static const Color _accentLight = Color(0xFF0F766E);
  static const Color _accentRing = Color(0xFF78B7C6);
  static const Color _listenRed = Color(0xFFDC2626);

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  void _toggleListening() async {
    if (_isListening) {
      await _sttService.stopListening();
      _rippleController.stop();
      _rippleController.reset();
      if (mounted) {
        setState(() => _isListening = false);
      }
    } else {
      setState(() {
        _isListening = true;
        _recognizedText = '';
        _results = [];
      });
      _rippleController.repeat();

      await _sttService.startListening((text) {
        if (!mounted) return;
        setState(() {
          _recognizedText = text;
          _results = _searchService.search(text);
        });
      });
    }
  }

  void _openMatchInReader(QuranSearchResult res) {
    if (!mounted) return;
    if (res.surahNumber < 1 || res.surahNumber > 114 || res.ayahNumber < 1) {
      return;
    }

    final surah = findSurahByNumber(res.surahNumber);
    if (surah.number != res.surahNumber) return;

    final ayah = res.ayahNumber.clamp(1, surah.numberOfAyahs);

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuranView(
          surah: surah,
          initialAyahNumber: ayah,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B0B0B) : const Color(0xFFF4FBFA);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: bg,
        foregroundColor: DashboardPalette.primaryText(context),
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.ayahFinderTitle,
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: DashboardPalette.primaryText(context),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              context.l10n.experimental,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: DashboardPalette.secondaryText(context),
              ),
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: _AyahFinderHero(
                isListening: _isListening,
                ripple: _rippleController,
                accentIdle: _accentLight,
                accentRing: _accentRing,
                listenRed: _listenRed,
                isDark: isDark,
                onTap: _toggleListening,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isListening
                            ? Icons.graphic_eq_rounded
                            : Icons.touch_app_rounded,
                        size: 18,
                        color: _isListening
                            ? _listenRed
                            : DashboardPalette.secondaryText(context),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _isListening
                              ? context.l10n.ayahFinderListeningStatus
                              : context.l10n.ayahFinderTapToIdentify,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                            color: DashboardPalette.primaryText(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_recognizedText.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _TranscriptChip(
                      text: _recognizedText,
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_results.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: DashboardPalette.listTileBorder(context),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${_results.length}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: DashboardPalette.secondaryText(context),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: DashboardPalette.listTileBorder(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_results.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _FinderEmptyState(
                message: _recognizedText.isEmpty
                    ? context.l10n.ayahFinderMatchesPlaceholder
                    : context.l10n.ayahFinderNoMatchesYet,
                isDark: isDark,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final res = _results[index];
                    final surah = findSurahByNumber(res.surahNumber);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _MatchResultCard(
                        result: res,
                        surahName: surah.englishName,
                        query: _recognizedText,
                        isDark: isDark,
                        onOpenInReader: () => _openMatchInReader(res),
                        openLabel: context.l10n.ayahFinderOpenInReader,
                        scoreLabel: context.l10n.ayahFinderMatchScoreLabel(
                          (res.score * 100).toInt(),
                        ),
                      ),
                    );
                  },
                  childCount: _results.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AyahFinderHero extends StatelessWidget {
  const _AyahFinderHero({
    required this.isListening,
    required this.ripple,
    required this.accentIdle,
    required this.accentRing,
    required this.listenRed,
    required this.isDark,
    required this.onTap,
  });

  final bool isListening;
  final AnimationController ripple;
  final Color accentIdle;
  final Color accentRing;
  final Color listenRed;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isListening ? context.l10n.ayahFinderStopListening : context.l10n.ayahFinderStartListening,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF141818),
                        const Color(0xFF0D1212),
                      ]
                    : [
                        Colors.white,
                        const Color(0xFFE8F7F5),
                      ],
              ),
              border: Border.all(
                color: isListening
                    ? listenRed.withValues(alpha: 0.35)
                    : accentRing.withValues(alpha: isDark ? 0.25 : 0.45),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isListening ? listenRed : accentIdle)
                      .withValues(alpha: isDark ? 0.2 : 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Column(
              children: [
                SizedBox(
                  height: 132,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isListening)
                        ...List.generate(3, (index) {
                          return AnimatedBuilder(
                            animation: ripple,
                            builder: (context, child) {
                              final t = (ripple.value + index / 3) % 1.0;
                              return Container(
                                width: 72 + t * 100,
                                height: 72 + t * 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: listenRed.withValues(
                                      alpha: (1 - t) * 0.45,
                                    ),
                                    width: 1.5,
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isListening
                                ? [listenRed, const Color(0xFFB91C1C)]
                                : [accentIdle, const Color(0xFF115E59)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isListening ? listenRed : accentIdle)
                                  .withValues(alpha: 0.45),
                              blurRadius: 14,
                              spreadRadius: 0,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          isListening ? Icons.stop_rounded : Icons.mic_rounded,
                          color: Colors.white,
                          size: 42,
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
    );
  }
}

class _TranscriptChip extends StatelessWidget {
  const _TranscriptChip({
    required this.text,
    required this.isDark,
  });

  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DashboardPalette.listTileBorder(context),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: GoogleFonts.amiri(
          fontSize: 22,
          height: 1.5,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0F766E),
        ),
      ),
    );
  }
}

class _FinderEmptyState extends StatelessWidget {
  const _FinderEmptyState({
    required this.message,
    required this.isDark,
  });

  final String message;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: DashboardPalette.pillBg(context).withValues(alpha: 0.35),
            ),
            child: Icon(
              Icons.search_rounded,
              size: 32,
              color: DashboardPalette.secondaryText(context),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: DashboardPalette.secondaryText(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchResultCard extends StatelessWidget {
  const _MatchResultCard({
    required this.result,
    required this.surahName,
    required this.query,
    required this.isDark,
    required this.onOpenInReader,
    required this.openLabel,
    required this.scoreLabel,
  });

  final QuranSearchResult result;
  final String surahName;
  final String query;
  final bool isDark;
  final VoidCallback onOpenInReader;
  final String openLabel;
  final String scoreLabel;

  @override
  Widget build(BuildContext context) {
    final border = DashboardPalette.listTileBorder(context);
    final bg = DashboardPalette.listTileBg(context);
    final accent = const Color(0xFF0F766E);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            surahName,
                            style: GoogleFonts.cairo(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: DashboardPalette.primaryText(context),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _InfoChip(
                                icon: Icons.numbers_rounded,
                                label:
                                    '${result.surahNumber}:${result.ayahNumber}',
                                emphasized: true,
                                accent: accent,
                              ),
                              _InfoChip(
                                icon: Icons.bubble_chart_outlined,
                                label: scoreLabel,
                                emphasized: false,
                                accent: accent,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0E0E0E)
                      : const Color(0xFFF8FAFC),
                  border: Border(
                    top: BorderSide(color: border.withValues(alpha: 0.7)),
                  ),
                ),
                child: _AyahHighlightedText(
                  original: result.originalText,
                  query: query,
                  isDark: isDark,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
                child: FilledButton.tonalIcon(
                  onPressed: onOpenInReader,
                  icon: const Icon(Icons.menu_book_rounded, size: 18),
                  label: Text(
                    openLabel,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    foregroundColor: AppColors.green500,
                    backgroundColor: isDark
                        ? const Color(0xFF1A2E2E)
                        : AppColors.green50,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.emphasized,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final bool emphasized;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: emphasized
            ? accent.withValues(alpha: 0.12)
            : DashboardPalette.pillBg(context).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: emphasized
              ? accent.withValues(alpha: 0.25)
              : DashboardPalette.listTileBorder(context),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: emphasized ? accent : DashboardPalette.secondaryText(context),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: emphasized
                  ? accent
                  : DashboardPalette.secondaryText(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _AyahHighlightedText extends StatelessWidget {
  const _AyahHighlightedText({
    required this.original,
    required this.query,
    required this.isDark,
  });

  final String original;
  final String query;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(
        original,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        style: GoogleFonts.amiri(
          fontSize: 21,
          height: 1.65,
          fontWeight: FontWeight.w700,
          color: DashboardPalette.primaryText(context),
        ),
      );
    }

    final highlightBg = isDark
        ? const Color(0xFF2DD4BF).withValues(alpha: 0.2)
        : const Color(0xFF0D9488).withValues(alpha: 0.12);
    final highlightText =
        isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E);
    final normalText = DashboardPalette.primaryText(context);

    final normalizedQuery = ArabicTextNormalizer.normalize(query);
    final queryWords =
        normalizedQuery.split(' ').where((w) => w.length >= 2).toSet();

    final originalWords = original.split(RegExp(r'\s+'));
    final spans = <TextSpan>[];

    for (var i = 0; i < originalWords.length; i++) {
      final originalWord = originalWords[i];
      if (originalWord.isEmpty) continue;

      final normalizedWord = ArabicTextNormalizer.normalize(originalWord);
      var isMatch = false;
      if (queryWords.isNotEmpty) {
        for (final qw in queryWords) {
          if (normalizedWord == qw || normalizedWord.contains(qw)) {
            isMatch = true;
            break;
          }
        }
      }

      spans.add(
        TextSpan(
          text: originalWord,
          style: TextStyle(
            color: isMatch ? highlightText : normalText,
            backgroundColor: isMatch ? highlightBg : null,
          ),
        ),
      );
      if (i < originalWords.length - 1) {
        spans.add(const TextSpan(text: ' '));
      }
    }

    return RichText(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      text: TextSpan(
        style: GoogleFonts.amiri(
          fontSize: 21,
          height: 1.65,
          fontWeight: FontWeight.w700,
        ),
        children: spans,
      ),
    );
  }
}
