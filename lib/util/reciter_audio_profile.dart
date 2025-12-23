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

  static const String _islamicNetworkBase =
      'https://cdn.islamic.network/quran/audio';

  static String _islamicNetworkBitrateBase(int bitrate) {
    return '$_islamicNetworkBase/$bitrate';
  }

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
              ayahBase: '${_islamicNetworkBitrateBase(128)}/ar.alafasy',
              ayahTemplate: '{ayahGlobal}.mp3',
            ),
          ];
        }

        if (reciterId == 'ar.saoodshuraym') {
          return [
            ReciterAudioSource(
              ayahBase: '${_islamicNetworkBitrateBase(64)}/ar.saoodshuraym',
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
          ayahBase: '${_islamicNetworkBitrateBase(192)}/ar.abdullahbasfar',
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

    // islamic.network verse-by-verse profiles (global ayah id filenames)
    'ar.hudhaify': ReciterAudioProfile(
      sources: [
        ReciterAudioSource(
          ayahBase: '${_islamicNetworkBitrateBase(128)}/ar.hudhaify',
          ayahTemplate: '{ayahGlobal}.mp3',
        ),
        ReciterAudioSource(
          ayahBase: '${_islamicNetworkBitrateBase(64)}/ar.hudhaify',
          ayahTemplate: '{ayahGlobal}.mp3',
        ),
        ReciterAudioSource(
          ayahBase: '${_islamicNetworkBitrateBase(32)}/ar.hudhaify',
          ayahTemplate: '{ayahGlobal}.mp3',
        ),
      ],
    ),
    'ar.ibrahimakhbar': ReciterAudioProfile(
      sources: [
        ReciterAudioSource(
          ayahBase: '${_islamicNetworkBitrateBase(32)}/ar.ibrahimakhbar',
          ayahTemplate: '{ayahGlobal}.mp3',
        ),
      ],
    ),
    'ar.mahermuaiqly': ReciterAudioProfile(
      sources: [
        ReciterAudioSource(
          ayahBase: '${_islamicNetworkBitrateBase(128)}/ar.mahermuaiqly',
          ayahTemplate: '{ayahGlobal}.mp3',
        ),
        ReciterAudioSource(
          ayahBase: '${_islamicNetworkBitrateBase(64)}/ar.mahermuaiqly',
          ayahTemplate: '{ayahGlobal}.mp3',
        ),
      ],
    ),
    'ar.minshawi': ReciterAudioProfile(
      sources: [
        ReciterAudioSource(
          ayahBase: '${_islamicNetworkBitrateBase(128)}/ar.minshawi',
          ayahTemplate: '{ayahGlobal}.mp3',
        ),
      ],
    ),
    'ar.minshawimujawwad': ReciterAudioProfile(
      sources: [
        ReciterAudioSource(
          ayahBase: '${_islamicNetworkBitrateBase(64)}/ar.minshawimujawwad',
          ayahTemplate: '{ayahGlobal}.mp3',
        ),
      ],
    ),
    'ar.muhammadayyoub': ReciterAudioProfile(
      sources: [
        ReciterAudioSource(
          ayahBase: '${_islamicNetworkBitrateBase(128)}/ar.muhammadayyoub',
          ayahTemplate: '{ayahGlobal}.mp3',
        ),
      ],
    ),
    'ar.muhammadjibreel': ReciterAudioProfile(
      sources: [
        ReciterAudioSource(
          ayahBase: '${_islamicNetworkBitrateBase(128)}/ar.muhammadjibreel',
          ayahTemplate: '{ayahGlobal}.mp3',
        ),
      ],
    ),
    'ar.parhizgar': ReciterAudioProfile(
      sources: [
        ReciterAudioSource(
          ayahBase: '${_islamicNetworkBitrateBase(48)}/ar.parhizgar',
          ayahTemplate: '{ayahGlobal}.mp3',
        ),
      ],
    ),
    'ar.aymanswoaid': ReciterAudioProfile(
      sources: [
        ReciterAudioSource(
          ayahBase: '${_islamicNetworkBitrateBase(64)}/ar.aymanswoaid',
          ayahTemplate: '{ayahGlobal}.mp3',
        ),
      ],
    ),
    'ur.khan': ReciterAudioProfile(
      sources: [
        ReciterAudioSource(
          ayahBase: '${_islamicNetworkBitrateBase(64)}/ur.khan',
          ayahTemplate: '{ayahGlobal}.mp3',
        ),
      ],
    ),
    'zh.chinese': ReciterAudioProfile(
      sources: [
        ReciterAudioSource(
          ayahBase: '${_islamicNetworkBitrateBase(128)}/zh.chinese',
          ayahTemplate: '{ayahGlobal}.mp3',
        ),
      ],
    ),
    'fr.leclerc': ReciterAudioProfile(
      sources: [
        ReciterAudioSource(
          ayahBase: '${_islamicNetworkBitrateBase(128)}/fr.leclerc',
          ayahTemplate: '{ayahGlobal}.mp3',
        ),
      ],
    ),
    'fa.hedayatfarfooladvand': ReciterAudioProfile(
      sources: [
        ReciterAudioSource(
          ayahBase: '${_islamicNetworkBitrateBase(40)}/fa.hedayatfarfooladvand',
          ayahTemplate: '{ayahGlobal}.mp3',
        ),
      ],
    ),
    'ru.kuliev-audio': ReciterAudioProfile(
      sources: [
        ReciterAudioSource(
          ayahBase: '${_islamicNetworkBitrateBase(128)}/ru.kuliev-audio',
          ayahTemplate: '{ayahGlobal}.mp3',
        ),
      ],
    ),
    'ru.kuliev-audio-2': ReciterAudioProfile(
      sources: [
        ReciterAudioSource(
          ayahBase: '${_islamicNetworkBitrateBase(320)}/ru.kuliev-audio-2',
          ayahTemplate: '{ayahGlobal}.mp3',
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
