import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/utils/currency_formatter.dart';
import '../../budgets/providers/budget_providers.dart';

class TransactionCard extends ConsumerWidget {
  final db.Transaction transaction;
  final VoidCallback? onTap;

  const TransactionCard({super.key, required this.transaction, this.onTap});

  Color _getBudgetColor(BuildContext context, int? statusColor) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (statusColor) {
      case 0: // Green - good
        return colorScheme.primary;
      case 1: // Yellow - warning
        return colorScheme.tertiary;
      case 2: // Red - over budget
        return colorScheme.error;
      default:
        return colorScheme.outline;
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

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
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
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    formattedDate,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Cost and Budget row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Cost
                  Text(
                    CurrencyFormatter.format(
                      transaction.amount,
                      transaction.currencyCode,
                    ),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  // Remaining Budget
                  remainingBudgetAsync?.when(
                        data: (remaining) {
                          if (remaining == null) {
                            return const SizedBox.shrink();
                          }
                          final statusColor = budgetStatusColorAsync?.value;
                          final color = _getBudgetColor(context, statusColor);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: color.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              CurrencyFormatter.format(
                                remaining,
                                transaction.currencyCode,
                              ),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                        loading: () => SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        ),
                        error: (_, _) => const SizedBox.shrink(),
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
