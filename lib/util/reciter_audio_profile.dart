class ReciterAudioProfile {
  final String? ayahBase;
  final String? surahBase;
  final String? ayahTemplate;
  final String? surahTemplate;

  const ReciterAudioProfile({
    this.ayahBase,
    this.surahBase,
    this.ayahTemplate,
    this.surahTemplate,
  });
}

class ReciterAudioProfiles {
  static const Map<String, ReciterAudioProfile> byReciterId = {
    'ar.saoodshuraym': ReciterAudioProfile(
      ayahBase: 'https://audio-cdn.tarteel.ai/quran/saudAlShuraim',
      ayahTemplate: '{surah:000}{ayah:000}.mp3',
    ),
    'ar.abdurrahmaansudais': ReciterAudioProfile(
      ayahBase: 'https://audio.qurancdn.com/Sudais/mp3',
      ayahTemplate: '{surah:000}{ayah:000}.mp3',
    ),
    'ar.yasseraldossary': ReciterAudioProfile(
      ayahBase: 'https://audio-cdn.tarteel.ai/quran/yasserAlDosari',
      ayahTemplate: '{surah:000}{ayah:000}.mp3',
    ),
    'ar.minshawymurattal': ReciterAudioProfile(
      ayahBase: 'https://audio-cdn.tarteel.ai/quran/minshawyMurattal',
      ayahTemplate: '{surah:000}{ayah:000}.mp3',
    ),
    'ar.minshawy_kids_repeat': ReciterAudioProfile(
      surahBase:
          'https://download.quranicaudio.com/qdc/siddiq_minshawi/kids_repeat',
      surahTemplate: '{surah}.mp3',
    ),
    'ar.noreen_siddiq': ReciterAudioProfile(
      surahBase: 'https://download.quranicaudio.com/quran/noreen_siddiq/',
      surahTemplate: '{surah:000}.mp3',
    ),
  };

  static ReciterAudioProfile? forReciter(String reciterId) {
    return byReciterId[reciterId];
  }
}
