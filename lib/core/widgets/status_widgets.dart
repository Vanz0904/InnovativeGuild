import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../../data/models/transaction_model.dart';

class StatusBadge extends StatelessWidget {
  final EscrowStatus status;
  final bool small;

  const StatusBadge({super.key, required this.status, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 9 : 12, vertical: small ? 5 : 7),
      decoration: BoxDecoration(
        color: status.tint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: small ? 12 : 14, color: status.color),
          SizedBox(width: small ? 4 : 6),
          Text(
            status.label,
            style: (small ? AppTextStyles.bodySm : AppTextStyles.label).copyWith(
              color: status.color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal 5-step escrow progress indicator — the app's recurring
/// signature element showing the trust journey: Held -> Confirmed ->
/// Shipped -> Verified -> Complete.
class EscrowProgressStepper extends StatelessWidget {
  final EscrowStatus status;

  const EscrowProgressStepper({super.key, required this.status});

  static const List<String> _labels = [
    'Held',
    'Confirmed',
    'Shipped',
    'Verified',
    'Complete',
  ];

  static const List<IconData> _icons = [
    Icons.lock_rounded,
    Icons.storefront_rounded,
    Icons.local_shipping_rounded,
    Icons.fact_check_rounded,
    Icons.verified_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final activeIndex = status.stepIndex;
    final isDisputed = status == EscrowStatus.disputed;

    return Row(
      children: List.generate(_labels.length, (i) {
        final isDone = i < activeIndex || status == EscrowStatus.completed;
        final isActive = i == activeIndex && status != EscrowStatus.completed;
        final color = isDisputed && i == activeIndex
            ? AppColors.danger
            : (isDone || isActive ? AppColors.primary : AppColors.border);

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (i != 0)
                    Expanded(
                      child: Container(
                        height: 2.5,
                        color: isDone ? AppColors.primary : AppColors.border,
                      ),
                    ),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? AppColors.primary
                          : (isActive
                              ? (isDisputed ? AppColors.dangerTint : AppColors.skyTint)
                              : AppColors.surface),
                      border: Border.all(
                        color: color,
                        width: isActive ? 2.2 : 1.4,
                      ),
                    ),
                    child: Icon(
                      isDone ? Icons.check_rounded : _icons[i],
                      size: 16,
                      color: isDone
                          ? Colors.white
                          : (isActive
                              ? (isDisputed ? AppColors.danger : AppColors.primary)
                              : AppColors.textMuted),
                    ),
                  ),
                  if (i != _labels.length - 1)
                    Expanded(
                      child: Container(
                        height: 2.5,
                        color: i < activeIndex - (isDisputed ? 1 : 0)
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _labels[i],
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySm.copyWith(
                  color: isDone || isActive ? AppColors.textPrimary : AppColors.textMuted,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// Small circular donut progress ring used for stat visualizations.
class DonutProgress extends StatelessWidget {
  final double progress; // 0..1
  final Color color;
  final double size;
  final double strokeWidth;
  final Widget? child;

  const DonutProgress({
    super.key,
    required this.progress,
    required this.color,
    this.size = 64,
    this.strokeWidth = 7,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutPainter(progress: progress, color: color, strokeWidth: strokeWidth),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _DonutPainter({required this.progress, required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = color.withOpacity(0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweep = 2 * 3.14159265 * progress.clamp(0, 1);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159265 / 2,
      sweep,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
