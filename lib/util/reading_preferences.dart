import 'package:hafiz_test/services/storage/abstract_storage_service.dart';

typedef ReadingPreferences = ({
  bool showTranslation,
  bool showTransliteration,
  double arabicFontSize,
});

const String showTranslationKey = 'show_translation';
const String showTransliterationKey = 'show_transliteration';
const String arabicFontSizeKey = 'arabic_font_size_v1';

ReadingPreferences getReadingPreferences(IStorageService storage) {
  final showTranslation =
      (storage.getString(showTranslationKey) ?? 'true') == 'true';
  final showTransliteration =
      (storage.getString(showTransliterationKey) ?? 'true') == 'true';
  final arabicFontSize = double.tryParse(
        storage.getString(arabicFontSizeKey) ?? '24.0',
      ) ??
      24.0;

  return (
    showTranslation: showTranslation,
    showTransliteration: showTransliteration,
    arabicFontSize: arabicFontSize,
  );
}

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
