import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocaviz/data/models/history_entry.dart';
import 'package:vocaviz/features/history/history_screen.dart';
import 'package:vocaviz/services/history_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await HistoryService.clearHistory();
  });

  testWidgets('shows empty state when history is empty', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HistoryScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No Inspection History'), findsOneWidget);
    expect(find.text('Your past inspections will appear here'), findsOneWidget);
  });

  testWidgets('shows history entries and opens details sheet on tap', (tester) async {
    await HistoryService.addEntry(
      HistoryEntry(
        id: 'entry-1',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        issueType: 'loose_belt',
        confidence: 0.84,
        summary: 'Loose belt found near main pulley',
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: HistoryScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Loose Belt'), findsOneWidget);
    expect(find.text('84%'), findsOneWidget);

    await tester.tap(find.text('Loose Belt'));
    await tester.pumpAndSettle();

    expect(find.text('Summary'), findsOneWidget);
    expect(find.text('Loose belt found near main pulley'), findsOneWidget);
  });
}
