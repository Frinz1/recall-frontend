import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../auth/auth_screen.dart';

class OnboardingSlideData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final Color accentColor;

  const OnboardingSlideData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.accentColor,
  });
}

class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const OnboardingScreen({super.key, this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingSlideData> _slides = const [
    OnboardingSlideData(
      icon: Icons.psychology_rounded,
      title: 'Scientific Spaced Repetition',
      subtitle: 'Overcome the Forgetting Curve',
      description:
          'Recall uses the proven SuperMemo-2 (SM-2) mathematical model to schedule your reviews at the exact moment before memory decay begins.',
      accentColor: AppColors.primary,
    ),
    OnboardingSlideData(
      icon: Icons.radar_rounded,
      title: 'Active Weakness Radar',
      subtitle: 'Target What You Struggle With',
      description:
          'Our heuristic radar tracks failure rates across all decks. Weak concepts like CIDR subnetting or deadlocks are highlighted for high-intensity drill.',
      accentColor: AppColors.danger,
    ),
    OnboardingSlideData(
      icon: Icons.cloud_done_rounded,
      title: 'Live Cloud Architecture',
      subtitle: 'Available Everywhere You Go',
      description:
          'Connected to a dedicated cloud PostgreSQL backend. Study seamlessly at home, at school, or on mobile data from any device.',
      accentColor: AppColors.accentCyan,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _navigateToAuth();
    }
  }

  void _navigateToAuth() {
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: _navigateToAuth,
            child: Text(
              'Skip',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: slide.accentColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: slide.accentColor.withValues(alpha: 0.4),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              slide.icon,
                              size: 52,
                              color: slide.accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          slide.subtitle.toUpperCase(),
                          style: AppTypography.badge.copyWith(
                            color: slide.accentColor,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          slide.title,
                          style: AppTypography.displayMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide.description,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.55,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation & Dots
            Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final isSelected = i == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isSelected ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.bgSurface2,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),
                  AppButton(
                    label: _currentIndex == _slides.length - 1
                        ? 'Get Started'
                        : 'Continue',
                    isExpanded: true,
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _nextPage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
