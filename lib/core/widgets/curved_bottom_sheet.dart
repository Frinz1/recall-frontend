import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Reusable Curved Bottom Sheet with a sculpted top-center circular close (`✕`) button.
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

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          // Main Curved Sheet Container pushed down slightly so top-center close button sits on the arch
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 22),
            decoration: BoxDecoration(
              color: AppColors.bgSurface1,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: const Border(
                top: BorderSide(color: AppColors.borderSubtle, width: 1.5),
                left: BorderSide(color: AppColors.borderSubtle, width: 1.0),
                right: BorderSide(color: AppColors.borderSubtle, width: 1.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 28,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 34, 24, bottomInset + 28),
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

          // Notched / Floating Circular Close (✕) Button sitting on top arch of sheet
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.bgCanvas,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderSubtle, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
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
