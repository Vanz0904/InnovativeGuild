import '../../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationService {
  final ApiClient client;
  NotificationService(this.client);

  Future<List<AppNotification>> list() async {
    final res = await client.get('/notifications');
    final items = (res['notifications'] as List<dynamic>? ?? []);
    return items.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> unreadCount() async {
    final res = await client.get('/notifications/unread-count');
    return (res['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markRead(String id) => client.post('/notifications/$id/read');

  Future<void> markAllRead() => client.post('/notifications/read-all');
}
