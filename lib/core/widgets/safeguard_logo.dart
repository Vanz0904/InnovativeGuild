import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// The SafeGuard signature mark: a shield holding a checkmark, rendered
/// with CustomPainter so it stays crisp at any size and needs no assets.
/// This shield-check motif recurs across the app (splash, security
/// badges, escrow progress rings) as the app's visual signature —
/// standing in for "your money, protected."
class SafeGuardLogo extends StatelessWidget {
  final double size;
  final Color shieldColor;
  final Color checkColor;

  const SafeGuardLogo({
    super.key,
    this.size = 96,
    this.shieldColor = Colors.white,
    this.checkColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ShieldPainter(shieldColor: shieldColor, checkColor: checkColor),
      ),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  final Color shieldColor;
  final Color checkColor;

  _ShieldPainter({required this.shieldColor, required this.checkColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final shieldPath = Path();
    shieldPath.moveTo(w * 0.5, h * 0.02);
    shieldPath.cubicTo(w * 0.5, h * 0.02, w * 0.86, h * 0.16, w * 0.92, h * 0.20);
    shieldPath.lineTo(w * 0.92, h * 0.52);
    shieldPath.cubicTo(w * 0.92, h * 0.78, w * 0.74, h * 0.94, w * 0.5, h * 0.99);
    shieldPath.cubicTo(w * 0.26, h * 0.94, w * 0.08, h * 0.78, w * 0.08, h * 0.52);
    shieldPath.lineTo(w * 0.08, h * 0.20);
    shieldPath.cubicTo(w * 0.14, h * 0.16, w * 0.5, h * 0.02, w * 0.5, h * 0.02);
    shieldPath.close();

    final shieldPaint = Paint()
      ..color = shieldColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(shieldPath, shieldPaint);

    final checkPaint = Paint()
      ..color = checkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final checkPath = Path();
    checkPath.moveTo(w * 0.32, h * 0.52);
    checkPath.lineTo(w * 0.45, h * 0.65);
    checkPath.lineTo(w * 0.70, h * 0.36);
    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant _ShieldPainter oldDelegate) =>
      oldDelegate.shieldColor != shieldColor || oldDelegate.checkColor != checkColor;
}

/// Compact wordmark: shield glyph + "SafeGuard" text, for app bars.
class SafeGuardWordmark extends StatelessWidget {
  final bool dark;
  const SafeGuardWordmark({super.key, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            gradient: AppColors.trustGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const SafeGuardLogo(size: 18, checkColor: AppColors.navy),
        ),
        const SizedBox(width: 10),
        Text(
          'SafeGuard',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: dark ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
