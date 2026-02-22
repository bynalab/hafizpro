import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hafiz_test/services/surah.services.dart';
import 'package:hafiz_test/services/network.services.dart';
import 'package:hafiz_test/services/surah_source.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:hafiz_test/util/surah_picker.dart';
import 'package:hafiz_test/model/surah.model.dart';

class MockNetworkServices extends Mock implements NetworkServices {}

class MockIStorageService extends Mock implements IStorageService {}

class MockSurahPicker extends Mock implements SurahPicker {}

class MockSurahSource extends Mock implements SurahSource {}

void main() {
  group('SurahServices', () {
    late SurahServices surahServices;
    late MockNetworkServices mockNetworkServices;
    late MockIStorageService mockStorageServices;
    late MockSurahPicker mockSurahPicker;
    late MockSurahSource mockSurahSource;

    setUp(() {
      mockNetworkServices = MockNetworkServices();
      mockStorageServices = MockIStorageService();
      mockSurahPicker = MockSurahPicker();
      mockSurahSource = MockSurahSource();
      surahServices = SurahServices(
        networkServices: mockNetworkServices,
        storageServices: mockStorageServices,
        surahPicker: mockSurahPicker,
        surahSource: mockSurahSource,
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

        final mockSurah = Surah(
          number: 1,
          name: 'Al-Fatihah',
          englishName: 'The Opener',
          ayahs: const [],
        );

        when(() => mockStorageServices.getReciterId()).thenReturn(reciterId);
        when(() => mockSurahSource.getSurah(surahNumber))
            .thenAnswer((_) async => mockSurah);

        // Act
        final result = await surahServices.getSurah(surahNumber);

        // Assert
        expect(result, isA<Surah>());
        expect(result.number, equals(1));
        expect(result.name, equals('Al-Fatihah'));
        verify(() => mockStorageServices.getReciterId()).called(1);
        verify(() => mockSurahSource.getSurah(surahNumber)).called(1);
      });

      test('should throw Exception on null response data', () async {
        // Arrange
        const surahNumber = 1;
        const reciterId = 'ar.alafasy';

        when(() => mockStorageServices.getReciterId()).thenReturn(reciterId);
        when(() => mockSurahSource.getSurah(surahNumber))
            .thenThrow(Exception('Failed to load surah'));

        // Act
        await expectLater(
          () async => await surahServices.getSurah(surahNumber),
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
        when(() => mockSurahSource.getSurah(surahNumber)).thenThrow(dioError);

        // Act & Assert
        expect(
          () async => await surahServices.getSurah(surahNumber),
          throwsA(isA<DioException>()),
        );
      });
    });
  });
}
