import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hafiz_test/locator.dart';
import 'package:hafiz_test/services/analytics_service.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RatingService {
  static const String _keyHasRated = 'has_rated_app';
  static const String _keyRatingRequestCount = 'rating_request_count';
  static const String _keyLastRatingRequest = 'last_rating_request';
  static const String _keyTestSessionsCompleted = 'test_sessions_completed';
  static const String _keySurahsListened = 'surahs_listened';
  static const String _keyAppFirstLaunch = 'app_first_launch';
  static const String _keyDaysSinceFirstLaunch = 'days_since_first_launch';

  static const int _minTestSessions = 5;
  static const int _minSurahsListened = 3;
  static const int _minDaysSinceLaunch = 3;
  static const int _maxRatingRequests = 3;
  static const int _daysBetweenRequests = 7;

  /// Initialize the rating service and check if we should show rating dialog
  static Future<bool> shouldShowRatingDialog() async {
    final prefs = await SharedPreferences.getInstance();

    // Don't show if user has already rated
    if (prefs.getBool(_keyHasRated) == true) {
      return false;
    }

    // Don't show if we've exceeded max requests
    final requestCount = prefs.getInt(_keyRatingRequestCount) ?? 0;
    if (requestCount >= _maxRatingRequests) {
      return false;
    }

    // Check if enough time has passed since last request
    final lastRequest = prefs.getInt(_keyLastRatingRequest) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final daysSinceLastRequest = (now - lastRequest) / (1000 * 60 * 60 * 24);

    if (daysSinceLastRequest < _daysBetweenRequests) {
      return false;
    }

    // Check engagement criteria
    final testSessions = prefs.getInt(_keyTestSessionsCompleted) ?? 0;
    final surahsListened = prefs.getInt(_keySurahsListened) ?? 0;
    final daysSinceLaunch = prefs.getInt(_keyDaysSinceFirstLaunch) ?? 0;

    // Show rating dialog if user meets engagement criteria
    return (testSessions >= _minTestSessions ||
            surahsListened >= _minSurahsListened) &&
        daysSinceLaunch >= _minDaysSinceLaunch;
  }

  /// Track when user completes a test session
  static Future<void> trackTestSessionCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyTestSessionsCompleted) ?? 0;
    await prefs.setInt(_keyTestSessionsCompleted, current + 1);
  }

  /// Track when user listens to a surah
  static Future<void> trackSurahListened() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keySurahsListened) ?? 0;
    await prefs.setInt(_keySurahsListened, current + 1);
  }

  /// Initialize app launch tracking
  static Future<void> initializeAppLaunch() async {
    final prefs = await SharedPreferences.getInstance();

    // Set first launch date if not set
    if (prefs.getString(_keyAppFirstLaunch) == null) {
      await prefs.setString(
          _keyAppFirstLaunch, DateTime.now().toIso8601String());
    }

    // Update days since first launch
    final firstLaunchStr = prefs.getString(_keyAppFirstLaunch);
    if (firstLaunchStr != null) {
      final firstLaunch = DateTime.parse(firstLaunchStr);
      final daysSinceLaunch = DateTime.now().difference(firstLaunch).inDays;
      await prefs.setInt(_keyDaysSinceFirstLaunch, daysSinceLaunch);
    }
  }

  /// Show rating dialog
  static Future<void> showRatingDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    // Update request count and timestamp
    final requestCount = prefs.getInt(_keyRatingRequestCount) ?? 0;
    await prefs.setInt(_keyRatingRequestCount, requestCount + 1);
    await prefs.setInt(
        _keyLastRatingRequest, DateTime.now().millisecondsSinceEpoch);

    if (!context.mounted) return;

    // Show the rating dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const RatingDialog(),
    );
  }

  /// Mark that user has rated the app
  static Future<void> markAsRated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasRated, true);
  }

  /// Open app store for rating
  static Future<void> openAppStore() async {
    final InAppReview inAppReview = InAppReview.instance;

    if (!kIsWeb && Platform.isAndroid) {
      try {
        if (await inAppReview.isAvailable()) {
          await inAppReview.requestReview();
        }
      } catch (_) {}

      await inAppReview.openStoreListing();
      return;
    }

    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    } else {
      await inAppReview.openStoreListing();
    }
  }

  /// Get user engagement stats (for debugging)
  static Future<Map<String, int>> getEngagementStats() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'testSessions': prefs.getInt(_keyTestSessionsCompleted) ?? 0,
      'surahsListened': prefs.getInt(_keySurahsListened) ?? 0,
      'daysSinceLaunch': prefs.getInt(_keyDaysSinceFirstLaunch) ?? 0,
      'ratingRequests': prefs.getInt(_keyRatingRequestCount) ?? 0,
      'hasRated': prefs.getBool(_keyHasRated) == true ? 1 : 0,
    };
  }
}

class RatingDialog extends StatefulWidget {
  const RatingDialog({super.key});

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int selectedRating = 0;
  bool isSubmitting = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            Icons.star_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 8),
          Text(
            'Rate Our App',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'How would you rate your experience with Hafiz Pro?',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => setState(() => selectedRating = index + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    index < selectedRating ? Icons.star : Icons.star_border,
                    size: 40,
                    color: index < selectedRating
                        ? Colors.amber
                        : Theme.of(context).colorScheme.outline,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          if (selectedRating > 0) ...[
            Text(
              _getRatingMessage(selectedRating),
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _commentController,
              minLines: 2,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: selectedRating >= 4
                    ? 'Optional: tell us what you like'
                    : 'Tell us what we can improve',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            'Maybe Later',
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
          ),
        ),
        if (selectedRating > 0)
          ElevatedButton(
            onPressed: isSubmitting ? null : _handleRatingSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Submit'),
          ),
      ],
    );
  }

  String _getRatingMessage(int rating) {
    switch (rating) {
      case 1:
        return 'We\'re sorry to hear that. Please let us know how we can improve.';
      case 2:
        return 'We appreciate your feedback. We\'re working to make it better.';
      case 3:
        return 'Thank you for your feedback. We\'ll keep improving.';
      case 4:
        return 'Great! We\'re glad you\'re enjoying the app.';
      case 5:
        return 'Excellent! Thank you for the amazing rating.';
      default:
        return '';
    }
  }

  Future<void> _handleRatingSubmit() async {
    setState(() => isSubmitting = true);

    try {
      final comment = _commentController.text.trim();
      final IStorageService storage = getIt<IStorageService>();
      final userId = storage.getString('user_id');

      AnalyticsService.trackEvent(
        'Rating Feedback Submitted',
        properties: {
          'stars': selectedRating,
          'comment': comment,
          'user_id': userId,
          'platform': kIsWeb ? 'web' : Platform.operatingSystem,
        },
      );

      if (selectedRating >= 4) {
        // High rating - open app store
        await RatingService.markAsRated();
        await RatingService.openAppStore();
      } else {
        // Low rating - mark as rated to avoid repeated requests
        await RatingService.markAsRated();
      }
    } catch (e) {
      debugPrint('Error handling rating: $e');
    } finally {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}
