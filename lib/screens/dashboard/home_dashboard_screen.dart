import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/formatters.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/transaction_card.dart';
import '../../core/widgets/safeguard_logo.dart';
import '../../core/state/session.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/notification_model.dart';
import '../escrow/transaction_details_screen.dart';
import '../escrow/create_escrow_screen.dart';
import '../notifications/notifications_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  final bool initialTabIsTransactions;
  const HomeDashboardScreen({super.key, this.initialTabIsTransactions = false});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  late bool _showTransactions = widget.initialTabIsTransactions;
  String _filter = 'All';
  final List<String> _filters = const ['All', 'Active', 'Completed', 'Disputed'];

  bool _loading = true;
  String? _error;
  List<EscrowTransaction> _transactions = [];
  List<AppNotification> _recentActivity = [];

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
        session.transactionService.myTransactions(),
        session.notificationService.list(),
      ]);
      setState(() {
        _transactions = results[0] as List<EscrowTransaction>;
        _recentActivity = (results[1] as List<AppNotification>).take(3).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load your dashboard. Pull down to try again.';
        _loading = false;
      });
    }
  }

  List<EscrowTransaction> get _activeTransactions => _transactions
      .where((t) => ![EscrowStatus.completed, EscrowStatus.refunded].contains(t.status))
      .toList();

  List<EscrowTransaction> get _completedTransactions =>
      _transactions.where((t) => t.status == EscrowStatus.completed).toList();

  double get _totalHeldInEscrow => _activeTransactions
      .where((t) => t.status != EscrowStatus.disputed && t.status != EscrowStatus.pendingPayment)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _totalCompletedValue => _completedTransactions.fold(0.0, (sum, t) => sum + t.amount);

  List<EscrowTransaction> get _filteredTransactions {
    switch (_filter) {
      case 'Active':
        return _activeTransactions;
      case 'Completed':
        return _completedTransactions;
      case 'Disputed':
        return _transactions.where((t) => t.status == EscrowStatus.disputed).toList();
      default:
        return _transactions;
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final user = session.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.primary,
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader(context, user?.fullName ?? '', user?.initials ?? '?')),
                    SliverToBoxAdapter(child: _buildBalanceHero(context)),
                    if (_error != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: AppColors.dangerTint, borderRadius: BorderRadius.circular(14)),
                            child: Text(_error!, style: AppTextStyles.bodySm.copyWith(color: AppColors.danger)),
                          ),
                        ),
                      ),
                    if (!_showTransactions) ...[
                      SliverToBoxAdapter(child: _buildStatsRow(context)),
                      SliverToBoxAdapter(child: _buildSectionToggle(context)),
                      SliverToBoxAdapter(child: _buildActiveEscrowSection(context)),
                      SliverToBoxAdapter(child: _buildRecentActivitySection(context)),
                    ] else ...[
                      SliverToBoxAdapter(child: _buildSectionToggle(context)),
                      SliverToBoxAdapter(child: _buildFilterChips(context)),
                      _buildTransactionList(context),
                    ],
                    const SliverToBoxAdapter(child: SizedBox(height: 110)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name, String initials) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : (hour < 17 ? 'Good afternoon' : 'Good evening');
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(gradient: AppColors.trustGradient, borderRadius: BorderRadius.circular(14)),
                alignment: Alignment.center,
                child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(greeting, style: AppTextStyles.bodySm),
                  Text(name, style: AppTextStyles.h3),
                ],
              ),
            ],
          ),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
              child: const Icon(Icons.notifications_none_rounded, size: 22, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceHero(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(26), boxShadow: AppColors.elevatedShadow),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const SafeGuardLogo(size: 20, checkColor: AppColors.navy),
                    const SizedBox(width: 8),
                    Text('SECURED IN ESCROW', style: AppTextStyles.eyebrow.copyWith(color: Colors.white.withOpacity(0.85))),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('Protected', style: AppTextStyles.bodySm.copyWith(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(AppFormatters.currency(_totalHeldInEscrow), style: AppTextStyles.amountXl),
            const SizedBox(height: 4),
            Text('${_activeTransactions.length} active escrow transactions', style: AppTextStyles.bodySm.copyWith(color: Colors.white.withOpacity(0.72))),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _HeroActionButton(
                    icon: Icons.add_circle_outline_rounded,
                    label: 'New Escrow',
                    onTap: () async {
                      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateEscrowScreen()));
                      _load();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HeroActionButton(
                    icon: Icons.receipt_long_rounded,
                    label: 'History',
                    onTap: () => setState(() => _showTransactions = true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              label: 'Completed deals',
              value: '${_completedTransactions.length}',
              icon: Icons.verified_rounded,
              accentColor: AppColors.success,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: StatCard(
              label: 'Total protected',
              value: AppFormatters.compactCurrency(_totalHeldInEscrow + _totalCompletedValue),
              icon: Icons.shield_rounded,
              accentColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionToggle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Expanded(child: _ToggleTab(label: 'Overview', selected: !_showTransactions, onTap: () => setState(() => _showTransactions = false))),
            Expanded(child: _ToggleTab(label: 'All Transactions', selected: _showTransactions, onTap: () => setState(() => _showTransactions = true))),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final f = _filters[i];
            final selected = f == _filter;
            return ChoiceChip(
              label: Text(f),
              selected: selected,
              onSelected: (_) => setState(() => _filter = f),
              labelStyle: AppTextStyles.label.copyWith(color: selected ? Colors.white : AppColors.textSecondary),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: selected ? AppColors.primary : AppColors.border)),
              showCheckmark: false,
            );
          },
        ),
      ),
    );
  }

  Widget _buildActiveEscrowSection(BuildContext context) {
    final items = _activeTransactions.take(3).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Active Escrows', actionLabel: 'View all', onAction: () => setState(() => _showTransactions = true)),
          const SizedBox(height: 14),
          if (items.isEmpty)
            _EmptyState(
              icon: Icons.inventory_2_outlined,
              message: 'No active escrow transactions yet. Tap "New Escrow" to start one.',
            )
          else
            ...items.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TransactionCard(
                    transaction: t,
                    onTap: () async {
                      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => TransactionDetailsScreen(transaction: t)));
                      _load();
                    },
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Recent Activity',
            actionLabel: 'See all',
            onAction: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
          const SizedBox(height: 14),
          if (_recentActivity.isEmpty)
            _EmptyState(icon: Icons.notifications_none_rounded, message: 'No activity yet.')
          else
            Container(
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
              child: Column(
                children: List.generate(_recentActivity.length, (i) {
                  final n = _recentActivity[i];
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(color: n.type.color.withOpacity(0.12), borderRadius: BorderRadius.circular(11)),
                              child: Icon(n.type.icon, size: 16, color: n.type.color),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(n.title, style: AppTextStyles.h3.copyWith(fontSize: 13.5)),
                                  const SizedBox(height: 2),
                                  Text(AppFormatters.timeAgo(n.time), style: AppTextStyles.bodySm),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (i != _recentActivity.length - 1) const Divider(height: 1, indent: 14, endIndent: 14),
                    ],
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(BuildContext context) {
    final items = _filteredTransactions;
    if (items.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 60),
          child: Center(child: Text('No transactions found')),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TransactionCard(
              transaction: items[i],
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => TransactionDetailsScreen(transaction: items[i])));
                _load();
              },
            ),
          ),
          childCount: items.length,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
          Icon(icon, size: 30, color: AppColors.textMuted),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center, style: AppTextStyles.bodySm),
        ],
      ),
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeroActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: Colors.white),
            const SizedBox(width: 7),
            Text(label, style: AppTextStyles.label.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _ToggleTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: selected ? AppColors.softShadow : [],
        ),
        child: Text(label, textAlign: TextAlign.center, style: AppTextStyles.label.copyWith(color: selected ? AppColors.primary : AppColors.textMuted)),
      ),
    );
  }
}
