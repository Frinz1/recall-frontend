import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ConfettiBurst extends StatefulWidget {
  final Widget child;

  const ConfettiBurst({super.key, required this.child});

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();
    final rng = Random(42);
    final colors = [
      AppColors.primary,
      AppColors.accentCyan,
      AppColors.success,
      AppColors.accentPurple,
      const Color(0xFFF43F5E),
    ];

    _particles = List.generate(36, (i) {
      final angle = (i / 36) * 2 * pi + rng.nextDouble() * 0.3;
      final speed = 70.0 + rng.nextDouble() * 110.0;
      return _ConfettiParticle(
        dx: cos(angle) * speed,
        dy: sin(angle) * speed - 40,
        size: 5.0 + rng.nextDouble() * 5.0,
        color: colors[i % colors.length],
        rotationSpeed: (rng.nextDouble() - 0.5) * 8,
      );
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        widget.child,
        IgnorePointer(
          child: SizedBox(
            width: 300,
            height: 220,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ConfettiPainter(
                    progress: _controller.value,
                    particles: _particles,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfettiParticle {
  final double dx;
  final double dy;
  final double size;
  final Color color;
  final double rotationSpeed;

  const _ConfettiParticle({
    required this.dx,
    required this.dy,
    required this.size,
    required this.color,
    required this.rotationSpeed,
  });
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_ConfettiParticle> particles;

  _ConfettiPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return;
    final center = Offset(size.width / 2, size.height * 0.3);
    final opacity = (1.0 - Curves.easeIn.transform(progress)).clamp(0.0, 1.0);

    for (final p in particles) {
      final t = Curves.easeOutCubic.transform(progress);
      final gravity = 110.0 * progress * progress;
      final x = center.dx + p.dx * t;
      final y = center.dy + p.dy * t + gravity;

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotationSpeed * progress);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size * 1.4, height: p.size),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
