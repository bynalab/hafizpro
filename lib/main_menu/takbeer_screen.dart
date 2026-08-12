import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/locator.dart';
import 'package:hafiz_test/services/audio_center.dart';
import 'package:hafiz_test/services/audio_services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:hafiz_test/util/app_messenger.dart';
import 'package:hafiz_test/util/l10n_extensions.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const kTakbeerAudioUrl =
    'https://endless-devotion-player.lovable.app/audio/takbeer.m4a';

const _kArabic =
    'اللهُ أَكْبَرُ، اللهُ أَكْبَرُ،\nلَا إِلَهَ إِلَّا اللهُ،\nوَاللهُ أَكْبَرُ، اللهُ أَكْبَرُ،\nوَلِلَّهِ الْحَمْدُ';

const _kTranslit =
    'Allahu Akbar, Allahu Akbar,\nLa Ilaha Illallah,\nWallahu Akbar, Allahu Akbar,\nWa Lillahil Hamd.';

// Palette
const _kBg = Color(0xFF080C14);
const _kGold = Color(0xFFC9A84C);
const _kGoldLight = Color(0xFFE8C97A);
const _kCream = Color(0xFFF5EDD6);
const _kSubtle = Color(0xFF9CA3AF);
const _kDimText = Color(0xFF6B7280);

// ─────────────────────────────────────────────────────────────────────────────
// TakbeerAudioService  — singleton so card + screen share the same player
// ─────────────────────────────────────────────────────────────────────────────

class TakbeerAudioService extends ChangeNotifier {
  TakbeerAudioService._() {
    final p = AudioServices().audioPlayer;
    _stateSub = p.playerStateStream.listen((_) => _updateState());
    _sequenceSub = p.sequenceStateStream.listen((_) => _updateState());
  }

  static final TakbeerAudioService instance = TakbeerAudioService._();

  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<SequenceState?>? _sequenceSub;
  bool isLoading = false;
  bool isPlaying = false;

  AudioPlayer get player => AudioServices().audioPlayer;

  bool get isTakbeerActive {
    final seq = player.sequenceState;
    final current = seq.currentSource;
    if (current == null) return false;
    final tag = current.tag;
    return tag is MediaItem && tag.id == 'takbeer';
  }

  void _updateState() {
    final state = player.playerState;
    final active = isTakbeerActive;

    final buffering = active &&
        (state.processingState == ProcessingState.buffering ||
            state.processingState == ProcessingState.loading);
    final playing = active &&
        state.playing &&
        state.processingState != ProcessingState.completed;

    if (isLoading != buffering || isPlaying != playing) {
      isLoading = buffering;
      isPlaying = playing;
      notifyListeners();
    }
  }

  Future<void> pause() async {
    if (isTakbeerActive) {
      await AudioServices().stop(trackEvent: false);
    }
  }

  Future<void> toggle() async {
    if (isLoading) return;

    if (isTakbeerActive && player.playing) {
      await pause();
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      // Deactivate normal Quran recitation states in AudioCenter and save state for resumption
      final audioCenter = getIt<AudioCenter>();
      audioCenter.saveStateForTakbeer();

      const tag = MediaItem(
        id: 'takbeer',
        title: 'Takbeer — Allahu Akbar',
        artist: 'Hafiz Pro',
      );
      final AudioSource src = kIsWeb
          ? AudioSource.uri(Uri.parse(kTakbeerAudioUrl), tag: tag)
          : LockCachingAudioSource(Uri.parse(kTakbeerAudioUrl), tag: tag);

      await player.stop();
      await player.setLoopMode(LoopMode.one);
      await player.setAudioSource(src);
      await player.play();
    } catch (e) {
      debugPrint('[TakbeerAudioService] $e');
      AppMessenger.showSnackBar('Error launching Takbeer: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _sequenceSub?.cancel();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class TakbeerScreen extends StatefulWidget {
  const TakbeerScreen({super.key});

  @override
  State<TakbeerScreen> createState() => _TakbeerScreenState();
}

class _TakbeerScreenState extends State<TakbeerScreen>
    with TickerProviderStateMixin {
  final TakbeerAudioService _svc = TakbeerAudioService.instance;

  // ── Animation controllers ─────────────────────────────────────────────────
  late final AnimationController _bgSpinCtrl;
  late final AnimationController _fadeCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _rippleCtrl;

  late final Animation<double> _fadeAnim;
  late final Animation<double> _floatAnim;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _svc.addListener(_onService);

    // Background star rotates one full turn every 90 seconds.
    _bgSpinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 90),
    )..repeat();

    // Fade-in on screen open.
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    // Gentle float: Arabic text drifts ±7 px every 3.2 s.
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -7, end: 7).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    // Play-button pulse.
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.14).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Ripple rings.
    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // Sync animations to current play state (e.g. if audio was already running).
    _syncAnimations();
  }

  void _onService() {
    if (!mounted) return;
    setState(() {});
    _syncAnimations();
  }

  void _syncAnimations() {
    if (_svc.isPlaying) {
      if (!_pulseCtrl.isAnimating) _pulseCtrl.repeat(reverse: true);
      if (!_rippleCtrl.isAnimating) _rippleCtrl.repeat();
    } else {
      _pulseCtrl
        ..stop()
        ..animateTo(0, duration: const Duration(milliseconds: 300));
      _rippleCtrl
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _svc.removeListener(_onService);
    _bgSpinCtrl.dispose();
    _fadeCtrl.dispose();
    _floatCtrl.dispose();
    _pulseCtrl.dispose();
    _rippleCtrl.dispose();
    // NOTE: _svc (and its player) are NOT disposed — it's a singleton that
    // keeps playing while the user navigates back to the dashboard.
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Layer 1 – tiled repeating Islamic star pattern (static)
          const Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _TilePainter()),
            ),
          ),

          // Layer 2 – large rotating central ornament
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _bgSpinCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _OrnamentPainter(
                    angle: _bgSpinCtrl.value * 2 * math.pi,
                  ),
                ),
              ),
            ),
          ),

          // Layer 3 – content
          Positioned.fill(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SafeArea(child: _buildContent()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildBrandingHeader(),
                  const SizedBox(height: 16),
                  _buildArabicText(),
                  const SizedBox(height: 16),
                  _buildDivider(),
                  const SizedBox(height: 16),
                  _buildTransliteration(),
                ],
              ),
            ),
          ),
        ),
        _buildPlayArea(),
        const SizedBox(height: 16),
        _buildHint(),
        const SizedBox(height: 36),
      ],
    );
  }

  Widget _buildBrandingHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _kGold.withValues(alpha: 0),
                    _kGold.withValues(alpha: 0.35),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Image.asset(
              'assets/img/logo.png',
              height: 44,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.star_rounded,
                color: _kGold,
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _kGold.withValues(alpha: 0.35),
                    _kGold.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sub-widgets ────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _kGold),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            'T A K B E E R   ·   ∞',
            style: GoogleFonts.inter(
              fontSize: 11,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w500,
              color: _kGold,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildArabicText() {
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (_, child) => Transform.translate(
          offset: Offset(0, _floatAnim.value), child: child),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          _kArabic,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.amiri(
            fontSize: 40,
            height: 1.75,
            color: _kCream,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _kGold.withValues(alpha: 0),
                    _kGold.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Text('✦', style: TextStyle(color: _kGold, fontSize: 14)),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _kGold.withValues(alpha: 0.5),
                    _kGold.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransliteration() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Text(
        _kTranslit,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 16,
          height: 1.85,
          color: _kSubtle,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildPlayArea() {
    final isPlaying = _svc.isPlaying;
    final isLoading = _svc.isLoading;

    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ripple rings
          AnimatedBuilder(
            animation: _rippleCtrl,
            builder: (_, __) => CustomPaint(
              size: const Size(180, 180),
              painter: _RipplePainter(
                progress: _rippleCtrl.value,
                color: _kGold,
                active: isPlaying,
              ),
            ),
          ),

          // Glow halo
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _kGold.withValues(alpha: isPlaying ? 0.45 : 0.12),
                  blurRadius: isPlaying ? 36 : 16,
                  spreadRadius: isPlaying ? 6 : 2,
                ),
              ],
            ),
          ),

          // Button
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, child) => Transform.scale(
              scale: isPlaying ? _pulseAnim.value : 1.0,
              child: child,
            ),
            child: GestureDetector(
              onTap: _svc.toggle,
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [_kGoldLight, _kGold],
                    stops: [0.0, 1.0],
                  ),
                ),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(_kBg),
                          ),
                        )
                      : Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: _kBg,
                          size: 60,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHint() {
    final isPlaying = _svc.isPlaying;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Text(
        key: ValueKey(isPlaying),
        isPlaying
            ? context.l10n.takbeerLooping
            : context.l10n.takbeerPlayHint,
        style: GoogleFonts.inter(fontSize: 12, color: _kDimText),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Painters
// ─────────────────────────────────────────────────────────────────────────────

class _TilePainter extends CustomPainter {
  const _TilePainter();

  static const _tile = 64.0;
  static const _r = _tile * 0.28;
  static const _innerR = _r * 0.42;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC9A84C).withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    final cols = (size.width / _tile).ceil() + 1;
    final rows = (size.height / _tile).ceil() + 1;

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        _drawStar(canvas, paint, Offset(col * _tile, row * _tile), _r, _innerR);
      }
    }
  }

  static void _drawStar(
      Canvas canvas, Paint paint, Offset center, double r, double innerR) {
    const points = 8;
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final a = (i * math.pi / points) - math.pi / 2;
      final radius = i.isEven ? r : innerR;
      final x = center.dx + radius * math.cos(a);
      final y = center.dy + radius * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TilePainter _) => false;
}

class _OrnamentPainter extends CustomPainter {
  final double angle;
  const _OrnamentPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide * 0.38;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    for (var i = 1; i <= 5; i++) {
      canvas.drawCircle(
        Offset.zero,
        r * i * 0.2,
        Paint()
          ..color = _kGold.withValues(alpha: 0.04)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7,
      );
    }

    _drawOctagram(canvas, r, fillAlpha: 0.05, strokeAlpha: 0.13);
    canvas.rotate(-angle * 0.5);
    _drawOctagram(canvas, r * 0.62, fillAlpha: 0.04, strokeAlpha: 0.10);

    canvas.restore();
  }

  static void _drawOctagram(Canvas canvas, double r,
      {required double fillAlpha, required double strokeAlpha}) {
    final innerR = r * 0.4;
    const points = 8;
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final a = (i * math.pi / points) - math.pi / 2;
      final radius = i.isEven ? r : innerR;
      final x = radius * math.cos(a);
      final y = radius * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(
        path,
        Paint()
          ..color = _kGold.withValues(alpha: fillAlpha)
          ..style = PaintingStyle.fill);
    canvas.drawPath(
        path,
        Paint()
          ..color = _kGold.withValues(alpha: strokeAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8);
  }

  @override
  bool shouldRepaint(_OrnamentPainter old) => old.angle != angle;
}

class _RipplePainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool active;

  const _RipplePainter(
      {required this.progress, required this.color, required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    if (!active) return;
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;
    for (var i = 0; i < 3; i++) {
      final t = (progress + i / 3.0) % 1.0;
      canvas.drawCircle(
        center,
        maxR * t,
        Paint()
          ..color = color.withValues(alpha: (1.0 - t) * 0.38)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) =>
      old.progress != progress || old.active != active;
}
