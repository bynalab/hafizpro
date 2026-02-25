import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:hafiz_test/services/network.services.dart';
import 'package:hafiz_test/services/audio_services.dart';
import 'package:hafiz_test/util/surah_picker.dart';

class MockIStorageService extends Mock implements IStorageService {
  @override
  Future<void> saveUserGuide() async {}
}

class MockNetworkServices extends Mock implements NetworkServices {}

class MockAudioServices extends Mock implements AudioServices {}

class MockSurahPicker extends Mock implements SurahPicker {}

void setupTestLocator() {
  final getIt = GetIt.instance;
  getIt.reset();

  // Register test doubles
  getIt.registerSingleton<IStorageService>(MockIStorageService());
  getIt.registerSingleton<NetworkServices>(MockNetworkServices());
  getIt.registerSingleton<AudioServices>(MockAudioServices());
  getIt.registerSingleton<SurahPicker>(MockSurahPicker());
}

void tearDownTestLocator() {
  GetIt.instance.reset();
}

void setupMockSharedPreferences() {
  SharedPreferences.setMockInitialValues({});
}
