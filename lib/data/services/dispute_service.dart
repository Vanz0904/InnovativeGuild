import '../../core/network/api_client.dart';
import '../models/notification_model.dart';

class DisputeService {
  final ApiClient client;
  DisputeService(this.client);

  Future<DisputeCase> file({
    required String transactionReference,
    required String reason,
    String? description,
  }) async {
    final res = await client.post('/disputes', body: {
      'transactionReference': transactionReference,
      'reason': reason,
      'description': description,
    });
    return DisputeCase.fromJson(res['dispute']);
  }

  Future<DisputeCase> forTransaction(String transactionReference) async {
    final res = await client.get('/disputes/$transactionReference');
    return DisputeCase.fromJson(res['dispute']);
  }

  Future<List<DisputeCase>> mine() async {
    final res = await client.get('/disputes/mine');
    final list = (res['disputes'] as List<dynamic>? ?? []);
    return list.map((e) => DisputeCase.fromJson(e as Map<String, dynamic>)).toList();
  }
}
