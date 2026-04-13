import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocaviz/data/models/history_entry.dart';
import 'package:vocaviz/services/history_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HistoryService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      // Clear history before each test
      await HistoryService.clearHistory();
    });

    tearDown(() async {
      // Clean up after tests
      await HistoryService.clearHistory();
    });

    test('getHistory returns empty list initially', () async {
      final history = await HistoryService.getHistory();
      expect(history, isEmpty);
    });

    test('addEntry adds entry to history', () async {
      final entry = HistoryEntry(
        id: 'test-1',
        timestamp: DateTime.now(),
        issueType: 'loose_belt',
        confidence: 0.85,
        summary: 'Test entry',
      );

      await HistoryService.addEntry(entry);
      final history = await HistoryService.getHistory();

      expect(history.length, 1);
      expect(history.first.id, 'test-1');
    });

    test('addEntry sorts by timestamp newest first', () async {
      final oldEntry = HistoryEntry(
        id: 'old',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        issueType: 'loose_belt',
        confidence: 0.8,
        summary: 'Old',
      );

      final newEntry = HistoryEntry(
        id: 'new',
        timestamp: DateTime.now(),
        issueType: 'worn_belt',
        confidence: 0.9,
        summary: 'New',
      );

      await HistoryService.addEntry(oldEntry);
      await HistoryService.addEntry(newEntry);

      final history = await HistoryService.getHistory();

      expect(history.length, 2);
      expect(history.first.id, 'new');
      expect(history.last.id, 'old');
    });

    test('addEntry trims to max entries', () async {
      // Add 55 entries (max is 50)
      for (int i = 0; i < 55; i++) {
        final entry = HistoryEntry(
          id: 'entry-$i',
          timestamp: DateTime.now().subtract(Duration(minutes: i)),
          issueType: 'loose_belt',
          confidence: 0.8,
          summary: 'Entry $i',
        );
        await HistoryService.addEntry(entry);
      }

      final history = await HistoryService.getHistory();
      expect(history.length, 50);
      expect(history.first.id, 'entry-0'); // newest
      expect(history.last.id, 'entry-49'); // oldest retained after trim
    });

    test('getLastEntry returns most recent entry', () async {
      final entry1 = HistoryEntry(
        id: 'first',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        issueType: 'loose_belt',
        confidence: 0.8,
        summary: 'First',
      );

      final entry2 = HistoryEntry(
        id: 'second',
        timestamp: DateTime.now(),
        issueType: 'worn_belt',
        confidence: 0.9,
        summary: 'Second',
      );

      await HistoryService.addEntry(entry1);
      await HistoryService.addEntry(entry2);

      final last = await HistoryService.getLastEntry();

      expect(last?.id, 'second');
    });

    test('getLastEntry returns null when empty', () async {
      final last = await HistoryService.getLastEntry();
      expect(last, isNull);
    });

    test('markRepairCompleted updates entry', () async {
      final entry = HistoryEntry(
        id: 'repair-test',
        timestamp: DateTime.now(),
        issueType: 'loose_belt',
        confidence: 0.8,
        summary: 'Test',
        completedRepair: false,
      );

      await HistoryService.addEntry(entry);
      await HistoryService.markRepairCompleted('repair-test');

      final history = await HistoryService.getHistory();
      expect(history.first.completedRepair, true);
    });

    test('markRepairCompleted does nothing for non-existent entry', () async {
      // Should not throw
      await HistoryService.markRepairCompleted('non-existent');
    });

    test('deleteEntry removes entry', () async {
      final entry1 = HistoryEntry(
        id: 'to-delete',
        timestamp: DateTime.now(),
        issueType: 'loose_belt',
        confidence: 0.8,
        summary: 'Delete me',
      );

      final entry2 = HistoryEntry(
        id: 'to-keep',
        timestamp: DateTime.now(),
        issueType: 'worn_belt',
        confidence: 0.9,
        summary: 'Keep me',
      );

      await HistoryService.addEntry(entry1);
      await HistoryService.addEntry(entry2);
      await HistoryService.deleteEntry('to-delete');

      final history = await HistoryService.getHistory();
      expect(history.length, 1);
      expect(history.first.id, 'to-keep');
    });

    test('deleteEntry does nothing for non-existent entry', () async {
      // Should not throw
      await HistoryService.deleteEntry('non-existent');
    });

    test('clearHistory removes all entries', () async {
      final entry1 = HistoryEntry(
        id: '1',
        timestamp: DateTime.now(),
        issueType: 'loose_belt',
        confidence: 0.8,
        summary: 'Test 1',
      );

      final entry2 = HistoryEntry(
        id: '2',
        timestamp: DateTime.now(),
        issueType: 'worn_belt',
        confidence: 0.9,
        summary: 'Test 2',
      );

      await HistoryService.addEntry(entry1);
      await HistoryService.addEntry(entry2);
      await HistoryService.clearHistory();

      final history = await HistoryService.getHistory();
      expect(history, isEmpty);
    });

    test('updateEntry modifies existing entry', () async {
      final entry = HistoryEntry(
        id: 'update-test',
        timestamp: DateTime.now(),
        issueType: 'loose_belt',
        confidence: 0.8,
        summary: 'Original',
      );

      await HistoryService.addEntry(entry);

      final updated = entry.copyWith(
        confidence: 0.95,
        summary: 'Updated summary',
      );

      await HistoryService.updateEntry('update-test', updated);

      final history = await HistoryService.getHistory();
      expect(history.first.confidence, 0.95);
      expect(history.first.summary, 'Updated summary');
    });
  });
}
