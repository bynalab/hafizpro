import 'dart:io';
import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/util/tarteel_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hafiz_test/services/tarteel_audio_resolver.dart';
import 'package:hafiz_test/services/surah_source.dart';
import 'package:hafiz_test/locator.dart';

class AudioDownloadService {
  AudioDownloadService();
  
  String? _cachedDocDirPath;

  /// Tracks download progress for a specific surah by a specific reciter.
  /// Key format: 'surahNumber_reciterId'
  final ValueNotifier<Map<String, double>> downloadProgress = ValueNotifier({});

  /// Tracks which surahs are fully downloaded.
  /// Key format: 'surahNumber_reciterId'
  final ValueNotifier<Set<String>> completedDownloads = ValueNotifier({});
  
  final Map<String, List<String>> _activeDownloads = {};

  Future<void> init() async {
    // We could scan the directory to find downloaded files,
    // but for simplicity and performance we will rely on checking
    // `isSurahDownloaded` dynamically when needed, or loading from SharedPreferences later.
    FileDownloader().configureNotificationForGroup(
      FileDownloader.defaultGroup,
      running: const TaskNotification('Downloading Audio', 'Please wait...'),
      complete: const TaskNotification('Download Finished', 'Audio is ready.'),
      error: const TaskNotification('Download Failed', 'Could not download audio.'),
      progressBar: true,
    );
  }

  Future<String> _getAudioDirectory(String reciterId) async {
    if (_cachedDocDirPath == null) {
      final docDir = await getApplicationDocumentsDirectory();
      _cachedDocDirPath = docDir.path;
    }
    final path = '$_cachedDocDirPath/audio/$reciterId';
    final audioDir = Directory(path);
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    return path;
  }

  String _getFileName(int surahNumber, {int? ayahNumber}) {
    if (ayahNumber != null) {
      return '${surahNumber}_$ayahNumber.mp3';
    }
    return '$surahNumber.mp3';
  }

  Future<String> getLocalAudioPath(String reciterId, int surahNumber,
      {int? ayahNumber}) async {
    final dir = await _getAudioDirectory(reciterId);
    final filename = _getFileName(surahNumber, ayahNumber: ayahNumber);
    return '$dir/$filename';
  }

  /// Checks if the audio file exists locally and returns the local file URI if it does.
  Future<String?> getLocalAudioUrlIfExists(String reciterId, int surahNumber,
      {int? ayahNumber}) async {
    final localPath =
        await getLocalAudioPath(reciterId, surahNumber, ayahNumber: ayahNumber);
    final file = File(localPath);
    if (await file.exists()) {
      return Uri.file(localPath).toString();
    }
    return null;
  }

  Future<bool> isSurahDownloaded(int surahNumber, String reciterId,
      TarteelSelection selection, Surah surah) async {
    if (selection.mode == TarteelMode.surah) {
      final path = await getLocalAudioPath(reciterId, surahNumber);
      return await File(path).exists();
    } else if (selection.mode == TarteelMode.verse) {
      // Check if all ayahs are downloaded using numberOfAyahs since the 
      // surah passed might only have metadata (no ayahs populated)
      if (surah.numberOfAyahs == 0) return false;
      
      for (int i = 1; i <= surah.numberOfAyahs; i++) {
        final path = await getLocalAudioPath(reciterId, surahNumber,
            ayahNumber: i);
        if (!await File(path).exists()) return false;
      }
      return true;
    }
    return false;
  }

  Future<void> downloadSurah({
    required int surahNumber,
    required String reciterId,
    required TarteelSelection selection,
    required Surah surah,
  }) async {
    final key = '${surahNumber}_$reciterId';

    // Set initial progress
    final currentProgress = Map<String, double>.from(downloadProgress.value);
    currentProgress[key] = 0.0;
    downloadProgress.value = currentProgress;

    _activeDownloads[key] = [];

    try {
      if (selection.mode == TarteelMode.surah) {
        final remoteUrl =
            TarteelAudio.surahUrlForReciter(reciterId, surahNumber);
        final filename = _getFileName(surahNumber);

        await _downloadFile(key, remoteUrl, reciterId, filename, (progress) {
          _updateProgress(key, progress);
        });
      } else if (selection.mode == TarteelMode.verse) {
        // Fallback to fetching full Surah if ayahs is empty to make sure we have all Ayahs
        final fullSurah = surah.ayahs.isEmpty
            ? await getIt<SurahSource>().getSurah(surahNumber)
            : surah;
        int completedAyahs = 0;
        final totalAyahs = fullSurah.numberOfAyahs > 0 ? fullSurah.numberOfAyahs : fullSurah.ayahs.length;

        for (final ayah in fullSurah.ayahs) {
          final remoteUrl = TarteelAudio.ayahUrlForReciter(
            reciterId,
            surahNumber,
            ayah.numberInSurah,
            ayahGlobal: ayah.number,
          );
          final localPath = await getLocalAudioPath(reciterId, surahNumber,
              ayahNumber: ayah.numberInSurah);
          final filename = _getFileName(surahNumber, ayahNumber: ayah.numberInSurah);

          if (!await File(localPath).exists()) {
            await _downloadFile(key, remoteUrl, reciterId, filename, (fileProgress) {
              final overallProgress =
                  (completedAyahs + fileProgress) / totalAyahs;
              _updateProgress(key, overallProgress);
            });
          }

          completedAyahs++;
          _updateProgress(key, completedAyahs / totalAyahs);
        }
      }

      // Mark as completed
      final completed = Set<String>.from(completedDownloads.value);
      completed.add(key);
      completedDownloads.value = completed;
    } catch (e) {
      if (e.toString().contains('canceled')) {
        debugPrint('Download cancelled for $key');
      } else {
        debugPrint('Error downloading surah: $e');
      }
    } finally {
      // Remove from progress mapping and active downloads
      final finalProgress = Map<String, double>.from(downloadProgress.value);
      finalProgress.remove(key);
      downloadProgress.value = finalProgress;
      _activeDownloads.remove(key);
    }
  }

  Future<void> deleteSurah(int surahNumber, String reciterId,
      TarteelSelection selection, Surah surah) async {
    if (selection.mode == TarteelMode.surah) {
      final path = await getLocalAudioPath(reciterId, surahNumber);
      final file = File(path);
      if (await file.exists()) await file.delete();
    } else if (selection.mode == TarteelMode.verse) {
      if (surah.numberOfAyahs == 0) return;
      for (int i = 1; i <= surah.numberOfAyahs; i++) {
        final path = await getLocalAudioPath(reciterId, surahNumber,
            ayahNumber: i);
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }

    final key = '${surahNumber}_$reciterId';
    final completed = Set<String>.from(completedDownloads.value);
    completed.remove(key);
    completedDownloads.value = completed;
  }

  Future<void> cancelDownload(int surahNumber, String reciterId, TarteelSelection selection, Surah surah) async {
    final key = '${surahNumber}_$reciterId';
    if (_activeDownloads.containsKey(key)) {
      final taskIds = _activeDownloads[key]!;
      for (final taskId in taskIds) {
        await FileDownloader().cancelTaskWithId(taskId);
      }
      _activeDownloads.remove(key);
    }
    
    // Clean up partial files
    await deleteSurah(surahNumber, reciterId, selection, surah);
  }

  void _updateProgress(String key, double progress) {
    final currentProgress = Map<String, double>.from(downloadProgress.value);
    currentProgress[key] = progress;
    downloadProgress.value = currentProgress;
  }

  Future<void> _downloadFile(
      String key, String url, String reciterId, String filename, void Function(double) onProgress) async {
    if (url.isEmpty) {
      throw ArgumentError.value(url, 'url', 'Empty download URL for key $key');
    }
    
    final task = DownloadTask(
      url: url,
      filename: filename,
      directory: 'audio/$reciterId',
      baseDirectory: BaseDirectory.applicationDocuments,
      updates: Updates.statusAndProgress,
    );

    _activeDownloads[key]?.add(task.taskId);

    try {
      final result = await FileDownloader().download(
        task,
        onProgress: (progress) {
          // background_downloader progress is usually between 0.0 and 1.0
          // Sometimes it can be negative for indeterminate progress
          if (progress >= 0.0 && progress <= 1.0) {
            onProgress(progress);
          }
        },
      );
      
      if (result.status == TaskStatus.canceled) {
        throw Exception('canceled');
      } else if (result.status != TaskStatus.complete) {
        throw Exception('Download failed with status: ${result.status}');
      }
    } catch (e) {
      debugPrint('Error downloading file $url: $e');
      rethrow;
    }
  }

  void dispose() {
    downloadProgress.dispose();
    completedDownloads.dispose();
  }
}
