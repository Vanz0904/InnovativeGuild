import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/state/session.dart';
import '../../core/network/api_exception.dart';
import '../../data/models/user_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _step = 0;
  bool _loading = false;
  bool _agree = false;
  String? _error;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  UserRole _role = UserRole.buyer;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _nextStep() async {
    setState(() => _error = null);

    if (_step == 0) {
      if (_nameController.text.trim().isEmpty || _emailController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
        setState(() => _error = 'Please fill in all fields');
        return;
      }
      setState(() => _step = 1);
      return;
    }

    if (_step == 1) {
      if (_passwordController.text.length < 8) {
        setState(() => _error = 'Password must be at least 8 characters');
        return;
      }
      if (_passwordController.text != _confirmController.text) {
        setState(() => _error = 'Passwords do not match');
        return;
      }
      setState(() => _step = 2);
      return;
    }

    // Final step — actually create the account.
    setState(() => _loading = true);
    try {
      final session = context.read<Session>();
      await session.register(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        role: _role,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AppShell()),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            if (_step == 0) {
              Navigator.pop(context);
            } else {
              setState(() => _step--);
            }
          },
        ),
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: List.generate(3, (i) {
                  final active = i <= _step;
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i == 2 ? 0 : 6),
                      height: 5,
                      decoration: BoxDecoration(
                        color: active ? AppColors.primary : AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(anim),
                          child: child,
                        ),
                      ),
                      child: _stepContent(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.dangerTint, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.danger),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_error!, style: AppTextStyles.bodySm.copyWith(color: AppColors.danger))),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: PrimaryButton(
                label: _step < 2 ? 'Continue' : 'Create Account',
                icon: _step < 2 ? Icons.arrow_forward_rounded : Icons.verified_user_rounded,
                isLoading: _loading,
                onPressed: (_step == 2 && !_agree) ? null : _nextStep,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepContent() {
    switch (_step) {
      case 0:
        return _PersonalDetailsStep(
          key: const ValueKey('s0'),
          nameController: _nameController,
          emailController: _emailController,
          phoneController: _phoneController,
          role: _role,
          onRoleChanged: (r) => setState(() => _role = r),
        );
      case 1:
        return _SecurityStep(
          key: const ValueKey('s1'),
          passwordController: _passwordController,
          confirmController: _confirmController,
        );
      default:
        return _ReviewStep(
          key: const ValueKey('s2'),
          agree: _agree,
          onAgreeChanged: (v) => setState(() => _agree = v),
          role: _role,
        );
    }
  }
}

class _PersonalDetailsStep extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final UserRole role;
  final ValueChanged<UserRole> onRoleChanged;

  const _PersonalDetailsStep({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.role,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Personal details', style: AppTextStyles.h1),
        const SizedBox(height: 6),
        Text('Tell us a bit about yourself to get started', style: AppTextStyles.bodyMd),
        const SizedBox(height: 22),
        Text('I want to join as a', style: AppTextStyles.label),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _RoleCard(
                label: 'Buyer',
                description: 'Shop safely, pay into escrow',
                icon: Icons.shopping_bag_rounded,
                selected: role == UserRole.buyer,
                onTap: () => onRoleChanged(UserRole.buyer),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RoleCard(
                label: 'Seller',
                description: 'List items, get paid on delivery',
                icon: Icons.storefront_rounded,
                selected: role == UserRole.seller,
                onTap: () => onRoleChanged(UserRole.seller),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        CustomTextField(label: 'Full name', hint: 'Chisomo Banda', icon: Icons.person_outline_rounded, controller: nameController),
        const SizedBox(height: 18),
        CustomTextField(
          label: 'Email address',
          hint: 'you@example.com',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          controller: emailController,
        ),
        const SizedBox(height: 18),
        CustomTextField(
          label: 'Phone number',
          hint: '+265 99 123 4567',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          controller: phoneController,
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.skyTint : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.6 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.textMuted, size: 24),
            const SizedBox(height: 10),
            Text(label, style: AppTextStyles.h3.copyWith(color: selected ? AppColors.primary : AppColors.textPrimary)),
            const SizedBox(height: 3),
            Text(description, style: AppTextStyles.bodySm),
          ],
        ),
      ),
    );
  }
}

class _SecurityStep extends StatefulWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  const _SecurityStep({super.key, required this.passwordController, required this.confirmController});

  @override
  State<_SecurityStep> createState() => _SecurityStepState();
}

class _SecurityStepState extends State<_SecurityStep> {
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Secure your account', style: AppTextStyles.h1),
        const SizedBox(height: 6),
        Text('Choose a strong password to protect your funds', style: AppTextStyles.bodyMd),
        const SizedBox(height: 26),
        CustomTextField(
          label: 'Password',
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          obscureText: _obscure1,
          controller: widget.passwordController,
          suffix: IconButton(
            icon: Icon(_obscure1 ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: AppColors.textMuted),
            onPressed: () => setState(() => _obscure1 = !_obscure1),
          ),
          helperText: 'Use 8+ characters with a mix of letters, numbers & symbols',
        ),
        const SizedBox(height: 18),
        CustomTextField(
          label: 'Confirm password',
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          obscureText: _obscure2,
          controller: widget.confirmController,
          suffix: IconButton(
            icon: Icon(_obscure2 ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: AppColors.textMuted),
            onPressed: () => setState(() => _obscure2 = !_obscure2),
          ),
        ),
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  final bool agree;
  final ValueChanged<bool> onAgreeChanged;
  final UserRole role;

  const _ReviewStep({super.key, required this.agree, required this.onAgreeChanged, required this.role});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review & confirm', style: AppTextStyles.h1),
        const SizedBox(height: 6),
        Text('You are creating a ${role.label.toLowerCase()} account', style: AppTextStyles.bodyMd),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.trustGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.elevatedShadow,
          ),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), shape: BoxShape.circle),
                child: Icon(
                  role == UserRole.buyer ? Icons.shopping_bag_rounded : Icons.storefront_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text('Identity verification', style: AppTextStyles.h3.copyWith(color: Colors.white)),
              const SizedBox(height: 6),
              Text(
                'After you create your account, verify your identity from Profile → Identity verification to unlock higher transaction limits.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySm.copyWith(color: Colors.white.withOpacity(0.78)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const SecurityInfoBanner(
          text: 'Your password is hashed and never stored in plain text. SafeGuard never shares your data with other users.',
          icon: Icons.enhanced_encryption_rounded,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Checkbox(
              value: agree,
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              onChanged: (v) => onAgreeChanged(v ?? false),
            ),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: 'I agree to the ',
                  style: AppTextStyles.bodySm,
                  children: [
                    TextSpan(text: 'Terms of Service', style: AppTextStyles.bodySm.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                    const TextSpan(text: ' and '),
                    TextSpan(text: 'Privacy Policy', style: AppTextStyles.bodySm.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
