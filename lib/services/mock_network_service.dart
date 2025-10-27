import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Mock network service for web platform when CORS issues occur
class MockNetworkService {
  /// Get mock surah data for web platform
  static Future<Response> getMockSurahData(int surahNumber) async {
    if (kDebugMode) {
      print('Using mock data for surah $surahNumber on web platform');
    }

    // Return mock response structure similar to the real API
    final mockData = {
      "code": 200,
      "status": "OK",
      "data": {
        "number": surahNumber,
        "name": "Al-Fatihah",
        "englishName": "The Opening",
        "englishNameTranslation": "The Opening",
        "revelationType": "Meccan",
        "numberOfAyahs": 7,
        "ayahs": [
          {
            "number": 1,
            "text": "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
            "numberInSurah": 1,
            "juz": 1,
            "manzil": 1,
            "page": 1,
            "ruku": 1,
            "hizbQuarter": 1,
            "sajda": false
          },
          {
            "number": 2,
            "text": "الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ",
            "numberInSurah": 2,
            "juz": 1,
            "manzil": 1,
            "page": 1,
            "ruku": 1,
            "hizbQuarter": 1,
            "sajda": false
          }
        ]
      }
    };

    // Create a mock response
    return Response(
      data: mockData,
      statusCode: 200,
      requestOptions: RequestOptions(path: '/surah/$surahNumber'),
    );
  }

  /// Get mock ayah data for web platform
  static Future<Response> getMockAyahData(
      int surahNumber, int ayahNumber) async {
    if (kDebugMode) {
      print(
          'Using mock data for surah $surahNumber, ayah $ayahNumber on web platform');
    }

    final mockData = {
      "code": 200,
      "status": "OK",
      "data": {
        "number": ayahNumber,
        "text": "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
        "numberInSurah": ayahNumber,
        "juz": 1,
        "manzil": 1,
        "page": 1,
        "ruku": 1,
        "hizbQuarter": 1,
        "sajda": false
      }
    };

    return Response(
      data: mockData,
      statusCode: 200,
      requestOptions: RequestOptions(path: '/surah/$surahNumber/$ayahNumber'),
    );
  }
}
