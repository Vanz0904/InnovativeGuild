import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/user_service.dart';
import '../../data/services/transaction_service.dart';
import '../../data/services/dispute_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/payment_service.dart';
import '../../data/services/admin_service.dart';

const _tokenPrefsKey = 'safeguard_auth_token';

/// The single source of truth for "who is logged in" and the shared
/// API client every screen's services are built from. Provided at the
/// root of the widget tree via ChangeNotifierProvider in main.dart.
class Session extends ChangeNotifier {
  final ApiClient client = ApiClient();

  late final AuthService authService = AuthService(client);
  late final UserService userService = UserService(client);
  late final TransactionService transactionService = TransactionService(client);
  late final DisputeService disputeService = DisputeService(client);
  late final NotificationService notificationService = NotificationService(client);
  late final PaymentService paymentService = PaymentService(client);
  late final AdminService adminService = AdminService(client);

  AppUser? currentUser;
  bool isBootstrapping = true;

  bool get isLoggedIn => currentUser != null;

  /// Called once at app start: restores a saved token and validates it
  /// against the backend so a killed-and-reopened app stays logged in.
  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenPrefsKey);

    if (token != null) {
      client.setToken(token);
      try {
        currentUser = await authService.me();
      } catch (_) {
        await prefs.remove(_tokenPrefsKey);
        client.setToken(null);
        currentUser = null;
      }
    }

    isBootstrapping = false;
    notifyListeners();
  }

  Future<void> _persistToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenPrefsKey, token);
    client.setToken(token);
  }

  Future<void> login(String email, String password) async {
    final (user, token) = await authService.login(email: email, password: password);
    await _persistToken(token);
    currentUser = user;
    notifyListeners();
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    final (user, token) = await authService.register(
      fullName: fullName,
      email: email,
      phone: phone,
      password: password,
      role: role,
    );
    await _persistToken(token);
    currentUser = user;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    currentUser = await authService.me();
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenPrefsKey);
    client.setToken(null);
    currentUser = null;
    notifyListeners();
  }
}
