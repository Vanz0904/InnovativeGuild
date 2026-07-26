import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Mirrors the `status` enum in the MySQL `transactions` table.
enum EscrowStatus {
  pendingPayment,
  paymentHeld,
  sellerConfirmed,
  inTransit,
  deliveryVerification,
  completed,
  disputed,
  refunded,
}

extension EscrowStatusX on EscrowStatus {
  static EscrowStatus fromApi(String value) {
    switch (value) {
      case 'pending_payment':
        return EscrowStatus.pendingPayment;
      case 'payment_held':
        return EscrowStatus.paymentHeld;
      case 'seller_confirmed':
        return EscrowStatus.sellerConfirmed;
      case 'in_transit':
        return EscrowStatus.inTransit;
      case 'delivery_verification':
        return EscrowStatus.deliveryVerification;
      case 'completed':
        return EscrowStatus.completed;
      case 'disputed':
        return EscrowStatus.disputed;
      case 'refunded':
        return EscrowStatus.refunded;
      default:
        return EscrowStatus.pendingPayment;
    }
  }

  String get apiValue {
    switch (this) {
      case EscrowStatus.pendingPayment:
        return 'pending_payment';
      case EscrowStatus.paymentHeld:
        return 'payment_held';
      case EscrowStatus.sellerConfirmed:
        return 'seller_confirmed';
      case EscrowStatus.inTransit:
        return 'in_transit';
      case EscrowStatus.deliveryVerification:
        return 'delivery_verification';
      case EscrowStatus.completed:
        return 'completed';
      case EscrowStatus.disputed:
        return 'disputed';
      case EscrowStatus.refunded:
        return 'refunded';
    }
  }

  String get label {
    switch (this) {
      case EscrowStatus.pendingPayment:
        return 'Awaiting Payment';
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
      case EscrowStatus.pendingPayment:
        return AppColors.textMuted;
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
      case EscrowStatus.pendingPayment:
        return AppColors.surfaceAlt;
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
      case EscrowStatus.pendingPayment:
        return Icons.payment_rounded;
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
  /// -1 means "before the stepper starts" (still awaiting payment).
  int get stepIndex {
    switch (this) {
      case EscrowStatus.pendingPayment:
        return -1;
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
  final String id; // human reference, e.g. SG-84213
  final String title;
  final String? description;
  final String counterpartyName;
  final String counterpartyInitials;
  final double amount;
  final double fee;
  final String currency;
  final EscrowStatus status;
  final DateTime createdAt;
  final DateTime? expectedCompletion;
  final TransactionRole myRole;
  final String category;
  final String? trackingCode;
  final String? courier;
  final String? deliveryAddress;
  final String? paymentMethod;

  const EscrowTransaction({
    required this.id,
    required this.title,
    this.description,
    required this.counterpartyName,
    required this.counterpartyInitials,
    required this.amount,
    required this.fee,
    this.currency = 'MWK',
    required this.status,
    required this.createdAt,
    this.expectedCompletion,
    required this.myRole,
    required this.category,
    this.trackingCode,
    this.courier,
    this.deliveryAddress,
    this.paymentMethod,
  });

  double get total => amount + fee;

  factory EscrowTransaction.fromJson(Map<String, dynamic> json) {
    return EscrowTransaction(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      counterpartyName: json['counterpartyName'] as String? ?? 'Unknown',
      counterpartyInitials: json['counterpartyInitials'] as String? ?? '??',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      fee: (json['fee'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'MWK',
      status: EscrowStatusX.fromApi(json['status'] as String? ?? 'pending_payment'),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      expectedCompletion: json['estimatedDelivery'] != null
          ? DateTime.tryParse(json['estimatedDelivery'] as String)
          : null,
      myRole: (json['myRole'] as String? ?? 'buyer') == 'buyer' ? TransactionRole.buyer : TransactionRole.seller,
      category: json['category'] as String? ?? 'Other',
      trackingCode: json['trackingCode'] as String?,
      courier: json['courier'] as String?,
      deliveryAddress: json['deliveryAddress'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
    );
  }
}
