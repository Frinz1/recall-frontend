import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Reusable Sculpted Curved Bottom Sheet with a top-center circular close (`✕`)
/// button nested in a curved top notch of the sheet container (Reference Image 5).
class CurvedBottomSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const CurvedBottomSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.68),
      builder: (ctx) => CurvedBottomSheet(
        title: title,
        subtitle: subtitle,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.90;

    const cornerRadius = 32.0;
    const notchRadius = 30.0;
    const notchDepth = 26.0;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          // Sculpted Notched Curved Sheet Container
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 22),
            child: CustomPaint(
              painter: _NotchedSheetPainter(
                cornerRadius: cornerRadius,
                notchRadius: notchRadius,
                notchDepth: notchDepth,
                fillColor: AppColors.bgSurface1,
                borderColor: AppColors.borderSubtle,
                isDarkMode: AppColors.isDarkMode,
              ),
              child: ClipPath(
                clipper: const _NotchedSheetClipper(
                  cornerRadius: cornerRadius,
                  notchRadius: notchRadius,
                  notchDepth: notchDepth,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24, 38, 24, bottomInset + 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          title,
                          style: AppTypography.displayMedium.copyWith(fontSize: 20),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            subtitle!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Sculpted Circular Close (✕) Button nested snugly in the top notch cradle
          Positioned(
            top: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.bgSurface1,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderSubtle, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: AppColors.isDarkMode ? 0.35 : 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.close_rounded,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotchedSheetPainter extends CustomPainter {
  final double cornerRadius;
  final double notchRadius;
  final double notchDepth;
  final Color fillColor;
  final Color borderColor;
  final bool isDarkMode;

  const _NotchedSheetPainter({
    required this.cornerRadius,
    required this.notchRadius,
    required this.notchDepth,
    required this.fillColor,
    required this.borderColor,
    required this.isDarkMode,
  });

  static Path buildNotchedPath({
    required Size size,
    required double cornerRadius,
    required double notchRadius,
    required double notchDepth,
  }) {
    final w = size.width;
    final h = size.height;
    final centerX = w / 2;
    final notchHalfWidth = notchRadius + 8.0;

    return Path()
      ..moveTo(0, h)
      ..lineTo(0, cornerRadius)
      ..quadraticBezierTo(0, 0, cornerRadius, 0)
      ..lineTo(centerX - notchHalfWidth, 0)
      // Sculpted concave notch cradling the circular close button
      ..cubicTo(
        centerX - notchRadius,
        0,
        centerX - 16,
        notchDepth,
        centerX,
        notchDepth,
      )
      ..cubicTo(
        centerX + 16,
        notchDepth,
        centerX + notchRadius,
        0,
        centerX + notchHalfWidth,
        0,
      )
      ..lineTo(w - cornerRadius, 0)
      ..quadraticBezierTo(w, 0, w, cornerRadius)
      ..lineTo(w, h)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = buildNotchedPath(
      size: size,
      cornerRadius: cornerRadius,
      notchRadius: notchRadius,
      notchDepth: notchDepth,
    );

    // Ambient drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDarkMode ? 0.45 : 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.save();
    canvas.translate(0, -4);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // Fill surface
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Border along the notched top silhouette and sides
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(_NotchedSheetPainter oldDelegate) =>
      oldDelegate.cornerRadius != cornerRadius ||
      oldDelegate.notchRadius != notchRadius ||
      oldDelegate.notchDepth != notchDepth ||
      oldDelegate.fillColor != fillColor ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.isDarkMode != isDarkMode;
}

class _NotchedSheetClipper extends CustomClipper<Path> {
  final double cornerRadius;
  final double notchRadius;
  final double notchDepth;

  const _NotchedSheetClipper({
    required this.cornerRadius,
    required this.notchRadius,
    required this.notchDepth,
  });

  @override
  Path getClip(Size size) {
    return _NotchedSheetPainter.buildNotchedPath(
      size: size,
      cornerRadius: cornerRadius,
      notchRadius: notchRadius,
      notchDepth: notchDepth,
    );
  }

  @override
  bool shouldReclip(_NotchedSheetClipper oldClipper) =>
      oldClipper.cornerRadius != cornerRadius ||
      oldClipper.notchRadius != notchRadius ||
      oldClipper.notchDepth != notchDepth;
}
