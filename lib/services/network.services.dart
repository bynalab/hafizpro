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
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );
  }

  Future<Response> get(
    String url, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final normalizedUrl = url.startsWith('/') ? url : '/$url';
    return await _dio.get(normalizedUrl, queryParameters: queryParameters);
  }
}
