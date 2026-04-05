// Utility to normalize Arabic text

class ArabicTextNormalizer {
  static String normalize(String text) {
    if (text.isEmpty) return text;

    // 1. Remove Tashkeel (harakat)
    // Range includes: Fatha, Damma, Kasra, Shadda, Sukun, Tanwin, etc.
    final tashkeelRegex = RegExp(r'[\u064B-\u0652\u0640]');
    String normalized = text.replaceAll(tashkeelRegex, '');

    // 2. Remove Arabic and Western digits
    final digitRegex = RegExp(r'[0-9\u0660-\u0669]');
    normalized = normalized.replaceAll(digitRegex, '');

    // 3. Remove common Quranic symbols (optional, but good for cleanliness)
    final symbolsRegex = RegExp(r'[\u06D6-\u06ED]');
    normalized = normalized.replaceAll(symbolsRegex, '');

    // 4. Normalize Alef variations (including Superscript Alef and Alif Wasla)
    normalized = normalized.replaceAll(RegExp(r'[أإآ\u0670\u0671]'), 'ا');

    // 5. Normalize Teh Marbuta to Heh
    normalized = normalized.replaceAll('ة', 'ه');

    // 6. Normalize Alef Maksura to Ya
    normalized = normalized.replaceAll('ى', 'ي');

    // 7. Remove extra spaces and trim
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();

    return normalized;
  }
}
