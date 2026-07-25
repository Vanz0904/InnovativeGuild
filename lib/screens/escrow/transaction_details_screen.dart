import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/formatters.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/status_widgets.dart';
import '../../core/widgets/stat_card.dart';
import '../../data/models/transaction_model.dart';
import 'seller_confirmation_screen.dart';
import 'delivery_verification_screen.dart';
import 'dispute_resolution_screen.dart';

class TransactionDetailsScreen extends StatelessWidget {
  final EscrowTransaction transaction;

  const TransactionDetailsScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isBuyer = transaction.myRole == TransactionRole.buyer;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount hero
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(transaction.id, style: AppTextStyles.mono.copyWith(color: Colors.white.withOpacity(0.7))),
                        StatusBadge(status: transaction.status, small: true),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(transaction.title, style: AppTextStyles.h1.copyWith(color: Colors.white)),
                    const SizedBox(height: 10),
                    Text(AppFormatters.currency(transaction.amount), style: AppTextStyles.amountXl.copyWith(fontSize: 30)),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text('Escrow Progress', style: AppTextStyles.h2),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: EscrowProgressStepper(status: transaction.status),
              ),
              const SizedBox(height: 22),
              Text(isBuyer ? 'Seller' : 'Buyer', style: AppTextStyles.h2),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(gradient: AppColors.trustGradient, borderRadius: BorderRadius.circular(14)),
                      alignment: Alignment.center,
                      child: Text(transaction.counterpartyInitials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(transaction.counterpartyName, style: AppTextStyles.h3),
                              const SizedBox(width: 6),
                              const Icon(Icons.verified_rounded, size: 14, color: AppColors.success),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text('Verified · 4.9★ rating', style: AppTextStyles.bodySm),
                        ],
                      ),
                    ),
                    GhostIconButton(icon: Icons.chat_bubble_outline_rounded, onPressed: () {}),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text('Transaction Info', style: AppTextStyles.h2),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _InfoRow(label: 'Category', value: transaction.category),
                    const Divider(height: 1),
                    _InfoRow(label: 'Created', value: AppFormatters.dateTime(transaction.createdAt)),
                    if (transaction.expectedCompletion != null) ...[
                      const Divider(height: 1),
                      _InfoRow(label: 'Expected completion', value: AppFormatters.date(transaction.expectedCompletion!)),
                    ],
                    if (transaction.trackingCode != null) ...[
                      const Divider(height: 1),
                      _InfoRow(label: 'Tracking code', value: transaction.trackingCode!, mono: true),
                    ],
                    const Divider(height: 1),
                    _InfoRow(label: 'Escrow fee', value: AppFormatters.currency(transaction.amount * 0.02)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildActionButtons(context),
              const SizedBox(height: 14),
              SecondaryButton(
                label: 'Open a Dispute',
                icon: Icons.gavel_rounded,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => DisputeResolutionScreen(transaction: transaction)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    switch (transaction.status) {
      case EscrowStatus.paymentHeld:
        return transaction.myRole == TransactionRole.seller
            ? PrimaryButton(
                label: 'Confirm Order & Ship',
                icon: Icons.storefront_rounded,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SellerConfirmationScreen(transaction: transaction)),
                ),
              )
            : const SecurityInfoBanner(text: 'Waiting for the seller to confirm and ship your order.');
      case EscrowStatus.sellerConfirmed:
      case EscrowStatus.inTransit:
        return transaction.myRole == TransactionRole.buyer
            ? PrimaryButton(
                label: 'Track & Verify Delivery',
                icon: Icons.local_shipping_rounded,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => DeliveryVerificationScreen(transaction: transaction)),
                ),
              )
            : const SecurityInfoBanner(text: 'Your item is on the way. Funds release once the buyer verifies delivery.');
      case EscrowStatus.deliveryVerification:
        return transaction.myRole == TransactionRole.buyer
            ? PrimaryButton(
                label: 'Confirm Delivery & Release Funds',
                icon: Icons.task_alt_rounded,
                gradient: AppColors.successGradient,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => DeliveryVerificationScreen(transaction: transaction)),
                ),
              )
            : const SecurityInfoBanner(text: 'Waiting for the buyer to confirm delivery and release funds.');
      case EscrowStatus.completed:
        return const SecurityInfoBanner(
          text: 'This transaction is complete. Funds have been released.',
          icon: Icons.verified_rounded,
          color: AppColors.success,
        );
      case EscrowStatus.disputed:
        return PrimaryButton(
          label: 'View Dispute Case',
          icon: Icons.gavel_rounded,
          gradient: const LinearGradient(colors: [AppColors.danger, Color(0xFFEF7B72)]),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => DisputeResolutionScreen(transaction: transaction)),
          ),
        );
      case EscrowStatus.refunded:
        return const SecurityInfoBanner(
          text: 'This transaction was refunded to the buyer.',
          icon: Icons.replay_rounded,
          color: AppColors.textMuted,
        );
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;

  const _InfoRow({required this.label, required this.value, this.mono = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMd),
          Text(value, style: mono ? AppTextStyles.mono.copyWith(color: AppColors.textPrimary) : AppTextStyles.label.copyWith(color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
