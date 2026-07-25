import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Type system:
/// - Display/Headings: Plus Jakarta Sans — geometric, confident, modern fintech
/// - Body/UI: Inter — highly legible workhorse for banking-grade UI
/// - Figures/Amounts: JetBrains Mono — tabular figures for money, IDs, codes
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _jakarta = GoogleFonts.plusJakartaSans();
  static TextStyle _inter = GoogleFonts.inter();
  static TextStyle _mono = GoogleFonts.jetBrainsMono();

  // Display
  static TextStyle displayLg = _jakarta.copyWith(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.8,
    height: 1.15,
  );

  static TextStyle displayMd = _jakarta.copyWith(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static TextStyle h1 = _jakarta.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static TextStyle h2 = _jakarta.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static TextStyle h3 = _jakarta.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // Body
  static TextStyle bodyLg = _inter.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle bodyMd = _inter.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static TextStyle bodySm = _inter.copyWith(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.4,
  );

  static TextStyle label = _inter.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.1,
  );

  static TextStyle eyebrow = _inter.copyWith(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    color: AppColors.skyAccent,
    letterSpacing: 1.4,
  );

  static TextStyle buttonText = _jakarta.copyWith(
    fontSize: 15.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
    color: AppColors.textOnDark,
  );

  // Figures
  static TextStyle amountXl = _mono.copyWith(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnDark,
    letterSpacing: -0.5,
  );

  static TextStyle amountLg = _mono.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static TextStyle amountMd = _mono.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle amountSm = _mono.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  static TextStyle mono = _mono.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    letterSpacing: 0.3,
  );
}
