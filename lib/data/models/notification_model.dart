import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum NotificationType { security, payment, delivery, dispute, system }

extension NotificationTypeX on NotificationType {
  IconData get icon {
    switch (this) {
      case NotificationType.security:
        return Icons.shield_rounded;
      case NotificationType.payment:
        return Icons.account_balance_wallet_rounded;
      case NotificationType.delivery:
        return Icons.local_shipping_rounded;
      case NotificationType.dispute:
        return Icons.gavel_rounded;
      case NotificationType.system:
        return Icons.campaign_rounded;
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.security:
        return AppColors.primary;
      case NotificationType.payment:
        return AppColors.success;
      case NotificationType.delivery:
        return const Color(0xFF7C5CD4);
      case NotificationType.dispute:
        return AppColors.danger;
      case NotificationType.system:
        return AppColors.warning;
    }
  }
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime time;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    this.isRead = false,
  });
}

enum DisputeStage { filed, underReview, evidenceRequested, mediation, resolved }

class DisputeCase {
  final String id;
  final String transactionId;
  final String reason;
  final DisputeStage stage;
  final DateTime filedAt;
  final List<String> evidenceFiles;

  const DisputeCase({
    required this.id,
    required this.transactionId,
    required this.reason,
    required this.stage,
    required this.filedAt,
    this.evidenceFiles = const [],
  });
}
