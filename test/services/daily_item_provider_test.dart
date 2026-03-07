import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_test/services/daily_item_provider.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:mocktail/mocktail.dart';

class MockStorage extends Mock implements IStorageService {}

void main() {
  late DailyItemProvider<String> provider;
  late MockStorage storage;
  final Map<String, String> memoryStorage = {};
  final List<String> testItems = ['A', 'B', 'C', 'D', 'E'];

  setUp(() {
    storage = MockStorage();
    memoryStorage.clear();

    when(() => storage.getString(any())).thenAnswer((invocation) {
      final key = invocation.positionalArguments[0] as String;
      return memoryStorage[key];
    });

    when(() => storage.setString(any(), any())).thenAnswer((invocation) async {
      final key = invocation.positionalArguments[0] as String;
      final val = invocation.positionalArguments[1] as String;
      memoryStorage[key] = val;
      return true;
    });

    provider = DailyItemProvider<String>(
      items: testItems,
      storage: storage,
      key: 'test',
    );
  });

  group('DailyItemProvider', () {
    test('should return different items for different days', () async {
      final day1 = DateTime(2026, 3, 6);
      final day2 = DateTime(2026, 3, 7);

      final item1 = await provider.getItem(date: day1);
      final item2 = await provider.getItem(date: day2);

      expect(item1, isNot(equals(item2)));
      expect(testItems.contains(item1), isTrue);
      expect(testItems.contains(item2), isTrue);
    });

    test('should be idempotent for the same day', () async {
      final day = DateTime(2026, 3, 6);

      final item1 = await provider.getItem(date: day);
      final item2 = await provider.getItem(date: day);

      expect(item1, equals(item2));
    });

    test('should cycle correctly', () async {
      final startDay = DateTime(2026, 3, 6);
      final Set<String> results = {};

      for (int i = 0; i < testItems.length; i++) {
        results
            .add(await provider.getItem(date: startDay.add(Duration(days: i))));
      }

      expect(results.length, equals(testItems.length));

      // Day total + 1 should match Day 1
      final itemStart = await provider.getItem(date: startDay);
      final itemAfterCycle = await provider.getItem(
          date: startDay.add(Duration(days: testItems.length)));
      expect(itemStart, equals(itemAfterCycle));
    });

    test('is deterministic with the same offset', () async {
      const offset = 2;
      final day = DateTime(2026, 3, 6);

      memoryStorage['daily_item_test_offset'] = offset.toString();

      final item1 = await provider.getItem(date: day);

      // Clear and re-force offset
      memoryStorage.clear();
      memoryStorage['daily_item_test_offset'] = offset.toString();

      final item2 = await provider.getItem(date: day);

      expect(item1, equals(item2));
    });
  });
}
