import 'package:flutter/material.dart';

/// SafeGuard design tokens — palette inspired by trusted institutional
/// banking (deep navy + confident blue) with a crisp, transparent white
/// canvas. Every accent has a job: blue = trust/primary action,
/// green = safe/completed, amber = pending/attention, red = risk/dispute.
class AppColors {
  AppColors._();

  // Brand blues
  static const Color navy = Color(0xFF0A1B3D); // deepest — splash, headers
  static const Color primary = Color(0xFF123B76); // core brand blue
  static const Color primaryLight = Color(0xFF2E6FBE);
  static const Color skyAccent = Color(0xFF4FA9E8);
  static const Color skyTint = Color(0xFFEAF3FC); // pale wash for chips/bg
  static const Color skyTint2 = Color(0xFFDCEBFA);

  // Neutral canvas
  static const Color background = Color(0xFFF5F8FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF0F4F9);
  static const Color border = Color(0xFFE4EAF1);
  static const Color divider = Color(0xFFEBEFF4);

  // Text
  static const Color textPrimary = Color(0xFF0D1B2E);
  static const Color textSecondary = Color(0xFF5B6B80);
  static const Color textMuted = Color(0xFF98A6B8);
  static const Color textOnDark = Color(0xFFF2F6FB);
  static const Color textOnDarkMuted = Color(0xFFAFC0D6);

  // Status semantics
  static const Color success = Color(0xFF1CA971);
  static const Color successTint = Color(0xFFE4F7EE);
  static const Color warning = Color(0xFFE8A23A);
  static const Color warningTint = Color(0xFFFCF1E0);
  static const Color danger = Color(0xFFE05555);
  static const Color dangerTint = Color(0xFFFBE7E7);
  static const Color info = Color(0xFF2E6FBE);
  static const Color infoTint = Color(0xFFE7F1FC);

  // Gradients
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, primary, Color(0xFF1E5FA0)],
  );

  static const LinearGradient trustGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, Color(0xFF16407D), Color(0xFF2E6FBE)],
  );

  static const LinearGradient cardSheenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surface, skyTint],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF17925F), Color(0xFF1CA971)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC9A24B), Color(0xFFE7CB86)],
  );

  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: navy.withOpacity(0.06),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: navy.withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: primary.withOpacity(0.22),
      blurRadius: 28,
      offset: const Offset(0, 14),
    ),
  ];
}
