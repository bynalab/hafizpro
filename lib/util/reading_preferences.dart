import 'package:hafiz_test/services/storage/abstract_storage_service.dart';

/// How the Quran reader lays out verses ([QuranView]).
enum QuranReaderViewMode {
  /// Scrollable list of ayah cards (default).
  normal,

  /// One ayah per page with swipe transitions.
  verseFocus,

  /// Page-by-page mushaf-style layout (planned).
  mushaf,
}

extension QuranReaderViewModeStorage on QuranReaderViewMode {
  String get storageValue {
    switch (this) {
      case QuranReaderViewMode.normal:
        return 'normal';
      case QuranReaderViewMode.verseFocus:
        return 'verseFocus';
      case QuranReaderViewMode.mushaf:
        return 'mushaf';
    }
  }

  static QuranReaderViewMode parse(String? raw) {
    switch (raw) {
      case 'verseFocus':
        return QuranReaderViewMode.verseFocus;
      case 'mushaf':
        return QuranReaderViewMode.mushaf;
      default:
        return QuranReaderViewMode.normal;
    }
  }
}

class ReadingPreferences {
  final bool showTranslation;
  final bool showTransliteration;
  final double arabicFontSize;
  final String arabicFontFamily;
  final String trackingMode;
  final QuranReaderViewMode readerViewMode;

  const ReadingPreferences({
    required this.showTranslation,
    required this.showTransliteration,
    required this.arabicFontSize,
    required this.arabicFontFamily,
    required this.trackingMode,
    this.readerViewMode = QuranReaderViewMode.normal,
  });

  ReadingPreferences copyWith({
    bool? showTranslation,
    bool? showTransliteration,
    double? arabicFontSize,
    String? arabicFontFamily,
    String? trackingMode,
    QuranReaderViewMode? readerViewMode,
  }) {
    return ReadingPreferences(
      showTranslation: showTranslation ?? this.showTranslation,
      showTransliteration: showTransliteration ?? this.showTransliteration,
      arabicFontSize: arabicFontSize ?? this.arabicFontSize,
      arabicFontFamily: arabicFontFamily ?? this.arabicFontFamily,
      trackingMode: trackingMode ?? this.trackingMode,
      readerViewMode: readerViewMode ?? this.readerViewMode,
    );
  }

  factory ReadingPreferences.fromStorage(IStorageService storage) {
    final showTranslation =
        (storage.getString(showTranslationKey) ?? 'true') == 'true';
    final showTransliteration =
        (storage.getString(showTransliterationKey) ?? 'true') == 'true';
    final arabicFontSize = double.tryParse(
          storage.getString(arabicFontSizeKey) ?? '24.0',
        ) ??
        24.0;
    final arabicFontFamily = storage.getString(arabicFontFamilyKey) ?? 'Amiri';
    final trackingMode = storage.getProgressTrackingMode();
    final readerViewMode = QuranReaderViewModeStorage.parse(
      storage.getString(quranReaderViewModeKey),
    );

    return ReadingPreferences(
      showTranslation: showTranslation,
      showTransliteration: showTransliteration,
      arabicFontSize: arabicFontSize,
      arabicFontFamily: arabicFontFamily,
      trackingMode: trackingMode,
      readerViewMode: readerViewMode,
    );
  }
}

const String showTranslationKey = 'show_translation';
const String showTransliterationKey = 'show_transliteration';
const String arabicFontSizeKey = 'arabic_font_size_v1';
const String arabicFontFamilyKey = 'arabic_font_family_v1';
const String quranReaderViewModeKey = 'quran_reader_view_mode_v1';

Future<void> setShowTranslationPreference(
  IStorageService storage,
  bool value,
) {
  return storage.setString(showTranslationKey, value.toString());
}

Future<void> setShowTransliterationPreference(
  IStorageService storage,
  bool value,
) {
  return storage.setString(showTransliterationKey, value.toString());
}

Future<void> setArabicFontSizePreference(
  IStorageService storage,
  double value,
) {
  return storage.setString(arabicFontSizeKey, value.toString());
}

Future<void> setArabicFontFamilyPreference(
  IStorageService storage,
  String value,
) {
  return storage.setString(arabicFontFamilyKey, value);
}

Future<void> setQuranReaderViewModePreference(
  IStorageService storage,
  QuranReaderViewMode mode,
) {
  return storage.setString(quranReaderViewModeKey, mode.storageValue);
}
