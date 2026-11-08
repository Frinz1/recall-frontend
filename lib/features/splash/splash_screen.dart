import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../auth/auth_screen.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    _controller.forward();

    // Check session after splash animation
    Timer(const Duration(milliseconds: 2200), _checkSessionAndNavigate);
  }

  void _checkSessionAndNavigate() {
    if (!mounted) return;

    if (AuthService.instance.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => widget.nextScreen),
      );
    } else {
      // First-time or unauthenticated flow: show Onboarding first
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OnboardingScreen(
            onComplete: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF4338CA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.bolt_rounded,
                      color: Colors.white,
                      size: 56,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            FadeTransition(
              opacity: _opacityAnimation,
              child: Column(
                children: [
                  const Text(
                    'RECALL',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4.0,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Study smarter. Remember longer.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            FadeTransition(
              opacity: _opacityAnimation,
              child: const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
