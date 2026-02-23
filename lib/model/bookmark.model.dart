import 'package:hafiz_test/model/ayah.model.dart';
import 'package:hafiz_test/model/surah.model.dart';

enum BookmarkViewContext { surah, juz }

class Bookmark {
  final Surah surah;
  final Ayah ayah;
  final int? juzNumber;
  final BookmarkViewContext viewContext;
  final DateTime timestamp;

  Bookmark({
    required this.surah,
    required this.ayah,
    this.juzNumber,
    required this.viewContext,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'surah': surah.toJson(),
        'ayah': ayah.toJson(),
        'juzNumber': juzNumber,
        'viewContext': viewContext.index,
        'timestamp': timestamp.toIso8601String(),
      };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
        surah: Surah.fromJson(json['surah']),
        ayah: Ayah.fromJson(json['ayah']),
        juzNumber: json['juzNumber'],
        viewContext: BookmarkViewContext.values[json['viewContext'] ?? 0],
        timestamp: DateTime.parse(
            json['timestamp'] ?? DateTime.now().toIso8601String()),
      );
}
