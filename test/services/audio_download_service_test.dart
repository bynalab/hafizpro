import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_test/services/audio_download_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioDownloadService', () {
    late AudioDownloadService service;

    setUp(() {
      service = AudioDownloadService();
    });

    tearDown(() {
      service.dispose();
    });

    test('completedDownloads ValueNotifier starts empty', () {
      expect(service.completedDownloads.value.isEmpty, true);
    });

    test('downloadProgress ValueNotifier starts empty', () {
      expect(service.downloadProgress.value.isEmpty, true);
    });

    test('downloadProgress updates value and fires notifications to listeners', () {
      var listenerCalled = false;
      service.downloadProgress.addListener(() {
        listenerCalled = true;
      });

      final progress = {'1_ar.alafasy': 0.5};
      service.downloadProgress.value = progress;

      expect(service.downloadProgress.value, equals(progress));
      expect(listenerCalled, true);
    });

    test('completedDownloads tracks finished entries and notifies listeners', () {
      var listenerCalled = false;
      service.completedDownloads.addListener(() {
        listenerCalled = true;
      });

      final completed = {'1_ar.alafasy'};
      service.completedDownloads.value = completed;

      expect(service.completedDownloads.value, equals(completed));
      expect(listenerCalled, true);
    });

    test('completedDownloads correctly removes entries on deletion simulations', () {
      final completed = {'1_ar.alafasy', '2_ar.alafasy'};
      service.completedDownloads.value = completed;

      final updated = Set<String>.from(service.completedDownloads.value);
      updated.remove('1_ar.alafasy');
      service.completedDownloads.value = updated;

      expect(service.completedDownloads.value.contains('1_ar.alafasy'), false);
      expect(service.completedDownloads.value.contains('2_ar.alafasy'), true);
    });
  });
}
