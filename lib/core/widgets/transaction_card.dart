import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../constants/formatters.dart';
import '../../data/models/transaction_model.dart';
import 'status_widgets.dart';

class TransactionCard extends StatelessWidget {
  final EscrowTransaction transaction;
  final VoidCallback? onTap;

  const TransactionCard({super.key, required this.transaction, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isBuyer = transaction.myRole == TransactionRole.buyer;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            _Avatar(initials: transaction.counterpartyInitials),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${isBuyer ? "Seller" : "Buyer"}: ${transaction.counterpartyName}',
                    style: AppTextStyles.bodySm,
                  ),
                  const SizedBox(height: 8),
                  StatusBadge(status: transaction.status, small: true),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppFormatters.compactCurrency(transaction.amount),
                  style: AppTextStyles.amountMd,
                ),
                const SizedBox(height: 4),
                Text(
                  AppFormatters.timeAgo(transaction.createdAt),
                  style: AppTextStyles.bodySm,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  const _Avatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: AppColors.trustGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTextStyles.h3.copyWith(color: Colors.white, fontSize: 14),
      ),
    );
  }
}
