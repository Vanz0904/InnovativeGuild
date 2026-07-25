import 'models/transaction_model.dart';
import 'models/notification_model.dart';

class MockData {
  MockData._();

  static final DateTime _now = DateTime.now();

  static final List<EscrowTransaction> transactions = [
    EscrowTransaction(
      id: 'SG-84213',
      title: 'iPhone 14 Pro Max — 256GB',
      counterpartyName: 'Thandiwe Banda',
      counterpartyInitials: 'TB',
      amount: 1450000,
      status: EscrowStatus.paymentHeld,
      createdAt: _now.subtract(const Duration(hours: 3)),
      expectedCompletion: _now.add(const Duration(days: 4)),
      myRole: TransactionRole.buyer,
      category: 'Electronics',
      trackingCode: 'SG-TRK-9021',
    ),
    EscrowTransaction(
      id: 'SG-84190',
      title: 'Toyota Vitz 2015 — Full Service',
      counterpartyName: 'Chikondi Phiri',
      counterpartyInitials: 'CP',
      amount: 8200000,
      status: EscrowStatus.sellerConfirmed,
      createdAt: _now.subtract(const Duration(days: 1, hours: 4)),
      expectedCompletion: _now.add(const Duration(days: 7)),
      myRole: TransactionRole.buyer,
      category: 'Vehicles',
      trackingCode: 'SG-TRK-8814',
    ),
    EscrowTransaction(
      id: 'SG-84102',
      title: 'MacBook Air M2 13"',
      counterpartyName: 'Grace Mvula',
      counterpartyInitials: 'GM',
      amount: 1180000,
      status: EscrowStatus.inTransit,
      createdAt: _now.subtract(const Duration(days: 2)),
      expectedCompletion: _now.add(const Duration(days: 2)),
      myRole: TransactionRole.seller,
      category: 'Electronics',
      trackingCode: 'SG-TRK-8790',
    ),
    EscrowTransaction(
      id: 'SG-83950',
      title: 'Samsung 55" QLED TV',
      counterpartyName: 'Blessings Nyirenda',
      counterpartyInitials: 'BN',
      amount: 890000,
      status: EscrowStatus.deliveryVerification,
      createdAt: _now.subtract(const Duration(days: 3)),
      expectedCompletion: _now.add(const Duration(hours: 20)),
      myRole: TransactionRole.buyer,
      category: 'Electronics',
      trackingCode: 'SG-TRK-8663',
    ),
    EscrowTransaction(
      id: 'SG-83820',
      title: 'Photography Service — Wedding',
      counterpartyName: 'Esther Kamanga',
      counterpartyInitials: 'EK',
      amount: 650000,
      status: EscrowStatus.completed,
      createdAt: _now.subtract(const Duration(days: 9)),
      expectedCompletion: _now.subtract(const Duration(days: 2)),
      myRole: TransactionRole.buyer,
      category: 'Services',
    ),
    EscrowTransaction(
      id: 'SG-83790',
      title: 'Gaming PC — RTX 4070',
      counterpartyName: 'Mphatso Zulu',
      counterpartyInitials: 'MZ',
      amount: 2350000,
      status: EscrowStatus.disputed,
      createdAt: _now.subtract(const Duration(days: 6)),
      myRole: TransactionRole.buyer,
      category: 'Electronics',
      trackingCode: 'SG-TRK-8501',
    ),
    EscrowTransaction(
      id: 'SG-83650',
      title: 'Office Furniture Set',
      counterpartyName: 'Patrick Mwale',
      counterpartyInitials: 'PM',
      amount: 540000,
      status: EscrowStatus.completed,
      createdAt: _now.subtract(const Duration(days: 14)),
      myRole: TransactionRole.seller,
      category: 'Furniture',
    ),
    EscrowTransaction(
      id: 'SG-83500',
      title: 'DJI Mini 4 Pro Drone',
      counterpartyName: 'Linda Chirwa',
      counterpartyInitials: 'LC',
      amount: 980000,
      status: EscrowStatus.refunded,
      createdAt: _now.subtract(const Duration(days: 20)),
      myRole: TransactionRole.buyer,
      category: 'Electronics',
    ),
  ];

  static List<EscrowTransaction> get activeTransactions => transactions
      .where((t) => ![
            EscrowStatus.completed,
            EscrowStatus.refunded,
          ].contains(t.status))
      .toList();

  static List<EscrowTransaction> get completedTransactions => transactions
      .where((t) => t.status == EscrowStatus.completed)
      .toList();

  static double get totalHeldInEscrow => activeTransactions
      .where((t) => t.status != EscrowStatus.disputed)
      .fold(0, (sum, t) => sum + t.amount);

  static double get totalCompletedValue =>
      completedTransactions.fold(0, (sum, t) => sum + t.amount);

  static final List<AppNotification> notifications = [
    AppNotification(
      id: 'N-1',
      type: NotificationType.security,
      title: 'New device sign-in detected',
      message: 'Your account was accessed from a new device in Lilongwe. Was this you?',
      time: _now.subtract(const Duration(minutes: 12)),
    ),
    AppNotification(
      id: 'N-2',
      type: NotificationType.payment,
      title: 'Payment secured in escrow',
      message: 'MWK 1,450,000 for "iPhone 14 Pro Max" is now safely held by SafeGuard.',
      time: _now.subtract(const Duration(hours: 3)),
      isRead: true,
    ),
    AppNotification(
      id: 'N-3',
      type: NotificationType.delivery,
      title: 'Delivery confirmation needed',
      message: 'Confirm you received "Samsung 55\" QLED TV" to release funds to the seller.',
      time: _now.subtract(const Duration(hours: 6)),
    ),
    AppNotification(
      id: 'N-4',
      type: NotificationType.dispute,
      title: 'Dispute update — SG-83790',
      message: 'Our resolution team has requested additional evidence from both parties.',
      time: _now.subtract(const Duration(hours: 20)),
    ),
    AppNotification(
      id: 'N-5',
      type: NotificationType.payment,
      title: 'Funds released to seller',
      message: 'MWK 650,000 released to Esther Kamanga after delivery verification.',
      time: _now.subtract(const Duration(days: 2)),
      isRead: true,
    ),
    AppNotification(
      id: 'N-6',
      type: NotificationType.system,
      title: 'New fraud pattern alert',
      message: 'SafeGuard blocked 214 suspicious listings in Malawi marketplaces this week.',
      time: _now.subtract(const Duration(days: 3)),
      isRead: true,
    ),
  ];

  static int get unreadCount => notifications.where((n) => !n.isRead).length;
}
