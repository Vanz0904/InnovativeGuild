import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/formatters.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/state/session.dart';
import '../../core/network/api_exception.dart';
import '../../data/models/transaction_model.dart';
import 'dispute_resolution_screen.dart';

class DeliveryVerificationScreen extends StatefulWidget {
  final EscrowTransaction transaction;
  const DeliveryVerificationScreen({super.key, required this.transaction});

  @override
  State<DeliveryVerificationScreen> createState() => _DeliveryVerificationScreenState();
}

class _DeliveryVerificationScreenState extends State<DeliveryVerificationScreen> {
  bool _released = false;
  bool _loading = false;
  String? _error;

  Future<void> _release() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = context.read<Session>();
      await session.transactionService.releaseFunds(widget.transaction.id);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _released = true;
      });
    } on ApiException catch (e) {
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Could not reach the server. Check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Verify Delivery')),
      body: SafeArea(child: _released ? _buildSuccess(context, t) : _buildBody(context, t)),
    );
  }

  Widget _buildBody(BuildContext context, EscrowTransaction t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(gradient: AppColors.trustGradient, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.local_shipping_rounded, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.trackingCode ?? 'No tracking code provided', style: AppTextStyles.mono.copyWith(color: Colors.white.withOpacity(0.75))),
                      const SizedBox(height: 4),
                      Text(t.title, style: AppTextStyles.h3.copyWith(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Shipment Details', style: AppTextStyles.h2),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
            child: Column(
              children: [
                _DetailRow(label: 'Courier', value: t.courier ?? 'Not specified'),
                const Divider(height: 24),
                _DetailRow(label: 'Tracking code', value: t.trackingCode ?? '—'),
                const Divider(height: 24),
                _DetailRow(
                  label: 'Expected delivery',
                  value: t.expectedCompletion != null ? AppFormatters.date(t.expectedCompletion!) : 'Not specified',
                ),
                const Divider(height: 24),
                _DetailRow(label: 'Delivery address', value: t.deliveryAddress ?? 'Not specified'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SecurityInfoBanner(
            text: 'Inspect the item carefully. Once you confirm, funds are released to the seller immediately and cannot be reversed automatically.',
            icon: Icons.info_outline_rounded,
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.dangerTint, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.danger),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: AppTextStyles.bodySm.copyWith(color: AppColors.danger))),
              ]),
            ),
          ],
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Confirm Delivery & Release Funds',
            icon: Icons.task_alt_rounded,
            gradient: AppColors.successGradient,
            isLoading: _loading,
            onPressed: _release,
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: 'Report a Problem',
            icon: Icons.report_gmailerrorred_rounded,
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DisputeResolutionScreen(transaction: t))),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(BuildContext context, EscrowTransaction t) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.successGradient, boxShadow: AppColors.elevatedShadow),
            child: const Icon(Icons.verified_rounded, color: Colors.white, size: 50),
          ),
          const SizedBox(height: 26),
          Text('Funds Released', style: AppTextStyles.displayMd),
          const SizedBox(height: 8),
          Text(
            '${AppFormatters.currency(t.amount)} has been released to ${t.counterpartyName}. Thank you for using SafeGuard.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd,
          ),
          const Spacer(),
          PrimaryButton(label: 'Back to Dashboard', onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMd),
        Flexible(child: Text(value, textAlign: TextAlign.right, style: AppTextStyles.label.copyWith(color: AppColors.textPrimary))),
      ],
    );
  }
}
