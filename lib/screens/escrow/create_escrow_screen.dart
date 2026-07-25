import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/formatters.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/stat_card.dart';
import 'payment_hold_screen.dart';

class CreateEscrowScreen extends StatefulWidget {
  const CreateEscrowScreen({super.key});

  @override
  State<CreateEscrowScreen> createState() => _CreateEscrowScreenState();
}

class _CreateEscrowScreenState extends State<CreateEscrowScreen> {
  int _step = 0;
  String _category = 'Electronics';
  double _amount = 450000;
  final List<String> _categories = const ['Electronics', 'Vehicles', 'Furniture', 'Fashion', 'Services', 'Other'];

  final double _feeRate = 0.02;

  double get _fee => _amount * _feeRate;
  double get _total => _amount + _fee;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('New Escrow Transaction'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            if (_step == 0) {
              Navigator.pop(context);
            } else {
              setState(() => _step--);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: List.generate(3, (i) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i == 2 ? 0 : 6),
                      height: 5,
                      decoration: BoxDecoration(
                        color: i <= _step ? AppColors.primary : AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildStep(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: PrimaryButton(
                label: _step == 2 ? 'Fund Escrow' : 'Continue',
                icon: _step == 2 ? Icons.lock_rounded : Icons.arrow_forward_rounded,
                onPressed: () {
                  if (_step < 2) {
                    setState(() => _step++);
                  } else {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => PaymentHoldScreen(amount: _total, itemTitle: 'New Item Escrow')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _ItemDetailsStep(key: const ValueKey('s0'), category: _category, onCategoryChanged: (c) => setState(() => _category = c));
      case 1:
        return _CounterpartyStep(key: const ValueKey('s1'));
      default:
        return _ReviewStep(key: const ValueKey('s2'), amount: _amount, fee: _fee, total: _total, onAmountChanged: (v) => setState(() => _amount = v));
    }
  }
}

class _ItemDetailsStep extends StatelessWidget {
  final String category;
  final ValueChanged<String> onCategoryChanged;
  const _ItemDetailsStep({super.key, required this.category, required this.onCategoryChanged});

  @override
  Widget build(BuildContext context) {
    final categories = const ['Electronics', 'Vehicles', 'Furniture', 'Fashion', 'Services', 'Other'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What are you buying?', style: AppTextStyles.h1),
        const SizedBox(height: 6),
        Text('Describe the item or service being protected by escrow', style: AppTextStyles.bodyMd),
        const SizedBox(height: 24),
        const CustomTextField(label: 'Item title', hint: 'e.g. iPhone 14 Pro Max 256GB', icon: Icons.inventory_2_outlined),
        const SizedBox(height: 18),
        Text('Category', style: AppTextStyles.label),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: categories.map((c) {
            final selected = c == category;
            return ChoiceChip(
              label: Text(c),
              selected: selected,
              onSelected: (_) => onCategoryChanged(c),
              labelStyle: AppTextStyles.label.copyWith(color: selected ? Colors.white : AppColors.textSecondary),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
              ),
              showCheckmark: false,
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        const CustomTextField(
          label: 'Description',
          hint: 'Condition, specifications, agreed terms...',
          icon: Icons.notes_rounded,
        ),
      ],
    );
  }
}

class _CounterpartyStep extends StatelessWidget {
  const _CounterpartyStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Who is the seller?', style: AppTextStyles.h1),
        const SizedBox(height: 6),
        Text('Enter their SafeGuard ID, email, or phone number', style: AppTextStyles.bodyMd),
        const SizedBox(height: 24),
        const CustomTextField(label: 'Seller identifier', hint: 'username, email, or phone', icon: Icons.alternate_email_rounded),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.successTint,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.success.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(gradient: AppColors.trustGradient, borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: const Text('TB', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Thandiwe Banda', style: AppTextStyles.h3),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded, size: 15, color: AppColors.success),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('Verified seller · 4.9★ (128 deals)', style: AppTextStyles.bodySm),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const CustomTextField(
          label: 'Delivery address',
          hint: 'Where should the item be delivered?',
          icon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 18),
        const SecurityInfoBanner(
          text: 'SafeGuard only releases payment once you confirm delivery — the seller never receives funds upfront.',
        ),
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  final double amount;
  final double fee;
  final double total;
  final ValueChanged<double> onAmountChanged;

  const _ReviewStep({
    super.key,
    required this.amount,
    required this.fee,
    required this.total,
    required this.onAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Set the amount', style: AppTextStyles.h1),
        const SizedBox(height: 6),
        Text('Review costs before funding the escrow', style: AppTextStyles.bodyMd),
        const SizedBox(height: 24),
        Text('Agreed price', style: AppTextStyles.label),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1.2),
          ),
          child: Row(
            children: [
              Text('MWK', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  amount.toStringAsFixed(0),
                  style: AppTextStyles.amountLg,
                ),
              ),
              Column(
                children: [
                  InkWell(
                    onTap: () => onAmountChanged(amount + 10000),
                    child: const Icon(Icons.keyboard_arrow_up_rounded, color: AppColors.textMuted),
                  ),
                  InkWell(
                    onTap: () => onAmountChanged((amount - 10000).clamp(0, double.infinity)),
                    child: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _SummaryRow(label: 'Item price', value: AppFormatters.currency(amount)),
              const SizedBox(height: 12),
              _SummaryRow(label: 'SafeGuard escrow fee (2%)', value: AppFormatters.currency(fee)),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1),
              ),
              _SummaryRow(
                label: 'Total to fund',
                value: AppFormatters.currency(total),
                isTotal: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const SecurityInfoBanner(
          text: 'Funds are locked in a secure escrow account and only released after delivery verification or dispute resolution.',
          icon: Icons.lock_rounded,
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _SummaryRow({required this.label, required this.value, this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: isTotal ? AppTextStyles.h3 : AppTextStyles.bodyMd),
        Text(
          value,
          style: isTotal ? AppTextStyles.amountMd.copyWith(fontSize: 18) : AppTextStyles.amountSm,
        ),
      ],
    );
  }
}
