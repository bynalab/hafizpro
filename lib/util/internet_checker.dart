import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

Future<bool> hasInternetConnection() async {
  try {
    final result = await Connectivity().checkConnectivity();

    // connectivity_plus returns a List<ConnectivityResult> (supports multi).
    // If `none` is present, treat as offline.
    if (result.contains(ConnectivityResult.none)) return false;

    // Web: keep it simple. Browser connectivity is not reliably probeable due to
    // CORS, captive portals, etc. If a network is present, allow the attempt.
    if (kIsWeb) return true;

    // Secondary check (mobile/desktop): confirm we can reach the internet.
    // Use Google's lightweight endpoint.
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
        sendTimeout: const Duration(seconds: 3),
      ),
    );

    final res = await dio.get(
      'https://www.google.com/generate_204',
      options: Options(
        responseType: ResponseType.plain,
        followRedirects: true,
        validateStatus: (status) => status != null,
      ),
    );

    final code = res.statusCode;
    return code != null && code >= 200 && code < 400;
  } catch (_) {
    // If the platform cannot report connectivity, default to allowing the try.
    return true;
  }
}
