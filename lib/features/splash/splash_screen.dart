import 'dart:async';
import 'dart:math' as math;
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
  late final Animation<double> _darkReveal;
  late final Animation<double> _brandFade;
  late final Animation<Offset> _brandSlideUp;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..forward();

    // 1. 0.00 -> 0.30: Emblem slides in horizontally from right to center on pure white canvas
    _slideFromRight = Tween<Offset>(
      begin: const Offset(2.5, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.30, curve: Curves.easeOutCubic),
      ),
    );

    // 2. 0.28 -> 0.68: 3 playful vertical hops in the center
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
        curve: const Interval(0.28, 0.68),
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
        curve: const Interval(0.28, 0.68),
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
        curve: const Interval(0.28, 0.68),
      ),
    );

    // 3. 0.58 -> 0.82: Pure White (#FFFFFF) -> Midnight Slate (AppColors.bgCanvas) radial reveal
    _darkReveal = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.58, 0.82, curve: Curves.easeInOutCubic),
    );

    // 4. 0.62 -> 0.90: Wordmark & Tagline slide/fade up underneath the logo
    _brandFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.62, 0.90, curve: Curves.easeOutCubic),
    );

    _brandSlideUp = Tween<Offset>(
      begin: const Offset(0.0, 0.28),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.62, 0.90, curve: Curves.easeOutCubic),
      ),
    );

    if (widget.onFinished != null) {
      _timer = Timer(const Duration(milliseconds: 3800), () {
        if (mounted && widget.onFinished != null) {
          widget.onFinished!();
        }
      });
    } else if (widget.nextScreen != null) {
      _timer = Timer(
        const Duration(milliseconds: 3800),
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
        final isDarkDominant = _darkReveal.value > 0.5;

        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            alignment: Alignment.center,
            children: [
              // Expanding Circular Radial Reveal from Pure White -> Midnight Slate
              Positioned.fill(
                child: CustomPaint(
                  painter: _CircularRevealPainter(
                    progress: _darkReveal.value,
                    color: AppColors.bgCanvas,
                  ),
                ),
              ),

              // Center Kinetic Brand Choreography
              SafeArea(
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
                                  scaleX: _squashX.value,
                                  scaleY: _squashY.value,
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
                                          color: isDarkDominant
                                              ? AppColors.primary.withValues(alpha: 0.34)
                                              : Colors.black.withValues(alpha: 0.16),
                                          blurRadius: 28,
                                          spreadRadius: isDarkDominant ? 4 : 1,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.bgSurface1,
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
                                    color: (isDarkDominant
                                            ? Colors.black
                                            : AppColors.bgCanvas)
                                        .withValues(
                                      alpha: (0.22 * (1.0 - jumpRatio * 0.6))
                                          .clamp(0.05, 0.28),
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Wordmark & Subtitle Reveal as Midnight Slate takes over
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
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CircularRevealPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _CircularRevealPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.sqrt(
      (size.width * size.width) + (size.height * size.height),
    );
    final currentRadius = maxRadius * progress;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, currentRadius, paint);
  }

  @override
  bool shouldRepaint(covariant _CircularRevealPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
