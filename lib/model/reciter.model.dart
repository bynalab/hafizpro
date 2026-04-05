class Reciter {
  final String identifier;
  final String language;
  final String name;
  final String englishName;
  final String format;
  final String type;
  final String? direction;

  bool get isVerseByVerse => type == 'versebyverse';
  bool get isSurahBySurah => type == 'surahbysurah';

  Reciter({
    required this.identifier,
    required this.language,
    required this.name,
    required this.englishName,
    required this.format,
    required this.type,
    this.direction,
  });

  factory Reciter.fromJson(Map<String, dynamic> json) {
    return Reciter(
      identifier: json['identifier'],
      language: json['language'],
      name: json['name'],
      englishName: json['englishName'],
      format: json['format'],
      type: json['type'],
      direction: json['direction'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'language': language,
      'name': name,
      'englishName': englishName,
      'format': format,
      'type': type,
      'direction': direction,
    };
  }

  static List<Reciter> fromJsonList(List<dynamic> list) {
    return list.map((json) => Reciter.fromJson(json)).toList();
  }
}
