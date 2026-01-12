import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/category_translations.dart';
import '../providers/budget_providers.dart';
import '../../categories/providers/category_providers.dart';

class BudgetCard extends ConsumerWidget {
  final db.Budget budget;
  final VoidCallback? onTap;

  const BudgetCard({super.key, required this.budget, this.onTap});

  Color _getProgressColor(BuildContext context, double percentage) {
    final colorScheme = Theme.of(context).colorScheme;
    if (percentage >= 1.0) {
      return colorScheme.error; // Over budget
    } else if (percentage >= 0.8) {
      return colorScheme.tertiary; // Warning
    } else {
      return colorScheme.primary; // Good
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetService = ref.watch(budgetServiceProvider);
    final categoryAsync = ref.watch(categoryProvider(budget.categoryId));

    // Calculate spent and remaining in parallel to avoid nested FutureBuilders
    // Memoize the future to prevent recalculation on every rebuild
    final budgetFuture = Future.wait([
      budgetService.calculateSpentAmount(budget),
      budgetService.calculateRemainingBudget(budget),
    ]).then((results) => (spent: results[0], remaining: results[1]));

    return FutureBuilder<({double spent, double remaining})>(
      future: budgetFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final data = snapshot.data!;
        final spent = data.spent;
        final remaining = data.remaining;
        final percentage = budget.amount > 0 ? spent / budget.amount : 0.0;
        final color = _getProgressColor(context, percentage);
        final theme = Theme.of(context);

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
                  categoryAsync.when(
                    data: (category) => Text(
                      category != null
                          ? CategoryTranslations.getTranslatedName(category)
                          : 'unknown_category'.tr(),
                      style: theme.textTheme.titleMedium,
                    ),
                    loading: () => SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    error: (_, _) => Text('unknown_category'.tr()),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${CurrencyFormatter.formatCompact(spent)} / ${CurrencyFormatter.formatCompact(budget.amount)}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
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
                              remaining >= 0
                                  ? '${CurrencyFormatter.formatCompact(remaining)} ${'remaining'.tr()}'
                                  : '${CurrencyFormatter.formatCompact(-remaining)} ${'over'.tr()}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: percentage.clamp(0.0, 1.0),
                        backgroundColor: color.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(percentage * 100).toStringAsFixed(0)}% ${'used'.tr()}',
                        style: theme.textTheme.bodySmall,
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
  }
}
