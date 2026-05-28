import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/services/network.services.dart';
import 'package:hafiz_test/services/quran_api_providers.dart';
import 'package:hafiz_test/services/quran_db.dart';
import 'package:hafiz_test/util/arabic_text_normalizer.dart';
import 'package:string_similarity/string_similarity.dart';

class QuranSearchResult {
  final int surahNumber;
  final int ayahNumber;
  final String originalText;
  final String normalizedText;
  final double score;

  QuranSearchResult({
    required this.surahNumber,
    required this.ayahNumber,
    required this.originalText,
    required this.normalizedText,
    this.score = 0,
  });
}

class QuranSearchService {
  final QuranDb? db;
  final NetworkServices? networkServices;

  List<QuranSearchResult> _index = [];
  bool _isInitialized = false;

  /// Local SQLite index (mobile / desktop).
  QuranSearchService.db({required QuranDb this.db}) : networkServices = null;

  /// Fetches Uthmani text from the network API (web — no local DB).
  QuranSearchService.network({required NetworkServices this.networkServices})
      : db = null;

  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;

    if (db != null) {
      final rawAyahs = await db!.getAllAyahsRaw();
      _index = rawAyahs.map((ayah) {
        return QuranSearchResult(
          surahNumber: ayah.surah,
          ayahNumber: ayah.ayah,
          originalText: ayah.textAr,
          normalizedText: ArabicTextNormalizer.normalize(ayah.textAr),
        );
      }).toList();
    } else if (networkServices != null) {
      _index = await _buildIndexFromNetwork(networkServices!);
    }

    _isInitialized = true;
  }

  static const int _networkFetchConcurrency = 8;

  Future<Surah?> _fetchSurahUthmani(NetworkServices network, int surahNumber) async {
    final path = 'surah/$surahNumber/quran-uthmani';
    final candidates =
        kIsWeb ? const <String?>[null] : QuranApiProviders.baseUrls;

    for (final base in candidates) {
      final url = (base == null) ? path : '$base$path';
      try {
        final response = await network.get(url);
        final body = response.data;
        if (body != null && body['data'] != null) {
          return Surah.fromJson(body['data'] as Map<String, dynamic>);
        }
      } on FormatException {
        continue;
      } on DioException catch (e) {
        final code = e.response?.statusCode;
        if (code == 400 || code == 404) continue;
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError) {
          continue;
        }
        rethrow;
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  Future<List<QuranSearchResult>> _buildIndexFromNetwork(
    NetworkServices network,
  ) async {
    final out = <QuranSearchResult>[];

    for (var start = 1; start <= 114; start += _networkFetchConcurrency) {
      final end = (start + _networkFetchConcurrency - 1).clamp(1, 114);
      final futures = <Future<Surah?>>[];
      for (var s = start; s <= end; s++) {
        futures.add(_fetchSurahUthmani(network, s));
      }
      final surahs = await Future.wait(futures);
      for (final surah in surahs) {
        if (surah == null) continue;
        for (final ayah in surah.ayahs) {
          final text = ayah.text;
          if (text.isEmpty) continue;
          out.add(
            QuranSearchResult(
              surahNumber: surah.number,
              ayahNumber: ayah.numberInSurah,
              originalText: text,
              normalizedText: ArabicTextNormalizer.normalize(text),
            ),
          );
        }
      }
    }

    if (out.isEmpty) {
      debugPrint(
        'QuranSearchService: network index is empty (check API / connectivity).',
      );
    } else {
      debugPrint(
        'QuranSearchService: built web search index (${out.length} ayahs).',
      );
    }

    return out;
  }

  List<QuranSearchResult> search(String query) {
    if (query.trim().length < 3) return [];

    final normalizedQuery = ArabicTextNormalizer.normalize(query);
    if (normalizedQuery.isEmpty) return [];

    final List<QuranSearchResult> results = [];

    for (final item in _index) {
      double score = 0;

      // 1. Strict substring match gets high priority
      if (item.normalizedText.contains(normalizedQuery)) {
        score = 1.0;
      } else {
        // 2. Fuzzy similarity match (same logic as TestScreen)
        score = item.normalizedText.similarityTo(normalizedQuery);
      }

      if (score > 0.3) {
        results.add(QuranSearchResult(
          surahNumber: item.surahNumber,
          ayahNumber: item.ayahNumber,
          originalText: item.originalText,
          normalizedText: item.normalizedText,
          score: score,
        ));
      }
    }

    // Sort by score descending
    results.sort((a, b) => b.score.compareTo(a.score));

    // Return top 25 matches
    return results.take(25).toList();
  }
}
