import 'package:hafiz_test/model/ayah.model.dart';
import 'package:hafiz_test/model/reciter.model.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/data/reciters.dart';
import 'package:hafiz_test/util/reciter_audio_profile.dart';

class TarteelAudio {
  /// Finds a [Reciter] from the static [reciters] list by its identifier.
  ///
  /// Returns `null` if the reciter id is unknown.
  static Reciter? reciterForId(String reciterId) {
    for (final Reciter r in reciters) {
      if (r.identifier == reciterId) return r;
    }

    return null;
  }

  /// Attaches a single *surah-level* audio URL to every ayah in [surah],
  /// based on [reciterId].
  ///
  /// This is used for reciters whose audio is provided as one file per surah.
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

  /// Returns the verse-by-verse (ayah-by-ayah) base URL for [reciterId]
  /// (primary source only).
  static String? ayahBaseForReciter(String reciterId) {
    return ReciterAudioProfiles.forReciter(reciterId)?.ayahBase;
  }

  /// Returns the surah-by-surah base URL for [reciterId]
  /// (primary source only).
  static String? surahBaseForReciter(String reciterId) {
    return ReciterAudioProfiles.forReciter(reciterId)?.surahBase;
  }

  /// Returns the recitation type declared in `lib/data/reciters.dart`.
  ///
  /// This is used by [TarteelAudioResolver] to determine whether to probe
  /// surah-by-surah or verse-by-verse audio for the given reciter.
  static String? reciterType(String reciterId) {
    return reciterForId(reciterId)?.type;
  }

  /// Left-pads [value] with zeros until [width] characters.
  static String _pad(int value, int width) =>
      value.toString().padLeft(width, '0');

  /// Joins a URL [base] and a relative [path], avoiding double slashes.
  static String _joinUrl(String base, String path) {
    final normalizedBase =
        base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return '$normalizedBase/$normalizedPath';
  }

  /// Renders a filename/path template using surah/ayah numbers.
  ///
  /// Supported placeholders:
  /// - `{surah}` / `{ayah}` / `{ayahGlobal}`
  /// - Optional padding spec: `{surah:000}` (width inferred by number of chars)
  ///
  /// Note: `{ayahGlobal}` uses [ayahGlobal] if provided; otherwise falls back
  /// to [ayahNumber]. (Global ayah IDs are supplied by DB via `verses.id`.)
  static String _renderTemplate({
    required String template,
    required int surahNumber,
    int? ayahNumber,
    int? ayahGlobal,
  }) {
    // Supports:
    // - {surah} / {ayah}
    // - {surah:000} (width inferred by count of 0)
    // - {surah:00n} (width inferred by length of spec; 'n' is just a marker)
    final exp = RegExp(r'\{(surah|ayah|ayahGlobal)(?::([0n]+))?\}');
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
      } else if (key == 'ayahGlobal') {
        value = ayahGlobal ?? ayahNumber ?? 0;
        // ?? _globalAyahNumber(surahNumber, ayahNumber ?? 0);
      } else {
        value = ayahNumber ?? 0;
      }

      if (width == null) return value.toString();
      return _pad(value, width);
    });
  }

  /// Builds a default ayah URL using the historical `{surah:000}{ayah:000}.mp3`
  /// filename scheme.
  static String ayahUrl(String base, int surahNumber, int ayahNumberInSurah) {
    // Internal helper for the old default format.
    return _joinUrl(
      base,
      '${_pad(surahNumber, 3)}${_pad(ayahNumberInSurah, 3)}.mp3',
    );
  }

  /// Builds an ayah (verse) audio URL for [reciterId].
  ///
  /// Selection rules:
  /// - If the resolver has picked a reachable source, we use its index.
  /// - Otherwise we use the first declared source.
  /// - Finally, we fall back to legacy `profile.ayahBase/profile.ayahTemplate`.
  ///
  /// [ayahGlobal] is used by some providers (e.g. islamic.network) that store
  /// files by global ayah id (`{ayahGlobal}.mp3`).
  static String ayahUrlForReciter(
    String reciterId,
    int surahNumber,
    int ayahNumberInSurah, {
    int? ayahGlobal,
  }) {
    final profile = ReciterAudioProfiles.forReciter(reciterId);
    final sources = profile?.sources ?? const [];

    final preferredIndex =
        ReciterAudioProfiles.preferredSourceIndexForReciter(reciterId);
    final index = (preferredIndex != null &&
            preferredIndex >= 0 &&
            preferredIndex < sources.length)
        ? preferredIndex
        : (sources.isNotEmpty ? 0 : null);

    if (index != null) {
      final url = ayahUrlForSource(
        sources[index],
        surahNumber,
        ayahNumberInSurah,
        ayahGlobal: ayahGlobal,
      );

      if (url.trim().isNotEmpty) return url;
    }

    final base = profile?.ayahBase;
    final template = profile?.ayahTemplate;
    if (base == null || template == null) return '';

    final path = _renderTemplate(
      template: template,
      surahNumber: surahNumber,
      ayahNumber: ayahNumberInSurah,
      ayahGlobal: ayahGlobal,
    );
    return _joinUrl(base, path);
  }

  /// Builds an ayah URL for a specific [source] (base + template).
  ///
  /// Returns `''` if the source does not define `ayahBase` or `ayahTemplate`.
  static String ayahUrlForSource(
    ReciterAudioSource source,
    int surahNumber,
    int ayahNumberInSurah, {
    int? ayahGlobal,
  }) {
    final base = source.ayahBase;
    final template = source.ayahTemplate;
    if (base == null || template == null) return '';

    final path = _renderTemplate(
      template: template,
      surahNumber: surahNumber,
      ayahNumber: ayahNumberInSurah,
      ayahGlobal: ayahGlobal,
    );

    return _joinUrl(base, path);
  }

  /// Builds a surah-by-surah URL in the simplest `{surah}.mp3` scheme.
  static String surahUrl(String base, int surahNumber) {
    return _joinUrl(base, '$surahNumber.mp3');
  }

  /// Builds a surah audio URL for [reciterId] (one file per surah).
  ///
  /// Selection rules mirror [ayahUrlForReciter].
  static String surahUrlForReciter(String reciterId, int surahNumber) {
    final profile = ReciterAudioProfiles.forReciter(reciterId);
    final sources = profile?.sources ?? const [];

    final preferredIndex =
        ReciterAudioProfiles.preferredSourceIndexForReciter(reciterId);
    final index = (preferredIndex != null &&
            preferredIndex >= 0 &&
            preferredIndex < sources.length)
        ? preferredIndex
        : (sources.isNotEmpty ? 0 : null);

    if (index != null) {
      final url = surahUrlForSource(sources[index], surahNumber);
      if (url.trim().isNotEmpty) return url;
    }

    final base = profile?.surahBase;
    final template = profile?.surahTemplate;
    if (base == null || template == null) return '';

    final path = _renderTemplate(
      template: template,
      surahNumber: surahNumber,
    );
    return _joinUrl(base, path);
  }

  /// Builds a surah URL for a specific [source] (base + template).
  ///
  /// Returns `''` if the source does not define `surahBase` or `surahTemplate`.
  static String surahUrlForSource(
    ReciterAudioSource source,
    int surahNumber,
  ) {
    final base = source.surahBase;
    final template = source.surahTemplate;
    if (base == null || template == null) return '';

    final path = _renderTemplate(
      template: template,
      surahNumber: surahNumber,
    );

    return _joinUrl(base, path);
  }

  /// Attaches verse-by-verse audio URLs to [ayahs] using a single [base]
  /// and the default filename scheme.
  ///
  /// If you need per-reciter templates or multiple sources, prefer
  /// [withAudioForAyahsByReciter].
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

  /// Attaches a single surah audio URL (one file) to every ayah in [ayahs],
  /// based on [reciterId].
  static List<Ayah> withSurahAudioForAyahsByReciter(
    List<Ayah> ayahs, {
    required int surahNumber,
    required String reciterId,
  }) {
    final url = surahUrlForReciter(reciterId, surahNumber);
    if (url.trim().isEmpty) return ayahs;
    return ayahs.map((ayah) => ayah.copyWith(audio: url)).toList();
  }

  /// Attaches verse-by-verse audio URLs to [ayahs] based on [reciterId].
  ///
  /// Uses [Ayah.number] as the global ayah id (`ayahGlobal`) when building URLs.
  /// If a URL cannot be generated (missing profile/source), the ayah is left
  /// unchanged.
  static List<Ayah> withAudioForAyahsByReciter(
    List<Ayah> ayahs, {
    required int surahNumber,
    required String reciterId,
  }) {
    return ayahs.map(
      (ayah) {
        final url = ayahUrlForReciter(
          reciterId,
          surahNumber,
          ayah.numberInSurah,
          ayahGlobal: ayah.number,
        );
        if (url.trim().isEmpty) return ayah;
        return ayah.copyWith(
          audio: url,
        );
      },
    ).toList();
  }

  /// Attaches verse-by-verse audio URLs to every ayah in [surah] using a single
  /// [base] and the default filename scheme.
  static Surah withAudioForSurah(Surah surah, {required String base}) {
    return surah.copyWith(
      ayahs: withAudioForAyahs(
        surah.ayahs,
        surahNumber: surah.number,
        base: base,
      ),
    );
  }

  /// Attaches verse-by-verse audio URLs to every ayah in [surah] based on
  /// [reciterId].
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

  /// Attaches a single surah audio URL (one file) to every ayah in [ayahs]
  /// using a single [base].
  static List<Ayah> withSurahAudioForAyahs(
    List<Ayah> ayahs, {
    required int surahNumber,
    required String base,
  }) {
    final url = surahUrl(base, surahNumber);

    return ayahs.map((ayah) => ayah.copyWith(audio: url)).toList();
  }

  /// Attaches a single surah audio URL (one file) to every ayah in [surah]
  /// using a single [base].
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
