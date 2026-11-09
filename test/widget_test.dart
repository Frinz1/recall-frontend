import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recall/app.dart';
import 'package:recall/core/algorithms/sm2_engine.dart';
import 'package:recall/core/models/flashcard_model.dart';
import 'package:recall/core/services/study_repository.dart';
import 'package:recall/core/theme/app_colors.dart';
import 'package:recall/core/theme/theme_service.dart';
import 'package:recall/core/widgets/curved_bottom_sheet.dart';
import 'package:recall/core/widgets/app_button.dart';
import 'package:recall/core/widgets/quick_create_sheet.dart';
import 'package:recall/features/auth/auth_screen.dart';
import 'package:recall/features/deck/deck_detail_screen.dart';
import 'package:recall/features/quiz/quiz_screen.dart';
import 'package:recall/features/settings/settings_screen.dart';
import 'package:recall/features/splash/splash_screen.dart';
import 'package:recall/features/study/widgets/flip_card_widget.dart';
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

  test('Flashcard.fromJson converts UTC timestamps to local timezone', () {
    final card = Flashcard.fromJson({
      'id': 'c1',
      'deckId': 'd1',
      'question': 'What is BGP path vector routing?',
      'answer': 'Autonomous system border routing protocol.',
      'nextReviewDate': '2026-11-08T22:37:00.000Z',
      'lastReviewedDate': '2026-11-08T22:37:00.000Z',
      'timesReviewed': 2,
      'masteryStatus': 'learning',
    });

    expect(card.nextReviewDate.isUtc, isFalse);
    expect(card.lastReviewedDate, isNotNull);
    expect(card.lastReviewedDate!.isUtc, isFalse);
  });

  testWidgets(
      'Dashboard Hero Banner reflects remaining Daily Goal and unmastered cards instead of falsely showing All Caught Up',
      (WidgetTester tester) async {
    final repo = StudyRepository.instance;
    repo.setActiveUser('user_goal_test');
    await repo.setDailyGoalCards(30);

    final sub = await repo.addSubject(
      name: 'Systems Programming',
      colorValue: AppColors.themeRoyalIndigo,
    );
    final deck = await repo.addDeck(
      title: 'Virtual Memory & Paging',
      description: 'TLB shootdowns and page tables',
      subjectId: sub!.id,
      colorValue: AppColors.themeRoyalIndigo,
    );
    await repo.addCardToDeck(
      deckId: deck!.id,
      question: 'Why does a TLB miss trigger a page table walk?',
      answer: 'Because the virtual-to-physical translation is not cached in the TLB.',
      explanation: 'Multi-level page tables reduce memory overhead for sparse address spaces.',
      tags: const ['MMU', 'TLB'],
      cardType: FlashcardType.standard,
    );

    final cardId = repo.decks.first.cards.first.id;
    // Review card with Good (moves nextReviewDate to tomorrow, masteryStatus remains learning, reviewedToday = 1)
    await repo.recordCardReview(
      deckId: deck.id,
      cardId: cardId,
      rating: RecallRating.good,
    );

    expect(repo.totalDueCardsCount, 0);
    expect(repo.totalUnmasteredCardsCount, 1);
    expect(repo.reviewedTodayCount, 1);

    await tester.pumpWidget(
      const MaterialApp(
        home: MainNavigationShell(),
      ),
    );
    await tester.pumpAndSettle();

    // Hero Banner must NOT say "All Caught Up Today!" when 29 cards remain for the 30-card goal
    expect(find.text('All Caught Up Today!'), findsNothing);
    expect(find.text('29 Cards Left for Daily Goal'), findsOneWidget);
    expect(find.textContaining('Continue Goal Review'), findsOneWidget);
    // Bento Deck Card must show "1 learning" instead of "All caught up"
    expect(find.text('1 learning'), findsOneWidget);
    expect(find.text('All caught up'), findsNothing);
  });

  testWidgets(
      'Kinetic SplashScreen runs slide-in, bounce, and radial reveal without STUDY TIP clutter',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
      ),
    );

    // Verify no legacy STUDY TIP box
    expect(find.text('STUDY TIP'), findsNothing);
    expect(find.text('Recall'), findsOneWidget);

    // Advance through slide-in (0.30), center bounce (0.50), and dark reveal (0.85)
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 1600));
    expect(find.text('Study smarter, remember longer.'), findsOneWidget);
  });

  testWidgets(
      'AuthScreen renders single-layer input fields and Redesigned FlipCardWidget flips cleanly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AuthScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));

    // Switch to Create Account
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(3));

    // Test Redesigned FlipCardWidget
    bool flipped = false;
    final sampleCard = Flashcard(
      id: 'card_flip_1',
      deckId: 'deck_1',
      question: 'What is the time complexity of B+Tree point lookup?',
      answer: 'O(log_b N) where b is the branching factor.',
      explanation: 'High fan-out keeps tree height between 3 and 4 levels.',
      tags: const ['Database', 'Indexing'],
      nextReviewDate: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return FlipCardWidget(
                card: sampleCard,
                isFlipped: flipped,
                onFlip: () => setState(() => flipped = !flipped),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CONCEPT • NEW'), findsOneWidget);
    expect(find.text('Tap anywhere to reveal answer'), findsOneWidget);
    expect(find.text('QUESTION PROMPT'), findsNothing);

    await tester.tap(find.byType(FlipCardWidget));
    await tester.pumpAndSettle();

    expect(find.text('VERIFIED ANSWER'), findsOneWidget);
    expect(find.textContaining('O(log_b N)'), findsOneWidget);
    expect(find.textContaining('High fan-out'), findsOneWidget);
  });

  testWidgets(
      'Repeated reviews in Continue Goal Review mode transition Hero Banner to Cards Still Learning and All Caught Up, and resetAllProgress clears lastReviewedDate & reviewedTodayCount',
      (WidgetTester tester) async {
    final repo = StudyRepository.instance;
    repo.setActiveUser('user_edge_cases');
    await repo.setDailyGoalCards(5);

    final sub = await repo.addSubject(
      name: 'Distributed Systems',
      colorValue: AppColors.themeSageEmerald,
    );
    final deck = await repo.addDeck(
      title: 'Raft & Paxos Consensus',
      description: 'Leader election and log replication',
      subjectId: sub!.id,
      colorValue: AppColors.themeSageEmerald,
    );
    await repo.addCardToDeck(
      deckId: deck!.id,
      question: 'What guarantees safety across network partitions in Raft?',
      answer: 'Quorum intersection requiring a majority of voting nodes.',
      explanation: 'At most one leader can be elected per term.',
      tags: const ['Consensus', 'Raft'],
      cardType: FlashcardType.standard,
    );
    await repo.addCardToDeck(
      deckId: deck.id,
      question: 'What is a split vote in Raft leader election?',
      answer: 'Multiple candidates split votes so no candidate achieves a majority.',
      explanation: 'Resolved via randomized election timeouts.',
      tags: const ['Consensus'],
      cardType: FlashcardType.standard,
    );

    final cards = repo.decks.first.cards;
    final c1Id = cards[0].id;
    final c2Id = cards[1].id;

    // Review c1 4 times with Hard (remains unmastered/learning) and c2 once with Hard = 5 total reviews today
    for (int i = 0; i < 4; i++) {
      await repo.recordCardReview(
        deckId: deck.id,
        cardId: c1Id,
        rating: RecallRating.hard,
      );
    }
    await repo.recordCardReview(
      deckId: deck.id,
      cardId: c2Id,
      rating: RecallRating.hard,
    );

    // Daily goal (5) is now reached, but both cards are still unmastered
    expect(repo.reviewedTodayCount, 5);
    expect(repo.totalUnmasteredCardsCount, 2);

    await tester.pumpWidget(
      const MaterialApp(
        home: MainNavigationShell(),
      ),
    );
    await tester.pumpAndSettle();

    // Hero Banner should show "2 Cards Still Learning" because daily goal is reached (5/5) but unmastered > 0
    expect(find.text('2 Cards Still Learning'), findsOneWidget);
    expect(find.textContaining('Continue Goal Review'), findsOneWidget);

    // Now review both cards with Easy repeatedly until both reach CardMasteryStatus.mastered (repetitions >= 3, intervalDays >= 21)
    for (int i = 0; i < 4; i++) {
      await repo.recordCardReview(
        deckId: deck.id,
        cardId: c1Id,
        rating: RecallRating.easy,
      );
      await repo.recordCardReview(
        deckId: deck.id,
        cardId: c2Id,
        rating: RecallRating.easy,
      );
    }

    expect(repo.totalUnmasteredCardsCount, 0);
    expect(repo.totalMasteredCardsCount, 2);
    expect(repo.reviewedTodayCount, 13);

    await tester.pumpAndSettle();

    // Now that dailyGoal is met AND unmasteredCount == 0, Hero Banner shows "All Caught Up Today!" and Deck pill shows "100% Mastered ✨"
    expect(find.text('All Caught Up Today!'), findsOneWidget);
    expect(find.text('100% Mastered ✨'), findsOneWidget);

    // Verify resetAllProgress clears lastReviewedDate on all cards and resets reviewedTodayCount to 0
    await repo.resetAllProgress();
    expect(repo.reviewedTodayCount, 0);
    expect(repo.allCards.every((c) => c.lastReviewedDate == null), isTrue);
    expect(repo.totalUnmasteredCardsCount, 2);

    // Verify midnight boundary rollover: stale cloud count from yesterday is ignored today
    repo.debugSetCloudReviewedToday(count: 18, dateKey: '2020-01-01');
    expect(repo.reviewedTodayCount, 0);
  });

  testWidgets('ThemeService defaults to Clean White & Slate (Light Mode) and switches to Midnight Mode in SettingsScreen',
      (WidgetTester tester) async {
    await ThemeService.instance.initializeTheme();
    // Default is Light Mode
    expect(ThemeService.instance.isDarkMode, isFalse);
    expect(AppColors.isDarkMode, isFalse);
    expect(AppColors.bgCanvas, const Color(0xFFF7F5F0));
    expect(AppColors.bgCard, const Color(0xFFFFFFFF));
    expect(AppColors.textPrimary, const Color(0xFF1A1D20));

    // Render SettingsScreen
    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('APPEARANCE & THEME'), findsOneWidget);
    expect(find.text('Theme Mode'), findsOneWidget);
    expect(find.text('Clean White & Two-Tone (Light)'), findsOneWidget);

    // Tap "Midnight" pill
    final midnightPill = find.text('Midnight');
    expect(midnightPill, findsOneWidget);
    await tester.tap(midnightPill);
    await tester.pumpAndSettle();

    // Verify switch to Midnight
    expect(ThemeService.instance.isDarkMode, isTrue);
    expect(AppColors.isDarkMode, isTrue);
    expect(AppColors.bgCanvas, const Color(0xFF0F172A));
    expect(AppColors.bgCard, const Color(0xFF1E293B));
    expect(AppColors.textPrimary, const Color(0xFFF8FAFC));
    expect(find.text('Midnight Slate (OLED Dark)'), findsOneWidget);

    // Switch back to Light Mode
    final lightPill = find.text('Light');
    await tester.tap(lightPill);
    await tester.pumpAndSettle();

    expect(ThemeService.instance.isDarkMode, isFalse);
    expect(AppColors.isDarkMode, isFalse);
    expect(AppColors.bgCanvas, const Color(0xFFF7F5F0));
  });

  testWidgets('Bento Cards resolve Whisper Tints in Light Mode and Deep Jewel Tones in Dark Mode with crisp contrast',
      (WidgetTester tester) async {
    await ThemeService.instance.initializeTheme();
    expect(AppColors.isDarkMode, isFalse);

    // Light Mode checks
    final lightSageGrad = AppColors.resolveBentoGradient(AppColors.themeSageEmerald);
    expect(lightSageGrad.colors.first, const Color(0xFFF0FDF4));
    expect(lightSageGrad.colors.last, const Color(0xFFDCFCE7));
    expect(AppColors.bentoTextPrimary(), const Color(0xFF1A1D20));
    expect(AppColors.bentoPodText, const Color(0xFF1A1D20));
    expect(AppColors.bentoLaunchButtonIcon(), const Color(0xFF1A1D20));

    // Create a deck and render MainNavigationShell in Light Mode
    await StudyRepository.instance.addSubject(name: 'Algorithms', colorValue: AppColors.themeSageEmerald);
    final sub = StudyRepository.instance.subjects.first;
    await StudyRepository.instance.addDeck(
      title: 'Graph Traversal',
      description: 'BFS, DFS, Dijkstra',
      subjectId: sub.id,
      colorValue: AppColors.themeSageEmerald,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: MainNavigationShell(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify deck card rendered with launch button and progress capsule
    expect(find.text('Graph Traversal'), findsOneWidget);
    expect(find.byIcon(Icons.north_east_rounded), findsWidgets);
    expect(find.textContaining('Progress •'), findsWidgets);

    // Switch to Midnight (Dark Mode)
    await ThemeService.instance.toggleTheme();
    expect(AppColors.isDarkMode, isTrue);

    final darkSageGrad = AppColors.resolveBentoGradient(AppColors.themeSageEmerald);
    expect(darkSageGrad.colors.first, const Color(0xFF1B4332));
    expect(darkSageGrad.colors.last, const Color(0xFF2D6A4F));
    expect(AppColors.bentoTextPrimary(), const Color(0xFFF8FAFC));
    expect(AppColors.bentoPodText, Colors.white);
    expect(AppColors.bentoLaunchButtonIcon(), Colors.white);

    // Re-pump widget to test dark mode render
    await tester.pumpWidget(
      const MaterialApp(
        home: MainNavigationShell(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Graph Traversal'), findsOneWidget);

    // Reset to light mode
    await ThemeService.instance.toggleTheme();
    expect(AppColors.isDarkMode, isFalse);
  });

  testWidgets('QuickCreateSheet renders tactile horizontal scrollable subject chips and circular color swatch selector dots with active rings',
      (WidgetTester tester) async {
    await StudyRepository.instance.addSubject(name: 'Distributed Systems', colorValue: AppColors.themeRoyalIndigo);
    await StudyRepository.instance.addSubject(name: 'Compilers', colorValue: AppColors.themeRoseCoral);

    await tester.pumpWidget(
      const MaterialApp(
        home: MainNavigationShell(),
      ),
    );
    await tester.pumpAndSettle();

    // Open QuickCreateSheet via center + dock button
    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pumpAndSettle();

    // Verify horizontal scrollable Subject Category chips inside QuickCreateSheet
    final quickSheet = find.byType(QuickCreateSheet);
    expect(find.descendant(of: quickSheet, matching: find.text('Distributed Systems')), findsOneWidget);
    expect(find.descendant(of: quickSheet, matching: find.text('Compilers')), findsOneWidget);

    // Tap Compilers chip
    await tester.tap(find.descendant(of: quickSheet, matching: find.text('Compilers')));
    await tester.pumpAndSettle();

    // Verify all 6 circular color swatch labels exist
    for (final option in AppColors.bentoThemeOptions) {
      await tester.ensureVisible(find.text(option.label));
      expect(find.text(option.label), findsOneWidget);
    }

    // Select Amber palette dot
    await tester.ensureVisible(find.text('Amber'));
    await tester.tap(find.text('Amber'));
    await tester.pumpAndSettle();

    // Verify active selection ring
    expect(find.byIcon(Icons.check_rounded), findsWidgets);
  });

  testWidgets('DeckDetailScreen header uses Bento tokens with crisp dark text in Light Mode and alabaster in Dark Mode',
      (WidgetTester tester) async {
    await ThemeService.instance.initializeTheme();
    expect(AppColors.isDarkMode, isFalse);

    await StudyRepository.instance.addSubject(
      name: 'Cloud Architecture',
      colorValue: AppColors.themeElectricOcean,
    );
    final sub = StudyRepository.instance.subjects.first;
    await StudyRepository.instance.addDeck(
      title: 'Kubernetes Ingress & Mesh',
      description: 'Envoy, Istio, NGINX',
      subjectId: sub.id,
      colorValue: AppColors.themeElectricOcean,
    );
    final deck = StudyRepository.instance.decks.first;

    await tester.pumpWidget(
      MaterialApp(
        home: DeckDetailScreen(deckId: deck.id),
      ),
    );
    await tester.pumpAndSettle();

    // Title should use dark bentoTextPrimary in Light Mode, NOT white
    final titleText = tester.widget<Text>(find.text('Kubernetes Ingress & Mesh'));
    expect(titleText.style?.color, const Color(0xFF1A1D20));

    // Stats Bar Total number should use bentoTextPrimary
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Mastered'), findsOneWidget);

    // Switch to Dark Mode
    await ThemeService.instance.toggleTheme();
    expect(AppColors.isDarkMode, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: DeckDetailScreen(deckId: deck.id),
      ),
    );
    await tester.pumpAndSettle();

    final darkTitleText = tester.widget<Text>(find.text('Kubernetes Ingress & Mesh'));
    expect(darkTitleText.style?.color, const Color(0xFFF8FAFC));

    // Reset to light mode
    await ThemeService.instance.toggleTheme();
    expect(AppColors.isDarkMode, isFalse);
  });

  testWidgets('CurvedBottomSheet renders ClipPath with notched silhouette and top-center close button',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  CurvedBottomSheet.show<void>(
                    context: context,
                    title: 'Test Notched Sheet',
                    subtitle: 'Testing silhouette clipping',
                    child: const Text('Sheet Content Inside'),
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap to open sheet
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    // Verify CurvedBottomSheet is visible
    expect(find.byType(CurvedBottomSheet), findsOneWidget);
    expect(find.text('Test Notched Sheet'), findsOneWidget);
    expect(find.text('Sheet Content Inside'), findsOneWidget);

    // Verify ClipPath wraps scroll view
    expect(find.descendant(of: find.byType(CurvedBottomSheet), matching: find.byType(ClipPath)), findsWidgets);

    // Verify close button is present and dismisses sheet
    final closeBtn = find.descendant(of: find.byType(CurvedBottomSheet), matching: find.byIcon(Icons.close_rounded));
    expect(closeBtn, findsOneWidget);
    await tester.tap(closeBtn);
    await tester.pumpAndSettle();

    expect(find.byType(CurvedBottomSheet), findsNothing);
  });

  testWidgets('Light Mode text visibility: QuizScreen, FlipCardWidget, AuthScreen, and AppButton render crisp dark text on light surfaces',
      (WidgetTester tester) async {
    // 1. Confirm Light Mode defaults
    await ThemeService.instance.setThemeMode(ThemeMode.light);
    expect(AppColors.isDarkMode, isFalse);
    expect(AppColors.textInverse, const Color(0xFF1A1D20));

    // 2. Test FlipCardWidget question & answer text colors in Light Mode
    final sampleCard = Flashcard(
      id: 'contrast_test_card',
      deckId: 'deck_c',
      question: 'What is the fanout of a B+Tree node?',
      answer: 'The number of child pointers per internal node.',
      explanation: 'Determines overall tree height.',
      tags: const ['BTree', 'Storage'],
      cardType: FlashcardType.standard,
      nextReviewDate: DateTime.now(),
    );

    // Front: Question text must use textPrimary (#1A1D20), NOT Colors.white
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlipCardWidget(
            card: sampleCard,
            isFlipped: false,
            currentIndex: 1,
            totalCards: 1,
            onFlip: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final questionWidget = tester.widget<Text>(find.text('What is the fanout of a B+Tree node?'));
    expect(questionWidget.style?.color, const Color(0xFF1A1D20));
    expect(questionWidget.style?.color, isNot(equals(Colors.white)));

    // Back: Answer text must use textPrimary (#1A1D20), NOT Colors.white
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlipCardWidget(
            card: sampleCard,
            isFlipped: true,
            currentIndex: 1,
            totalCards: 1,
            onFlip: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final answerWidget = tester.widget<Text>(find.text('The number of child pointers per internal node.'));
    expect(answerWidget.style?.color, const Color(0xFF1A1D20));
    expect(answerWidget.style?.color, isNot(equals(Colors.white)));

    // 3. Test QuizScreen option tiles in Light Mode
    final quizDeck = Deck(
      id: 'quiz_test_deck',
      title: 'Database Architecture',
      description: 'ACID and indexing',
      subjectId: 'sub_1',
      colorValue: AppColors.themeRoyalIndigo,
      createdAt: DateTime.now(),
      cards: [sampleCard],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: QuizScreen(deck: quizDeck),
      ),
    );
    await tester.pumpAndSettle();

    // Verify option text uses textPrimary (#1A1D20), NOT Colors.white
    final optionFinder = find.text('The number of child pointers per internal node.');
    expect(optionFinder, findsOneWidget);
    final optionWidget = tester.widget<Text>(optionFinder);
    expect(optionWidget.style?.color, const Color(0xFF1A1D20));
    expect(optionWidget.style?.color, isNot(equals(Colors.white)));

    // 4. Test AppButton outline and secondary variants in Light Mode
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              AppButton(
                label: 'Outline Button',
                variant: AppButtonVariant.outline,
                onPressed: () {},
              ),
              AppButton(
                label: 'Secondary Button',
                variant: AppButtonVariant.secondary,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Outline button text must use dark amber (#D97706) in Light Mode, NOT pale primaryLight
    final outlineText = tester.widget<Text>(find.text('Outline Button'));
    expect(outlineText.style?.color, const Color(0xFFD97706));
    expect(outlineText.style?.color, isNot(equals(AppColors.primaryLight)));

    // 5. Test AuthScreen tab switcher in Light Mode
    await tester.pumpWidget(
      const MaterialApp(
        home: AuthScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Active 'Sign In' tab text must use textInverse (#1A1D20) on gold, NOT bgCanvas (#F7F5F0)
    final signInTabText = tester.widget<Text>(find.text('Sign In'));
    expect(signInTabText.style?.color, const Color(0xFF1A1D20));
    expect(signInTabText.style?.color, isNot(equals(AppColors.bgCanvas)));
  });
}

