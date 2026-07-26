import '../../core/network/api_client.dart';
import '../models/user_model.dart';

class UserService {
  final ApiClient client;
  UserService(this.client);

  Future<List<UserSummary>> searchSellers(String query) async {
    final res = await client.get('/users/search', query: {'q': query, 'role': 'seller'});
    final list = (res['users'] as List<dynamic>? ?? []);
    return list.map((e) => UserSummary.fromJson(e as Map<String, dynamic>)).toList();
  }
}
