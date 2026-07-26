import '../../core/network/api_client.dart';

class AdminStats {
  final int totalUsers;
  final int buyers;
  final int sellers;
  final double heldVolume;
  final double completedVolume;
  final int completedCount;
  final int disputedCount;
  final int openDisputes;
  final List<Map<String, dynamic>> dailyVolume;

  const AdminStats({
    required this.totalUsers,
    required this.buyers,
    required this.sellers,
    required this.heldVolume,
    required this.completedVolume,
    required this.completedCount,
    required this.disputedCount,
    required this.openDisputes,
    required this.dailyVolume,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    final users = json['users'] as Map<String, dynamic>;
    final tx = json['transactions'] as Map<String, dynamic>;
    final disputes = json['disputes'] as Map<String, dynamic>;
    return AdminStats(
      totalUsers: (users['total'] as num?)?.toInt() ?? 0,
      buyers: (users['buyers'] as num?)?.toInt() ?? 0,
      sellers: (users['sellers'] as num?)?.toInt() ?? 0,
      heldVolume: (tx['heldVolume'] as num?)?.toDouble() ?? 0,
      completedVolume: (tx['completedVolume'] as num?)?.toDouble() ?? 0,
      completedCount: (tx['completedCount'] as num?)?.toInt() ?? 0,
      disputedCount: (tx['disputedCount'] as num?)?.toInt() ?? 0,
      openDisputes: (disputes['open'] as num?)?.toInt() ?? 0,
      dailyVolume: List<Map<String, dynamic>>.from(json['dailyVolume'] as List? ?? []),
    );
  }
}

class AdminUserRow {
  final int id;
  final String fullName;
  final String email;
  final String role;
  final bool isVerified;
  final bool isSuspended;
  final int trustScore;

  const AdminUserRow({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isVerified,
    required this.isSuspended,
    required this.trustScore,
  });

  factory AdminUserRow.fromJson(Map<String, dynamic> json) => AdminUserRow(
        id: json['id'] as int,
        fullName: json['fullName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: json['role'] as String? ?? 'buyer',
        isVerified: json['isVerified'] as bool? ?? false,
        isSuspended: json['isSuspended'] as bool? ?? false,
        trustScore: (json['trustScore'] as num?)?.toInt() ?? 0,
      );
}

class AdminDisputeRow {
  final String id;
  final String transactionId;
  final String transactionTitle;
  final double amount;
  final String currency;
  final String reason;
  final String stage;
  final String buyerName;
  final String sellerName;

  const AdminDisputeRow({
    required this.id,
    required this.transactionId,
    required this.transactionTitle,
    required this.amount,
    required this.currency,
    required this.reason,
    required this.stage,
    required this.buyerName,
    required this.sellerName,
  });

  factory AdminDisputeRow.fromJson(Map<String, dynamic> json) => AdminDisputeRow(
        id: json['id'] as String,
        transactionId: json['transactionId'] as String,
        transactionTitle: json['transactionTitle'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        currency: json['currency'] as String? ?? 'MWK',
        reason: json['reason'] as String? ?? '',
        stage: json['stage'] as String? ?? 'filed',
        buyerName: json['buyerName'] as String? ?? '',
        sellerName: json['sellerName'] as String? ?? '',
      );
}

class AdminService {
  final ApiClient client;
  AdminService(this.client);

  Future<AdminStats> stats() async {
    final res = await client.get('/admin/stats');
    return AdminStats.fromJson(res);
  }

  Future<List<AdminUserRow>> users({String? role}) async {
    final res = await client.get('/admin/users', query: role != null ? {'role': role} : null);
    final list = (res['users'] as List<dynamic>? ?? []);
    return list.map((e) => AdminUserRow.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> setSuspended(int userId, bool suspended) async {
    await client.put('/admin/users/$userId/suspend', body: {'suspended': suspended});
  }

  Future<List<AdminDisputeRow>> disputes({String? stage}) async {
    final res = await client.get('/admin/disputes', query: stage != null ? {'stage': stage} : null);
    final list = (res['disputes'] as List<dynamic>? ?? []);
    return list.map((e) => AdminDisputeRow.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> resolveDispute(String disputeId, String resolution, {String? notes}) async {
    final numericId = disputeId.replaceFirst('DP-', '');
    await client.post('/disputes/$numericId/resolve', body: {'resolution': resolution, 'notes': notes});
  }
}
