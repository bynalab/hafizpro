import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

class AssetUtil {
  /// Loads and decodes a JSON file from the application's assets.
  /// Returns null if the file cannot be loaded or decoded.
  static Future<dynamic> loadJson(String path) async {
    try {
      final String jsonStr = await rootBundle.loadString(path);
      return json.decode(jsonStr);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading JSON from $path: $e');
      }

      return null;
    }
  }
}
