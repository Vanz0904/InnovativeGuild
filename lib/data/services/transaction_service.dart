import '../../core/network/api_client.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final ApiClient client;
  TransactionService(this.client);

  Future<List<EscrowTransaction>> myTransactions({String? status}) async {
    final res = await client.get('/transactions/mine', query: status != null ? {'status': status} : null);
    final list = (res['transactions'] as List<dynamic>? ?? []);
    return list.map((e) => EscrowTransaction.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<EscrowTransaction> getByReference(String reference) async {
    final res = await client.get('/transactions/$reference');
    return EscrowTransaction.fromJson(res['transaction']);
  }

  Future<EscrowTransaction> create({
    required String title,
    String? description,
    required String category,
    required int sellerId,
    required double amount,
    String? deliveryAddress,
  }) async {
    final res = await client.post('/transactions', body: {
      'title': title,
      'description': description,
      'category': category,
      'sellerId': sellerId,
      'amount': amount,
      'deliveryAddress': deliveryAddress,
    });
    return EscrowTransaction.fromJson(res['transaction']);
  }

  Future<EscrowTransaction> confirmShipment({
    required String reference,
    required String courier,
    required String trackingCode,
    String? estimatedDelivery,
  }) async {
    final res = await client.post('/transactions/$reference/confirm-shipment', body: {
      'courier': courier,
      'trackingCode': trackingCode,
      'estimatedDelivery': estimatedDelivery,
    });
    return EscrowTransaction.fromJson(res['transaction']);
  }

  Future<EscrowTransaction> releaseFunds(String reference) async {
    final res = await client.post('/transactions/$reference/release');
    return EscrowTransaction.fromJson(res['transaction']);
  }
}
