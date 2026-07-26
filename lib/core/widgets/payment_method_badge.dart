import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Generic, clearly-labeled payment method chips. These intentionally
/// use simple icons + brand-appropriate colors rather than reproducing
/// any institution's actual trademarked logo artwork.
class PaymentMethodInfo {
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;

  const PaymentMethodInfo({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  static const nationalBank = PaymentMethodInfo(
    name: 'National Bank',
    subtitle: 'Bank transfer & cards',
    icon: Icons.account_balance_rounded,
    color: AppColors.primary,
  );

  static const airtelMoney = PaymentMethodInfo(
    name: 'Airtel Money',
    subtitle: 'Mobile money',
    icon: Icons.account_balance_wallet_rounded,
    color: Color(0xFFE4002B),
  );

  static const tnmMpamba = PaymentMethodInfo(
    name: 'TNM Mpamba',
    subtitle: 'Mobile money',
    icon: Icons.smartphone_rounded,
    color: Color(0xFF6BAA2C),
  );

  static const all = [nationalBank, airtelMoney, tnmMpamba];
}

/// Small badge shown in a horizontal row (e.g. "Accepted payment methods").
class PaymentMethodBadge extends StatelessWidget {
  final PaymentMethodInfo info;

  const PaymentMethodBadge({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: info.color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(info.icon, size: 17, color: info.color),
          ),
          const SizedBox(height: 6),
          Text(
            info.name,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySm.copyWith(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

/// Full row of accepted payment methods with a heading — used on the
/// escrow review step and the payment hold screen.
class AcceptedPaymentMethodsRow extends StatelessWidget {
  const AcceptedPaymentMethodsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Accepted payment methods', style: AppTextStyles.label),
        const SizedBox(height: 10),
        Row(
          children: PaymentMethodInfo.all
              .map((m) => Expanded(child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: PaymentMethodBadge(info: m),
                  )))
              .toList(),
        ),
      ],
    );
  }
}
