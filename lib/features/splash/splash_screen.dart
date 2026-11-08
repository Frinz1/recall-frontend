import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  final Widget? nextScreen;
  final VoidCallback? onFinished;

  const SplashScreen({super.key, this.nextScreen, this.onFinished});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _progressController;
  late final AnimationController _pulseController;
  late final Animation<double> _progressAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _timer;

  static const List<String> _studyTips = [
    'Active recall strengthens neural pathways 3× faster than passive re-reading.',
    'Reviewing a concept right before you forget it doubles your memory interval.',
    'Star your priority decks (★) to pin them to the top of your library.',
    'Keep daily study sessions focused: 15–20 cards per session yields peak retention.',
  ];

  late final String _selectedTip;

  @override
  void initState() {
    super.initState();
    _selectedTip = _studyTips[DateTime.now().second % _studyTips.length];

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _progressAnimation = Tween<double>(begin: 0.08, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: const Interval(0.0, 0.38, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: const Interval(0.0, 0.28, curve: Curves.easeOut),
      ),
    );

    if (widget.onFinished != null) {
      _timer = Timer(const Duration(milliseconds: 3800), () {
        if (mounted && widget.onFinished != null) {
          widget.onFinished!();
        }
      });
    } else if (widget.nextScreen != null) {
      _timer = Timer(const Duration(milliseconds: 3800), _checkSessionAndNavigate);
    }
  }

  void _checkSessionAndNavigate() {
    if (!mounted) return;

    if (AuthService.instance.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => widget.nextScreen!),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  String _statusStageText(double progress) {
    if (progress < 0.38) return 'Initializing SM-2 Spaced Repetition...';
    if (progress < 0.78) return 'Syncing your subjects & decks...';
    return 'Workspace ready!';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 36),

                  // Center Animated Brand Emblem
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final glowSpread = 4.0 + (_pulseController.value * 8.0);
                            return Container(
                              width: 104,
                              height: 104,
                              padding: const EdgeInsets.only(bottom: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primaryDark,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.28),
                                    blurRadius: 32,
                                    spreadRadius: glowSpread,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.bgSurface1,
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(color: AppColors.primary, width: 2.2),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.bolt_rounded,
                                    color: AppColors.primary,
                                    size: 54,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 26),
                      Text(
                        'Recall',
                        textAlign: TextAlign.center,
                        style: AppTypography.displayLarge.copyWith(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          color: AppColors.textPrimary,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Study smarter, remember longer.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentCyan,
                        ),
                      ),
                    ],
                  ),

                  // Bottom Section: Study Tip Card + Staged Progress Bar
                  Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.bgSurface1,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.lightbulb_outline_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'STUDY TIP',
                                      style: AppTypography.badge.copyWith(
                                        color: AppColors.primary,
                                        fontSize: 10,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _selectedTip,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, _) {
                            final pct = (_progressAnimation.value * 100).round();
                            return Column(
                              children: [
                                Container(
                                  width: 220,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.bgSurface1,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: AppColors.borderSubtle, width: 1),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: _progressAnimation.value,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [AppColors.primary, AppColors.accentCyan],
                                        ),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '${_statusStageText(_progressAnimation.value)} ($pct%)',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
