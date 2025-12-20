class ReciterAudioSource {
  final String? ayahBase;
  final String? surahBase;
  final String? ayahTemplate;
  final String? surahTemplate;

  const ReciterAudioSource({
    this.ayahBase,
    this.surahBase,
    this.ayahTemplate,
    this.surahTemplate,
  });
}

class ReciterAudioProfile {
  final List<ReciterAudioSource> sources;

  const ReciterAudioProfile({
    this.sources = const [],
  });

  ReciterAudioSource? get primarySource {
    if (sources.isEmpty) return null;
    return sources.first;
  }

  String? get ayahBase => primarySource?.ayahBase;
  String? get surahBase => primarySource?.surahBase;
  String? get ayahTemplate => primarySource?.ayahTemplate;
  String? get surahTemplate => primarySource?.surahTemplate;
}

class ReciterAudioProfiles {
  static const String _tarteelQuranBase = 'https://audio-cdn.tarteel.ai/quran';
  static const String _tarteelAyahTemplate = '{surah:000}{ayah:000}.mp3';

  static const String _islamicNetwork192Base =
      'https://cdn.islamic.network/quran/audio/192';
  static const String _islamicNetwork128Base =
      'https://cdn.islamic.network/quran/audio/128';

  static final Map<String, ReciterAudioProfile> byReciterId = {
    ..._tarteelVerseByVerseProfiles(
      {
        'ar.saoodshuraym': 'saudAlShuraim',
        'ar.abdulbasitmurattal': 'abdulBasitMurattal',
        'ar.shaatree': 'abuBakrAlShatri',
        'ar.alafasy': 'alafasy',
        'ar.yasseraldossary': 'yasserAlDosari',
        'ar.minshawymurattal': 'minshawyMurattal',
      },
      extraSources: (reciterId) {
        if (reciterId == 'ar.alafasy') {
          return [
            ReciterAudioSource(
              ayahBase: '$_islamicNetwork128Base/ar.alafasy',
              ayahTemplate: '{ayahGlobal}.mp3',
            ),
          ];
        }

        return const [];
      },
    ),
    'ar.abdullahbasfar': ReciterAudioProfile(
      sources: [
        ReciterAudioSource(
          ayahBase: '$_islamicNetwork192Base/ar.abdullahbasfar',
          ayahTemplate: '{ayahGlobal}.mp3',
        ),
      ],
    ),
    'ar.abdurrahmaansudais': ReciterAudioProfile(
      sources: [
        ReciterAudioSource(
          ayahBase: 'https://audio.qurancdn.com/Sudais/mp3',
          ayahTemplate: _tarteelAyahTemplate,
        ),
      ],
    ),
    'ar.minshawy_kids_repeat': ReciterAudioProfile(
      sources: [
        ReciterAudioSource(
          surahBase:
              'https://download.quranicaudio.com/qdc/siddiq_minshawi/kids_repeat',
          surahTemplate: '{surah}.mp3',
        ),
      ],
    ),
    'ar.noreen_siddiq': ReciterAudioProfile(
      sources: [
        ReciterAudioSource(
          surahBase: 'https://download.quranicaudio.com/quran/noreen_siddiq/',
          surahTemplate: '{surah:000}.mp3',
        ),
      ],
    ),
  };

  static final Map<String, int> _preferredSourceIndexByReciterId = {};

  static int? preferredSourceIndexForReciter(String reciterId) {
    return _preferredSourceIndexByReciterId[reciterId];
  }

  static void setPreferredSourceIndexForReciter(
    String reciterId,
    int? sourceIndex,
  ) {
    if (sourceIndex == null) {
      _preferredSourceIndexByReciterId.remove(reciterId);
      return;
    }
    _preferredSourceIndexByReciterId[reciterId] = sourceIndex;
  }

  static Map<String, ReciterAudioProfile> _tarteelVerseByVerseProfiles(
      Map<String, String> reciterIdToFolder,
      {List<ReciterAudioSource> Function(String reciterId)? extraSources}) {
    return reciterIdToFolder.map(
      (reciterId, folder) => MapEntry(
        reciterId,
        ReciterAudioProfile(
          sources: [
            ReciterAudioSource(
              ayahBase: '$_tarteelQuranBase/$folder',
              ayahTemplate: _tarteelAyahTemplate,
            ),
            ...?extraSources?.call(reciterId),
          ],
        ),
      ),
    );
  }

  static ReciterAudioProfile? forReciter(String reciterId) {
    return byReciterId[reciterId];
  }
}
