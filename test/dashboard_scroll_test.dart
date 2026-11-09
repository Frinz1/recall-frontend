import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/services/study_repository.dart';
import 'package:recall/features/dashboard/dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StudyRepository.instance.clearLocalState();
  });

  testWidgets('Dashboard scrolls when the swipe starts on the "No Flashcard Decks Yet" empty state',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: DashboardScreen(onNavigateToDecks: () {}, onNavigateToSettings: () {}),
    ));
    await tester.pumpAndSettle();

    final emptyTitle = find.text('No Flashcard Decks Yet');
    await tester.scrollUntilVisible(emptyTitle, 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    // Only the Dashboard's own scroll view should exist around the empty state (no nested scroller).
    final nestedScrollers = find.descendant(
      of: find.ancestor(of: emptyTitle, matching: find.byType(Container)).first,
      matching: find.byType(Scrollable),
    );
    expect(nestedScrollers, findsNothing);

    final before = tester.getTopLeft(emptyTitle).dy;
    await tester.drag(emptyTitle, const Offset(0, 250)); // swipe down, starting on the empty state
    await tester.pumpAndSettle();
    final after = tester.getTopLeft(emptyTitle).dy;

    expect(after, greaterThan(before), reason: 'Swipe on the empty state must scroll the Dashboard');
  });
}
