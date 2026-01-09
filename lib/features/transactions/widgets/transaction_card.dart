import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart' as db;
import '../../budgets/providers/budget_providers.dart';

class TransactionCard extends ConsumerWidget {
  final db.Transaction transaction;
  final VoidCallback? onTap;

  const TransactionCard({super.key, required this.transaction, this.onTap});

  Color _getBudgetColor(int? statusColor) {
    switch (statusColor) {
      case 0: // Green - good
        return Colors.green;
      case 1: // Yellow - warning
        return Colors.orange;
      case 2: // Red - over budget
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('yyyy/MM/dd');
    final formattedDate = dateFormat.format(transaction.date);

    // Get remaining budget for this transaction's category
    final remainingBudgetAsync = transaction.categoryId != null
        ? ref.watch(remainingBudgetProvider(transaction.categoryId!))
        : null;
    final budgetStatusColorAsync = transaction.categoryId != null
        ? ref.watch(budgetStatusColorProvider(transaction.categoryId!))
        : null;

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
              // Store Name and Date row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      transaction.storeName,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    formattedDate,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Cost and Budget row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Cost
                  Text(
                    '${transaction.amount.toStringAsFixed(2)} ${transaction.currencyCode}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Remaining Budget
                  remainingBudgetAsync?.when(
                        data: (remaining) {
                          if (remaining == null) {
                            return const SizedBox.shrink();
                          }
                          final statusColor = budgetStatusColorAsync?.value;
                          final color = _getBudgetColor(statusColor);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: color.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '${remaining.toStringAsFixed(2)} ${transaction.currencyCode}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          );
                        },
                        loading: () => const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                      ) ??
                      const SizedBox.shrink(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
