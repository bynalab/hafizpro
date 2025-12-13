import 'package:hafiz_test/model/surah.model.dart';

class Ayah {
  final int number;
  final String audio;
  final List<String> audioSecondary;
  final String text;
  final String? translation;
  final int numberInSurah;
  final int juz;
  final int manzil;
  final int page;
  final int ruku;
  final int hizbQuarter;
  final Surah? surah;
  // final bool sajda;

  Ayah({
    this.number = 0,
    this.audio = '',
    this.audioSecondary = const [],
    this.text = '',
    this.translation,
    this.numberInSurah = 0,
    this.juz = 0,
    this.manzil = 0,
    this.page = 0,
    this.ruku = 0,
    this.hizbQuarter = 0,
    this.surah,
    // this.sajda = false,
  });

  factory Ayah.fromJson(Map<String, dynamic> json) {
    return Ayah(
      number: json['number'],
      audio: json['audio'] ?? '',
      audioSecondary: ((json['audioSecondary'] ?? []) as List).cast<String>(),
      text: json['text'],
      translation: (json['translation'] ??
              json['textTranslation'] ??
              json['englishTranslation'])
          ?.toString(),
      numberInSurah: json['numberInSurah'],
      juz: json['juz'],
      manzil: json['manzil'],
      page: json['page'],
      ruku: json['ruku'],
      hizbQuarter: json['hizbQuarter'],
      surah: Surah.fromJson(json['surah'] ?? {}),
      // sajda: json['sajda'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'audio': audio,
      'audioSecondary': audioSecondary,
      'text': text,
      'translation': translation,
      'numberInSurah': numberInSurah,
      'juz': juz,
      'manzil': manzil,
      'page': page,
      'ruku': ruku,
      'hizbQuarter': hizbQuarter,
      'surah': surah,
      // 'sajda': sajda,
    };
  }

  @override
  String toString() {
    return toJson().toString();
  }

  static List<Ayah> fromJsonList(List jsonList) {
    return jsonList.map((json) => Ayah.fromJson(json)).toList();
  }

  static List<Map<String, dynamic>> toJsonList(List<Ayah> ayahList) {
    return ayahList.map((ayah) => ayah.toJson()).toList();
  }
}
