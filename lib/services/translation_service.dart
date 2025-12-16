import 'dart:convert';
import 'dart:collection';

import 'package:flutter/services.dart';

class SurahTextData {
  final Map<int, String> translations;
  final Map<int, String> transliterations;

  const SurahTextData({
    this.translations = const {},
    this.transliterations = const {},
  });
}

class TranslationService {
  static const int _maxCachedSurahs = 8;

  /// LRU-ish cache: insertion order map; we remove the oldest when exceeding
  /// [_maxCachedSurahs].
  final LinkedHashMap<int, SurahTextData> _surahCache = LinkedHashMap();

  SurahTextData _parseSurahFile(Object? decoded) {
    if (decoded is! Map<String, dynamic>) {
      return const SurahTextData();
    }

    final translations = <int, String>{};
    final transliterations = <int, String>{};

    for (final entry in decoded.entries) {
      final ayahNumber = int.tryParse(entry.key);
      if (ayahNumber == null) continue;

      final value = entry.value;

      if (value is String) {
        final t = value.trim();
        if (t.isNotEmpty) translations[ayahNumber] = t;
        continue;
      }

      if (value is Map) {
        final t = value['t']?.toString().trim();
        if (t != null && t.isNotEmpty) translations[ayahNumber] = t;

        final tr = value['tr']?.toString().trim();
        if (tr != null && tr.isNotEmpty) transliterations[ayahNumber] = tr;
        continue;
      }

      final t = value?.toString().trim();
      if (t != null && t.isNotEmpty) translations[ayahNumber] = t;
    }

    return SurahTextData(
      translations: translations,
      transliterations: transliterations,
    );
  }

  Future<SurahTextData> getSurahTextData(int surahNumber) async {
    if (surahNumber <= 0) return const SurahTextData();

    final cached = _surahCache[surahNumber];
    if (cached != null) {
      _surahCache.remove(surahNumber);
      _surahCache[surahNumber] = cached;
      return cached;
    }

    try {
      final raw =
          await rootBundle.loadString('assets/surah_meta/$surahNumber.json');

      final decoded = jsonDecode(raw);

      final data = _parseSurahFile(decoded);
      _surahCache[surahNumber] = data;

      while (_surahCache.length > _maxCachedSurahs) {
        _surahCache.remove(_surahCache.keys.first);
      }

      return data;
    } catch (_) {
      return const SurahTextData();
    }
  }

  Future<Map<int, String>> getSurahTranslations(int surahNumber) async {
    final data = await getSurahTextData(surahNumber);
    return data.translations;
  }

  Future<Map<int, String>> getSurahTransliterations(int surahNumber) async {
    final data = await getSurahTextData(surahNumber);
    return data.transliterations;
  }

  Future<String?> getTranslation({
    required int surahNumber,
    required int ayahNumberInSurah,
  }) async {
    if (surahNumber <= 0 || ayahNumberInSurah <= 0) return null;

    final surahMap = await getSurahTranslations(surahNumber);
    return surahMap[ayahNumberInSurah];
  }

  Future<String?> getTransliteration({
    required int surahNumber,
    required int ayahNumberInSurah,
  }) async {
    if (surahNumber <= 0 || ayahNumberInSurah <= 0) return null;

    final surahMap = await getSurahTransliterations(surahNumber);
    return surahMap[ayahNumberInSurah];
  }
}
