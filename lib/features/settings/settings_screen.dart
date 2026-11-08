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
        final syncSubtitle = repo.lastSyncedAt != null
            ? DateFormat('h:mm a').format(repo.lastSyncedAt!)
            : 'Synced';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings', style: AppTypography.titleLarge),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Account Header Card
                _buildSectionLabel('PROFILE & ACCOUNT'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      radius: 22,
                      child: Text(
                        (user != null && user.name.isNotEmpty)
                            ? user.name[0].toUpperCase()
                            : 'R',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: AppColors.textInverse,
                        ),
                      ),
                    ),
                    title: Text(
                      user?.name ?? 'Recall Learner',
                      style: AppTypography.titleMedium,
                    ),
                    subtitle: Text(
                      user?.email ?? 'Signed in',
                      style: AppTypography.bodySmall,
                    ),
                    trailing: TextButton(
                      onPressed: () => _openEditNameDialog(context, user?.name ?? ''),
                      child: const Text(
                        'Edit',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // 2. Study & Spaced Repetition Group
                _buildSectionLabel('STUDY & SPACED REPETITION'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      _buildNavRow(
                        icon: Icons.flag_rounded,
                        iconColor: AppColors.primary,
                        title: 'Daily Review Goal',
                        valueText: '${repo.dailyGoalCards} cards/day',
                        onTap: () => _openDailyGoalSheet(context, repo.dailyGoalCards),
                      ),
                      const Divider(color: AppColors.borderSubtle, height: 1, indent: 56),
                      _buildSwitchRow(
                        icon: Icons.shuffle_rounded,
                        iconColor: AppColors.accentCyan,
                        title: 'Shuffle Study Cards',
                        subtitle: 'Randomize card order during sessions',
                        value: repo.shuffleStudyCards,
                        onChanged: (val) => repo.setShuffleStudyCards(val),
                      ),
                      const Divider(color: AppColors.borderSubtle, height: 1, indent: 56),
                      _buildSwitchRow(
                        icon: Icons.auto_awesome_rounded,
                        iconColor: AppColors.accentPurple,
                        title: 'Include New Cards in Due',
                        subtitle: 'Mix unreviewed cards into Smart Review',
                        value: repo.includeNewInDue,
                        onChanged: (val) => repo.setIncludeNewInDue(val),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // 3. Cloud & Study Data Group
                _buildSectionLabel('CLOUD & DATA'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      _buildNavRow(
                        icon: Icons.cloud_sync_rounded,
                        iconColor: AppColors.success,
                        title: 'Sync Workspace Now',
                        valueText: repo.isSyncing ? 'Syncing...' : syncSubtitle,
                        onTap: repo.isSyncing
                            ? null
                            : () async {
                                await repo.fetchAllFromCloud();
                                if (context.mounted) {
                                  ToastFeedback.showSuccess(
                                    context,
                                    'Workspace synced with Recall Cloud.',
                                  );
                                }
                              },
                      ),
                      const Divider(color: AppColors.borderSubtle, height: 1, indent: 56),
                      _buildNavRow(
                        icon: Icons.restart_alt_rounded,
                        iconColor: AppColors.warning,
                        title: 'Reset All Study Progress',
                        valueText: '${repo.totalCardsCount} cards',
                        onTap: repo.totalCardsCount == 0
                            ? null
                            : () => _confirmResetAllProgress(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // 4. App Information Group
                _buildSectionLabel('APPLICATION'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      _buildNavRow(
                        icon: Icons.info_outline_rounded,
                        iconColor: AppColors.accentCyan,
                        title: 'About Recall & Features',
                        valueText: 'v2.3.0',
                        onTap: () => _openAboutRecallSheet(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // 5. Sign Out Row
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.45)),
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    onTap: () => _confirmSignOut(context),
                    leading: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 18),
                    ),
                    title: Text(
                      'Sign Out',
                      style: AppTypography.titleMedium.copyWith(color: AppColors.danger),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.danger,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: AppTypography.labelMedium.copyWith(
          color: AppColors.textMuted,
          fontSize: 11,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildNavRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String valueText,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 19),
      ),
      title: Text(title, style: AppTypography.titleMedium.copyWith(fontSize: 15)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            valueText,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 19),
      ),
      title: Text(title, style: AppTypography.titleMedium.copyWith(fontSize: 15)),
      subtitle: Text(subtitle, style: AppTypography.bodySmall.copyWith(fontSize: 12)),
      trailing: Switch(
        value: value,
        activeThumbColor: AppColors.primary,
        onChanged: onChanged,
      ),
    );
  }

  void _openDailyGoalSheet(BuildContext context, int currentGoal) {
    final options = [
      (10, 'Casual • ~5 mins/day'),
      (20, 'Regular • ~10 mins/day'),
      (30, 'Serious • ~15 mins/day'),
      (50, 'Intensive • ~25 mins/day'),
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bgSurface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daily Review Goal', style: AppTypography.titleLarge),
                const SizedBox(height: 4),
                const Text(
                  'Choose how many flashcards you aim to review each day.',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 16),
                ...options.map((opt) {
                  final count = opt.$1;
                  final desc = opt.$2;
                  final selected = count == currentGoal;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.bgSurface2,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.borderSubtle,
                        width: selected ? 1.8 : 1.0,
                      ),
                    ),
                    child: ListTile(
                      onTap: () {
                        StudyRepository.instance.setDailyGoalCards(count);
                        Navigator.of(ctx).pop();
                        ToastFeedback.showSuccess(
                          context,
                          'Daily goal updated to $count cards/day.',
                        );
                      },
                      title: Text(
                        '$count cards per day',
                        style: AppTypography.titleMedium.copyWith(
                          color: selected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(desc, style: AppTypography.bodySmall),
                      trailing: selected
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                          : null,
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openAboutRecallSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: AppColors.textInverse,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('About Recall', style: AppTypography.titleLarge),
                          Text(
                            'Version 2.3.0 • Study smarter, remember longer.',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.accentCyan),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildAboutItem(
                  icon: Icons.psychology_outlined,
                  color: AppColors.primary,
                  title: 'SuperMemo-2 (SM-2) Scheduling',
                  desc:
                      'Adapts review intervals dynamically based on your recall rating (Again, Hard, Good, Easy) so you review concepts right before forgetting.',
                ),
                const SizedBox(height: 14),
                _buildAboutItem(
                  icon: Icons.auto_awesome_rounded,
                  color: AppColors.accentCyan,
                  title: 'New Cards vs. Due Today',
                  desc:
                      'Unstudied cards start as "New Card". Once completed in your first study pass, they enter your timed SM-2 review schedule.',
                ),
                const SizedBox(height: 14),
                _buildAboutItem(
                  icon: Icons.star_rounded,
                  color: Colors.amber,
                  title: 'Starred Priority Decks',
                  desc:
                      'Star any deck to pin it to the top of your Dashboard and Decks Library for quick exam preparation.',
                ),
                const SizedBox(height: 14),
                _buildAboutItem(
                  icon: Icons.radar_rounded,
                  color: AppColors.danger,
                  title: 'Weakness Radar & Quiz Mode',
                  desc:
                      'Automatically detects cards with ≥ 40% failure rate or low Ease Factor (< 1.9) so you can drill weak concepts.',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAboutItem({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.titleMedium.copyWith(fontSize: 14)),
              const SizedBox(height: 2),
              Text(desc, style: AppTypography.bodySmall),
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
        title: const Text('Edit Display Name', style: AppTypography.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('DISPLAY NAME', style: AppTypography.labelMedium),
            const SizedBox(height: 6),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Enter your name'),
            ),
          ],
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
            label: 'Reset All',
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
        title: const Text('Sign Out of Recall?', style: AppTypography.titleLarge),
        content: const Text(
          'Your subjects, decks, and study progress are safely synced with your Recall Cloud account.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Sign Out',
            variant: AppButtonVariant.danger,
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
