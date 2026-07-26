import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../state/session.dart';
import '../../screens/dashboard/home_dashboard_screen.dart';
import '../../screens/escrow/create_escrow_screen.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../screens/profile/profile_settings_screen.dart';

/// The shell that hosts the four primary tabs behind a floating,
/// pill-shaped bottom navigation bar, with a raised center action
/// button for starting a new escrow transaction.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  int _unreadCount = 0;
  Timer? _pollTimer;

  final List<Widget> _pages = const [
    HomeDashboardScreen(),
    HomeDashboardScreen(initialTabIsTransactions: true),
    NotificationsScreen(embedded: true),
    ProfileSettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _refreshUnreadCount();
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) => _refreshUnreadCount());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshUnreadCount() async {
    try {
      final session = context.read<Session>();
      final count = await session.notificationService.unreadCount();
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {
      // Silently ignore — the badge just won't update this cycle.
    }
  }

  void _onTabTap(int i) {
    setState(() => _index = i);
    if (i == 2) _refreshUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _pages),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateEscrowScreen()),
            );
            if (mounted) setState(() {}); // refresh dashboard data on return
          },
          backgroundColor: AppColors.primary,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
        ),
      ),
      bottomNavigationBar: _FloatingNavBar(
        currentIndex: _index,
        onTap: _onTabTap,
        unreadCount: _unreadCount,
      ),
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int unreadCount;

  const _FloatingNavBar({required this.currentIndex, required this.onTap, required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.32), blurRadius: 24, offset: const Offset(0, 12))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(icon: Icons.dashboard_rounded, label: 'Home', selected: currentIndex == 0, onTap: () => onTap(0)),
            _NavItem(icon: Icons.swap_horiz_rounded, label: 'Escrow', selected: currentIndex == 1, onTap: () => onTap(1)),
            const SizedBox(width: 46),
            _NavItem(
              icon: Icons.notifications_rounded,
              label: 'Alerts',
              selected: currentIndex == 2,
              onTap: () => onTap(2),
              badgeCount: unreadCount,
            ),
            _NavItem(icon: Icons.person_rounded, label: 'Profile', selected: currentIndex == 3, onTap: () => onTap(3)),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.skyAccent : AppColors.textOnDarkMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 23, color: color),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text(
                        '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.bodySm.copyWith(color: color, fontSize: 10.5)),
          ],
        ),
      ),
    );
  }
}
