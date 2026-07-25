import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/formatters.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/stat_card.dart';
import '../../data/models/transaction_model.dart';

class SellerConfirmationScreen extends StatefulWidget {
  final EscrowTransaction transaction;
  const SellerConfirmationScreen({super.key, required this.transaction});

  @override
  State<SellerConfirmationScreen> createState() => _SellerConfirmationScreenState();
}

class _SellerConfirmationScreenState extends State<SellerConfirmationScreen> {
  String _courier = 'DHL Express';
  bool _confirmed = false;
  bool _loading = false;

  final List<String> _couriers = const ['DHL Express', 'FedEx', 'Local Courier', 'Self-delivery'];

  void _confirm() {
    setState(() => _loading = true);
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _confirmed = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Confirm Order')),
      body: SafeArea(
        child: _confirmed ? _buildSuccess(context) : _buildForm(context, t),
      ),
    );
  }

  Widget _buildForm(BuildContext context, EscrowTransaction t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.infoTint, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.inventory_2_rounded, color: AppColors.info),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.title, style: AppTextStyles.h3),
                      const SizedBox(height: 3),
                      Text(AppFormatters.currency(t.amount), style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SecurityInfoBanner(
            text: 'By confirming, you agree to ship this order as described. Funds remain safely held until the buyer verifies delivery.',
            icon: Icons.info_outline_rounded,
          ),
          const SizedBox(height: 22),
          Text('Choose courier', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          ..._couriers.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CourierTile(
                  label: c,
                  selected: _courier == c,
                  onTap: () => setState(() => _courier = c),
                ),
              )),
          const SizedBox(height: 8),
          const CustomTextField(
            label: 'Tracking number',
            hint: 'Enter shipment tracking code',
            icon: Icons.confirmation_number_outlined,
          ),
          const SizedBox(height: 18),
          const CustomTextField(
            label: 'Estimated delivery date',
            hint: 'Select a date',
            icon: Icons.calendar_today_outlined,
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: 'Confirm & Ship Order',
            icon: Icons.local_shipping_rounded,
            isLoading: _loading,
            onPressed: _confirm,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.successGradient, boxShadow: AppColors.elevatedShadow),
            child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 26),
          Text('Order Confirmed', style: AppTextStyles.displayMd),
          const SizedBox(height: 8),
          Text(
            'The buyer has been notified. Funds stay secured in escrow until they verify delivery.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd,
          ),
          const Spacer(),
          PrimaryButton(label: 'Done', onPressed: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }
}

class _CourierTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CourierTile({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.skyTint : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.6 : 1),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              size: 20,
              color: selected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 12),
            Text(label, style: AppTextStyles.bodyMd.copyWith(color: AppColors.textPrimary, fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}
