import 'package:hafiz_test/model/ayah.model.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

Uri get artUri {
  return Uri.parse(
    'https://static.vecteezy.com/system/resources/thumbnails/052/112/816/small_2x/3d-many-qurans-on-the-wooden-table-islamic-concept-the-holy-al-quran-with-written-arabic-calligraphy-meaning-of-al-quran-photo.jpg',
  );
}

extension SurahAudioExtension on Surah {
  List<AudioSource> get audioSources {
    return ayahs.map((e) => e.audioSource).toList();
  }
}

extension AudioSourcePlaylistExtension on List<AudioSource> {
  List<AudioSource> prependBismillah(AudioSource? bismillah) {
    if (bismillah == null) return this;
    return [bismillah, ...this];
  }
}

extension AyahAudioExtension on Ayah {
  AudioSource get audioSource {
    final title = (surah?.englishName != null)
        ? '${surah?.englishName} v $numberInSurah'
        : 'Ayah $numberInSurah';

    return AudioSource.uri(
      Uri.parse(audio),
      tag: MediaItem(
        id: number.toString(),
        title: title,
        artUri: artUri,
      ),
    );
  }
}
