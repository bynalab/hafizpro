import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_test/services/audio_download_service.dart';
import 'package:hafiz_test/services/tarteel_audio_resolver.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hafiz_test/services/surah.services.dart';
import 'package:hafiz_test/services/network.services.dart';
import 'package:hafiz_test/services/surah_source.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:hafiz_test/util/surah_picker.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/model/ayah.model.dart';

class MockNetworkServices extends Mock implements NetworkServices {}

class MockIStorageService extends Mock implements IStorageService {}

class MockSurahPicker extends Mock implements SurahPicker {}

class MockSurahSource extends Mock implements SurahSource {}

class MockAudioDownloadService extends Mock implements AudioDownloadService {}

class FakeTarteelSelection extends Fake implements TarteelSelection {}
class FakeSurah extends Fake implements Surah {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    registerFallbackValue(FakeTarteelSelection());
    registerFallbackValue(FakeSurah());
  });
  group('SurahServices', () {
    late SurahServices surahServices;
    late MockNetworkServices mockNetworkServices;
    late MockIStorageService mockStorageServices;
    late MockSurahPicker mockSurahPicker;
    late MockSurahSource mockSurahSource;
    late MockAudioDownloadService mockAudioDownloadService;

    setUp(() {
      mockNetworkServices = MockNetworkServices();
      mockStorageServices = MockIStorageService();
      mockSurahPicker = MockSurahPicker();
      mockSurahSource = MockSurahSource();
      mockAudioDownloadService = MockAudioDownloadService();
      surahServices = SurahServices(
        networkServices: mockNetworkServices,
        storageServices: mockStorageServices,
        surahPicker: mockSurahPicker,
        surahSource: mockSurahSource,
        audioDownloadService: mockAudioDownloadService,
      );
    });

    group('getRandomSurahNumber', () {
      test('should return random surah number from picker', () {
        // Arrange
        const expectedSurahNumber = 42;
        when(() => mockSurahPicker.getNextSurah())
            .thenReturn(expectedSurahNumber);

        // Act
        final result = surahServices.getRandomSurahNumber();

        // Assert
        expect(result, equals(expectedSurahNumber));
        verify(() => mockSurahPicker.getNextSurah()).called(1);
      });
    });

    group('getSurah', () {
      test('should return Surah on successful response without local audio',
          () async {
        // Arrange
        const surahNumber = 1;
        const reciterId = 'ar.alafasy';

        final mockSurah = Surah(
          number: 1,
          name: 'Al-Fatihah',
          englishName: 'The Opener',
          ayahs: [
            Ayah(
                number: 1,
                text: 'Bismillah',
                numberInSurah: 1,
                juz: 1,
                manzil: 1,
                page: 1,
                ruku: 1,
                hizbQuarter: 1,
                audio: 'remote_url'),
          ],
        );

        when(() => mockStorageServices.getReciterId()).thenReturn(reciterId);
        when(() => mockSurahSource.getSurah(surahNumber))
            .thenAnswer((_) async => mockSurah);
        when(() => mockNetworkServices.urlExists(any()))
            .thenAnswer((_) async => true);
        when(() => mockAudioDownloadService.isSurahDownloaded(
                surahNumber, reciterId, any(), mockSurah))
            .thenAnswer((_) async => false);
        when(() => mockAudioDownloadService.getLocalAudioUrlIfExists(
                reciterId, surahNumber, ayahNumber: any(named: 'ayahNumber')))
            .thenAnswer((_) async => null);

        // Act
        final result = await surahServices.getSurah(surahNumber);

        // Assert
        expect(result, isA<Surah>());
        expect(result.number, equals(1));
        expect(result.ayahs.first.audio, equals('https://audio-cdn.tarteel.ai/quran/alafasy/001001.mp3'));
        verify(() => mockStorageServices.getReciterId()).called(1);
        verify(() => mockSurahSource.getSurah(surahNumber)).called(1);
        verify(() => mockAudioDownloadService.getLocalAudioUrlIfExists(
            reciterId, surahNumber,
            ayahNumber: 1)).called(1);
      });

      test('should return Surah with local audio URLs when downloaded',
          () async {
        // Arrange
        const surahNumber = 1;
        const reciterId = 'ar.alafasy';

        final mockSurah = Surah(
          number: 1,
          name: 'Al-Fatihah',
          englishName: 'The Opener',
          ayahs: [
            Ayah(
                number: 1,
                text: 'Bismillah',
                numberInSurah: 1,
                juz: 1,
                manzil: 1,
                page: 1,
                ruku: 1,
                hizbQuarter: 1,
                audio: 'remote_url'),
          ],
        );

        when(() => mockStorageServices.getReciterId()).thenReturn(reciterId);
        when(() => mockSurahSource.getSurah(surahNumber))
            .thenAnswer((_) async => mockSurah);
        when(() => mockNetworkServices.urlExists(any()))
            .thenAnswer((_) async => true);
        when(() => mockAudioDownloadService.isSurahDownloaded(
                surahNumber, reciterId, any(), mockSurah))
            .thenAnswer((_) async => true);
        when(() => mockAudioDownloadService.getLocalAudioUrlIfExists(
                reciterId, surahNumber, ayahNumber: 1))
            .thenAnswer((_) async => 'file:///local_audio.mp3');

        // Act
        final result = await surahServices.getSurah(surahNumber);

        // Assert
        expect(result.ayahs.first.audio, equals('file:///local_audio.mp3'));
        verify(() => mockAudioDownloadService.getLocalAudioUrlIfExists(
            reciterId, surahNumber,
            ayahNumber: 1)).called(1);
      });

      test('should throw Exception on null response data', () async {
        // Arrange
        const surahNumber = 1;
        const reciterId = 'ar.alafasy';

        when(() => mockStorageServices.getReciterId()).thenReturn(reciterId);
        when(() => mockNetworkServices.urlExists(any()))
            .thenAnswer((_) async => true);
        when(() => mockSurahSource.getSurah(surahNumber))
            .thenThrow(Exception('Failed to load surah'));
        when(() => mockAudioDownloadService.isSurahDownloaded(
            any(), any(), any(), any())).thenAnswer((_) async => false);

        // Act
        await expectLater(
          surahServices.getSurah(surahNumber),
          throwsA(isA<Exception>()),
        );

        // Assert
        verify(() => mockStorageServices.getReciterId()).called(1);
        verify(() => mockSurahSource.getSurah(surahNumber)).called(1);
      });

      test('should rethrow network errors', () async {
        // Arrange
        const surahNumber = 1;
        const reciterId = 'ar.alafasy';
        final dioError = DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.unknown,
        );

        when(() => mockStorageServices.getReciterId()).thenReturn(reciterId);
        when(() => mockNetworkServices.urlExists(any()))
            .thenAnswer((_) async => true);
        when(() => mockSurahSource.getSurah(surahNumber)).thenThrow(dioError);
        when(() => mockAudioDownloadService.isSurahDownloaded(
            any(), any(), any(), any())).thenAnswer((_) async => false);

        // Act & Assert
        await expectLater(
          surahServices.getSurah(surahNumber),
          throwsA(isA<DioException>()),
        );
      });
    });
  });
}
