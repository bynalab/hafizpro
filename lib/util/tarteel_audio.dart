import 'package:hafiz_test/model/ayah.model.dart';
import 'package:hafiz_test/model/reciter.model.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/data/reciters.dart';
import 'package:hafiz_test/util/reciter_audio_profile.dart';

class TarteelAudio {
  static Reciter? reciterForId(String reciterId) {
    for (final Reciter r in reciters) {
      if (r.identifier == reciterId) return r;
    }

    return null;
  }

  static Surah withSurahAudioForSurahByReciter(
    Surah surah, {
    required String reciterId,
  }) {
    return surah.copyWith(
      ayahs: withSurahAudioForAyahsByReciter(
        surah.ayahs,
        surahNumber: surah.number,
        reciterId: reciterId,
      ),
    );
  }

  static String? ayahBaseForReciter(String reciterId) {
    return ReciterAudioProfiles.forReciter(reciterId)?.ayahBase;
  }

  static String? surahBaseForReciter(String reciterId) {
    return ReciterAudioProfiles.forReciter(reciterId)?.surahBase;
  }

  static String? reciterType(String reciterId) {
    return reciterForId(reciterId)?.type;
  }

  static String _pad(int value, int width) =>
      value.toString().padLeft(width, '0');

  static String _joinUrl(String base, String path) {
    final normalizedBase =
        base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return '$normalizedBase/$normalizedPath';
  }

  static String _renderTemplate({
    required String template,
    required int surahNumber,
    int? ayahNumber,
  }) {
    // Supports:
    // - {surah} / {ayah}
    // - {surah:000} (width inferred by count of 0)
    // - {surah:00n} (width inferred by length of spec; 'n' is just a marker)
    final exp = RegExp(r'\{(surah|ayah)(?::([0n]+))?\}');
    return template.replaceAllMapped(exp, (m) {
      final key = m.group(1);
      final spec = m.group(2);

      int? width;
      if (spec != null) {
        // Allow both "000" and "00n" styles.
        width = spec.length;
      }

      int value;
      if (key == 'surah') {
        value = surahNumber;
      } else {
        value = ayahNumber ?? 0;
      }

      if (width == null) return value.toString();
      return _pad(value, width);
    });
  }

  static String ayahUrl(String base, int surahNumber, int ayahNumberInSurah) {
    // Internal helper for the old default format.
    return _joinUrl(
      base,
      '${_pad(surahNumber, 3)}${_pad(ayahNumberInSurah, 3)}.mp3',
    );
  }

  static String ayahUrlForReciter(
    String reciterId,
    int surahNumber,
    int ayahNumberInSurah,
  ) {
    final profile = ReciterAudioProfiles.forReciter(reciterId);
    final base = profile?.ayahBase;
    final template = profile?.ayahTemplate;
    if (base == null || template == null) return '';

    final path = _renderTemplate(
      template: template,
      surahNumber: surahNumber,
      ayahNumber: ayahNumberInSurah,
    );
    return _joinUrl(base, path);
  }

  static String surahUrl(String base, int surahNumber) {
    return _joinUrl(base, '$surahNumber.mp3');
  }

  static String surahUrlForReciter(String reciterId, int surahNumber) {
    final profile = ReciterAudioProfiles.forReciter(reciterId);
    final base = profile?.surahBase;
    final template = profile?.surahTemplate;
    if (base == null || template == null) return '';

    final path = _renderTemplate(
      template: template,
      surahNumber: surahNumber,
    );
    return _joinUrl(base, path);
  }

  static List<Ayah> withAudioForAyahs(
    List<Ayah> ayahs, {
    required int surahNumber,
    required String base,
  }) {
    // This API is base-only. If you need different filename schemes per reciter,
    // use withAudioForAyahsByReciter.
    return ayahs.map(
      (ayah) {
        return ayah.copyWith(
          audio: ayahUrl(base, surahNumber, ayah.numberInSurah),
        );
      },
    ).toList();
  }

  static List<Ayah> withSurahAudioForAyahsByReciter(
    List<Ayah> ayahs, {
    required int surahNumber,
    required String reciterId,
  }) {
    final url = surahUrlForReciter(reciterId, surahNumber);
    return ayahs.map((ayah) => ayah.copyWith(audio: url)).toList();
  }

  static List<Ayah> withAudioForAyahsByReciter(
    List<Ayah> ayahs, {
    required int surahNumber,
    required String reciterId,
  }) {
    return ayahs.map(
      (ayah) {
        return ayah.copyWith(
          audio: ayahUrlForReciter(reciterId, surahNumber, ayah.numberInSurah),
        );
      },
    ).toList();
  }

  static Surah withAudioForSurah(Surah surah, {required String base}) {
    return surah.copyWith(
      ayahs: withAudioForAyahs(
        surah.ayahs,
        surahNumber: surah.number,
        base: base,
      ),
    );
  }

  static Surah withAudioForSurahByReciter(
    Surah surah, {
    required String reciterId,
  }) {
    return surah.copyWith(
      ayahs: withAudioForAyahsByReciter(
        surah.ayahs,
        surahNumber: surah.number,
        reciterId: reciterId,
      ),
    );
  }

  static List<Ayah> withSurahAudioForAyahs(
    List<Ayah> ayahs, {
    required int surahNumber,
    required String base,
  }) {
    final url = surahUrl(base, surahNumber);

    return ayahs.map((ayah) => ayah.copyWith(audio: url)).toList();
  }

  static Surah withSurahAudioForSurah(Surah surah, {required String base}) {
    return surah.copyWith(
      ayahs: withSurahAudioForAyahs(
        surah.ayahs,
        surahNumber: surah.number,
        base: base,
      ),
    );
  }
}
