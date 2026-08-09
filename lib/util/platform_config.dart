import 'package:flutter/foundation.dart';

enum AppPlatform { web, mobile }

class PlatformConfig {
  /// Default target platforms on which a feature is enabled and visible.
  static const List<AppPlatform> defaultPlatforms = [
    AppPlatform.web,
    AppPlatform.mobile,
  ];

  /// Returns whether a feature should be shown on the current running platform,
  /// given a list of target [platforms] (defaults to [defaultPlatforms] if omitted).
  static bool shouldShow([List<AppPlatform>? platforms]) {
    final targetPlatforms = platforms ?? defaultPlatforms;
    if (kIsWeb) {
      return targetPlatforms.contains(AppPlatform.web);
    }

    return targetPlatforms.contains(AppPlatform.mobile);
  }

  /// Shortcut that checks visibility on both web and mobile platforms.
  static bool get showOnAllPlatforms => shouldShow();

  /// Shortcut that checks visibility on mobile only.
  static bool get showOnMobileOnly => shouldShow([AppPlatform.mobile]);

  /// Shortcut that checks visibility on web only.
  static bool get showOnWebOnly => shouldShow([AppPlatform.web]);

  /// Shortcut that hides from all platforms.
  static bool get hideFromAllPlatforms => !showOnAllPlatforms;
}
