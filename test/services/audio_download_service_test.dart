import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_test/services/audio_download_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioDownloadService', () {
    late AudioDownloadService service;

    setUp(() {
      service = AudioDownloadService();
    });

    test('completedDownloads ValueNotifier starts empty', () {
      expect(service.completedDownloads.value.isEmpty, true);
    });

    test('downloadProgress ValueNotifier starts empty', () {
      expect(service.downloadProgress.value.isEmpty, true);
    });
  });
}
