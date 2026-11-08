import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recall/app.dart';
import 'package:recall/core/services/study_repository.dart';
import 'package:recall/core/theme/app_colors.dart';
import 'package:recall/core/widgets/quick_create_sheet.dart';
import 'package:recall/features/subject/subject_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StudyRepository.instance.clearLocalState();
  });

  testWidgets('Recall app smoke test boots cleanly without leaking timers',
      (WidgetTester tester) async {
    await tester.pumpWidget(const RecallApp());
    expect(find.text('Recall'), findsWidgets);
  });

  test('AppColors.resolveBentoGradient returns distinct rich gradients for all 6 Bento themes', () {
    for (final option in AppColors.bentoThemeOptions) {
      final gradient = AppColors.resolveBentoGradient(option.value);
      final accent = AppColors.resolveBentoAccent(option.value);
      expect(gradient.colors.length, 2);
      expect(gradient.colors.first, isNot(equals(gradient.colors.last)));
      expect(accent.a, 1.0);
    }

    // Fallback custom hex color
    final fallbackGradient = AppColors.resolveBentoGradient(0xFF14B8A6);
    expect(fallbackGradient.colors.length, 2);
  });

  testWidgets(
      'MainNavigationShell renders Sculpted Center Action Cradle and opens QuickCreateSheet',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MainNavigationShell(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify 4 dock tabs exist
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Decks'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Verify Dashboard Hero & 7-Day Capsule Strip
    expect(find.text('DAILY SM-2 SCHEDULE'), findsOneWidget);
    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Sun'), findsOneWidget);

    // Verify no redundant tune/settings icon button on Dashboard AppBar
    expect(find.byIcon(Icons.tune_rounded), findsNothing);

    // Tap the Center + Cradle button in the sculpted dock
    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pumpAndSettle();

    // Verify Unified QuickCreateSheet opens with 2-pill switcher
    expect(find.text('Create Workspace Item'), findsOneWidget);
    expect(find.text('New Deck'), findsOneWidget);
    expect(find.text('New Subject'), findsOneWidget);

    // Switch to New Subject tab and create a subject
    await tester.tap(find.text('New Subject'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Cybersecurity');
    await tester.pumpAndSettle();

    // Select Lavender palette
    await tester.ensureVisible(find.text('Lavender'));
    await tester.tap(find.text('Lavender'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Create Subject'));
    await tester.tap(find.text('Create Subject'));
    await tester.pumpAndSettle();

    expect(StudyRepository.instance.subjects.length, 1);
    expect(StudyRepository.instance.subjects.first.name, 'Cybersecurity');
    expect(
      StudyRepository.instance.subjects.first.colorValue,
      AppColors.themeSoftLavender,
    );
  });

  testWidgets('QuickCreateSheet creates a Bento-themed Deck and displays it on DeckListScreen',
      (WidgetTester tester) async {
    await StudyRepository.instance.addSubject(
      name: 'Networking',
      colorValue: AppColors.themeElectricOcean,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: MainNavigationShell(),
      ),
    );
    await tester.pumpAndSettle();

    // Navigate to Decks tab
    await tester.tap(find.text('Decks'));
    await tester.pumpAndSettle();

    // Open QuickCreateSheet via Center Cradle
    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(1), 'BGP & OSPF Routing');
    await tester.enterText(
      find.byType(TextField).at(2),
      'Autonomous system path vector and link-state protocols',
    );
    await tester.ensureVisible(find.text('Sage'));
    await tester.tap(find.text('Sage'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Create Deck'));
    await tester.tap(find.text('Create Deck'));
    await tester.pumpAndSettle();

    expect(StudyRepository.instance.decks.length, 1);
    expect(StudyRepository.instance.decks.first.title, 'BGP & OSPF Routing');
    expect(find.text('BGP & OSPF Routing'), findsWidgets);
    expect(find.textContaining('Progress •'), findsWidgets);
  });

  testWidgets('SubjectListScreen renders Bento subject cards and CurvedBottomSheet close button',
      (WidgetTester tester) async {
    await StudyRepository.instance.addSubject(
      name: 'Operating Systems',
      colorValue: AppColors.themeWarmAmber,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: SubjectListScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Operating Systems'), findsOneWidget);
    expect(find.textContaining('Progress •'), findsOneWidget);

    // Tap New Subject button in SubjectListScreen AppBar
    await tester.tap(find.text('New Subject'));
    await tester.pumpAndSettle();

    expect(find.byType(QuickCreateSheet), findsOneWidget);

    // Tap the top-center circular close (✕) button on CurvedBottomSheet
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(QuickCreateSheet), findsNothing);
  });

  testWidgets(
      'Compact 360x800 mobile viewport renders Dashboard, Decks, and keyboard-raised QuickCreateSheet with zero overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
    });

    StudyRepository.instance.setActiveUser('user_mobile_test');
    await StudyRepository.instance.addSubject(
      name: 'Networking & Cloud Infrastructure',
      colorValue: AppColors.themeElectricOcean,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: MainNavigationShell(),
      ),
    );
    await tester.pumpAndSettle();

    // Open QuickCreateSheet on 360x800 with software keyboard raised (viewInsets.bottom = 320)
    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pumpAndSettle();

    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pumpAndSettle();

    // Toggle inline + Quick Subject and verify validation when left blank
    await tester.tap(find.text('+ Quick Subject'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Clinical Pharmacology');
    await tester.ensureVisible(find.text('Create Deck'));
    await tester.tap(find.text('Create Deck'));
    await tester.pumpAndSettle();

    expect(
      find.text('Please enter a new subject name or select an existing subject.'),
      findsOneWidget,
    );

    // Wait for error snackbar to clear or enter quick subject name and create deck
    await tester.enterText(find.byType(TextField).at(2), 'Pharmacology');
    await tester.ensureVisible(find.text('Create Deck'));
    await tester.tap(find.text('Create Deck'));
    await tester.pumpAndSettle();

    // Verify both the new subject and deck were created AND ToastFeedback was shown
    expect(StudyRepository.instance.subjects.any((s) => s.name == 'Pharmacology'), isTrue);
    expect(StudyRepository.instance.decks.first.title, 'Clinical Pharmacology');
    expect(find.text('Deck "Clinical Pharmacology" created and synced!'), findsOneWidget);

    tester.view. resetViewInsets();
    await tester.pumpAndSettle();

    // Navigate to Decks tab on 360x800 and filter by subject, then delete subject
    await tester.tap(find.text('Decks'));
    await tester.pumpAndSettle();

    expect(find.text('Clinical Pharmacology'), findsWidgets);

    // Add a deck under the first subject so we can verify filtering vs All Decks recovery
    final netSub = StudyRepository.instance.subjects
        .firstWhere((s) => s.name == 'Networking & Cloud Infrastructure');
    await StudyRepository.instance.addDeck(
      title: 'TCP/IP Congestion Control',
      description: 'Slow start, AIMD, and BBR',
      subjectId: netSub.id,
      colorValue: AppColors.themeElectricOcean,
    );
    await tester.pumpAndSettle();

    // Filter by Pharmacology chip (so TCP/IP Congestion Control is hidden)
    await tester.ensureVisible(find.widgetWithText(FilterChip, 'Pharmacology'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Pharmacology'));
    await tester.pumpAndSettle();
    expect(find.text('TCP/IP Congestion Control'), findsNothing);

    // Delete Pharmacology subject and verify DeckListScreen automatically recovers filter to All Decks
    final pharmSub = StudyRepository.instance.subjects.firstWhere((s) => s.name == 'Pharmacology');
    await StudyRepository.instance.deleteSubject(pharmSub.id);
    await tester.pumpAndSettle();

    expect(find.text('TCP/IP Congestion Control'), findsOneWidget);

    // Also visit Stats and Settings tabs on 360x800 to confirm zero overflow
    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    expect(find.text('Weekly Study Consistency'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Daily Review Goal'), findsOneWidget);
  });
}
