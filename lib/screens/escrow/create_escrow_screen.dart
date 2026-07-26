import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/formatters.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/payment_method_badge.dart';
import '../../core/state/session.dart';
import '../../core/network/api_exception.dart';
import '../../data/models/user_model.dart';
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
  bool _submitting = false;
  String? _error;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sellerSearchController = TextEditingController();
  final _addressController = TextEditingController();

  UserSummary? _selectedSeller;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _sellerSearchController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() {
        _step = 0;
        _error = 'Give this escrow a title';
      });
      return;
    }
    if (_selectedSeller == null) {
      setState(() {
        _step = 1;
        _error = 'Choose a seller before continuing';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final session = context.read<Session>();
      final tx = await session.transactionService.create(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        category: _category,
        sellerId: _selectedSeller!.id,
        amount: _amount,
        deliveryAddress: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => PaymentHoldScreen(transactionReference: tx.id)),
      );
    } on ApiException catch (e) {
      setState(() {
        _submitting = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _submitting = false;
        _error = 'Could not reach the server. Check your connection and try again.';
      });
    }
  }

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: _buildStep()),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.dangerTint, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.danger),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_error!, style: AppTextStyles.bodySm.copyWith(color: AppColors.danger))),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: PrimaryButton(
                label: _step == 2 ? 'Fund Escrow' : 'Continue',
                icon: _step == 2 ? Icons.lock_rounded : Icons.arrow_forward_rounded,
                isLoading: _submitting,
                onPressed: () {
                  setState(() => _error = null);
                  if (_step < 2) {
                    if (_step == 0 && _titleController.text.trim().isEmpty) {
                      setState(() => _error = 'Give this escrow a title');
                      return;
                    }
                    if (_step == 1 && _selectedSeller == null) {
                      setState(() => _error = 'Choose a seller before continuing');
                      return;
                    }
                    setState(() => _step++);
                  } else {
                    _submit();
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
        return _ItemDetailsStep(
          key: const ValueKey('s0'),
          titleController: _titleController,
          descriptionController: _descriptionController,
          category: _category,
          onCategoryChanged: (c) => setState(() => _category = c),
        );
      case 1:
        return _CounterpartyStep(
          key: const ValueKey('s1'),
          searchController: _sellerSearchController,
          addressController: _addressController,
          selectedSeller: _selectedSeller,
          onSellerSelected: (s) => setState(() => _selectedSeller = s),
        );
      default:
        return _ReviewStep(
          key: const ValueKey('s2'),
          amount: _amount,
          onAmountChanged: (v) => setState(() => _amount = v),
        );
    }
  }
}

class _ItemDetailsStep extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final String category;
  final ValueChanged<String> onCategoryChanged;

  const _ItemDetailsStep({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.category,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    const categories = ['Electronics', 'Vehicles', 'Furniture', 'Fashion', 'Services', 'Other'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What are you buying?', style: AppTextStyles.h1),
        const SizedBox(height: 6),
        Text('Describe the item or service being protected by escrow', style: AppTextStyles.bodyMd),
        const SizedBox(height: 24),
        CustomTextField(label: 'Item title', hint: 'e.g. iPhone 14 Pro Max 256GB', icon: Icons.inventory_2_outlined, controller: titleController),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: selected ? AppColors.primary : AppColors.border)),
              showCheckmark: false,
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        CustomTextField(
          label: 'Description',
          hint: 'Condition, specifications, agreed terms...',
          icon: Icons.notes_rounded,
          controller: descriptionController,
        ),
      ],
    );
  }
}

class _CounterpartyStep extends StatefulWidget {
  final TextEditingController searchController;
  final TextEditingController addressController;
  final UserSummary? selectedSeller;
  final ValueChanged<UserSummary?> onSellerSelected;

  const _CounterpartyStep({
    super.key,
    required this.searchController,
    required this.addressController,
    required this.selectedSeller,
    required this.onSellerSelected,
  });

  @override
  State<_CounterpartyStep> createState() => _CounterpartyStepState();
}

class _CounterpartyStepState extends State<_CounterpartyStep> {
  List<UserSummary> _results = [];
  bool _searching = false;
  Timer? _debounce;

  void _onChanged(String query) {
    widget.onSellerSelected(null);
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _searching = true);
      try {
        final session = context.read<Session>();
        final results = await session.userService.searchSellers(query.trim());
        if (mounted) setState(() => _results = results);
      } catch (_) {
        if (mounted) setState(() => _results = []);
      } finally {
        if (mounted) setState(() => _searching = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Who is the seller?', style: AppTextStyles.h1),
        const SizedBox(height: 6),
        Text('Search by their SafeGuard email, phone, or name', style: AppTextStyles.bodyMd),
        const SizedBox(height: 24),
        CustomTextField(
          label: 'Seller search',
          hint: 'email, phone, or name',
          icon: Icons.alternate_email_rounded,
          controller: widget.searchController,
          onChanged: _onChanged,
          suffix: _searching
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : null,
        ),
        const SizedBox(height: 12),
        if (widget.selectedSeller != null)
          _SelectedSellerCard(seller: widget.selectedSeller!, onClear: () => widget.onSellerSelected(null))
        else if (_results.isNotEmpty)
          Column(
            children: _results
                .map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SellerResultTile(seller: s, onTap: () => widget.onSellerSelected(s)),
                    ))
                .toList(),
          ),
        const SizedBox(height: 18),
        CustomTextField(
          label: 'Delivery address',
          hint: 'Where should the item be delivered?',
          icon: Icons.location_on_outlined,
          controller: widget.addressController,
        ),
        const SizedBox(height: 18),
        const SecurityInfoBanner(
          text: 'SafeGuard only releases payment once you confirm delivery — the seller never receives funds upfront.',
        ),
      ],
    );
  }
}

class _SellerResultTile extends StatelessWidget {
  final UserSummary seller;
  final VoidCallback onTap;
  const _SellerResultTile({required this.seller, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(gradient: AppColors.trustGradient, borderRadius: BorderRadius.circular(11)),
              alignment: Alignment.center,
              child: Text(seller.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(seller.fullName, style: AppTextStyles.h3.copyWith(fontSize: 14)),
                    if (seller.isVerified) ...[
                      const SizedBox(width: 5),
                      const Icon(Icons.verified_rounded, size: 13, color: AppColors.success),
                    ],
                  ]),
                  Text(seller.email, style: AppTextStyles.bodySm),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _SelectedSellerCard extends StatelessWidget {
  final UserSummary seller;
  final VoidCallback onClear;
  const _SelectedSellerCard({required this.seller, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.successTint, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.success.withOpacity(0.25))),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(gradient: AppColors.trustGradient, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Text(seller.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(seller.fullName, style: AppTextStyles.h3),
                  if (seller.isVerified) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.verified_rounded, size: 15, color: AppColors.success),
                  ],
                ]),
                const SizedBox(height: 2),
                Text('Trust score ${seller.trustScore} · ${seller.email}', style: AppTextStyles.bodySm),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: onClear),
        ],
      ),
    );
  }
}

class _ReviewStep extends StatelessWidget {
  final double amount;
  final ValueChanged<double> onAmountChanged;

  const _ReviewStep({super.key, required this.amount, required this.onAmountChanged});

  static const double feeRate = 0.02;

  @override
  Widget build(BuildContext context) {
    final fee = amount * feeRate;
    final total = amount + fee;
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
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border, width: 1.2)),
          child: Row(
            children: [
              Text('MWK', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(width: 10),
              Expanded(child: Text(amount.toStringAsFixed(0), style: AppTextStyles.amountLg)),
              Column(
                children: [
                  InkWell(onTap: () => onAmountChanged(amount + 10000), child: const Icon(Icons.keyboard_arrow_up_rounded, color: AppColors.textMuted)),
                  InkWell(onTap: () => onAmountChanged((amount - 10000).clamp(0, double.infinity)), child: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
          child: Column(
            children: [
              _SummaryRow(label: 'Item price', value: AppFormatters.currency(amount)),
              const SizedBox(height: 12),
              _SummaryRow(label: 'SafeGuard escrow fee (2%)', value: AppFormatters.currency(fee)),
              const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1)),
              _SummaryRow(label: 'Total to fund', value: AppFormatters.currency(total), isTotal: true),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const AcceptedPaymentMethodsRow(),
        const SizedBox(height: 22),
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
        Text(value, style: isTotal ? AppTextStyles.amountMd.copyWith(fontSize: 18) : AppTextStyles.amountSm),
      ],
    );
  }
}
