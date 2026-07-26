import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/formatters.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/status_widgets.dart';
import '../../core/widgets/safeguard_logo.dart';
import '../../core/state/session.dart';
import '../../data/services/admin_service.dart';
import '../auth/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _navIndex = 0;
  bool _loading = true;
  String? _error;
  AdminStats? _stats;
  List<AdminDisputeRow> _disputes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = context.read<Session>();
      final results = await Future.wait([
        session.adminService.stats(),
        session.adminService.disputes(),
      ]);
      setState(() {
        _stats = results[0] as AdminStats;
        _disputes = results[1] as List<AdminDisputeRow>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load platform data.';
        _loading = false;
      });
    }
  }

  Future<void> _resolveDispute(AdminDisputeRow dispute) async {
    final resolution = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ResolveSheet(dispute: dispute),
    );
    if (resolution == null) return;

    try {
      final session = context.read<Session>();
      await session.adminService.resolveDispute(dispute.id, resolution);
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not resolve this dispute.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Row(
          children: [
            _buildSideRail(context),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(28), bottomLeft: Radius.circular(28)),
                ),
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : RefreshIndicator(onRefresh: _load, color: AppColors.primary, child: _buildContent(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideRail(BuildContext context) {
    final items = [
      (Icons.dashboard_rounded, 'Overview'),
      (Icons.gavel_rounded, 'Disputes'),
      (Icons.groups_rounded, 'Users'),
      (Icons.shield_rounded, 'Fraud'),
      (Icons.settings_rounded, 'Settings'),
    ];
    return Container(
      width: 74,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          const SafeGuardLogo(size: 30, checkColor: AppColors.navy),
          const SizedBox(height: 34),
          ...List.generate(items.length, (i) {
            final selected = _navIndex == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => setState(() => _navIndex = i),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: selected ? Colors.white.withOpacity(0.14) : Colors.transparent, borderRadius: BorderRadius.circular(14)),
                  child: Icon(items[i].$1, color: selected ? AppColors.skyAccent : Colors.white38, size: 21),
                ),
              ),
            );
          }),
          const Spacer(),
          InkWell(
            onTap: () async {
              await context.read<Session>().logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
              }
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(width: 46, height: 46, alignment: Alignment.center, child: const Icon(Icons.logout_rounded, color: Colors.white38, size: 20)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final stats = _stats;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Administrator Console', style: AppTextStyles.displayMd),
                const SizedBox(height: 4),
                Text('Platform-wide oversight & fraud monitoring', style: AppTextStyles.bodyMd),
              ],
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(gradient: AppColors.trustGradient, borderRadius: BorderRadius.circular(14)),
              alignment: Alignment.center,
              child: const Text('AD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_error != null)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: AppColors.dangerTint, borderRadius: BorderRadius.circular(14)),
            child: Text(_error!, style: AppTextStyles.bodySm.copyWith(color: AppColors.danger)),
          ),
        if (stats != null) ...[
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.35,
            children: [
              StatCard(label: 'Volume secured', value: AppFormatters.compactCurrency(stats.heldVolume + stats.completedVolume), icon: Icons.account_balance_wallet_rounded, accentColor: AppColors.primary),
              StatCard(label: 'Total users', value: '${stats.totalUsers}', icon: Icons.groups_rounded, accentColor: AppColors.skyAccent),
              StatCard(label: 'Open disputes', value: '${stats.openDisputes}', icon: Icons.gavel_rounded, accentColor: AppColors.warning),
              StatCard(label: 'Completed deals', value: '${stats.completedCount}', icon: Icons.verified_rounded, accentColor: AppColors.success),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildVolumeChart(context, stats)),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _buildUserBreakdown(context, stats)),
            ],
          ),
        ],
        const SizedBox(height: 28),
        _buildDisputeQueue(context),
      ],
    );
  }

  Widget _buildVolumeChart(BuildContext context, AdminStats stats) {
    final daily = stats.dailyVolume;
    final values = daily.map((d) => (d['volume'] as num).toDouble()).toList();
    final maxVal = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b).clamp(1, double.infinity);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Escrow Volume — Last 7 Days', style: AppTextStyles.h3),
              Text('MWK', style: AppTextStyles.bodySm),
            ],
          ),
          const SizedBox(height: 24),
          if (daily.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(child: Text('No transactions in the last 7 days yet', style: AppTextStyles.bodySm)),
            )
          else
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(daily.length, (i) {
                  final heightFactor = values[i] / maxVal;
                  final isPeak = values[i] == maxVal;
                  final dayLabel = _formatDayLabel(daily[i]['day'] as String);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(AppFormatters.compactCurrency(values[i]), style: AppTextStyles.bodySm.copyWith(fontSize: 9)),
                          const SizedBox(height: 6),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            height: (96 * heightFactor).clamp(4, 96),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: isPeak ? [AppColors.primaryLight, AppColors.primary] : [AppColors.skyTint2, AppColors.skyTint],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(dayLabel, style: AppTextStyles.bodySm),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDayLabel(String isoDate) {
    final parsed = DateTime.tryParse(isoDate);
    if (parsed == null) return '';
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[parsed.weekday - 1];
  }

  Widget _buildUserBreakdown(BuildContext context, AdminStats stats) {
    final total = stats.buyers + stats.sellers;
    final buyerShare = total == 0 ? 0.5 : stats.buyers / total;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('User Base', style: AppTextStyles.h3),
          const SizedBox(height: 18),
          Center(
            child: DonutProgress(
              progress: buyerShare,
              color: AppColors.primary,
              size: 100,
              strokeWidth: 10,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${stats.totalUsers}', style: AppTextStyles.h2),
                  Text('Users', style: AppTextStyles.bodySm),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          _LegendRow(color: AppColors.primary, label: 'Buyers', value: '${stats.buyers}'),
          const SizedBox(height: 8),
          _LegendRow(color: AppColors.skyAccent, label: 'Sellers', value: '${stats.sellers}'),
        ],
      ),
    );
  }

  Widget _buildDisputeQueue(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Dispute Queue', style: AppTextStyles.h3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.dangerTint, borderRadius: BorderRadius.circular(20)),
                child: Text('${_disputes.length} cases', style: AppTextStyles.bodySm.copyWith(color: AppColors.danger, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_disputes.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Center(child: Text('No disputes filed yet', style: AppTextStyles.bodySm)))
          else
            ..._disputes.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(gradient: AppColors.trustGradient, borderRadius: BorderRadius.circular(11)),
                          alignment: Alignment.center,
                          child: const Icon(Icons.gavel_rounded, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d.transactionTitle, style: AppTextStyles.h3.copyWith(fontSize: 13.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text('${d.transactionId} · ${AppFormatters.currency(d.amount, symbol: d.currency)} · ${d.reason}', style: AppTextStyles.bodySm, maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        if (d.stage != 'resolved')
                          TextButton(onPressed: () => _resolveDispute(d), child: const Text('Review'))
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.successTint, borderRadius: BorderRadius.circular(8)),
                            child: Text('Resolved', style: AppTextStyles.bodySm.copyWith(color: AppColors.success, fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}

class _ResolveSheet extends StatelessWidget {
  final AdminDisputeRow dispute;
  const _ResolveSheet({required this.dispute});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 20),
          Text('Resolve ${dispute.id}', style: AppTextStyles.h2),
          const SizedBox(height: 6),
          Text('${dispute.buyerName} vs ${dispute.sellerName} — ${AppFormatters.currency(dispute.amount, symbol: dispute.currency)}', style: AppTextStyles.bodyMd),
          const SizedBox(height: 20),
          _ResolutionOption(
            label: 'Refund the buyer',
            description: 'Full amount returned to the buyer',
            icon: Icons.undo_rounded,
            color: AppColors.danger,
            onTap: () => Navigator.of(context).pop('refund_buyer'),
          ),
          const SizedBox(height: 10),
          _ResolutionOption(
            label: 'Release to seller',
            description: 'Full amount released to the seller',
            icon: Icons.storefront_rounded,
            color: AppColors.success,
            onTap: () => Navigator.of(context).pop('release_seller'),
          ),
          const SizedBox(height: 10),
          _ResolutionOption(
            label: 'Partial settlement',
            description: 'Funds split between both parties',
            icon: Icons.call_split_rounded,
            color: AppColors.warning,
            onTap: () => Navigator.of(context).pop('partial'),
          ),
        ],
      ),
    );
  }
}

class _ResolutionOption extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ResolutionOption({required this.label, required this.description, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.2))),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.h3),
                  Text(description, style: AppTextStyles.bodySm),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _LegendRow({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: AppTextStyles.bodySm)),
        Text(value, style: AppTextStyles.label.copyWith(color: AppColors.textPrimary)),
      ],
    );
  }
}
