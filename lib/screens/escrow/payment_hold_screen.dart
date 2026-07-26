import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/formatters.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/safeguard_logo.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/state/session.dart';
import '../../data/models/transaction_model.dart';

enum _PayState { loadingTransaction, readyToPay, processing, success, failed }

class PaymentHoldScreen extends StatefulWidget {
  final String transactionReference;
  const PaymentHoldScreen({super.key, required this.transactionReference});

  @override
  State<PaymentHoldScreen> createState() => _PaymentHoldScreenState();
}

class _PaymentHoldScreenState extends State<PaymentHoldScreen> {
  _PayState _state = _PayState.loadingTransaction;
  EscrowTransaction? _transaction;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTransaction();
  }

  Future<void> _loadTransaction() async {
    try {
      final session = context.read<Session>();
      final tx = await session.transactionService.getByReference(widget.transactionReference);
      setState(() {
        _transaction = tx;
        _state = _PayState.readyToPay;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not load this transaction.';
        _state = _PayState.failed;
      });
    }
  }

  Future<void> _pay() async {
    setState(() => _state = _PayState.processing);
    final session = context.read<Session>();
    final result = await session.paymentService.payForTransaction(
      context: context,
      transactionReference: widget.transactionReference,
    );

    if (!mounted) return;

    if (result.success) {
      setState(() => _state = _PayState.success);
    } else {
      setState(() {
        _state = _PayState.failed;
        _errorMessage = result.errorMessage ?? 'Payment could not be completed.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: AnimatedSwitcher(duration: const Duration(milliseconds: 400), child: _buildForState()),
        ),
      ),
    );
  }

  Widget _buildForState() {
    switch (_state) {
      case _PayState.loadingTransaction:
        return const Center(key: ValueKey('loading'), child: CircularProgressIndicator(color: Colors.white));
      case _PayState.readyToPay:
        return _buildReadyToPay();
      case _PayState.processing:
        return _buildProcessing();
      case _PayState.success:
        return _buildSuccess();
      case _PayState.failed:
        return _buildFailed();
    }
  }

  Widget _buildReadyToPay() {
    final tx = _transaction!;
    return Column(
      key: const ValueKey('ready'),
      children: [
        IconButton(
          alignment: Alignment.centerLeft,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        const Spacer(),
        const SafeGuardLogo(size: 64, checkColor: AppColors.navy),
        const SizedBox(height: 24),
        Text(tx.title, textAlign: TextAlign.center, style: AppTextStyles.h1.copyWith(color: Colors.white)),
        const SizedBox(height: 10),
        Text(AppFormatters.currency(tx.total), style: AppTextStyles.amountXl),
        const SizedBox(height: 6),
        Text(
          'Includes ${AppFormatters.currency(tx.fee)} SafeGuard escrow fee',
          style: AppTextStyles.bodySm.copyWith(color: Colors.white.withOpacity(0.6)),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
          child: Text(
            'You will be redirected to Flutterwave\'s secure checkout to pay by card, bank transfer, or mobile money.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySm.copyWith(color: Colors.white.withOpacity(0.75), height: 1.5),
          ),
        ),
        const Spacer(),
        PrimaryButton(label: 'Pay ${AppFormatters.currency(tx.total)}', icon: Icons.lock_rounded, onPressed: _pay),
      ],
    );
  }

  Widget _buildProcessing() {
    return Column(
      key: const ValueKey('processing'),
      children: [
        const Spacer(),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06), border: Border.all(color: Colors.white.withOpacity(0.14))),
          child: Center(
            child: SizedBox(width: 46, height: 46, child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation(AppColors.skyAccent))),
          ),
        ),
        const SizedBox(height: 30),
        Text('Securing your funds', style: AppTextStyles.h1.copyWith(color: Colors.white)),
        const SizedBox(height: 8),
        Text(
          'Confirming payment with Flutterwave...',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMd.copyWith(color: Colors.white.withOpacity(0.65)),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildSuccess() {
    final tx = _transaction!;
    return Column(
      key: const ValueKey('success'),
      children: [
        const Spacer(),
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
        Text(AppFormatters.currency(tx.total), style: AppTextStyles.amountXl),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
          child: Text(
            'The seller has been notified to confirm and ship your order',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySm.copyWith(color: Colors.white.withOpacity(0.75), height: 1.5),
          ),
        ),
        const Spacer(),
        PrimaryButton(
          label: 'Go to Dashboard',
          icon: Icons.dashboard_rounded,
          gradient: AppColors.successGradient,
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const AppShell()), (route) => false);
          },
        ),
      ],
    );
  }

  Widget _buildFailed() {
    return Column(
      key: const ValueKey('failed'),
      children: [
        const Spacer(),
        Container(
          width: 110,
          height: 110,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.danger),
          child: const Icon(Icons.close_rounded, color: Colors.white, size: 50),
        ),
        const SizedBox(height: 26),
        Text('Payment Failed', style: AppTextStyles.h1.copyWith(color: Colors.white)),
        const SizedBox(height: 10),
        Text(
          _errorMessage ?? 'Something went wrong while processing your payment.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMd.copyWith(color: Colors.white.withOpacity(0.7)),
        ),
        const Spacer(),
        PrimaryButton(
          label: 'Try Again',
          icon: Icons.refresh_rounded,
          onPressed: () => setState(() => _state = _PayState.readyToPay),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: AppTextStyles.label.copyWith(color: Colors.white.withOpacity(0.6))),
        ),
      ],
    );
  }
}
