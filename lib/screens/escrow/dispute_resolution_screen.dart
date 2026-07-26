import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/state/session.dart';
import '../../core/network/api_exception.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/notification_model.dart';

class DisputeResolutionScreen extends StatefulWidget {
  final EscrowTransaction transaction;
  const DisputeResolutionScreen({super.key, required this.transaction});

  @override
  State<DisputeResolutionScreen> createState() => _DisputeResolutionScreenState();
}

class _DisputeResolutionScreenState extends State<DisputeResolutionScreen> {
  bool _loadingExisting = true;
  DisputeCase? _existingCase;
  String? _reason;
  final _descriptionController = TextEditingController();
  bool _submitting = false;
  String? _error;

  final List<String> _reasons = const [
    'Item not received',
    'Item not as described',
    'Damaged or defective item',
    'Wrong item delivered',
    'Seller unresponsive',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _checkExisting();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _checkExisting() async {
    if (widget.transaction.status != EscrowStatus.disputed) {
      setState(() => _loadingExisting = false);
      return;
    }
    try {
      final session = context.read<Session>();
      final dispute = await session.disputeService.forTransaction(widget.transaction.id);
      setState(() {
        _existingCase = dispute;
        _loadingExisting = false;
      });
    } catch (_) {
      setState(() => _loadingExisting = false);
    }
  }

  Future<void> _submit() async {
    if (_reason == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final session = context.read<Session>();
      final dispute = await session.disputeService.file(
        transactionReference: widget.transaction.id,
        reason: _reason!,
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _existingCase = dispute;
        _submitting = false;
      });
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
      appBar: AppBar(title: const Text('Dispute Resolution')),
      body: SafeArea(
        child: _loadingExisting
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : (_existingCase != null ? _buildCaseTracker(context, _existingCase!) : _buildFileForm(context)),
      ),
    );
  }

  Widget _buildFileForm(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SecurityInfoBanner(
            text: 'Filing a dispute pauses fund release and notifies our resolution team to review both sides.',
            icon: Icons.pause_circle_outline_rounded,
            color: AppColors.warning,
          ),
          const SizedBox(height: 22),
          Text('What went wrong?', style: AppTextStyles.h2),
          const SizedBox(height: 14),
          ..._reasons.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ReasonTile(label: r, selected: _reason == r, onTap: () => setState(() => _reason = r)),
              )),
          const SizedBox(height: 8),
          CustomTextField(label: 'Describe the issue', hint: 'Provide as much detail as possible...', icon: Icons.edit_note_rounded, controller: _descriptionController),
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
          PrimaryButton(
            label: 'Submit Dispute',
            icon: Icons.gavel_rounded,
            gradient: const LinearGradient(colors: [AppColors.danger, Color(0xFFEF7B72)]),
            isLoading: _submitting,
            onPressed: _reason == null ? null : _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildCaseTracker(BuildContext context, DisputeCase dispute) {
    final stageOrder = [
      DisputeStage.filed,
      DisputeStage.underReview,
      DisputeStage.evidenceRequested,
      DisputeStage.mediation,
      DisputeStage.resolved,
    ];
    final currentIndex = stageOrder.indexOf(dispute.stage);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.dangerTint, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.danger.withOpacity(0.2))),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                  child: const Icon(Icons.gavel_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Case ${dispute.id}', style: AppTextStyles.h3),
                      const SizedBox(height: 3),
                      Text(dispute.reason, style: AppTextStyles.bodySm),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Case Progress', style: AppTextStyles.h2),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
            child: Column(
              children: List.generate(stageOrder.length, (i) {
                final stage = stageOrder[i];
                final done = i <= currentIndex;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: done ? AppColors.danger : AppColors.surfaceAlt),
                          child: Icon(_iconFor(stage), size: 15, color: done ? Colors.white : AppColors.textMuted),
                        ),
                        if (i != stageOrder.length - 1)
                          Container(width: 2, height: 34, color: done ? AppColors.danger.withOpacity(0.4) : AppColors.border),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 20),
                        child: Text(
                          stage.label,
                          style: AppTextStyles.bodyMd.copyWith(color: done ? AppColors.textPrimary : AppColors.textMuted, fontWeight: done ? FontWeight.w700 : FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
          if (dispute.stage == DisputeStage.resolved) ...[
            const SizedBox(height: 22),
            SecurityInfoBanner(
              text: _resolutionText(dispute.resolution),
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.success,
            ),
          ],
          const SizedBox(height: 22),
          const SecurityInfoBanner(
            text: 'Our resolution team typically responds within 48 hours. You\'ll be notified at every stage.',
            icon: Icons.schedule_rounded,
          ),
          const SizedBox(height: 22),
          SecondaryButton(label: 'Contact Support', icon: Icons.support_agent_rounded, onPressed: () {}),
        ],
      ),
    );
  }

  IconData _iconFor(DisputeStage stage) {
    switch (stage) {
      case DisputeStage.filed:
        return Icons.flag_rounded;
      case DisputeStage.underReview:
        return Icons.search_rounded;
      case DisputeStage.evidenceRequested:
        return Icons.upload_file_rounded;
      case DisputeStage.mediation:
        return Icons.balance_rounded;
      case DisputeStage.resolved:
        return Icons.check_circle_rounded;
    }
  }

  String _resolutionText(String resolution) {
    switch (resolution) {
      case 'refund_buyer':
        return 'Resolved: funds were refunded to the buyer.';
      case 'release_seller':
        return 'Resolved: funds were released to the seller.';
      case 'partial':
        return 'Resolved: funds were split as a partial settlement.';
      default:
        return 'This case has been resolved.';
    }
  }
}

class _ReasonTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ReasonTile({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.dangerTint : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.danger : AppColors.border, width: selected ? 1.6 : 1),
        ),
        child: Row(
          children: [
            Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, size: 20, color: selected ? AppColors.danger : AppColors.textMuted),
            const SizedBox(width: 12),
            Text(label, style: AppTextStyles.bodyMd.copyWith(color: AppColors.textPrimary, fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}
