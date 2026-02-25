import 'package:adhkar/adhkar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/services/tts_service.dart';

class AdhkarDetailPage extends StatefulWidget {
  final String title;
  final AdhkarData item;
  final int count;
  final int total;

  const AdhkarDetailPage({
    super.key,
    required this.title,
    required this.item,
    required this.count,
    required this.total,
  });

  @override
  State<AdhkarDetailPage> createState() => _AdhkarDetailPageState();
}

class _AdhkarDetailPageState extends State<AdhkarDetailPage> {
  final _ttsService = TtsService();
  bool _isSpeakingTranslation = false;
  // bool _isSpeakingArabic = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _ttsService.init();
    _ttsService.setHandler(
      onStart: () {}, // No global state change here, handled in toggle methods
      onCompletion: () => setState(() {
        _isSpeakingTranslation = false;
        // _isSpeakingArabic = false;
      }),
      onPause: () => setState(() {
        _isSpeakingTranslation = false;
        // _isSpeakingArabic = false;
      }),
    );
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  void _toggleTranslationTts() {
    if (_isSpeakingTranslation) {
      _ttsService.stop();
      setState(() => _isSpeakingTranslation = false);
    } else {
      _ttsService.stop(); // Stop any other playing
      setState(() {
        _isSpeakingTranslation = true;
        // _isSpeakingArabic = false;
      });
      _ttsService.speak(widget.item.translationText, language: "en-US");
    }
  }

/*
  void _toggleArabicTts() {
    if (_isSpeakingArabic) {
      _ttsService.stop();
      setState(() => _isSpeakingArabic = false);
    } else {
      _ttsService.stop(); // Stop any other playing
      setState(() {
        _isSpeakingArabic = true;
        _isSpeakingTranslation = false;
      });
      _ttsService.speak(widget.item.arabicText, language: "ar", rate: 0.3);
    }
  }
*/

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B0B0B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final secondaryText =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              widget.title,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textColor,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),

            // Counter Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white : const Color(0xFF111827),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${widget.count}/${widget.total}',
                style: GoogleFonts.inter(
                  color: isDark ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Arabic Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF0F0F0F) : const Color(0xFF111827),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      /*
                      GestureDetector(
                        onTap: _toggleArabicTts,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Icon(
                            _isSpeakingArabic
                                ? Icons.stop_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      */
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2FA2B1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Read',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      widget.item.arabicText,
                      style: const TextStyle(
                        fontFamily: 'Kitab',
                        fontSize: 24,
                        color: Colors.white,
                        height: 1.8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Transliteration / Phonetic
            if (widget.item.transliterationText.isNotEmpty) ...[
              Text(
                widget.item.transliterationText,
                style: GoogleFonts.inter(
                  color: secondaryText,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Translation Header & Play Button
            Row(
              children: [
                Text(
                  'Translation',
                  style: GoogleFonts.outfit(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _toggleTranslationTts,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _isSpeakingTranslation
                          ? const Color(0xFF2FA2B1).withValues(alpha: 0.2)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isSpeakingTranslation
                          ? Icons.stop_circle_outlined
                          : Icons.volume_up_outlined,
                      size: 20,
                      color: _isSpeakingTranslation
                          ? const Color(0xFF2FA2B1)
                          : secondaryText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.item.translationText,
              style: GoogleFonts.inter(
                color: secondaryText,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Help? Reference?
            if (widget.item.urlReference.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Reference',
                style: GoogleFonts.outfit(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                widget.item.urlReference,
                style: GoogleFonts.inter(
                  color: secondaryText,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
