import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart' as db;
import '../../budgets/providers/budget_providers.dart';
import '../../categories/providers/category_providers.dart';

class BudgetCard extends ConsumerWidget {
  final db.Budget budget;
  final VoidCallback? onTap;

  const BudgetCard({super.key, required this.budget, this.onTap});

  Color _getProgressColor(double percentage) {
    if (percentage >= 1.0) {
      return Colors.red; // Over budget
    } else if (percentage >= 0.8) {
      return Colors.orange; // Warning
    } else {
      return Colors.green; // Good
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetService = ref.watch(budgetServiceProvider);
    final categoryAsync = ref.watch(categoryProvider(budget.categoryId));

    // Calculate spent and remaining using FutureBuilder
    return FutureBuilder<double>(
      future: budgetService.calculateSpentAmount(budget),
      builder: (context, spentSnapshot) {
        if (!spentSnapshot.hasData) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final spent = spentSnapshot.data!;
        return FutureBuilder<double>(
          future: budgetService.calculateRemainingBudget(budget),
          builder: (context, remainingSnapshot) {
            final remaining = remainingSnapshot.data ?? (budget.amount - spent);
            final percentage = budget.amount > 0 ? spent / budget.amount : 0.0;
            final color = _getProgressColor(percentage);

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
                      categoryAsync.when(
                        data: (category) => Text(
                          category?.name ?? 'Unknown Category',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        loading: () => const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        error: (_, __) => const Text('Unknown Category'),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${spent.toStringAsFixed(2)} / ${budget.amount.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Container(
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
                                  remaining >= 0
                                      ? '${remaining.toStringAsFixed(2)} remaining'
                                      : '${(-remaining).toStringAsFixed(2)} over',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: percentage.clamp(0.0, 1.0),
                            backgroundColor: color.withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 8,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(percentage * 100).toStringAsFixed(0)}% used',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
