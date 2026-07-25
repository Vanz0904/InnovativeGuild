import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/notification_tile.dart';
import '../../data/mock_data.dart';

class NotificationsScreen extends StatelessWidget {
  final bool embedded;
  const NotificationsScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final notifications = MockData.notifications;
    final content = SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          if (embedded)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Notifications', style: AppTextStyles.displayMd),
                    TextButton(onPressed: () {}, child: const Text('Mark all read')),
                  ],
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: NotificationTile(notification: notifications[i]),
                ),
                childCount: notifications.length,
              ),
            ),
          ),
        ],
      ),
    );

    if (embedded) {
      return Scaffold(backgroundColor: AppColors.background, body: content);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(onPressed: () {}, child: const Text('Mark all read')),
          const SizedBox(width: 6),
        ],
      ),
      body: content,
    );
  }
}
