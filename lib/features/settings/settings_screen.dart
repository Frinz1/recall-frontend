import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/study_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_service.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/curved_bottom_sheet.dart';
import '../../core/widgets/toast_feedback.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        AuthService.instance,
        StudyRepository.instance,
        ThemeService.instance,
      ]),
      builder: (context, _) {
        final user = AuthService.instance.currentUser;
        final repo = StudyRepository.instance;
        final syncSubtitle = repo.lastSyncedAt != null
            ? DateFormat('h:mm a').format(repo.lastSyncedAt!)
            : 'Synced';

        return Scaffold(
          appBar: AppBar(
            title: Text('Settings', style: AppTypography.titleLarge),
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
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary,
                        radius: 22,
                        child: Text(
                          (user != null && user.name.isNotEmpty)
                              ? user.name[0].toUpperCase()
                              : 'R',
                          style: TextStyle(
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
                ),

                const SizedBox(height: 22),

                // 2. Appearance & Theme Group (Light vs Midnight Slate)
                _buildSectionLabel('APPEARANCE & THEME'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      _buildThemeSelectorRow(context),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // 3. Study & Spaced Repetition Group
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
                        valueText:
                            '${repo.dailyGoalCards} ${repo.dailyGoalCards == 1 ? 'card' : 'cards'}/day',
                        onTap: () => _openDailyGoalSheet(context, repo.dailyGoalCards),
                      ),
                      Divider(color: AppColors.borderSubtle, height: 1, indent: 56),
                      _buildSwitchRow(
                        icon: Icons.shuffle_rounded,
                        iconColor: AppColors.accentCyan,
                        title: 'Shuffle Study Cards',
                        subtitle: 'Randomize card order during sessions',
                        value: repo.shuffleStudyCards,
                        onChanged: (val) => repo.setShuffleStudyCards(val),
                      ),
                      Divider(color: AppColors.borderSubtle, height: 1, indent: 56),
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

                // 4. Cloud & Study Data Group
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
                      Divider(color: AppColors.borderSubtle, height: 1, indent: 56),
                      _buildNavRow(
                        icon: Icons.restart_alt_rounded,
                        iconColor: AppColors.warning,
                        title: 'Reset All Study Progress',
                        valueText:
                            '${repo.totalCardsCount} ${repo.totalCardsCount == 1 ? 'card' : 'cards'}',
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
                  child: Material(
                    color: Colors.transparent,
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
    String? valueText,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
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
            if (valueText != null && valueText.isNotEmpty) ...[
              Text(
                valueText,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(width: 4),
            ],
            Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelectorRow(BuildContext context) {
    final isDark = ThemeService.instance.isDarkMode;
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: (isDark ? AppColors.primary : AppColors.accentCyan)
                    .withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: isDark ? AppColors.primary : AppColors.accentCyan,
                size: 19,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme Mode',
                    style: AppTypography.titleMedium.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isDark
                        ? 'Midnight Slate (OLED Dark)'
                        : 'Clean White & Two-Tone (Light)',
                    style: AppTypography.bodySmall.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.bgSurface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildThemeOptionPill(
                    context,
                    isSelected: !isDark,
                    label: 'Light',
                    icon: Icons.light_mode_rounded,
                    onTap: () async {
                      if (isDark) {
                        await ThemeService.instance.setThemeMode(ThemeMode.light);
                        if (context.mounted) {
                          ToastFeedback.showSuccess(
                            context,
                            'Switched to Clean White & Slate (Light Mode).',
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  _buildThemeOptionPill(
                    context,
                    isSelected: isDark,
                    label: 'Midnight',
                    icon: Icons.nightlight_round,
                    onTap: () async {
                      if (!isDark) {
                        await ThemeService.instance.setThemeMode(ThemeMode.dark);
                        if (context.mounted) {
                          ToastFeedback.showSuccess(
                            context,
                            'Switched to Midnight Slate Mode.',
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOptionPill(
    BuildContext context, {
    required bool isSelected,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.textInverse : AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.badge.copyWith(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.textInverse : AppColors.textMuted,
              ),
            ),
          ],
        ),
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
    return Material(
      color: Colors.transparent,
      child: ListTile(
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

    CurvedBottomSheet.show<void>(
      context: context,
      title: 'Daily Review Goal',
      subtitle: 'Choose how many flashcards you aim to review each day.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
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
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                onTap: () {
                  StudyRepository.instance.setDailyGoalCards(count);
                  Navigator.of(context).pop();
                  ToastFeedback.showSuccess(
                    context,
                    'Daily goal updated to $count ${count == 1 ? 'card' : 'cards'}/day.',
                  );
                },
                title: Text(
                  '$count ${count == 1 ? 'card' : 'cards'} per day',
                  style: AppTypography.titleMedium.copyWith(
                    color: selected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(desc, style: AppTypography.bodySmall),
                trailing: selected
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _openAboutRecallSheet(BuildContext context) {
    CurvedBottomSheet.show<void>(
      context: context,
      title: 'About Recall',
      subtitle: 'Study smarter, remember longer.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Image.asset(
              'assets/images/recall_logo.png',
              width: 68,
              height: 80,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
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
            color: AppColors.primaryLight,
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
                'Automatically detects cards after 2+ reviews with ≥ 40% failure rate or low Ease Factor (< 1.9) so you can drill weak concepts.',
          ),
        ],
      ),
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
    CurvedBottomSheet.show<void>(
      context: context,
      title: 'Edit Display Name',
      subtitle: 'Update how your name appears on your study dashboard',
      child: _EditDisplayNameSheet(currentName: currentName),
    );
  }

  void _confirmResetAllProgress(BuildContext context) {
    CurvedBottomSheet.show<void>(
      context: context,
      title: 'Reset All Study Progress?',
      subtitle: 'Restore all flashcards across your library to unstudied state',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'This will reset all cards across your decks back to "New Card" (0 reviews) so you can study everything fresh. Your subjects, decks, and flashcards will not be deleted.',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Reset All Progress',
            icon: Icons.restart_alt_rounded,
            isExpanded: true,
            onPressed: () async {
              ToastFeedback.showSuccess(context, 'All study progress has been reset.');
              Navigator.of(context).pop();
              await StudyRepository.instance.resetAllProgress();
            },
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    CurvedBottomSheet.show<void>(
      context: context,
      title: 'Sign Out of Recall?',
      subtitle: 'Your subjects, decks, and study progress are safely synced with Recall Cloud.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppButton(
            label: 'Sign Out',
            icon: Icons.logout_rounded,
            variant: AppButtonVariant.danger,
            isExpanded: true,
            onPressed: () {
              Navigator.of(context).pop();
              AuthService.instance.logout();
            },
          ),
        ],
      ),
    );
  }
}

class _EditDisplayNameSheet extends StatefulWidget {
  final String currentName;

  const _EditDisplayNameSheet({required this.currentName});

  @override
  State<_EditDisplayNameSheet> createState() => _EditDisplayNameSheetState();
}

class _EditDisplayNameSheetState extends State<_EditDisplayNameSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('DISPLAY NAME', style: AppTypography.labelMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _ctrl,
          autofocus: true,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter your name',
            filled: true,
            fillColor: AppColors.bgSurface2,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 22),
        AppButton(
          label: 'Save Display Name',
          icon: Icons.check_rounded,
          isExpanded: true,
          onPressed: () async {
            final nextName = _ctrl.text.trim();
            if (nextName.length < 2) {
              ToastFeedback.showError(context, 'Name must be at least 2 characters.');
              return;
            }
            ToastFeedback.showSuccess(context, 'Display name updated to "$nextName".');
            Navigator.of(context).pop();
            await AuthService.instance.updateDisplayName(nextName);
          },
        ),
      ],
    );
  }
}

