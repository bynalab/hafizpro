class PlaybackSnapshot {
  final int surahNumber;
  final String surahName;
  final int index;
  final Duration position;

  const PlaybackSnapshot({
    required this.surahNumber,
    required this.surahName,
    required this.index,
    required this.position,
  });
}
