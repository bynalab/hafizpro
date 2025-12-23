// ignore_for_file: avoid_print

import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:hafiz_test/config/analytics_config.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static const String _projectToken = AnalyticsConfig.mixpanelProjectToken;
  static Mixpanel? _mixpanel;
  static bool _isInitialized = false;

  // Simple session tracking
  static DateTime? _sessionStartTime;
  static String? _currentScreen;
  static DateTime? _screenStartTime;
  static bool _sessionEnded = false;

  // Audio tracking deduplication
  static String? _lastTrackedAudio;
  static DateTime? _lastAudioTrackTime;

  /// Initialize Mixpanel with the project token
  static Future<void> initialize() async {
    if (_isInitialized || !AnalyticsConfig.enableAnalytics) return;

    try {
      if (AnalyticsConfig.debugMode) {
        print(
            'Initializing Mixpanel with token: ${_projectToken.substring(0, 8)}...');
      }

      // Skip Mixpanel initialization on web for now due to compatibility issues
      if (kIsWeb) {
        if (AnalyticsConfig.debugMode) {
          print('⚠️ Skipping Mixpanel initialization on web platform');
        }
        _isInitialized = true;
        _sessionStartTime = DateTime.now();
        return;
      }

      _mixpanel =
          await Mixpanel.init(_projectToken, trackAutomaticEvents: true);

      _isInitialized = true;

      // Initialize session tracking
      _sessionStartTime = DateTime.now();

      if (AnalyticsConfig.debugMode) {
        print('✅ Mixpanel initialized successfully');
      }
    } catch (e) {
      print('❌ Failed to initialize Mixpanel: $e');
      // Don't fail the app if analytics fails
      if (kDebugMode) {
        print('Analytics initialization failed, continuing without analytics');
      }
      _isInitialized = true; // Mark as initialized to prevent repeated attempts
    }
  }

  /// Track an event with optional properties
  static void trackEvent(String eventName, {Map<String, dynamic>? properties}) {
    if (!AnalyticsConfig.enableAnalytics ||
        !_isInitialized ||
        _mixpanel == null) {
      if (AnalyticsConfig.debugMode) {
        print(
            'Mixpanel not initialized or disabled. Cannot track event: $eventName');
      }
      return;
    }

    try {
      _mixpanel!.track(eventName, properties: properties);

      if (AnalyticsConfig.debugMode) {
        print('Tracked event: $eventName with properties: $properties');
        _mixpanel!.flush();
      }
    } catch (e) {
      print('Failed to track event $eventName: $e');
    }
  }

  /// Identify a user with a unique ID
  static void identifyUser(String userId) {
    if (!AnalyticsConfig.enableAnalytics ||
        !_isInitialized ||
        _mixpanel == null) {
      if (AnalyticsConfig.debugMode) {
        print('Mixpanel not initialized or disabled. Cannot identify user');
      }
      return;
    }

    try {
      _mixpanel!.identify(userId);

      if (AnalyticsConfig.debugMode) {
        print('User identified: $userId');
      }
    } catch (e) {
      print('Failed to identify user: $e');
    }
  }

  // ===== 1. LIFECYCLE TRACKING =====

  /// Track app lifecycle events
  static void trackAppLifecycle(String lifecycleState) {
    trackEvent('App Lifecycle', properties: {
      'lifecycle_state': lifecycleState,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track session start
  static void trackSessionStart() {
    _sessionStartTime = DateTime.now();
    _sessionEnded = false; // Reset session ended flag
    _resetAudioTracking(); // Reset audio tracking state
    trackEvent('Session Started', properties: {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Reset audio tracking state
  static void _resetAudioTracking() {
    _lastTrackedAudio = null;
    _lastAudioTrackTime = null;
  }

  /// Track session end
  static void trackSessionEnd() {
    if (_sessionStartTime != null && !_sessionEnded) {
      _sessionEnded = true; // Prevent duplicate session end events
      final sessionDuration = DateTime.now().difference(_sessionStartTime!);
      trackEvent('Session Ended', properties: {
        'session_duration_seconds': sessionDuration.inSeconds,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  // ===== 2. TIME SPENT ON PAGE/SCREEN =====

  /// Track screen view and start timing
  static void trackScreenView(String screenName) {
    // Track time spent on previous screen
    if (_currentScreen != null && _screenStartTime != null) {
      final timeSpent = DateTime.now().difference(_screenStartTime!);
      trackEvent('Time Spent on Screen', properties: {
        'screen_name': _currentScreen,
        'time_spent_seconds': timeSpent.inSeconds,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }

    // Start timing for new screen
    _currentScreen = screenName;
    _screenStartTime = DateTime.now();

    trackEvent('Screen View', properties: {
      'screen_name': screenName,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // ===== 3. BUTTON CLICKS =====

  /// Track button clicks
  static void trackButtonClick(String buttonName,
      {String? screen, Map<String, dynamic>? context}) {
    trackEvent('Button Clicked', properties: {
      'button_name': buttonName,
      'screen': screen ?? _currentScreen,
      'timestamp': DateTime.now().toIso8601String(),
      ...?context,
    });
  }

  // ===== 4. AUDIO CONTROLS =====

  /// Track audio control (play/pause/stop)
  static void trackAudioControl(String action, String audioName,
      {String? audioType}) {
    trackEvent('Audio Control', properties: {
      'action': action, // 'play', 'pause', 'stop'
      'audio_name': audioName,
      'audio_type': audioType ?? 'unknown',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // ===== 5. BACK PRESS =====

  /// Track back press
  static void trackBackPress({String? fromScreen}) {
    trackEvent('Back Pressed', properties: {
      'from_screen': fromScreen ?? _currentScreen,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // ===== 6. TEST REFRESH AND REPEAT =====

  /// Track test refresh
  static void trackTestRefresh(String testType,
      {Map<String, dynamic>? context}) {
    trackEvent('Test Refreshed', properties: {
      'test_type': testType,
      'timestamp': DateTime.now().toIso8601String(),
      ...?context,
    });
  }

  /// Track repeat switch toggle
  static void trackRepeatSwitch(bool isEnabled, {String? audioName}) {
    trackEvent('Repeat Switch Toggled', properties: {
      'repeat_enabled': isEnabled,
      'audio_name': audioName,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // ===== LEGACY METHODS (keeping for compatibility) =====

  static void trackAppLaunch() {
    trackSessionStart();
    trackEvent('App Launched', properties: {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static void trackSurahSelected(String surahName, int surahNumber) {
    trackEvent('Surah Selected', properties: {
      'surah_name': surahName,
      'surah_number': surahNumber,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static void trackJuzSelected(int juzNumber) {
    trackEvent('Juz Selected', properties: {
      'juz_number': juzNumber,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static void trackTestStarted(
      String testType, Map<String, dynamic> testDetails) {
    trackEvent('Test Started', properties: {
      'test_type': testType,
      ...testDetails,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static void trackTestCompleted(
      String testType, Map<String, dynamic> testResults) {
    trackEvent('Test Completed', properties: {
      'test_type': testType,
      ...testResults,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static void trackSettingsChanged(
      String settingName, dynamic oldValue, dynamic newValue) {
    trackEvent('Settings Changed', properties: {
      'setting_name': settingName,
      'old_value': oldValue.toString(),
      'new_value': newValue.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // ===== AUDIO LIFECYCLE TRACKING =====

  /// Track audio lifecycle events (start/complete)
  static void trackAudioLifecycle(
    String event,
    String audioName, {
    String? audioType,
    String? surahName,
    int? ayahNumber,
    bool? isPlaylist,
    Map<String, dynamic>? additionalProperties,
  }) {
    final properties = <String, dynamic>{
      'audio_name': audioName,
      'audio_type': audioType ?? 'recitation',
      'timestamp': DateTime.now().toIso8601String(),
      if (surahName != null) 'surah_name': surahName,
      if (ayahNumber != null) 'ayah_number': ayahNumber,
      if (isPlaylist != null) 'is_playlist': isPlaylist,
      ...?additionalProperties,
    };

    trackEvent(event, properties: properties);
  }

  /// Track audio start with deduplication
  static void trackAudioStart(
    String audioName, {
    String? audioType,
    String? surahName,
    int? ayahNumber,
    bool? isPlaylist,
    Map<String, dynamic>? additionalProperties,
  }) {
    final now = DateTime.now();
    final audioKey = '${audioName}_${surahName ?? ''}_${ayahNumber ?? ''}';

    // Check if this is a duplicate within 2 seconds
    if (_lastTrackedAudio == audioKey &&
        _lastAudioTrackTime != null &&
        now.difference(_lastAudioTrackTime!).inSeconds < 2) {
      return; // Skip duplicate
    }

    // Update tracking state
    _lastTrackedAudio = audioKey;
    _lastAudioTrackTime = now;

    trackAudioLifecycle(
      'Audio Started',
      audioName,
      audioType: audioType,
      surahName: surahName,
      ayahNumber: ayahNumber,
      isPlaylist: isPlaylist,
      additionalProperties: additionalProperties,
    );
  }

  /// Track audio completion
  static void trackAudioComplete(
    String audioName, {
    String? audioType,
    String? surahName,
    int? ayahNumber,
    bool? wasPlaylist,
    Map<String, dynamic>? additionalProperties,
  }) {
    trackAudioLifecycle(
      'Audio Completed',
      audioName,
      audioType: audioType,
      surahName: surahName,
      ayahNumber: ayahNumber,
      isPlaylist: wasPlaylist,
      additionalProperties: additionalProperties,
    );
  }

  /// Track speed change
  static void trackSpeedChanged(double newSpeed, String audioName) {
    trackEvent('Speed Changed', properties: {
      'new_speed': newSpeed,
      'audio_name': audioName,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
