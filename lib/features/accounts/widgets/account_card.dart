import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart' as db;

class AccountCard extends StatelessWidget {
  final db.Card card;
  final db.Bank? bank;
  final int transactionCount;
  final double totalSpent;
  final VoidCallback? onTap;

  const AccountCard({
    super.key,
    required this.card,
    this.bank,
    required this.transactionCount,
    required this.totalSpent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.credit_card),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.cardName.isNotEmpty
                              ? card.cardName
                              : 'Card ${card.last4Digits}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (bank != null)
                          Text(
                            bank!.name,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '****${card.last4Digits}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$transactionCount transactions',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Total: ${totalSpent.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
