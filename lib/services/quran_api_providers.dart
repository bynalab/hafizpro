class QuranApiProviders {
  static const List<String> baseUrls = [
    'https://api.alquran.cloud/v1/',
    // Fallback proxy (useful for ISPs that block api.alquran.cloud; VPN works but direct doesn't).
    // Note: Surah/Ayah services build `path` like 'surah/1/quran-uthmani', so we include a trailing
    // slash after `path=` to produce `.../api/quran?path=/surah/1/...`.
    'https://quran-proxy-steel.vercel.app/api/quran?path=/',
  ];
}
