import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_buttons.dart';
import '../auth/login_screen.dart';

class _OnboardData {
  final IconData icon;
  final String title;
  final String description;
  final Color accent;

  const _OnboardData({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  final List<_OnboardData> _pages = const [
    _OnboardData(
      icon: Icons.lock_person_rounded,
      title: 'Your money, held safe',
      description:
          'Funds stay securely locked in SafeGuard escrow until both buyer and seller confirm the deal is done — never straight into a stranger\'s pocket.',
      accent: AppColors.primary,
    ),
    _OnboardData(
      icon: Icons.fact_check_rounded,
      title: 'Verify before you pay',
      description:
          'Sellers confirm the order and ship with tracking. Buyers verify delivery before any money is released — no more "paid but never received."',
      accent: Color(0xFF7C5CD4),
    ),
    _OnboardData(
      icon: Icons.gavel_rounded,
      title: 'Fair dispute resolution',
      description:
          'If something goes wrong, our resolution team reviews evidence from both sides and issues a fair outcome — refund, release, or partial settlement.',
      accent: AppColors.warning,
    ),
    _OnboardData(
      icon: Icons.verified_user_rounded,
      title: 'Bank-grade protection',
      description:
          'Encrypted transactions, verified identities, and 24/7 fraud monitoring — the same standards trusted by leading financial institutions.',
      accent: AppColors.success,
    ),
  ];

  void _next() {
    if (_page < _pages.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _goToLogin,
                    child: Text('Skip', style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _OnboardPage(data: _pages[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  final active = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 26 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
              child: PrimaryButton(
                label: _page == _pages.length - 1 ? 'Get Started' : 'Continue',
                icon: _page == _pages.length - 1 ? Icons.arrow_forward_rounded : null,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  final _OnboardData data;
  const _OnboardPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.7, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
            child: Container(
              width: 168,
              height: 168,
              decoration: BoxDecoration(
                color: data.accent.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [data.accent, data.accent.withOpacity(0.75)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: data.accent.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 12)),
                    ],
                  ),
                  child: Icon(data.icon, size: 46, color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 44),
          Text(data.title, textAlign: TextAlign.center, style: AppTextStyles.displayMd),
          const SizedBox(height: 14),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd.copyWith(height: 1.55),
          ),
        ],
      ),
    );
  }
}
