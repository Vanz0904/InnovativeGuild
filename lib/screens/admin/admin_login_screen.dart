import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/state/session.dart';
import '../../core/network/api_exception.dart';
import 'admin_dashboard_screen.dart';

/// Administrators are provisioned by SafeGuard directly — there is no
/// public sign-up path. This screen authenticates against the same
/// /api/auth/login endpoint as regular users, then refuses to proceed
/// unless the account's role is actually 'admin'.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final session = context.read<Session>();
      await session.login(_emailController.text.trim(), _passwordController.text);

      if (session.currentUser!.role.name != 'admin') {
        await session.logout();
        setState(() {
          _loading = false;
          _error = 'This account is not an administrator.';
        });
        return;
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        (route) => false,
      );
    } on ApiException catch (e) {
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Could not reach the server. Check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.16)),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 24),
              Text('Administrator Access', style: AppTextStyles.displayMd.copyWith(color: Colors.white)),
              const SizedBox(height: 8),
              Text(
                'Restricted area. Accounts are provisioned by SafeGuard — there is no self-registration.',
                style: AppTextStyles.bodyMd.copyWith(color: Colors.white.withOpacity(0.65)),
              ),
              const SizedBox(height: 32),
              _DarkField(label: 'Admin email', hint: 'admin@safeguard.mw', icon: Icons.badge_outlined, controller: _emailController),
              const SizedBox(height: 18),
              _DarkField(
                label: 'Password',
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscure,
                controller: _passwordController,
                suffix: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: Colors.white54),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.16), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 18, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: AppTextStyles.bodySm.copyWith(color: Colors.redAccent))),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: Colors.white.withOpacity(0.6)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'The default admin account is created by running "npm run seed" on the backend, using the credentials in your .env file.',
                        style: AppTextStyles.bodySm.copyWith(color: Colors.white.withOpacity(0.55)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              PrimaryButton(label: 'Sign In as Administrator', icon: Icons.login_rounded, isLoading: _loading, onPressed: _login),
            ],
          ),
        ),
      ),
    );
  }
}

class _DarkField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;
  final TextEditingController controller;

  const _DarkField({
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffix,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label.copyWith(color: Colors.white.withOpacity(0.7))),
        const SizedBox(height: 9),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
            prefixIcon: Icon(icon, size: 20, color: Colors.white54),
            suffixIcon: suffix,
            filled: true,
            fillColor: Colors.white.withOpacity(0.07),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.12))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.12))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.skyAccent, width: 1.6)),
          ),
        ),
      ],
    );
  }
}
