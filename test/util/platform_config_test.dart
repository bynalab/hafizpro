import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_test/util/platform_config.dart';

void main() {
  group('PlatformConfig', () {
    test(
        'shouldShow returns true when target platform list contains current platform',
        () {
      expect(
        PlatformConfig.shouldShow([AppPlatform.web, AppPlatform.mobile]),
        isTrue,
      );
    });

    test(
        'shouldShow returns false when target platform list excludes current platform',
        () {
      expect(
        PlatformConfig.shouldShow([]),
        isFalse,
      );
    });

    test('shouldShow defaults to PlatformConfig.defaultPlatforms when omitted',
        () {
      expect(PlatformConfig.shouldShow(), isTrue);
    });
  });
}
