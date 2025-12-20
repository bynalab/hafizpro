import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class QuranDbAyahRow {
  final int surah;
  final int ayah;
  final String textAr;
  final String? translation;
  final String? transliteration;
  final int? juz;
  final int? page;
  final int? ruku;
  final int? hizbQuarter;
  final int? manzil;

  const QuranDbAyahRow({
    required this.surah,
    required this.ayah,
    required this.textAr,
    required this.translation,
    required this.transliteration,
    this.juz,
    this.page,
    this.ruku,
    this.hizbQuarter,
    this.manzil,
  });

  factory QuranDbAyahRow.fromMap(Map<String, Object?> row) {
    return QuranDbAyahRow(
      surah: (row['surah_number'] as int?) ?? 0,
      ayah: (row['ayah_number'] as int?) ?? 0,
      textAr: (row['text'] as String?) ?? '',
      translation: row['translation'] as String?,
      transliteration: row['transliteration'] as String?,
    );
  }
}

class QuranDb {
  static const String assetPath = 'assets/quran-offline.sqlite';
  static const String _fileName = 'quran-offline.sqlite';

  static const String defaultTranslationId = 'en_default';
  static const String defaultTransliterationId = 'tr_default';

  Database? _db;

  Future<void> init() async {
    if (_db != null) return;

    final docs = await getApplicationDocumentsDirectory();
    final destPath = p.join(docs.path, _fileName);

    final destFile = File(destPath);

    if (!destFile.existsSync()) {
      destFile.parent.createSync(recursive: true);
      final bytes = await rootBundle.load(assetPath);
      await destFile.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );
    }

    _db = await openDatabase(
      destPath,
      readOnly: true,
      singleInstance: true,
    );
  }

  Future<List<String>> getAvailableTranslationIds() async {
    final db = _db;
    if (db == null) {
      throw StateError('QuranDb not initialized. Call init() first.');
    }

    final rows = await db.rawQuery(
      'SELECT DISTINCT translation_id FROM verse_texts ORDER BY translation_id ASC;',
    );

    return rows
        .map((r) => (r['translation_id'] as String?)?.trim())
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toList(growable: false);
  }

  Future<List<QuranDbAyahRow>> getAyahsForSurah(
    int surahNumber, {
    String translationId = defaultTranslationId,
    String transliterationId = defaultTransliterationId,
  }) async {
    final db = _db;
    if (db == null) {
      throw StateError('QuranDb not initialized. Call init() first.');
    }

    final rows = await db.rawQuery(
      '''
SELECT
  v.surah_number AS surah_number,
  v.ayah_number AS ayah_number,
  v.text AS text,
  t.text AS translation,
  tr.text AS transliteration
FROM verses v
LEFT JOIN verse_texts t
  ON t.translation_id = ?
  AND t.surah_number = v.surah_number
  AND t.ayah_number = v.ayah_number
LEFT JOIN verse_texts tr
  ON tr.translation_id = ?
  AND tr.surah_number = v.surah_number
  AND tr.ayah_number = v.ayah_number
WHERE v.surah_number = ?
ORDER BY v.ayah_number ASC;
''',
      [translationId, transliterationId, surahNumber],
    );

    return rows
        .map(
          (r) => QuranDbAyahRow(
            surah: (r['surah_number'] as int?) ?? 0,
            ayah: (r['ayah_number'] as int?) ?? 0,
            textAr: (r['text'] as String?) ?? '',
            translation: r['translation'] as String?,
            transliteration: r['transliteration'] as String?,
            juz: null,
            page: null,
            ruku: null,
            hizbQuarter: null,
            manzil: null,
          ),
        )
        .toList(growable: false);
  }

  Future<void> dispose() async {
    final db = _db;
    _db = null;
    await db?.close();
  }
}
