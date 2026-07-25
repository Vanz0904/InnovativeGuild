import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/formatters.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/stat_card.dart';
import '../../data/models/transaction_model.dart';

class DisputeResolutionScreen extends StatefulWidget {
  final EscrowTransaction transaction;
  const DisputeResolutionScreen({super.key, required this.transaction});

  @override
  State<DisputeResolutionScreen> createState() => _DisputeResolutionScreenState();
}

class _DisputeResolutionScreenState extends State<DisputeResolutionScreen> {
  bool get _alreadyDisputed => widget.transaction.status == EscrowStatus.disputed;
  String? _reason;
  bool _submitted = false;

  final List<String> _reasons = const [
    'Item not received',
    'Item not as described',
    'Damaged or defective item',
    'Wrong item delivered',
    'Seller unresponsive',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Dispute Resolution')),
      body: SafeArea(
        child: (_alreadyDisputed || _submitted) ? _buildCaseTracker(context) : _buildFileForm(context),
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
          const CustomTextField(
            label: 'Describe the issue',
            hint: 'Provide as much detail as possible...',
            icon: Icons.edit_note_rounded,
          ),
          const SizedBox(height: 18),
          Text('Evidence', style: AppTextStyles.label),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _UploadTile(icon: Icons.photo_camera_outlined, label: 'Photos')),
              const SizedBox(width: 10),
              Expanded(child: _UploadTile(icon: Icons.description_outlined, label: 'Documents')),
            ],
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: 'Submit Dispute',
            icon: Icons.gavel_rounded,
            gradient: const LinearGradient(colors: [AppColors.danger, Color(0xFFEF7B72)]),
            onPressed: _reason == null ? null : () => setState(() => _submitted = true),
          ),
        ],
      ),
    );
  }

  Widget _buildCaseTracker(BuildContext context) {
    final t = widget.transaction;
    final stages = [
      _StageInfo('Filed', Icons.flag_rounded, true),
      _StageInfo('Under Review', Icons.search_rounded, true),
      _StageInfo('Evidence Requested', Icons.upload_file_rounded, true),
      _StageInfo('Mediation', Icons.balance_rounded, false),
      _StageInfo('Resolved', Icons.check_circle_rounded, false),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.dangerTint,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.danger.withOpacity(0.2)),
            ),
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
                      Text('Case #DP-${t.id.substring(3)}', style: AppTextStyles.h3),
                      const SizedBox(height: 3),
                      Text(_reason ?? 'Item not as described', style: AppTextStyles.bodySm),
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
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: List.generate(stages.length, (i) {
                final s = stages[i];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: s.done ? AppColors.danger : AppColors.surfaceAlt,
                          ),
                          child: Icon(s.icon, size: 15, color: s.done ? Colors.white : AppColors.textMuted),
                        ),
                        if (i != stages.length - 1)
                          Container(width: 2, height: 34, color: s.done ? AppColors.danger.withOpacity(0.4) : AppColors.border),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 20),
                        child: Text(
                          s.label,
                          style: AppTextStyles.bodyMd.copyWith(
                            color: s.done ? AppColors.textPrimary : AppColors.textMuted,
                            fontWeight: s.done ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
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
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              size: 20,
              color: selected ? AppColors.danger : AppColors.textMuted,
            ),
            const SizedBox(width: 12),
            Text(label, style: AppTextStyles.bodyMd.copyWith(color: AppColors.textPrimary, fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  final IconData icon;
  final String label;
  const _UploadTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.textMuted, size: 24),
            const SizedBox(height: 8),
            Text(label, style: AppTextStyles.bodySm),
          ],
        ),
      ),
    );
  }
}

class _StageInfo {
  final String label;
  final IconData icon;
  final bool done;
  _StageInfo(this.label, this.icon, this.done);
}
