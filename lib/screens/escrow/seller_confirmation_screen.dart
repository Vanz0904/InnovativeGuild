import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/formatters.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/state/session.dart';
import '../../core/network/api_exception.dart';
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
  String? _error;

  final _trackingController = TextEditingController();
  final _dateController = TextEditingController();

  final List<String> _couriers = const ['DHL Express', 'FedEx', 'Local Courier', 'Self-delivery'];

  @override
  void dispose() {
    _trackingController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_trackingController.text.trim().isEmpty) {
      setState(() => _error = 'Enter a tracking number');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = context.read<Session>();
      await session.transactionService.confirmShipment(
        reference: widget.transaction.id,
        courier: _courier,
        trackingCode: _trackingController.text.trim(),
        estimatedDelivery: _dateController.text.trim().isEmpty ? null : _dateController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _confirmed = true;
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
      appBar: AppBar(title: const Text('Confirm Order')),
      body: SafeArea(child: _confirmed ? _buildSuccess(context) : _buildForm(context, t)),
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
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
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
                child: _CourierTile(label: c, selected: _courier == c, onTap: () => setState(() => _courier = c)),
              )),
          const SizedBox(height: 8),
          CustomTextField(label: 'Tracking number', hint: 'Enter shipment tracking code', icon: Icons.confirmation_number_outlined, controller: _trackingController),
          const SizedBox(height: 18),
          CustomTextField(label: 'Estimated delivery date', hint: 'YYYY-MM-DD', icon: Icons.calendar_today_outlined, controller: _dateController),
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
          const SizedBox(height: 28),
          PrimaryButton(label: 'Confirm & Ship Order', icon: Icons.local_shipping_rounded, isLoading: _loading, onPressed: _confirm),
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
          Text('The buyer has been notified. Funds stay secured in escrow until they verify delivery.', textAlign: TextAlign.center, style: AppTextStyles.bodyMd),
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
            Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, size: 20, color: selected ? AppColors.primary : AppColors.textMuted),
            const SizedBox(width: 12),
            Text(label, style: AppTextStyles.bodyMd.copyWith(color: AppColors.textPrimary, fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}
