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
  late final Animation<Offset> _slideFromRight;
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

    // 1. 0.00 -> 0.20: Emblem slides in horizontally from right to center
    _slideFromRight = Tween<Offset>(
      begin: const Offset(2.5, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.20, curve: Curves.easeOutCubic),
      ),
    );

    // 2. 0.18 -> 0.44: 3 playful vertical hops in the center
    _bounceDy = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -42.0)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -42.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -22.0)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 16,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -22.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 16,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -10.0)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 16,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -10.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 16,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.18, 0.44),
      ),
    );

    // Subtle squash-and-stretch during the 3 hops
    _squashX = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.94), weight: 18),
      TweenSequenceItem(tween: Tween<double>(begin: 0.94, end: 1.08), weight: 18),
      TweenSequenceItem(tween: Tween<double>(begin: 1.08, end: 0.96), weight: 16),
      TweenSequenceItem(tween: Tween<double>(begin: 0.96, end: 1.05), weight: 16),
      TweenSequenceItem(tween: Tween<double>(begin: 1.05, end: 0.98), weight: 16),
      TweenSequenceItem(tween: Tween<double>(begin: 0.98, end: 1.0), weight: 16),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.18, 0.44),
      ),
    );

    _squashY = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.06), weight: 18),
      TweenSequenceItem(tween: Tween<double>(begin: 1.06, end: 0.92), weight: 18),
      TweenSequenceItem(tween: Tween<double>(begin: 0.92, end: 1.04), weight: 16),
      TweenSequenceItem(tween: Tween<double>(begin: 1.04, end: 0.95), weight: 16),
      TweenSequenceItem(tween: Tween<double>(begin: 0.95, end: 1.02), weight: 16),
      TweenSequenceItem(tween: Tween<double>(begin: 1.02, end: 1.0), weight: 16),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.18, 0.44),
      ),
    );

    // 3. 0.42 -> 0.58: Wordmark & Tagline slide/fade up underneath the logo
    _brandFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.42, 0.58, curve: Curves.easeOutCubic),
    );

    _brandSlideUp = Tween<Offset>(
      begin: const Offset(0.0, 0.28),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.42, 0.58, curve: Curves.easeOutCubic),
      ),
    );

    // 4. 0.58 -> 1.00: Subtle breathing pulse while splash artwork is held in view (+2.5s)
    _breatheGlow = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.05)
            .chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.58, 1.0),
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
        final jumpRatio = (-dy / 42.0).clamp(0.0, 1.0);

        return Scaffold(
          backgroundColor: const Color(0xFF0A0F1D),
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sliding + Bouncing Recall Emblem
                    SlideTransition(
                      position: _slideFromRight,
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
                                width: 104,
                                height: 104,
                                padding: const EdgeInsets.only(bottom: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryDark,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.35),
                                      blurRadius: 28,
                                      spreadRadius: 4,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF162032),
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: AppColors.primary,
                                      width: 2.4,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.bolt_rounded,
                                      color: AppColors.primary,
                                      size: 54,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Reactive Floor Shadow Oval under the bouncing logo
                          Transform.scale(
                            scaleX: 1.0 - (jumpRatio * 0.45),
                            scaleY: 1.0 - (jumpRatio * 0.35),
                            child: Container(
                              width: 56,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(
                                  alpha: (0.30 * (1.0 - jumpRatio * 0.6))
                                      .clamp(0.05, 0.30),
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Wordmark & Subtitle Reveal
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
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                                color: const Color(0xFFF8FAFC),
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
                                color: const Color(0xFF38BDF8),
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
