import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/locator.dart';
import 'package:hafiz_test/services/quran_search_service.dart';
import 'package:hafiz_test/services/recitation_verification_service.dart';
import 'package:hafiz_test/util/arabic_text_normalizer.dart';
import 'package:hafiz_test/data/surah_list.dart';
import 'package:hafiz_test/util/l10n_extensions.dart';

class ShazamQuranPage extends StatefulWidget {
  const ShazamQuranPage({super.key});

  @override
  State<ShazamQuranPage> createState() => _ShazamQuranPageState();
}

class _ShazamQuranPageState extends State<ShazamQuranPage>
    with SingleTickerProviderStateMixin {
  final _searchService = getIt<QuranSearchService>();
  final _sttService = getIt<RecitationVerificationService>();

  bool _isListening = false;
  String _recognizedText = '';
  List<QuranSearchResult> _results = [];
  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
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
      setState(() {
        _isListening = false;
      });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primary = Color(0xFF004B40);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          context.l10n.quranShazamTitle,
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          // Shazam Ripple Area
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isListening)
                  ...List.generate(3, (index) {
                    return AnimatedBuilder(
                      animation: _rippleController,
                      builder: (context, child) {
                        final progress =
                            (_rippleController.value + index / 3) % 1.0;
                        return Container(
                          width: 120 + (progress * 180),
                          height: 120 + (progress * 180),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: primary.withValues(alpha: 1.0 - progress),
                              width: 2,
                            ),
                          ),
                        );
                      },
                    );
                  }),
                GestureDetector(
                  onTap: _toggleListening,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening ? Colors.red.shade600 : primary,
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening ? Colors.red : primary)
                              .withValues(alpha: 0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Text(
            _isListening
                ? context.l10n.shazamListeningStatus
                : context.l10n.shazamTapToIdentifySurah,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          if (_recognizedText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                _recognizedText,
                textAlign: TextAlign.center,
                style: GoogleFonts.amiri(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primary.withValues(alpha: 0.7),
                ),
              ),
            ),
          const Divider(height: 40, indent: 40, endIndent: 40),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Text(
                      _recognizedText.isEmpty
                          ? context.l10n.shazamMatchesPlaceholder
                          : context.l10n.shazamNoMatchesYet,
                      style: GoogleFonts.montserrat(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final res = _results[index];
                      final surah = findSurahByNumber(res.surahNumber);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "${res.surahNumber}:${res.ayahNumber}",
                                          style: GoogleFonts.montserrat(
                                            color: primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 1,
                                          height: 12,
                                          color: primary.withValues(alpha: 0.3),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          context.l10n.shazamMatchScoreLabel(
                                            (res.score * 100).toInt(),
                                          ),
                                          style: GoogleFonts.montserrat(
                                            color:
                                                primary.withValues(alpha: 0.7),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    surah.englishName,
                                    style: GoogleFonts.montserrat(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildHighlightedVerseText(
                                res.originalText,
                                _recognizedText,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedVerseText(String original, String query) {
    if (query.isEmpty) {
      return Text(
        original,
        textDirection: TextDirection.rtl,
        style: GoogleFonts.amiri(
          fontSize: 22,
          height: 1.6,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highlightBg = isDark
        ? const Color(0xFF2DD4BF).withValues(alpha: 0.25)
        : const Color(0xFF004B40).withValues(alpha: 0.12);
    final highlightText =
        isDark ? const Color(0xFF2DD4BF) : const Color(0xFF004B40);
    final normalText = isDark ? Colors.white : Colors.black87;

    final normalizedQuery = ArabicTextNormalizer.normalize(query);
    // Split into words, remove very short ones but keep 2-char words as they are common in Arabic
    final queryWords =
        normalizedQuery.split(' ').where((w) => w.length >= 2).toSet();

    final originalWords = original.split(RegExp(r'\s+'));
    final List<TextSpan> spans = [];

    for (int i = 0; i < originalWords.length; i++) {
      final originalWord = originalWords[i];
      if (originalWord.isEmpty) continue;

      final normalizedWord = ArabicTextNormalizer.normalize(originalWord);

      bool isMatch = false;
      if (queryWords.isNotEmpty) {
        for (final qw in queryWords) {
          // Check for exact match or contains
          if (normalizedWord == qw || normalizedWord.contains(qw)) {
            isMatch = true;
            break;
          }
        }
      }

      spans.add(TextSpan(
        text: originalWord,
        style: TextStyle(
          color: isMatch ? highlightText : normalText,
          backgroundColor: isMatch ? highlightBg : null,
        ),
      ));

      if (i < originalWords.length - 1) {
        spans.add(const TextSpan(text: ' '));
      }
    }

    return RichText(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      text: TextSpan(
        style: GoogleFonts.amiri(
          fontSize: 22,
          height: 1.6,
          fontWeight: FontWeight.bold,
        ),
        children: spans,
      ),
    );
  }
}
