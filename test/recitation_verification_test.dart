import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_test/util/arabic_text_normalizer.dart';
import 'package:hafiz_test/services/recitation_verification_service.dart';

void main() {
  group('ArabicTextNormalizer', () {
    test('should remove tashkeel', () {
      expect(
          ArabicTextNormalizer.normalize(
              'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ'),
          'بسم الله الرحمن الرحيم');
    });

    test('should normalize Alef variations and Quranic marks', () {
      expect(ArabicTextNormalizer.normalize('أإآ'), 'ااا');
      expect(ArabicTextNormalizer.normalize('الرَّحْمَٰنِ'),
          'الرحمان'); // Superscript alef
      expect(
          ArabicTextNormalizer.normalize('ٱلْحَمْدُ'), 'الحمد'); // Alif wasla
    });

    test('should remove numbers (Western and Arabic)', () {
      expect(ArabicTextNormalizer.normalize('سورة الفاتحة ١'), 'سوره الفاتحه');
      expect(ArabicTextNormalizer.normalize('Verse 1'), 'Verse');
    });

    test('should remove extra spaces', () {
      expect(ArabicTextNormalizer.normalize('  بسم   الله  '), 'بسم الله');
    });
  });

  group('RecitationVerificationService', () {
    final service = RecitationVerificationService();

    test('verify should score correctly', () {
      final result = service.verify('بسم الله', 'بسم الله');
      expect(result.type, RecitationResultType.correct);
      expect(result.similarity, 1.0);
    });

    test('verify should score almost correct', () {
      // "بسم الله" vs "بسم اله" (missing one l)
      final result = service.verify('بسم الله', 'بسم اله');
      expect(
          result.type == RecitationResultType.almostCorrect ||
              result.type == RecitationResultType.correct,
          true);
    });

    test('verify should score incorrect', () {
      final result = service.verify('بسم الله', 'الحمد لله');
      expect(result.type, RecitationResultType.incorrect);
    });
  });
}
