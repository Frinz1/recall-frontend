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

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _dropFromTop;
  late final Animation<double> _bounceDy;
  late final Animation<double> _squashX;
  late final Animation<double> _squashY;
  late final Animation<double> _brandFade;
  late final Animation<Offset> _brandSlideUp;
  late final Animation<double> _breatheGlow;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Extended duration: 6000ms (+2.2s from original 3800ms) to allow at least
    // 2.5s of peaceful hold time for users to admire the full splash artwork.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..forward();

    // 1. 0.00 -> 0.28: 3D Stacked Cards drop vertically from top into center (WebM sample)
    _dropFromTop = Tween<Offset>(
      begin: const Offset(0.0, -3.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.28, curve: Curves.easeInQuad),
      ),
    );

    // 2. 0.26 -> 0.48: Satisfying physical bounce on landing
    _bounceDy = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -36.0)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 24,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -36.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 24,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -16.0)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -16.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -6.0)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 8,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -6.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 8,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.26, 0.48),
      ),
    );

    // Subtle squash-and-stretch on landing and rebounds
    _squashX = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.14), weight: 12),
      TweenSequenceItem(tween: Tween<double>(begin: 1.14, end: 0.94), weight: 18),
      TweenSequenceItem(tween: Tween<double>(begin: 0.94, end: 1.06), weight: 18),
      TweenSequenceItem(tween: Tween<double>(begin: 1.06, end: 0.97), weight: 18),
      TweenSequenceItem(tween: Tween<double>(begin: 0.97, end: 1.03), weight: 18),
      TweenSequenceItem(tween: Tween<double>(begin: 1.03, end: 1.0), weight: 16),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.26, 0.48),
      ),
    );

    _squashY = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.88), weight: 12),
      TweenSequenceItem(tween: Tween<double>(begin: 0.88, end: 1.06), weight: 18),
      TweenSequenceItem(tween: Tween<double>(begin: 1.06, end: 0.94), weight: 18),
      TweenSequenceItem(tween: Tween<double>(begin: 0.94, end: 1.03), weight: 18),
      TweenSequenceItem(tween: Tween<double>(begin: 1.03, end: 0.98), weight: 18),
      TweenSequenceItem(tween: Tween<double>(begin: 0.98, end: 1.0), weight: 16),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.26, 0.48),
      ),
    );

    // 3. 0.46 -> 0.62: Wordmark & Tagline slide/fade up underneath the logo
    _brandFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.46, 0.62, curve: Curves.easeOutCubic),
    );

    _brandSlideUp = Tween<Offset>(
      begin: const Offset(0.0, 0.28),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.46, 0.62, curve: Curves.easeOutCubic),
      ),
    );

    // 4. 0.62 -> 1.00: Subtle breathing pulse while splash artwork is held in view (+2.5s)
    _breatheGlow = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.04)
            .chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.04, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.62, 1.0),
      ),
    );

    if (widget.onFinished != null) {
      _timer = Timer(const Duration(milliseconds: 6000), () {
        if (mounted && widget.onFinished != null) {
          widget.onFinished!();
        }
      });
    } else if (widget.nextScreen != null) {
      _timer = Timer(
        const Duration(milliseconds: 6000),
        _checkSessionAndNavigate,
      );
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final dy = _bounceDy.value;
        final jumpRatio = (-dy / 36.0).clamp(0.0, 1.0);

        return Scaffold(
          backgroundColor: AppColors.bgCanvas,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Vertical Drop + Bouncing 3D Card Stack Emblem (from WebM sample)
                    SlideTransition(
                      position: _dropFromTop,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.translate(
                            offset: Offset(0, dy),
                            child: Transform.scale(
                              scaleX: _squashX.value * _breatheGlow.value,
                              scaleY: _squashY.value * _breatheGlow.value,
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: 140,
                                height: 165,
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFD97706).withValues(alpha: 0.18 * _breatheGlow.value),
                                      blurRadius: 36,
                                      spreadRadius: 8,
                                      offset: const Offset(0, 14),
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/images/recall_logo.png',
                                  width: 140,
                                  height: 165,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(
                                      Icons.layers_rounded,
                                      color: AppColors.primary,
                                      size: 80,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Reactive Floor Shadow Oval under the bouncing 3D cards
                          Transform.scale(
                            scaleX: (1.0 - (jumpRatio * 0.45)).clamp(0.4, 1.2),
                            scaleY: (1.0 - (jumpRatio * 0.35)).clamp(0.4, 1.2),
                            child: Container(
                              width: 80,
                              height: 12,
                              decoration: BoxDecoration(
                                color: (AppColors.isDarkMode
                                        ? Colors.black
                                        : const Color(0xFF4A4538))
                                    .withValues(
                                  alpha: (0.18 * (1.0 - jumpRatio * 0.6))
                                      .clamp(0.04, 0.20),
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),

                    // Wordmark & Subtitle Reveal (Fade & Slide Up)
                    FadeTransition(
                      opacity: _brandFade,
                      child: SlideTransition(
                        position: _brandSlideUp,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Recall',
                              textAlign: TextAlign.center,
                              style: AppTypography.displayLarge.copyWith(
                                fontSize: 42,
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
                                color: AppColors.isDarkMode
                                    ? const Color(0xFF38BDF8)
                                    : const Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
