import '../../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiClient client;
  AuthService(this.client);

  Future<(AppUser, String)> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    final res = await client.post('/auth/register', body: {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'password': password,
      'role': role.apiValue,
    });
    return (AppUser.fromJson(res['user']), res['token'] as String);
  }

  Future<(AppUser, String)> login({required String email, required String password}) async {
    final res = await client.post('/auth/login', body: {'email': email, 'password': password});
    return (AppUser.fromJson(res['user']), res['token'] as String);
  }

  Future<AppUser> me() async {
    final res = await client.get('/users/me');
    return AppUser.fromJson(res['user']);
  }

  Future<AppUser> updateProfile({String? fullName, String? phone, bool? twoFactorEnabled}) async {
    final res = await client.put('/users/me', body: {
      if (fullName != null) 'fullName': fullName,
      if (phone != null) 'phone': phone,
      if (twoFactorEnabled != null) 'twoFactorEnabled': twoFactorEnabled,
    });
    return AppUser.fromJson(res['user']);
  }
}
