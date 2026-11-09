import 'package:flutter/material.dart';
import '../../core/models/flashcard_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/study_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/quick_create_sheet.dart';
import '../../core/widgets/toast_feedback.dart';
import '../deck/deck_detail_screen.dart';
import '../study/study_session_screen.dart';
import '../subject/subject_list_screen.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onNavigateToDecks;
  final VoidCallback? onNavigateToSettings;

  const DashboardScreen({
    super.key,
    required this.onNavigateToDecks,
    this.onNavigateToSettings,
  });

  String _resolveGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _resolveFirstName(UserProfile? user) {
    if (user == null || user.name.trim().isEmpty) return 'Scholar';
    return user.name.trim().split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([StudyRepository.instance, AuthService.instance]),
      builder: (context, _) {
        final repo = StudyRepository.instance;
        final user = AuthService.instance.currentUser;
        final firstName = _resolveFirstName(user);
        final greeting = _resolveGreeting();

        final totalDue = repo.totalDueCardsCount;
        final scheduledDue = repo.totalScheduledDueCount;
        final newCount = repo.totalNewCardsCount;
        final weakCards = repo.weakCards;
        final decks = repo.decks;
        final subjects = repo.subjects;
        final reviewedToday = repo.reviewedTodayCount;
        final dailyGoal = repo.dailyGoalCards;

        // Recommend deck: prioritize Starred/active decks with due cards, then unmastered cards
        int effectiveDue(Deck d) =>
            repo.includeNewInDue ? d.dueCardsCount : d.scheduledDueCount;
        Deck? priorityDeck;
        if (decks.isNotEmpty) {
          final sorted = List<Deck>.from(decks)
            ..sort((a, b) {
              if (a.isFavorite != b.isFavorite) {
                return a.isFavorite ? -1 : 1;
              }
              final aDue = effectiveDue(a);
              final bDue = effectiveDue(b);
              if (aDue != bDue) {
                return bDue.compareTo(aDue);
              }
              return b.unmasteredCount.compareTo(a.unmasteredCount);
            });
          priorityDeck = sorted.firstWhere(
            (d) => effectiveDue(d) > 0,
            orElse: () => sorted.firstWhere(
              (d) => d.unmasteredCount > 0,
              orElse: () => sorted.firstWhere(
                (d) => d.totalCards > 0,
                orElse: () => sorted.first,
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 20,
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryLight, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      firstName[0].toUpperCase(),
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textInverse,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recall Workspace',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        '$greeting, $firstName 👋',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleLarge.copyWith(fontSize: 17),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // Streak Flame Pill (Single clean status badge, no redundant Settings button)
              Container(
                margin: const EdgeInsets.only(right: 20),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface2,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.45)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: AppColors.warning,
                      size: 17,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${repo.studyStreakDays}d streak',
                      style: AppTypography.badge.copyWith(color: AppColors.warning),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.bgSurface1,
            onRefresh: () => repo.fetchAllFromCloud(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Upgraded Hero Card with 3D AI Mascot + 7-Day Capsule Calendar Strip
                  _buildHeroBanner(
                    context,
                    repo: repo,
                    totalDue: totalDue,
                    scheduledDue: scheduledDue,
                    newCount: newCount,
                    priorityDeck: priorityDeck,
                    hasNoDecks: decks.isEmpty,
                    reviewedToday: reviewedToday,
                    dailyGoal: dailyGoal,
                  ),

                  const SizedBox(height: 20),

                  // Metrics Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatTile(
                          label: scheduledDue > 0 ? 'Due Today' : 'New Cards',
                          value: scheduledDue > 0 ? '$scheduledDue' : '$newCount',
                          color: scheduledDue > 0
                              ? AppColors.danger
                              : (newCount > 0 ? AppColors.accentCyan : AppColors.success),
                          icon: scheduledDue > 0
                              ? Icons.access_time_rounded
                              : Icons.auto_awesome_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatTile(
                          label: 'Mastered',
                          value: '${repo.totalMasteredCardsCount}',
                          color: AppColors.success,
                          icon: Icons.check_circle_outline_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatTile(
                          label: 'Retention',
                          value: '${repo.overallRetentionRate.round()}%',
                          color: AppColors.isDarkMode ? AppColors.primaryLight : const Color(0xFFD97706),
                          icon: Icons.psychology_outlined,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Weakness Quick Alert (if any weak cards)
                  if (weakCards.isNotEmpty) ...[
                    _buildWeaknessAlertBanner(context, weakCards.length),
                    const SizedBox(height: 24),
                  ],

                  // Subjects Section Header — Single Clean 'Manage →' Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Subjects',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleLarge,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const SubjectListScreen()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.bgSurface1,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Manage',
                                style: AppTypography.badge.copyWith(
                                  color: AppColors.isDarkMode ? AppColors.primaryLight : const Color(0xFFD97706),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: AppColors.isDarkMode ? AppColors.primaryLight : const Color(0xFFD97706),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (subjects.isEmpty)
                    InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => QuickCreateSheet.show(context, initialTab: 1),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface1,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.local_offer_outlined,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('No subjects yet', style: AppTypography.titleMedium),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tap to create a color-blocked subject category (e.g. Networking, Calculus).',
                                    style: AppTypography.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: AppColors.bgSurface2,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.borderSubtle),
                              ),
                              child: const Icon(
                                Icons.north_east_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 82,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: subjects.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final sub = subjects[index];
                          final subDecks = decks.where((d) => d.subjectId == sub.id).toList();
                          final count = subDecks.length;
                          final cardCount = subDecks.fold(0, (s, d) => s + d.totalCards);
                          final subIcon = AppColors.resolveSubjectIcon(sub.name);
                          final monogram = AppColors.getSubjectMonogram(sub.name);
                          final accent = AppColors.resolveBentoAccent(sub.colorValue);

                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(builder: (_) => const SubjectListScreen()),
                              );
                            },
                            child: Container(
                              width: 196,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: AppColors.resolveBentoGradient(sub.colorValue),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.bentoBorderColor(sub.colorValue),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: AppColors.isDarkMode ? 0.25 : 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.isDarkMode
                                          ? Colors.white.withValues(alpha: 0.16)
                                          : Colors.white.withValues(alpha: 0.90),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: AppColors.isDarkMode
                                          ? null
                                          : [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.06),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                    ),
                                    child: Center(
                                      child: subIcon != null
                                          ? Icon(
                                              subIcon,
                                              size: 20,
                                              color: AppColors.isDarkMode ? Colors.white : accent,
                                            )
                                          : Text(
                                              monogram,
                                              style: AppTypography.titleMedium.copyWith(
                                                color: AppColors.isDarkMode ? Colors.white : accent,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sub.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.titleMedium.copyWith(
                                            color: AppColors.bentoTextPrimary(sub.colorValue),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$count ${count == 1 ? 'deck' : 'decks'} • $cardCount cards',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.bodySmall.copyWith(
                                            color: AppColors.bentoTextSecondary(sub.colorValue),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: AppColors.bentoLaunchButtonBg(sub.colorValue),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.bentoLaunchButtonBorder(sub.colorValue),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.north_east_rounded,
                                      size: 14,
                                      color: AppColors.bentoLaunchButtonIcon(sub.colorValue),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 26),

                  // Active Decks Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Active Decks',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleLarge,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: onNavigateToDecks,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'View All',
                                style: AppTypography.badge.copyWith(
                                  color: AppColors.isDarkMode ? AppColors.primaryLight : const Color(0xFFD97706),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: AppColors.isDarkMode ? AppColors.primaryLight : const Color(0xFFD97706),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (decks.isEmpty)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface1,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: const EmptyStateView(
                        icon: Icons.style_outlined,
                        title: 'No Flashcard Decks Yet',
                        description:
                            'Tap the center + button in the bottom dock to create your first subject or flashcard deck.',
                      ),
                    )
                  else
                    ...decks.take(4).map((deck) => _buildBentoDeckCard(context, deck)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroBanner(
    BuildContext context, {
    required StudyRepository repo,
    required int totalDue,
    required int scheduledDue,
    required int newCount,
    required Deck? priorityDeck,
    required bool hasNoDecks,
    required int reviewedToday,
    required int dailyGoal,
  }) {
    final goalProgress = dailyGoal > 0 ? (reviewedToday / dailyGoal).clamp(0.0, 1.0) : 0.0;
    final unmasteredCount = repo.totalUnmasteredCardsCount;
    final remainingGoal = (dailyGoal - reviewedToday).clamp(0, dailyGoal);

    String headline;
    String subtext;
    if (hasNoDecks) {
      headline = 'Ready to Start Studying?';
      subtext =
          'Create a Subject and Flashcard Deck to begin your SM-2 spaced repetition schedule.';
    } else if (scheduledDue > 0) {
      headline = '$scheduledDue Cards Due Today';
      subtext = remainingGoal > 0
          ? 'Complete your scheduled reviews ($remainingGoal left for your $dailyGoal-card daily goal).'
          : (newCount > 0
              ? 'Plus $newCount new cards ready ($reviewedToday / $dailyGoal daily goal).'
              : 'Complete your scheduled SM-2 reviews today to extend retention.');
    } else if (newCount > 0 && totalDue > 0) {
      headline = '$newCount New Cards Ready';
      subtext = remainingGoal > 0
          ? 'Start your first study pass ($remainingGoal left for your $dailyGoal-card daily goal).'
          : 'Start your first study pass on these flashcards to schedule SM-2 intervals.';
    } else if (remainingGoal > 0 && repo.totalCardsCount > 0) {
      headline = '$remainingGoal Cards Left for Daily Goal';
      subtext = unmasteredCount > 0
          ? 'You have $unmasteredCount cards still in learning/reviewing ($reviewedToday / $dailyGoal daily goal). Keep practicing!'
          : 'You completed $reviewedToday / $dailyGoal reviews today. Review your decks to hit your daily target!';
    } else if (unmasteredCount > 0) {
      headline = '$unmasteredCount Cards Still Learning';
      subtext =
          'Daily goal reached ($reviewedToday / $dailyGoal)! Practice your $unmasteredCount unmastered cards anytime.';
    } else {
      headline = 'All Caught Up Today!';
      subtext =
          'You completed $reviewedToday / $dailyGoal reviews and mastered all ${repo.totalCardsCount} cards!';
    }

    final isDark = AppColors.isDarkMode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [AppColors.heroSurfaceStart, AppColors.heroSurfaceEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFFFFDF8), Color(0xFFFFF7E6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: isDark ? 0.42 : 0.40),
          width: 1.2,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.38),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFFD97706).withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: const Color(0xFF1A1D20).withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Status Pill, Bold Headline, Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'DAILY SM-2 SCHEDULE',
                        style: AppTypography.badge.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A1D20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      headline,
                      style: AppTypography.displayMedium.copyWith(
                        fontSize: 22,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtext,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.heroTextMuted : AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Right Column: 3D AI Study Robot Mascot
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.heroSurfaceStart : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.18)
                        : const Color(0xFFE7E3DA),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.35)
                          : const Color(0xFF1A1D20).withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/hero_mascot.jpg',
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(
                        Icons.smart_toy_rounded,
                        color: AppColors.primary,
                        size: 42,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Daily Goal Progress Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Daily Goal Progress',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.badge.copyWith(
                    fontSize: 11,
                    color: isDark ? AppColors.heroTextMuted : AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$reviewedToday / $dailyGoal cards',
                style: AppTypography.badge.copyWith(
                  fontSize: 11,
                  color: isDark ? AppColors.primaryLight : const Color(0xFFB45309),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: goalProgress,
              minHeight: 7,
              backgroundColor: isDark
                  ? Colors.black.withValues(alpha: 0.32)
                  : const Color(0xFFE7E3DA),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),

          const SizedBox(height: 18),

          // 7-Day Capsule Calendar Strip (Mon..Sun vertical pills)
          _buildSevenDayCapsuleStrip(repo),

          if (priorityDeck != null && repo.totalCardsCount > 0) ...[
            const SizedBox(height: 18),
            AppButton(
              label: totalDue > 0
                  ? 'Start Smart Review (${priorityDeck.title})'
                  : 'Continue Goal Review (${priorityDeck.title})',
              icon: Icons.play_arrow_rounded,
              isExpanded: true,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => StudySessionScreen(
                      deck: priorityDeck,
                      onlyDueCards: totalDue > 0,
                    ),
                  ),
                );
              },
            ),
          ] else if (hasNoDecks) ...[
            const SizedBox(height: 18),
            AppButton(
              label: 'Create First Subject & Deck',
              icon: Icons.add_circle_outline_rounded,
              isExpanded: true,
              onPressed: () => QuickCreateSheet.show(context, initialTab: 0),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSevenDayCapsuleStrip(StudyRepository repo) {
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    final currentWeekdayIndex = now.weekday - 1; // 0 = Mon .. 6 = Sun
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: currentWeekdayIndex));

    String dateKey(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final activeDates = <String>{...repo.cloudActiveReviewDates};

    for (final log in repo.reviewLogs) {
      activeDates.add(dateKey(log.timestamp.toLocal()));
    }
    for (final c in repo.allCards) {
      if (c.timesReviewed > 0 && c.lastReviewedDate != null) {
        activeDates.add(dateKey(c.lastReviewedDate!.toLocal()));
      }
    }
    if (repo.studyStreakDays > 0 && activeDates.isEmpty) {
      for (int s = 0; s < repo.studyStreakDays.clamp(0, 7); s++) {
        activeDates.add(dateKey(now.subtract(Duration(days: s))));
      }
    }

    final isDark = AppColors.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.24)
            : const Color(0xFFF2ECE1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : const Color(0xFFE7E3DA),
        ),
      ),
      child: Row(
        children: List.generate(7, (index) {
          final date = startOfWeek.add(Duration(days: index));
          final isToday = index == currentWeekdayIndex;
          final isActive = activeDates.contains(dateKey(date));

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isToday
                      ? AppColors.primary
                      : (isActive
                          ? (isDark
                              ? Colors.white.withValues(alpha: 0.14)
                              : Colors.white)
                          : Colors.transparent),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isToday
                        ? AppColors.primaryLight
                        : (isActive
                            ? AppColors.primary.withValues(alpha: 0.5)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.transparent)),
                    width: isToday ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dayLabels[index],
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: AppTypography.badge.copyWith(
                        fontSize: 10,
                        color: isToday
                            ? const Color(0xFF1A1D20)
                            : (isDark ? AppColors.heroTextMuted : AppColors.textMuted),
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${date.day}',
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isToday
                            ? const Color(0xFF1A1D20)
                            : (isDark ? Colors.white : AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isToday
                            ? const Color(0xFF1A1D20)
                            : (isActive ? AppColors.primary : Colors.transparent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBentoDeckCard(BuildContext context, Deck deck) {
    final accent = AppColors.resolveBentoAccent(deck.colorValue);
    final masteryPct = deck.masteryPercentage.round();
    final progressValue = deck.cards.isEmpty ? 0.0 : (deck.masteredCount / deck.cards.length);

    String statusLabel;
    Color statusDotColor;
    if (deck.scheduledDueCount > 0) {
      statusLabel = '${deck.scheduledDueCount} due today';
      statusDotColor = AppColors.warning;
    } else if (deck.newCardsCount > 0) {
      statusLabel = '${deck.newCardsCount} new';
      statusDotColor = AppColors.accentCyan;
    } else if (deck.totalCards == 0) {
      statusLabel = '0 cards • New deck';
      statusDotColor = AppColors.textMuted;
    } else if (deck.unmasteredCount > 0) {
      statusLabel = '${deck.unmasteredCount} learning';
      statusDotColor = accent;
    } else {
      statusLabel = '100% Mastered ✨';
      statusDotColor = AppColors.success;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: AppColors.resolveBentoGradient(deck.colorValue),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: deck.isFavorite
              ? (AppColors.isDarkMode ? AppColors.primaryLight : AppColors.primary).withValues(alpha: 0.85)
              : AppColors.bentoBorderColor(deck.colorValue),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppColors.isDarkMode ? 0.28 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => DeckDetailScreen(deckId: deck.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Neutral Status Pod (Left) + Star, Edit & Circular Arrow Launch Button (Right)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.bentoPodBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.bentoPodBorder),
                          boxShadow: AppColors.isDarkMode
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: statusDotColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                statusLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.badge.copyWith(
                                  color: AppColors.bentoPodText,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            final next = !deck.isFavorite;
                            StudyRepository.instance.toggleFavoriteDeck(deck.id);
                            if (next) {
                              ToastFeedback.showSuccess(
                                context,
                                '"${deck.title}" pinned to top of decks!',
                              );
                            } else {
                              ToastFeedback.showInfo(
                                context,
                                '"${deck.title}" unpinned.',
                              );
                            }
                          },
                          child: Container(
                            width: 34,
                            height: 34,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: AppColors.isDarkMode
                                  ? Colors.black.withValues(alpha: 0.25)
                                  : Colors.white.withValues(alpha: 0.85),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.isDarkMode
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : AppColors.borderSubtle,
                              ),
                            ),
                            child: Icon(
                              deck.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 17,
                              color: deck.isFavorite
                                  ? AppColors.primary
                                  : (AppColors.isDarkMode ? Colors.white70 : AppColors.textMuted),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => QuickCreateSheet.show(context, existingDeck: deck),
                          child: Container(
                            width: 34,
                            height: 34,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: AppColors.isDarkMode
                                  ? Colors.black.withValues(alpha: 0.25)
                                  : Colors.white.withValues(alpha: 0.85),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.isDarkMode
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : AppColors.borderSubtle,
                              ),
                            ),
                            child: Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: AppColors.isDarkMode ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.bentoLaunchButtonBg(deck.colorValue),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.bentoLaunchButtonBorder(deck.colorValue),
                            ),
                            boxShadow: AppColors.isDarkMode
                                ? null
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Icon(
                            Icons.north_east_rounded,
                            size: 17,
                            color: AppColors.bentoLaunchButtonIcon(deck.colorValue),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  deck.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.bentoTextPrimary(deck.colorValue),
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  deck.description.isNotEmpty
                      ? deck.description
                      : '${deck.totalCards} flashcards • ${deck.masteredCount} mastered',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.bentoTextSecondary(deck.colorValue),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Progress • $masteryPct%',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.badge.copyWith(
                          color: AppColors.bentoTextPrimary(deck.colorValue),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${deck.masteredCount}/${deck.totalCards} mastered',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.bentoTextMuted(deck.colorValue),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 10,
                    backgroundColor: AppColors.bentoProgressTrackBg(),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.bentoProgressBarColor(deck.colorValue),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(value, style: AppTypography.metricMedium.copyWith(color: color, fontSize: 20)),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.bodySmall.copyWith(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildWeaknessAlertBanner(BuildContext context, int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dangerSurface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weakness Radar Alert',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.isDarkMode ? Colors.white : AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count concepts have high failure rates. Check Stats to drill them.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
