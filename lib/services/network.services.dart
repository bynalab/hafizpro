import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hafiz_test/services/mock_network_service.dart';

class NetworkServices {
  late final Dio _dio;

  NetworkServices() {
    if (kIsWeb) {
      // Use alternative CORS proxy for web platform
      _dio = Dio(
        BaseOptions(
          baseUrl:
              'https://api.allorigins.win/raw?url=https://api.alquran.cloud/v1/',
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          connectTimeout: Duration(seconds: 20),
          receiveTimeout: Duration(seconds: 20),
        ),
      );
    } else {
      // Use direct API for mobile platforms
      _dio = Dio(
        BaseOptions(
          baseUrl: 'https://api.alquran.cloud/v1/',
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          connectTimeout: Duration(seconds: 10),
          receiveTimeout: Duration(seconds: 10),
        ),
      );
    }
  }

  Future<Response> get(
    String url, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      if (kIsWeb) {
        print('Making web request to: $url');
      }
      return await _dio.get(url, queryParameters: queryParameters);
    } catch (e) {
      if (kIsWeb) {
        print('Web network error: $e');
        print('Falling back to mock data for web platform');

        // Try to extract surah number from URL for mock data
        try {
          final surahMatch = RegExp(r'/surah/(\d+)').firstMatch(url);
          if (surahMatch != null) {
            final surahNumber = int.parse(surahMatch.group(1)!);
            return await MockNetworkService.getMockSurahData(surahNumber);
          }
        } catch (mockError) {
          print('Mock data also failed: $mockError');
        }

        // If mock data fails, throw the original error
        throw DioException(
          requestOptions: RequestOptions(path: url),
          error:
              'Network request failed on web platform. CORS restrictions prevent API access.',
          type: DioExceptionType.connectionError,
        );
      }
      rethrow;
    }
  }

  Future<Response> post(
    String url, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? headers,
  }) async {
    try {
      if (kIsWeb) {
        print('Making web POST request to: $url');
      }
      return await _dio.post(
        url,
        data: body,
        options: Options(headers: headers),
      );
    } catch (e) {
      if (kIsWeb) {
        print('Web POST network error: $e');
        throw DioException(
          requestOptions: RequestOptions(path: url),
          error:
              'Network POST request failed on web platform. This may be due to CORS restrictions.',
          type: DioExceptionType.connectionError,
        );
      }
      rethrow;
    }
  }
}
