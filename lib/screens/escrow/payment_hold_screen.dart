import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/formatters.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/safeguard_logo.dart';
import '../../core/widgets/app_shell.dart';

class PaymentHoldScreen extends StatefulWidget {
  final double amount;
  final String itemTitle;

  const PaymentHoldScreen({super.key, required this.amount, required this.itemTitle});

  @override
  State<PaymentHoldScreen> createState() => _PaymentHoldScreenState();
}

class _PaymentHoldScreenState extends State<PaymentHoldScreen> with SingleTickerProviderStateMixin {
  bool _processing = true;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() => _processing = false);
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _processing ? _buildProcessing() : _buildSuccess(),
              ),
              const Spacer(),
              if (!_processing)
                Column(
                  children: [
                    PrimaryButton(
                      label: 'Go to Dashboard',
                      icon: Icons.dashboard_rounded,
                      gradient: AppColors.successGradient,
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const AppShell()),
                          (route) => false,
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Funds are locked until delivery is verified',
                      style: AppTextStyles.bodySm.copyWith(color: Colors.white.withOpacity(0.55)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessing() {
    return Column(
      key: const ValueKey('processing'),
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.06),
            border: Border.all(color: Colors.white.withOpacity(0.14)),
          ),
          child: Center(
            child: SizedBox(
              width: 46,
              height: 46,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(AppColors.skyAccent),
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
        Text(
          'Securing your funds',
          style: AppTextStyles.h1.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          'Encrypting and placing ${AppFormatters.currency(widget.amount)} into escrow',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMd.copyWith(color: Colors.white.withOpacity(0.65)),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      key: const ValueKey('success'),
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.5, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.successGradient,
              boxShadow: [BoxShadow(color: AppColors.success.withOpacity(0.4), blurRadius: 30, offset: const Offset(0, 12))],
            ),
            child: const SafeGuardLogo(size: 60, checkColor: AppColors.success),
          ),
        ),
        const SizedBox(height: 30),
        Text('Payment Secured', style: AppTextStyles.h1.copyWith(color: Colors.white)),
        const SizedBox(height: 8),
        Text(
          AppFormatters.currency(widget.amount),
          style: AppTextStyles.amountXl,
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            'The seller has been notified to confirm and ship your order',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySm.copyWith(color: Colors.white.withOpacity(0.75), height: 1.5),
          ),
        ),
      ],
    );
  }
}
