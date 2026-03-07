import 'package:hafiz_test/services/storage/abstract_storage_service.dart';

class ReadingPreferences {
  final bool showTranslation;
  final bool showTransliteration;
  final double arabicFontSize;
  final String arabicFontFamily;
  final String trackingMode;

  const ReadingPreferences({
    required this.showTranslation,
    required this.showTransliteration,
    required this.arabicFontSize,
    required this.arabicFontFamily,
    required this.trackingMode,
  });

  ReadingPreferences copyWith({
    bool? showTranslation,
    bool? showTransliteration,
    double? arabicFontSize,
    String? arabicFontFamily,
    String? trackingMode,
  }) {
    return ReadingPreferences(
      showTranslation: showTranslation ?? this.showTranslation,
      showTransliteration: showTransliteration ?? this.showTransliteration,
      arabicFontSize: arabicFontSize ?? this.arabicFontSize,
      arabicFontFamily: arabicFontFamily ?? this.arabicFontFamily,
      trackingMode: trackingMode ?? this.trackingMode,
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

    return ReadingPreferences(
      showTranslation: showTranslation,
      showTransliteration: showTransliteration,
      arabicFontSize: arabicFontSize,
      arabicFontFamily: arabicFontFamily,
      trackingMode: trackingMode,
    );
  }
}

const String showTranslationKey = 'show_translation';
const String showTransliterationKey = 'show_transliteration';
const String arabicFontSizeKey = 'arabic_font_size_v1';
const String arabicFontFamilyKey = 'arabic_font_family_v1';

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
