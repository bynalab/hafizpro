import 'package:flutter/foundation.dart';

enum AdhkarPlatform { web, mobile }

class AdhkarConfig {
  /// Platforms on which the Adhkar feature is enabled and visible.
  /// Configure easily:
  /// - `[AdhkarPlatform.web, AdhkarPlatform.mobile]` for both Mobile & Web
  /// - `[AdhkarPlatform.web]` for Web only
  /// - `[AdhkarPlatform.mobile]` for Mobile only
  /// - `[]` to disable everywhere
  static const List<AdhkarPlatform> showOn = [
    AdhkarPlatform.web,
    AdhkarPlatform.mobile,
  ];

  /// Returns whether Adhkar should be shown on the current platform.
  static bool get shouldShow {
    if (kIsWeb) {
      return showOn.contains(AdhkarPlatform.web);
    }

    return showOn.contains(AdhkarPlatform.mobile);
  }
}
