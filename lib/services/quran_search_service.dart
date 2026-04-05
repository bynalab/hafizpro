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
  final QuranDb db;
  List<QuranSearchResult> _index = [];
  bool _isInitialized = false;

  QuranSearchService({required this.db});

  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;

    final rawAyahs = await db.getAllAyahsRaw();
    _index = rawAyahs.map((ayah) {
      return QuranSearchResult(
        surahNumber: ayah.surah,
        ayahNumber: ayah.ayah,
        originalText: ayah.textAr,
        normalizedText: ArabicTextNormalizer.normalize(ayah.textAr),
      );
    }).toList();

    _isInitialized = true;
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
