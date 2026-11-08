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

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();

    _progressAnimation = Tween<double>(begin: 0.15, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );

    if (widget.onFinished != null) {
      _timer = Timer(const Duration(milliseconds: 1800), () {
        if (mounted && widget.onFinished != null) {
          widget.onFinished!();
        }
      });
    } else if (widget.nextScreen != null) {
      _timer = Timer(const Duration(milliseconds: 1800), _checkSessionAndNavigate);
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

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 32),

                // Center Brand Lockup
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface1,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: AppColors.primary, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.primaryGlow,
                              blurRadius: 28,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.bolt_rounded,
                            color: AppColors.primary,
                            size: 48,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Recall',
                        textAlign: TextAlign.center,
                        style: AppTypography.displayLarge.copyWith(
                          fontSize: 38,
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
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Section: Loading Bar & Microcopy
                Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 148,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface1,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.borderSubtle, width: 1),
                        ),
                        child: AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _progressAnimation.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),

                      Text(
                        'Syncing your study workspace...',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Container(
                        width: 128,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.borderSubtle,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
