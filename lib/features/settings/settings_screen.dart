import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/study_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/toast_feedback.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([AuthService.instance, StudyRepository.instance]),
      builder: (context, _) {
        final user = AuthService.instance.currentUser;
        final repo = StudyRepository.instance;
        final lastSyncText = repo.lastSyncedAt != null
            ? 'Last synced at ${DateFormat('h:mm a').format(repo.lastSyncedAt!)}'
            : 'Connected to Recall Cloud';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings & Preferences', style: AppTypography.titleLarge),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Account & Profile Card
                const Text('ACCOUNT', style: AppTypography.labelMedium),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary,
                        radius: 24,
                        child: Text(
                          (user != null && user.name.isNotEmpty)
                              ? user.name[0].toUpperCase()
                              : 'R',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: AppColors.bgCanvas,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'Recall Learner',
                              style: AppTypography.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.email ?? 'Signed in',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                        tooltip: 'Edit Display Name',
                        onPressed: () => _openEditNameDialog(context, user?.name ?? ''),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 2. Study & Spaced Repetition Preferences
                const Text('STUDY PREFERENCES', style: AppTypography.labelMedium),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Daily Review Goal', style: AppTypography.titleMedium),
                                SizedBox(height: 2),
                                Text(
                                  'Target number of flashcards to review each day.',
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${repo.dailyGoalCards} cards/day',
                              style: AppTypography.badge.copyWith(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [10, 20, 30, 50].map((goal) {
                          final selected = repo.dailyGoalCards == goal;
                          return ChoiceChip(
                            label: Text(
                              '$goal cards',
                              style: AppTypography.badge.copyWith(
                                color: selected ? AppColors.bgCanvas : AppColors.textSecondary,
                              ),
                            ),
                            selected: selected,
                            onSelected: (_) {
                              repo.setDailyGoalCards(goal);
                              ToastFeedback.showInfo(
                                context,
                                'Daily review goal set to $goal cards.',
                              );
                            },
                            backgroundColor: AppColors.bgSurface2,
                            selectedColor: AppColors.primary,
                            showCheckmark: false,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: selected ? AppColors.primary : AppColors.borderSubtle,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: AppColors.borderSubtle, height: 1),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: AppColors.primary,
                        title: const Text('Shuffle Cards in Study Sessions',
                            style: AppTypography.titleMedium),
                        subtitle: const Text(
                          'Randomize card order so you recall concepts rather than sequence.',
                          style: AppTypography.bodySmall,
                        ),
                        value: repo.shuffleStudyCards,
                        onChanged: (val) {
                          repo.setShuffleStudyCards(val);
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(color: AppColors.borderSubtle, height: 1),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: AppColors.primary,
                        title: const Text('Include New Cards in Daily Smart Review',
                            style: AppTypography.titleMedium),
                        subtitle: const Text(
                          'Automatically include unreviewed New Cards alongside scheduled due cards.',
                          style: AppTypography.bodySmall,
                        ),
                        value: repo.includeNewInDue,
                        onChanged: (val) {
                          repo.setIncludeNewInDue(val);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3. Cloud Sync & Data Management
                const Text('CLOUD & DATA', style: AppTypography.labelMedium),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: repo.isSyncing
                              ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                )
                              : const Icon(Icons.cloud_done_outlined, color: AppColors.primary),
                        ),
                        title: const Text('Recall Cloud Sync', style: AppTypography.titleMedium),
                        subtitle: Text(lastSyncText, style: AppTypography.bodySmall),
                        trailing: TextButton(
                          onPressed: repo.isSyncing
                              ? null
                              : () async {
                                  await repo.fetchAllFromCloud();
                                  if (context.mounted) {
                                    ToastFeedback.showSuccess(
                                      context,
                                      'Subjects, decks, and analytics synced with cloud.',
                                    );
                                  }
                                },
                          child: const Text(
                            'Sync Now',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const Divider(color: AppColors.borderSubtle, height: 1),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.restart_alt_rounded, color: AppColors.warning),
                        ),
                        title: const Text('Reset All Study Progress',
                            style: AppTypography.titleMedium),
                        subtitle: const Text(
                          'Reset intervals and review counts to 0 without deleting your decks.',
                          style: AppTypography.bodySmall,
                        ),
                        onTap: repo.totalCardsCount == 0
                            ? null
                            : () => _confirmResetAllProgress(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 4. About Recall (What's Inside the App)
                const Text('ABOUT RECALL', style: AppTypography.labelMedium),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.bolt_rounded,
                              color: AppColors.bgCanvas,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Recall Learning Companion',
                                    style: AppTypography.titleMedium),
                                Text(
                                  'Version 2.2.0 • Study smarter, remember longer.',
                                  style: AppTypography.bodySmall.copyWith(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureExplanation(
                        icon: Icons.psychology_outlined,
                        color: AppColors.primary,
                        title: 'SuperMemo-2 (SM-2) Spaced Repetition',
                        description:
                            'Every time you flip a card and rate your recall (Again, Hard, Good, Easy), Recall calculates your personal Ease Factor and schedules the next review right before you forget (1d → 6d → 15d+).',
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureExplanation(
                        icon: Icons.auto_awesome_rounded,
                        color: AppColors.accentCyan,
                        title: 'New Cards vs. Due Today',
                        description:
                            'Newly created flashcards are tagged as "New Card" for initial learning. Once studied, they move onto a timed schedule and appear as "Due Today" when their interval arrives.',
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureExplanation(
                        icon: Icons.star_rounded,
                        color: Colors.amber,
                        title: 'Starred Priority Decks',
                        description:
                            'Tap the star icon on any deck to pin it to the top of your Dashboard and Library, or filter by "★ Starred" during exam prep.',
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureExplanation(
                        icon: Icons.radar_rounded,
                        color: AppColors.danger,
                        title: 'Weakness Radar & Active Quiz',
                        description:
                            'Cards with ≥ 40% failure rate or low Ease Factor (< 1.9) are automatically surfaced in Analytics so you can drill weak spots or test yourself in Multiple-Choice Quiz mode.',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 5. Sign Out Button
                 SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: BorderSide(color: AppColors.danger.withValues(alpha: 0.6)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: const Text(
                      'Sign Out of Recall',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    onPressed: () => _confirmSignOut(context),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureExplanation({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.labelMedium.copyWith(color: Colors.white)),
              const SizedBox(height: 2),
              Text(description, style: AppTypography.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  void _openEditNameDialog(BuildContext context, String currentName) {
    final ctrl = TextEditingController(text: currentName);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurface1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
        title: const Text('Edit Display Name', style: AppTypography.titleLarge),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: AppTypography.bodyMedium.copyWith(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Your Name',
            filled: true,
            fillColor: AppColors.bgSurface2,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Save',
            onPressed: () async {
              final nextName = ctrl.text.trim();
              if (nextName.length < 2) {
                ToastFeedback.showError(context, 'Name must be at least 2 characters.');
                return;
              }
              Navigator.of(ctx).pop();
              final ok = await AuthService.instance.updateDisplayName(nextName);
              if (context.mounted) {
                if (ok) {
                  ToastFeedback.showSuccess(context, 'Display name updated to "$nextName".');
                } else {
                  ToastFeedback.showInfo(context, 'Display name updated locally.');
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmResetAllProgress(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurface1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
        title: const Text('Reset All Study Progress?', style: AppTypography.titleLarge),
        content: const Text(
          'This will reset all cards across your decks back to "New Card" (0 reviews) so you can study everything fresh. Your subjects, decks, and flashcards will not be deleted.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Reset All Progress',
            onPressed: () async {
              Navigator.of(ctx).pop();
              await StudyRepository.instance.resetAllProgress();
              if (context.mounted) {
                ToastFeedback.showSuccess(context, 'All study progress has been reset.');
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurface1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
        title: const Text('Sign Out of Recall?', style: AppTypography.titleLarge),
        content: const Text(
          'Your subjects, decks, and study progress are safely saved to your Recall Cloud account.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Sign Out',
            onPressed: () {
              Navigator.of(ctx).pop();
              AuthService.instance.logout();
            },
          ),
        ],
      ),
    );
  }
}
