import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/notification_tile.dart';
import '../../core/state/session.dart';
import '../../data/models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  final bool embedded;
  const NotificationsScreen({super.key, this.embedded = false});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  List<AppNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final session = context.read<Session>();
      final list = await session.notificationService.list();
      if (mounted) setState(() => _notifications = list);
    } catch (_) {
      // Keep whatever was already loaded.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    final session = context.read<Session>();
    try {
      await session.notificationService.markAllRead();
      _load();
    } catch (_) {}
  }

  Future<void> _openNotification(AppNotification n) async {
    if (!n.isRead) {
      final session = context.read<Session>();
      try {
        await session.notificationService.markRead(n.id);
        _load();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: _loading
          ? const Center(child: Padding(padding: EdgeInsets.only(top: 100), child: CircularProgressIndicator(color: AppColors.primary)))
          : CustomScrollView(
              slivers: [
                if (widget.embedded)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Notifications', style: AppTextStyles.displayMd),
                          TextButton(onPressed: _markAllRead, child: const Text('Mark all read')),
                        ],
                      ),
                    ),
                  ),
                if (_notifications.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.notifications_none_rounded, size: 40, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text('No notifications yet', style: AppTextStyles.bodyMd),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: NotificationTile(notification: _notifications[i], onTap: () => _openNotification(_notifications[i])),
                        ),
                        childCount: _notifications.length,
                      ),
                    ),
                  ),
              ],
            ),
    );

    if (widget.embedded) {
      return Scaffold(backgroundColor: AppColors.background, body: SafeArea(bottom: false, child: body));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [TextButton(onPressed: _markAllRead, child: const Text('Mark all read')), const SizedBox(width: 6)],
      ),
      body: SafeArea(child: body),
    );
  }
}
