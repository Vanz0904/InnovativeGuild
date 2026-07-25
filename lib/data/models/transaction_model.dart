import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Full lifecycle of an escrow transaction on SafeGuard.
enum EscrowStatus {
  paymentHeld,
  sellerConfirmed,
  inTransit,
  deliveryVerification,
  completed,
  disputed,
  refunded,
}

extension EscrowStatusX on EscrowStatus {
  String get label {
    switch (this) {
      case EscrowStatus.paymentHeld:
        return 'Payment Held';
      case EscrowStatus.sellerConfirmed:
        return 'Seller Confirmed';
      case EscrowStatus.inTransit:
        return 'In Transit';
      case EscrowStatus.deliveryVerification:
        return 'Verifying Delivery';
      case EscrowStatus.completed:
        return 'Completed';
      case EscrowStatus.disputed:
        return 'Disputed';
      case EscrowStatus.refunded:
        return 'Refunded';
    }
  }

  Color get color {
    switch (this) {
      case EscrowStatus.paymentHeld:
        return AppColors.info;
      case EscrowStatus.sellerConfirmed:
        return AppColors.skyAccent;
      case EscrowStatus.inTransit:
        return const Color(0xFF7C5CD4);
      case EscrowStatus.deliveryVerification:
        return AppColors.warning;
      case EscrowStatus.completed:
        return AppColors.success;
      case EscrowStatus.disputed:
        return AppColors.danger;
      case EscrowStatus.refunded:
        return AppColors.textMuted;
    }
  }

  Color get tint {
    switch (this) {
      case EscrowStatus.paymentHeld:
        return AppColors.infoTint;
      case EscrowStatus.sellerConfirmed:
        return AppColors.skyTint;
      case EscrowStatus.inTransit:
        return const Color(0xFFEEE9FA);
      case EscrowStatus.deliveryVerification:
        return AppColors.warningTint;
      case EscrowStatus.completed:
        return AppColors.successTint;
      case EscrowStatus.disputed:
        return AppColors.dangerTint;
      case EscrowStatus.refunded:
        return AppColors.surfaceAlt;
    }
  }

  IconData get icon {
    switch (this) {
      case EscrowStatus.paymentHeld:
        return Icons.lock_clock_rounded;
      case EscrowStatus.sellerConfirmed:
        return Icons.storefront_rounded;
      case EscrowStatus.inTransit:
        return Icons.local_shipping_rounded;
      case EscrowStatus.deliveryVerification:
        return Icons.fact_check_rounded;
      case EscrowStatus.completed:
        return Icons.verified_rounded;
      case EscrowStatus.disputed:
        return Icons.gavel_rounded;
      case EscrowStatus.refunded:
        return Icons.replay_rounded;
    }
  }

  /// Step index (0-4) within the standard happy-path stepper.
  int get stepIndex {
    switch (this) {
      case EscrowStatus.paymentHeld:
        return 0;
      case EscrowStatus.sellerConfirmed:
        return 1;
      case EscrowStatus.inTransit:
        return 2;
      case EscrowStatus.deliveryVerification:
        return 3;
      case EscrowStatus.completed:
        return 4;
      case EscrowStatus.disputed:
        return 2;
      case EscrowStatus.refunded:
        return 4;
    }
  }
}

enum TransactionRole { buyer, seller }

class EscrowTransaction {
  final String id;
  final String title;
  final String counterpartyName;
  final String counterpartyInitials;
  final double amount;
  final String currency;
  final EscrowStatus status;
  final DateTime createdAt;
  final DateTime? expectedCompletion;
  final TransactionRole myRole;
  final String category;
  final String? trackingCode;

  const EscrowTransaction({
    required this.id,
    required this.title,
    required this.counterpartyName,
    required this.counterpartyInitials,
    required this.amount,
    this.currency = 'MWK',
    required this.status,
    required this.createdAt,
    this.expectedCompletion,
    required this.myRole,
    required this.category,
    this.trackingCode,
  });
}
