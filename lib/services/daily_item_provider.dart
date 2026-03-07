import 'dart:math';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';

/// A generic provider that returns one item per day from a list.
/// It uses a stored offset to give a unique sequence per user.
class DailyItemProvider<T> {
  final List<T> items;
  final IStorageService _storage;
  final String _key;
  final Random _random = Random();

  DailyItemProvider({
    required this.items,
    required IStorageService storage,
    required String key,
  })  : _storage = storage,
        _key = key;

  String get _offsetKey => 'daily_item_${_key}_offset';

  /// Returns the item for a specific date (defaults to today).
  /// Providing a date is useful for scheduling future notifications.
  Future<T> getItem({DateTime? date}) async {
    if (items.isEmpty) {
      throw Exception('DailyItemProvider: items list is empty');
    }

    final targetDate = date ?? DateTime.now();
    final n = items.length;

    int? offset = _storage.getInt(_offsetKey);
    if (offset == null) {
      offset = _random.nextInt(n);
      await _storage.setInt(_offsetKey, offset);
    }

    final days =
        targetDate.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    final index = (days + offset) % n;

    return items[index];
  }
}
