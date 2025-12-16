import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hafiz_test/services/surah.services.dart';
import 'package:hafiz_test/services/network.services.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:hafiz_test/services/translation_service.dart';
import 'package:hafiz_test/util/surah_picker.dart';
import 'package:hafiz_test/model/surah.model.dart';

class MockNetworkServices extends Mock implements NetworkServices {}

class MockIStorageService extends Mock implements IStorageService {}

class MockSurahPicker extends Mock implements SurahPicker {}

class MockTranslationService extends Mock implements TranslationService {}

void main() {
  group('SurahServices', () {
    late SurahServices surahServices;
    late MockNetworkServices mockNetworkServices;
    late MockIStorageService mockStorageServices;
    late MockSurahPicker mockSurahPicker;
    late MockTranslationService mockTranslationService;

    setUp(() {
      mockNetworkServices = MockNetworkServices();
      mockStorageServices = MockIStorageService();
      mockSurahPicker = MockSurahPicker();
      mockTranslationService = MockTranslationService();
      surahServices = SurahServices(
        networkServices: mockNetworkServices,
        storageServices: mockStorageServices,
        surahPicker: mockSurahPicker,
        translationService: mockTranslationService,
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
      test('should return Surah on successful response', () async {
        // Arrange
        const surahNumber = 1;
        const reciterId = 'ar.alafasy';
        final mockResponse = Response(
          data: {
            'data': {
              'number': 1,
              'name': 'Al-Fatihah',
              'englishName': 'The Opener',
              'ayahs': []
            }
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(() => mockStorageServices.getReciterId()).thenReturn(reciterId);
        when(() => mockNetworkServices.urlExists(any()))
            .thenAnswer((_) async => false);
        when(() => mockNetworkServices.get(any()))
            .thenAnswer((_) async => mockResponse);

        when(() => mockTranslationService.getSurahTranslations(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await surahServices.getSurah(surahNumber);

        // Assert
        expect(result, isA<Surah>());
        expect(result.number, equals(1));
        expect(result.name, equals('Al-Fatihah'));
        verify(() => mockStorageServices.getReciterId()).called(1);
        verify(() => mockNetworkServices.get(any())).called(greaterThan(0));
        verify(() => mockTranslationService.getSurahTranslations(surahNumber))
            .called(1);
      });

      test('should return empty Surah on null response data', () async {
        // Arrange
        const surahNumber = 1;
        const reciterId = 'ar.alafasy';
        final mockResponse = Response(
          data: null,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(() => mockStorageServices.getReciterId()).thenReturn(reciterId);
        when(() => mockNetworkServices.urlExists(any()))
            .thenAnswer((_) async => false);
        when(() => mockNetworkServices.get(any()))
            .thenAnswer((_) async => mockResponse);

        // Act
        expect(() async => await surahServices.getSurah(surahNumber),
            throwsA(isA<Exception>()));

        // Assert
        verify(() => mockStorageServices.getReciterId()).called(1);
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
            .thenAnswer((_) async => false);
        when(() => mockNetworkServices.get(any())).thenThrow(dioError);

        // Act & Assert
        expect(
          () async => await surahServices.getSurah(surahNumber),
          throwsA(isA<DioException>()),
        );
      });
    });
  });
}
