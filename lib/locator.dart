import 'package:get_it/get_it.dart';
import 'package:hafiz_test/services/audio_center.dart';
import 'package:hafiz_test/services/audio_services.dart';
import 'package:hafiz_test/services/ayah.services.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:hafiz_test/services/storage/shared_prefs_storage_service.dart';
import 'package:hafiz_test/services/translation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hafiz_test/services/network.services.dart';
import 'package:hafiz_test/services/surah.services.dart';
import 'package:hafiz_test/util/surah_picker.dart';
import 'package:hafiz_test/util/theme_controller.dart';

final getIt = GetIt.instance;

Future<void> setupLocator() async {
  final prefs = await SharedPreferences.getInstance();

  getIt.registerSingleton<SharedPreferences>(prefs);

  getIt.registerSingleton<IStorageService>(SharedPrefsStorageService(prefs));
  getIt.registerSingleton<NetworkServices>(NetworkServices());
  getIt.registerSingleton<SurahPicker>(SurahPicker());
  getIt.registerSingleton<AudioServices>(AudioServices());
  getIt.registerSingleton<ThemeController>(ThemeController());
  getIt.registerSingleton<TranslationService>(TranslationService());

  getIt.registerSingleton<SurahServices>(
    SurahServices(
      networkServices: getIt<NetworkServices>(),
      storageServices: getIt<IStorageService>(),
      surahPicker: getIt<SurahPicker>(),
      translationService: getIt<TranslationService>(),
    ),
  );

  getIt.registerSingleton<AudioCenter>(
    AudioCenter(
      audioServices: getIt<AudioServices>(),
      surahServices: getIt<SurahServices>(),
    ),
  );

  getIt.registerSingleton<AyahServices>(
    AyahServices(
      networkServices: getIt<NetworkServices>(),
      storageServices: getIt<IStorageService>(),
    ),
  );
}
