import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/formatters.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/stat_card.dart';
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

  final List<_TrackingEvent> _events = [
    _TrackingEvent('Order confirmed by seller', 'Yesterday, 9:14 AM', true),
    _TrackingEvent('Package picked up by courier', 'Yesterday, 2:40 PM', true),
    _TrackingEvent('In transit to destination hub', 'Today, 7:05 AM', true),
    _TrackingEvent('Out for delivery', 'Today, 11:20 AM', true),
    _TrackingEvent('Delivered — awaiting your confirmation', 'Pending', false),
  ];

  void _release() {
    setState(() => _loading = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _released = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Verify Delivery')),
      body: SafeArea(
        child: _released ? _buildSuccess(context, t) : _buildBody(context, t),
      ),
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
            decoration: BoxDecoration(
              gradient: AppColors.trustGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppColors.cardShadow,
            ),
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
                      Text(t.trackingCode ?? 'SG-TRK-0000', style: AppTextStyles.mono.copyWith(color: Colors.white.withOpacity(0.75))),
                      const SizedBox(height: 4),
                      Text(t.title, style: AppTextStyles.h3.copyWith(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Shipment Timeline', style: AppTextStyles.h2),
          const SizedBox(height: 16),
          ...List.generate(_events.length, (i) => _buildTimelineTile(_events[i], i == _events.length - 1)),
          const SizedBox(height: 24),
          const SecurityInfoBanner(
            text: 'Inspect the item carefully. Once you confirm, funds are released to the seller immediately and cannot be reversed automatically.',
            icon: Icons.info_outline_rounded,
          ),
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
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => DisputeResolutionScreen(transaction: t)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTile(_TrackingEvent event, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: event.done ? AppColors.primary : AppColors.surface,
                  border: Border.all(color: event.done ? AppColors.primary : AppColors.border, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: event.done ? AppColors.primary : AppColors.border),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: event.done ? AppColors.textPrimary : AppColors.textMuted,
                      fontWeight: event.done ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(event.time, style: AppTextStyles.bodySm),
                ],
              ),
            ),
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

class _TrackingEvent {
  final String title;
  final String time;
  final bool done;
  _TrackingEvent(this.title, this.time, this.done);
}
