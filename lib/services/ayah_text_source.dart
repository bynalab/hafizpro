import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

abstract interface class AyahTextSource {
  Future<Map<int, ({String? translation, String? transliteration})>>
      getTextForSurah(
    int surahNumber, {
    required String translationId,
    required String transliterationId,
  });
}

class SurahMetaAssetAyahTextSource implements AyahTextSource {
  @override
  Future<Map<int, ({String? translation, String? transliteration})>>
      getTextForSurah(
    int surahNumber, {
    required String translationId,
    required String transliterationId,
  }) async {
    try {
      final raw =
          await rootBundle.loadString('assets/surah_meta/$surahNumber.json');
      final decoded = json.decode(raw) as Map;

      return {
        for (final entry in decoded.entries)
          if (int.tryParse(entry.key.toString()) case final ayahNum?)
            if (entry.value case {'t': final String t, 'tr': final String tr})
              ayahNum: (
                translation: t.isNotEmpty ? t : null,
                transliteration: tr.isNotEmpty ? tr : null,
              )
      };
    } catch (_) {
      return const {};
    }
  }
}
