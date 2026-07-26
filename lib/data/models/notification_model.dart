import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum NotificationType { security, payment, delivery, dispute, system }

extension NotificationTypeX on NotificationType {
  static NotificationType fromApi(String value) {
    return NotificationType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => NotificationType.system,
    );
  }

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
  final String? transactionId;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    this.isRead = false,
    this.transactionId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: NotificationTypeX.fromApi(json['type'] as String? ?? 'system'),
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      time: DateTime.tryParse(json['time'] as String? ?? '') ?? DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
      transactionId: json['transactionId']?.toString(),
    );
  }
}

enum DisputeStage { filed, underReview, evidenceRequested, mediation, resolved }

extension DisputeStageX on DisputeStage {
  static DisputeStage fromApi(String value) {
    switch (value) {
      case 'under_review':
        return DisputeStage.underReview;
      case 'evidence_requested':
        return DisputeStage.evidenceRequested;
      case 'mediation':
        return DisputeStage.mediation;
      case 'resolved':
        return DisputeStage.resolved;
      default:
        return DisputeStage.filed;
    }
  }

  String get apiValue {
    switch (this) {
      case DisputeStage.underReview:
        return 'under_review';
      case DisputeStage.evidenceRequested:
        return 'evidence_requested';
      case DisputeStage.mediation:
        return 'mediation';
      case DisputeStage.resolved:
        return 'resolved';
      case DisputeStage.filed:
        return 'filed';
    }
  }

  String get label {
    switch (this) {
      case DisputeStage.filed:
        return 'Filed';
      case DisputeStage.underReview:
        return 'Under Review';
      case DisputeStage.evidenceRequested:
        return 'Evidence Requested';
      case DisputeStage.mediation:
        return 'Mediation';
      case DisputeStage.resolved:
        return 'Resolved';
    }
  }
}

class DisputeCase {
  final String id;
  final String transactionId;
  final String reason;
  final String? description;
  final DisputeStage stage;
  final String resolution;
  final DateTime filedAt;
  final DateTime? resolvedAt;

  const DisputeCase({
    required this.id,
    required this.transactionId,
    required this.reason,
    this.description,
    required this.stage,
    this.resolution = 'pending',
    required this.filedAt,
    this.resolvedAt,
  });

  factory DisputeCase.fromJson(Map<String, dynamic> json) {
    return DisputeCase(
      id: json['id'] as String,
      transactionId: json['transactionId'] as String,
      reason: json['reason'] as String? ?? '',
      description: json['description'] as String?,
      stage: DisputeStageX.fromApi(json['stage'] as String? ?? 'filed'),
      resolution: json['resolution'] as String? ?? 'pending',
      filedAt: DateTime.tryParse(json['filedAt'] as String? ?? '') ?? DateTime.now(),
      resolvedAt: json['resolvedAt'] != null ? DateTime.tryParse(json['resolvedAt'] as String) : null,
    );
  }
}
