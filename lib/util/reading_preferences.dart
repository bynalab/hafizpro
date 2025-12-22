import 'package:hafiz_test/services/storage/abstract_storage_service.dart';

typedef ReadingPreferences = ({bool showTranslation, bool showTransliteration});

const String showTranslationKey = 'show_translation';
const String showTransliterationKey = 'show_transliteration';

ReadingPreferences getReadingPreferences(IStorageService storage) {
  final showTranslation =
      (storage.getString(showTranslationKey) ?? 'true') == 'true';
  final showTransliteration =
      (storage.getString(showTransliterationKey) ?? 'true') == 'true';

  return (
    showTranslation: showTranslation,
    showTransliteration: showTransliteration,
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
