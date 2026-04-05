import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:hafiz_test/util/arabic_text_normalizer.dart';
import 'package:path_provider/path_provider.dart';

enum RecitationResultType { correct, almostCorrect, incorrect }

class RecitationResult {
  final String expectedText;
  final String recognizedText;
  final double similarity;
  final RecitationResultType type;

  RecitationResult({
    required this.expectedText,
    required this.recognizedText,
    required this.similarity,
    required this.type,
  });
}

/// Long-ayah friendly STT: OS recognizers often end the session after a short
/// silence ([RecognitionListener.onEndOfSpeech] on Android). We use dictation
/// hints, long [pauseFor]/[listenFor], and auto-resume on [SpeechToText.doneStatus]
/// while the user session is active, merging final segments into one transcript.
class RecitationVerificationService {
  AudioRecorder? __recorder;
  SpeechToText? __speechToText;

  AudioRecorder get _recorder => __recorder ??= AudioRecorder();
  SpeechToText get _speechToText => __speechToText ??= SpeechToText();

  bool _isInitialized = false;

  /// User pressed mic; keep restarting STT until [stopListening].
  bool _continuousSession = false;

  Function(String)? _onResultCallback;
  final List<String> _committedSegments = [];

  /// Serializes auto-resume so two [listen] calls never overlap (avoids mic
  /// glitches / chopped audio when the OS ends a segment and fires [done]).
  Future<void> _resumeChain = Future<void>.value();

  /// Pause after [SpeechToText.doneStatus] before starting the next session so
  /// the native stack can tear down the previous recognizer cleanly.
  static const Duration _resumeSettleDelay = Duration(milliseconds: 420);

  static const Duration _listenFor = Duration(minutes: 5);
  static const Duration _pauseFor = Duration(seconds: 45);

  static final SpeechListenOptions _listenOptions = SpeechListenOptions(
    listenMode: ListenMode.dictation,
    partialResults: true,
    cancelOnError: false,
  );

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = await _speechToText.initialize(
      onError: (val) => debugPrint('STT Error: $val'),
      onStatus: _onSpeechStatus,
    );
  }

  void _onSpeechStatus(String status) {
    debugPrint('STT Status: $status');
    if (!_continuousSession) return;
    if (status != SpeechToText.doneStatus) return;

    _resumeChain = _resumeChain.then((_) async {
      try {
        await _performResumeHandover();
      } catch (e, st) {
        debugPrint('STT resume chain error: $e\n$st');
      }
    });
  }

  Future<void> _performResumeHandover() async {
    if (!_continuousSession) return;
    await Future<void>.delayed(_resumeSettleDelay);
    if (!_continuousSession) return;
    if (_speechToText.isListening) return;
    try {
      await _beginListenSession();
    } catch (e, st) {
      debugPrint('STT resume after pause failed: $e\n$st');
    }
  }

  String get _fullCommitted => _committedSegments.join(' ').trim();

  void _appendFinalSegment(String words) {
    final prior = _fullCommitted;
    if (prior.isEmpty) {
      _committedSegments
        ..clear()
        ..add(words);
      return;
    }
    if (words == prior) return;
    if (words.startsWith(prior) || words.startsWith('$prior ')) {
      _committedSegments
        ..clear()
        ..add(words);
      return;
    }
    if (_committedSegments.isNotEmpty && words == _committedSegments.last) {
      return;
    }
    _committedSegments.add(words);
  }

  void _emitTranscript({String? partialInFlight}) {
    final committed = _fullCommitted;
    final text = (partialInFlight != null && partialInFlight.isNotEmpty)
        ? (committed.isEmpty
            ? partialInFlight
            : '$committed $partialInFlight'.trim())
        : committed;
    if (text.isEmpty) return;
    _onResultCallback?.call(text);
  }

  void _processSpeechResult(SpeechRecognitionResult result) {
    final words = result.recognizedWords.trim();
    if (result.finalResult && words.isNotEmpty) {
      _appendFinalSegment(words);
      _emitTranscript();
    } else if (!result.finalResult && words.isNotEmpty) {
      _emitTranscript(partialInFlight: words);
    }
  }

  Future<void> _beginListenSession() async {
    await _speechToText.listen(
      onResult: _processSpeechResult,
      localeId: 'ar-SA',
      listenOptions: _listenOptions,
      listenFor: _listenFor,
      pauseFor: _pauseFor,
    );
  }

  Future<void> startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      debugPrint('Microphone permission denied');
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final path =
        '${dir.path}/recitation_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(const RecordConfig(), path: path);
    debugPrint('Recording started at $path');
  }

  Future<String?> stopRecordingAndGetText() async {
    final path = await _recorder.stop();
    debugPrint('Recording stopped at $path');

    if (path == null) return null;

    // Here we would ideally send the file to a cloud STT if local STT is not enough.
    // For local STT using speech_to_text, it works in real-time.
    // However, the user request says: "Convert the recorded Arabic recitation into text using speech-to-text."
    // If we use the plugin, it usually listens while recording.
    // We'll return the last recognized text from a temporary variable if using real-time,
    // or implement a file-based STT if available.

    // To keep it simple as requested, let's assume we use the plugin's real-time listening
    // but the user wants it triggered by "Start/Stop" buttons.
    return null; // Placeholder for now, will refine in integration
  }

  Future<void> startListening(Function(String) onResult) async {
    await init();
    if (!_isInitialized) return;

    _onResultCallback = onResult;
    _committedSegments.clear();
    _continuousSession = true;
    _resumeChain = Future<void>.value();

    try {
      await _beginListenSession();
    } catch (e) {
      _continuousSession = false;
      debugPrint('Error starting listening: $e');
      rethrow;
    }
  }

  Future<void> stopListening() async {
    _continuousSession = false;
    _resumeChain = Future<void>.value();
    _committedSegments.clear();
    _onResultCallback = null;
    await _speechToText.stop();
  }

  RecitationResult verify(String expected, String recognized) {
    final normExpected = ArabicTextNormalizer.normalize(expected);
    final normRecognized = ArabicTextNormalizer.normalize(recognized);

    final similarity = normExpected.similarityTo(normRecognized);

    RecitationResultType type;
    if (similarity >= 0.9) {
      type = RecitationResultType.correct;
    } else if (similarity >= 0.7) {
      type = RecitationResultType.almostCorrect;
    } else {
      type = RecitationResultType.incorrect;
    }

    return RecitationResult(
      expectedText: expected,
      recognizedText: recognized,
      similarity: similarity,
      type: type,
    );
  }
}
