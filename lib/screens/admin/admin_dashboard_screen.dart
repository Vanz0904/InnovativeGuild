import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/formatters.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/status_widgets.dart';
import '../../core/widgets/safeguard_logo.dart';
import '../../data/mock_data.dart';
import '../auth/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _navIndex = 0;

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
                child: _buildContent(context),
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
                  decoration: BoxDecoration(
                    color: selected ? Colors.white.withOpacity(0.14) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(items[i].$1, color: selected ? AppColors.skyAccent : Colors.white38, size: 21),
                ),
              ),
            );
          }),
          const Spacer(),
          InkWell(
            onTap: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            ),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              child: const Icon(Icons.logout_rounded, color: Colors.white38, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
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
              decoration: BoxDecoration(
                gradient: AppColors.trustGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Text('AD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.35,
          children: [
            StatCard(label: 'Total volume secured', value: AppFormatters.compactCurrency(48200000), icon: Icons.account_balance_wallet_rounded, accentColor: AppColors.primary, trend: '+14.2%'),
            StatCard(label: 'Active users', value: '12,480', icon: Icons.groups_rounded, accentColor: AppColors.skyAccent, trend: '+3.1%'),
            StatCard(label: 'Open disputes', value: '18', icon: Icons.gavel_rounded, accentColor: AppColors.warning, trend: '-6%', trendUp: false),
            StatCard(label: 'Fraud attempts blocked', value: '214', icon: Icons.shield_rounded, accentColor: AppColors.danger, trend: '+22%'),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _buildVolumeChart(context)),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: _buildStatusBreakdown(context)),
          ],
        ),
        const SizedBox(height: 28),
        _buildDisputeQueue(context),
      ],
    );
  }

  Widget _buildVolumeChart(BuildContext context) {
    final values = [22.0, 31.0, 27.0, 40.0, 35.0, 48.0, 44.0];
    final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Escrow Volume This Week', style: AppTextStyles.h3),
              Text('MWK millions', style: AppTextStyles.bodySm),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(values.length, (i) {
                final heightFactor = values[i] / maxVal;
                final isPeak = values[i] == maxVal;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(values[i].toStringAsFixed(0), style: AppTextStyles.bodySm.copyWith(fontSize: 10)),
                        const SizedBox(height: 6),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          height: 96 * heightFactor,
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
                        Text(labels[i], style: AppTextStyles.bodySm),
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

  Widget _buildStatusBreakdown(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Transaction Health', style: AppTextStyles.h3),
          const SizedBox(height: 18),
          Center(
            child: DonutProgress(
              progress: 0.87,
              color: AppColors.success,
              size: 100,
              strokeWidth: 10,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('87%', style: AppTextStyles.h2),
                  Text('Success', style: AppTextStyles.bodySm),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          _LegendRow(color: AppColors.success, label: 'Completed', value: '87%'),
          const SizedBox(height: 8),
          _LegendRow(color: AppColors.warning, label: 'In progress', value: '9%'),
          const SizedBox(height: 8),
          _LegendRow(color: AppColors.danger, label: 'Disputed', value: '4%'),
        ],
      ),
    );
  }

  Widget _buildDisputeQueue(BuildContext context) {
    final disputed = MockData.transactions.where((t) => t.status.name == 'disputed').toList();
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
                child: Text('${disputed.length + 15} pending', style: AppTextStyles.bodySm.copyWith(color: AppColors.danger, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...MockData.transactions.take(4).map((t) => Padding(
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
                        child: Text(t.counterpartyInitials, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.title, style: AppTextStyles.h3.copyWith(fontSize: 13.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text('${t.id} · ${AppFormatters.currency(t.amount)}', style: AppTextStyles.bodySm),
                          ],
                        ),
                      ),
                      TextButton(onPressed: () {}, child: const Text('Review')),
                    ],
                  ),
                ),
              )),
        ],
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
