import 'package:flutter_test/flutter_test.dart';
import 'package:vocaviz/app/app.dart';

void main() {
  testWidgets('App loads and shows onboarding', (WidgetTester tester) async {
    await tester.pumpWidget(const VocaVizApp());

    // Verify onboarding screen appears
    expect(find.text('VocaViz'), findsOneWidget);
    expect(find.text('Point & Analyze'), findsOneWidget);
  });

  testWidgets('Onboarding has Get Started button on last page', (WidgetTester tester) async {
    await tester.pumpWidget(const VocaVizApp());

    // Navigate through onboarding pages
    for (int i = 0; i < 3; i++) {
      expect(find.text('Next'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }

    // Last page should have 'Get Started'
    expect(find.text('Get Started'), findsOneWidget);
  });
}
