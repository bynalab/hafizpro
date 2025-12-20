import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class NetworkServices {
  late final Dio _dio;

  NetworkServices() {
    _dio = Dio(
      BaseOptions(
        baseUrl: kIsWeb
            // For web, use the proxy format: /api/quran?path=/surah/1
            // The path passed to get() will be appended after `?path=`
            ? 'https://quran-proxy-steel.vercel.app/api/quran?path='
            : 'https://api.alquran.cloud/v1/',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        connectTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 45),
      ),
    );
  }

  Future<Response> get(
    String url, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final isAbsolute = url.startsWith('http://') || url.startsWith('https://');
    final normalizedUrl =
        isAbsolute ? url : (url.startsWith('/') ? url : '/$url');
    return await _dio.get(normalizedUrl, queryParameters: queryParameters);
  }

  Future<Response> head(
    String url, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final isAbsolute = url.startsWith('http://') || url.startsWith('https://');
    final normalizedUrl =
        isAbsolute ? url : (url.startsWith('/') ? url : '/$url');
    return await _dio.head(normalizedUrl, queryParameters: queryParameters);
  }

  Future<bool> urlExists(String url) async {
    try {
      await head(url);
      return true;
    } on DioException catch (e) {
      final code = e.response?.statusCode;

      // Many CDNs don't support HEAD (or respond inconsistently). Fall back to a
      // minimal GET.
      if (code == 403 || code == 405 || code == 404) {
        try {
          final isAbsolute =
              url.startsWith('http://') || url.startsWith('https://');
          final normalizedUrl =
              isAbsolute ? url : (url.startsWith('/') ? url : '/$url');

          final res = await _dio.get(
            normalizedUrl,
            options: Options(
              headers: const {'Range': 'bytes=0-0'},
              responseType: ResponseType.bytes,
              followRedirects: true,
              validateStatus: (status) => status != null,
            ),
          );

          return res.statusCode == 200 || res.statusCode == 206;
        } catch (_) {
          return false;
        }
      }

      if (code == 400) return false;
      return false;
    } catch (_) {
      return false;
    }
  }
}
